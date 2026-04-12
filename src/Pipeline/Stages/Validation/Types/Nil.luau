-- Shared/Pipeline/Stages/Validation/Types/Nil.luau
--!strict
--!optimize 2
--!native

local NilType = {}

NilType.Name = "nil"
NilType.Tag = 0

function NilType.Check(value: any): boolean
	return value == nil
end

function NilType.Encode(_buf: buffer, cursor: number, _value: nil, _validator: any?): number
	return cursor
end

function NilType.Decode(_buf: buffer, cursor: number, _validator: any?): (nil, number)
	return nil, cursor
end

return NilType
