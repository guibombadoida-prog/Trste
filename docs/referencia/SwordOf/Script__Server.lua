local tool = script.Parent
local remote = tool:WaitForChild("Remote")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local handle = tool:FindFirstChild("Handle")
local ServerStorage = game:GetService("ServerStorage")
local astralisuse = false
local SlashTrailModule = require(125275839196878)

local SearchChild = game.FindFirstChild and game.WaitForChild

local RNG, VEC3, New, fromRGB = math.random, Vector3.new, Instance.new, Color3.fromRGB

Clone, FFC, FFCOC = game.Clone, game.FindFirstChild, game.FindFirstChildOfClass

Self, Destroy, Inf, Seed = script, script.Destroy, math.huge, Random.new(tick())

local Grips = {
	Normal = tool:WaitForChild("CFrames", 10):WaitForChild("NormalGrip", 10).Value,
}

local elementData = {
	Color = Color3.fromRGB(1000,1000,1000)
}

local Deletables = {}

local playerElementIndex = {}

local function IsTeamMate(Player1, Player2)
	return (Player1 and Player2 and not Player1.Neutral and not Player2.Neutral and Player1.TeamColor == Player2.TeamColor)
end

function Motorize_Tool(char)
	--// Function Written by: @SonarHEXAGON, with a few modifications by @Yukikuramudo
	local Target_Hand = (char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand"));

	local Tool_Motor_Instance

	if Target_Hand then

		if not tool:IsDescendantOf(char) then
			return
		end

		local Grip = SearchChild(Target_Hand, "RightGrip", 10)

		coroutine.wrap(function()

			local Safety_Grip = Target_Hand:FindFirstChild("RightGrip_Motor");
			if Safety_Grip then
				Destroy(Safety_Grip);
				Safety_Grip = nil;
			end

			Tool_Motor_Instance = New("Motor6D", Target_Hand);
			Deletables[#Deletables + 1] = Tool_Motor_Instance;

			Tool_Motor_Instance.MaxVelocity = Inf;
			Tool_Motor_Instance.Name = "RightGrip_Motor"

			Tool_Motor_Instance.Part0 = Target_Hand;
			Tool_Motor_Instance.Part1 = handle;
			Tool_Motor_Instance.C0 = Grip.C0;
			Tool_Motor_Instance.C1 = Grips.Normal;

			Tool_Motor_Instance.Part0.AssemblyLinearVelocity = VEC3(0, 0, 0);
			Tool_Motor_Instance.Part1.AssemblyLinearVelocity = VEC3(0, 0, 0);


		end)();

		coroutine.wrap(function()
			Grip = Target_Hand:FindFirstChild("RightGrip");
			if Grip then
				Grip.Enabled = false;
			end
		end)();

	end

	return Tool_Motor_Instance;

end

local function doExplosionEffects(hrp, mainScript, elementData)
	local ServerStorage = game:GetService("ServerStorage")
	local vfxFolder = ServerStorage:FindFirstChild("CosmicVFX2")
	if vfxFolder then
		local explosionParts = {"Nova_Circle", "Nova_Wave"}
		for _, vfxName in ipairs(explosionParts) do
			local vfx = vfxFolder:FindFirstChild(vfxName)
			if vfx then
				local clone = vfx:Clone()
				clone.Position = hrp.Position
				local placefor = workspace:FindFirstChild("Gear Parts")

				clone.Parent = placefor or workspace

				
				if vfxName == "Nova_Circle" then
					local tween1 = mainScript:FindFirstChild("tween1")
					if tween1 then
						local tweenClone = tween1:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
						local sfx = script:FindFirstChild("Supernova"):Clone()
						sfx.Parent = clone
						sfx:Play()
					end
					
					clone.Position = hrp.Position + Vector3.new(0, 3, 0)
					
					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end

					-- Find 'Center' part and emit particles
					local center = clone:FindFirstChild("Center")
					if center and center:IsA("Attachment") then
						for _, particle in ipairs(center:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then
								wait()
								particle:Emit(30)
							end
						end
					end

				elseif vfxName == "Nova_Wave" then
					local tween2 = mainScript:FindFirstChild("Tween2")
					if tween2 then
						local tweenClone = tween2:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
					end
					
					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end
				end
				
				local Players = game:GetService("Players")
				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					local humanoidRoot = char and char:FindFirstChild("HumanoidRootPart")
					if humanoidRoot and (humanoidRoot.Position - clone.Position).Magnitude <= 150 then
						if not char:FindFirstChild("cosmostwjasdjdad") then
							local shakeScript = mainScript:FindFirstChild("ShakeCam")
							if shakeScript then
								local cloneShake = shakeScript:Clone()
								cloneShake.Parent = char
								cloneShake.Disabled = false
							end
						end
					end
				end

				game:GetService("Debris"):AddItem(clone, 7)
			end
		end
	end
end

local function ShurikenExplode(hrp, mainScript, elementData)
	local ServerStorage = game:GetService("ServerStorage")
	local vfxFolder = ServerStorage:FindFirstChild("CosmicVFX2")
	if vfxFolder then
		local explosionParts = {"Core", "MainCore", "WindWave","MegaWave"}
		for _, vfxName in ipairs(explosionParts) do
			local vfx = vfxFolder:FindFirstChild(vfxName)
			if vfx then
				local clone = vfx:Clone()
				clone.Position = hrp.Position
				local placefor = workspace:FindFirstChild("Gear Parts")

				clone.Parent = placefor or workspace

				-- Clone and parent tween scripts from main script
				if vfxName == "MainCore" then
					local tween1 = script:FindFirstChild("tween4")
					if tween1 then
						local tweenClone = tween1:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
						tweenClone:FindFirstChild("Size").Value = Vector3.new(41, 41, 41)
						local sfx = script:FindFirstChild("ShurikenExplode"):Clone()
						sfx.Parent = clone
						sfx:Play()
					end

					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end
					
				elseif vfxName == "Core" then
					local tween1 = script:FindFirstChild("tween4")
					if tween1 then
						local tweenClone = tween1:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
						tweenClone:FindFirstChild("Size").Value = Vector3.new(25, 25, 25)
					end
						
					local center = clone:FindFirstChild("Center")
					if center and center:IsA("Attachment") then
						for _, particle in ipairs(center:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then
								wait()
								particle:Emit(30)
							end
						end
					end
					
				elseif vfxName == "WindWave" then
					local tween2 = mainScript:FindFirstChild("Tween3")
					if tween2 then
						local tweenClone = tween2:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
						tweenClone:FindFirstChild("Size").Value = Vector3.new(100, 3, 100)
					end

					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end
					
				elseif vfxName == "MegaWave" then
					local tween2 = mainScript:FindFirstChild("tween4")
					if tween2 then
						local tweenClone = tween2:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
						tweenClone:FindFirstChild("Size").Value = Vector3.new(140, 0.4, 140)
						clone.Orientation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
					end

					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end
				end
				
				local Players = game:GetService("Players")
				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					local humanoidRoot = char and char:FindFirstChild("HumanoidRootPart")
					if humanoidRoot and (humanoidRoot.Position - clone.Position).Magnitude <= 150 then
						if not char:FindFirstChild("cosmostwjasdjdad") then
							local shakeScript = mainScript:FindFirstChild("ShakeCam")
							if shakeScript then
								local cloneShake = shakeScript:Clone()
								cloneShake.Parent = char
								cloneShake.Disabled = false
							end
						end
					end
				end


				game:GetService("Debris"):AddItem(clone, 7)
			end
		end
	end
end


local function TpExplode(hrp, mainScript, elementData)
	local ServerStorage = game:GetService("ServerStorage")
	local vfxFolder = ServerStorage:FindFirstChild("CosmicVFX2")
	if vfxFolder then
		local explosionParts = {"Explosion_Sphere", "Explosion_Wind"}
		for _, vfxName in ipairs(explosionParts) do
			local vfx = vfxFolder:FindFirstChild(vfxName)
			if vfx then
				local clone = vfx:Clone()
				clone.Position = hrp.Position
				local placefor = workspace:FindFirstChild("Gear Parts")
				clone.Parent = placefor or workspace

				for _, part in ipairs(clone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0.6
					end
				end

				if vfxName == "Explosion_Sphere" then
					local tween1 = mainScript:FindFirstChild("tweenball")
					if tween1 then
						local tweenClone = tween1:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false

						local sfx = mainScript:FindFirstChild("Explode")
						if sfx then
							local sfxClone = sfx:Clone()
							sfxClone.Parent = clone
							sfxClone:Play()
						end
					end

					if clone:IsA("BasePart") then
						clone.Color = elementData.Color
					end

					local center = clone:FindFirstChild("Center")
					if center and center:IsA("Attachment") then
						for _, particle in ipairs(center:GetDescendants()) do
							if particle:IsA("ParticleEmitter") then

								if particle.Name == "Explosion_Smoke" then
									particle.Size = NumberSequence.new{
										NumberSequenceKeypoint.new(0, 0),
										NumberSequenceKeypoint.new(1, 5)
									}

									particle.Speed = NumberRange.new(15.55)
								end
								
								if particle.Name == "Ember" then
									particle.Color = ColorSequence.new(Color3.new(1, 1, 1)) -- White
								end

								wait()
								particle:Emit(30)
							end
						end
					end

				elseif vfxName == "Explosion_Wind" then
					local tween2 = mainScript:FindFirstChild("tweenring")
					if tween2 then
						local tweenClone = tween2:Clone()
						tweenClone.Parent = clone
						tweenClone.Disabled = false
					end
				end

				game.Debris:AddItem(clone, 3)
			end
		end
	end
end

local function Supernova(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	local animFolder = tool:FindFirstChild("Animations")
	local slamAnim = animFolder and animFolder:FindFirstChild("R6") and animFolder.R6:FindFirstChild("Slam")
	local groundAnim = animFolder and animFolder:FindFirstChild("R6") and animFolder.R6:FindFirstChild("Unleash")

	local lock = 0.5
	local grounded = false

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local downRay = workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), rayParams)

	if downRay then
		-- 🧍 Grounded
		grounded = true
		local originalSpeed = 16
		humanoid.WalkSpeed = 0
		task.delay(lock, function()
			if humanoid then
				humanoid.WalkSpeed = originalSpeed
			end
		end)
	else
		local lockPosition = hrp.Position

		local bodyPos = Instance.new("BodyPosition")
		bodyPos.Name = "LockPosition"
		bodyPos.Position = lockPosition
		bodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyPos.D = 1000
		bodyPos.P = 30000
		bodyPos.Parent = hrp

		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.Name = "LockOrientation"
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		bodyGyro.D = 1000
		bodyGyro.P = 30000
		bodyGyro.Parent = hrp

		task.delay(lock, function()
			if bodyPos then bodyPos:Destroy() end
			if bodyGyro then bodyGyro:Destroy() end
		end)
	end

	if animator then
		if grounded and groundAnim and groundAnim:IsA("Animation") then
			local track = animator:LoadAnimation(groundAnim)
			track:Play()
			track:AdjustSpeed(1.25) -- slightly faster grounded anim
		elseif not grounded and slamAnim and slamAnim:IsA("Animation") then
			local track = animator:LoadAnimation(slamAnim)
			track:Play()
		end
	end

	task.wait(lock)

	doExplosionEffects(hrp, script, elementData)
	
	for _, target in ipairs(workspace:GetDescendants()) do
		if target:IsA("Model") and target ~= character then
			local root = target:FindFirstChild("HumanoidRootPart")
			local hum = target:FindFirstChildOfClass("Humanoid")
			local targetPlayer = Players:GetPlayerFromCharacter(target)

			local hasForceField = target:FindFirstChildOfClass("ForceField") ~= nil

			if root and hum and hum.Health > 0 and not hasForceField then
				if (root.Position - hrp.Position).Magnitude <= 80 then
					if targetPlayer and IsTeamMate(player, targetPlayer) then
						continue
					end

					-- Damage
					hum:TakeDamage(30)

					local tag = Instance.new("ObjectValue")
					tag.Name = "creator"
					tag.Value = player
					tag.Parent = hum
					Debris:AddItem(tag, 2)
					
					hum:UnequipTools()
					
					local direction = (root.Position - hrp.Position).Unit
					local randomUpDown = Vector3.new(math.random(), math.random(), math.random()) * 0.5 -- Random variation
					local knockback = Instance.new("BodyVelocity")
					knockback.Velocity = direction * 50 + Vector3.new(0, 100, 0) + randomUpDown  -- Apply moderate knockback
					knockback.MaxForce = Vector3.new(1e6, 1e6, 1e6)  -- High force for good knockback effect
					knockback.P = 5000
					knockback.Parent = root
					Debris:AddItem(knockback, 0.3)

					local angular = Instance.new("BodyAngularVelocity")
					angular.AngularVelocity = Vector3.new(0, 80, 0) + Vector3.new(math.random(), math.random(), math.random()) * 40  -- Moderate rotation
					angular.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
					angular.P = 2000
					angular.Parent = root
					Debris:AddItem(angular, 0.3)

					-- Trail effect
					local att1 = Instance.new("Attachment")
					att1.Name = "TrailAttachment1"
					att1.Position = Vector3.new(2, 0, 0)
					att1.Parent = root

					local att2 = Instance.new("Attachment")
					att2.Name = "TrailAttachment2"
					att2.Position = Vector3.new(-2, 0, 0)
					att2.Parent = root
					
					local smoke = script:FindFirstChild("Meteor_Smoke"):Clone()
					smoke.Parent = root
					smoke.Enabled = true
					
					local smoke2 = script:FindFirstChild("Meteor_Sparkles"):Clone()
					smoke2.Parent = root
					smoke2.Enabled = true
					
					Debris:AddItem(smoke2, 3)
					Debris:AddItem(smoke, 3)

					local trailTemplate = script:FindFirstChild("Launch_Trail")
					if trailTemplate and trailTemplate:IsA("Trail") then
						local trail = trailTemplate:Clone()
						trail.Attachment0 = att1
						trail.Attachment1 = att2
						trail.Enabled = true
						trail.Parent = root
						Debris:AddItem(trail, 6)
					end
				end
			end
		end
	end
end

tool.Equipped:Connect(function()	
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	local playerValue = tool:FindFirstChild("Player")

	if not playerValue then
		playerValue = Instance.new("ObjectValue")
		playerValue.Name = "Player"
		playerValue.Value = player
		playerValue.Parent = tool
	end

	if playerValue.Value ~= player then
		-- Set all parts to black
		for _, part in ipairs(handle.Sword:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = Color3.fromRGB(0, 0, 0)
			end
		end

		script:Destroy()
		return
	end

	local player = Players:GetPlayerFromCharacter(tool.Parent)
	if not player then return end
	
	local char = player.Character

	-- Play random equip sound
	local equipSounds = { "Equip1", "Equip2" }
	local randomName = equipSounds[math.random(1, #equipSounds)]
	local sound = handle:FindFirstChild(randomName)
	if sound and sound:IsA("Sound") then
		local cloned = sound:Clone()
		cloned.Parent = handle
		cloned:Play()
		Debris:AddItem(cloned, cloned.TimeLength + 1)
	end
	
	Motorize_Tool(char)
	
end)

tool.Activated:Connect(function()
	if not tool.Enabled then return end
	tool.Enabled = false

	local character = tool.Parent
	if not character or not character:IsA("Model") then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local handle = tool:FindFirstChild("Handle")
	if not humanoid or not handle or not root then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local animFolder = tool:FindFirstChild("Animations")
	local animSet = animFolder and animFolder:FindFirstChild("R6")
	local chosenAnim = "Spin"

	if animSet then
		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local isFloating = not grounded
		local foundLowerTarget = false

		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= character and obj.PrimaryPart then
				local enemyHumanoid = obj:FindFirstChildOfClass("Humanoid")
				if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end

				local enemyRoot = obj.PrimaryPart
				if obj:FindFirstChildOfClass("ForceField") then continue end

				local targetPlayer = Players:GetPlayerFromCharacter(obj)
				if IsTeamMate(player, targetPlayer) then continue end

				local distance = (enemyRoot.Position - root.Position).Magnitude
				if distance <= 25 and enemyRoot.Position.Y < root.Position.Y - 0.5 then
					foundLowerTarget = true
					break
				end
			end
		end

		if isFloating or foundLowerTarget then
			chosenAnim = "Ground"
		else
			local choices = { "Spin", "Stab" }
			chosenAnim = choices[math.random(1, #choices)]
		end

		-- Play animation
		local animObj = animSet:FindFirstChild(chosenAnim)
		local animator = humanoid:FindFirstChildWhichIsA("Animator") or humanoid:WaitForChild("Animator", 1)

		if animObj and animator then
			local animationTrack = animator:LoadAnimation(animObj)
			animationTrack:Play()

			if chosenAnim == "Spin" then
				animationTrack:AdjustSpeed(2)
			elseif chosenAnim == "Ground" then
				animationTrack:AdjustSpeed(2.3)
			else
				animationTrack:AdjustSpeed(1)
			end

			game:GetService("Debris"):AddItem(animationTrack, animationTrack.Length + 0.5)
		end
	end
	
	if chosenAnim == "Ground" then
		-- Fire Ground effect
		SlashTrailModule:FireAllClients("Cast_Effects", "Slash_Trail", root, 19, 1.3, Color3.fromRGB(1000, 1000, 1000), .25, CFrame.Angles(0, 0, 1.5), -2, 4)
	elseif chosenAnim == "Stab" then
		-- Fire Stab effect
		SlashTrailModule:FireAllClients("Cast_Effects", "Slash_Trail", root, 19, 1.3, Color3.fromRGB(1000, 1000, 1000), .25, CFrame.Angles(0, -.2, -.2), -2, 4)
	elseif chosenAnim == "Spin" then
		-- Fire Spin effect
		SlashTrailModule:FireAllClients("Cast_Effects", "Slash_Trail", root, 19, 1.3, Color3.fromRGB(1000, 1000, 1000), .25, CFrame.new(0, 0.4, 0), 2, -4)
	end

	-- Slash sound
	local slashSound = handle:FindFirstChild("Slash")
	if slashSound then
		local cloned = slashSound:Clone()
		cloned.Parent = handle
		cloned:Play()
		game:GetService("Debris"):AddItem(cloned, cloned.TimeLength + 1)
	end

	-- Enable trails briefly
	for _, trail in ipairs(handle:GetDescendants()) do
		if trail:IsA("Trail") then
			trail.Enabled = true
			task.delay(0.2, function()
				if trail then trail.Enabled = false end
			end)
		end
	end

	local touchedCooldown = {}
	local connection
	connection = handle.Touched:Connect(function(hit)
		local targetChar = hit:FindFirstAncestorOfClass("Model")
		if not targetChar or touchedCooldown[targetChar] then return end
		touchedCooldown[targetChar] = true
		task.delay(0.5, function()
			touchedCooldown[targetChar] = nil
		end)

		if targetChar == character then return end

		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if IsTeamMate(player, targetPlayer) then return end

		local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHum or not targetRoot or targetHum.Health <= 0 or targetChar:FindFirstChildOfClass("ForceField") then return end

		-- Damage
		targetHum:TakeDamage(40)
		
		local tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Value = player
		tag.Parent = targetHum
		game:GetService("Debris"):AddItem(tag, 2)

		-- VFX
		local part = Instance.new("Part")
		part.Name = "Slash"
		part.Size = Vector3.new(10, 10, 10)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Locked = true
		part.Position = targetRoot.Position
		part.Orientation = Vector3.new(math.random(-180,180), math.random(-180,180), math.random(-180,180))
		part.Material = Enum.Material.Neon
		part.Color = Color3.new(1,1,1)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part

		local container = workspace:FindFirstChild("Gear Parts")
		part.Parent = container or workspace

		-- Sounds
		local scarSound = script:FindFirstChild("Scar"):Clone()
		scarSound.Parent = targetRoot
		scarSound:Play()
		game:GetService("Debris"):AddItem(scarSound, 1)

		if chosenAnim == "Ground" then
			local spikeSound = script:FindFirstChild("Spike")
			if spikeSound then
				local spikeClone = spikeSound:Clone()
				spikeClone.Parent = targetRoot
				spikeClone:Play()
				game:GetService("Debris"):AddItem(spikeClone, 2)
			end
		end
		
		local tween = script:FindFirstChild("SlashTween"):Clone()
		tween.Parent = part
		tween.Enabled = true
		game:GetService("Debris"):AddItem(part, 0.5)
		
		if chosenAnim == "Spin" or chosenAnim == "Stab" then
			local direction = (targetRoot.Position - root.Position).Unit
			local randomUpDown = Vector3.new(math.random(), math.random(), math.random()) * 0.5
			local knockback = Instance.new("BodyVelocity")
			knockback.Velocity = direction * 25 + Vector3.new(0, 10, 0) + randomUpDown
			knockback.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			knockback.P = 1000
			knockback.Parent = targetRoot
			Debris:AddItem(knockback, 0.2)

			local angular = Instance.new("BodyAngularVelocity")
			angular.AngularVelocity = Vector3.new(0, 80, 0) + Vector3.new(math.random(), math.random(), math.random()) * 40  -- Moderate rotation
			angular.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			angular.P = 2000
			angular.Parent = targetRoot

			Debris:AddItem(angular, 0.1)
			local angular = Instance.new("BodyAngularVelocity")
			angular.AngularVelocity = Vector3.new(0, 80, 0) + Vector3.new(math.random(), math.random(), math.random()) * 40
			angular.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			angular.P = 2000
			angular.Parent = targetRoot
			Debris:AddItem(angular, 0.1)
		end
	end)

	task.delay(0.5, function()
		if connection then
			connection:Disconnect()
		end
	end)

	task.delay(0.5, function()
		tool.Enabled = true
	end)
end)

local elementEnable = true
local supernovaOn = true
local teleportOn = true
local fire = true
local astralcan = true

local activeShuriken = {}
local shurikenCooldown = {}


remote.OnServerEvent:Connect(function(player, keyCode)
	if keyCode == Enum.KeyCode.E and supernovaOn and astralisuse == false then
		supernovaOn = false
		Supernova(player)
		task.delay(15, function()
			supernovaOn = true
		end)
	elseif keyCode == Enum.KeyCode.Q and tool.Enabled == true then
		local character = player.Character
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local directionTarget = tool:FindFirstChild("DirectionInvoker")
		if not directionTarget then return end

		local serverStorage = game:GetService("ServerStorage")
		local cosmicFolder = serverStorage:FindFirstChild("CosmicVFX2")
		if not cosmicFolder then return end

		local shurikenModel = cosmicFolder:FindFirstChild("ShurikenModel")
		if not shurikenModel then return end

		if activeShuriken[player] and activeShuriken[player].Launched == false then
			activeShuriken[player].LaunchNow()
			return
		end

		if shurikenCooldown[player] then return end
		shurikenCooldown[player] = true
		task.delay(15, function()
			shurikenCooldown[player] = nil
		end)

		local Supernova = shurikenModel:Clone()
		Supernova.Name = "Supernova"
		Supernova.Parent = workspace
		
		game.Debris:AddItem(Supernova, 30)

		local PrimaryPart = Supernova.PrimaryPart
		if not PrimaryPart then return end

		PrimaryPart.Anchored = false
		PrimaryPart:SetNetworkOwner(nil)
		Supernova:MoveTo(hrp.Position + Vector3.new(0, 15, 0))
		
		PrimaryPart:FindFirstChild("Summon"):Play()
		wait()
		PrimaryPart:FindFirstChild("StarSplash"):Emit(30)

		-- Add creator reference
		local creator = Instance.new("ObjectValue")
		creator.Name = "Creator"
		creator.Value = player
		creator.Parent = Supernova

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local summonAnim = tool:FindFirstChild("Animations") and tool.Animations:FindFirstChild("R6") and tool.Animations.R6:FindFirstChild("Summon")

		if animator and summonAnim and summonAnim:IsA("Animation") then
			local track = animator:LoadAnimation(summonAnim)
			track:Play()
			track:AdjustSpeed(1.25)
		end

		-- Spin
		local spin = Instance.new("BodyAngularVelocity")
		spin.AngularVelocity = Vector3.new(0, 5, 0)
		spin.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		spin.P = 10000
		spin.Parent = PrimaryPart

		-- Follow hover
		local follow = Instance.new("BodyPosition")
		follow.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		follow.P = 50000
		follow.Position = PrimaryPart.Position
		follow.Parent = PrimaryPart

		local updatingFollow = true
		task.spawn(function()
			while updatingFollow and character and character:FindFirstChild("HumanoidRootPart") do
				follow.Position = hrp.Position + Vector3.new(0, 15, 0)
				task.wait(0.1)
			end
		end)


		for _, t in ipairs(Supernova:GetDescendants()) do
			if t:IsA("Trail") then
				t.Color = ColorSequence.new(Color3.fromRGB(21, 0, 255))
			end
		end
		
		local pulling = false
		local RunService = game:GetService("RunService")
		local lastHitTimestamps = {}
		local hitCooldown = 0.1 
		
		local function launchShuriken()
			if not Supernova or not Supernova.Parent then return end

			updatingFollow = false
			pulling = true
			if follow then follow:Destroy() end
			if activeShuriken[player] then activeShuriken[player] = nil end

			local mouseInfo = directionTarget:InvokeClient(player)
			if not mouseInfo or typeof(mouseInfo.Position) ~= "Vector3" then return end
			local mousePos = mouseInfo.Position

			local direction = (mousePos - PrimaryPart.Position).Unit
			local velocity = Instance.new("BodyVelocity")
			velocity.Velocity = direction * 100
			velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			velocity.P = 100000
			velocity.Parent = PrimaryPart
			
			local RunService = game:GetService("RunService")
			local Debris = game:GetService("Debris")
			
			local connection
			local darkenStep = 0.03
			local minColorValue = 0.01

			connection = PrimaryPart.Touched:Connect(function(hit)
				if not pulling then return end
				if not hit:IsDescendantOf(character) then
					local now = tick()
					if now - (lastHitTimestamps["__global"] or 0) < hitCooldown then return end
					lastHitTimestamps["__global"] = now

					local shurikenPart = Supernova:FindFirstChild("Shuriken")
					if shurikenPart and shurikenPart:IsA("BasePart") then
						local c = shurikenPart.Color
						local r = math.clamp(c.R - darkenStep, 0, 1)
						local g = math.clamp(c.G - darkenStep, 0, 1)
						local b = math.clamp(c.B - darkenStep, 0, 1)
						shurikenPart.Color = Color3.new(r, g, b)

						if r <= minColorValue and g <= minColorValue and b <= minColorValue then
							pulling = false
							if connection then connection:Disconnect() end

							-- AoE Damage on explode (within 50 studs)
							for _, descendant in ipairs(workspace:GetDescendants()) do
								if descendant:IsA("Humanoid") then
									local char = descendant.Parent
									if char and char:IsA("Model") and char ~= character and not char:FindFirstChildOfClass("ForceField") then
										local root = char:FindFirstChild("HumanoidRootPart")
										if root and (root.Position - PrimaryPart.Position).Magnitude <= 50 then
											if descendant.Health > 0 then
												local plr = game.Players:GetPlayerFromCharacter(char)
												if not plr or not IsTeamMate(player, plr) then
													
													descendant:TakeDamage(10)
													
													local char = hit:FindFirstAncestorOfClass("Model")
													local hum = char and char:FindFirstChildOfClass("Humanoid")
													
													local direction = (root.Position - hrp.Position).Unit
													local randomUpDown = Vector3.new(math.random(), math.random(), math.random()) * 0.5 -- Random variation
													local knockback = Instance.new("BodyVelocity")
													knockback.Velocity = direction * 35 + Vector3.new(0, 30, 0) + randomUpDown  -- Apply moderate knockback
													knockback.MaxForce = Vector3.new(1e6, 1e6, 1e6)  -- High force for good knockback effect
													knockback.P = 2000
													knockback.Parent = root
													Debris:AddItem(knockback, 0.3)

													local angular = Instance.new("BodyAngularVelocity")
													angular.AngularVelocity = Vector3.new(0, 80, 0) + Vector3.new(math.random(), math.random(), math.random()) * 40  -- Moderate rotation
													angular.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
													angular.P = 2000
													angular.Parent = root
													Debris:AddItem(angular, 0.3)

													if hum and not hum:FindFirstChild("Creator") then
														local creator = Instance.new("ObjectValue")
														creator.Name = "Creator"
														creator.Value = player
														creator.Parent = hum
														
														Debris:AddItem(creator, 2)
													end
												end
											end
										end
									end
								end
							end

							ShurikenExplode(PrimaryPart, script, elementData)
							Supernova:Destroy()
							return
						end
					end

					-- FX only
					local fx = Instance.new("Part")
					fx.Size = Vector3.new(30, 30, 30)
					fx.Anchored = true
					fx.CanCollide = false
					fx.Position = PrimaryPart.Position
					fx.Material = Enum.Material.Neon
					fx.Color = Color3.new(1, 1, 1)
					fx.Orientation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
					Instance.new("SpecialMesh", fx).MeshType = Enum.MeshType.Sphere
					fx.Parent = workspace:FindFirstChild("Gear Parts") or workspace

					local cutSound = script:FindFirstChild("ShuriHit"):Clone()
					cutSound.Parent = PrimaryPart
					cutSound:Play()

					local tween = script:FindFirstChild("SlashTween"):Clone()
					tween.Parent = fx
					tween.Enabled = true

					Debris:AddItem(fx, 0.5)
					Debris:AddItem(cutSound, 1)
				end
			end)
		end
		
		RunService.Heartbeat:Connect(function()
			if not pulling or not PrimaryPart then return end

			local now = tick()
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc:IsA("Humanoid") then
					local char = desc.Parent
					if char and char:IsA("Model") and char ~= character and not char:FindFirstChildOfClass("ForceField") then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						local targetPlayer = Players:GetPlayerFromCharacter(char)

						if hrp and (hrp.Position - PrimaryPart.Position).Magnitude <= 20 then
							-- Ignore if target is a teammate
							if targetPlayer and IsTeamMate(player, targetPlayer) then
								continue
							end

							if not lastHitTimestamps[char] or now - lastHitTimestamps[char] >= hitCooldown then
								lastHitTimestamps[char] = now

								-- Pull
								hrp.Velocity = Vector3.zero
								hrp.CFrame = CFrame.new(PrimaryPart.Position) * hrp.CFrame.Rotation

								desc:TakeDamage(5)

								local creator = Instance.new("ObjectValue")
								creator.Name = "Creator"
								creator.Value = player
								creator.Parent = desc

								game.Debris:AddItem(creator, 1)

								-- Attach Creator tag to the shuriken if not already there
								if not PrimaryPart:FindFirstChild("Creator") then
									local creator = Instance.new("ObjectValue")
									creator.Name = "Creator"
									creator.Value = player
									creator.Parent = PrimaryPart
								end
							end
						end
					end
				end
			end
		end)
		
		activeShuriken[player] = {
			Model = Supernova,
			Launched = false,
			LaunchNow = function()
				if activeShuriken[player] then
					activeShuriken[player].Launched = true
					launchShuriken()
				end
			end
		}

		-- Launch after 5s if not launched early
		task.delay(3, function()
			if activeShuriken[player] and not activeShuriken[player].Launched then
				activeShuriken[player].Launched = true
				launchShuriken()
			end
		end)
	elseif keyCode == Enum.KeyCode.X and teleportOn == true and astralisuse == false then
		teleportOn = false

		task.delay(10, function()
			teleportOn = true
		end)

		local directionTarget = tool:FindFirstChild("DirectionInvoker")
		if not directionTarget then return end

		local Remote = tool:WaitForChild("StartHeadCamera")

		local mouseInfo = directionTarget:InvokeClient(player)
		if not mouseInfo or typeof(mouseInfo.Position) ~= "Vector3" then return end

		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then return end

		local startPos = hrp.Position
		local maxDistance = 500
		
		local rawTargetPos = mouseInfo.Position

		local rayOrigin = rawTargetPos
		local rayDirection = Vector3.new(0, -10, 0)  -- Short downward check

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {player.Character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.IgnoreWater = false

		local groundHit = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		local finalTargetPos

		if groundHit then
			finalTargetPos = groundHit.Position
		else
			local directionVec = rawTargetPos - hrp.Position
			local distance = directionVec.Magnitude

			if distance > maxDistance then
				finalTargetPos = hrp.Position + directionVec.Unit * maxDistance
			else
				finalTargetPos = rawTargetPos
			end
		end

		local targetPos = finalTargetPos

		humanoid:UnequipTools()

		local sound = script:FindFirstChild("TeleportActive")
		if sound then
			local clonedSound = sound:Clone()
			clonedSound.Parent = hrp
			clonedSound:Play()
			game:GetService("Debris"):AddItem(clonedSound, 3)
			
			local teleportParticles = handle:FindFirstChild("starTip"):Clone()
			teleportParticles.Parent = hrp
			teleportParticles.Sparkles.Enabled = true
		end

		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 1
			end
		end

		if humanoid and humanoid.Health > 0 then
			Remote:FireClient(player, true)
			
		else
			Remote:FireClient(player, false)
			
		end
		
		local targetModel = nil
		local lockRange = math.huge
		
		local nextPos 
		
		local diedConnection
		if humanoid then
			diedConnection = humanoid.Died:Connect(function()
				if Remote then
					Remote:FireClient(player, false)
				end
			end)
		end

		local rayOrigin = hrp.Position
		local rayDirection = (targetPos - rayOrigin).Unit * 1000

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {char}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.IgnoreWater = true

		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if result and result.Instance then
			local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel ~= char and hitModel:FindFirstChildOfClass("Humanoid") then
				local hum = hitModel:FindFirstChildOfClass("Humanoid")
				local root = hitModel:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 and (root.Position - targetPos).Magnitude <= lockRange then
					local plr = game.Players:GetPlayerFromCharacter(hitModel)
					if not plr or not IsTeamMate(player, plr) then
						targetModel = hitModel
					end
				end
			end
		end

		if targetModel then
			local lockedOnSound = script:FindFirstChild("Locked On")
			if lockedOnSound then
				local soundClone = lockedOnSound:Clone()
				soundClone.Parent = hrp
				soundClone:Play()
				game:GetService("Debris"):AddItem(soundClone, 3)
			end
		end

		local distance = (targetPos - startPos).Magnitude
		local maxSegmentLength = 25
		local segmentCount = math.max(5, math.ceil(distance / maxSegmentLength))
		local lastPos = startPos
		local starPositions = {}
		local partsToDestroy = {}

		local bodyPos = Instance.new("BodyPosition")
		bodyPos.Name = "AntiFallPosition"
		bodyPos.MaxForce = Vector3.new(1e7, 1e7, 1e7)
		bodyPos.P = 1e5
		bodyPos.D = 1e3
		bodyPos.Position = startPos
		bodyPos.Parent = hrp
		
		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.Name = "LockOrientation"
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bodyGyro.P = 1e9
		bodyGyro.D = 1e9
		bodyGyro.Parent = hrp

		for i = 1, segmentCount do
			local alpha = i / segmentCount

			if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
				targetPos = targetModel.HumanoidRootPart.Position
			end

			local basePos = startPos:Lerp(targetPos, alpha)
			local offset = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
			local desiredPos = basePos + offset

			local moveVec = desiredPos - bodyPos.Position
			local dist = moveVec.Magnitude

			if dist > math.huge then
				desiredPos = bodyPos.Position + moveVec.Unit * math.huge
			end

			bodyPos.Position = desiredPos

			-- Visual trail
			local trail = Instance.new("Part")
			trail.Size = Vector3.new(0.2, 0.2, (desiredPos - lastPos).Magnitude)
			trail.Anchored = true
			trail.CanCollide = false
			trail.Material = Enum.Material.Neon
			trail.Color = Color3.fromRGB(167, 255, 255)
			trail.CFrame = CFrame.new((lastPos + desiredPos) / 2, desiredPos)
			trail.Parent = workspace:FindFirstChild("Gear Parts") or workspace

			local star = Instance.new("Part")
			star.Shape = Enum.PartType.Ball
			star.Size = Vector3.new(0.7, 0.7, 0.7)
			star.Anchored = true
			star.CanCollide = false
			star.Material = Enum.Material.Neon
			star.Color = Color3.new(1, 1, 1)
			star.CFrame = CFrame.new(desiredPos)
			star.Parent = workspace:FindFirstChild("Gear Parts") or workspace

			local startip = handle:FindFirstChild("starTip"):Clone()
			startip.Parent = star
			startip.StarEmitter.Enabled = true

			local star1 = handle.ParticleHolder.Star:Clone()
			star1.Parent = star
			star1.Lifetime = NumberRange.new(0.5)
			wait()
			star1:Emit(1)

			table.insert(partsToDestroy, trail)
			table.insert(partsToDestroy, star)
			table.insert(starPositions, star.Position)
			
			hrp.CFrame = CFrame.new(desiredPos)
			lastPos = desiredPos

			Debris:AddItem(trail, 80)
			Debris:AddItem(star, 80)

			-- Break early if close to target
			if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
				local distToTarget = (targetModel.HumanoidRootPart.Position - desiredPos).Magnitude
				if distToTarget <= 2 then
					break
				end
			end

			task.wait(0.1)
		end

		-- Get final target position (without random offset)
		local finalTargetPosition = nil

		if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
			finalTargetPosition = targetModel.HumanoidRootPart.Position
		else
			finalTargetPosition = targetPos
		end

		local rayOrigin = finalTargetPosition + Vector3.new(0, 15, 0)
		local rayDirection = Vector3.new(0, -15, 0)

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.IgnoreWater = false

		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		local finalLandingPos = finalTargetPosition
		if result then
			finalLandingPos = result.Position + Vector3.new(0, 2.5, 0)
		end

		-- Apply final position
		hrp.CFrame = CFrame.new(finalLandingPos)
		bodyPos.Position = finalLandingPos

		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 0
			end
		end

		local antiFall = hrp:FindFirstChild("AntiFallPosition")
		if antiFall then
			antiFall:Destroy()
			bodyGyro:Destroy()
		end
		
		Remote:FireClient(player, false)
		
		task.wait(0.1)

		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack and tool:IsDescendantOf(backpack) then
			humanoid:EquipTool(tool)
		end
		
		if hrp:FindFirstChild("starTip") then
			hrp.starTip:Destroy()
		end

		for _, part in ipairs(partsToDestroy) do
			if part and part.Parent then
				part:Destroy()
			end
		end

		for _, pos in ipairs(starPositions) do
			local fakeRoot = Instance.new("Part")
			fakeRoot.Position = pos
			fakeRoot.Anchored = true
			fakeRoot.CanCollide = false
			fakeRoot.Transparency = 1
			fakeRoot.Name = "FakeExplosionAnchor"
			fakeRoot.Parent = workspace:FindFirstChild("Gear Parts") or workspace

			TpExplode(fakeRoot, script, elementData)

			game:GetService("Debris"):AddItem(fakeRoot, 3) -- Destroy after 3 seconds
		end

		for _, pos in ipairs(starPositions) do
			for _, model in ipairs(workspace:GetDescendants()) do
				local hum = model:FindFirstChildOfClass("Humanoid")
				local root = model:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 and (root.Position - pos).Magnitude <= 20 then
					if model ~= char and not model:FindFirstChildOfClass("ForceField") then
						local plr = game.Players:GetPlayerFromCharacter(model)
						if not plr or not IsTeamMate(player, plr) then
							
							hum:TakeDamage(10)

							local creator = Instance.new("ObjectValue")
							creator.Name = "Creator"
							creator.Value = player
							creator.Parent = hum
							game:GetService("Debris"):AddItem(creator, 1)
						end
					end
				end
			end
		end
	end
end)