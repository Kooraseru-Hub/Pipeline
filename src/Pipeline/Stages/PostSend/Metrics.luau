-- Shared/Pipeline/Stages/PostSend/Metrics.luau
--!strict
--!optimize 2

local Metrics = {}
Metrics.type = "Metrics"
Metrics.counts = {} :: { [string]: number }
Metrics.drops = {} :: { [string]: number }

--[[
	Increments the invocation count for the message's binding, tracking
	drops separately from successful dispatches.

	@param network Network Active Network instance.
	@param message Message Pipeline message being recorded.
]]
function Metrics:Handle(network: any, message: any)
	local bucket = if message.dropped then self.drops else self.counts
	bucket[message.name] = (bucket[message.name] or 0) + 1
end

--[[
	Returns a snapshot of current metric tables.

	@return { counts: { [string]: number }, drops: { [string]: number } }
]]
function Metrics:Snapshot(): { counts: { [string]: number }, drops: { [string]: number } }
	return { counts = self.counts, drops = self.drops }
end

--[[
	Clears counts and drops. Called from Pipeline:Init to reset state across
	re-initialization.
]]
function Metrics:Reset()
	self.counts = {}
	self.drops = {}
end

return Metrics
