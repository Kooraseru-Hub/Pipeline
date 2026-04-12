-- Shared/Pipeline/Stages/Validation/CustomValidation.luau
--!strict
--!optimize 2

export type Rule = (network: any, message: any) -> boolean

local CustomValidation = {}
CustomValidation.type = "CustomValidation"
CustomValidation.rules = {} :: { Rule }

--[[
	Appends a validation rule. Each rule returns true when the message is
	acceptable and false to drop it.

	@param rule Rule Predicate applied per message.
]]
function CustomValidation:Register(rule: Rule)
	self.rules[#self.rules + 1] = rule
end

--[[
	Runs every registered rule against the message, dropping it on the first
	failure.

	@param network Network Active Network instance.
	@param message Message Pipeline message being validated.
]]
function CustomValidation:Handle(network: any, message: any)
	local rules = self.rules
	for i = 1, #rules do
		if not rules[i](network, message) then
			message.dropped = true
			return
		end
	end
end

--[[
	Clears all registered rules. Called from Pipeline:Init to reset state
	across re-initialization.
]]
function CustomValidation:Reset()
	self.rules = {}
end

return CustomValidation
