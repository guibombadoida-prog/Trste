--Made By ICAN_REA0
VFX = require(125275839196878)
Gear_Manager = require(6645113937)
Creator = script.creator
Sky_Of_Color = Instance.new("ColorCorrectionEffect")
Sky_Of_Color.Name = "Jupiter"
Sky_Of_Color.TintColor = Color3.fromRGB(255, 255, 255)
Sky_Of_Color.Saturation = 0
Sky_Of_Color.Parent = game.Lighting
game:GetService("Debris"):AddItem(Sky_Of_Color,50)
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = game.Lighting
game:GetService("Debris"):AddItem(Blur,50)

TweenService = game:GetService("TweenService")


function OnRedJupiter()
	wait(1)
	TweenService:Create(Sky_Of_Color,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{TintColor = Color3.fromRGB(255, 0, 4)}):Play()
	TweenService:Create(Sky_Of_Color,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Saturation = 1}):Play()
	TweenService:Create(Blur,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Size = 24}):Play()
	wait(1.75)
	TweenService:Create(Blur,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Size = 0}):Play()
	wait(0.25)
	for i=1,15 do
		wait(1.5)
		spawn(function()
			local Found,Target = Gear_Manager:Detect_Humanoids_Nearby(Creator.Value.Character.HumanoidRootPart,math.huge,{Creator.Value.Character},Creator.Value)
			if Found then
				for i,Hum in pairs(Target) do
					if Hum and Hum:IsA("Humanoid") and not Hum.Parent:FindFirstChildWhichIsA("ForceField") then
						local TagHumanoid = Instance.new("ObjectValue")
						TagHumanoid.Name = "creator"
						TagHumanoid.Value = Creator.Value
						TagHumanoid.Parent = Hum
						game:GetService("Debris"):AddItem(TagHumanoid,1.45)
						Hum:TakeDamage(11);
						Hum:UnequipTools();
						VFX:FireAllClients("Cast_Effects","Lightning",Vector3.new(0,3500,0),Hum.Parent.HumanoidRootPart.Position,1.65,7.5,0,1,0,Color3.fromRGB(255, 0, 4),Color3.fromRGB(255, 0, 4))
						VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.Lightning_Explosion,Hum.Parent.HumanoidRootPart.Position,1,6.5,ColorSequence.new(Color3.fromRGB(255, 0, 4)),Color3.fromRGB(255, 96, 99),Vector3.new(0,1,0))
						local L_Sounds = {script.L_Sounds.Lightning1,script.L_Sounds.Lightning2,script.L_Sounds.Lightning3,script.L_Sounds.Lightning4,script.L_Sounds.Lightning5,script.L_Sounds.Lightning6}
						local RandomSounds = L_Sounds[math.random(1,#L_Sounds)]:Clone()
						RandomSounds.Parent = game.Workspace
						RandomSounds:Play()
						game:GetService("Debris"):AddItem(RandomSounds,2.125)
					end
				end
			end
		end)
	end
	TweenService:Create(Sky_Of_Color,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	TweenService:Create(Sky_Of_Color,TweenInfo.new(1.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Saturation = 0}):Play()
	wait(1.25)
	Blur:Destroy()
	Sky_Of_Color:Destroy()
end

OnRedJupiter()