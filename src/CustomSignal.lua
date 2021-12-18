local HttpService = game:GetService("HttpService")

local Prototype = {}

function Prototype:Fire(...: any)
	if not self._bindableEvent then
		error("signal was destroyed", 2)
	end

	local args = table.pack(...)

	local key = HttpService:GenerateGUID(false)
	self._argMap[key] = args

	self._bindableEvent:Fire(key)
end

function Prototype:Connect(callback: (...any) -> ...any): RBXScriptConnection
	if not self._bindableEvent then
		error("signal was destroyed", 2)
	elseif type(callback) ~= "function" then
		error("#1 argument must be a function!", 2)
	end

	return self._bindableEvent.Event:Connect(function(key: string)
		if not self._bindableEvent then
			error("signal was destroyed", 2)
		end

		local args = self._argMap[key]
		if args then
			callback(table.unpack(args, 1, args.n))
		else
			error("missing arg data, probably due to reentrance")
		end
	end)
end

function Prototype:Wait(): ...any
	local key = self._bindableEvent.Event:Wait()
	local args = self._argMap[key]
	if not args then
		error("missing arg data, probably due to reentrance")
	end

	return table.unpack(args, 1, args.n)
end

function Prototype:Destroy()
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
end

local Signal = {}
Signal.__index = Prototype

function Signal.is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == Signal
end

local function new()
	local self = setmetatable({}, Signal)

	self._bindableEvent = Instance.new("BindableEvent")
	self._argMap = {}

	self._bindableEvent.Event:Connect(function(key: string)
		self._argMap[key] = nil

		if not self._bindableEvent and (not next(self._argMap)) then
			self._argMap = nil
		end
	end)

	return self
end

export type Signal = typeof(new())

function Signal.new(): Signal
	return new()
end

Prototype.fire = Prototype.Fire
Prototype.connect = Prototype.Connect
Prototype.wait = Prototype.Wait
Prototype.destroy = Prototype.Destroy

return Signal
