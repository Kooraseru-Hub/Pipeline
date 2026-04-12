-- Shared/Pipeline/Stages/Validation/Types/Color3.luau
--!strict
--!optimize 2
--!native

local Color3Type = {}

Color3Type.Name = "Color3"
Color3Type.Tag = 13

function Color3Type.Check(value: any): boolean
	return typeof(value) == "Color3"
end

function Color3Type.Encode(buf: buffer, cursor: number, value: Color3, _validator: any?): number
	buffer.writef32(buf, cursor, value.R)
	buffer.writef32(buf, cursor + 4, value.G)
	buffer.writef32(buf, cursor + 8, value.B)
	return cursor + 12
end

function Color3Type.Decode(buf: buffer, cursor: number, _validator: any?): (Color3, number)
	local r: number = buffer.readf32(buf, cursor)
	local g: number = buffer.readf32(buf, cursor + 4)
	local b: number = buffer.readf32(buf, cursor + 8)
	return Color3.new(r, g, b), cursor + 12
end

return Color3Type
