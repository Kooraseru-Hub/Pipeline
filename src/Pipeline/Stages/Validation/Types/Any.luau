-- Shared/Pipeline/Stages/Validation/Types/Any.luau
--!strict
--!optimize 2
--!native

local AnyType = {}

AnyType.Name = "any"
AnyType.Tag = 5

function AnyType.Check(_value: any): boolean
	return true
end

function AnyType.Encode(buf: buffer, cursor: number, value: any, validator: any): number
	local typeMod = validator:ResolveByValue(value)
	if not typeMod then
		warn(`[AnyType] No type module for value of type '{typeof(value)}'`)
		buffer.writeu8(buf, cursor, 0)
		return cursor + 1
	end
	buffer.writeu8(buf, cursor, typeMod.Tag)
	return typeMod.Encode(buf, cursor + 1, value, validator)
end

function AnyType.Decode(buf: buffer, cursor: number, validator: any): (any, number)
	local tag: number = buffer.readu8(buf, cursor)
	local typeMod = validator:GetByTag(tag)
	if not typeMod then
		warn(`[AnyType] No type module for tag {tag}`)
		return nil, cursor + 1
	end
	return typeMod.Decode(buf, cursor + 1, validator)
end

return AnyType
