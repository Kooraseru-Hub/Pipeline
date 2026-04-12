-- Shared/Pipeline/Stages/PreSend/NetworkedObjects.luau
--!strict
--!optimize 2

local NetworkedObjects = {}
NetworkedObjects.type = "NetworkedObjects"
NetworkedObjects.instanceToId = {} :: { [Instance]: number }
NetworkedObjects.idToInstance = {} :: { [number]: Instance }
NetworkedObjects.nextId = 0

--[[
	Returns the stable numeric id for the given Instance, assigning a new id
	on first sight. Used by the Instance and Player type modules for the
	serialization wire format.

	@param instance Instance The Instance to identify.
	@return number Stable numeric id.
]]
function NetworkedObjects:GetId(instance: Instance): number
	local existing: number? = self.instanceToId[instance]
	if existing then
		return existing
	end
	self.nextId += 1
	local id: number = self.nextId
	self.instanceToId[instance] = id
	self.idToInstance[id] = instance
	return id
end

--[[
	Resolves a previously assigned numeric id back to its Instance.

	@param id number Identifier issued by GetId.
	@return Instance? The associated Instance, or nil if unknown.
]]
function NetworkedObjects:Resolve(id: number): Instance?
	return self.idToInstance[id]
end

--[[
	Assigns ids to any Instance references found in the message arguments so
	downstream stages can look them up by numeric id.

	@param network Network Active Network instance.
	@param message Message Pipeline message being inspected.
]]
function NetworkedObjects:Handle(network: any, message: any)
	local args = message.args
	for i = 1, #args do
		local value = args[i]
		if typeof(value) == "Instance" then
			self:GetId(value)
		end
	end
end

--[[
	Clears all tracked Instance ids. Called from Pipeline:Init to reset
	state across re-initialization.
]]
function NetworkedObjects:Reset()
	self.instanceToId = {}
	self.idToInstance = {}
	self.nextId = 0
end

return NetworkedObjects
