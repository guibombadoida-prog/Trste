--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Spiral Explosion for convenience.
	
	Could be used to make a windy explosion
	
	OLD
	
]]

local Debris = (game:FindService("Debris") or game:GetService("Debris"))
local TweenService = (game:FindService("TweenService") or game:GetService("TweenService"))

local Effect = script:WaitForChild("VFX");
Effect.Parent = nil;

return function(Position, Duration, Size_Start, Size_End, Sphere_Color, Secondary_Color, Tietary_Color, Quadrentary_Color)
	
	Position = Position or Vector3.new();
	Duration = Duration or 2
	Size_Start = Size_Start or 5;
	Size_End = Size_End or 15
	Sphere_Color = Sphere_Color or Color3.fromRGB(13, 105, 172);
	Secondary_Color = Secondary_Color or Color3.fromRGB(0, 16, 176);
	Tietary_Color = Tietary_Color or Color3.fromRGB(248, 248, 248)
	Quadrentary_Color = Quadrentary_Color or Color3.fromRGB(18, 238, 212)
	
	local Sphere_Model = Effect:Clone()
	Sphere_Model.Parent = workspace;
	Sphere_Model:SetPrimaryPartCFrame(CFrame.new(Position))
	
	local Sphere = Sphere_Model:FindFirstChild("CoreSphere")
	local Sphere_2 = Sphere_Model:FindFirstChild("Sphere2")
	local Sphere_3 = Sphere_Model:FindFirstChild("Sphere3")
	local Sphere_4 = Sphere_Model:FindFirstChild("Sphere4")
	Sphere.Transparency = 0
	Sphere_2.Transparency = 0
	Sphere_3.Transparency = 0
	Sphere_3.Transparency = 0
	
	Sphere.Color = Sphere_Color;
	Sphere_2.Color = Secondary_Color;
	Sphere_3.Color = Tietary_Color;
	Sphere_4.Color = Quadrentary_Color;
	
	Sphere.Size =  Vector3.new(1,1,1) * Size_Start;
	Sphere_2.Size = Vector3.new(1,1,1) * Size_Start;
	Sphere_3.Size = Vector3.new(1,1,1) * Size_Start;
	Sphere_4.Size = Vector3.new(1,1,1) * Size_Start;
	
	Debris:AddItem(Sphere_Model,Duration + 3)
	
	TweenService:Create(Sphere_2,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Sine),{Orientation = Vector3.new(0,1000,0)}):Play()
	TweenService:Create(Sphere_3,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Sine),{Orientation = Vector3.new(0,1000,0)}):Play()
	TweenService:Create(Sphere_4,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Sine),{Orientation = Vector3.new(0,1000,0)}):Play()
	
	TweenService:Create(Sphere,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Exponential),{Size = ((Vector3.new(1,1,1) * Size_End) - Vector3.new(.5,.5,.5))}):Play()
	TweenService:Create(Sphere_2,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Exponential),{Size = ((Vector3.new(1,1,1) * Size_End))}):Play()
	TweenService:Create(Sphere_3,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Exponential),{Size = ((Vector3.new(1,1,1) * Size_End))}):Play()
	TweenService:Create(Sphere_4,TweenInfo.new(Duration + 0.65,Enum.EasingStyle.Exponential),{Size = ((Vector3.new(1,1,1) * Size_End))}):Play()
	
	task.delay(Duration,function()
		TweenService:Create(Sphere,TweenInfo.new(.65,Enum.EasingStyle.Sine),{Transparency = 1}):Play()
		TweenService:Create(Sphere_2,TweenInfo.new(.65,Enum.EasingStyle.Sine),{Transparency = 1}):Play()
		TweenService:Create(Sphere_3,TweenInfo.new(.65,Enum.EasingStyle.Sine),{Transparency = 1}):Play()
		TweenService:Create(Sphere_4,TweenInfo.new(.65,Enum.EasingStyle.Sine),{Transparency = 1}):Play()
	end)
	
end
