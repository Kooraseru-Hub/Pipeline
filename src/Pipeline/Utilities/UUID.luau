-- Shared/Pipeline/Utilities/UUID.luau
--!strict
--!optimize 2
--!native

local HttpService = game:GetService("HttpService")

local UUID = {}

local counter: number = 0

--[[
	Generates a unique identifier string.

	Mode controls the generation strategy:
	  0 — disabled: returns "" instantly (zero cost, default)
	  1 — counter:  returns tostring(n), session-unique, very cheap
	  2 — RFC GUID: HttpService:GenerateGUID(false) with gsub fallback

	@param mode number? Generation mode (defaults to 0 if omitted).
	@return string Unique identifier, or "" when mode is 0.
]]
function UUID.Generate(mode: number?): string
	local m: number = mode or 0

	if m == 0 then
		return ""
	elseif m == 1 then
		counter += 1
		return tostring(counter)
	else
		local ok, result = pcall(function()
			return HttpService:GenerateGUID(false)
		end)
		if ok then
			return result
		end

		local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
		return (template:gsub("[xy]", function(char: string): string
			local value = if char == "x" then math.random(0, 0xF) else math.random(8, 0xB)
			return string.format("%x", value)
		end))
	end
end

return UUID
