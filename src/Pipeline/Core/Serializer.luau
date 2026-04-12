-- Shared/Pipeline/Core/Serializer.luau
--!strict
--!optimize 2

local Config = require("./Config")

local INITIAL_CAPACITY: number = 64

local Serializer = {}
Serializer.config = Config
Serializer.validator = nil :: any

local function ensureCapacity(buf: buffer, capacity: number, needed: number): (buffer, number)
	if needed <= capacity then
		return buf, capacity
	end
	local newCapacity: number = capacity
	while newCapacity < needed do
		newCapacity *= 2
	end
	local newBuf: buffer = buffer.create(newCapacity)
	buffer.copy(newBuf, 0, buf, 0, capacity)
	return newBuf, newCapacity
end

function Serializer:SetValidator(validator: any)
	self.validator = validator
end

function Serializer:Handle(network: any, message: any)
	if not self.config.SerializerEnabled then
		return
	end

	local validator = self.validator
	if not validator then
		return
	end

	local args = message.args
	local argCount: number = #args

	local capacity: number = INITIAL_CAPACITY
	local buf: buffer = buffer.create(capacity)
	local cursor: number = 0

	buf, capacity = ensureCapacity(buf, capacity, cursor + 4)
	buffer.writeu32(buf, cursor, argCount)
	cursor += 4

	local paramTypes = message.paramTypes
	local tagFree: boolean = paramTypes ~= nil

	for i = 1, argCount do
		local value = args[i]
		local typeMod

		if tagFree then
			local typeName: string = (paramTypes :: { string })[i]
			typeMod = validator:GetByName(typeName)
			if not typeMod then
				warn(`[Serializer] Unknown paramType '{typeName}'`)
				return
			end
		else
			typeMod = validator:ResolveByValue(value)
			if not typeMod then
				warn(`[Serializer] Unsupported arg type '{typeof(value)}'`)
				return
			end
			buf, capacity = ensureCapacity(buf, capacity, cursor + 1)
			buffer.writeu8(buf, cursor, typeMod.Tag)
			cursor += 1
		end

		-- Grow speculatively for the encode pass. Type modules write raw
		-- primitives without bounds checks, so reserve a generous slab per
		-- value and let doubling absorb the rest.
		buf, capacity = ensureCapacity(buf, capacity, cursor + 64)
		cursor = typeMod.Encode(buf, cursor, value, validator)
	end

	local finalBuf: buffer = buffer.create(cursor)
	buffer.copy(finalBuf, 0, buf, 0, cursor)
	message.encoded = finalBuf
end

function Serializer:Decode(payload: buffer, paramTypes: { string }?): { any }
	local validator = self.validator
	assert(validator, "[Serializer] validator not set; call SetValidator before Decode")

	local cursor: number = 0
	local argCount: number = buffer.readu32(payload, cursor)
	cursor += 4

	local tagFree: boolean = paramTypes ~= nil
	local result: { any } = table.create(argCount)

	for i = 1, argCount do
		local typeMod

		if tagFree then
			local typeName: string = (paramTypes :: { string })[i]
			typeMod = validator:GetByName(typeName)
			if not typeMod then
				warn(`[Serializer] Unknown paramType '{typeName}'`)
				return result
			end
		else
			local tag: number = buffer.readu8(payload, cursor)
			cursor += 1
			typeMod = validator:GetByTag(tag)
			if not typeMod then
				warn(`[Serializer] Unknown tag {tag}`)
				return result
			end
		end

		local value, nextCursor = typeMod.Decode(payload, cursor, validator)
		result[i] = value
		cursor = nextCursor
	end

	return result
end

return Serializer
