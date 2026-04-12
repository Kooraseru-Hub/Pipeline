-- Shared/Pipeline/Stages/Validation/Types/String.luau
--!strict
--!optimize 2
--!native

local StringType = {}

StringType.Name = "string"
StringType.Tag = 3

function StringType.Check(value: any): boolean
	return type(value) == "string"
end

function StringType.Encode(buf: buffer, cursor: number, value: string, _validator: any?): number
	local length: number = #value
	buffer.writeu32(buf, cursor, length)
	buffer.writestring(buf, cursor + 4, value)
	return cursor + 4 + length
end

function StringType.Decode(buf: buffer, cursor: number, _validator: any?): (string, number)
	local length: number = buffer.readu32(buf, cursor)
	local value: string = buffer.readstring(buf, cursor + 4, length)
	return value, cursor + 4 + length
end

return StringType
