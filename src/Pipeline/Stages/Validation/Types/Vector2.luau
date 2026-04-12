-- Shared/Pipeline/Stages/Validation/Types/Vector2.luau
--!strict
--!optimize 2
--!native

local Vector2Type = {}

Vector2Type.Name = "Vector2"
Vector2Type.Tag = 10

function Vector2Type.Check(value: any): boolean
	return typeof(value) == "Vector2"
end

function Vector2Type.Encode(buf: buffer, cursor: number, value: Vector2, _validator: any?): number
	buffer.writef32(buf, cursor, value.X)
	buffer.writef32(buf, cursor + 4, value.Y)
	return cursor + 8
end

function Vector2Type.Decode(buf: buffer, cursor: number, _validator: any?): (Vector2, number)
	local x: number = buffer.readf32(buf, cursor)
	local y: number = buffer.readf32(buf, cursor + 4)
	return Vector2.new(x, y), cursor + 8
end

return Vector2Type
