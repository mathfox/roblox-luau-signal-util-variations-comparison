local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalBenchmarkModule = require(script.SignalBenchmarkModule)

task.wait(5)

for _, signalModuleScript in ipairs(ReplicatedStorage:GetChildren()) do
	if not signalModuleScript:IsA("ModuleScript") then
		continue
	end

	SignalBenchmarkModule(signalModuleScript)

	-- prevent exhausted allowed execution time
	task.wait(1)
end
