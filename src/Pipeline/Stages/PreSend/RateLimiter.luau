-- Shared/Pipeline/Stages/PreSend/RateLimiter.luau
--!strict
--!optimize 2
--!native

type Bucket = {
	count: number,
	windowStart: number,
}

local Config = require("../../Core/Config")

local RateLimiter = {}
RateLimiter.type = "RateLimiter"
RateLimiter.config = Config
RateLimiter.buckets = {} :: { [string]: Bucket }

--[[
	Drops the message if the current binding has exceeded its call budget
	for the rolling window. Limits are read from Config so they can be
	adjusted without touching this file.

	@param network Network Active Network instance.
	@param message Message Pipeline message being inspected.
]]
function RateLimiter:Handle(network: any, message: any)
	local buckets = self.buckets
	local bucket: Bucket? = buckets[message.name]
	if not bucket then
		bucket = { count = 0, windowStart = os.clock() }
		buckets[message.name] = bucket
	end
	local b: Bucket = bucket :: Bucket

	local rateMaxCalls: number = self.config.RateMaxCalls
	if b.count + 1 <= rateMaxCalls then
		b.count += 1
		return
	end

	local now: number = os.clock()
	local rateWindow: number = self.config.RateWindowSeconds
	if now - b.windowStart >= rateWindow then
		b.windowStart = now
		b.count = 1
		return
	end

	message.dropped = true
end

--[[
	Clears all rate buckets. Called from Pipeline:Init to reset state across
	re-initialization.
]]
function RateLimiter:Reset()
	self.buckets = {}
end

return RateLimiter
