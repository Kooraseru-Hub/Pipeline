-- Shared/Pipeline/Stages/Validation/Types/Instance.luau
--!strict
--!optimize 2

local InstanceType = {}

InstanceType.Name = "Instance"
InstanceType.Tag = 16

function InstanceType.Check(value: any): boolean
	return typeof(value) == "Instance"
end

function InstanceType.Encode(buf: buffer, cursor: number, value: Instance, validator: any): number
	local networkedObjects = validator:GetNetworkedObjects()
	local id: number = if networkedObjects then networkedObjects:GetId(value) else 0
	buffer.writeu32(buf, cursor, id)
	return cursor + 4
end

function InstanceType.Decode(buf: buffer, cursor: number, validator: any): (Instance?, number)
	local id: number = buffer.readu32(buf, cursor)
	local networkedObjects = validator:GetNetworkedObjects()
	local instance: Instance? = if networkedObjects then networkedObjects:Resolve(id) else nil
	return instance, cursor + 4
end

return InstanceType
