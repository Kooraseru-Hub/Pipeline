# Pipeline

A small, middleware-first networking layer for Roblox.

Pipeline routes messages through one reliable `RemoteEvent` and one `UnreliableRemoteEvent`. It provides channel routing and composable middleware, then gets out of the way. There is no built-in serializer, scheduler, logger, tracer, rate limiter, registry, or RPC framework.

## Design

- **No middleware:** send and receive use native remote varargs without allocating a packet table.
- **With middleware:** a context is allocated only for the affected direction, and the chain is compiled when handlers are registered.
- **No forced batching:** Roblox handles its own network scheduling. Pipeline adds no artificial 20 Hz delay.
- **Explicit channels:** choose an integer ID between `0` and `65535`, and use the same ID and lane on both sides.
- **Explicit ownership:** `Pipeline.new()` creates/connects the transport; `:Destroy()` disconnects it. Requiring the module has no side effects.

The core makes no claim to outperform native remotes in every workload. Its job is to keep the overhead of middleware optional and observable.

## Install

Place the `src/Pipeline` folder in `ReplicatedStorage` as a ModuleScript named `Pipeline`, with `Middleware` as its child ModuleScript.

### Server

```luau
-- ServerScriptService/Networking.server.luau
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pipeline = require(ReplicatedStorage.Pipeline)

local network, reason = Pipeline.new()
if not network then
	error(reason or "Pipeline startup failed")
end

local damage, channelReason = network:Channel(1)
if not damage then
	error(channelReason or "Damage channel failed")
end

damage:Use("receive", function(context, next)
	local amount = context.values[1]
	if typeof(amount) ~= "number" or amount < 0 or amount > 100 then
		return
	end

	next(context)
end)

damage:Connect(function(player, amount)
	print(player, amount)
end)

-- damage:FireClient(player, 10)
-- damage:FireAllClients(10)
```

### Client

```luau
-- StarterPlayerScripts/Networking.client.luau
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pipeline = require(ReplicatedStorage.Pipeline)

local network, reason = Pipeline.new()
if not network then
	error(reason or "Pipeline startup failed")
end

local damage, channelReason = network:Channel(1)
if not damage then
	error(channelReason or "Damage channel failed")
end

damage:FireServer(10)
```

Create the same channel ID and lane on the server and client. A channel has one receiver, registered with `:Connect()`; a subsequent registration replaces the previous receiver. `:Disconnect()` clears it.

## Middleware

Middleware is just a function receiving the context and the next handler.

```luau
channel:Use("send", function(context, next)
	-- Called before the message is sent.
	next(context)
	-- Called after the downstream handler returns.
end)
```

Use `network:Use(direction, handler)` for every channel or `channel:Use(direction, handler)` for one channel. Directions are `"send"` and `"receive"`. Global handlers run first, followed by channel handlers, in registration order.

The context contains:

| Field | Meaning |
| --- | --- |
| `id` | Numeric channel ID |
| `lane` | `"reliable"` or `"unreliable"` |
| `direction` | `"send"` or `"receive"` |
| `sender` | Sending `Player` on server receives; otherwise `nil` |
| `target` | Destination `Player` for targeted sends |
| `broadcast` | Whether the send targets all clients |
| `values` | Mutable array of arguments |
| `count` | Argument count, including trailing `nil` values |

Middleware can inspect or modify `values`, replace `count`, omit `next(context)` to drop a message, or execute work after the downstream handler returns. Call `next` at most once. Keep handlers synchronous and cheap on hot paths.

To create an unreliable channel:

```luau
local movement, reason = network:Channel(2, "unreliable")
if movement then
	movement:FireServer(1, 2, 3)
end
```

Unreliable messages may be dropped or reordered. Roblox currently drops unreliable payloads larger than 1,000 bytes and rate-limits client-to-server remote calls. Pipeline does not promise to alter those engine limits.

## API

| Method | Purpose |
| --- | --- |
| `Pipeline.new(namespace?, container?)` | Create or connect to two namespaced remotes; returns `network?, error?` |
| `network:Channel(id, lane?)` | Get or create a channel; defaults to reliable |
| `network:Use(direction, middleware)` | Register middleware for all channels |
| `channel:Use(direction, middleware)` | Register channel-specific middleware |
| `channel:Connect(callback)` | Register the channel's receiver |
| `channel:Disconnect()` | Remove the receiver |
| `channel:FireServer(...)` | Client to server |
| `channel:FireClient(player, ...)` | Server to one client |
| `channel:FireAllClients(...)` | Server broadcast |
| `network:Destroy()` | Disconnect; destroy remotes only when server-owned |

If you provide a namespace, both sides must use the same name. The server fails initialization when matching remotes already exist, avoiding accidental ownership of someone else's transport. Client construction waits up to 20 seconds for the server's remotes.

### Security and tradeoffs

- Client-supplied payloads are untrusted. Validate and rate-limit them in receive middleware before executing authoritative gameplay logic.
- Pipeline intentionally does not serialize or compress arguments. Add serialization as middleware only when measurements justify its CPU, allocation, and bandwidth costs.
- Global middleware applies to every matching direction, including channels created after registration.
- There is no implicit request-response abstraction. Use Roblox's `RemoteFunction` directly or build a separate middleware-based protocol if needed.
- Do not use unreliable channels for state changes requiring guaranteed delivery or ordering.

## Tests

```bash
node tests/run.mjs
luau-compile src/Pipeline/init.luau src/Pipeline/Middleware.luau > /dev/null
```

The tests use Luau CLI and a minimal mock transport. Run a Studio client/server test as well before a release.

## License

[CC0 1.0 Universal](LICENSE).
