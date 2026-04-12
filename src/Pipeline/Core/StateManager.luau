-- Shared/Pipeline/Core/StateManager.luau
--!strict
--!optimize 2
--!native

export type PendingEntry = {
	name: string,
	args: { any },
	queuedAt: number,
}

local StateManager = {}
StateManager.pendingMessages = {} :: { PendingEntry }
StateManager.activeChannels = {} :: { [string]: boolean }

--[[
	Appends a pending message entry to the queue.

	@param entry PendingEntry Message queued for later processing.
]]
function StateManager:QueuePending(entry: PendingEntry)
	self.pendingMessages[#self.pendingMessages + 1] = entry
end

--[[
	Drains and returns the pending message queue, leaving state empty.

	@return { PendingEntry } All queued entries at call time.
]]
function StateManager:DrainPending(): { PendingEntry }
	local drained: { PendingEntry } = self.pendingMessages
	self.pendingMessages = {}
	return drained
end

--[[
	Marks a channel as active or inactive.

	@param channel string Channel identifier.
	@param active boolean Whether the channel should be flagged active.
]]
function StateManager:SetChannelActive(channel: string, active: boolean)
	self.activeChannels[channel] = active or nil
end

return StateManager
