-- Shared/Pipeline/Stages/Validation/Types/UDim2.luau
--!strict
--!optimize 2
--!native

local UDim2Type = {}

UDim2Type.Name = "UDim2"
UDim2Type.Tag = 15

function UDim2Type.Check(value: any): boolean
	return typeof(value) == "UDim2"
end

function UDim2Type.Encode(buf: buffer, cursor: number, value: UDim2, _validator: any?): number
	buffer.writef32(buf, cursor, value.X.Scale)
	buffer.writei32(buf, cursor + 4, value.X.Offset)
	buffer.writef32(buf, cursor + 8, value.Y.Scale)
	buffer.writei32(buf, cursor + 12, value.Y.Offset)
	return cursor + 16
end

function UDim2Type.Decode(buf: buffer, cursor: number, _validator: any?): (UDim2, number)
	local xScale: number = buffer.readf32(buf, cursor)
	local xOffset: number = buffer.readi32(buf, cursor + 4)
	local yScale: number = buffer.readf32(buf, cursor + 8)
	local yOffset: number = buffer.readi32(buf, cursor + 12)
	return UDim2.new(xScale, xOffset, yScale, yOffset), cursor + 16
end

return UDim2Type
