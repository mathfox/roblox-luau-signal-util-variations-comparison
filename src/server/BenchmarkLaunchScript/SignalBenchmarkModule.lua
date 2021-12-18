local function SignalBenchmarkModule(signalModuleScript: ModuleScript)
	local signalUtil = require(signalModuleScript)

	-- soft yield benchmark
	do
		local signal = signalUtil.new()

		local function void() end

		for _ = 1, 1_000_000 do
			signal:Connect(void)
		end

		local softYieldStartTime = os.clock()
		signal:Fire()
		print(("soft yield of %s:"):format(signalModuleScript.Name), os.clock() - softYieldStartTime)

		signal:Destroy()
	end

	print("\n\n\n")
end

return SignalBenchmarkModule
