local function SignalBenchmarkModule(signalModuleScript: ModuleScript)
	local signalUtil = require(signalModuleScript)

	local function output(message: string)
		print(("(%s) %s"):format(signalModuleScript.Name, message))
	end

	-- soft yield benchmark
	do
		local totalIterationsAmount = 1_000_000
		local function void() end
		local signal = signalUtil.new()

		local softYieldStartTime = os.clock()

		for _ = 1, totalIterationsAmount do
			signal:Connect(void)
		end

		output(("soft yield: %f"):format(os.clock() - softYieldStartTime))

		signal:Destroy()
	end

	task.wait(1)

	-- create/destroy time benchmark
	do
		local signals = {}

		do
			local createStartTime = os.clock()

			for _ = 1, 1_000_000 do
				local signal = signalUtil.new()
				table.insert(signals, signal)
			end

			output(("creation time: %f"):format(os.clock() - createStartTime))
		end

		task.wait(1)

		do
			local destroyStartTime = os.clock()

			for _, signal in ipairs(signals) do
				signal:Destroy()
			end

			output(("destroy time: %f"):format(os.clock() - destroyStartTime))
		end
	end

	print("\n\n\n")
end

return SignalBenchmarkModule
