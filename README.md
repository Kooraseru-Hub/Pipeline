<h1 align="center">Pipeline</h1>

<p align="center">
  <strong>A middleware-based network message pipeline for Roblox</strong><br>
  Route RemoteEvent and RemoteFunction traffic through staged handlers: rate limiting, validation, binary serialization, batching, tracing, and metrics.
</p>

<div align="center">
    <a href="https://github.com/Kooraseru-Hub/Pipeline">
        <img src="https://img.shields.io/badge/Source%20Code-00A2FF?style=for-the-badge&logo=github&logoColor=white"></a>
    <a href="https://create.roblox.com/store/asset/75329843346171/Pipeline">
        <img src="https://img.shields.io/badge/Download-000000?style=for-the-badge&logo=data:image/svg%2bxml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjwhLS0gR2VuZXJhdG9yOiBBZG9iZSBJbGx1c3RyYXRvciAyOC40LjEsIFNWRyBFeHBvcnQgUGx1Zy1JbiAuIFNWRyBWZXJzaW9uOiA2LjAwIEJ1aWxkIDApICAtLT4NCjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iUm9ibG94Xy1fSWNvbl94MkNfXzIwMjUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiDQoJIHg9IjBweCIgeT0iMHB4IiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgNTEyIDUxMjsiIHhtbDpzcGFjZT0icHJlc2VydmUiPg0KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4NCgkuc3Qwe2ZpbGw6I0ZGRkZGRjt9DQo8L3N0eWxlPg0KPGcgaWQ9IlN0dWRpbyI+DQoJPHBhdGggaWQ9IkJHIiBkPSJNNDE5LjgsNTEySDkyLjJDNDEuMyw1MTIsMCw0NzAuNywwLDQxOS44VjkyLjJDMCw0MS4zLDQxLjMsMCw5Mi4yLDBoMzI3LjVDNDcwLjcsMCw1MTIsNDEuMyw1MTIsOTIuMnYzMjcuNQ0KCQlDNTEyLDQ3MC43LDQ3MC43LDUxMiw0MTkuOCw1MTJ6Ii8+DQoJPGcgaWQ9Ik9fQmx4XzAwMDAwMTMxMzYzNjI4MTcwMzcyNzEwMjkwMDAwMDA0NDY0ODg5NzU4MTkzNTU4Njc0XyI+DQoJCTxwb2x5Z29uIGNsYXNzPSJzdDAiIHBvaW50cz0iMzk5LjksMjk0LjYgMjk2LjIsMjY2LjggMjg1LjQsMzA3IDEwMS40LDI1Ny43IDczLjYsMzYxLjMgMzYxLjMsNDM4LjQgMzg5LjEsMzM0LjggMzg5LjEsMzM0LjggCQkNCgkJCSIvPg0KCQk8cG9seWdvbiBjbGFzcz0ic3QwIiBwb2ludHM9IjQzOC40LDE1MC43IDE1MC43LDczLjYgMTEyLjEsMjE3LjQgMjE1LjgsMjQ1LjIgMjI2LjYsMjA1IDQxMC42LDI1NC4zIAkJIi8+DQoJPC9nPg0KPC9nPg0KPC9zdmc+DQo="></a>
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/License-CC0%201.0-blue?style=for-the-badge"></a>
</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
- [Project Structure](#project-structure)
- [Best Practices](#best-practices)

---

## Overview

Pipeline wraps Roblox's RemoteEvent and RemoteFunction with a four-stage handler chain: PreSend, Validation, Sending, and PostSend. Every fire or invoke call becomes a `Message` object routed through that chain. Each stage can inspect, modify, or drop the message before it reaches the network.

Stages are modular and config-driven: disable serialization, tracing, logging, or transport independently via `Config` flags without touching any call site. Pipeline integrates with a Registry module by accepting `registry` and `name` parameters in `Init`, or it can be used standalone by passing `nil` for registry.

---

## Features

**Routing:**
- [x] RemoteEvent-style objects: FireAllClients, FireClient, FireServer, Relay, OnServer, OnClient
- [x] RemoteFunction-style objects: InvokeServer, InvokeClient with OnServerInvoke / OnClientInvoke callbacks
- [x] P2P relay: skips the Validation stage, forwarded directly via Transport

**Pipeline internals:**
- [x] Four-stage pipeline: PreSend, Validation, Sending, PostSend with dropped-message short-circuit
- [x] Message batching at 20 Hz flush interval via BulkSender
- [x] Binary serialization: encodes args to buffer using 14 built-in Luau and Roblox types
- [x] Per-event sliding window rate limiter with configurable max calls and window duration
- [x] Type validation: per-message `paramTypes` declaration or dynamic type inference

**Observability:**
- [x] Structured logger per message, toggled by `Config.LoggerEnabled`
- [x] Trace span collection with configurable max and `Tracer:Drain()` API
- [x] Per-event count and drop counters with `Metrics:Snapshot()` API

**Extensibility:**
- [x] Custom type registration: `Validator:Register()` with Name, Tag, Check, Encode, Decode interface
- [x] Custom validation rules: `CustomValidation:Register()` with user-defined predicates
- [x] Config-driven toggling of every subsystem: serialization, tracing, logging, transport
- [x] Full Luau strict mode (`--!strict`) and `--!optimize 2` across all modules

---

## Installation

1. Download `Pipeline` from this repository.
2. Place the `Pipeline` folder in `ReplicatedStorage` or your shared module location.
3. Require it from your bootstrap script.

```lua
local Pipeline = require(game.ReplicatedStorage.Pipeline)
```

> [!NOTE]
> Call `Pipeline:Init()` before creating any events or functions. For standalone use without a Registry, pass `nil` as the first argument.

---

## Quick Start

### Server

```lua
-- ServerScriptService/Main.server.luau
--!strict

local Pipeline = require(game.ReplicatedStorage.Pipeline)
Pipeline:Init(nil, "Pipeline")

local DamageEvent = Pipeline:GetEvent("Damage")

-- Listen for client fires
DamageEvent:OnServer(function(player, amount)
    print(player.Name, "dealt", amount, "damage")
end)

-- Broadcast to all clients
DamageEvent:FireAllClients(100)
```

### Client

```lua
-- StarterPlayerScripts/ClientMain.client.luau
--!strict

local Pipeline = require(game.ReplicatedStorage.Pipeline)

local DamageEvent = Pipeline:GetEvent("Damage")

-- Fire the server
DamageEvent:FireServer(50)

-- Listen for server broadcasts
DamageEvent:OnClient(function(amount)
    print("Received damage:", amount)
end)
```

> [!IMPORTANT]
> Call `Pipeline:Init()` exactly once, on the server. The client-side Transport waits for the server's RemoteEvent to appear in ReplicatedStorage before connecting. Do not call Init twice on the same instance.

---

## API Reference

<details>
<summary><code>Pipeline:Init(registry, name)</code></summary>

Single lifecycle entry point. Wires all internal components: loads the Validator type registry, resets per-stage state, connects the BulkSender heartbeat flush, and sets up Transport remotes. Must be called once before any other method.

**Parameters:**
- `registry`: Registry instance, or `nil` for standalone use
- `name`: Registered name of this module (used for logging and tracing)

**Example:**
```lua
Pipeline:Init(nil, "Pipeline")
```
</details>

---

<details>
<summary><code>Pipeline:GetEvent(name: string): RemoteEventObject</code></summary>

Returns the named RemoteEvent-style object, creating it on first access. Subsequent calls with the same name return the cached object.

**Parameters:**
- `name`: Unique, non-empty string identifying the remote

**Returns:** `RemoteEventObject`

**RemoteEventObject methods:**

| Method | Context | Description |
|--------|---------|-------------|
| `FireAllClients(...)` | Server | Fires all connected clients |
| `FireClient(player, ...)` | Server | Fires a specific client |
| `FireServer(...)` | Client | Fires the server |
| `Relay(target, ...)` | Server | P2P relay, skips Validation stage |
| `OnServer(callback)` | Server | Listens for fires from any client. Returns `Connection` |
| `OnClient(callback)` | Client | Listens for fires from the server. Returns `Connection` |

**Example:**
```lua
local ChatEvent = Pipeline:GetEvent("Chat")

-- Server
ChatEvent:OnServer(function(player, message)
    ChatEvent:FireAllClients(player.Name, message)
end)

-- Client
ChatEvent:OnClient(function(name, message)
    print(name .. ": " .. message)
end)
ChatEvent:FireServer("Hello!")
```
</details>

---

<details>
<summary><code>Pipeline:GetFunction(name: string): RemoteFunctionObject</code></summary>

Returns the named RemoteFunction-style object, creating it on first access.

**Parameters:**
- `name`: Unique, non-empty string identifying the remote function

**Returns:** `RemoteFunctionObject`

**RemoteFunctionObject properties and methods:**

| Member | Context | Description |
|--------|---------|-------------|
| `OnServerInvoke` | Server | Assign a function `(player, ...) -> ...` to handle invocations from clients |
| `OnClientInvoke` | Client | Assign a function `(...) -> ...` to handle invocations from the server |
| `InvokeServer(...)` | Client | Invokes the server handler. Returns results |
| `InvokeClient(player, ...)` | Server | Invokes a specific client's handler. Returns results |

**Example:**
```lua
local GetDataFn = Pipeline:GetFunction("GetData")

-- Server
GetDataFn.OnServerInvoke = function(player, key)
    return DataStore:Get(player, key)
end

-- Client
local value = GetDataFn:InvokeServer("coins")
print("Coins:", value)
```
</details>

---

<details>
<summary><code>Pipeline:GetPipeline(): Pipeline</code></summary>

Returns the pipeline table (stage name to list of handler slots). Treat as read-only. Useful for debugging handler counts per stage.

**Example:**
```lua
local pipeline = Pipeline:GetPipeline()
for stage, slots in pairs(pipeline) do
    print(stage, #slots, "handlers")
end
```
</details>

---

<details>
<summary><code>Connection:Disconnect()</code></summary>

Disconnects an `OnServer` or `OnClient` callback registered via `GetEvent`.

**Example:**
```lua
local connection = DamageEvent:OnClient(function(amount)
    print(amount)
end)

-- Later:
connection:Disconnect()
```
</details>

---

## Configuration

Edit `Config` values before calling `Pipeline:Init()`. All options are in `src/Pipeline/Core/Config.luau`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `UUIDMode` | number | `0` | Message ID generation: 0 = off, 1 = counter, 2 = RFC GUID |
| `LoggerEnabled` | boolean | `false` | Structured per-message logging to output |
| `SerializerEnabled` | boolean | `true` | Binary buffer encoding of message args |
| `TracerEnabled` | boolean | `false` | Trace span collection per message |
| `TracerMaxSpans` | number | `1000` | Maximum spans held before new ones are dropped |
| `RateMaxCalls` | number | `600000` | Maximum fires allowed per event per window |
| `RateWindowSeconds` | number | `1.0` | Sliding window duration in seconds |
| `TransportEnabled` | boolean | `true` | Enable Roblox RemoteEvent/RemoteFunction transport |

```lua
local Config = require(game.ReplicatedStorage.Pipeline.Core.Config)

Config.UUIDMode = 1
Config.TracerEnabled = false
Config.RateMaxCalls = 100

Pipeline:Init(nil, "Pipeline")
```

> [!TIP]
> Set `Config.TransportEnabled = false` during unit testing or offline development to avoid errors from missing Roblox remotes.

---

## Advanced Usage

### Custom Types

Register types beyond the 14 built-ins by implementing the `TypeModule` interface and calling `Validator:Register()`. Each type must provide a unique `Tag` integer that does not collide with built-in tags 1-14.

```lua
local Validator = require(game.ReplicatedStorage.Pipeline.Stages.Validation.Validator)

Validator:Register({
    Name = "MyType",
    Tag = 20, -- must not be 1-14 (reserved for built-ins)

    Check = function(value)
        return typeof(value) == "userdata" -- your type guard
    end,

    Encode = function(buf, cursor, value)
        -- write value into buf starting at cursor
        -- return next cursor position
        return cursor
    end,

    Decode = function(buf, cursor)
        -- read value from buf at cursor
        -- return value, next cursor position
        return nil, cursor
    end,
})
```

> [!NOTE]
> Call `Validator:Register()` before `Pipeline:Init()`. Built-ins are loaded during Init via `Validator:LoadBuiltIns()`.

---

### Custom Validation Rules

Register per-message predicates that run during the Validation stage. Returning `false` drops the message and increments its drop counter in Metrics.

```lua
local CustomValidation = require(game.ReplicatedStorage.Pipeline.Stages.Validation.CustomValidation)

CustomValidation:Register(function(network, message)
    -- Drop messages with no arguments
    return #message.args > 0
end)
```

> [!WARNING]
> Validation predicates run on every message that passes through the Validation stage. Keep them fast. Heavy operations here will stall the pipeline under high fire rates.

---

### Metrics and Tracing

**Metrics** tracks successful and dropped fires per event name:

```lua
local Metrics = require(game.ReplicatedStorage.Pipeline.Stages.PostSend.Metrics)

local snapshot = Metrics:Snapshot()
-- snapshot.counts["Damage"] -> number of successful fires
-- snapshot.drops["Damage"]  -> number of dropped fires

for name, count in pairs(snapshot.counts) do
    print(name, "sent:", count, "dropped:", snapshot.drops[name] or 0)
end
```

**Tracer** collects a span record for each message:

```lua
local Tracer = require(game.ReplicatedStorage.Pipeline.Stages.PostSend.Tracer)

local spans = Tracer:Drain() -- returns and clears all spans
for _, span in spans do
    local duration = span.endedAt - span.startedAt
    print(span.name, string.format("%.4f", duration), "s", span.dropped and "(dropped)" or "")
end
```

> [!NOTE]
> `Tracer:Drain()` clears the span buffer. Call it on a timer and process spans asynchronously to avoid stalling the pipeline.

---

## Project Structure

```
src/Pipeline/
├── init.luau              -- Network entry point, pipeline builder, event/function factories
├── Core/
│   ├── Config.luau        -- All feature flags and tuning constants
│   ├── Serializer.luau    -- Buffer encoding dispatcher over the Validator type registry
│   └── StateManager.luau  -- Shared pending-message and channel state helpers
├── Stages/
│   ├── init.luau          -- Stage registry (ordered Entries table)
│   ├── PreSend/
│   │   ├── RateLimiter.luau        -- Sliding window rate limiter
│   │   ├── NetworkedObjects.luau   -- Instance ID registry for serialization
│   │   └── PlayerRegistry.luau    -- Connected player tracking
│   ├── Validation/
│   │   ├── Validator.luau          -- Type registry and per-message validation
│   │   ├── CustomValidation.luau   -- User-defined predicate rules
│   │   └── Types/                  -- 14 built-in type modules
│   ├── Sending/
│   │   ├── BulkSender.luau         -- 20 Hz batching queue
│   │   ├── Transport.luau          -- Roblox RemoteEvent/RemoteFunction bridge
│   │   ├── Dispatcher.luau         -- Local message routing and result capture
│   │   └── P2PRelay.luau           -- Relay forwarding (bypasses Validation)
│   └── PostSend/
│       ├── Logger.luau             -- Structured per-message log
│       ├── Tracer.luau             -- Span collection with Drain() API
│       └── Metrics.luau            -- Count and drop counters with Snapshot() API
└── Utilities/
    ├── UUID.luau           -- ID generation (off / counter / RFC GUID)
    └── Promise.luau        -- Async helper with All and AllSettled
```

---

## Best Practices

> [!IMPORTANT]
> Call `Pipeline:Init()` exactly once, before creating any events or functions. Building events before Init completes means the pipeline table is not yet built and handlers will not run.

> [!TIP]
> Reuse event and function objects. `GetEvent` and `GetFunction` cache by name: calling them multiple times with the same name returns the same object at no extra cost.

> [!TIP]
> For type-safe messages, set `message.paramTypes` at call sites or enforce invariants through `CustomValidation:Register()` rather than trusting raw argument positions at runtime.

> [!NOTE]
> Relay messages bypass the Validation stage by design. Use `Relay` only for trusted server-to-client forwarding where the payload has already been validated upstream.

> [!TIP]
> Disable `Config.SerializerEnabled` if nothing in your pipeline reads `message.encoded`. The encoding step has non-trivial cost at high fire rates and produces no benefit unless a downstream handler consumes the buffer.

> [!WARNING]
> `Tracer:Drain()` clears the span buffer. Calling it on every message would defeat the purpose. Drain on a heartbeat or a timer and process spans off the critical path.

---

## License

This project is open source and available under the [CC0 1.0 Universal License](LICENSE).

Feel free to use, modify, and share this in your projects.

---

## Support

If you find Pipeline helpful, consider sharing it with other Roblox developers or contributing improvements back to the project.

<div align="center">
    <a href="https://www.roblox.com/users/3294832549/profile">
        <img src="https://img.shields.io/badge/Follow%20On%20Roblox-000000?style=for-the-badge&logo=roblox&logoColor=white"></a>
    <a href="https://github.com/sponsors/Kooraseru">
        <img src="https://img.shields.io/badge/Sponsor%20On%20Github-blue?style=for-the-badge&logo=githubsponsors&logoColor=white"></a>
    <a href="https://github.com/Kooraseru-Hub/Pipeline/issues">
        <img src="https://img.shields.io/badge/Report%20Issues-F36D5D?style=for-the-badge&logo=github&logoColor=white"></a>
    <a href="CONTRIBUTING.md">
        <img src="https://img.shields.io/badge/Contribute-ffb703?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGhlaWdodD0iNDBweCIgdmlld0JveD0iMCAtOTYwIDk2MCA5NjAiIHdpZHRoPSI0MHB4IiBmaWxsPSIjM2U0MjQ1Ij48cGF0aCBkPSJNNjI3LjMzLTU5NS40cS0xOC42Ni0xOS40LTE4LjY2LTQ2LjE3IDAtMjYuNzYgMTguODQtNDQuOTMgMTguODQtMTguMTcgNDUuMjctMTguMTcgMjYuNDQgMCA0NS40OSAxOC4zNSAxOS4wNiAxOC4zNCAxOS4wNiA0NS4xIDAgMjYuNzctMTkuMjMgNDUuOTlRNjk4Ljg2LTU3NiA2NzIuNDMtNTc2cS0yNi40MyAwLTQ1LjEtMTkuNFptLTM4NS4yNyAwcS0xOC43My0xOS40LTE4LjczLTQ2LjE3IDAtMjYuNzYgMTguOTEtNDQuOTMgMTguOS0xOC4xNyA0NS4zMy0xOC4xN3Q0NS4xIDE4LjM1cTE4LjY2IDE4LjM0IDE4LjY2IDQ1LjEgMCAyNi43Ny0xOC44NCA0NS45OVEzMTMuNjUtNTc2IDI4Ny4yMi01NzZxLTI2LjQ0IDAtNDUuMTYtMTkuNFptMTkyLjI3IDExOC4yMlE0MTYtNDk1LjM1IDQxNi01MjIuNDV0MTguNTEtNDYuMzJRNDUzLjAyLTU4OCA0ODAuMTgtNTg4cTI3LjE1IDAgNDUuODIgMTkuNHQxOC42NyA0Ni41cTAgMjcuMS0xOC44NSA0NS4xLTE4Ljg0IDE4LTQ2IDE4LTI3LjE1IDAtNDUuNDktMTguMThabTAtMjM2UTQxNi03MzIuMDIgNDE2LTc1OC44NHEwLTI2LjgzIDE4LjUxLTQ1LjQ5UTQ1My4wMi04MjMgNDgwLjE4LTgyM3EyNy4xNSAwIDQ1LjgyIDE4Ljg0IDE4LjY3IDE4Ljg1IDE4LjY3IDQ1LjY3VDUyNS44Mi03MTNxLTE4Ljg0IDE4LjY3LTQ2IDE4LjY3LTI3LjE1IDAtNDUuNDktMTguODVabTMuNDMgNTcyLjlxLTIyLjI0LTMuMjgtNDIuMDktNy43di0xNTQuMjRxMC0zNy40NiAyMy45NS02NC43OSAyMy45Ni0yNy4zMiA2MC4zNC0yNy4zMiAzNi4zNyAwIDYwLjcxIDI3LjMyUTU2NS0zMzkuNjggNTY1LTMwMi4yMnYxNTQuMjRxLTIwLjUyIDQuNDItNDIuNzMgNy43LTIyLjIyIDMuMjgtNDIuMjUgMy4yOC0yMC4wMiAwLTQyLjI2LTMuMjhaTTMzMS42Ny0xNzJxLTIwLjYzLTcuNS00MS41NC0xOC42MS0yMC45MS0xMS4xMi0zNy40My0yMy41My0zMC41Mi0yMC4wNy00OC4yNy01NC4yOC0xNy43Ni0zNC4yMS0xNy43Ni03NC41OCAwLTI3LjE0LTUuNjctNTIuMjMtNS42Ny0yNS4xLTIwLjMzLTQ2LjEtMTEuMDktMTMuMzYtNDEuNzYtNDEuODRRODguMjQtNTExLjY2IDY1LjMzLTUzNSA1Mi01NDkgNTItNTY1LjgzcTAtMTYuODQgMTIuODMtMzAuMTcgMTIuODQtMTQgMzAtMTQgMTcuMTcgMCAzMC41IDE0bDE2NC44NSAxNTQuNjdxMTkuNDkgMTkuNjYgMzAuNDkgNDYgMTEgMjYuMzMgMTEgNTQuNjZWLTE3MlpNNjI5LTE3MnYtMTY4LjY3cTAtMjguMzMgMTIuNDktNTQuOTggMTIuNS0yNi42NCAzMi43Ny00NS4ybDE2MC41OC0xNTUuNDJxMTIuNDktMTIuNCAzMC42Ni0xMi4wNiAxOC4xNy4zMyAzMC4zMyAxMi4zM1E5MDgtNTgyLjY3IDkwOC01NjUuODMgOTA4LTU0OSA4OTUuMzMtNTM1cS0yMy41NyAyMy4zNC01NC4yNCA1MS4wNC0zMC42NyAyNy43MS00MS4wOSA0Mi42My0xNS4zMyAyMS42Ni0yMC42NyA0Ni4zM1E3NzQgLTM0MCA3NzQtMzEzLjA4cTAgNDAuNTUtMTguMTcgNzQuNzMtMTguMTYgMzQuMTktNDguNTQgNTQuNTQtMTcuOTQgMTIuNTYtMzguMDMgMjMuNFE2NDkuMTgtMTc5Ljc0IDYyOS0xNzJaIi8+PC9zdmc+"></a>
</div>
