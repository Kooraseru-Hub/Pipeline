-- Shared/Pipeline/Core/Config.luau
--!strict
--!optimize 2

local Config = {
    -- UUID generation mode applied to all pipeline messages.
    -- 0 = disabled — Generate() returns "" instantly (zero cost)
    -- 1 = counter  — returns tostring(n), session-unique, very cheap
    -- 2 = RFC GUID — HttpService:GenerateGUID / gsub fallback (full compliance)
    UUIDMode = 0,

    -- When false, Logger:Handle() is a no-op (zero cost).
    LoggerEnabled = false,

    -- When false, Serializer:Handle() is a no-op.
    -- The encoded buffer is unused in the current fire-all dispatch path;
    -- enable only when a consumer actually reads message.encoded.
    SerializerEnabled = true,

    -- When false, Tracer:Handle() is a no-op (zero allocations).
    TracerEnabled = false,

    -- Maximum number of spans held by Tracer before new ones are dropped.
    -- Prevents unbounded memory growth under high fire rates.
    TracerMaxSpans = 1000,

    -- RateLimiter: maximum calls allowed per event name per window.
    RateMaxCalls = 600000,

    -- RateLimiter: sliding window duration in seconds.
    RateWindowSeconds = 1.0,

    -- When false, Transport:Handle is a no-op (allows offline/test usage without remotes).
    TransportEnabled = true,
}

return Config
