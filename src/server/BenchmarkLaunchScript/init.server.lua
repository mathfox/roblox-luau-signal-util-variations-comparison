local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalBenchmarkModule = require(script.SignalBenchmarkModule)

task.wait(5)

local benchmarkModules = ReplicatedStorage:GetChildren()

for _, signalModuleScript in ipairs(benchmarkModules) do
	if not signalModuleScript:IsA("ModuleScript") then
		continue
	end

	SignalBenchmarkModule(signalModuleScript)

	-- prevent exhausted allowed execution time
	task.wait(5)
end
