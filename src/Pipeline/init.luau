-- Shared/Pipeline/init.luau
--!strict
--!optimize 2

export type MessageKind = "FireAllClients" | "FireClient" | "FireServer" | "InvokeClient" | "InvokeServer" | "Relay"

export type Message = {
	name: string,
	kind: MessageKind,
	target: Player?,
	args: { any },
	paramTypes: { string }?,
	dropped: boolean,
	results: { any }?,
	isRelay: boolean?,
	id: string,
	sentAt: number,
	encoded: buffer?,
	batched: boolean?,
}

export type StageHandler = (network: Network, message: Message) -> ()

export type HandlerSlot = {
	handle: (self: any, network: Network, message: Message) -> (),
	module: any,
}

export type Pipeline = { [string]: { HandlerSlot } }

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
}

export type RemoteEventObject = {
	name: string,
	OnServerEvent: Signal,
	OnClientEvent: Signal,

	FireAllClients: (self: RemoteEventObject, ...any) -> (),
	FireClient: (self: RemoteEventObject, player: Player, ...any) -> (),
	FireServer: (self: RemoteEventObject, ...any) -> (),
	Relay: (self: RemoteEventObject, target: Player, ...any) -> (),
	OnServer: (self: RemoteEventObject, callback: (...any) -> ()) -> Connection,
	OnClient: (self: RemoteEventObject, callback: (...any) -> ()) -> Connection,
}

export type RemoteFunctionObject = {
	name: string,
	OnServerInvoke: ((player: Player, ...any) -> ...any)?,
	OnClientInvoke: ((...any) -> ...any)?,

	InvokeServer: (self: RemoteFunctionObject, ...any) -> ...any,
	InvokeClient: (self: RemoteFunctionObject, player: Player, ...any) -> ...any,
}

export type Network = {
	registry: any,
	pipeline: Pipeline,
	events: { [string]: RemoteEventObject },
	functions: { [string]: RemoteFunctionObject },

	Init: (self: Network, registry: any, name: string) -> (),
	GetEvent: (self: Network, name: string) -> RemoteEventObject,
	GetFunction: (self: Network, name: string) -> RemoteFunctionObject,
	GetPipeline: (self: Network) -> Pipeline,
}

local RunService = game:GetService("RunService")

local UUID = require("@self/Utilities/UUID")
local Config = require("@self/Core/Config")
local Serializer = require("@self/Core/Serializer")
local Stages = require("@self/Stages")
local Validator = require("@self/Stages/Validation/Validator")

local FLUSH_INTERVAL_SECONDS: number = 0.05

local function findModule(stage: string, typeTag: string): any?
	for _, entry in Stages.Entries do
		if entry.stage ~= stage then
			continue
		end
		local modules = entry.modules
		if not modules then
			return nil
		end
		for i = 1, #modules do
			local mod = modules[i]
			if (mod :: any).type == typeTag then
				return mod
			end
		end
		return nil
	end
	return nil
end

local function collectHandlers(stage: string): { HandlerSlot }
	local handlers: { HandlerSlot } = {}

	for _, entry in Stages.Entries do
		if entry.stage ~= stage then
			continue
		end
		local modules = entry.modules or {}
		for i = 1, #modules do
			local mod: any = modules[i]
			local handle = mod.Handle
			if not handle then
				continue
			end
			-- Config-driven stage skipping (optimization 5.11): omit disabled
			-- handlers from the pipeline entirely.
			if mod == Serializer and not Config.SerializerEnabled then
				continue
			end
			if mod.config == Config then
				-- Logger / Tracer carry their own enabled flag; leave the
				-- runtime check inside Handle. Still include them here so
				-- Config flips are picked up without a Pipeline rebuild.
			end
			handlers[#handlers + 1] = { handle = handle, module = mod } :: HandlerSlot
		end
		break
	end

	return handlers
end

local function buildPipeline(): Pipeline
	local pipeline: Pipeline = {}
	local pipelineAny: any = pipeline
	for _, entry in Stages.Entries do
		pipelineAny[entry.stage] = collectHandlers(entry.stage)
	end
	return pipeline
end

local function runStage(network: Network, stage: string, message: Message)
	local slots = network.pipeline[stage]
	for i = 1, #slots do
		if message.dropped then
			return
		end
		local slot = slots[i]
		slot.handle(slot.module, network, message)
	end
end

--[[
	Drives a message through the full pipeline. Relay messages skip the
	Validation stage (per the project's relay policy: server still
	rate-limits via PreSend but does not inspect payload semantics).
]]
local function runPipeline(network: Network, message: Message)
	runStage(network, "PreSend", message)
	if message.dropped then
		runStage(network, "PostSend", message)
		return
	end

	if not message.isRelay then
		runStage(network, "Validation", message)
		if message.dropped then
			runStage(network, "PostSend", message)
			return
		end
	end

	runStage(network, "Sending", message)
	runStage(network, "PostSend", message)
end

local Signal = {}
Signal.__index = Signal

local function createSignal(): Signal
	return setmetatable({ _handlers = {} }, Signal) :: any
end

function Signal:Connect(callback: (...any) -> ()): Connection
	local handlers = (self :: any)._handlers
	local idx: number = #handlers + 1
	handlers[idx] = callback

	local connection = {}
	function connection:Disconnect()
		if handlers[idx] ~= callback then
			return
		end
		local last: number = #handlers
		if idx ~= last then
			handlers[idx] = handlers[last]
		end
		handlers[last] = nil
	end
	return connection :: Connection
end

function Signal:Fire(...: any)
	local handlers = (self :: any)._handlers
	for i = 1, #handlers do
		handlers[i](...)
	end
end

local function buildMessage(name: string, kind: MessageKind, target: Player?, args: { any }): Message
	return {
		name = name,
		kind = kind,
		target = target,
		args = args,
		paramTypes = nil,
		dropped = false,
		results = nil,
		isRelay = kind == "Relay" or nil,
		id = UUID.Generate(Config.UUIDMode),
		sentAt = os.clock(),
		encoded = nil,
		batched = nil,
	}
end

local function newEventObject(network: Network, name: string): RemoteEventObject
	local obj = {} :: any
	obj.name = name
	obj.OnServerEvent = createSignal()
	obj.OnClientEvent = createSignal()

	function obj:FireAllClients(...: any)
		runPipeline(network, buildMessage(name, "FireAllClients", nil, { ... }))
	end

	function obj:FireClient(player: Player, ...: any)
		runPipeline(network, buildMessage(name, "FireClient", player, { ... }))
	end

	function obj:FireServer(...: any)
		runPipeline(network, buildMessage(name, "FireServer", nil, { ... }))
	end

	function obj:Relay(target: Player, ...: any)
		runPipeline(network, buildMessage(name, "Relay", target, { ... }))
	end

	function obj:OnServer(callback: (...any) -> ())
		return obj.OnServerEvent:Connect(callback)
	end

	function obj:OnClient(callback: (...any) -> ())
		return obj.OnClientEvent:Connect(callback)
	end

	return obj :: RemoteEventObject
end

local function newFunctionObject(network: Network, name: string): RemoteFunctionObject
	local obj = {} :: any
	obj.name = name
	obj.OnServerInvoke = nil
	obj.OnClientInvoke = nil

	function obj:InvokeServer(...: any): ...any
		local message = buildMessage(name, "InvokeServer", nil, { ... })
		runPipeline(network, message)
		if message.results then
			return table.unpack(message.results)
		end
		return
	end

	function obj:InvokeClient(player: Player, ...: any): ...any
		local message = buildMessage(name, "InvokeClient", player, { ... })
		runPipeline(network, message)
		if message.results then
			return table.unpack(message.results)
		end
		return
	end

	return obj :: RemoteFunctionObject
end

local Pipeline = {} :: Network
(Pipeline :: any).__index = Pipeline;
(Pipeline :: any).Priority = 100

--[[
	Single lifecycle entry point. Wires every internal component: loads the
	validator type registry, resets per-stage state, installs Transport and
	BulkSender, and builds the handler pipeline. Must be called once per
	Network instance.

	@param registry any The owning registry instance (or nil for standalone use).
	@param name string The registered name of this module.
]]
function Pipeline:Init(registry: any, name: string)
	self.registry = registry
	self.events = {}
	self.functions = {}

	-- Validator: load all built-in type modules and expose NetworkedObjects.
	Validator:LoadBuiltIns()

	-- Resolve known modules by their internal type tag.
	local bulkSender = findModule("Sending", "BulkSender")
	local transport = findModule("Sending", "Transport")
	local netObj = findModule("PreSend", "NetworkedObjects")
	local playerRegistry = findModule("PreSend", "PlayerRegistry")
	local rateLimiter = findModule("PreSend", "RateLimiter")
	local customValidation = findModule("Validation", "CustomValidation")
	local tracer = findModule("PostSend", "Tracer")
	local metrics = findModule("PostSend", "Metrics")

	if netObj then
		(netObj :: any):Reset()
		Validator:SetNetworkedObjects(netObj)
	end
	if playerRegistry then
		(playerRegistry :: any):Reset()
	end
	if rateLimiter then
		(rateLimiter :: any):Reset()
	end
	if customValidation then
		(customValidation :: any):Reset()
	end
	if tracer then
		(tracer :: any):Reset()
	end
	if metrics then
		(metrics :: any):Reset()
	end

	-- Serializer: thin dispatcher over the validator type registry.
	Serializer:SetValidator(Validator)

	-- BulkSender: reset queue state and connect the flush heartbeat.
	if bulkSender then
		local bs: any = bulkSender
		bs.queue = {}
		bs.lastFlush = os.clock()
		bs.network = self
		bs.flushHook = nil

		if transport then
			bs.flushHook = function(drained: { any })
				(transport :: any):FlushBatch(drained)
			end
		end

		if bs.heartbeatConnection then
			(bs.heartbeatConnection :: RBXScriptConnection):Disconnect()
		end
		bs.heartbeatConnection = RunService.Heartbeat:Connect(function()
			if os.clock() - bs.lastFlush < FLUSH_INTERVAL_SECONDS then
				return
			end
			if bs.network == nil then
				return
			end
			bs:Flush()
		end)
	end

	-- Transport: create or wait for the shared remotes.
	if transport and Config.TransportEnabled then
		if RunService:IsServer() then
			(transport :: any):SetupServer(self)
		elseif RunService:IsClient() then
			task.spawn(function()
				(transport :: any):SetupClient(self)
			end)
		end
	end

	self.pipeline = buildPipeline()
end

--[[
	Returns the named RemoteEvent-style object, creating it on first access.

	@param name string Unique remote name.
	@return RemoteEventObject
]]
function Pipeline:GetEvent(name: string): RemoteEventObject
	assert(type(name) == "string" and name ~= "", "[Pipeline] name must be a non-empty string")

	local existing = self.events[name]
	if existing then
		return existing
	end

	local obj = newEventObject(self, name)
	self.events[name] = obj
	return obj
end

--[[
	Returns the named RemoteFunction-style object, creating it on first access.

	@param name string Unique remote name.
	@return RemoteFunctionObject
]]
function Pipeline:GetFunction(name: string): RemoteFunctionObject
	assert(type(name) == "string" and name ~= "", "[Pipeline] name must be a non-empty string")

	local existing = self.functions[name]
	if existing then
		return existing
	end

	local obj = newFunctionObject(self, name)
	self.functions[name] = obj
	return obj
end

--[[
	Returns the pipeline table (stage name → list of handler slots). Treat
	as read-only.

	@return Pipeline
]]
function Pipeline:GetPipeline(): Pipeline
	return self.pipeline
end

return Pipeline
