-- Shared/Pipeline/Stages/PostSend/Logger.luau
--!strict
--!optimize 2

local Config = require("../../Core/Config")

local Logger = {}
Logger.config = Config

--[[
	Emits a structured log line describing the processed message.

	@param network Network Active Network instance.
	@param message Message Pipeline message being logged.
]]
function Logger:Handle(network: any, message: any)
	if not self.config.LoggerEnabled then
		return
	end
	local status: string = if message.dropped then "dropped" else "ok"
	print(string.format("[Network] %s name=%s args=%d", status, message.name, #message.args))
end

return Logger
