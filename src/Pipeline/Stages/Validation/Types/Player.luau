-- Shared/Pipeline/Stages/Validation/Types/Player.luau
--!strict
--!optimize 2

local PlayerType = {}

PlayerType.Name = "Player"
PlayerType.Tag = 17

function PlayerType.Check(value: any): boolean
	return typeof(value) == "Instance" and (value :: Instance):IsA("Player")
end

function PlayerType.Encode(buf: buffer, cursor: number, value: Player, _validator: any?): number
	buffer.writei64(buf, cursor, value.UserId)
	return cursor + 8
end

function PlayerType.Decode(buf: buffer, cursor: number, _validator: any?): (Player?, number)
	local Players = game:GetService("Players")
	local userId: number = buffer.readi64(buf, cursor)
	local player: Player? = Players:GetPlayerByUserId(userId)
	return player, cursor + 8
end

return PlayerType
