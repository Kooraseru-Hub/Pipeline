-- Shared/Pipeline/Stages/Sending/BulkSender.luau
--!strict
--!optimize 2

local BulkSender = {}
BulkSender.type = "BulkSender"
BulkSender.queue = {} :: { any }
BulkSender.lastFlush = 0
BulkSender.network = nil :: any
BulkSender.flushHook = nil :: (({ any }) -> ())?

--[[
	Records the message in the batch queue and marks it as batched so
	Dispatcher skips synchronous delivery. Invoke kinds bypass batching.

	@param network Network Active Network instance.
	@param message Message Pipeline message being observed.
]]
function BulkSender:Handle(network: any, message: any)
	local kind: string = message.kind
	if kind == "InvokeServer" or kind == "InvokeClient" then
		return
	end
	if self.network == nil then
		self.network = network
	end
	message.batched = true
	self.queue[#self.queue + 1] = message
end

--[[
	Drains and returns the pending batch queue. When a flush hook is set
	(by Transport during Pipeline:Init), delivery is delegated to it.
	Otherwise messages are fired locally on their matching signals.

	@return { any } All queued messages at call time.
]]
function BulkSender:Flush(): { any }
	local drained: { any } = self.queue
	self.queue = {}
	self.lastFlush = os.clock()

	local flushHook = self.flushHook
	if flushHook then
		flushHook(drained)
		return drained
	end

	local network = self.network
	if network == nil then
		return drained
	end

	for i = 1, #drained do
		local msg = drained[i]
		if not msg.dropped then
			local kind: string = msg.kind
			if kind == "FireServer" or kind == "FireClient" then
				local event = network.events[msg.name] :: any
				if event then
					event.OnServerEvent:Fire(table.unpack(msg.args))
				end
			elseif kind == "FireAllClients" then
				local event = network.events[msg.name] :: any
				if event then
					event.OnClientEvent:Fire(table.unpack(msg.args))
				end
			end
		end
	end

	return drained
end

return BulkSender
