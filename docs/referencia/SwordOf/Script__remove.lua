local tool = script.Parent
local ServerStorage = game:GetService("ServerStorage")

local eldrichSoulInTool = tool:FindFirstChild("CosmicVFX2")
if not eldrichSoulInTool then
	return
end

local existingModel = ServerStorage:FindFirstChild("CosmicVFX2")

if existingModel == nil then
	eldrichSoulInTool.Parent = ServerStorage
else
	eldrichSoulInTool:Destroy()
	script:Destroy()
end