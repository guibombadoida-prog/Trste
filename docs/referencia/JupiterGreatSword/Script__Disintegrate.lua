--// Disintegration Effect by @SonarHEXAGON

--// Tweaked a little by @Yukikuramudo for Color Randomization and Additional configuration.

--// !!@ { Must be inserted inside a character model. } @!! \\--

--// Requirings

local Gear_Manager = require(6645113937);

--// Objectariables

local Self, Game = script, game;

local SearchChild = (Game.FindFirstChild and Game.WaitForChild);

local Character = Self.Parent;

local Specified_Colour_A = SearchChild(Self, "Color_A", 10).Value; --// This could also be a Color3 Value below the script.
local Specified_Colour_B = SearchChild(Self, "Color_B", 10).Value;
local Use_Random_Color = SearchChild(Self, "Use_Random_Color", 10).Value;

--// Primary Engine

for _, Object in pairs(Character:GetDescendants()) do
	if Object:IsA("BasePart") then
		
		Object.CanCollide   = false;
		Object.CanTouch     = false;
		Object.Anchored     = true;
		
	elseif Object:IsA("Humanoid") then
		
		local FF = Character:FindFirstChildWhichIsA("ForceField") 

		if FF then
			FF:Destroy()
		end

		Object.Health = 0
		Object:ChangeState(Enum.HumanoidStateType.Dead);

		Object.NameOcclusion      = Enum.NameOcclusion.OccludeAll;
		Object.HealthDisplayType  = Enum.HumanoidHealthDisplayType.AlwaysOff;
		Object.BreakJointsOnDeath = true;

	elseif Object:IsA("Tool") then
		
		for _, Object in pairs(Object:GetDescendants()) do
			if Object:IsA("BasePart") then

				Object.Parent       = Character;
				Object.CanCollide   = false;
				Object.CanTouch     = false;
				Object.Anchored     = true;

			end
		end
		
	elseif Object:IsA("Decal") or Object:IsA("Texture") then
		
		Object:Destroy();
		
	end;
end;

--// Visual Effect

local Local_Script = SearchChild(Self, "Disintegration", 10);
if Local_Script then
	if Use_Random_Color then
		SearchChild(Local_Script, "Target", 10).Value = Character;
		SearchChild(Local_Script, "Color_A", 10).Value = Specified_Colour_A;
		SearchChild(Local_Script, "Color_B", 10).Value = Specified_Colour_B;
		Gear_Manager:CastLocalScripts(Local_Script, 2, false);
	else
		SearchChild(Local_Script, "Target", 10).Value = Character;
		SearchChild(Local_Script, "Color_A", 10).Value = Specified_Colour_A;
		SearchChild(Local_Script, "Color_B", 10).Value = Specified_Colour_A;
		Gear_Manager:CastLocalScripts(Local_Script, 2, false);
	end
	
end;

--// Engine End

Self:Destroy();
