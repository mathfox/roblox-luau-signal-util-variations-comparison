local freeRunnerThread = nil

-- creates a new thread if existing one is busy or not exist
local function acquireRunnerThreadAndCallEventHandler(fn: (...any) -> ...any, ...: any)
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
ConnectionPrototype.__index = ConnectionPrototype

function ConnectionPrototype:Disconnect()
	if not self._connected then
		return
	else
		self._connected = false

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

function Connection.new(signal, fn: (...any) -> ...any)
	local self = setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
	}, ConnectionPrototype)

	return self
end

local SignalPrototype = {}
SignalPrototype.__index = SignalPrototype

function SignalPrototype:Connect(fn: (...any) -> ...any)
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
		if connection._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end

			task.spawn(freeRunnerThread, connection._fn, ...)
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

SignalPrototype.fire = SignalPrototype.Fire
SignalPrototype.connect = SignalPrototype.Connect
SignalPrototype.wait = SignalPrototype.Wait
SignalPrototype.destroy = SignalPrototype.Destroy

local Signal = {}

function Signal.new()
	local self = setmetatable({}, SignalPrototype)

	return self
end

function Signal.is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == SignalPrototype
end

return Signal
