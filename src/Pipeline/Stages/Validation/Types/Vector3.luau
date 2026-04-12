-- Shared/Pipeline/Stages/Validation/Types/Vector3.luau
--!strict
--!optimize 2
--!native

local Vector3Type = {}

Vector3Type.Name = "Vector3"
Vector3Type.Tag = 11

function Vector3Type.Check(value: any): boolean
	return typeof(value) == "Vector3"
end

function Vector3Type.Encode(buf: buffer, cursor: number, value: Vector3, _validator: any?): number
	buffer.writef32(buf, cursor, value.X)
	buffer.writef32(buf, cursor + 4, value.Y)
	buffer.writef32(buf, cursor + 8, value.Z)
	return cursor + 12
end

function Vector3Type.Decode(buf: buffer, cursor: number, _validator: any?): (Vector3, number)
	local x: number = buffer.readf32(buf, cursor)
	local y: number = buffer.readf32(buf, cursor + 4)
	local z: number = buffer.readf32(buf, cursor + 8)
	return Vector3.new(x, y, z), cursor + 12
end

return Vector3Type
