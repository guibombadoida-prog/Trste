--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Basic Explosion for convenience.
	
	
]]
local TweenService = game:FindService("TweenService") or game:GetService("TweenService")
local Debris = game:FindService("Debris") or game:GetService("Debris")

local Wave_Base = script:WaitForChild("Wave"):Clone()

return function(Position, Duration, Size_A,Size_B,Color_A,Color_B, Easing_Style)
	--// Keeping this local for performance and stability
	
	
	local BaseURL = "rbxassetid://"
	
	Position = Position or Vector3.new(0,5,0)
	Duration = Duration or .5;
	Size_A = Size_A or 0;
	Size_B = Size_B or 50;
	Color_A = Color_A or Color3.fromRGB(255,255,255);
	Color_B = Color_B or Color_A
	Easing_Style = Easing_Style or Enum.EasingStyle.Linear
	
	local Sequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color_A);
		ColorSequenceKeypoint.new(1,Color_B);
	})

	
	local function Explode(Position)
		local ExplosionPart = Instance.new("Part");
		ExplosionPart.Color = Color_A
		ExplosionPart.CanCollide = false;
		ExplosionPart.CanTouch = false;
		ExplosionPart.CanQuery = false;
		ExplosionPart.Anchored = true;
		ExplosionPart.Shape = Enum.PartType.Ball;
		ExplosionPart.Size = Vector3.new(0.001,0.001,0.001) * Size_A
		ExplosionPart.Position = Position
		ExplosionPart.CastShadow = false
		ExplosionPart.Material = "Neon"
		
		local Mesh = Instance.new("SpecialMesh")
		Mesh.Parent = ExplosionPart
		Mesh.MeshType = Enum.MeshType.Sphere;
		Mesh.Scale = Vector3.new(1000,1000,1000)
		
		local Attachment = Instance.new("Attachment")
		Attachment.Name = "Holder";
		Attachment.Parent = ExplosionPart

		local ExplosionParticles = script.ExplosionParticles:Clone()
		ExplosionParticles.Color = Sequence
		ExplosionParticles.Lifetime = NumberRange.new(Duration - 0.5,Duration + 0.5)
		ExplosionParticles.Speed = NumberRange.new(Size_B/2,Size_B * 2)
		ExplosionParticles.Parent = Attachment
		ExplosionParticles:Emit(Size_A/2 + Size_B/2)

		local LastTime = Duration + 3;

		local Wave = Wave_Base:Clone()
		
		--print(Color_A)
		
		Wave.CFrame = ExplosionPart.CFrame * CFrame.Angles(math.pi/2,0,0)
		Wave.Color = Color_A;
		Wave.Size = Vector3.new(1,1,0.1) * Size_A;
		ExplosionPart.Parent = workspace.Camera
		Wave.Parent = workspace
		Wave.Transparency = 0

		TweenService:Create(ExplosionPart,TweenInfo.new(Duration,Easing_Style),{Size = Vector3.new(0.001,0.001,0.001) * Size_B,Transparency = 1,Color = Color_B}):Play()
		TweenService:Create(Wave,TweenInfo.new(Duration,Easing_Style),{Size = Vector3.new(1,1,0.1) * (Size_B * 1.5),Transparency = 1,Color = Color_B}):Play()

		Debris:AddItem(ExplosionPart,LastTime + 1)
		Debris:AddItem(Wave,LastTime + 1)

	end

	do
		Explode(Position)
	end







end