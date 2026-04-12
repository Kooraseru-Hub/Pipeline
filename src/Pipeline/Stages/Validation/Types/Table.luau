-- Shared/Pipeline/Stages/Validation/Types/Table.luau
--!strict
--!optimize 2
--!native

local TableType = {}

TableType.Name = "table"
TableType.Tag = 4

function TableType.Check(value: any): boolean
	return type(value) == "table"
end

function TableType.Encode(buf: buffer, cursor: number, value: { [any]: any }, validator: any): number
	local count: number = 0
	for _ in value do
		count += 1
	end

	buffer.writeu32(buf, cursor, count)
	cursor += 4

	for k, v in value do
		local keyType = validator:ResolveByValue(k)
		if not keyType then
			warn(`[TableType] Unsupported key type '{typeof(k)}'`)
			return cursor
		end
		buffer.writeu8(buf, cursor, keyType.Tag)
		cursor = keyType.Encode(buf, cursor + 1, k, validator)

		local valueType = validator:ResolveByValue(v)
		if not valueType then
			warn(`[TableType] Unsupported value type '{typeof(v)}'`)
			return cursor
		end
		buffer.writeu8(buf, cursor, valueType.Tag)
		cursor = valueType.Encode(buf, cursor + 1, v, validator)
	end

	return cursor
end

function TableType.Decode(buf: buffer, cursor: number, validator: any): ({ [any]: any }, number)
	local count: number = buffer.readu32(buf, cursor)
	cursor += 4

	local result: { [any]: any } = {}
	for _ = 1, count do
		local keyTag: number = buffer.readu8(buf, cursor)
		local keyType = validator:GetByTag(keyTag)
		if not keyType then
			warn(`[TableType] Unknown key tag {keyTag}`)
			return result, cursor
		end
		local key, keyCursor = keyType.Decode(buf, cursor + 1, validator)
		cursor = keyCursor

		local valueTag: number = buffer.readu8(buf, cursor)
		local valueType = validator:GetByTag(valueTag)
		if not valueType then
			warn(`[TableType] Unknown value tag {valueTag}`)
			return result, cursor
		end
		local value, valueCursor = valueType.Decode(buf, cursor + 1, validator)
		cursor = valueCursor

		result[key] = value
	end

	return result, cursor
end

return TableType
