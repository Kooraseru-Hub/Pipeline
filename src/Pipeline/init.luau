-- src/Pipeline/init.luau
--!strict

local Pipeline = {}
Pipeline.__index = Pipeline

local Channel = {}
Channel.__index = Channel

--# Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--# Modules

local Middleware = require(script.Middleware)

--# Types

export type Direction = Middleware.Direction
export type Lane = Middleware.Lane
export type Context = Middleware.Context
export type MiddlewareHandler = Middleware.Handler

type Receiver = (...unknown) -> ()
type Next = Middleware.Next
type Handler = Middleware.Handler

type ChannelFields = {
	id: number,
	lane: Lane,
	network: Network,
	remote: RemoteEvent | UnreliableRemoteEvent,
	receiver: Receiver?,
	sendMiddleware: { Handler },
	receiveMiddleware: { Handler },
	sendChain: Next?,
	receiveChain: Next?,
}

type NetworkFields = {
	isServer: boolean,
	active: boolean,
	reliable: RemoteEvent,
	unreliable: UnreliableRemoteEvent,
	channels: { [number]: Channel },
	connections: { RBXScriptConnection },
	sendMiddleware: { Handler },
	receiveMiddleware: { Handler },
}

export type Channel = setmetatable<ChannelFields, typeof(Channel)>
export type Network = setmetatable<NetworkFields, typeof(Pipeline)>

--# Constants

const DEFAULT_NAMESPACE = "Pipeline"
const MAX_CHANNEL_ID = 65535
const WAIT_TIMEOUT_SECONDS = 20

--# Helpers

-- The unmodified path passes varargs directly to Roblox without allocating a packet.
local function fireDirect(channel: Channel, target: Player?, broadcast: boolean, ...: unknown)
	local network = channel.network
	if not network.active then
		return
	end

	local remote = channel.remote
	if not network.isServer then
		remote:FireServer(channel.id, ...)
		return
	end

	if broadcast then
		remote:FireAllClients(channel.id, ...)
		return
	end

	if not target then
		return
	end

	remote:FireClient(target, channel.id, ...)
end

local function deliverDirect(channel: Channel, sender: Player?, ...: unknown)
	local receiver = channel.receiver
	if not receiver then
		return
	end

	if channel.network.isServer then
		receiver(sender, ...)
		return
	end

	receiver(...)
end

-- Global middleware always runs before middleware registered on a channel.
local function collectMiddleware(channel: Channel, direction: Direction): { Handler }
	local network = channel.network
	local globalHandlers = if direction == "send" then network.sendMiddleware else network.receiveMiddleware
	local channelHandlers = if direction == "send" then channel.sendMiddleware else channel.receiveMiddleware
	local count = #globalHandlers + #channelHandlers
	local handlers: { Handler } = table.create(count)

	for index = 1, #globalHandlers do
		handlers[index] = globalHandlers[index]
	end

	for index = 1, #channelHandlers do
		handlers[#globalHandlers + index] = channelHandlers[index]
	end

	return handlers
end

-- Middleware chains are compiled only when registration changes, not per packet.
local function rebuildChannel(channel: Channel)
	local sendHandlers = collectMiddleware(channel, "send")
	local receiveHandlers = collectMiddleware(channel, "receive")

	channel.sendChain = nil
	channel.receiveChain = nil

	if #sendHandlers > 0 then
		channel.sendChain = Middleware.Compose(sendHandlers, function(context: Context)
			fireDirect(channel, context.target, context.broadcast, table.unpack(context.values, 1, context.count))
		end)
	end

	if #receiveHandlers > 0 then
		channel.receiveChain = Middleware.Compose(receiveHandlers, function(context: Context)
			deliverDirect(channel, context.sender, table.unpack(context.values, 1, context.count))
		end)
	end
end

local function sendWithMiddleware(channel: Channel, target: Player?, broadcast: boolean, ...: unknown)
	local chain = channel.sendChain
	if not chain then
		return
	end

	local values = table.pack(...)
	local context: Context = {
		id = channel.id,
		lane = channel.lane,
		direction = "send",
		sender = nil,
		target = target,
		broadcast = broadcast,
		values = values,
		count = values.n,
	}

	chain(context)
end

local function receivePacket(network: Network, sender: Player?, lane: Lane, id: unknown, ...: unknown)
	if not network.active or type(id) ~= "number" then
		return
	end

	local channel = network.channels[id]
	if not channel or channel.lane ~= lane then
		return
	end

	local chain = channel.receiveChain
	if not chain then
		local receiver = channel.receiver
		if not receiver then
			return
		end

		if network.isServer then
			receiver(sender, ...)
			return
		end

		receiver(...)
		return
	end

	local values = table.pack(...)
	local context: Context = {
		id = channel.id,
		lane = lane,
		direction = "receive",
		sender = sender,
		target = nil,
		broadcast = false,
		values = values,
		count = values.n,
	}

	chain(context)
end

--# Methods

-- A channel has one receiver; middleware handles shared cross-cutting behavior.
function Channel.Connect(self: Channel, callback: Receiver)
	self.receiver = callback
end

function Channel.Disconnect(self: Channel)
	self.receiver = nil
end

function Channel.Use(self: Channel, direction: Direction, handler: Handler)
	local handlers = if direction == "send" then self.sendMiddleware else self.receiveMiddleware
	handlers[#handlers + 1] = handler
	rebuildChannel(self)
end

function Channel.FireServer(self: Channel, ...: unknown)
	if self.network.isServer or not self.network.active then
		return
	end

	if not self.sendChain then
		self.remote:FireServer(self.id, ...)
		return
	end

	sendWithMiddleware(self, nil, false, ...)
end

function Channel.FireClient(self: Channel, player: Player, ...: unknown)
	if not self.network.isServer or not self.network.active then
		return
	end

	if not self.sendChain then
		self.remote:FireClient(player, self.id, ...)
		return
	end

	sendWithMiddleware(self, player, false, ...)
end

function Channel.FireAllClients(self: Channel, ...: unknown)
	if not self.network.isServer or not self.network.active then
		return
	end

	if not self.sendChain then
		self.remote:FireAllClients(self.id, ...)
		return
	end

	sendWithMiddleware(self, nil, true, ...)
end

function Pipeline.Channel(self: Network, id: number, lane: Lane?): (Channel?, string?)
	if not self.active then
		return nil, "Pipeline has been destroyed"
	end

	if id % 1 ~= 0 or id < 0 or id > MAX_CHANNEL_ID then
		return nil, `Channel id must be an integer from 0 to {MAX_CHANNEL_ID}`
	end

	local actualLane: Lane = lane or "reliable"
	local existing = self.channels[id]
	if existing then
		if existing.lane ~= actualLane then
			return nil, `Channel {id} is already registered as {existing.lane}`
		end

		return existing, nil
	end

	local fields: ChannelFields = {
		id = id,
		lane = actualLane,
		network = self,
		remote = if actualLane == "reliable" then self.reliable else self.unreliable,
		receiver = nil,
		sendMiddleware = {},
		receiveMiddleware = {},
		sendChain = nil,
		receiveChain = nil,
	}

	local channel = setmetatable(fields, Channel)
	self.channels[id] = channel
	rebuildChannel(channel)

	return channel, nil
end

function Pipeline.Use(self: Network, direction: Direction, handler: Handler)
	if not self.active then
		return
	end

	local handlers = if direction == "send" then self.sendMiddleware else self.receiveMiddleware
	handlers[#handlers + 1] = handler

	for _, channel in self.channels do
		rebuildChannel(channel)
	end
end

function Pipeline.Destroy(self: Network)
	if not self.active then
		return
	end

	self.active = false

	for _, connection in self.connections do
		connection:Disconnect()
	end

	table.clear(self.connections)
	table.clear(self.channels)
	table.clear(self.sendMiddleware)
	table.clear(self.receiveMiddleware)

	-- Only the server owns the RemoteEvent instances and may destroy them.
	if self.isServer then
		self.reliable:Destroy()
		self.unreliable:Destroy()
	end
end

--# Constructor

-- Construction is explicit: requiring Pipeline never creates remotes or listeners.
function Pipeline.new(namespace: string?, container: Instance?): (Network?, string?)
	local name = namespace or DEFAULT_NAMESPACE
	local parent = container or ReplicatedStorage
	local reliableName = `{name}Reliable`
	local unreliableName = `{name}Unreliable`
	local isServer = RunService:IsServer()

	if name == "" then
		return nil, "Pipeline namespace cannot be empty"
	end

	local reliable: RemoteEvent
	local unreliable: UnreliableRemoteEvent

	if isServer then
		if parent:FindFirstChild(reliableName) or parent:FindFirstChild(unreliableName) then
			return nil, `Pipeline remotes for '{name}' already exist`
		end

		reliable = Instance.new("RemoteEvent")
		reliable.Name = reliableName

		unreliable = Instance.new("UnreliableRemoteEvent")
		unreliable.Name = unreliableName

		reliable.Parent = parent
		unreliable.Parent = parent
	else
		local reliableInstance = parent:WaitForChild(reliableName, WAIT_TIMEOUT_SECONDS)
		local unreliableInstance = parent:WaitForChild(unreliableName, WAIT_TIMEOUT_SECONDS)

		if not reliableInstance or not reliableInstance:IsA("RemoteEvent") then
			return nil, `Missing RemoteEvent '{reliableName}'`
		end

		if not unreliableInstance or not unreliableInstance:IsA("UnreliableRemoteEvent") then
			return nil, `Missing UnreliableRemoteEvent '{unreliableName}'`
		end

		reliable = reliableInstance
		unreliable = unreliableInstance
	end

	local fields: NetworkFields = {
		isServer = isServer,
		active = true,
		reliable = reliable,
		unreliable = unreliable,
		channels = {},
		connections = {},
		sendMiddleware = {},
		receiveMiddleware = {},
	}

	local network = setmetatable(fields, Pipeline)

	if isServer then
		network.connections[1] = reliable.OnServerEvent:Connect(function(player: Player, id: unknown, ...: unknown)
			receivePacket(network, player, "reliable", id, ...)
		end)
		network.connections[2] = unreliable.OnServerEvent:Connect(function(player: Player, id: unknown, ...: unknown)
			receivePacket(network, player, "unreliable", id, ...)
		end)
	else
		network.connections[1] = reliable.OnClientEvent:Connect(function(id: unknown, ...: unknown)
			receivePacket(network, nil, "reliable", id, ...)
		end)
		network.connections[2] = unreliable.OnClientEvent:Connect(function(id: unknown, ...: unknown)
			receivePacket(network, nil, "unreliable", id, ...)
		end)
	end

	return network, nil
end

return Pipeline
