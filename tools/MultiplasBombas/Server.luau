-- ============================================================================
-- Server  (Script)  ·  FICA DENTRO DA TOOL "Multiplas Bombas"
--
-- 1 HABILIDADE (só clique, sem habilidades extras):
--   Clique -> arremessa uma bomba (animação CFrame R6 no braço). Ao explodir,
--   libera 3 Mini Bombas, cada uma causando 20% do dano da bomba principal.
--   Recarga: 3s.
--
-- BASEADO em: Granada Tatica / Script_MultipleBombs (IsAlly, DealDamage,
-- explosão) — VFX SUPER melhorada (core + shockwave + anel + estilhaços em
-- CFrame + fogo/fumaça/faíscas + luz + screen shake).
--
-- REGRAS: sem math.random · sem :Destroy() (usa Parent = nil) · não deleta
-- humanoides · sem GUI/hub · não dá dano em time/si mesmo · dá dano em NPC.
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local CameraShake = Tool:WaitForChild("CameraShake") -- RemoteEvent (Server -> Client)

Tool.CanBeDropped = false
Tool.RequiresHandle = true
Tool.ToolTip = "Multiplas Bombas - clique para arremessar"

-- ===================== CONFIG (ajustável) ===================================
local CONFIG = {
	BombDamage = 50,
	BombRadius = 16,
	BombScale = 1.2,
	BombKnockback = 45,
	Cooldown = 3,

	MiniCount = 3,
	MiniDamagePercent = 0.20, -- 20% do dano da bomba principal
	MiniRadius = 10,
	MiniScale = 0.6,
	MiniKnockback = 25,

	ThrowSpeed = 62,
	ThrowUp = 26,
	Gravity = 85,
	BombMaxTime = 4,
	MiniMaxTime = 0.6,

	ExplosionSoundID = "rbxassetid://165970126", -- troque pelo seu som
}

-- Direções pré-definidas (sem math.random) para estilhaços e mini bombas.
local DEBRIS_DIRS = {
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
	Vector3.new(1.4, 0.8, 1.4),
	Vector3.new(0.9, 1.4, 0.9),
	Vector3.new(1.8, 0.7, 1.1),
	Vector3.new(1.1, 1.1, 1.8),
	Vector3.new(0.8, 1.6, 0.9),
	Vector3.new(1.6, 0.9, 0.8),
	Vector3.new(0.9, 0.8, 1.6),
	Vector3.new(1.3, 1.3, 1.3),
}
-- 3 direções fixas para as mini bombas
local MINI_DIRS = {
	Vector3.new(1.0, 0.0, 0.3).Unit,
	Vector3.new(-0.8, 0.0, 0.6).Unit,
	Vector3.new(-0.1, 0.0, -1.0).Unit,
}

-- ===================== ESTADO / LIMPEZA =====================================
local cooldowns = {}
local efeitosAtivos = {}
local conexoesAtivas = {}

local function remover(inst, atraso)
	if not inst then
		return
	end
	if atraso then
		task.delay(atraso, function()
			inst.Parent = nil
		end)
	else
		inst.Parent = nil
	end
end

local function rastrearParte(parte, vida)
	table.insert(efeitosAtivos, parte)
	if vida then
		remover(parte, vida)
	end
	return parte
end

local function rastrearConexao(con)
	table.insert(conexoesAtivas, con)
	return con
end

local function limparEfeitos()
	for _, item in efeitosAtivos do
		if item then
			item.Parent = nil
		end
	end
	table.clear(efeitosAtivos)
	for _, con in conexoesAtivas do
		if con.Connected then
			con:Disconnect()
		end
	end
	table.clear(conexoesAtivas)
end

-- ===================== HELPERS ==============================================
local function getDonoChar()
	local char = Tool.Parent
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char
	end
	return nil
end

local function estaVivo(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		return true, hum, char:FindFirstChild("HumanoidRootPart")
	end
	return false
end

local function emCooldown(char, duracao)
	local agora = os.clock()
	if cooldowns[char] and agora < cooldowns[char] then
		return true
	end
	cooldowns[char] = agora + duracao
	return false
end

local function podeAtingir(donoChar, alvoModel)
	if alvoModel == donoChar then
		return false
	end
	local donoPlayer = Players:GetPlayerFromCharacter(donoChar)
	local alvoPlayer = Players:GetPlayerFromCharacter(alvoModel)
	if alvoPlayer then
		if donoPlayer and alvoPlayer == donoPlayer then
			return false
		end
		if donoPlayer then
			if _G.CanDamagePlayer then
				if _G.CanDamagePlayer(donoPlayer, alvoPlayer) == false then
					return false
				end
			elseif _G.IsTeammate then
				if _G.IsTeammate(donoPlayer, alvoPlayer) then
					return false
				end
			end
			if
				donoPlayer.Team
				and alvoPlayer.Team
				and not donoPlayer.Neutral
				and not alvoPlayer.Neutral
				and donoPlayer.Team == alvoPlayer.Team
			then
				return false
			end
		end
	end
	return true
end

local function atingirArea(donoChar, centro, raio, dano, knockback)
	local vistos = {}
	local donoPlayer = Players:GetPlayerFromCharacter(donoChar)
	for _, part in workspace:GetPartBoundsInRadius(centro, raio) do
		local model = part:FindFirstAncestorWhichIsA("Model")
		if model and not vistos[model] then
			vistos[model] = true
			local hum = model:FindFirstChildOfClass("Humanoid")
			local raiz = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
			if hum and hum.Health > 0 and raiz and podeAtingir(donoChar, model) then
				if donoPlayer then
					local tag = Instance.new("ObjectValue")
					tag.Name = "creator"
					tag.Value = donoPlayer
					tag.Parent = hum
					remover(tag, 3)
				end
				hum:TakeDamage(dano)
				if knockback and knockback > 0 then
					local dir = (raiz.Position - centro)
					dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 1, 0)
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bv.P = 1e7
					bv.Velocity = dir * knockback + Vector3.new(0, knockback * 0.4, 0)
					bv.Parent = raiz
					remover(bv, 0.2)
				end
			end
		end
	end
end

local function shake(donoChar, intensidade, duracao)
	local p = Players:GetPlayerFromCharacter(donoChar)
	if p then
		CameraShake:FireClient(p, intensidade, duracao)
	end
end

local function tween(obj, t, props, style, dir)
	TweenService:Create(
		obj,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

-- ===================== VFX: EXPLOSÃO SUPER MELHORADA ========================
local function createSuperExplosion(position, scale)
	scale = scale or 1

	-- Host (luz + som + partículas)
	local host = rastrearParte(Instance.new("Part"), 2.5)
	host.Name = "ExplosionFX"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.new(1, 1, 1)
	host.CFrame = CFrame.new(position)
	host.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 60)
	light.Brightness = 12 * scale
	light.Range = 28 * scale
	light.Parent = host
	tween(light, 0.6, { Brightness = 0, Range = 6 })

	local s = Instance.new("Sound")
	s.SoundId = CONFIG.ExplosionSoundID
	s.Volume = 2.2
	s.RollOffMode = Enum.RollOffMode.Inverse
	s.Parent = host
	s:Play()

	-- Fogo / fumaça / faíscas (texturas nativas do Roblox)
	local at = Instance.new("Attachment", host)
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 70, 0))
	fire.Lifetime = NumberRange.new(0.3, 0.6)
	fire.Speed = NumberRange.new(18 * scale, 32 * scale)
	fire.SpreadAngle = Vector2.new(180, 180)
	fire.Size = NumberSequence.new(3 * scale, 0)
	fire.Rate = 0
	fire.Parent = at

	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(60, 50, 45), Color3.fromRGB(20, 18, 16))
	smoke.Lifetime = NumberRange.new(0.7, 1.2)
	smoke.Speed = NumberRange.new(8 * scale, 16 * scale)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Size = NumberSequence.new(4 * scale, 8 * scale)
	smoke.Transparency = NumberSequence.new(0.2, 1)
	smoke.Rate = 0
	smoke.Parent = at

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
	sparks.Lifetime = NumberRange.new(0.4, 0.8)
	sparks.Speed = NumberRange.new(30 * scale, 50 * scale)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new(0.6 * scale, 0)
	sparks.Rate = 0
	sparks.Parent = at

	fire:Emit(math.floor(26 * scale))
	smoke:Emit(math.floor(16 * scale))
	sparks:Emit(math.floor(30 * scale))

	-- Núcleo (flash)
	local core = rastrearParte(Instance.new("Part"), 0.6)
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.CastShadow = false
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(255, 240, 180)
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(3, 3, 3) * scale
	core.CFrame = CFrame.new(position)
	core.Parent = workspace
	tween(core, 0.4, { Size = Vector3.new(11, 11, 11) * scale, Transparency = 1 })

	-- Onda de choque
	local shock = rastrearParte(Instance.new("Part"), 0.7)
	shock.Name = "Shockwave"
	shock.Anchored = true
	shock.CanCollide = false
	shock.CanQuery = false
	shock.CanTouch = false
	shock.CastShadow = false
	shock.Material = Enum.Material.Neon
	shock.Color = Color3.fromRGB(255, 120, 30)
	shock.Transparency = 0.35
	shock.Shape = Enum.PartType.Ball
	shock.Size = Vector3.new(5, 5, 5) * scale
	shock.CFrame = CFrame.new(position)
	shock.Parent = workspace
	tween(shock, 0.6, { Size = Vector3.new(22, 22, 22) * scale, Transparency = 1 })

	-- Anel de impacto (cilindro achatado)
	local ring = rastrearParte(Instance.new("Part"), 0.7)
	ring.Name = "Ring"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 180, 60)
	ring.Transparency = 0.2
	ring.Size = Vector3.new(1, 6, 6) * scale
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local ringMesh = Instance.new("SpecialMesh")
	ringMesh.MeshType = Enum.MeshType.Cylinder
	ringMesh.Parent = ring
	tween(ring, 0.55, { Size = Vector3.new(1, 30, 30) * scale, Transparency = 1 })

	-- Estilhaços em CFrame (voando com gravidade + rotação)
	for i = 1, #DEBRIS_DIRS do
		local shard = rastrearParte(Instance.new("Part"), 1.3)
		shard.Name = "Shard"
		shard.Anchored = true
		shard.CanCollide = false
		shard.CanQuery = false
		shard.CanTouch = false
		shard.CastShadow = false
		shard.Material = Enum.Material.Neon
		shard.Color = Color3.fromRGB(255, 130, 30)
		shard.Size = DEBRIS_SIZES[i] * scale
		shard.CFrame = CFrame.new(position)
		shard.Parent = workspace

		local vel = (DEBRIS_DIRS[i] * 42 + Vector3.new(0, 18, 0)) * scale
		local life = 0
		local con
		con = rastrearConexao(RunService.Heartbeat:Connect(function(dt)
			life = life + dt
			if life >= 1.1 or not shard.Parent then
				con:Disconnect()
				return
			end
			vel = vel + Vector3.new(0, -90 * dt, 0)
			shard.CFrame = (shard.CFrame + vel * dt) * CFrame.Angles(dt * 9, dt * 6, dt * 3)
			shard.Transparency = life / 1.1
		end))
	end
end

-- ===================== ARCO BALÍSTICO (CFrame) =============================
local function simularArco(part, vel, maxTime, donoChar, onEnd)
	local t = 0
	local pos = part.Position
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { donoChar, part }
	local con
	con = rastrearConexao(RunService.Heartbeat:Connect(function(dt)
		t = t + dt
		vel = vel + Vector3.new(0, -CONFIG.Gravity * dt, 0)
		local nextPos = pos + vel * dt
		local result = workspace:Raycast(pos, nextPos - pos, rp)
		pos = result and result.Position or nextPos
		part.CFrame = CFrame.new(pos) * CFrame.Angles(t * 9, t * 7, 0)
		if result or t >= maxTime then
			con:Disconnect()
			part.Parent = nil
			onEnd(pos)
		end
	end))
end

local function addFuse(part, color)
	local at = Instance.new("Attachment", part)
	local em = Instance.new("ParticleEmitter")
	em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	em.Color = ColorSequence.new(color)
	em.Lifetime = NumberRange.new(0.2, 0.4)
	em.Rate = 50
	em.Speed = NumberRange.new(2, 5)
	em.SpreadAngle = Vector2.new(40, 40)
	em.Size = NumberSequence.new(0.5, 0)
	em.Parent = at
end

local function novaBombaPart(position, diametro, cor)
	local b = rastrearParte(Instance.new("Part"), CONFIG.BombMaxTime + 2)
	b.Shape = Enum.PartType.Ball
	b.Material = Enum.Material.SmoothPlastic
	b.Color = cor
	b.Size = Vector3.new(diametro, diametro, diametro)
	b.CanCollide = false
	b.CanQuery = false
	b.Anchored = true
	b.CFrame = CFrame.new(position)
	b.Parent = workspace
	return b
end

-- ===================== MINI BOMBAS ==========================================
local function lancarMiniBomba(origem, dir, donoChar)
	local mini = novaBombaPart(origem + Vector3.new(0, 1, 0), 1.1, Color3.fromRGB(30, 30, 30))
	addFuse(mini, Color3.fromRGB(255, 120, 0))
	local vel = dir * 20 + Vector3.new(0, 16, 0)
	simularArco(mini, vel, CONFIG.MiniMaxTime, donoChar, function(finalPos)
		createSuperExplosion(finalPos, CONFIG.MiniScale)
		atingirArea(
			donoChar,
			finalPos,
			CONFIG.MiniRadius,
			CONFIG.BombDamage * CONFIG.MiniDamagePercent,
			CONFIG.MiniKnockback
		)
		shake(donoChar, 1, 0.2)
	end)
end

-- ===================== ANIMAÇÃO CFrame R6 (braço arremessando) ==============
local function animarArremessoR6(char, onRelease)
	local torso = char:FindFirstChild("Torso")
	local shoulder = torso and torso:FindFirstChild("Right Shoulder")
	if not shoulder or not shoulder:IsA("Motor6D") then
		-- R15 ou sem junta R6: solta a bomba sem animar
		if onRelease then
			onRelease()
		end
		return
	end

	local original = shoulder.C0
	local windup = original * CFrame.Angles(math.rad(-155), 0, math.rad(15))
	local arremesso = original * CFrame.Angles(math.rad(80), 0, 0)

	-- 1) windup (braço pra trás/cima)
	tween(shoulder, 0.16, { C0 = windup }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.wait(0.16)
	-- 2) arremesso rápido pra frente
	tween(shoulder, 0.09, { C0 = arremesso }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.wait(0.07)
	if onRelease then
		onRelease() -- solta a bomba no ápice do movimento
	end
	task.wait(0.05)
	-- 3) volta à posição original
	tween(shoulder, 0.22, { C0 = original }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- ===================== BOMBA PRINCIPAL ======================================
local function explodirPrincipal(finalPos, donoChar)
	createSuperExplosion(finalPos, CONFIG.BombScale)
	atingirArea(donoChar, finalPos, CONFIG.BombRadius, CONFIG.BombDamage, CONFIG.BombKnockback)
	shake(donoChar, 2.2, 0.4)

	-- libera 3 mini bombas
	for i = 1, CONFIG.MiniCount do
		local dir = MINI_DIRS[((i - 1) % #MINI_DIRS) + 1]
		task.delay(0.05 * i, function()
			lancarMiniBomba(finalPos, dir, donoChar)
		end)
	end
end

local function arremessarBomba(donoChar)
	local vivo, _, raiz = estaVivo(donoChar)
	if not vivo or not raiz then
		return
	end
	animarArremessoR6(donoChar, function()
		local maoPos = raiz.Position + raiz.CFrame.LookVector * 2.5 + Vector3.new(0, 2.5, 0)
		local bomba = novaBombaPart(maoPos, 1.6, Color3.fromRGB(25, 25, 25))
		addFuse(bomba, Color3.fromRGB(255, 100, 0))
		local vel = raiz.CFrame.LookVector * CONFIG.ThrowSpeed + Vector3.new(0, CONFIG.ThrowUp, 0)
		simularArco(bomba, vel, CONFIG.BombMaxTime, donoChar, function(finalPos)
			explodirPrincipal(finalPos, donoChar)
		end)
	end)
end

-- ===================== ENTRADA: CLIQUE ======================================
Tool.Activated:Connect(function()
	local char = getDonoChar()
	if not char then
		return
	end
	if not Players:GetPlayerFromCharacter(char) then
		return -- jogador real; NPC usa o loop abaixo
	end
	if emCooldown(char, CONFIG.Cooldown) then
		return
	end
	arremessarBomba(char)
end)

-- ===================== LIMPEZA AO MORRER / DESEQUIPAR =======================
Tool.Equipped:Connect(function()
	local char = getDonoChar()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		rastrearConexao(hum.Died:Connect(limparEfeitos))
	end
end)
Tool.Unequipped:Connect(limparEfeitos)
Tool.AncestryChanged:Connect(function()
	if not Tool.Parent then
		limparEfeitos()
	end
end)

-- ===================== NPC: arremesso automático ============================
local function acharAlvoProximo(donoChar, pos, alcance)
	local melhor, dist = nil, alcance
	for _, model in workspace:GetChildren() do
		if model:IsA("Model") and model ~= donoChar then
			local raiz = model:FindFirstChild("HumanoidRootPart")
			local hum = model:FindFirstChildOfClass("Humanoid")
			if raiz and hum and hum.Health > 0 and podeAtingir(donoChar, model) then
				local d = (raiz.Position - pos).Magnitude
				if d < dist then
					melhor, dist = raiz, d
				end
			end
		end
	end
	return melhor
end

task.spawn(function()
	while true do
		task.wait(CONFIG.Cooldown)
		local char = getDonoChar()
		if char and Players:GetPlayerFromCharacter(char) == nil then
			local vivo, _, raiz = estaVivo(char)
			if vivo and raiz and acharAlvoProximo(char, raiz.Position, 80) then
				arremessarBomba(char)
			end
		end
	end
end)
