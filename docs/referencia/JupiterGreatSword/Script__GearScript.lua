---Made By ICAN_REA0
MyVFX = script.GearObject
VFX = require(125275839196878)
Gear_Manager = require(6645113937)
Tool = script.Parent
Handle = Tool:WaitForChild("Handle")
Animations = Tool:WaitForChild("Animations")
Table = {}
HitTable = false
DoingSpecial = false
Special1 = true
Special2 = true
Special3 = true
Remote = Tool:WaitForChild("Remote")
MouseInput = Tool:WaitForChild("MouseInput")
TweenService = game:GetService("TweenService")
GearFolder = Tool.JupiterGearFolder
ReturnGearFolder = GearFolder:Clone()
ReturnGearFolder.Parent = game.ServerScriptService
GearFolder:Destroy()




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




function OnActiavted()
	if not Tool.Enabled then return end
	Tool.Enabled = false
	HitTable = true
	Handle.SwordLunge:Play()
	SlashAnim = Humanoid:LoadAnimation(Animations:WaitForChild(AnimRigtype):WaitForChild("StabAnim"))
	SlashAnim:Play(nil,nil,2.65)
	wait(0.125)
	VFX:FireAllClients("Cast_Effects","Slash_Trail",Root, 20, 0.5, Color3.fromRGB(255, 0, 4), 0.2, CFrame.Angles(0,0.4,0), 2, 4)
	wait(0.255)
	Tool.Enabled = true
	HitTable = false
end





function OnSwordHit(Hit)
	if not HitTable then return end
	if Hit == nil or Hit.Parent == nil or Hit:IsDescendantOf(Character) or IsTeamMate(Player,game.Players:GetPlayerFromCharacter(Hit.Parent)) and Gear_Manager:Is_NPC_Team(Hit.Parent,Player) then return end
	local Hum = Hit.Parent.Humanoid
	Hum:TakeDamage(45)
	Hum:UnequipTools()
	VFX:FireAllClients("Cast_Effects","Slice",Hit.Parent.HumanoidRootPart.Position, 9, math.random(-35,35), math.random(-35,35), Color3.fromRGB(255, 0, 4), Color3.fromRGB(255, 0, 4), 0.75)
	VFX:FireAllClients("Cast_Effects","Slice",Hit.Parent.HumanoidRootPart.Position, 9, math.random(-35,35), math.random(-35,35), Color3.fromRGB(255, 0, 4), Color3.fromRGB(255, 0, 4), 0.75)
	VFX:FireAllClients("Cast_Effects","Slice",Hit.Parent.HumanoidRootPart.Position, 9, math.random(-35,35), math.random(-35,35), Color3.fromRGB(255, 0, 4), Color3.fromRGB(255, 0, 4), 0.75)
	Handle.SwordHit:Play()
	Handle.SwordHit2:Play()
	HitTable = false
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
	parts = game.Workspace:FindPartsInRegion3(DetectRegion,Character,math.huge)
	for a = 1,#parts do
		if parts[a].Parent ~= nil and parts[a].Parent:FindFirstChild("Humanoid") and not parts[a].Parent:FindFirstChild("ForceField") and not IsTeamMate(Player,game.Players:GetPlayerFromCharacter(parts[a].Parent))  then
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


function IsCharacterFlying(char) -- helps check if person is flying
	local FlightClasses = {"BodyPosition","BodyThrust","BodyVelocity","BodyGyro"}
	if char then
		for i,v in pairs(FlightClasses) do
			if char:FindFirstChildWhichIsA(v,true) then
				return true
			end
		end
	end
	return false
end

function Is_Character_Flying2(Char)
	for _,forces in pairs(Char:GetDescendants()) do
		if forces:IsA("BodyMover") then
			forces:Destroy()
		end
	end
end

function OnUnwing()
	DoingSpecial = true
	local UnwingAnim = Humanoid:LoadAnimation(Animations:WaitForChild(AnimRigtype):WaitForChild("Unwing"))
	UnwingAnim:Play(nil,nil,1.35)
	Handle.Unwing:Play()
	Handle.Hitbox.Particle.Burst_Particle:Emit(Handle.Hitbox.Particle.Burst_Particle.Rate)
	Handle.Hitbox.Particle.Flash_Particle:Emit(Handle.Hitbox.Particle.Flash_Particle.Rate)
	wait(1.575)
	spawn(function()
		local Found,Target = Gear_Manager:Detect_Humanoids_Nearby(Root,1500,{Character},Player)
		if Found then
			for i,Hum in pairs(Target) do
				if Hum and Hum:IsA("Humanoid") and not Hum.Parent:FindFirstChildWhichIsA("ForceField") and IsCharacterFlying(Hum.Parent) then
					local TagHumanoid = Instance.new("ObjectValue")
					TagHumanoid.Name = "creator"
					TagHumanoid.Value = Player
					TagHumanoid.Parent = Hum
					game:GetService("Debris"):AddItem(TagHumanoid,1.45)
					Hum:TakeDamage(99);
					Hum:UnequipTools();
					VFX:FireAllClients("Cast_Effects","Lightning",Root.Position,Hum.Parent.HumanoidRootPart.Position,1.65,7.5,0,1,0,Color3.fromRGB(255, 0, 4),Color3.fromRGB(255, 0, 4))
					VFX:FireAllClients("Cast_Effects","Custom_VFX",script.VFXModule.Lightning_Explosion,Hum.Parent.HumanoidRootPart.Position,1,6.5,ColorSequence.new(Color3.fromRGB(255, 0, 4)),Color3.fromRGB(255, 96, 99),Vector3.new(0,1,0))
					Is_Character_Flying2(Hum.Parent)
					local MeteorSmash = script.Sounds.MeteorSmash:Clone()
					MeteorSmash.Parent = Hum.Parent.HumanoidRootPart
					MeteorSmash:Play()
					local Tased = script.Tased:Clone()
					Tased.Duration.Value = 7.45
					Tased.Enabled = true
					Tased.Parent = Hum.Parent
				end
			end
		end
	end)
	wait(16)
	DoingSpecial = false
end

function OnJupiter()
	DoingSpecial = true
	local UnwingAnim = Humanoid:LoadAnimation(Animations:WaitForChild(AnimRigtype):WaitForChild("Unwing"))
	UnwingAnim:Play(nil,nil,1.35)
	Handle.JupiterSummon:Play()
	local Cylinder = Instance.new("Part")
	Cylinder.Name = "LightRed"
	Cylinder.Shape = "Cylinder"
	Cylinder.Size = Vector3.new(2048,0,2048)
	Cylinder.Color = Color3.fromRGB(255, 0, 0)
	Cylinder.Transparency = 1
	Cylinder.Position = Root.Position
	Cylinder.Orientation = Vector3.new(0,90,90)
	Cylinder.Material = Enum.Material.Neon
	Cylinder.CanCollide = false
	Cylinder.Anchored = true
	Cylinder.Parent = workspace
	TweenService:Create(Cylinder,TweenInfo.new(1.65,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Size = Vector3.new(1655,10,1655)}):Play()
	TweenService:Create(Cylinder,TweenInfo.new(1.65,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Transparency = 0}):Play()
	wait(2.35)
	local LightingScript = script.New_Lightning:Clone()
	LightingScript.Parent = workspace
	LightingScript.creator.Value = Player
	LightingScript.Enabled = true
	wait(3.45)
	TweenService:Create(Cylinder,TweenInfo.new(1.65,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Size = Vector3.new(1655,0,1655)}):Play()
	TweenService:Create(Cylinder,TweenInfo.new(1.65,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Transparency = 1}):Play()
	game.Debris:AddItem(Cylinder,4.65)
	wait(5.5)
	DoingSpecial = false
end

function OnJupiterNotice()
	DoingSpecial = true
	local UnwingAnim2 = Humanoid:LoadAnimation(Animations:WaitForChild(AnimRigtype):WaitForChild("RaiseUp"))
	UnwingAnim2:Play(nil,nil,0.65)
	BodyPosition = Instance.new("BodyPosition")
	BodyPosition.Position = Root.Position + Vector3.new(0,30,0)
	BodyPosition.MaxForce = Vector3.new(1,1,1)*math.huge
	BodyPosition.Parent = Root
	local FF = Instance.new("ForceField")
	FF.Name = "FF"
	FF.Visible = false
	FF.Parent = Character
	local DisableBackpack = script.SettingFolder.DisableBackpack:Clone()
	DisableBackpack.Parent = Player.PlayerGui
	DisableBackpack.Enabled = true
	wait(0.35)
	DisableBackpack:Destroy()
	wait(2.35)
	local Jupiter = ReturnGearFolder.Jupiter:Clone()
	Jupiter.Parent = game.Workspace
	Jupiter.Size = Vector3.new(0,0,0)
	Jupiter.Position = Root.Position + Vector3.new(0,75,0)
	TweenService:Create(Jupiter,TweenInfo.new(1.115,Enum.EasingStyle.Circular,Enum.EasingDirection.InOut),{Size = Vector3.new(22.653, 22.653, 22.653)}):Play()
	local JupiterScript = script.JupiterOmni:Clone()
	JupiterScript.Parent = Jupiter
	JupiterScript.Enabled = true
	JupiterScript.creator.Value = Player
	wait(22.55)
	FF:Destroy()
	local DisableBackpack = script.SettingFolder.EnableBackpack:Clone()
	DisableBackpack.Parent = Player.PlayerGui
	DisableBackpack.Enabled = true
	Root.Anchored = false
	BodyPosition:Destroy()
	wait(7)
	DoingSpecial = false
end




function OnEquipped()
	Character = Tool.Parent
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Player = game.Players:GetPlayerFromCharacter(Character)
	Root = Character:WaitForChild("HumanoidRootPart")
	AnimRigtype = Humanoid.RigType.Name
	Humanoid.Died:Connect(function()
		local EnableBackpack = script.SettingFolder.EnableBackpack:Clone()
		EnableBackpack.Parent = Player.PlayerGui
		EnableBackpack.Enabled = true
		Root.Anchored = false
		BodyPosition:Destroy()
	end)
end



Tool.Equipped:Connect(OnEquipped)
Tool.Activated:Connect(OnActiavted)
Handle.Hitbox.Touched:Connect(OnSwordHit)
Remote.OnServerEvent:Connect(function(ClientContext,Key)
	if not Player or not ClientContext or ClientContext ~= Player or not Key or not Tool.Enabled or Humanoid.Health <= 0 or DoingSpecial then return end
	if Key == Enum.KeyCode.E then
		if Special1 == true then
			Special1 = false
			OnUnwing()
			wait(15)
			Special1 = true
		end
	elseif Key == Enum.KeyCode.Q then
		if Special2 == true then
			Special2 = false
			OnJupiter()
			wait(50)
			Special2 = true
		end
	elseif Key == Enum.KeyCode.X then
		if Special3 == true then
			Special3 = false
			OnJupiterNotice()
			wait(75)
			Special3 = true
		end
	end
end)
