type Function = (...any) -> ...any

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler(fn: Function, ...: any)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)

	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local ConnectionPrototype = {}
ConnectionPrototype.Connected = true
ConnectionPrototype.__index = ConnectionPrototype

function ConnectionPrototype:Disconnect()
	if not self.Connected then
		return
	else
		self.Connected = false

		if self._signal._previous == self then
			self._signal._previous = self._previous
		else
			local current = self._signal._previous

			while current and current._previous ~= self do
				current = current._previous
			end

			if current then
				current._previous = self._previous
			end
		end
	end
end

ConnectionPrototype.disconnect = ConnectionPrototype.Disconnect

local Connection = {}

function Connection.new(signal: Signal, fn: Function): Connection
	local constructor: {
		Connected: boolean,
		_signal: Signal,
		_fn: Function,
		_previous: Connection?,
	} = {
		_signal = signal,
		_fn = fn,
	}

	local self = setmetatable(constructor, ConnectionPrototype)

	return self
end

local SignalPrototype = {}
SignalPrototype.__index = SignalPrototype

function SignalPrototype:Connect(fn: Function): Connection
	local connection = Connection.new(self, fn)

	if self._previous then
		connection._previous = self._previous

		self._previous = connection
	else
		self._previous = connection
	end

	return connection
end

function SignalPrototype:Fire(...: any)
	local connection = self._previous

	while connection do
		if connection.Connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end

			task.spawn(freeRunnerThread :: thread, connection._fn, ...)
		end

		connection = connection._previous
	end
end

function SignalPrototype:Wait(): ...any
	local waitingCoroutine = coroutine.running()

	local connection
	connection = self:Connect(function(...: any)
		connection:Disconnect()

		task.spawn(waitingCoroutine, ...)
	end)

	return coroutine.yield()
end

function SignalPrototype:Destroy()
	self._previous = nil
end

SignalPrototype.connect = SignalPrototype.Connect
SignalPrototype.fire = SignalPrototype.Fire
SignalPrototype.wait = SignalPrototype.Wait
SignalPrototype.destroy = SignalPrototype.Destroy

local Signal = {}

function Signal.new(): Signal
	local constructor: {
		_previous: Connection?,
	} = {}

	local self = setmetatable(constructor, SignalPrototype)

	return self
end

export type Signal = typeof(Signal.new())
export type Connection = typeof(Connection.new(Signal.new(), function() end))

function Signal.is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == SignalPrototype
end

return Signal
