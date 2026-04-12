-- Shared/Pipeline/Stages/Validation/Types/Boolean.luau
--!strict
--!optimize 2
--!native

local BooleanType = {}

BooleanType.Name = "boolean"
BooleanType.Tag = 1

function BooleanType.Check(value: any): boolean
	return type(value) == "boolean"
end

function BooleanType.Encode(buf: buffer, cursor: number, value: boolean, _validator: any?): number
	buffer.writeu8(buf, cursor, if value then 1 else 0)
	return cursor + 1
end

function BooleanType.Decode(buf: buffer, cursor: number, _validator: any?): (boolean, number)
	return buffer.readu8(buf, cursor) ~= 0, cursor + 1
end

return BooleanType
