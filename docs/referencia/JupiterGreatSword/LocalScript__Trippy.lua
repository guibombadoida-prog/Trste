local RunService = game:FindService("RunService") or game:GetService("RunService")

local Humanoid = script.Parent;
local RootPart = Humanoid:IsA("Humanoid") and Humanoid.RootPart;

while Humanoid and Humanoid.Parent and script and script.Parent do
	
	Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown);
	
	if RootPart then
		
		RootPart.AssemblyAngularVelocity = Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*2*30
		
	end
	
		
	for _,v in pairs(Humanoid.Parent:GetDescendants()) do
		if v:IsA("BodyMover") then
			if (Humanoid:IsA("Humanoid")) then
				Humanoid:UnequipTools();
			end
			break
		end
	end
	
	--[[for i,v in pairs(script.Parent:GetPlayingAnimationTracks()) do
		v:Stop()
	end]]
	
	
	RunService.RenderStepped:Wait()
end