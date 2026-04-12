-- Shared/Pipeline/Stages/Validation/Types/Number.luau
--!strict
--!optimize 2
--!native

local NumberType = {}

NumberType.Name = "number"
NumberType.Tag = 2

function NumberType.Check(value: any): boolean
	return type(value) == "number"
end

function NumberType.Encode(buf: buffer, cursor: number, value: number, _validator: any?): number
	buffer.writef64(buf, cursor, value)
	return cursor + 8
end

function NumberType.Decode(buf: buffer, cursor: number, _validator: any?): (number, number)
	return buffer.readf64(buf, cursor), cursor + 8
end

return NumberType
