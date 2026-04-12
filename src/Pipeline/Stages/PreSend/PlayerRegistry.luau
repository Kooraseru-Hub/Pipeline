-- Shared/Pipeline/Stages/PreSend/PlayerRegistry.luau
--!strict
--!optimize 2

local PlayerRegistry = {}
PlayerRegistry.type = "PlayerRegistry"
PlayerRegistry.knownPlayers = {} :: { [Player]: boolean }

--[[
	Records any Player references found in the message arguments. Reserved
	for future recipient resolution.

	@param network Network Active Network instance.
	@param message Message Pipeline message being inspected.
]]
function PlayerRegistry:Handle(network: any, message: any)
	local args = message.args
	for i = 1, #args do
		local value = args[i]
		if typeof(value) == "Instance" and (value :: Instance):IsA("Player") then
			self.knownPlayers[value :: Player] = true
		end
	end
end

--[[
	Clears tracked players. Called from Pipeline:Init to reset state across
	re-initialization.
]]
function PlayerRegistry:Reset()
	self.knownPlayers = {}
end

return PlayerRegistry
