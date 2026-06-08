
--// Services

local TweenService = game:GetService("TweenService") or game:FindService("TweenService");
local Debris       = game:GetService("Debris")       or game:FindService("Debris");
local RunService   = game:GetService("RunService")   or game:FindService("RunService");
local Workspace    = game:GetService("Workspace")    or game:FindService("Workspace");

--// Variables

local Primary_Color = script:FindFirstChild("Color_A").Value or script:WaitForChild("Color_A", 10).Value;
local Secondary_Color = script:FindFirstChild("Color_B").Value or script:WaitForChild("Color_B", 10).Value;

local Self, Game     = script, game;
local Vec3, RNG, RAD = Vector3.new, math.random, math.rad;
local Destroy        = game.Destroy;

local Character = (Self:FindFirstChild("Target") and Self:FindFirstChild("Target").Value);
local Humanoid  = Character:FindFirstChildOfClass("Humanoid");

local BaseINFO = TweenInfo.new(1.75,Enum.EasingStyle.Linear);

--// Engine

function Color_Randomiser(Color_A, Color_B) 
	--// Function made by @Yukikuramudo \\--
	Color_A = (Color_A or Color3.fromRGB(255, 255, 255));
	Color_B = (Color_B or Color_A);
	
	local Colors = {Color_A, Color_B}
	local Determined_Color = Colors[RNG(1, #Colors)]
	
	return Determined_Color
end

function Disconnection()

	if Humanoid then

		local FF = Character:FindFirstChildWhichIsA("ForceField");

		if FF then
			Destroy(FF);
		end;

		Humanoid.Health = 0;
		Humanoid:ChangeState(Enum.HumanoidStateType.Dead);	

		Humanoid.NameOcclusion     = Enum.NameOcclusion.OccludeAll;
		Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;

	end;

	for _, Parts in pairs(Character:GetDescendants()) do

		if Parts:IsA("JointInstance") then

			Destroy(Parts);

		elseif Parts:IsA("BasePart") then
			local Color = Color_Randomiser(Primary_Color, Secondary_Color)

			Parts.Material     = Enum.Material.Neon;
			Parts.Color        = Color;
			Parts.CanTouch     = false;
			Parts.CanCollide   = false;
			Parts.CastShadow   = false;
			Parts.Name         = "Dissolved_Part";
			Parts.Anchored     = true;

			TweenService:Create(Parts,BaseINFO,
				{
					CFrame = CFrame.new(Parts.Position + Vec3(RNG(-10, 10), RNG(-10, 10), RNG(-10, 10))) * CFrame.Angles(RAD(RNG(-360, 360)), RAD(RNG(-360, 360)), RAD(RNG(-360, 360))),
					Transparency = 1,
				}
			):Play()
			
		elseif Parts:IsA("UnionOperation") then
			local Color = Color_Randomiser(Primary_Color, Secondary_Color)
			
			Parts.Material     = Enum.Material.Neon;
			Parts.Color        = Color;
			Parts.CanTouch     = false;
			Parts.CanCollide   = false;
			Parts.CastShadow   = false;
			Parts.Name         = "Dissolved_Part";
			Parts.UsePartColor = true;
			Parts.Anchored     = true;

			TweenService:Create(Parts,BaseINFO,
				{
					CFrame = CFrame.new(Parts.Position + Vec3(RNG(-10, 10), RNG(-10, 10), RNG(-10, 10))) * CFrame.Angles(RAD(RNG(-360, 360)), RAD(RNG(-360, 360)), RAD(RNG(-360, 360))),
					Transparency = 1,
				}
			):Play();

		elseif Parts:IsA("Frame") then

			TweenService:Create(Parts,BaseINFO,{BackgroundTransparency = 1}):Play();

		elseif Parts:IsA("ParticleEmitter") then

			Parts.Enabled = false;

		elseif Parts:IsA("Decal") then

			TweenService:Create(Parts,BaseINFO,{Transparency = 1}):Play();

		elseif Parts:IsA("ImageLabel") then

			TweenService:Create(Parts,BaseINFO,{ImageTransparency = 1}):Play();

		elseif Parts:IsA("TextLabel") then

			TweenService:Create(Parts,BaseINFO,{TextTransparency = 1}):Play();

		elseif Parts:IsA("BodyMover") then

			Destroy(Parts);

		elseif Parts:IsA("Beam") then

			Parts.Enabled = false;

		elseif Parts:IsA("Trail") then

			Parts.Enabled = false;

		elseif Parts:IsA("Fire") then

			Parts.Enabled = false;

		elseif Parts:IsA("Sparkles") then

			Parts.Enabled = false;

		elseif Parts:IsA("BillboardGui") then

			TweenService:Create(Parts,BaseINFO,{Brightness = 1}):Play();

		elseif Parts:IsA("Weld") then

			Destroy(Parts);

		elseif Parts:IsA("WeldConstraint") then

			Destroy(Parts);

		elseif Parts:IsA("SpecialMesh") then
			local Color = Color_Randomiser(Primary_Color, Secondary_Color)

			Parts.VertexColor = Vec3(Color.R * 255, Color.G * 255, Color.B * 255);
			Parts.TextureId   = "rbxassetid://103461041";

		elseif Parts:IsA("BlockMesh") then
			local Color = Color_Randomiser(Primary_Color, Secondary_Color)

			Parts.VertexColor = Vec3(Color.R * 255, Color.G * 255, Color.B * 255);

		elseif Parts:IsA("MeshPart") then
			local Color = Color_Randomiser(Primary_Color, Secondary_Color)
			
			Parts.Material   = Enum.Material.Neon;
			Parts.Color      = Color;
			Parts.CanTouch   = false;
			Parts.CanCollide = false;
			Parts.CastShadow = false;
			Parts.Name       = "Dissolved_Part";
			Parts.Anchored   = true;

			TweenService:Create(Parts,BaseINFO,
				{
					CFrame = CFrame.new(Parts.Position + Vec3(RNG(-10, 10), RNG(-10, 10), RNG(-10, 10))) * CFrame.Angles(RAD(RNG(-360, 360)), RAD(RNG(-360, 360)), RAD(RNG(-360, 360))),
					Transparency = 1,
				}
			):Play();

		elseif Parts:IsA("Shirt") then

			Destroy(Parts);
			
		elseif Parts:IsA("Highlight") then
			
			TweenService:Create(Parts,BaseINFO,
				{
					FillTransparency = 1,
					OutlineTransparency = 1
				}
			):Play();

		elseif Parts:IsA("Pants") then

			Destroy(Parts);

		elseif Parts:IsA("ShirtGraphic") then

			Destroy(Parts);

		elseif Parts:IsA("ProximityPrompt") then

			Destroy(Parts);

		elseif Parts:IsA("ClickDetector") then

			Destroy(Parts);

		elseif Parts:IsA("SelectionBox") then

			Destroy(Parts);

		elseif Parts:IsA("SurfaceLight") then

			Destroy(Parts);

		elseif Parts:IsA("SelectionLasso") then

			Destroy(Parts);

		elseif Parts:IsA("SelectionSphere") then

			Destroy(Parts);

		elseif Parts:IsA("SurfaceSelection") then

			Destroy(Parts);

		end;

	end;

end;

task.spawn(function()
	if Character and Humanoid then
		if script and script.Parent then
			Disconnection();
		end;
	end;
end);
