-- Shared/Pipeline/Stages/Sending/Transport.luau
--!strict
--!optimize 2

--[[
	Provides Roblox RemoteEvent / RemoteFunction network transport for the
	Pipeline. Without this module all Pipeline messages dispatch in the same
	Luau VM and never cross the client / server boundary.

	The transport multiplexes every Pipeline message through two shared
	Roblox instances created by the server at Pipeline:Init() time:

	    ReplicatedStorage.PipelineEvent    (RemoteEvent)
	    ReplicatedStorage.PipelineFunction (RemoteFunction)

	Each payload on the wire is a plain table:
	    { name: string, kind: string, args: { any }, id: string }

	Pipeline:Init wires BulkSender.flushHook to Transport:FlushBatch so
	batched events are sent in one call per destination bucket instead of
	fanning out locally.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require("../../Core/Config")

local REMOTE_EVENT_NAME: string = "PipelineEvent"
local REMOTE_FUNCTION_NAME: string = "PipelineFunction"
local WAIT_TIMEOUT: number = 10

local Transport = {}
Transport.type = "Transport"
Transport.isServer = false
Transport.isClient = false
Transport.pipelineEvent = nil :: any
Transport.pipelineFunction = nil :: any
Transport.network = nil :: any
Transport.bulkSender = nil :: any

--[[
	Wires server-side remotes. Creates PipelineEvent and PipelineFunction in
	ReplicatedStorage and connects OnServerEvent / OnServerInvoke listeners.
	Called from Pipeline:Init on the server.
]]
function Transport:SetupServer(network: any)
	self.network = network
	self.isServer = true

	local re: RemoteEvent = Instance.new("RemoteEvent")
	re.Name = REMOTE_EVENT_NAME
	re.Parent = ReplicatedStorage

	local rf: RemoteFunction = Instance.new("RemoteFunction")
	rf.Name = REMOTE_FUNCTION_NAME
	rf.Parent = ReplicatedStorage

	self.pipelineEvent = re
	self.pipelineFunction = rf

	re.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then
			return
		end
		self:DispatchIncoming(player, payload)
	end)

	rf.OnServerInvoke = function(player: Player, payload: any): any
		if type(payload) ~= "table" then
			return nil
		end
		return self:InvokeIncoming(player, payload)
	end
end

--[[
	Waits for the server-created remotes and wires client-side listeners.
	Intended to be called in a background task from Pipeline:Init so the
	client's Init() does not yield.
]]
function Transport:SetupClient(network: any)
	self.network = network
	self.isClient = true

	local re = ReplicatedStorage:WaitForChild(REMOTE_EVENT_NAME, WAIT_TIMEOUT)
	if not re then
		error(`[Transport] Timed out waiting for '{REMOTE_EVENT_NAME}' after {WAIT_TIMEOUT}s`)
	end

	local rf = ReplicatedStorage:WaitForChild(REMOTE_FUNCTION_NAME, WAIT_TIMEOUT)
	if not rf then
		error(`[Transport] Timed out waiting for '{REMOTE_FUNCTION_NAME}' after {WAIT_TIMEOUT}s`)
	end

	self.pipelineEvent = re
	self.pipelineFunction = rf;

	(re :: RemoteEvent).OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		self:DispatchIncoming(nil, payload)
	end)

	;(rf :: RemoteFunction).OnClientInvoke = function(payload: any): any
		if type(payload) ~= "table" then
			return nil
		end
		return self:InvokeIncoming(nil, payload)
	end
end

--[[
	Sends the message over the wire when it must cross the VM boundary, and
	marks the message dropped so Dispatcher does not re-fire it locally.

	@param network Network Active Network instance.
	@param message Message Pipeline message being sent.
]]
function Transport:Handle(network: any, message: any)
	if not Config.TransportEnabled then
		return
	end
	if message.dropped or message.batched then
		return
	end

	local kind: string = message.kind
	if kind == "Relay" then
		return
	end

	local shouldCross: boolean = false
	if self.isServer then
		shouldCross = kind == "FireAllClients" or kind == "FireClient" or kind == "InvokeClient"
	elseif self.isClient then
		shouldCross = kind == "FireServer" or kind == "InvokeServer"
	end

	if not shouldCross then
		return
	end

	local payload = {
		name = message.name,
		kind = kind,
		args = message.args,
		id = message.id,
	}

	if kind == "FireServer" then
		self.pipelineEvent:FireServer(payload)
		message.dropped = true
	elseif kind == "FireAllClients" then
		self.pipelineEvent:FireAllClients(payload)
		message.dropped = true
	elseif kind == "FireClient" then
		self.pipelineEvent:FireClient(message.target, payload)
		message.dropped = true
	elseif kind == "InvokeServer" then
		local result = self.pipelineFunction:InvokeServer(payload)
		if result ~= nil then
			message.results = result
		end
		message.dropped = true
	elseif kind == "InvokeClient" then
		local ok, result = pcall(function()
			return self.pipelineFunction:InvokeClient(message.target, payload)
		end)
		if ok and result ~= nil then
			message.results = result
		elseif not ok then
			warn(`[Transport] InvokeClient failed for '{message.name}': {result}`)
		end
		message.dropped = true
	end
end

--[[
	Dispatches an incoming wire payload onto the local Network instance's
	signals. On the server, player is the sender; on the client, player is nil.
]]
function Transport:DispatchIncoming(player: Player?, payload: any)
	local network = self.network
	if not network then
		return
	end

	local kind: string = payload.kind

	if kind == "Batch" then
		if type(payload.items) ~= "table" then
			return
		end
		for _, item in payload.items do
			self:DispatchIncoming(player, item)
		end
		return
	end

	local args: { any } = payload.args or {}

	if kind == "FireServer" then
		local event = network.events[payload.name]
		if event then
			event.OnServerEvent:Fire(player, table.unpack(args))
		end
	elseif kind == "FireAllClients" or kind == "FireClient" then
		local event = network.events[payload.name]
		if event then
			event.OnClientEvent:Fire(table.unpack(args))
		end
	end
end

--[[
	Resolves an incoming Invoke payload by running the local invoke handler
	and returning the packed results.
]]
function Transport:InvokeIncoming(player: Player?, payload: any): any
	local network = self.network
	if not network then
		return nil
	end

	local kind: string = payload.kind
	local args: { any } = payload.args or {}

	if kind == "InvokeServer" then
		local fn = network.functions[payload.name]
		if fn and fn.OnServerInvoke then
			return table.pack(fn.OnServerInvoke(player, table.unpack(args)))
		end
	elseif kind == "InvokeClient" then
		local fn = network.functions[payload.name]
		if fn and fn.OnClientInvoke then
			return table.pack(fn.OnClientInvoke(table.unpack(args)))
		end
	end

	return nil
end

--[[
	Transport-aware BulkSender flush. Installed as BulkSender.flushHook by
	Pipeline:Init. Groups batched messages by destination and sends one
	FireServer / FireAllClients / FireClient call per bucket.
]]
function Transport:FlushBatch(drained: { any })
	if not self.pipelineEvent then
		return
	end

	local toServer: { any } = {}
	local toAllClients: { any } = {}
	local toClient: { [Player]: { any } } = {}

	for i = 1, #drained do
		local msg = drained[i]
		if msg.dropped then
			continue
		end
		local kind: string = msg.kind
		local item = { name = msg.name, kind = kind, args = msg.args }

		if kind == "FireServer" then
			toServer[#toServer + 1] = item
		elseif kind == "FireAllClients" then
			toAllClients[#toAllClients + 1] = item
		elseif kind == "FireClient" and msg.target then
			local bucket = toClient[msg.target]
			if not bucket then
				bucket = {}
				toClient[msg.target] = bucket
			end
			bucket[#bucket + 1] = item
		end
	end

	if self.isClient and #toServer > 0 then
		self.pipelineEvent:FireServer({ kind = "Batch", items = toServer })
	end

	if self.isServer then
		if #toAllClients > 0 then
			self.pipelineEvent:FireAllClients({ kind = "Batch", items = toAllClients })
		end
		for player, items in toClient do
			self.pipelineEvent:FireClient(player, { kind = "Batch", items = items })
		end
	end
end

return Transport
