# Changelog

All notable changes to Pipeline are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-04-12

### Added

**Core:** `Pipeline:Init(registry, name)` single lifecycle entry point that wires all stages, resets per-stage state, connects BulkSender's Heartbeat flush, and sets up Transport remotes. `Pipeline:GetEvent(name)` creates and caches `RemoteEventObject` instances by name. `Pipeline:GetFunction(name)` creates and caches `RemoteFunctionObject` instances by name. `Pipeline:GetPipeline()` returns the built pipeline table for inspection. Four-stage message pipeline (PreSend, Validation, Sending, PostSend) with dropped-message short-circuit routing to PostSend. `Message` type carrying name, kind, target, args, paramTypes, dropped flag, results, relay flag, id, sentAt, encoded buffer, and batched flag.

**RemoteEventObject:** `FireAllClients`, `FireClient`, `FireServer`, `Relay`, `OnServer`, `OnClient`. `OnServerEvent` and `OnClientEvent` signals with `Connect` and `Disconnect` support.

**RemoteFunctionObject:** `InvokeServer`, `InvokeClient`. `OnServerInvoke` and `OnClientInvoke` callback properties.

**Stages (PreSend):** `RateLimiter`: per-event sliding window limiter configurable via `Config.RateMaxCalls` and `Config.RateWindowSeconds`. `NetworkedObjects`: instance ID registry used by Validator for Instance and Player type encoding. `PlayerRegistry`: connected player tracking for server-side observability.

**Stages (Validation):** `Validator`: type registry with 14 built-in types: Nil, Boolean, Number, String, Table, Any, Vector2, Vector3, CFrame, Color3, UDim, UDim2, Instance, Player. `Validator:Register(typeModule)`: custom type registration via Name/Tag/Check/Encode/Decode interface. `CustomValidation:Register(predicate)`: user-defined per-message validation predicates. Relay messages bypass the Validation stage entirely.

**Stages (Sending):** `BulkSender`: queues fire calls and flushes at 20 Hz (0.05 s) via `RunService.Heartbeat`. `Transport`: creates and connects Roblox RemoteEvent and RemoteFunction on the server; client waits for server remotes before connecting. `Dispatcher`: routes message results back to the caller for InvokeServer and InvokeClient. `P2PRelay`: forwards relay messages directly without passing through Validation.

**Stages (PostSend):** `Logger`: structured per-message log toggled by `Config.LoggerEnabled`. `Tracer`: span collection (id, name, startedAt, endedAt, dropped) capped at `Config.TracerMaxSpans`; `Tracer:Drain()` returns and clears all spans. `Metrics`: per-event count and drop counters; `Metrics:Snapshot()` returns `{ counts, drops }`.

**Core modules:** `Config`: all feature flags and tuning constants with documented defaults (UUIDMode, LoggerEnabled, SerializerEnabled, TracerEnabled, TracerMaxSpans, RateMaxCalls, RateWindowSeconds, TransportEnabled). `Serializer`: buffer encoding dispatcher over the Validator type registry; skipped at zero cost when `Config.SerializerEnabled` is false. `UUID`: three-mode ID generation (0 = off, 1 = counter, 2 = RFC GUID) controlled by `Config.UUIDMode`. `Promise`: async utility with `AndThen`, `Catch`, `Cancel`, `Promise.All`, and `Promise.AllSettled`.

### Notes

> [!NOTE]
> This is the initial public release. All public APIs are considered stable. `Config` flags are the intended extension point for enabling and disabling subsystems. Modifying stage module internals directly is not a supported upgrade path.
