-- Shared/Pipeline/Utilities/Promise.luau
--!strict
--!optimize 2
--!native

export type PromiseState = "pending" | "resolved" | "rejected" | "cancelled"

export type Promise = {
	state: PromiseState,
	value: any,
	callbacks: { (any) -> () },
	catches: { (any) -> () },

	AndThen: (self: Promise, onResolved: (any) -> any) -> Promise,
	Catch: (self: Promise, onRejected: (any) -> any) -> Promise,
	Cancel: (self: Promise) -> (),
}

local Promise = {}
Promise.__index = Promise

local function settle(self: Promise, state: PromiseState, value: any)
	if self.state ~= "pending" then
		return
	end
	self.state = state
	self.value = value

	if state == "cancelled" then
		return
	end

	local list = if state == "resolved" then self.callbacks else self.catches
	for i = 1, #list do
		list[i](value)
	end
end

--[[
	Creates a new Promise. The executor is invoked immediately with resolve
	and reject functions.

	@param executor ((any) -> (), (any) -> ()) -> () Callback run at creation.
	@return Promise Newly created promise.
]]
function Promise.new(executor: ((any) -> (), (any) -> ()) -> ()): Promise
	local self = setmetatable({}, Promise) :: Promise
	self.state = "pending"
	self.value = nil
	self.callbacks = {}
	self.catches = {}

	local function resolve(value: any)
		settle(self, "resolved", value)
	end
	local function reject(err: any)
		settle(self, "rejected", err)
	end

	executor(resolve, reject)
	return self
end

--[[
	Registers a callback for the resolved value. Returns a new child Promise
	that resolves with the return value of onResolved, enabling chaining.
	If the promise is rejected or cancelled, the rejection propagates to
	the child.

	@param onResolved (any) -> any Callback invoked with the resolved value.
	@return Promise Child promise.
]]
function Promise:AndThen(onResolved: (any) -> any): Promise
	local child = Promise.new(function(resolve, reject)
		local function handler(value: any)
			local ok, result = pcall(onResolved, value)
			if ok then
				resolve(result)
			else
				reject(result)
			end
		end

		if self.state == "resolved" then
			handler(self.value)
		elseif self.state == "pending" then
			self.callbacks[#self.callbacks + 1] = handler
		else
			reject(self.value)
		end
	end)
	return child
end

--[[
	Registers a callback for the rejected value. Returns a new child Promise
	that resolves with the return value of onRejected. If the parent is
	resolved, the resolved value propagates to the child.

	@param onRejected (any) -> any Callback invoked with the rejection reason.
	@return Promise Child promise.
]]
function Promise:Catch(onRejected: (any) -> any): Promise
	local child = Promise.new(function(resolve, reject)
		local function handler(value: any): ()
			local ok, result = pcall(onRejected, value)
			if ok then
				resolve(result)
			else
				reject(result)
			end
		end

		if self.state == "rejected" then
			handler(self.value)
		elseif self.state == "pending" then
			self.catches[#self.catches + 1] = handler
		else
			resolve(self.value)
		end
	end)
	return child
end

--[[
	Cancels the promise. A cancelled promise will not invoke any AndThen
	or Catch callbacks.
]]
function Promise:Cancel()
	settle(self :: Promise, "cancelled", nil)
end

--[[
	Returns a Promise that resolves with an ordered array of values once all
	input promises resolve. Rejects immediately if any input promise rejects.

	@param promises { Promise } Array of promises to wait on.
	@return Promise Promise resolving to { any }.
]]
function Promise.All(promises: { Promise }): Promise
	return Promise.new(function(resolve, reject)
		if #promises == 0 then
			resolve({})
			return
		end

		local results: { any } = table.create(#promises)
		local remaining: number = #promises
		local settled: boolean = false

		for i = 1, #promises do
			local index: number = i
			promises[i]:AndThen(function(value: any): ()
				if not settled then
					results[index] = value
					remaining -= 1
					if remaining == 0 then
						settled = true
						resolve(results)
					end
				end
			end):Catch(function(err: any): ()
				if not settled then
					settled = true
					reject(err)
				end
			end)
		end
	end)
end

--[[
	Returns a Promise that always resolves once all input promises settle,
	regardless of whether they resolved or rejected. The resolved value is
	an ordered array of { status: string, value: any } records.

	@param promises { Promise } Array of promises to wait on.
	@return Promise Promise resolving to { { status: string, value: any } }.
]]
function Promise.AllSettled(promises: { Promise }): Promise
	return Promise.new(function(resolve, _reject)
		if #promises == 0 then
			resolve({})
			return
		end

		type SettledResult = { status: string, value: any }
		local results: { SettledResult } = table.create(#promises) :: { SettledResult }
		local remaining: number = #promises

		local function onSettled(index: number, status: string, value: any)
			results[index] = { status = status, value = value }
			remaining -= 1
			if remaining == 0 then
				resolve(results)
			end
		end

		for i = 1, #promises do
			local index = i
			promises[i]:AndThen(function(value: any)
				onSettled(index, "resolved", value)
				return
			end):Catch(function(err: any): any
				onSettled(index, "rejected", err)
				return
			end)
		end
	end)
end

return Promise
