---Made By ICAN_REA0

if script:WaitForChild("creator").Value == nil then
	script:Destroy()
end

VFX = require(125275839196878)
Gear_Manager = require(6645113937)

Creator = script.creator

Plyr = Creator.Value.Character

ObjectCharacter = script.ObjectCharacter

Jupiter = script.Parent

TweenService = game:GetService("TweenService")


function IsTeamMate(Player1, Player2)
	return (Player1 and Player2 and not Player1.Neutral and not Player2.Neutral and Player1.TeamColor == Player2.TeamColor)
end

function TagHumanoid(humanoid, player)
	local Creator_Tag = Instance.new("ObjectValue")
	Creator_Tag.Name = "creator"
	Creator_Tag.Value = player
	game.Debris:AddItem(Creator_Tag, 2)
	Creator_Tag.Parent = humanoid
end

function UntagHumanoid(humanoid)
	for i, v in pairs(humanoid:GetChildren()) do
		if v:IsA("ObjectValue") and v.Name == "creator" then
			v:Destroy()
		end
	end
end

DetectionAOE = Vector3.new(30,30,30)
TempHums = {}
parts = {}
TempRoot = nil
TempChar = nil
TempHum = nil
Ignore = false
Targets = {}
Distance = 999

function FindCharacters(rangePoint,maxRange)
	TempHums = {}
	Targets = {}
	DetectionAOE = Vector3.new(maxRange,maxRange,maxRange)
	DetectRegion = Region3.new(rangePoint - DetectionAOE,rangePoint + DetectionAOE)
	parts = game.Workspace:FindPartsInRegion3(DetectRegion,Plyr,math.huge)
	for a = 1,#parts do
		if parts[a].Parent ~= nil and parts[a].Parent:FindFirstChild("Humanoid") and not parts[a].Parent:FindFirstChild("ForceField") and not IsTeamMate(Plyr,game.Players:GetPlayerFromCharacter(parts[a].Parent)) then
			TempRoot = parts[a].Parent:FindFirstChild("HumanoidRootPart") or parts[a].Parent:FindFirstChild("Torso")
			TempHum = parts[a].Parent.Humanoid
			TempChar = parts[a].Parent
			Ignore = false
			for h = 1,#TempHums do
				if TempHums[h] == TempHum then
					Ignore = true
				end
			end
			if Ignore == false and TempRoot and TempHum.Health > 0 then
				Distance = (rangePoint - TempRoot.Position).magnitude
				if Distance <= maxRange then
					table.insert(TempHums,TempHum)
					table.insert(Targets,TempChar)
				end
			end
		end
	end
end

Running = true

function OnBlackHole()
	wait(1.115)
	Jupiter.SpawnJupiter:Play()
	wait(2.45)
	Jupiter.DuperBoom:Play()
	Jupiter.DistantJupiter:Play()
	Jupiter.SpirtLoop:Play()
	Jupiter.Particle.JupiterRange.Enabled = true
	Jupiter.Particle.JupiterRange2.Enabled = true
	Jupiter.Particle.JupiterSpin.Enabled = true
	Jupiter.Particle.JupiterSpin2.Enabled = true
	Jupiter.Particle.JupiterSpin3.Enabled = true
	Jupiter.JupiterEffect.Enabled = true
		spawn(function()
			while Running do
			wait(0.25)
			local Found,Target = Gear_Manager:Detect_Humanoids_Nearby(Jupiter,3450,{Creator.Value.Character},Creator.Value)
			if Found then
				for i,Hum in pairs(Target) do
					if Hum and Hum:IsA("Humanoid") and not Hum.Parent:FindFirstChildWhichIsA("ForceField") then
						Hum:TakeDamage(1);
						Hum:UnequipTools();
						local BodyVelocity = Instance.new("BodyVelocity")
						BodyVelocity.Name = "BlackHoleD"
						BodyVelocity.Velocity = (Hum.Parent.HumanoidRootPart.Position-Jupiter.Position).Unit*-50
						BodyVelocity.Parent = Hum.Parent.HumanoidRootPart
						BodyVelocity.MaxForce = Vector3.new(1,1,1)*math.huge
						game:GetService("Debris"):AddItem(BodyVelocity,0.35)
					end
				end
			end
			end
	end)
	wait(13.55)
	Running = false
	local JupiterColor = script.Color:Clone()
	JupiterColor.Parent = game.Lighting
	game:GetService("Debris"):AddItem(JupiterColor,50)
	TweenService:Create(JupiterColor,TweenInfo.new(1.25,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Brightness = -0.15}):Play()
	TweenService:Create(JupiterColor,TweenInfo.new(1.25,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{TintColor = Color3.fromRGB(255, 0, 0)}):Play()
	TweenService:Create(JupiterColor,TweenInfo.new(1.25,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Saturation = 1}):Play()
	TweenService:Create(Jupiter.SpirtLoop,TweenInfo.new(4.45,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Pitch = 0.009}):Play()
	wait(0.985)
	local JupiterColor = game.Lighting.Color
	TweenService:Create(JupiterColor,TweenInfo.new(6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Brightness = 0}):Play()
	TweenService:Create(JupiterColor,TweenInfo.new(6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	TweenService:Create(JupiterColor,TweenInfo.new(6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Saturation = 0}):Play()
	TweenService:Create(Jupiter,TweenInfo.new(2.35,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Size = Vector3.new(0,0,0)}):Play()
	Jupiter.Particle.JupiterRange.Enabled = false
	Jupiter.Particle.JupiterRange2.Enabled = false
	Jupiter.Particle.JupiterSpin.Enabled = false
	Jupiter.Particle.JupiterSpin2.Enabled = false
	Jupiter.Particle.JupiterSpin3.Enabled = false
	wait(1.95)
	VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.ImpactFrameScript,Jupiter.Position,0.65)
	wait(0.65)
	JupiterColor:Destroy()
	local Explosion = script.VJ_Explosion:Clone()
	Explosion.Parent = game.Workspace
	Explosion:Play()
	game:GetService("Debris"):AddItem(Explosion,Explosion.TimeLength+1)
	local Explosion2 = script.VJ_Explosion2:Clone()
	Explosion2.Parent = game.Workspace
	Explosion2:Play()
	game:GetService("Debris"):AddItem(Explosion2,Explosion2.TimeLength+1)
	local Explosion3 = script.VJ_Explosion3:Clone()
	Explosion3.Parent = game.Workspace
	Explosion3:Play()
	game:GetService("Debris"):AddItem(Explosion3,Explosion3.TimeLength+1)
	Jupiter.Transparency = 1
	spawn(function()
		local Found,Target = Gear_Manager:Detect_Humanoids_Nearby(Jupiter,475*2,{Creator.Value.Character},Creator.Value)
		if Found then
			for i,Hum in pairs(Target) do
				if Hum and Hum:IsA("Humanoid") and not Hum.Parent:FindFirstChildWhichIsA("ForceField") then
					Hum:TakeDamage(750);
					Hum:UnequipTools();
					if Hum.Health < 0 then
						local FadeAway = script:WaitForChild("Disintegrate"):Clone()
						FadeAway.Enabled = true
						FadeAway.Parent = Hum.Parent
					end
				end
			end
		end
	end)
	VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.Spiral_Explosion,Jupiter.Position,2.35,1,145*2,Color3.fromRGB(255, 95, 95),Color3.fromRGB(0, 0, 0),Color3.fromRGB(255, 0, 0),Color3.fromRGB(176, 176, 176))
	VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.Small_Nova,Jupiter.Position,1.875,1,225*2,Color3.fromRGB(255, 0, 4),Color3.fromRGB(0, 0, 0),Enum.EasingStyle.Quad)
	VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.Shockwave_2,Jupiter.CFrame,Jupiter.CFrame,2.35,Vector3.new(9.1,0.1,0),Vector3.new(600.1*2,0.1,600*2),Color3.fromRGB(255, 0, 4),Color3.fromRGB(255, 0, 4),Enum.EasingStyle.Quad)
	VFX:FireAllClients("Cast_Effects","Shake_Camera",7,2.85,750,Jupiter.Position)
	VFX:FireAllClients("Cast_Effects","DistortionModule",CFrame.new(Jupiter.Position), Vector3.new(1,1,1), 0, Vector3.new(750*2,750*2,750*2), 0.875)
	VFX:FireAllClients("Cast_Effects","Floating_Debris",Jupiter.Position, {Creator.Value.Character}, 40, 345, 250)
	wait(6)
	Jupiter:Destroy()
	script:Destroy()
end
OnBlackHole()
