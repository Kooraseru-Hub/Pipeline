-- tests/Runtime.spec.luau
--!strict

-- This test supplies a minimal engine boundary so transport can be exercised in Luau CLI.

--# Helpers

local function expect(condition: boolean, message: string)
	if not condition then
		error(message)
	end
end

local function createSignal()
	local listeners = {}
	local signal = {}

	function signal:Connect(callback)
		local entry = { callback = callback, connected = true }
		listeners[#listeners + 1] = entry

		return {
			Disconnect = function()
				entry.connected = false
			end,
		}
	end

	function signal:Fire(...)
		for _, entry in listeners do
			if entry.connected then
				entry.callback(...)
			end
		end
	end

	return signal
end

--# Variables

local isServer = true
local instances = {}
local examplePlayer = { Name = "Example" }
local storage = {}

function storage:FindFirstChild(name)
	for _, instance in instances do
		if instance.Parent == self and instance.Name == name then
			return instance
		end
	end

	return nil
end

function storage:WaitForChild(name)
	return self:FindFirstChild(name)
end

local mockRunService = {}

function mockRunService:IsServer()
	return isServer
end

local mockGame = {}

function mockGame:GetService(name)
	if name == "ReplicatedStorage" then
		return storage
	end

	if name == "RunService" then
		return mockRunService
	end

	return nil
end

local mockInstance = {}

function mockInstance.new(className)
	local instance = {
		Name = "",
		Parent = nil,
		className = className,
		OnServerEvent = createSignal(),
		OnClientEvent = createSignal(),
	}

	function instance:IsA(name)
		return self.className == name
	end

	function instance:FireServer(...)
		self.OnServerEvent:Fire(examplePlayer, ...)
	end

	function instance:FireClient(_, ...)
		self.OnClientEvent:Fire(...)
	end

	function instance:FireAllClients(...)
		self.OnClientEvent:Fire(...)
	end

	function instance:Destroy()
		self.Parent = nil
	end

	instances[#instances + 1] = instance
	return instance
end

-- Roblox sets these globals when loading a ModuleScript.
game = mockGame
Instance = mockInstance

--# Tests

local Pipeline = require("../src/Pipeline")

local server, serverError = Pipeline.new("Test")
expect(server ~= nil, serverError or "server initialization failed")

local duplicate = Pipeline.new("Test")
expect(duplicate == nil, "server accepted a duplicate transport namespace")

isServer = false
local client, clientError = Pipeline.new("Test")
expect(client ~= nil, clientError or "client initialization failed")

if not server or not client then
	error("transport setup failed")
end

local serverChannel = server:Channel(1)
local clientChannel = client:Channel(1)
if not serverChannel or not clientChannel then
	error("reliable channel setup failed")
end

local receivedServer: number? = nil
local receivedClient: string? = nil

serverChannel:Connect(function(player, amount)
	expect(player == examplePlayer, "server did not receive the sending player")
	receivedServer = amount
end)

clientChannel:Connect(function(message)
	receivedClient = message
end)

clientChannel:FireServer(42)
expect(receivedServer == 42, "client-to-server fast path failed")

local receivedCount = 0
serverChannel:Connect(function(_, ...)
	receivedCount = select("#", ...)
end)

clientChannel:FireServer(1, nil, 3)
expect(receivedCount == 3, "native varargs lost a nil argument")

serverChannel:Connect(function(_, amount)
	receivedServer = amount
end)

serverChannel:FireClient(examplePlayer, "hello")
expect(receivedClient == "hello", "server-to-client fast path failed")

local order: { string } = {}
server:Use("receive", function(context, next)
	order[#order + 1] = "global"
	next(context)
end)

serverChannel:Use("receive", function(context, next)
	order[#order + 1] = "channel"
	if context.values[1] ~= 100 then
		return
	end

	next(context)
end)

clientChannel:Use("send", function(context, next)
	context.values[1] = 100
	next(context)
end)

clientChannel:FireServer(50)
expect(receivedServer == 100, "middleware did not change the outgoing packet")
expect(order[1] == "global" and order[2] == "channel", "global and channel middleware are out of order")

clientChannel:FireServer(0)
expect(receivedServer == 100, "receive middleware did not short-circuit delivery")

local serverUnreliable = server:Channel(2, "unreliable")
local clientUnreliable = client:Channel(2, "unreliable")
if not serverUnreliable or not clientUnreliable then
	error("unreliable channel setup failed")
end

local unreliableValue: number? = nil
serverUnreliable:Connect(function(_, value)
	unreliableValue = value
end)

clientUnreliable:FireServer(12)
expect(unreliableValue == 12, "unreliable lane failed")

local reliableRemote = storage:FindFirstChild("TestReliable")
if not reliableRemote then
	error("reliable remote missing")
end

reliableRemote:FireServer(2, 99)
expect(unreliableValue == 12, "wrong transport lane reached the unreliable channel")

local mismatched = server:Channel(2, "reliable")
expect(mismatched == nil, "channel accepted conflicting lane")

client:Destroy()
server:Destroy()
clientChannel:FireServer(300)
expect(receivedServer == 100, "destroyed channel still sent data")

print("Runtime tests passed")
