-- Shared/Pipeline/Stages/Validation/Types/UDim.luau
--!strict
--!optimize 2
--!native

local UDimType = {}

UDimType.Name = "UDim"
UDimType.Tag = 14

function UDimType.Check(value: any): boolean
	return typeof(value) == "UDim"
end

function UDimType.Encode(buf: buffer, cursor: number, value: UDim, _validator: any?): number
	buffer.writef32(buf, cursor, value.Scale)
	buffer.writei32(buf, cursor + 4, value.Offset)
	return cursor + 8
end

function UDimType.Decode(buf: buffer, cursor: number, _validator: any?): (UDim, number)
	local scale: number = buffer.readf32(buf, cursor)
	local offset: number = buffer.readi32(buf, cursor + 4)
	return UDim.new(scale, offset), cursor + 8
end

return UDimType
