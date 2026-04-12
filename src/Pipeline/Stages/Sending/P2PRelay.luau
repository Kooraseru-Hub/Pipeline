-- Shared/Pipeline/Stages/Sending/P2PRelay.luau
--!strict
--!optimize 2

local P2PRelay = {}

--[[
	Routes Relay-kind messages to the target peer. There is no live
	transport for relays; the message surfaces locally by firing the named
	event's OnClientEvent signal — which is the same channel a real
	cross-client delivery would land on. Non-relay messages are ignored here
	and handled by Dispatcher.

	@param network Network Active Network instance.
	@param message Message Pipeline message being routed.
]]
function P2PRelay:Handle(network: any, message: any)
	if message.dropped or not message.isRelay then
		return
	end

	local event = network.events[message.name]
	if not event then
		message.dropped = true
		return
	end

	event.OnClientEvent:Fire(table.unpack(message.args))
end

return P2PRelay
