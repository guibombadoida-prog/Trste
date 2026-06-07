-- ServerScript_GranadaTatica_V1.lua
-- Coloque DENTRO da Tool "GranadaTatica" com o nome "Script"
-- NOVO SCRIPT (não substitui nenhum — unifica habilidades de bomba)

--[[
═══════════════════════════════════════════════════════════════
          GRANADA TÁTICA - SERVER SCRIPT V1
═══════════════════════════════════════════════════════════════
DESCRIÇÃO:
  Tool unificada de bombas LEVES com 3 habilidades:

  CLIQUE — BOMBA DOIDA
    Spawna uma bomba que rola no chão e persegue o inimigo mais próximo
    Quanto mais tempo viva → mais vermelha e mais rápida
    Explode no contato com inimigo
    Auto-explode após 10s se não achar ninguém
    Cooldown: 4s

  BOTÃO 1 (F / Mobile) — FILA DE BOMBAS
    Posiciona 7 bombas no chão na direção do olhar do jogador
    Espaçamento de 3 studs entre cada
    Explodem em sequência (uma após a outra)
    Cooldown: 8s

  BOTÃO 2 (G / Mobile) — AUTO DESTRUIÇÃO
    Explosão centrada no próprio jogador após delay de 2s
    Dano em área ao redor, incluindo o próprio jogador
    Cooldown: 15s

SCRIPTS REUTILIZADOS:
  - Script_MultipleBombs_V1_4   → IsAlly, DealDamage, createExplosionEffect
  - ServerScript_BombaAdesiva_V1 → sistema de lançamento Majima (bomba doida)
  - ServerScript_BombaMeteórica_V3 → padrão NPC (findNearestTorso)
  - Auto Destruição original     → mecânica de explosão centrada no jogador
    SFX: rbxassetid://5693336619

SISTEMA: Anti-friendly fire | NPC compatível | Cross-platform
═══════════════════════════════════════════════════════════════
--]]

--[[
═══════════════════════════════════════════════════════════════
                  CONFIGURAÇÕES CUSTOMIZÁVEIS
═══════════════════════════════════════════════════════════════
--]]

local CONFIG = {
	-- ========== BOMBA DOIDA (Clique) ==========
	CrazyBomb_Damage = 25,
	CrazyBomb_ExplosionRadius = 16,
	CrazyBomb_ExplosionScale = 1.0,
	CrazyBomb_Cooldown = 4,
	CrazyBomb_MaxLifetime = 10, -- segundos antes de auto-explodir
	CrazyBomb_ChaseRange = 60, -- raio de detecção de inimigos
	CrazyBomb_BaseSpeed = 18, -- velocidade inicial
	CrazyBomb_MaxSpeed = 55, -- velocidade máxima aos 10s
	CrazyBomb_KnockbackForce = 40,

	-- ========== FILA DE BOMBAS (Botão 1) ==========
	BombLine_Count = 7,
	BombLine_Spacing = 3, -- studs entre cada bomba
	BombLine_Damage = 18,
	BombLine_ExplosionRadius = 12,
	BombLine_ExplosionScale = 0.7,
	BombLine_DetonationDelay = 0.35, -- delay entre cada explosão
	BombLine_Cooldown = 8,
	BombLine_KnockbackForce = 30,

	-- ========== AUTO DESTRUIÇÃO (Botão 2) ==========
	SelfDestruct_Damage = 40,
	SelfDestruct_ExplosionRadius = 18,
	SelfDestruct_ExplosionScale = 1.3,
	SelfDestruct_ChargeTime = 2, -- segundos antes de explodir
	SelfDestruct_SelfDamage = 20, -- dano no próprio jogador
	SelfDestruct_Cooldown = 15,
	SelfDestruct_KnockbackForce = 55,

	-- ========== SONS (SFX) ==========
	-- Explosão padrão (reutilizado de MultipleBombs)
	ExplosionSoundID = "rbxassetid://12222065",
	-- Explosão pesada (auto destruição)
	HeavyExplosionID = "rbxassetid://3636730677",
	-- Charge/fuse da auto destruição (do script original)
	SelfDestructChargeID = "rbxassetid://5693336619",
	-- Som de rolagem da bomba doida
	RollingSoundID = "rbxassetid://12222084",
	-- Som de spawn/posicionar bomba na fila
	PlaceBombSoundID = "rbxassetid://131092162",
	-- Som de sequência detonando
	FuseTickSoundID = "rbxassetid://138189916",

	-- ========== CLUSTER DE PLASMA (Skill3 / R) ==========
	Cluster_Damage = 22,
	Cluster_ExplosionRadius = 14,
	Cluster_ExplosionScale = 1.0,
	Cluster_SubCount = 7,
	Cluster_SubRadius = 9,
	Cluster_SubScale = 0.6,
	Cluster_SubSpread = 13,
	Cluster_TravelSpeed = 75,
	Cluster_MaxTravel = 3.5,
	Cluster_Cooldown = 9,
	Cluster_KnockbackForce = 35,
	PlasmaColor1 = "Bright violet",
	PlasmaColor2 = "Cyan",

	-- ========== CHUVA DE METEOROS (Skill4 / T) ==========
	Meteor_Count = 6,
	Meteor_Damage = 20,
	Meteor_ExplosionRadius = 13,
	Meteor_ExplosionScale = 0.9,
	Meteor_AreaRadius = 18,
	Meteor_FallHeight = 95,
	Meteor_FallTime = 0.65,
	Meteor_Interval = 0.16,
	Meteor_Cooldown = 12,
	Meteor_KnockbackForce = 30,
	MeteorColor1 = "Bright orange",
	MeteorColor2 = "Really red",
}

--[[
═══════════════════════════════════════════════════════════════
        TABELAS PRÉ-DEFINIDAS (SUBSTITUI math.random)
═══════════════════════════════════════════════════════════════
--]]

-- Cores da Bomba Doida: verde → amarelo → laranja → vermelho
-- 10 estágios representando 0% a 100% do tempo de vida
local CRAZY_BOMB_COLORS = {
	Color3.fromRGB(50, 200, 50), -- 0% - verde
	Color3.fromRGB(100, 200, 30), -- 10%
	Color3.fromRGB(150, 200, 20), -- 20%
	Color3.fromRGB(200, 200, 10), -- 30% - amarelo-verde
	Color3.fromRGB(220, 180, 0), -- 40% - amarelo
	Color3.fromRGB(240, 140, 0), -- 50% - laranja
	Color3.fromRGB(250, 100, 0), -- 60% - laranja escuro
	Color3.fromRGB(255, 60, 0), -- 70% - vermelho-laranja
	Color3.fromRGB(255, 30, 0), -- 80% - vermelho
	Color3.fromRGB(255, 0, 0), -- 90-100% - vermelho puro
}

-- Tamanhos de partícula da Bomba Doida por estágio (pulso crescente)
local CRAZY_BOMB_PARTICLE_SIZES = { 0.5, 0.7, 0.9, 1.1, 1.4, 1.7, 2.0, 2.5, 3.0, 3.5 }

-- Ângulos pré-definidos para debris de explosão (8 entradas, ciclo)
local DEBRIS_DIRECTIONS = {
	Vector3.new(1.0, 0.6, 0.0).Unit,
	Vector3.new(0.7, 0.5, 0.7).Unit,
	Vector3.new(0.0, 0.7, 1.0).Unit,
	Vector3.new(-0.7, 0.5, 0.7).Unit,
	Vector3.new(-1.0, 0.6, 0.0).Unit,
	Vector3.new(-0.7, 0.5, -0.7).Unit,
	Vector3.new(0.0, 0.7, -1.0).Unit,
	Vector3.new(0.7, 0.5, -0.7).Unit,
}

local DEBRIS_SIZES = {
	Vector3.new(1.5, 1.0, 1.5),
	Vector3.new(1.0, 1.5, 1.0),
	Vector3.new(2.0, 0.8, 1.2),
	Vector3.new(1.2, 1.2, 2.0),
	Vector3.new(0.8, 1.8, 1.0),
	Vector3.new(1.8, 1.0, 0.8),
	Vector3.new(1.0, 0.8, 1.8),
	Vector3.new(1.4, 1.4, 1.4),
}

--[[
═══════════════════════════════════════════════════════════════
                    CÓDIGO PRINCIPAL
═══════════════════════════════════════════════════════════════
--]]

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local RemoteEvent = Tool:WaitForChild("RemoteEvent")
local Skill1Event = Tool:WaitForChild("Skill1")
local Skill2Event = Tool:WaitForChild("Skill2")
local Skill3Event = Tool:WaitForChild("Skill3")
local Skill4Event = Tool:WaitForChild("Skill4")

local Services = {
	Players = game:GetService("Players"),
	Debris = game:GetService("Debris"),
	RunService = game:GetService("RunService"),
	TweenService = game:GetService("TweenService"),
}

local owner = nil
local character = nil
local humanoid = nil
local equipped = false

local lastCrazyBombTime = 0
local lastBombLineTime = 0
local lastSelfDestructTime = 0
local lastClusterTime = 0
local lastMeteorTime = 0

local deathCleanupConn = nil
local debrisIndex = 1

local ActiveEffects = {
	Parts = {},
	Sounds = {},
	Connections = {},
	Coroutines = {},
}

-- ========== CONFIGURAÇÕES OBRIGATÓRIAS ==========
Tool.CanBeDropped = false
Tool.RequiresHandle = true
Tool.ToolTip = "Granada Tática - 5 habilidades (clique, F, G, R, T)"
Tool.Enabled = true

-- ========== ÍNDICE CÍCLICO (sem math.random) ==========
local function NextDebrisIndex()
	local idx = debrisIndex
	debrisIndex = (debrisIndex % #DEBRIS_DIRECTIONS) + 1
	return idx
end

-- ========== SISTEMA ANTI-FRIENDLY FIRE ==========
-- Reutilizado de: Script_MultipleBombs_V1_4
local function IsAlly(character1, character2)
	if not character1 or not character2 then
		return false
	end
	if character1 == character2 then
		return true
	end

	local player1 = Services.Players:GetPlayerFromCharacter(character1)
	local player2 = Services.Players:GetPlayerFromCharacter(character2)

	if player1 and player2 then
		if not player1.Neutral and not player2.Neutral then
			return player1.Team == player2.Team
		end
	end

	if
		character1:FindFirstChild("PossessFollow") and character2:FindFirstChild("PossessFollow")
	then
		return character1.PossessFollow.Owner.Value == character2.PossessFollow.Owner.Value
	end
	if character1:FindFirstChild("SuitFollow") and character2:FindFirstChild("SuitFollow") then
		return character1.SuitFollow.Owner.Value == character2.SuitFollow.Owner.Value
	end
	if
		character1:FindFirstChild("ControlFollow") and character2:FindFirstChild("ControlFollow")
	then
		return character1.ControlFollow.Owner.Value == character2.ControlFollow.Owner.Value
	end

	return false
end

-- ========== LIMPEZA COMPLETA ==========
local function CleanupAllEffects()
	for _, part in pairs(ActiveEffects.Parts) do
		if part and part.Parent then
			part.Transparency = 1
			part.CanCollide = false
			Services.Debris:AddItem(part, 0.1)
		end
	end
	ActiveEffects.Parts = {}

	for _, sound in pairs(ActiveEffects.Sounds) do
		if sound and sound.Parent then
			sound:Stop()
		end
	end
	ActiveEffects.Sounds = {}

	for _, connection in pairs(ActiveEffects.Connections) do
		if connection then
			connection:Disconnect()
		end
	end
	ActiveEffects.Connections = {}

	for _, thread in pairs(ActiveEffects.Coroutines) do
		if thread then
			task.cancel(thread)
		end
	end
	ActiveEffects.Coroutines = {}
end

local function AddPart(part, lifetime)
	table.insert(ActiveEffects.Parts, part)
	if lifetime then
		Services.Debris:AddItem(part, lifetime)
	end
	return part
end

local function AddSound(sound, autoDestroy)
	table.insert(ActiveEffects.Sounds, sound)
	if autoDestroy then
		sound.Ended:Connect(function()
			sound.Parent = nil
		end)
	end
	return sound
end

local function PlaySoundAt(parent, soundId, volume, looped)
	if soundId == "rbxassetid://0" then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 1.5
	s.Looped = looped or false
	s.RollOffMode = Enum.RollOffMode.Inverse
	s.Parent = parent
	s:Play()
	AddSound(s, not looped)
	return s
end

-- ========== DANO EM ÁREA ==========
-- Reutilizado de: Script_MultipleBombs_V1_4
local function DealDamage(position, radius, damage, knockback, attackerCharacter, hitSelf)
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("Humanoid") and v.Health > 0 then
			local rootPart = v.RootPart
				or v.Parent:FindFirstChild("HumanoidRootPart")
				or v.Parent:FindFirstChild("Torso")
			if rootPart then
				local distance = (rootPart.Position - position).Magnitude
				if distance < radius then
					local victimCharacter = v.Parent

					-- Auto Destruição: pode dar dano no próprio jogador
					if hitSelf and victimCharacter == attackerCharacter then
						v:TakeDamage(CONFIG.SelfDestruct_SelfDamage)
					elseif not IsAlly(attackerCharacter, victimCharacter) then
						v:TakeDamage(damage)

						if knockback and knockback > 0 then
							local direction = (rootPart.Position - position).Unit
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bv.P = 10000000
							bv.Velocity = direction * knockback
							bv.Parent = rootPart
							Services.Debris:AddItem(bv, 0.2)
						end
					end
				end
			end
		end
	end
end

-- ========== EFEITO DE EXPLOSÃO ==========
-- Reutilizado de: Script_MultipleBombs_V1_4 / ServerScript_BombaAdesiva_V1
local function CreateExplosionEffect(position, scale, color1, color2, soundId)
	scale = scale or 1
	color1 = color1 or BrickColor.new("Deep orange")
	color2 = color2 or BrickColor.new("Bright red")
	soundId = soundId or CONFIG.ExplosionSoundID

	-- Esfera principal (core)
	local ef1 = Instance.new("Part")
	ef1.Name = "ExplosionCore"
	ef1.BrickColor = color1
	ef1.CastShadow = false
	ef1.Material = Enum.Material.Neon
	ef1.Size = Vector3.new(4, 4, 4) * scale
	ef1.CFrame = CFrame.new(position)
	ef1.CanCollide = false
	ef1.CanTouch = false
	ef1.CanQuery = false
	ef1.Anchored = true
	ef1.Shape = Enum.PartType.Ball
	ef1.Parent = workspace
	AddPart(ef1, 2.5)

	-- Onda de choque (shockwave)
	local ef2 = Instance.new("Part")
	ef2.Name = "ExplosionShock"
	ef2.BrickColor = color2
	ef2.CastShadow = false
	ef2.Material = Enum.Material.Neon
	ef2.Size = Vector3.new(8, 8, 8) * scale
	ef2.Transparency = 0.3
	ef2.CFrame = CFrame.new(position)
	ef2.CanCollide = false
	ef2.CanTouch = false
	ef2.CanQuery = false
	ef2.Anchored = true
	ef2.Shape = Enum.PartType.Ball
	ef2.Parent = workspace
	AddPart(ef2, 2.5)

	-- Anel de impacto (ring)
	local ring = Instance.new("Part")
	ring.Name = "ExplosionRing"
	ring.BrickColor = color1
	ring.Material = Enum.Material.Neon
	ring.Size = Vector3.new(2, 0.3, 2) * scale
	ring.CFrame = CFrame.new(position)
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Anchored = true
	ring.Transparency = 0.3
	ring.Parent = workspace
	AddPart(ring, 2.5)

	local ringMesh = Instance.new("SpecialMesh")
	ringMesh.MeshType = Enum.MeshType.Cylinder
	ringMesh.Parent = ring

	-- Som de explosão
	PlaySoundAt(ef1, soundId, 2.5 * scale)

	-- Luz de explosão
	local light = Instance.new("PointLight")
	light.Brightness = 8 * scale
	light.Color = color1.Color
	light.Range = 25 * scale
	light.Parent = ef1

	-- Partículas de fumaça/fogo burst
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(color1.Color, Color3.fromRGB(80, 80, 80))
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2 * scale),
		NumberSequenceKeypoint.new(0.5, 4 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	particle.Lifetime = NumberRange.new(0.5, 1.2)
	particle.Speed = NumberRange.new(8 * scale, 20 * scale)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.LightEmission = 0.8
	particle.LightInfluence = 0.2
	particle.Rate = 0
	particle.Parent = ef1
	particle:Emit(15)

	-- Debris (pedaços voando)
	for i = 1, 4 do
		local idx = NextDebrisIndex()
		local debris = Instance.new("Part")
		debris.Name = "ExplosionDebris"
		debris.Size = DEBRIS_SIZES[idx] * scale * 0.8
		debris.BrickColor = color2
		debris.Material = Enum.Material.SmoothPlastic
		debris.CFrame = CFrame.new(position)
		debris.Anchored = false
		debris.CanCollide = true
		debris.CanTouch = false
		debris.CanQuery = false
		debris.CastShadow = false
		debris.Parent = workspace
		AddPart(debris, 3)

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = DEBRIS_DIRECTIONS[idx] * 35 * scale
		bv.Parent = debris
		Services.Debris:AddItem(bv, 0.15)
	end

	-- Animação de expansão + fade
	task.spawn(function()
		local startTime = tick()
		local duration = 1.5
		while tick() - startTime < duration do
			local progress = (tick() - startTime) / duration
			local easeOut = 1 - (1 - progress) ^ 3
			local expansion = easeOut * 10 * scale

			if ef1.Parent then
				ef1.Size = Vector3.new(4, 4, 4) * scale
					+ Vector3.new(expansion, expansion, expansion)
				ef1.Transparency = easeOut
			end
			if ef2.Parent then
				ef2.Size = Vector3.new(8, 8, 8) * scale
					+ Vector3.new(expansion * 1.5, expansion * 1.5, expansion * 1.5)
				ef2.Transparency = 0.3 + (easeOut * 0.7)
			end
			if ring.Parent then
				ring.Size = Vector3.new(2, 0.3, 2) * scale
					+ Vector3.new(expansion * 2, 0, expansion * 2)
				ring.Transparency = 0.3 + (easeOut * 0.7)
			end
			if light.Parent then
				light.Brightness = 8 * scale * (1 - easeOut)
				light.Range = 25 * scale * (1 + easeOut)
			end

			Services.RunService.Heartbeat:Wait()
		end
	end)
end

-- ========== SCREEN SHAKE (via RemoteEvent) ==========
local function TriggerScreenShake(intensity, duration)
	if RemoteEvent then
		RemoteEvent:FireAllClients("ScreenShake", intensity, duration)
	end
end

--[[
═══════════════════════════════════════════════════════════════
          HABILIDADE 1: BOMBA DOIDA (Clique)
═══════════════════════════════════════════════════════════════
Spawna bomba que rola e persegue inimigos.
Fica mais vermelha e rápida com o tempo.
Explode no contato ou após 10s.
═══════════════════════════════════════════════════════════════
--]]

local function FindNearestEnemy(position, range, attackerChar)
	local closestPart = nil
	local closestDist = range

	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model ~= attackerChar then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
			if hum and hum.Health > 0 and hrp then
				if not IsAlly(attackerChar, model) then
					local dist = (hrp.Position - position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPart = hrp
					end
				end
			end
		end
	end

	return closestPart
end

local function LaunchCrazyBomb(attackerCharacter)
	if not attackerCharacter then
		return
	end
	local hrp = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local aHum = attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not aHum or aHum.Health <= 0 then
		return
	end

	-- Criar bomba
	local bomb = Instance.new("Part")
	bomb.Name = "CrazyBomb"
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(2.5, 2.5, 2.5)
	bomb.BrickColor = BrickColor.new("Lime green")
	bomb.Material = Enum.Material.SmoothPlastic
	bomb.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 4 + Vector3.new(0, 1, 0))
	bomb.Anchored = false
	bomb.CanCollide = true
	bomb.CanTouch = true
	bomb.CastShadow = false
	bomb.CustomPhysicalProperties = PhysicalProperties.new(3, 0.3, 0.2, 1, 1)
	bomb.Parent = workspace
	AddPart(bomb, CONFIG.CrazyBomb_MaxLifetime + 1)

	-- VFX: PointLight (muda de cor com o tempo)
	local bombLight = Instance.new("PointLight")
	bombLight.Brightness = 3
	bombLight.Color = CRAZY_BOMB_COLORS[1]
	bombLight.Range = 12
	bombLight.Parent = bomb

	-- VFX: Smoke (fumaça que muda de cor)
	local bombSmoke = Instance.new("Smoke")
	bombSmoke.Color = CRAZY_BOMB_COLORS[1]
	bombSmoke.Opacity = 0.3
	bombSmoke.RiseVelocity = 3
	bombSmoke.Size = 2
	bombSmoke.Parent = bomb

	-- VFX: ParticleEmitter (faíscas)
	local bombParticle = Instance.new("ParticleEmitter")
	bombParticle.Color = ColorSequence.new(CRAZY_BOMB_COLORS[1])
	bombParticle.Size = NumberSequence.new(CRAZY_BOMB_PARTICLE_SIZES[1], 0)
	bombParticle.Transparency = NumberSequence.new(0, 1)
	bombParticle.Lifetime = NumberRange.new(0.3, 0.8)
	bombParticle.Rate = 15
	bombParticle.Speed = NumberRange.new(2, 5)
	bombParticle.SpreadAngle = Vector2.new(180, 180)
	bombParticle.LightEmission = 0.9
	bombParticle.LightInfluence = 0.1
	bombParticle.Parent = bomb

	-- VFX: Trail
	local a0 = Instance.new("Attachment", bomb)
	a0.Position = Vector3.new(0, 1, 0)
	local a1 = Instance.new("Attachment", bomb)
	a1.Position = Vector3.new(0, -1, 0)
	local trail = Instance.new("Trail", bomb)
	trail.FaceCamera = true
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.4
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Color = ColorSequence.new(CRAZY_BOMB_COLORS[1])
	trail.LightEmission = 0.8

	-- SFX: som de rolagem
	local rollSound = PlaySoundAt(bomb, CONFIG.RollingSoundID, 1.0, true)

	-- Impulso inicial na direção do olhar
	local launchBV = Instance.new("BodyVelocity")
	launchBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	launchBV.Velocity = hrp.CFrame.LookVector * CONFIG.CrazyBomb_BaseSpeed + Vector3.new(0, 8, 0)
	launchBV.Parent = bomb
	Services.Debris:AddItem(launchBV, 0.3)

	-- Lógica de perseguição + explosão
	local bombExploded = false

	local function ExplodeCrazyBomb(impactPos)
		if bombExploded then
			return
		end
		bombExploded = true

		-- Calcular cor baseada no tempo de vida para explosão temática
		bombSmoke.Enabled = false
		bombParticle.Enabled = false
		trail.Enabled = false
		bomb.Transparency = 1
		bomb.CanCollide = false
		bomb.CanTouch = false
		if rollSound then
			rollSound:Stop()
		end
		Services.Debris:AddItem(bomb, 0.2)

		DealDamage(
			impactPos,
			CONFIG.CrazyBomb_ExplosionRadius,
			CONFIG.CrazyBomb_Damage,
			CONFIG.CrazyBomb_KnockbackForce,
			attackerCharacter,
			false
		)
		CreateExplosionEffect(
			impactPos,
			CONFIG.CrazyBomb_ExplosionScale,
			BrickColor.new("Bright red"),
			BrickColor.new("Deep orange")
		)
		TriggerScreenShake(0.6, 0.3)
	end

	-- Toque: explode no contato com inimigo
	local touchConn
	touchConn = bomb.Touched:Connect(function(hit)
		if bombExploded then
			return
		end
		if not hit or not hit.Parent then
			return
		end

		local hitChar = hit.Parent
		if hitChar == attackerCharacter then
			return
		end
		if hit.Name:find("Bomb") or hit.Name:find("Projectile") or hit.Name:find("Mina") then
			return
		end

		local hitHum = hitChar:FindFirstChildOfClass("Humanoid")
		if hitHum and hitHum.Health > 0 then
			if not IsAlly(attackerCharacter, hitChar) then
				touchConn:Disconnect()
				ExplodeCrazyBomb(bomb.Position)
			end
		end
	end)

	-- Thread de perseguição com evolução visual
	local chaseThread = task.spawn(function()
		local spawnTime = tick()

		while not bombExploded and bomb.Parent do
			local elapsed = tick() - spawnTime
			local progress = elapsed / CONFIG.CrazyBomb_MaxLifetime -- 0 a 1

			-- Auto-explodir após tempo máximo
			if elapsed >= CONFIG.CrazyBomb_MaxLifetime then
				if touchConn then
					touchConn:Disconnect()
				end
				ExplodeCrazyBomb(bomb.Position)
				return
			end

			-- Calcular estágio visual (1-10)
			local stage = math.floor(progress * 9) + 1
			if stage > 10 then
				stage = 10
			end
			local stageColor = CRAZY_BOMB_COLORS[stage]

			-- Atualizar VFX progressivo
			if bomb.Parent then
				bomb.Color = stageColor
				bombLight.Color = stageColor
				bombLight.Brightness = 3 + (progress * 8)
				bombSmoke.Color = stageColor
				bombSmoke.Size = 2 + (progress * 4)
				trail.Color = ColorSequence.new(stageColor)
				bombParticle.Color = ColorSequence.new(stageColor)

				-- Aumentar rate de partículas
				bombParticle.Rate = 15 + (progress * 40)

				-- Som fica mais agudo com o tempo
				if rollSound and rollSound.Parent then
					rollSound.PlaybackSpeed = 1 + (progress * 0.8)
					rollSound.Volume = 1 + (progress * 1.5)
				end
			end

			-- Velocidade crescente
			local currentSpeed = CONFIG.CrazyBomb_BaseSpeed
				+ (CONFIG.CrazyBomb_MaxSpeed - CONFIG.CrazyBomb_BaseSpeed) * progress

			-- Perseguir inimigo mais próximo
			local target =
				FindNearestEnemy(bomb.Position, CONFIG.CrazyBomb_ChaseRange, attackerCharacter)
			if target and bomb.Parent then
				local direction = (target.Position - bomb.Position)
				-- Manter a bomba no chão: zerar componente Y da direção de perseguição
				direction = Vector3.new(direction.X, 0, direction.Z)
				if direction.Magnitude > 0.1 then
					direction = direction.Unit
					bomb.AssemblyLinearVelocity = Vector3.new(
						direction.X * currentSpeed,
						bomb.AssemblyLinearVelocity.Y, -- manter gravidade
						direction.Z * currentSpeed
					)
				end
			end

			Services.RunService.Heartbeat:Wait()
		end
	end)
	table.insert(ActiveEffects.Coroutines, chaseThread)
end

--[[
═══════════════════════════════════════════════════════════════
        HABILIDADE 2: FILA DE BOMBAS (Botão 1)
═══════════════════════════════════════════════════════════════
7 bombas no chão na direção do olhar, 3 studs entre cada.
Explodem em sequência (uma após a outra).
═══════════════════════════════════════════════════════════════
--]]

local function SpawnBombLine(attackerCharacter)
	if not attackerCharacter then
		return
	end
	local hrp = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local aHum = attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not aHum or aHum.Health <= 0 then
		return
	end

	local lookDir = hrp.CFrame.LookVector
	local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z)
	if flatDir.Magnitude < 0.1 then
		flatDir = Vector3.new(0, 0, 1)
	end
	flatDir = flatDir.Unit

	-- Posição base: 3 studs à frente do jogador, no chão
	local basePos = hrp.Position + flatDir * 3

	-- Raycast para encontrar o chão
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { attackerCharacter }

	local bombs = {}

	-- Spawnar 7 bombas no chão em sequência de posição
	for i = 1, CONFIG.BombLine_Count do
		local offset = flatDir * CONFIG.BombLine_Spacing * (i - 1)
		local spawnAt = basePos + offset

		-- Raio para achar o chão
		local rayResult =
			workspace:Raycast(spawnAt + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), rayParams)
		local groundY = spawnAt.Y - 2
		if rayResult then
			groundY = rayResult.Position.Y
		end

		local bombPos = Vector3.new(spawnAt.X, groundY + 0.8, spawnAt.Z)

		local bomb = Instance.new("Part")
		bomb.Name = "LineBomb_" .. tostring(i)
		bomb.Shape = Enum.PartType.Ball
		bomb.Size = Vector3.new(1.8, 1.8, 1.8)
		bomb.BrickColor = BrickColor.new("Bright orange")
		bomb.Material = Enum.Material.Neon
		bomb.CFrame = CFrame.new(bombPos)
		bomb.Anchored = true
		bomb.CanCollide = false
		bomb.CanTouch = false
		bomb.CanQuery = false
		bomb.CastShadow = false
		bomb.Transparency = 0
		bomb.Parent = workspace
		AddPart(bomb, 10)

		-- VFX: PointLight pulsante
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Color = Color3.fromRGB(255, 150, 30)
		light.Range = 8
		light.Parent = bomb

		-- VFX: Partículas de fuse/faísca
		local fuseParticle = Instance.new("ParticleEmitter")
		fuseParticle.Color =
			ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 80, 0))
		fuseParticle.Size = NumberSequence.new(0.4, 0)
		fuseParticle.Transparency = NumberSequence.new(0, 1)
		fuseParticle.Lifetime = NumberRange.new(0.3, 0.6)
		fuseParticle.Rate = 10
		fuseParticle.Speed = NumberRange.new(1, 3)
		fuseParticle.SpreadAngle = Vector2.new(180, 180)
		fuseParticle.LightEmission = 1
		fuseParticle.Parent = bomb

		-- SFX: som de posicionar
		if i == 1 then
			PlaySoundAt(bomb, CONFIG.PlaceBombSoundID, 1.5)
		end

		table.insert(
			bombs,
			{ part = bomb, position = bombPos, light = light, particle = fuseParticle }
		)
	end

	-- Detonação sequencial
	local detonateThread = task.spawn(function()
		-- Espera antes da primeira explosão
		task.wait(0.5)

		for i, bombData in ipairs(bombs) do
			if not bombData.part.Parent then
				continue
			end

			-- VFX pré-explosão: pulso brilhante
			if bombData.light.Parent then
				bombData.light.Brightness = 10
				bombData.light.Range = 15
			end
			if bombData.part.Parent then
				bombData.part.BrickColor = BrickColor.new("Really red")
			end

			-- SFX: tick de fusível
			PlaySoundAt(bombData.part, CONFIG.FuseTickSoundID, 1.0)

			task.wait(CONFIG.BombLine_DetonationDelay)

			-- Explodir
			if bombData.part.Parent then
				bombData.particle.Enabled = false
				bombData.part.Transparency = 1

				DealDamage(
					bombData.position,
					CONFIG.BombLine_ExplosionRadius,
					CONFIG.BombLine_Damage,
					CONFIG.BombLine_KnockbackForce,
					attackerCharacter,
					false
				)
				CreateExplosionEffect(
					bombData.position,
					CONFIG.BombLine_ExplosionScale,
					BrickColor.new("Bright orange"),
					BrickColor.new("Bright red")
				)

				Services.Debris:AddItem(bombData.part, 0.2)
			end
		end

		TriggerScreenShake(0.8, 0.4)
	end)
	table.insert(ActiveEffects.Coroutines, detonateThread)
end

--[[
═══════════════════════════════════════════════════════════════
        HABILIDADE 3: AUTO DESTRUIÇÃO (Botão 2)
═══════════════════════════════════════════════════════════════
Explosão centrada no próprio jogador após delay de 2s.
Adaptada do script original de Auto Destruição.
SFX reutilizado: rbxassetid://5693336619
═══════════════════════════════════════════════════════════════
--]]

local function SelfDestruct(attackerCharacter)
	if not attackerCharacter then
		return
	end
	local hrp = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local aHum = attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not aHum or aHum.Health <= 0 then
		return
	end

	-- VFX: aura de carga ao redor do jogador
	local chargeAura = Instance.new("Part")
	chargeAura.Name = "SelfDestructCharge"
	chargeAura.Shape = Enum.PartType.Ball
	chargeAura.Size = Vector3.new(4, 4, 4)
	chargeAura.BrickColor = BrickColor.new("Really red")
	chargeAura.Material = Enum.Material.Neon
	chargeAura.Transparency = 0.7
	chargeAura.CFrame = hrp.CFrame
	chargeAura.Anchored = true
	chargeAura.CanCollide = false
	chargeAura.CanTouch = false
	chargeAura.CanQuery = false
	chargeAura.CastShadow = false
	chargeAura.Parent = workspace
	AddPart(chargeAura, CONFIG.SelfDestruct_ChargeTime + 1)

	-- VFX: luz de carga
	local chargeLight = Instance.new("PointLight")
	chargeLight.Brightness = 5
	chargeLight.Color = Color3.fromRGB(255, 30, 0)
	chargeLight.Range = 20
	chargeLight.Parent = chargeAura

	-- VFX: partículas sendo sugadas para o centro
	local chargeParticle = Instance.new("ParticleEmitter")
	chargeParticle.Color =
		ColorSequence.new(Color3.fromRGB(255, 50, 0), Color3.fromRGB(255, 200, 0))
	chargeParticle.Size = NumberSequence.new(1.5, 0)
	chargeParticle.Transparency = NumberSequence.new(0.3, 1)
	chargeParticle.Lifetime = NumberRange.new(0.4, 0.8)
	chargeParticle.Rate = 30
	chargeParticle.Speed = NumberRange.new(-8, -4) -- negativo = sugando para dentro
	chargeParticle.SpreadAngle = Vector2.new(180, 180)
	chargeParticle.LightEmission = 1
	chargeParticle.LightInfluence = 0
	chargeParticle.Parent = chargeAura

	-- SFX: som de carga (do script original)
	local chargeSound = PlaySoundAt(chargeAura, CONFIG.SelfDestructChargeID, 3.0)

	-- Animação de carga: esfera cresce e pulsa
	local chargeThread = task.spawn(function()
		local startTime = tick()
		local pulseSpeed = 0

		while tick() - startTime < CONFIG.SelfDestruct_ChargeTime do
			local progress = (tick() - startTime) / CONFIG.SelfDestruct_ChargeTime
			pulseSpeed = pulseSpeed + 0.15

			if chargeAura.Parent and hrp.Parent then
				chargeAura.CFrame = CFrame.new(hrp.Position)

				-- Esfera cresce
				local baseSize = 4 + (progress * 6)
				local pulse = 1 + 0.15 * math.sin(pulseSpeed)
				chargeAura.Size = Vector3.new(baseSize, baseSize, baseSize) * pulse
				chargeAura.Transparency = 0.7 - (progress * 0.3) -- fica mais opaco

				-- Luz intensifica
				chargeLight.Brightness = 5 + (progress * 15)
				chargeLight.Range = 20 + (progress * 25)

				-- Partículas intensificam
				chargeParticle.Rate = 30 + (progress * 50)
			end

			Services.RunService.Heartbeat:Wait()
		end

		-- === EXPLOSÃO ===
		local explosionPos = hrp.Position

		-- Limpar aura de carga
		chargeParticle.Enabled = false
		chargeAura.Transparency = 1
		Services.Debris:AddItem(chargeAura, 0.2)

		-- Dano (inclui dano no próprio jogador)
		DealDamage(
			explosionPos,
			CONFIG.SelfDestruct_ExplosionRadius,
			CONFIG.SelfDestruct_Damage,
			CONFIG.SelfDestruct_KnockbackForce,
			attackerCharacter,
			true
		)

		-- VFX de explosão pesada
		CreateExplosionEffect(
			explosionPos,
			CONFIG.SelfDestruct_ExplosionScale,
			BrickColor.new("Really red"),
			BrickColor.new("Maroon"),
			CONFIG.HeavyExplosionID
		)

		-- SFX: explosão pesada extra
		PlaySoundAt(Instance.new("Part", workspace), CONFIG.ExplosionSoundID, 3.0)

		-- Screen shake forte
		TriggerScreenShake(1.2, 0.5)
	end)
	table.insert(ActiveEffects.Coroutines, chargeThread)
end

--[[
═══════════════════════════════════════════════════════════════
                  REMOTEEVENT HANDLERS
═══════════════════════════════════════════════════════════════
--]]

--[[
═══════════════════════════════════════════════════════════════
        HABILIDADE 4: CLUSTER DE PLASMA (Skill3 / R)
═══════════════════════════════════════════════════════════════
Granada de plasma MIRADA: viaja, explode e dispara várias
sub-explosões em leque, ligadas por arcos de raio.
Reutiliza CreateExplosionEffect/DealDamage. Sem math.random.
═══════════════════════════════════════════════════════════════
--]]

-- Zigue-zague pré-definido para os arcos de raio (sem random)
local ARC_ZIGZAG = { 0, 2.4, -2.4, 1.4, -1.4, 0.8, -0.8 }

local function LightningArc(p0, p1, brickColor)
	local dir = p1 - p0
	if dir.Magnitude < 0.1 then
		return
	end
	local perp = dir.Unit:Cross(Vector3.new(0, 1, 0))
	if perp.Magnitude < 0.1 then
		perp = dir.Unit:Cross(Vector3.new(1, 0, 0))
	end
	perp = perp.Unit
	local segs = 6
	local prev = p0
	for i = 1, segs do
		local along = p0 + dir * (i / segs)
		local pt = (i < segs) and (along + perp * ARC_ZIGZAG[((i - 1) % #ARC_ZIGZAG) + 1]) or p1
		local segLen = (pt - prev).Magnitude
		if segLen > 0.05 then
			local bolt = Instance.new("Part")
			bolt.Anchored = true
			bolt.CanCollide = false
			bolt.CanQuery = false
			bolt.CanTouch = false
			bolt.CastShadow = false
			bolt.Material = Enum.Material.Neon
			bolt.BrickColor = brickColor
			bolt.Size = Vector3.new(0.45, 0.45, segLen)
			bolt.CFrame = CFrame.lookAt((prev + pt) / 2, pt)
			bolt.Parent = workspace
			AddPart(bolt, 0.4)
			Services.TweenService:Create(bolt, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		end
		prev = pt
	end
end

local function LaunchPlasmaCluster(attackerCharacter, aimPos)
	local hrp = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local startPos = hrp.Position + Vector3.new(0, 2, 0) + hrp.CFrame.LookVector * 3
	local target = aimPos or (hrp.Position + hrp.CFrame.LookVector * 45)
	local toTarget = target - startPos
	if toTarget.Magnitude < 1 then
		return
	end
	local dir = toTarget.Unit
	local maxDist = toTarget.Magnitude

	local proj = Instance.new("Part")
	proj.Name = "PlasmaGrenade"
	proj.Shape = Enum.PartType.Ball
	proj.Material = Enum.Material.Neon
	proj.BrickColor = BrickColor.new(CONFIG.PlasmaColor1)
	proj.Size = Vector3.new(2.4, 2.4, 2.4)
	proj.CanCollide = false
	proj.CanQuery = false
	proj.Anchored = true
	proj.CFrame = CFrame.new(startPos)
	proj.Parent = workspace
	AddPart(proj, CONFIG.Cluster_MaxTravel + 1)

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, 1)
	a0.Parent = proj
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -1)
	a1.Parent = proj
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(proj.Color)
	trail.Lifetime = 0.45
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = proj

	local light = Instance.new("PointLight")
	light.Color = proj.Color
	light.Brightness = 6
	light.Range = 16
	light.Parent = proj

	PlaySoundAt(proj, CONFIG.RollingSoundID, 1.2, false)

	task.spawn(function()
		local traveled = 0
		while traveled < maxDist do
			local dt = Services.RunService.Heartbeat:Wait()
			if not proj.Parent then
				return
			end
			proj.CFrame = proj.CFrame + dir * (CONFIG.Cluster_TravelSpeed * dt)
			traveled = traveled + CONFIG.Cluster_TravelSpeed * dt
		end
		local center = proj.Position
		proj.Parent = nil

		CreateExplosionEffect(
			center,
			CONFIG.Cluster_ExplosionScale,
			BrickColor.new(CONFIG.PlasmaColor1),
			BrickColor.new(CONFIG.PlasmaColor2),
			CONFIG.ExplosionSoundID
		)
		DealDamage(
			center,
			CONFIG.Cluster_ExplosionRadius,
			CONFIG.Cluster_Damage,
			CONFIG.Cluster_KnockbackForce,
			attackerCharacter,
			false
		)
		TriggerScreenShake(0.7, 0.35)

		for i = 1, CONFIG.Cluster_SubCount do
			local ang = math.rad((360 / CONFIG.Cluster_SubCount) * i)
			local subPos = center
				+ Vector3.new(
					math.cos(ang) * CONFIG.Cluster_SubSpread,
					0,
					math.sin(ang) * CONFIG.Cluster_SubSpread
				)
			task.delay(0.06 * i, function()
				LightningArc(center, subPos, BrickColor.new(CONFIG.PlasmaColor2))
				CreateExplosionEffect(
					subPos,
					CONFIG.Cluster_SubScale,
					BrickColor.new(CONFIG.PlasmaColor1),
					BrickColor.new(CONFIG.PlasmaColor2),
					CONFIG.ExplosionSoundID
				)
				DealDamage(
					subPos,
					CONFIG.Cluster_SubRadius,
					CONFIG.Cluster_Damage * 0.6,
					CONFIG.Cluster_KnockbackForce,
					attackerCharacter,
					false
				)
			end)
		end
	end)
end

--[[
═══════════════════════════════════════════════════════════════
        HABILIDADE 5: CHUVA DE METEOROS (Skill4 / T)
═══════════════════════════════════════════════════════════════
Chama vários meteoros do céu na área mirada. Cada um cai com
rastro de fogo e explode no impacto. Offsets pré-definidos (sem random).
═══════════════════════════════════════════════════════════════
--]]

local METEOR_OFFSETS = {
	Vector3.new(0, 0, 0),
	Vector3.new(0.9, 0, 0.2),
	Vector3.new(-0.6, 0, 0.7),
	Vector3.new(0.3, 0, -0.9),
	Vector3.new(-0.8, 0, -0.4),
	Vector3.new(0.5, 0, 0.6),
	Vector3.new(-0.3, 0, 0.95),
	Vector3.new(0.75, 0, -0.5),
}

local function DropMeteor(landPos, attackerCharacter)
	local startPos = landPos + Vector3.new(0, CONFIG.Meteor_FallHeight, 0)
	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Material = Enum.Material.Neon
	meteor.BrickColor = BrickColor.new(CONFIG.MeteorColor1)
	meteor.Size = Vector3.new(3, 3, 3)
	meteor.CanCollide = false
	meteor.CanQuery = false
	meteor.Anchored = true
	meteor.CFrame = CFrame.new(startPos)
	meteor.Parent = workspace
	AddPart(meteor, CONFIG.Meteor_FallTime + 1)

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = meteor
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = meteor
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 0, 0))
	trail.Lifetime = 0.5
	trail.WidthScale = NumberSequence.new(3, 0)
	trail.Parent = meteor

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 0)
	light.Brightness = 5
	light.Range = 18
	light.Parent = meteor

	Services.TweenService
		:Create(
			meteor,
			TweenInfo.new(CONFIG.Meteor_FallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = CFrame.new(landPos) }
		)
		:Play()

	task.delay(CONFIG.Meteor_FallTime, function()
		meteor.Parent = nil
		CreateExplosionEffect(
			landPos,
			CONFIG.Meteor_ExplosionScale,
			BrickColor.new(CONFIG.MeteorColor1),
			BrickColor.new(CONFIG.MeteorColor2),
			CONFIG.ExplosionSoundID
		)
		DealDamage(
			landPos,
			CONFIG.Meteor_ExplosionRadius,
			CONFIG.Meteor_Damage,
			CONFIG.Meteor_KnockbackForce,
			attackerCharacter,
			false
		)
		TriggerScreenShake(0.5, 0.25)
	end)
end

local function MeteorShower(attackerCharacter, aimPos)
	local hrp = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local centerArea = aimPos or (hrp.Position + hrp.CFrame.LookVector * 30)
	TriggerScreenShake(0.4, 0.3)
	for i = 1, CONFIG.Meteor_Count do
		local off = METEOR_OFFSETS[((i - 1) % #METEOR_OFFSETS) + 1]
		local landPos = centerArea + off * CONFIG.Meteor_AreaRadius + Vector3.new(0, 1, 0)
		task.delay(CONFIG.Meteor_Interval * i, function()
			DropMeteor(landPos, attackerCharacter)
		end)
	end
end

-- CLIQUE → Bomba Doida
RemoteEvent.OnServerEvent:Connect(function(player, action)
	if player ~= owner or not equipped then
		return
	end

	if action == "BombaDoida" then
		local currentTime = tick()
		if currentTime - lastCrazyBombTime >= CONFIG.CrazyBomb_Cooldown then
			lastCrazyBombTime = currentTime
			LaunchCrazyBomb(character)
		end
	end
end)

-- BOTÃO 1 → Fila de Bombas
Skill1Event.OnServerEvent:Connect(function(player)
	if player ~= owner or not equipped then
		return
	end

	local currentTime = tick()
	if currentTime - lastBombLineTime >= CONFIG.BombLine_Cooldown then
		lastBombLineTime = currentTime
		SpawnBombLine(character)
	end
end)

-- BOTÃO 2 → Auto Destruição
Skill2Event.OnServerEvent:Connect(function(player)
	if player ~= owner or not equipped then
		return
	end

	local currentTime = tick()
	if currentTime - lastSelfDestructTime >= CONFIG.SelfDestruct_Cooldown then
		lastSelfDestructTime = currentTime
		SelfDestruct(character)
	end
end)

-- BOTÃO 3 → Cluster de Plasma
Skill3Event.OnServerEvent:Connect(function(player, aimPos)
	if player ~= owner or not equipped then
		return
	end
	if aimPos ~= nil and typeof(aimPos) ~= "Vector3" then
		aimPos = nil
	end
	local currentTime = tick()
	if currentTime - lastClusterTime >= CONFIG.Cluster_Cooldown then
		lastClusterTime = currentTime
		LaunchPlasmaCluster(character, aimPos)
	end
end)

-- BOTÃO 4 → Chuva de Meteoros
Skill4Event.OnServerEvent:Connect(function(player, aimPos)
	if player ~= owner or not equipped then
		return
	end
	if aimPos ~= nil and typeof(aimPos) ~= "Vector3" then
		aimPos = nil
	end
	local currentTime = tick()
	if currentTime - lastMeteorTime >= CONFIG.Meteor_Cooldown then
		lastMeteorTime = currentTime
		MeteorShower(character, aimPos)
	end
end)

--[[
═══════════════════════════════════════════════════════════════
                    SISTEMA NPC
═══════════════════════════════════════════════════════════════
Reutilizado de: Script_MultipleBombs_V1_4 → findNearestTorso
═══════════════════════════════════════════════════════════════
--]]

local function findNearestTorso(pos)
	local list = workspace:GetDescendants()
	local torso = nil
	local dist = 50

	for _, temp2 in pairs(list) do
		local isOwner = false

		if
			temp2:FindFirstChild("PossessFollow")
			and character
			and character:FindFirstChild("ControlFollow")
		then
			if temp2.PossessFollow.Owner.Value == character.ControlFollow.Owner.Value then
				isOwner = true
			end
		end
		if
			temp2:FindFirstChild("SuitFollow")
			and character
			and character:FindFirstChild("ControlFollow")
		then
			if temp2.SuitFollow.Owner.Value == character.ControlFollow.Owner.Value then
				isOwner = true
			end
		end
		if
			temp2:FindFirstChild("ControlFollow")
			and character
			and character:FindFirstChild("ControlFollow")
		then
			if temp2.ControlFollow.Owner.Value == character.ControlFollow.Owner.Value then
				isOwner = true
			end
		end
		if character and character:FindFirstChild("ControlFollow") then
			if temp2 == character.ControlFollow.Owner.Value then
				isOwner = true
			end
		end

		if temp2.ClassName == "Model" and temp2 ~= character and not isOwner then
			local temp = temp2:FindFirstChild("HumanoidRootPart")
			local human = temp2:FindFirstChildOfClass("Humanoid")
			if temp and human and human.Health > 0 then
				if (temp.Position - pos).Magnitude < dist then
					torso = temp
					dist = (temp.Position - pos).Magnitude
				end
			end
		end
	end
	return torso
end

-- NPC skill cycle index
local npcSkillIndex = 1
local NPC_SKILL_CYCLE = { "CrazyBomb", "BombLine", "CrazyBomb", "SelfDestruct" }
local npcLastUseTime = 0

task.spawn(function()
	while true do
		if Services.Players:GetPlayerFromCharacter(Tool.Parent) == nil and equipped then
			local currentTime = tick()
			if currentTime - npcLastUseTime >= 5 then
				if character and character:FindFirstChild("HumanoidRootPart") then
					local targetTorso = findNearestTorso(character.HumanoidRootPart.Position)
					if targetTorso then
						local skill = NPC_SKILL_CYCLE[npcSkillIndex]
						npcSkillIndex = (npcSkillIndex % #NPC_SKILL_CYCLE) + 1
						npcLastUseTime = currentTime

						if skill == "CrazyBomb" then
							LaunchCrazyBomb(character)
						elseif skill == "BombLine" then
							SpawnBombLine(character)
						elseif skill == "SelfDestruct" then
							SelfDestruct(character)
						end
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

--[[
═══════════════════════════════════════════════════════════════
               EVENTOS DE EQUIPAR / DESEQUIPAR
═══════════════════════════════════════════════════════════════
--]]

Tool.Equipped:Connect(function()
	equipped = true
	owner = Services.Players:GetPlayerFromCharacter(Tool.Parent)
	character = Tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")

	if deathCleanupConn then
		deathCleanupConn:Disconnect()
	end
	if humanoid then
		deathCleanupConn = humanoid.Died:Connect(function()
			CleanupAllEffects()
		end)
	end
end)

Tool.Unequipped:Connect(function()
	equipped = false
end)

Tool.AncestryChanged:Connect(function()
	if not Tool.Parent then
		CleanupAllEffects()
	end
end)

--[[
═══════════════════════════════════════════════════════════════
ESTRUTURA DA TOOL:
Tool (GranadaTatica)
├─ Handle (Part ou MeshPart)
├─ Script       → ServerScript_GranadaTatica_V1.lua  (este)
├─ Client       → LocalScript_GranadaTatica_V1.lua
├─ RemoteEvent  → clique principal (BombaDoida) + feedback
├─ Skill1       → RemoteEvent (Fila de Bombas)
└─ Skill2       → RemoteEvent (Auto Destruição)
═══════════════════════════════════════════════════════════════
--]]
