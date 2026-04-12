-- Shared/Pipeline/Stages/Sending/Dispatcher.luau
--!strict
--!optimize 2

local Dispatcher = {}

--[[
	Routes the message to its destination based on message.kind. Event kinds
	fire the matching signal on the named event object; function kinds run
	the assigned OnServerInvoke / OnClientInvoke callback and store the
	packed return values on message.results. Relay messages are no-ops here
	— relay routing happens in P2PRelay.

	@param network Network Active Network instance.
	@param message Message Pipeline message being dispatched.
]]
function Dispatcher:Handle(network: any, message: any)
	if message.dropped or message.batched then
		return
	end

	local kind: string = message.kind

	if kind == "Relay" then
		return
	end

	if kind == "FireServer" then
		local event = network.events[message.name]
		if not event then
			message.dropped = true
			return
		end
		event.OnServerEvent:Fire(table.unpack(message.args))
		return
	end

	if kind == "FireAllClients" or kind == "FireClient" then
		local event = network.events[message.name]
		if not event then
			message.dropped = true
			return
		end
		event.OnClientEvent:Fire(table.unpack(message.args))
		return
	end

	if kind == "InvokeServer" then
		local fn = network.functions[message.name]
		if not fn or not fn.OnServerInvoke then
			message.dropped = true
			return
		end
		message.results = table.pack((fn.OnServerInvoke :: any)(message.target, table.unpack(message.args)))
		return
	end

	if kind == "InvokeClient" then
		local fn = network.functions[message.name]
		if not fn or not fn.OnClientInvoke then
			message.dropped = true
			return
		end
		message.results = table.pack((fn.OnClientInvoke :: any)(table.unpack(message.args)))
		return
	end

	message.dropped = true
end

return Dispatcher
