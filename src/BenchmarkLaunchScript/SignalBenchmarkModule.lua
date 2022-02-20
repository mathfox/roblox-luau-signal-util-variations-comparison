local RUNS_AMOUNT = 10
local ITERATIONS_PER_RUN = 1_000_000

local function void() end

local function SignalBenchmarkModule(signalModuleScript: ModuleScript)
	local signalUtil = require(signalModuleScript)

	local function output(message: string)
		print(("(%s) %s"):format(signalModuleScript.Name, message))
	end

	-- soft yield benchmark
	do
		local signal = signalUtil.new()
		local totalSoftYieldTime = 0

		for _ = 1, RUNS_AMOUNT do
			local softYieldStart = os.clock()

			for _ = 1, ITERATIONS_PER_RUN do
				signal:Connect(void)
			end

			totalSoftYieldTime += os.clock() - softYieldStart

			-- prevent annoying script timeout
			task.wait()
		end

		output(("soft yield: %f\n"):format(totalSoftYieldTime / RUNS_AMOUNT))

		signal:Destroy()
	end

	-- create/destroy time benchmark
	do
		local signals = {}

		do
			local totalCreationTime = 0
			local totalDestroyTime = 0

			for _ = 1, RUNS_AMOUNT do
				do
					local creationStartTime = os.clock()

					for _ = 1, ITERATIONS_PER_RUN do
						table.insert(signals, signalUtil.new())
					end

					totalCreationTime += os.clock() - creationStartTime
				end

				-- prevent annoying script timeout
				task.wait()

				do
					local destroyStartTime = os.clock()

					for _, signal in ipairs(signals) do
						signal:Destroy()
					end

					totalDestroyTime += os.clock() - destroyStartTime
				end

				table.clear(signals)

				-- prevent annoying script timeout
				task.wait()
			end

			output(("creation time: %f\n"):format(totalCreationTime / RUNS_AMOUNT))
			output(("destroy time: %f\n"):format(totalDestroyTime / RUNS_AMOUNT))
		end
	end
end

return SignalBenchmarkModule
