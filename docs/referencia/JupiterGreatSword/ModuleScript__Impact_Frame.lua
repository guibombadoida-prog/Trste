local Impact_Frame = {}

local RunService = game:GetService("RunService") or game:FindService("RunService")
local Debris = game:GetService("Debris") or game:FindService("Debris")
local Lighting = game:GetService("Lighting") or game:FindService("Lighting")
local TweenService = game:GetService("TweenService") or game:FindService("TweenService")
local Players = game:FindService("Players") or game:GetService("Players")
local Camera = workspace.CurrentCamera

Impact_Frame = function(Character1:Model, Character2:Model, Duration:number)
	
	local LocalPlayer = Players.LocalPlayer;

	local OldSkies = {}

	local Exposure
	local Inversion
	local Sky
	local FogColor
	local FogEnd
	if false then
		
		return
			
	else
		
		Inversion = script:FindFirstChild("Invert"):Clone()
		Inversion.Parent = Lighting;
		Inversion.Enabled = true

		Debris:AddItem(Inversion, Duration + 3)

		for i,v in pairs(Lighting:GetChildren()) do
			if v:IsA("Sky") then
				v.Parent = script;
				OldSkies[#OldSkies + 1] = Sky;
			end
		end

		Sky = script.Sky:Clone();
		Sky.Parent = Lighting;
	end
	local Hit_Gui = script.Hit:Clone()
	Hit_Gui.Enabled = true
	Hit_Gui.Parent = LocalPlayer.PlayerGui;

	local Move
	Move = RunService.RenderStepped:Connect(function()

		local Position_A = Character1:GetPivot().Position;
		local Position_B = Character2:GetPivot().Position;
		local worldPoint = Position_A:Lerp(Position_B, .5)
		local vector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(worldPoint)

		Hit_Gui.Impact.Position = UDim2.new(0, vector.X, 0, vector.Y)

	end)

	local Impact_Sound = script.Impact_Sound:Clone()
	Impact_Sound.PlayOnRemove = true;
	Impact_Sound.Parent = workspace;
	Impact_Sound:Destroy()

	task.wait(Duration)

	if Move then
		Move:Disconnect(); Move = nil
	end

	if Hit_Gui then
		Hit_Gui:Destroy(); Hit_Gui = nil;
	end

	if Inversion then
		Inversion:Destroy(); Inversion = nil;
	end
	
	if Sky then
		Sky:Destroy();

		for i,v in pairs(OldSkies) do
			v.Parent = Lighting;
		end
	end
	
end


return Impact_Frame
