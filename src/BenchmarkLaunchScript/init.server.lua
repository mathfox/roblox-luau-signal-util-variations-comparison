local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalBenchmarkModule = require(script.SignalBenchmarkModule)

for _, signalModuleScript in ipairs(ReplicatedStorage:GetChildren()) do
	if signalModuleScript:IsA("ModuleScript") then
		task.spawn(SignalBenchmarkModule, signalModuleScript)
	end
end
