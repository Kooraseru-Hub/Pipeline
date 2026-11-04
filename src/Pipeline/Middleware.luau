-- src/Pipeline/Middleware.luau
--!strict

--# Types

export type Direction = "send" | "receive"
export type Lane = "reliable" | "unreliable"

export type Context = {
	id: number,
	lane: Lane,
	direction: Direction,
	sender: Player?,
	target: Player?,
	broadcast: boolean,
	values: { unknown },
	count: number,
}

export type Next = (context: Context) -> ()
export type Handler = (context: Context, next: Next) -> ()

--# Functions

local Middleware = {}

-- Compose once when middleware is registered, never while dispatching a packet.
function Middleware.Compose(handlers: { Handler }, terminal: Next): Next
	local nextHandler = terminal

	for index = #handlers, 1, -1 do
		local handler = handlers[index]
		local downstream = nextHandler

		nextHandler = function(context: Context)
			handler(context, downstream)
		end
	end

	return nextHandler
end

return Middleware
