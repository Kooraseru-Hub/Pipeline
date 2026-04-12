-- Shared/Pipeline/Stages/PostSend/Tracer.luau
--!strict
--!optimize 2

export type Span = {
	id: string,
	name: string,
	startedAt: number,
	endedAt: number,
	dropped: boolean,
}

local UUID = require("../../Utilities/UUID")
local Config = require("../../Core/Config")

local Tracer = {}
Tracer.type = "Tracer"
Tracer.config = Config
Tracer.uuid = UUID
Tracer.spans = {} :: { Span }

--[[
	Records a trace span for the processed message. Skipped entirely when
	Config.TracerEnabled is false. When the span buffer is full
	(Config.TracerMaxSpans) new spans are dropped to bound memory growth.

	@param network Network Active Network instance.
	@param message Message Pipeline message being traced.
]]
function Tracer:Handle(network: any, message: any)
	if not self.config.TracerEnabled then
		return
	end
	if #self.spans >= self.config.TracerMaxSpans then
		return
	end

	local now: number = os.clock()
	local span: Span = {
		id = if #message.id > 0 then message.id else self.uuid.Generate(self.config.UUIDMode),
		name = message.name,
		startedAt = message.sentAt or now,
		endedAt = now,
		dropped = message.dropped,
	}
	self.spans[#self.spans + 1] = span
end

--[[
	Drains and returns recorded spans.

	@return { Span } All spans collected since the last drain.
]]
function Tracer:Drain(): { Span }
	local drained: { Span } = self.spans
	self.spans = {}
	return drained
end

--[[
	Clears the span buffer. Called from Pipeline:Init to reset state across
	re-initialization.
]]
function Tracer:Reset()
	self.spans = {}
end

return Tracer
