-- Shared/Pipeline/Stages/Validation/Types/CFrame.luau
--!strict
--!optimize 2
--!native

local CFrameType = {}

CFrameType.Name = "CFrame"
CFrameType.Tag = 12

function CFrameType.Check(value: any): boolean
	return typeof(value) == "CFrame"
end

function CFrameType.Encode(buf: buffer, cursor: number, value: CFrame, _validator: any?): number
	local components = { value:GetComponents() }
	for i = 1, 12 do
		buffer.writef32(buf, cursor + (i - 1) * 4, components[i])
	end
	return cursor + 48
end

function CFrameType.Decode(buf: buffer, cursor: number, _validator: any?): (CFrame, number)
	local c1: number = buffer.readf32(buf, cursor)
	local c2: number = buffer.readf32(buf, cursor + 4)
	local c3: number = buffer.readf32(buf, cursor + 8)
	local c4: number = buffer.readf32(buf, cursor + 12)
	local c5: number = buffer.readf32(buf, cursor + 16)
	local c6: number = buffer.readf32(buf, cursor + 20)
	local c7: number = buffer.readf32(buf, cursor + 24)
	local c8: number = buffer.readf32(buf, cursor + 28)
	local c9: number = buffer.readf32(buf, cursor + 32)
	local c10: number = buffer.readf32(buf, cursor + 36)
	local c11: number = buffer.readf32(buf, cursor + 40)
	local c12: number = buffer.readf32(buf, cursor + 44)
	return CFrame.new(c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12), cursor + 48
end

return CFrameType
