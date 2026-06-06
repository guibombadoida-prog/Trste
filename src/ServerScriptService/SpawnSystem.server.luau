-- ============================================
-- SPAWN SYSTEM V6 - PLAYERTP + MAPAPRINCIPAL
-- Coloque em ServerScriptService
-- Nome: "SpawnSystem"
-- SUBSTITUI: SPAWN_SYSTEM_V5
-- ============================================
-- NOVIDADES V6:
-- • Lobby posicionado automaticamente acima do modelo "MapaPrincipal"
-- • Spawn points do mapa lidos da pasta "PlayerTp" (workspace)
-- • teleportToMapSpawn usa o CFrame exato das partes de PlayerTp
-- • Fallback robusto caso MapaPrincipal ou PlayerTp não existam
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

print([[
╔════════════════════════════════════════════════════╗
║   🚀 SPAWN SYSTEM V6 - PLAYERTP + MAPAPRINCIPAL   ║
╚════════════════════════════════════════════════════╝
]])

-- =====================================
-- INICIALIZAÇÃO
-- =====================================

local isSystemReady = false
local initializationAttempts = 0
local MAX_INIT_ATTEMPTS = 10

local function waitForSystems()
	print("[SPAWN V6] Aguardando sistemas...")

	local timeout = 0
	while not _G.PlayerDataManager and timeout < 30 do
		task.wait(0.5)
		timeout = timeout + 0.5
	end

	if not _G.PlayerDataManager then
		warn("[SPAWN V6] ❌ PlayerDataManager não encontrado!")
		return false
	end

	print("[SPAWN V6] ✓ PlayerDataManager carregado")

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		warn("[SPAWN V6] ❌ Pasta Remotes não encontrada!")
		return false
	end

	print("[SPAWN V6] ✓ Remotes encontrados")
	return true
end

local function initializeSystem()
	initializationAttempts = initializationAttempts + 1
	print(string.format("[SPAWN V6] Inicialização #%d", initializationAttempts))

	if not waitForSystems() then
		if initializationAttempts < MAX_INIT_ATTEMPTS then
			print("[SPAWN V6] Tentando novamente em 3s...")
			task.wait(3)
			return initializeSystem()
		else
			error("[SPAWN V6] ❌ FALHA CRÍTICA: sistemas não carregaram!")
		end
	end

	isSystemReady = true
	print("[SPAWN V6] ✅ Sistema inicializado!")
	return true
end

if not initializeSystem() then
	error("[SPAWN V6] Sistema não inicializado!")
end

-- =====================================
-- DETECTAR POSIÇÃO DO LOBBY (V6 NOVO)
-- Lê o bounding box do modelo MapaPrincipal e
-- posiciona o lobby centralizado acima dele.
-- =====================================

local LOBBY_HEIGHT_OFFSET = 60 -- studs acima do topo do MapaPrincipal

local function getLobbyPosition()
	local mapa = workspace:FindFirstChild("MapaPrincipal")

	if mapa then
		-- GetBoundingBox retorna (CFrame do centro, Vector3 do tamanho)
		local ok, cf, size = pcall(function()
			return mapa:GetBoundingBox()
		end)

		if ok and cf then
			local centerX = cf.Position.X
			local centerZ = cf.Position.Z
			local topY = cf.Position.Y + (size.Y / 2)

			local lobbyY = topY + LOBBY_HEIGHT_OFFSET

			print(
				string.format(
					"[SPAWN V6] ✓ MapaPrincipal encontrado — Centro: (%.1f, %.1f, %.1f) | Topo: %.1f | Lobby Y: %.1f",
					centerX,
					cf.Position.Y,
					centerZ,
					topY,
					lobbyY
				)
			)

			return Vector3.new(centerX, lobbyY, centerZ)
		else
			warn("[SPAWN V6] ⚠️ Falha ao obter bounding box do MapaPrincipal, usando fallback")
		end
	else
		warn(
			"[SPAWN V6] ⚠️ Modelo 'MapaPrincipal' não encontrado no Workspace! Usando posição fallback."
		)
		warn("[SPAWN V6]    Certifique-se de que o modelo se chama exatamente 'MapaPrincipal'.")
	end

	-- Fallback
	return Vector3.new(0, 505, 0)
end

-- =====================================
-- CONFIGURAÇÃO DO LOBBY
-- POSITION é calculado dinamicamente no initializeSystem
-- =====================================

local LOBBY = {
	POSITION = Vector3.new(0, 505, 0), -- será sobrescrito abaixo
	SIZE = Vector3.new(150, 60, 150),
	SPAWN_RADIUS = 30,
	FLOOR_HEIGHT = 4,
	WALL_HEIGHT = 50,
	WALL_THICKNESS = 2,
}

-- Calcular posição real antes de criar qualquer estrutura
LOBBY.POSITION = getLobbyPosition()
print(
	string.format(
		"[SPAWN V6] 📍 Lobby posicionado em: (%.1f, %.1f, %.1f)",
		LOBBY.POSITION.X,
		LOBBY.POSITION.Y,
		LOBBY.POSITION.Z
	)
)

local CONFIG = {
	CHECK_INTERVAL = 0.5,
	TELEPORT_COOLDOWN = 2,
	MAX_DETECTION_RETRIES = 5,
}

-- =====================================
-- REMOTES
-- =====================================

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local spectatorModeRemote = remotes:WaitForChild("SpectatorMode", 10)
local syncCharacterStateRemote = remotes:WaitForChild("SyncCharacterState", 10)

if not spectatorModeRemote then
	spectatorModeRemote = Instance.new("RemoteEvent")
	spectatorModeRemote.Name = "SpectatorMode"
	spectatorModeRemote.Parent = remotes
end

if not syncCharacterStateRemote then
	syncCharacterStateRemote = Instance.new("RemoteEvent")
	syncCharacterStateRemote.Name = "SyncCharacterState"
	syncCharacterStateRemote.Parent = remotes
end

-- =====================================
-- VARIÁVEIS GLOBAIS
-- =====================================

local playerStates = {}
local lobbyModel = nil
local lobbySpawnLocation = nil
local exitBarriers = {}
local mapSpawnPoints = {} -- lista de CFrames das partes de PlayerTp

-- =====================================
-- COLETAR SPAWN POINTS — PASTA PlayerTp (V6 NOVO)
-- Lê todas as BaseParts dentro de workspace.PlayerTp
-- e armazena seus CFrames para uso no teleporte.
-- =====================================

local function collectMapSpawnPoints()
	mapSpawnPoints = {}

	print("[SPAWN V6] Coletando spawn points da pasta 'PlayerTp'...")

	local folder = workspace:FindFirstChild("PlayerTp")

	if not folder then
		warn("[SPAWN V6] ⚠️ Pasta 'PlayerTp' não encontrada no Workspace!")
		warn("[SPAWN V6]    Crie uma Folder chamada 'PlayerTp' e coloque Parts dentro.")
		-- Fallback: posições padrão
		mapSpawnPoints = {
			CFrame.new(200, 10, 200),
			CFrame.new(-200, 10, 200),
			CFrame.new(200, 10, -200),
			CFrame.new(-200, 10, -200),
		}
		warn("[SPAWN V6] ⚠️ Usando 4 posições de fallback.")
		return
	end

	for _, part in pairs(folder:GetChildren()) do
		if part:IsA("BasePart") then
			-- Guarda o CFrame completo (inclui rotação da part)
			table.insert(mapSpawnPoints, part.CFrame)
			print(
				string.format(
					"[SPAWN V6]   ✓ Spawn point: %s em (%.1f, %.1f, %.1f)",
					part.Name,
					part.Position.X,
					part.Position.Y,
					part.Position.Z
				)
			)
		end
	end

	if #mapSpawnPoints == 0 then
		warn("[SPAWN V6] ⚠️ Pasta 'PlayerTp' está vazia! Adicione Parts dentro dela.")
		mapSpawnPoints = { CFrame.new(200, 10, 200) }
		warn("[SPAWN V6] ⚠️ Usando 1 posição de fallback.")
		return
	end

	print(
		string.format("[SPAWN V6] ✓ %d spawn point(s) coletado(s) de 'PlayerTp'", #mapSpawnPoints)
	)
end

-- =====================================
-- CRIAR ESTRUTURA DO LOBBY
-- (1 único SpawnLocation — igual ao V5)
-- =====================================

local function createLobbyStructure()
	print("[SPAWN V6] Criando estrutura do lobby...")

	-- Remover estruturas antigas
	local oldLobby = workspace:FindFirstChild("LobbyStructure")
	if oldLobby then
		oldLobby:Destroy()
	end

	local oldSafeZone = workspace:FindFirstChild("SafeZone")
	if oldSafeZone then
		oldSafeZone:Destroy()
	end

	-- Modelo principal
	lobbyModel = Instance.new("Model")
	lobbyModel.Name = "LobbyStructure"
	lobbyModel.Parent = workspace

	-- 1. PISO
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Size = Vector3.new(LOBBY.SIZE.X, LOBBY.FLOOR_HEIGHT, LOBBY.SIZE.Z)
	floor.Position = LOBBY.POSITION
	floor.Anchored = true
	floor.Material = Enum.Material.SmoothPlastic
	floor.Color = Color3.fromRGB(30, 30, 50)
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = lobbyModel

	local floorLight = Instance.new("PointLight")
	floorLight.Brightness = 1.5
	floorLight.Range = 60
	floorLight.Color = Color3.fromRGB(0, 170, 255)
	floorLight.Parent = floor

	-- 2. PLATAFORMA DE SPAWN CENTRAL
	local spawnPlatform = Instance.new("Part")
	spawnPlatform.Name = "SpawnPlatform"
	spawnPlatform.Size = Vector3.new(15, 2, 15)
	spawnPlatform.Position = LOBBY.POSITION + Vector3.new(0, LOBBY.FLOOR_HEIGHT / 2 + 1, 0)
	spawnPlatform.Anchored = true
	spawnPlatform.Material = Enum.Material.ForceField
	spawnPlatform.Color = Color3.fromRGB(255, 255, 0)
	spawnPlatform.Parent = lobbyModel

	local platformLight = Instance.new("PointLight")
	platformLight.Brightness = 3
	platformLight.Range = 40
	platformLight.Color = Color3.fromRGB(255, 255, 0)
	platformLight.Parent = spawnPlatform

	task.spawn(function()
		while spawnPlatform.Parent do
			TweenService:Create(
				spawnPlatform,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					Transparency = 0.3,
				}
			):Play()
			task.wait(1)
		end
	end)

	-- 3. SPAWN LOCATION DO LOBBY (único)
	lobbySpawnLocation = Instance.new("SpawnLocation")
	lobbySpawnLocation.Name = "LobbySpawn"
	lobbySpawnLocation.Size = Vector3.new(8, 1, 8)
	lobbySpawnLocation.Position = LOBBY.POSITION + Vector3.new(0, LOBBY.FLOOR_HEIGHT / 2 + 3, 0)
	lobbySpawnLocation.Anchored = true
	lobbySpawnLocation.Transparency = 1
	lobbySpawnLocation.CanCollide = false
	lobbySpawnLocation.TopSurface = Enum.SurfaceType.Smooth
	lobbySpawnLocation.Enabled = true
	lobbySpawnLocation.Neutral = true
	lobbySpawnLocation.AllowTeamChangeOnTouch = false
	lobbySpawnLocation.Duration = 0
	lobbySpawnLocation.Parent = lobbyModel

	print("[SPAWN V6] ✓ SpawnLocation único do lobby criado")

	-- 4. PAREDES
	local wallPositions = {
		{
			pos = Vector3.new(0, LOBBY.WALL_HEIGHT / 2, LOBBY.SIZE.Z / 2),
			size = Vector3.new(LOBBY.SIZE.X, LOBBY.WALL_HEIGHT, LOBBY.WALL_THICKNESS),
		},
		{
			pos = Vector3.new(0, LOBBY.WALL_HEIGHT / 2, -LOBBY.SIZE.Z / 2),
			size = Vector3.new(LOBBY.SIZE.X, LOBBY.WALL_HEIGHT, LOBBY.WALL_THICKNESS),
		},
		{
			pos = Vector3.new(LOBBY.SIZE.X / 2, LOBBY.WALL_HEIGHT / 2, 0),
			size = Vector3.new(LOBBY.WALL_THICKNESS, LOBBY.WALL_HEIGHT, LOBBY.SIZE.Z),
		},
		{
			pos = Vector3.new(-LOBBY.SIZE.X / 2, LOBBY.WALL_HEIGHT / 2, 0),
			size = Vector3.new(LOBBY.WALL_THICKNESS, LOBBY.WALL_HEIGHT, LOBBY.SIZE.Z),
		},
	}

	for i, wallData in ipairs(wallPositions) do
		local wall = Instance.new("Part")
		wall.Name = "Wall" .. i
		wall.Size = wallData.size
		wall.Position = LOBBY.POSITION + wallData.pos
		wall.Anchored = true
		wall.Transparency = 0.2
		wall.Material = Enum.Material.ForceField
		wall.Color = Color3.fromRGB(0, 255, 255)
		wall.CanCollide = true
		wall.Parent = lobbyModel

		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
		particles.Size = NumberSequence.new(0.5)
		particles.Transparency = NumberSequence.new(0.5, 1)
		particles.Lifetime = NumberRange.new(2)
		particles.Rate = 10
		particles.Speed = NumberRange.new(2)
		particles.Parent = wall
	end

	-- 5. TETO
	local ceiling = Instance.new("Part")
	ceiling.Name = "LobbyCeiling"
	ceiling.Size = Vector3.new(LOBBY.SIZE.X, LOBBY.WALL_THICKNESS, LOBBY.SIZE.Z)
	ceiling.Position = LOBBY.POSITION
		+ Vector3.new(0, LOBBY.WALL_HEIGHT + LOBBY.WALL_THICKNESS / 2, 0)
	ceiling.Anchored = true
	ceiling.Transparency = 0.5
	ceiling.Material = Enum.Material.Glass
	ceiling.Color = Color3.fromRGB(100, 200, 255)
	ceiling.CanCollide = true
	ceiling.Parent = lobbyModel

	-- 6. PILARES
	local pillarOffsets = {
		Vector3.new(LOBBY.SIZE.X / 2 - 10, LOBBY.WALL_HEIGHT / 2, LOBBY.SIZE.Z / 2 - 10),
		Vector3.new(-LOBBY.SIZE.X / 2 + 10, LOBBY.WALL_HEIGHT / 2, LOBBY.SIZE.Z / 2 - 10),
		Vector3.new(LOBBY.SIZE.X / 2 - 10, LOBBY.WALL_HEIGHT / 2, -LOBBY.SIZE.Z / 2 + 10),
		Vector3.new(-LOBBY.SIZE.X / 2 + 10, LOBBY.WALL_HEIGHT / 2, -LOBBY.SIZE.Z / 2 + 10),
	}

	for i, offset in ipairs(pillarOffsets) do
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar" .. i
		pillar.Size = Vector3.new(8, LOBBY.WALL_HEIGHT, 8)
		pillar.Position = LOBBY.POSITION + offset
		pillar.Anchored = true
		pillar.Material = Enum.Material.Marble
		pillar.Color = Color3.fromRGB(220, 220, 220)
		pillar.Parent = lobbyModel

		local pLight = Instance.new("PointLight")
		pLight.Brightness = 2
		pLight.Range = 30
		pLight.Color = Color3.fromRGB(255, 255, 255)
		pLight.Parent = pillar
	end

	-- Referência SafeZone para compatibilidade com outros sistemas
	local safeZoneRef = Instance.new("Model")
	safeZoneRef.Name = "SafeZone"
	safeZoneRef.Parent = workspace

	local refPart = Instance.new("Part")
	refPart.Name = "Reference"
	refPart.Size = Vector3.new(1, 1, 1)
	refPart.Position = LOBBY.POSITION
	refPart.Anchored = true
	refPart.Transparency = 1
	refPart.CanCollide = false
	refPart.Parent = safeZoneRef

	print("[SPAWN V6] ✓ Estrutura do lobby completa")
end

-- =====================================
-- TELEPORTES
-- =====================================

local function teleportToLobby(character)
	if not character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	local angle = math.random() * math.pi * 2
	local radius = math.random(5, LOBBY.SPAWN_RADIUS)

	local targetPosition = LOBBY.POSITION
		+ Vector3.new(math.cos(angle) * radius, LOBBY.FLOOR_HEIGHT + 5, math.sin(angle) * radius)

	hrp.CFrame = CFrame.new(targetPosition)
	hrp.Velocity = Vector3.new(0, 0, 0)
	hrp.RotVelocity = Vector3.new(0, 0, 0)
	return true
end

-- (V6) Usa o CFrame das partes de PlayerTp diretamente.
-- O jogador aparece exatamente onde a part está (com 3 studs de offset Y).
local function teleportToMapSpawn(character)
	if not character or #mapSpawnPoints == 0 then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	local chosenCFrame = mapSpawnPoints[math.random(1, #mapSpawnPoints)]

	-- Mantém a rotação da part e adiciona offset Y para não spawnar dentro dela
	hrp.CFrame = chosenCFrame + Vector3.new(0, 3, 0)
	hrp.Velocity = Vector3.new(0, 0, 0)
	hrp.RotVelocity = Vector3.new(0, 0, 0)
	return true
end

-- =====================================
-- EFEITOS DA SAFE ZONE
-- =====================================

local function applyZoneSafeEffects(character)
	if not character then
		return
	end

	local oldFF = character:FindFirstChild("SafeZoneProtection")
	if oldFF then
		oldFF:Destroy()
	end

	local oldTag = character:FindFirstChild("InSafeZone")
	if oldTag then
		oldTag:Destroy()
	end

	local ff = Instance.new("ForceField")
	ff.Name = "SafeZoneProtection"
	ff.Visible = true
	ff.Parent = character

	local tag = Instance.new("BoolValue")
	tag.Name = "InSafeZone"
	tag.Value = true
	tag.Parent = character
end

local function removeZoneSafeEffects(character)
	if not character then
		return
	end

	local ff = character:FindFirstChild("SafeZoneProtection")
	if ff then
		ff:Destroy()
	end

	local tag = character:FindFirstChild("InSafeZone")
	if tag then
		tag:Destroy()
	end
end

-- =====================================
-- BARREIRA DO JOGADOR
-- =====================================

local function createPlayerBarrier(player)
	if exitBarriers[player] then
		exitBarriers[player]:Destroy()
	end

	local barrier = Instance.new("Part")
	barrier.Name = "PlayerBarrier_" .. player.Name
	barrier.Size = Vector3.new(20, 20, 5)
	barrier.Position = LOBBY.POSITION + Vector3.new(0, 10, -LOBBY.SIZE.Z / 2 + 2)
	barrier.Anchored = true
	barrier.Transparency = 0.8
	barrier.Material = Enum.Material.ForceField
	barrier.Color = Color3.fromRGB(255, 0, 0)
	barrier.CanCollide = true
	barrier.Parent = lobbyModel

	exitBarriers[player] = barrier
end

local function removePlayerBarrier(player)
	if exitBarriers[player] then
		local barrier = exitBarriers[player]

		TweenService:Create(barrier, TweenInfo.new(0.5), {
			Transparency = 1,
			Size = Vector3.new(20, 20, 0.1),
		}):Play()

		task.wait(0.5)
		if barrier and barrier.Parent then
			barrier:Destroy()
		end
		exitBarriers[player] = nil
	end
end

-- =====================================
-- RESPAWN LOCATION DINÂMICO
-- =====================================

local function updateRespawnLocation(player, hasCharacter)
	if hasCharacter then
		player.RespawnLocation = nil
		print(string.format("[SPAWN V6] %s → RespawnLocation: MAPA (PlayerTp)", player.Name))
	else
		player.RespawnLocation = lobbySpawnLocation
		print(string.format("[SPAWN V6] %s → RespawnLocation: LOBBY", player.Name))
	end
end

-- =====================================
-- CLASSE DE ESTADO DO JOGADOR
-- =====================================

local PlayerState = {}
PlayerState.__index = PlayerState

function PlayerState.new(player)
	local self = setmetatable({}, PlayerState)

	self.player = player
	self.hasCharacter = false
	self.isInSafeZone = true
	self.isDead = false
	self.equippedCharacter = nil
	self.lastTeleportTime = 0
	self.detectionActive = false
	self.isProcessing = false
	self.detectionRetries = 0

	return self
end

function PlayerState:log(message)
	print(string.format("[%s] %s", self.player.Name, message))
end

function PlayerState:canTeleport()
	return (tick() - self.lastTeleportTime) >= CONFIG.TELEPORT_COOLDOWN
end

function PlayerState:startDetection()
	if self.detectionActive then
		self:log("⚠️ Detecção já ativa")
		return
	end

	self.detectionActive = true
	self.detectionRetries = 0
	self:log("🔍 Detecção ATIVADA — aguardando personagem ser equipado")

	task.spawn(function()
		while self.detectionActive and self.player.Parent do
			if self.isInSafeZone and self.player.Character then
				local humanoid = self.player.Character:FindFirstChild("Humanoid")
				local hrp = self.player.Character:FindFirstChild("HumanoidRootPart")

				if humanoid and humanoid.Health > 0 and hrp then
					local success, data = pcall(function()
						return _G.PlayerDataManager.getPlayerData(self.player)
					end)

					if
						success
						and data
						and data.equippedCharacter
						and not self.hasCharacter
						and not self.isProcessing
					then
						self:log(string.format("✅ DETECTADO: %s", data.equippedCharacter))
						self:handleEquipment(data.equippedCharacter)
					elseif not success then
						self.detectionRetries = self.detectionRetries + 1
						self:log(
							string.format(
								"⚠️ Erro ao obter dados (%d/%d)",
								self.detectionRetries,
								CONFIG.MAX_DETECTION_RETRIES
							)
						)

						if self.detectionRetries >= CONFIG.MAX_DETECTION_RETRIES then
							self:log("❌ Detecção falhou após muitas tentativas")
							self:stopDetection()
						end
					end

					-- Anti-escape: força volta ao lobby se saiu sem personagem
					local distance = (hrp.Position - LOBBY.POSITION).Magnitude
					if distance > LOBBY.SIZE.X / 2 + 10 and not self.hasCharacter then
						self:log("⚠️ Tentativa de escape bloqueada — teleportando de volta")
						teleportToLobby(self.player.Character)
					end
				end
			else
				break
			end

			task.wait(CONFIG.CHECK_INTERVAL)
		end

		self:log("🛑 Loop de detecção finalizado")
	end)
end

function PlayerState:stopDetection()
	if not self.detectionActive then
		return
	end

	self.detectionActive = false
	self.detectionRetries = 0
	self:log("🛑 Detecção DESATIVADA")
end

function PlayerState:handleEquipment(characterName)
	if self.isProcessing or not self:canTeleport() then
		return
	end

	self.isProcessing = true
	self:log(string.format("⚙️ Equipando: %s → teleportando para mapa", characterName))

	self.hasCharacter = true
	self.equippedCharacter = characterName
	self.isInSafeZone = false
	self.lastTeleportTime = tick()

	updateRespawnLocation(self.player, true)
	self:stopDetection()
	removePlayerBarrier(self.player)

	task.wait(0.5)

	if self.player.Character then
		removeZoneSafeEffects(self.player.Character)
		task.wait(0.3)

		local success = teleportToMapSpawn(self.player.Character)
		if success then
			self:log(string.format("✅ %s teleportado para mapa via PlayerTp!", characterName))
		else
			self:log("⚠️ Falha ao teleportar — PlayerTp pode estar vazio")
		end

		pcall(function()
			if syncCharacterStateRemote then
				syncCharacterStateRemote:FireClient(self.player, characterName, true)
			end
		end)

		pcall(function()
			if spectatorModeRemote then
				spectatorModeRemote:FireClient(self.player, false, {})
			end
		end)
	end

	self.isProcessing = false
end

function PlayerState:handleSpawn()
	if self.isProcessing then
		self:log("⚠️ Já processando spawn, ignorando")
		return
	end

	self.isProcessing = true
	self:log("🔄 Processando spawn...")

	local character = self.player.Character
	if not character then
		self.isProcessing = false
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		self:log("❌ Humanoid não encontrado")
		self.isProcessing = false
		return
	end

	if self.isDead or not self.hasCharacter then
		-- SEM PERSONAGEM → SPAWN NO LOBBY
		self:log("🛡️ SPAWN NO LOBBY (sem personagem equipado)")

		updateRespawnLocation(self.player, false)
		task.wait(0.2)

		-- Duplo teleporte para garantir posição
		teleportToLobby(character)
		task.wait(0.1)
		teleportToLobby(character)

		applyZoneSafeEffects(character)
		createPlayerBarrier(self.player)

		self.isDead = false
		self.isInSafeZone = true
		self.hasCharacter = false
		self.equippedCharacter = nil

		pcall(function()
			local data = _G.PlayerDataManager.getPlayerData(self.player)
			if data then
				data.equippedCharacter = nil
			end
		end)

		task.wait(0.5)
		self:startDetection()

		pcall(function()
			if syncCharacterStateRemote then
				syncCharacterStateRemote:FireClient(self.player, nil, false)
			end
		end)

		pcall(function()
			if spectatorModeRemote then
				local activePlayers = {}
				for _, p in pairs(Players:GetPlayers()) do
					local state = playerStates[p]
					if state and state.hasCharacter and p.Character then
						table.insert(activePlayers, p)
					end
				end
				spectatorModeRemote:FireClient(self.player, true, activePlayers)
			end
		end)
	else
		-- COM PERSONAGEM → SPAWN NO MAPA
		self:log(
			string.format("⚔️ SPAWN NO MAPA (%s) — usando PlayerTp", self.equippedCharacter)
		)

		updateRespawnLocation(self.player, true)
		task.wait(0.2)

		removeZoneSafeEffects(character)
		removePlayerBarrier(self.player)

		self.isInSafeZone = false
		self:stopDetection()

		pcall(function()
			if spectatorModeRemote then
				spectatorModeRemote:FireClient(self.player, false, {})
			end
		end)
	end

	-- Detectar morte
	pcall(function()
		humanoid.Died:Connect(function()
			self:log("💀 Morte detectada — voltando para lobby no próximo spawn")
			self.isDead = true
			self.hasCharacter = false
			self.equippedCharacter = nil
			self:stopDetection()
			removePlayerBarrier(self.player)
			updateRespawnLocation(self.player, false)
		end)
	end)

	self.isProcessing = false
end

-- =====================================
-- EVENTOS DE JOGADOR
-- =====================================

Players.PlayerAdded:Connect(function(player)
	if not isSystemReady then
		warn("[SPAWN V6] ⚠️ Sistema não pronto, aguardando...")
		while not isSystemReady do
			task.wait(0.5)
		end
	end

	local state = PlayerState.new(player)
	playerStates[player] = state

	state:log("✅ Conectado")

	updateRespawnLocation(player, false)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		pcall(function()
			state:handleSpawn()
		end)
	end)

	player.CharacterRemoving:Connect(function()
		pcall(function()
			state:stopDetection()
			removePlayerBarrier(player)
		end)
	end)

	task.wait(1)
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	local state = playerStates[player]
	if state then
		state:log("👋 Desconectando")
		pcall(function()
			state:stopDetection()
		end)
	end
	pcall(function()
		removePlayerBarrier(player)
	end)
	playerStates[player] = nil
end)

-- =====================================
-- FUNÇÕES GLOBAIS
-- =====================================

_G.OnCharacterSelected = function(player, characterName)
	local state = playerStates[player]
	if state and state.isInSafeZone then
		pcall(function()
			state:handleEquipment(characterName)
		end)
	end
end

_G.SetSpectatorMode = function(player, enabled)
	local state = playerStates[player]
	if not state then
		return
	end

	pcall(function()
		if enabled then
			state.hasCharacter = false
			state.isInSafeZone = true

			updateRespawnLocation(player, false)

			if player.Character then
				teleportToLobby(player.Character)
				applyZoneSafeEffects(player.Character)
			end

			createPlayerBarrier(player)
			state:startDetection()
		end
	end)
end

-- =====================================
-- DEBUG
-- =====================================

_G.DebugSpawnState = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		print("❌ Jogador não encontrado")
		return
	end

	local state = playerStates[player]
	if not state then
		print("❌ Estado não encontrado")
		return
	end

	print(
		"\n═══════════════════════════════════════"
	)
	print(string.format("DEBUG SPAWN V6: %s", playerName))
	print(
		"═══════════════════════════════════════"
	)
	print("hasCharacter:      ", state.hasCharacter)
	print("isInSafeZone:      ", state.isInSafeZone)
	print("isDead:            ", state.isDead)
	print("equippedCharacter: ", state.equippedCharacter or "Nenhum")
	print("detectionActive:   ", state.detectionActive)
	print(
		"RespawnLocation:   ",
		player.RespawnLocation and player.RespawnLocation.Name or "MAPA (nil)"
	)
	print("Lobby Position:    ", tostring(LOBBY.POSITION))
	print("Map Spawn Points:  ", #mapSpawnPoints)
	print(
		"═══════════════════════════════════════\n"
	)
end

_G.ListAllPlayers = function()
	print("\n═══ JOGADORES ONLINE (SPAWN V6) ═══")
	for player, state in pairs(playerStates) do
		local location = state.hasCharacter and "⚔️ MAPA" or "🛡️ LOBBY"
		local respawnLoc = player.RespawnLocation and "Lobby" or "Mapa (PlayerTp)"
		print(string.format("  %s: %s | Next spawn: %s", player.Name, location, respawnLoc))
	end
	print(
		"═══════════════════════════════════\n"
	)
end

-- Recarregar spawn points em runtime (útil se PlayerTp mudar)
_G.ReloadMapSpawnPoints = function()
	collectMapSpawnPoints()
	print(string.format("[SPAWN V6] ✓ Spawn points recarregados: %d pontos", #mapSpawnPoints))
end

-- =====================================
-- INICIALIZAÇÃO FINAL
-- =====================================

-- 1. Coletar spawn points da pasta PlayerTp
collectMapSpawnPoints()

-- 2. Criar estrutura do lobby (centralizada sobre MapaPrincipal)
createLobbyStructure()

-- 3. Configurar jogadores já presentes
for _, player in pairs(Players:GetPlayers()) do
	updateRespawnLocation(player, false)
	print(string.format("[SPAWN V6] ✓ RespawnLocation configurado: %s", player.Name))
end

-- 4. Auto-sync (detecta personagem equipado enquanto no lobby)
task.spawn(function()
	while true do
		task.wait(2)

		for player, state in pairs(playerStates) do
			if player.Parent then
				pcall(function()
					local data = _G.PlayerDataManager.getPlayerData(player)

					if
						data
						and data.equippedCharacter
						and not state.equippedCharacter
						and state.isInSafeZone
					then
						state:log("🔄 Auto-sync detectado")
						state:handleEquipment(data.equippedCharacter)
					end
				end)
			end
		end
	end
end)

-- 5. Monitor de saúde
task.spawn(function()
	while true do
		task.wait(60)

		local inLobby, inMap = 0, 0

		for player, state in pairs(playerStates) do
			if player.Parent then
				if state.hasCharacter then
					inMap = inMap + 1
				else
					inLobby = inLobby + 1
				end
			end
		end

		print(
			string.format(
				"[SPAWN V6 HEALTH] Lobby: %d | Mapa: %d | Spawns: %d",
				inLobby,
				inMap,
				#mapSpawnPoints
			)
		)
	end
end)

print([[
╔════════════════════════════════════════════════════╗
║  ✅ SPAWN SYSTEM V6 CARREGADO                     ║
╠════════════════════════════════════════════════════╣
║  SUBSTITUI: SPAWN_SYSTEM_V5                       ║
║  ⚠️  REMOVER: SPAWN_SYSTEM_V5                     ║
╠════════════════════════════════════════════════════╣
║  NOVIDADES V6:                                     ║
║  • Lobby centralizado sobre "MapaPrincipal" ✓     ║
║  • Spawn points lidos de workspace.PlayerTp ✓     ║
║  • teleportToMapSpawn usa CFrame das Parts ✓      ║
║  • 1 único SpawnLocation no lobby (mantido) ✓     ║
╠════════════════════════════════════════════════════╣
║  SETUP NECESSÁRIO NO STUDIO:                       ║
║  • Modelo do mapa: nome exato "MapaPrincipal"     ║
║  • Pasta de spawns: workspace > "PlayerTp"        ║
║    └─ Adicione Parts onde os jogadores aparecem   ║
╠════════════════════════════════════════════════════╣
║  DEBUG:                                            ║
║  • _G.DebugSpawnState("Nome")                     ║
║  • _G.ListAllPlayers()                            ║
║  • _G.ReloadMapSpawnPoints() — recarrega PlayerTp ║
╚════════════════════════════════════════════════════╝
]])
