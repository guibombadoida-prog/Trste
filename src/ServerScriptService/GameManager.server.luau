-- ============================================
-- GAME MANAGER V6 — SELL SYSTEM + METADATA
-- Coloque em ServerScriptService
-- Nome: "GameManager"
-- SUBSTITUI: GAME_MANAGER_V5
-- ============================================
-- NOVIDADES V6:
-- * Sistema de VENDA de personagens (25% do valor)
-- * Compatível com DataManager V4 (objetos com metadados)
-- * ownsCharacter agora busca por name nos objetos
-- * Novo remote: SellCharacter
-- * Personagens de Bounty NÃO podem ser vendidos
-- * Personagens Mandatory/Gamepass/Badge/Awakened NÃO vendáveis
-- * Validação de equipamento ativo antes da venda
-- * Toda lógica de Kill/Death/HP mantida
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

-- Aguardar sistemas
repeat
	task.wait()
until _G.PlayerDataManager
if _G.AwakeningSystem then
	print("[GAME MGR V6] Sistema de despertar detectado")
end

print([[
╔══════════════════════════════════════════════╗
║     GAME MANAGER V6 - INICIALIZANDO          ║
╚══════════════════════════════════════════════╝
]])

-- =====================================
-- REMOTES
-- =====================================

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local charactersFolder = ReplicatedStorage:FindFirstChild("Characters")
if not charactersFolder then
	charactersFolder = Instance.new("Folder")
	charactersFolder.Name = "Characters"
	charactersFolder.Parent = ReplicatedStorage
end

-- Pasta de imagens
local characterImages = ReplicatedStorage:FindFirstChild("CharacterImages")
if not characterImages then
	characterImages = Instance.new("Folder")
	characterImages.Name = "CharacterImages"
	characterImages.Parent = ReplicatedStorage
	print("[GAME MGR V6] Pasta 'CharacterImages' criada")
else
	print(
		string.format(
			"[GAME MGR V6] CharacterImages: %d imagem(ns)",
			#characterImages:GetChildren()
		)
	)
end

-- =====================================
-- GARANTIR TIPO CORRETO DOS REMOTES
-- =====================================

local function ensureRemoteType(name, requiredType)
	local existing = remotes:FindFirstChild(name)

	if existing then
		if requiredType == "RemoteFunction" and not existing:IsA("RemoteFunction") then
			existing.Parent = nil
			existing = nil
		elseif requiredType == "RemoteEvent" and not existing:IsA("RemoteEvent") then
			existing.Parent = nil
			existing = nil
		end
	end

	if not existing then
		existing = Instance.new(requiredType)
		existing.Name = name
		existing.Parent = remotes
		print(string.format("[GAME MGR V6] Remote criado: %s (%s)", name, requiredType))
	end

	return existing
end

local selectCharacter = ensureRemoteType("SelectCharacter", "RemoteFunction")
local purchaseCharacter = ensureRemoteType("PurchaseCharacter", "RemoteFunction")
local getPlayerData = ensureRemoteType("GetPlayerData", "RemoteFunction")
local syncCharacterState = ensureRemoteType("SyncCharacterState", "RemoteEvent")
local sellCharacter = ensureRemoteType("SellCharacter", "RemoteFunction")

-- =====================================
-- TABELAS DE PERSONAGENS
-- =====================================

local characterPrices = {
	Noob = 0,
	Guest = 50,
	Danilo = 200,
	["Gui Bomba"] = 300,
	["Dark Jc"] = 500,
	Shushuhus8 = 250,
}

local bountyCharacters = {
	-- Adicione personagens de bounty aqui (veja GUIA)
	-- Exemplo: Maria = 2500,
}

local gamepassCharacters = {
	["Faker Gui"] = 1247245466,
	["Alma Perdida"] = 1161544217,
}

local badgeIds = {
	-- ["Miner Pedro"] = 123456,
}

local characterHealth = {
	Noob = 200,
	Guest = 220,
	Danilo = 200,
	["Gui Bomba"] = 220,
	["Faker Gui"] = 250,
	Maria = 230,
	Shushuhus8 = 200,
	["Dark Jc"] = 280,
	["Alma Perdida"] = 300,
}

-- =====================================
-- SELL CONFIG
-- =====================================

local SELL_PERCENTAGE = 0.25 -- 25%

-- =====================================
-- VARIÁVEIS
-- =====================================

local equippedCharacters = {}
local lastDamager = {}
local characterDeathConnections = {}
local sellCooldowns = {} -- Anti-spam para vendas

-- =====================================
-- FUNÇÕES AUXILIARES (V4 compatível)
-- =====================================

local function playerOwnsCharacter(player, characterName)
	-- Usa a nova API do DataManager V4
	if _G.PlayerDataManager.ownsCharacter then
		return _G.PlayerDataManager.ownsCharacter(player, characterName)
	end

	-- Fallback: busca manual
	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if not playerData then
		return false
	end

	-- V4: ownedCharacters é lista de objetos
	for _, charObj in ipairs(playerData.ownedCharacters) do
		if type(charObj) == "table" then
			if charObj.name == characterName then
				return true
			end
		elseif type(charObj) == "string" then
			if charObj == characterName then
				return true
			end
		end
	end

	-- Noob sempre disponível
	if characterName == "Noob" then
		_G.PlayerDataManager.addCharacterToInventory(player, characterName)
		return true
	end

	-- Bounty
	if bountyCharacters[characterName] then
		local bounty = 0
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local bv = ls:FindFirstChild("Bounty")
			if bv then
				bounty = bv.Value
			end
		end
		return bounty >= bountyCharacters[characterName]
	end

	-- Gamepass
	if gamepassCharacters[characterName] then
		local gpId = gamepassCharacters[characterName]
		if gpId and gpId > 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gpId)
			end)
			if ok and has then
				_G.PlayerDataManager.addCharacterToInventory(player, characterName)
				_G.PlayerDataManager.savePlayerData(player)
				return true
			end
		end
	end

	-- Badge
	if badgeIds[characterName] then
		local bid = badgeIds[characterName]
		if bid and bid > 0 then
			local ok, has = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, bid)
			end)
			if ok and has then
				_G.PlayerDataManager.addCharacterToInventory(player, characterName)
				return true
			end
		end
	end

	return false
end

-- =====================================
-- DESEQUIPAR PERSONAGEM
-- =====================================

local function unequipCharacter(player)
	if not equippedCharacters[player] then
		return
	end

	local characterName = equippedCharacters[player]
	print(string.format("[GAME MGR V6] Desequipando %s de %s", characterName, player.Name))

	equippedCharacters[player] = nil

	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if playerData then
		playerData.equippedCharacter = nil
	end

	pcall(function()
		syncCharacterState:FireClient(player, nil, false)
	end)

	if characterDeathConnections[player] then
		pcall(function()
			characterDeathConnections[player]:Disconnect()
		end)
		characterDeathConnections[player] = nil
	end
end

-- =====================================
-- EQUIPAR PERSONAGEM
-- =====================================

local function equipCharacter(player, characterName)
	if not player or not player.Character then
		return false
	end

	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- HP
	local health = characterHealth[characterName] or 100
	humanoid.MaxHealth = health
	humanoid.Health = health

	-- Limpar ferramentas
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		backpack = Instance.new("Backpack")
		backpack.Parent = player
	end

	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = nil
		end
	end
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = nil
		end
	end

	-- Dar ferramentas
	local characterFolder = charactersFolder:FindFirstChild(characterName)
	if characterFolder then
		for _, item in pairs(characterFolder:GetChildren()) do
			if item:IsA("Tool") then
				item:Clone().Parent = backpack
			end
		end
	end

	equippedCharacters[player] = characterName

	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if playerData then
		playerData.equippedCharacter = characterName
	end

	syncCharacterState:FireClient(player, characterName, true)

	if _G.OnCharacterSelected then
		_G.OnCharacterSelected(player, characterName)
	end

	print(string.format("[GAME MGR V6] %s equipou %s (%d HP)", player.Name, characterName, health))
	return true
end

-- =====================================
-- REMOTE: SELECIONAR PERSONAGEM
-- =====================================

local function handleSelectCharacter(player, characterName)
	if type(characterName) ~= "string" then
		return false, "Dados inválidos!"
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if equippedCharacters[player] and humanoid and humanoid.Health > 0 then
			return false, "Você precisa morrer para trocar de personagem!"
		end
	end

	if not playerOwnsCharacter(player, characterName) then
		if bountyCharacters[characterName] then
			return false, "Você precisa de " .. bountyCharacters[characterName] .. " de bounty!"
		elseif gamepassCharacters[characterName] then
			return false, "Você precisa comprar o gamepass!"
		end
		return false, "Você não possui este personagem!"
	end

	local success = equipCharacter(player, characterName)
	if success then
		return true, characterName
	else
		return false, "Erro ao equipar personagem!"
	end
end

selectCharacter.OnServerInvoke = handleSelectCharacter
_G.SelectCharacterFunction = handleSelectCharacter

-- =====================================
-- REMOTE: COMPRAR PERSONAGEM
-- =====================================

purchaseCharacter.OnServerInvoke = function(player, characterName)
	if type(characterName) ~= "string" then
		return false, "Dados inválidos!"
	end

	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if not playerData then
		return false, "Erro ao carregar dados!"
	end

	-- Verificar posse (V4 compatível)
	if _G.PlayerDataManager.ownsCharacter(player, characterName) then
		return false, "Você já possui este personagem!"
	end

	local price = characterPrices[characterName]
	if not price then
		return false, "Personagem não encontrado na loja!"
	end

	if playerData.coins < price then
		return false, "Moedas insuficientes! Precisa de " .. price
	end

	-- Comprar com metadados (V4)
	_G.PlayerDataManager.updateCoins(player, -price)
	local success, charId = _G.PlayerDataManager.addCharacter(player, characterName, "Shop", price)

	if not success then
		-- Reembolsar
		_G.PlayerDataManager.updateCoins(player, price)
		return false, "Erro ao adicionar personagem!"
	end

	_G.PlayerDataManager.savePlayerData(player)

	print(
		string.format(
			"[GAME MGR V6] %s comprou %s por %d moedas",
			player.Name,
			characterName,
			price
		)
	)
	return true, "Personagem comprado com sucesso!"
end

-- =====================================
-- REMOTE: OBTER DADOS DO JOGADOR
-- =====================================

getPlayerData.OnServerInvoke = function(player)
	-- Usar getClientData para retrocompatibilidade
	if _G.PlayerDataManager.getClientData then
		local data = _G.PlayerDataManager.getClientData(player)
		if data and equippedCharacters[player] then
			data.equippedCharacter = equippedCharacters[player]
		end
		return data
	end

	-- Fallback
	local data = _G.PlayerDataManager.getPlayerData(player)
	if data and equippedCharacters[player] then
		data.equippedCharacter = equippedCharacters[player]
	end
	return data
end

-- =====================================
-- SISTEMA DE VENDA DE PERSONAGENS
-- =====================================

local function calculateSellPrice(charObj)
	if not charObj then
		return 0
	end

	-- Personagens de bounty NÃO podem ser vendidos
	if charObj.source == "Reward" then
		return 0
	end

	-- Personagens sem preço original não podem ser vendidos
	if not charObj.originalPrice or charObj.originalPrice <= 0 then
		return 0
	end

	return math.floor(charObj.originalPrice * SELL_PERCENTAGE)
end

sellCharacter.OnServerInvoke = function(player, charId)
	-- ===== CAMADA 1: Type checking =====
	if type(charId) ~= "string" then
		return false, "Dados inválidos!", 0
	end

	if #charId > 100 then
		return false, "Dados inválidos!", 0
	end

	-- ===== CAMADA 2: Rate limiting =====
	local now = tick()
	if sellCooldowns[player] and now - sellCooldowns[player] < 1 then
		return false, "Aguarde antes de vender novamente!", 0
	end
	sellCooldowns[player] = now

	-- ===== CAMADA 3: Dados do jogador =====
	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if not playerData then
		return false, "Erro ao carregar dados!", 0
	end

	-- ===== CAMADA 4: Buscar personagem por ID =====
	local charObj, charIndex = _G.PlayerDataManager.getCharacterById(player, charId)
	if not charObj then
		return false, "Personagem não encontrado no seu inventário!", 0
	end

	-- ===== CAMADA 5: Validações de permissão =====

	-- Não pode vender personagem equipado
	if equippedCharacters[player] == charObj.name then
		return false, "Desequipe o personagem antes de vender! (Morra primeiro)", 0
	end

	-- Verificar sellable pelo source
	if not charObj.sellable then
		local reasons = {
			Mandatory = "Personagens obrigatórios não podem ser vendidos!",
			Gamepass = "Personagens de Gamepass não podem ser vendidos!",
			Badge = "Personagens de Badge não podem ser vendidos!",
			Reward = "Personagens de Recompensa (Bounty) não podem ser vendidos!",
			Awakened = "Personagens Despertados não podem ser vendidos!",
		}
		local reason = reasons[charObj.source] or "Este personagem não pode ser vendido!"
		return false, reason, 0
	end

	-- Calcular preço de venda
	local sellPrice = calculateSellPrice(charObj)
	if sellPrice <= 0 then
		return false, "Este personagem não tem valor de venda!", 0
	end

	-- ===== CAMADA 6: Executar venda =====

	-- Remover personagem
	local removed, removedObj = _G.PlayerDataManager.removeCharacterById(player, charId)
	if not removed then
		return false, "Erro ao remover personagem!", 0
	end

	-- Dar moedas
	_G.PlayerDataManager.updateCoins(player, sellPrice)

	-- Rastrear venda
	playerData.stats.characters_sold = (playerData.stats.characters_sold or 0) + 1

	-- Salvar
	_G.PlayerDataManager.savePlayerData(player)

	print(
		string.format(
			"[GAME MGR V6] %s vendeu %s por %d moedas (25%% de %d)",
			player.Name,
			charObj.name,
			sellPrice,
			charObj.originalPrice
		)
	)

	return true, string.format("Vendeu %s por %d moedas!", charObj.name, sellPrice), sellPrice
end

-- =====================================
-- SISTEMA DE KILL / DEATH
-- =====================================

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if characterDeathConnections[player] then
		pcall(function()
			characterDeathConnections[player]:Disconnect()
		end)
	end

	characterDeathConnections[player] = humanoid.Died:Connect(function()
		unequipCharacter(player)
		_G.PlayerDataManager.incrementStat(player, "deaths", 1)

		local killer = lastDamager[player]
		if killer and killer ~= player and killer.Parent then
			_G.PlayerDataManager.updateCoins(killer, 50)
			_G.PlayerDataManager.updateBounty(killer, 10)
			_G.PlayerDataManager.incrementStat(killer, "kills", 1)

			local gui = killer:FindFirstChild("PlayerGui")
			if gui then
				local notification = Instance.new("ScreenGui")
				notification.Name = "KillNotification"
				notification.Parent = gui

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(0.3, 0, 0.1, 0)
				frame.Position = UDim2.new(0.35, 0, 0.05, 0)
				frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
				frame.BorderSizePixel = 3
				frame.Parent = notification

				local text = Instance.new("TextLabel")
				text.Size = UDim2.new(1, 0, 1, 0)
				text.BackgroundTransparency = 1
				text.Text = "ELIMINASTE " .. player.Name:upper() .. "! +$50 +10B"
				text.TextColor3 = Color3.new(1, 1, 1)
				text.TextScaled = true
				text.Font = Enum.Font.Arcade
				text.Parent = frame

				Debris:AddItem(notification, 3)
			end
		end

		lastDamager[player] = nil
	end)

	-- Detector de dano
	character.ChildAdded:Connect(function(tool)
		if tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle")
			if handle then
				handle.Touched:Connect(function(hit)
					if hit and hit.Parent then
						local hitHumanoid = hit.Parent:FindFirstChild("Humanoid")
						if hitHumanoid and hitHumanoid.Parent ~= character then
							local victim = Players:GetPlayerFromCharacter(hit.Parent)
							if victim then
								lastDamager[victim] = player
								task.wait(10)
								if lastDamager[victim] == player then
									lastDamager[victim] = nil
								end
							end
						end
					end
				end)
			end
		end
	end)
end

-- =====================================
-- VERIFICAR GAMEPASSES
-- =====================================

local function checkGamepasses(player)
	task.wait(2)

	for charName, gpId in pairs(gamepassCharacters) do
		if gpId and gpId > 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gpId)
			end)
			if ok and has then
				if not _G.PlayerDataManager.ownsCharacter(player, charName) then
					_G.PlayerDataManager.addCharacterToInventory(player, charName)
					print(
						string.format(
							"[GAME MGR V6] Auto-adicionado %s para %s",
							charName,
							player.Name
						)
					)
				end
			end
		end
	end

	_G.PlayerDataManager.savePlayerData(player)
end

-- =====================================
-- EVENTOS DE JOGADOR
-- =====================================

Players.PlayerAdded:Connect(function(player)
	print(string.format("[GAME MGR V6] %s entrou no jogo", player.Name))

	task.spawn(function()
		checkGamepasses(player)
	end)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character)
	end)

	player.CharacterRemoving:Connect(function()
		lastDamager[player] = nil
		if characterDeathConnections[player] then
			pcall(function()
				characterDeathConnections[player]:Disconnect()
			end)
			characterDeathConnections[player] = nil
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	unequipCharacter(player)
	lastDamager[player] = nil
	sellCooldowns[player] = nil

	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if playerData then
		playerData.equippedCharacter = nil
		_G.PlayerDataManager.savePlayerData(player)
	end
end)

-- =====================================
-- EXPORTAR CONFIG PARA OUTROS SISTEMAS
-- =====================================

_G.GameManagerConfig = {
	characterPrices = characterPrices,
	bountyCharacters = bountyCharacters,
	gamepassCharacters = gamepassCharacters,
	badgeIds = badgeIds,
	characterHealth = characterHealth,
	SELL_PERCENTAGE = SELL_PERCENTAGE,
	getEquippedCharacter = function(player)
		return equippedCharacters[player]
	end,
	isCharacterEquipped = function(player, characterName)
		return equippedCharacters[player] == characterName
	end,
}

-- =====================================
-- DEBUG
-- =====================================

_G.DebugGameManager = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		print("Jogador não encontrado")
		return
	end

	print("\n========== DEBUG GAME MANAGER V6 ==========")
	print(string.format("Jogador: %s", player.Name))
	print(string.format("Equipado: %s", equippedCharacters[player] or "Nenhum"))

	local playerData = _G.PlayerDataManager.getPlayerData(player)
	if playerData then
		print("\n--- PERSONAGENS (V4 com metadados) ---")
		for i, charObj in ipairs(playerData.ownedCharacters) do
			local sellPrice = calculateSellPrice(charObj)
			print(
				string.format(
					"  %d. %s [%s] | Preço: %d | Venda: %s | Trade: %s | ID: %s",
					i,
					charObj.name,
					charObj.source,
					charObj.originalPrice or 0,
					charObj.sellable and (sellPrice .. " moedas") or "N/A",
					charObj.tradeable and "Sim" or "Não",
					string.sub(charObj.id, 1, 8) .. "..."
				)
			)
		end
	end

	print("=====================================\n")
end

print([[
╔══════════════════════════════════════════════════════╗
║  GAME MANAGER V6 — SELL SYSTEM + METADATA            ║
╠══════════════════════════════════════════════════════╣
║  SUBSTITUI: GAME_MANAGER_V5                          ║
║  REMOVER:   GAME_MANAGER_V5                          ║
╠══════════════════════════════════════════════════════╣
║  NOVIDADES V6:                                       ║
║  * Sistema de VENDA (25% do valor original)          ║
║  * Compatível com DataManager V4 (metadados)         ║
║  * Bounty NÃO vendável                               ║
║  * Mandatory/Gamepass/Badge NÃO vendáveis            ║
║  * Rate limiting na venda                            ║
║  * Validação de personagem equipado                  ║
║  * _G.GameManagerConfig exportado                    ║
╠══════════════════════════════════════════════════════╣
║  REMOTES:                                            ║
║  * SellCharacter (NOVO) → RemoteFunction             ║
║  * PurchaseCharacter     → RemoteFunction            ║
║  * SelectCharacter       → RemoteFunction            ║
║  * GetPlayerData         → RemoteFunction            ║
║  * SyncCharacterState    → RemoteEvent               ║
╠══════════════════════════════════════════════════════╣
║  DEBUG: _G.DebugGameManager("NomeJogador")           ║
╚══════════════════════════════════════════════════════╝
]])
