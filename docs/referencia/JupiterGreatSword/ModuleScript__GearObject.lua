local GearManagerSetting = {};
local Statuses = require(11484159494)
local Gear_Manager = require(6645113937)


function GearManagerSetting:AnimPlay(Object,ObjectAnim,Speed,LoopedEnabled)
	if not Object.Humanoid:FindFirstChild("Animator") then
		local Animator = Instance.new("Animator")
		Animator.Parent = Object.Humanoid
	end
	local Track = Object.Humanoid:LoadAnimation(ObjectAnim)
	Track:Play()
	Track.Looped = LoopedEnabled
	Track:AdjustSpeed(Speed)
	return Track
end


function GearManagerSetting:AnimStop(Object,ObjectAnim)
	if not Object.Humanoid:FindFirstChild("Animator") then
		local Animator = Instance.new("Animator")
		Animator.Parent = Object.Humanoid
	end
	local Track = Object.Humanoid:LoadAnimation(ObjectAnim)
	Track:Stop()
	return Track
end

function GearManagerSetting:TakeDamage(Object,Damage)
	Object.Humanoid:TakeDamage(Damage)
end

function GearManagerSetting:UnEquipToolsBreak(Object,SoundIds,Duration)
	Object.UnequipTools()
	local Soundis = Instance.new("Sound")
	SoundIds.Name = "BreakTool"
	SoundIds.SoundId = SoundIds
	SoundIds.Parent = workspace
	SoundIds:Play()
	for i=1,Duration do
		game["Run Service"].RenderStepped:Wait()
		Object.UnequipTools()
	end
end

function GearManagerSetting:StatusesEffect(Instanced,Duration,Statuseds,CreatorName)
	if not Instanced then return end
	
	local StausesEffectScript = (Instanced:FindFirstChild(Statuseds) or Gear_Manager:Status_Effect(Statuseds));
	
	local Duration = (StausesEffectScript:FindFirstChild("Duration") or Gear_Manager:Create("NumberValue")){
		Name = "Duration";
		Value = Duration
	}
	
	local Creator = (StausesEffectScript:FindFirstChild("Creator") or Gear_Manager:Create("ObjectValue")){
		Name = "Creator";
		Value = CreatorName
	}
	
	StausesEffectScript.Enabled = true
	StausesEffectScript.Parent = Instanced
	
	
end

function GearManagerSetting:BossChatterPlayer(Text,Timer,ColorText,StrokeColor)
	local Dialogue = script.Dialouge:Clone()
	Dialogue.Enabled = true
	Dialogue.Parent = game.StarterGui
	Dialogue.TextLabel.TextColor3 = ColorText
	Dialogue.TextLabel.UIStroke.Color = StrokeColor
	for i=1,string.len(Text) do
		Dialogue.TextLabel.Text = string.sub(Text, 1, i)
		local InstanceSound = Instance.new("Sound")
		InstanceSound.Name = "VoiceSpeech"
		InstanceSound.SoundId = "rbxassetid://6564956178"
		InstanceSound.Parent = Dialogue
		InstanceSound.Pitch = (math.random(800,1200)/1000)
		InstanceSound.Volume = 10
		InstanceSound:Play()
		game.Debris:AddItem(InstanceSound,1.15)
		wait(Timer)
	end
	wait(0.955)
	for i=1,45 do
		Dialogue.TextLabel.TextTransparency += 0.05
		Dialogue.TextLabel.UIStroke.Transparency += 0.05
		wait(0)
	end
	Dialogue:Destroy()
end

function GearManagerSetting:YouChatterPlayer(Player,Text,Timer,ColorText,StrokeColor)
	local Player = game:GetService("Players"):GetPlayerFromCharacter(Player)
	local Dialogue = script.Dialouge:Clone()
	Dialogue.Enabled = true
	Dialogue.Parent = Player.PlayerGui
	Dialogue.TextLabel.TextColor3 = ColorText
	Dialogue.TextLabel.UIStroke.Color = StrokeColor
	for i=1,string.len(Text) do
		Dialogue.TextLabel.Text = string.sub(Text, 1, i)
		local InstanceSound = Instance.new("Sound")
		InstanceSound.Name = "VoiceSpeech"
		InstanceSound.SoundId = "rbxassetid://6564956178"
		InstanceSound.Parent = Dialogue
		InstanceSound.Pitch = (math.random(800,1200)/1000)
		InstanceSound.Volume = 10
		InstanceSound:Play()
		game.Debris:AddItem(InstanceSound,1.15)
		wait(Timer)
	end
	wait(0.955)
	for i=1,45 do
		Dialogue.TextLabel.TextTransparency += 0.05
		Dialogue.TextLabel.UIStroke.Transparency += 0.05
		wait(0)
	end
	Dialogue:Destroy()
end

return GearManagerSetting;
