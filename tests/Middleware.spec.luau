-- tests/Middleware.spec.luau
--!strict

--# Modules

local Middleware = require("../src/Pipeline/Middleware")

--# Helpers

local function expect(condition: boolean, message: string)
	if not condition then
		error(message)
	end
end

--# Tests

local steps: { string } = {}
local terminalCalls = 0

local first: Middleware.Handler = function(context, next)
	steps[#steps + 1] = "first:before"
	next(context)
	steps[#steps + 1] = "first:after"
end

local second: Middleware.Handler = function(context, next)
	steps[#steps + 1] = "second:before"
	context.values[1] = "modified"
	next(context)
	steps[#steps + 1] = "second:after"
end

local terminal: Middleware.Next = function(context)
	terminalCalls += 1
	expect(context.values[1] == "modified", "middleware did not mutate the packet")
	expect(context.count == 3, "packet argument count was changed")
	expect(context.values[2] == nil, "nil argument was not preserved")
	expect(context.values[3] == "last", "argument following nil was lost")
	steps[#steps + 1] = "terminal"
end

local context: Middleware.Context = {
	id = 1,
	lane = "reliable",
	direction = "send",
	sender = nil,
	target = nil,
	broadcast = false,
	values = { "first", nil, "last" },
	count = 3,
}

Middleware.Compose({ first, second }, terminal)(context)

local expected = {
	"first:before",
	"second:before",
	"terminal",
	"second:after",
	"first:after",
}

for index, name in expected do
	expect(steps[index] == name, `Incorrect middleware execution order at {index}`)
end

expect(terminalCalls == 1, "terminal should be called exactly once")
expect(Middleware.Compose({}, terminal) == terminal, "empty middleware chain added a wrapper")

local blocked = Middleware.Compose({
	function()
		-- Omitting next prevents the terminal from running.
	end,
}, terminal)

blocked(context)
expect(terminalCalls == 1, "short-circuited middleware reached the terminal")

print("Middleware tests passed")
