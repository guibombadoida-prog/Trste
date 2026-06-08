-- ============================================
-- DATA MANAGER SERVER V4 — SISTEMA DE METADADOS
-- Coloque em ServerScriptService
-- Nome: "DataManager"
-- SUBSTITUI: DataManager_Server_Script_V3
-- ============================================
-- NOVIDADES V4:
-- * ownedCharacters migra de strings para objetos com metadados
-- * Cada personagem tem: id, name, source, acquiredAt, originalPrice
-- * Source define permissões: tradeable, sellable
-- * Migração automática de dados V3 → V4
-- * API expandida: getCharacterById, removeCharacter, etc.
-- * Novos campos: tradeHistory, missions (preparado)
-- * Retrocompatível: GetPlayerData envia lista simples ao client
-- ============================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- DataStore (MESMO nome para manter dados existentes)
local DATASTORE_NAME = "RetroVerseDataV3_Awakening"
local DATA_VERSION = "V4_Metadata"
local playerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- Cache
local playerDataCache = {}
local isSaving = {}

-- =====================================
-- REMOTES
-- =====================================

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local updateStatsRemote = remotes:FindFirstChild("UpdateStats")
if not updateStatsRemote then
	updateStatsRemote = Instance.new("RemoteEvent")
	updateStatsRemote.Name = "UpdateStats"
	updateStatsRemote.Parent = remotes
end

-- =====================================
-- CONFIGURAÇÃO DE SOURCES
-- =====================================

local SOURCE_PERMISSIONS = {
	Mandatory = { tradeable = false, sellable = false },
	Shop = { tradeable = true, sellable = true },
	Reward = { tradeable = true, sellable = false },
	Gamepass = { tradeable = false, sellable = false },
	Badge = { tradeable = false, sellable = false },
	Trade = { tradeable = true, sellable = true },
	Awakened = { tradeable = false, sellable = false },
}

-- Tabelas de classificação para migração V3 → V4
local MIGRATION_CONFIG = {
	mandatoryCharacters = { "Noob" },
	characterPrices = {
		Noob = 0,
		Guest = 50,
		Danilo = 200,
		["Gui Bomba"] = 300,
		["Dark Jc"] = 500,
		Shushuhus8 = 250,
	},
	bountyCharacters = {
		-- Adicione personagens de bounty aqui (veja GUIA_ADICIONAR_PERSONAGENS.md)
		-- Exemplo: Maria = 2500,
	},
	gamepassCharacters = {
		["Faker Gui"] = 1247245466,
		["Alma Perdida"] = 1161544217,
	},
	badgeCharacters = {
		-- ["Miner Pedro"] = 123456,
	},
}

-- =====================================
-- ESTRUTURA PADRÃO V4
-- =====================================

local function createDefaultCharacter(name, source, price)
	local perms = SOURCE_PERMISSIONS[source] or { tradeable = false, sellable = false }
	return {
		id = HttpService:GenerateGUID(false),
		name = name,
		source = source,
		acquiredAt = os.time(),
		originalPrice = price or 0,
		tradeable = perms.tradeable,
		sellable = perms.sellable,
	}
end

local function getDefaultData()
	return {
		coins = 0,
		ownedCharacters = {
			createDefaultCharacter("Noob", "Mandatory", 0),
		},
		equippedCharacter = nil,
		awakenedCharacters = {},
		stats = {
			bounty = 0,
			deaths = 0,
			kills = 0,
			kills_total = 0,
			coins_earned_total = 0,
			trades_completed = 0,
			characters_bought = 0,
			characters_sold = 0,
		},
		tradeHistory = {},
		claimedMissions = {},
		version = DATA_VERSION,
	}
end

-- =====================================
-- FUNÇÕES UTILITÁRIAS
-- =====================================

local function deepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = deepCopy(value)
	end
	return copy
end

local function isOldFormat(ownedCharacters)
	if not ownedCharacters or #ownedCharacters == 0 then
		return true
	end
	return type(ownedCharacters[1]) == "string"
end

-- =====================================
-- MIGRAÇÃO V3 → V4
-- =====================================

local function migrateCharacterList(oldList)
	local newList = {}
	local cfg = MIGRATION_CONFIG

	for _, name in ipairs(oldList) do
		if type(name) ~= "string" then
			continue
		end

		local source = "Shop"
		local price = 0

		-- Classificar por source
		if table.find(cfg.mandatoryCharacters, name) then
			source = "Mandatory"
			price = 0
		elseif cfg.bountyCharacters[name] then
			source = "Reward"
			price = 0
		elseif cfg.gamepassCharacters[name] then
			source = "Gamepass"
			price = 0
		elseif cfg.badgeCharacters[name] then
			source = "Badge"
			price = 0
		else
			price = cfg.characterPrices[name] or 0
		end

		table.insert(newList, createDefaultCharacter(name, source, price))
	end

	return newList
end

-- =====================================
-- VALIDAÇÃO DE DADOS
-- =====================================

local function validateData(data)
	if not data then
		return getDefaultData()
	end

	local validated = getDefaultData()

	-- Migrar coins
	validated.coins = type(data.coins) == "number" and math.max(0, data.coins) or 0

	-- Migrar ownedCharacters (V3 strings → V4 objetos)
	if data.ownedCharacters then
		if isOldFormat(data.ownedCharacters) then
			print("[DATA V4] Migrando ownedCharacters de V3 (strings) para V4 (objetos)...")
			validated.ownedCharacters = migrateCharacterList(data.ownedCharacters)
			print(
				"[DATA V4] Migração concluída: " .. #validated.ownedCharacters .. " personagens"
			)
		else
			-- Já está no formato V4, validar cada entrada
			validated.ownedCharacters = {}
			for _, charObj in ipairs(data.ownedCharacters) do
				if type(charObj) == "table" and type(charObj.name) == "string" then
					-- Garantir campos obrigatórios
					local perms = SOURCE_PERMISSIONS[charObj.source]
						or { tradeable = false, sellable = false }
					table.insert(validated.ownedCharacters, {
						id = charObj.id or HttpService:GenerateGUID(false),
						name = charObj.name,
						source = charObj.source or "Shop",
						acquiredAt = charObj.acquiredAt or os.time(),
						originalPrice = charObj.originalPrice or 0,
						tradeable = perms.tradeable,
						sellable = perms.sellable,
					})
				end
			end
		end
	end

	-- Garantir Noob existe
	local hasNoob = false
	for _, charObj in ipairs(validated.ownedCharacters) do
		if charObj.name == "Noob" then
			hasNoob = true
			charObj.source = "Mandatory"
			charObj.tradeable = false
			charObj.sellable = false
			break
		end
	end
	if not hasNoob then
		table.insert(validated.ownedCharacters, 1, createDefaultCharacter("Noob", "Mandatory", 0))
	end

	-- Migrar equippedCharacter
	validated.equippedCharacter = data.equippedCharacter

	-- Migrar awakenedCharacters
	if type(data.awakenedCharacters) == "table" then
		validated.awakenedCharacters = deepCopy(data.awakenedCharacters)
	end

	-- Migrar stats (merge com defaults)
	if type(data.stats) == "table" then
		for key, value in pairs(data.stats) do
			if key ~= "playtime" and type(value) == "number" then
				validated.stats[key] = value
			end
		end
		-- Migrar kills_total se não existir
		if not data.stats.kills_total and data.stats.kills then
			validated.stats.kills_total = data.stats.kills
		end
	end

	-- Migrar tradeHistory
	if type(data.tradeHistory) == "table" then
		validated.tradeHistory = data.tradeHistory
	end

	-- Preservar missões já resgatadas (corrige "não salva as missões realizadas")
	if type(data.claimedMissions) == "table" then
		validated.claimedMissions = data.claimedMissions
	end

	-- Marcar versão
	validated.version = DATA_VERSION

	return validated
end

-- =====================================
-- SYNC COM CLIENT (RETROCOMPATÍVEL)
-- =====================================

local function getClientSafeData(data)
	if not data then
		return nil
	end

	-- Lista simples de nomes para clients antigos
	local simpleNames = {}
	for _, charObj in ipairs(data.ownedCharacters) do
		table.insert(simpleNames, charObj.name)
	end

	return {
		coins = data.coins,
		ownedCharacters = simpleNames,
		ownedCharactersDetailed = data.ownedCharacters,
		equippedCharacter = data.equippedCharacter,
		awakenedCharacters = data.awakenedCharacters,
		stats = data.stats,
		tradeHistory = data.tradeHistory,
		claimedMissions = data.claimedMissions or {},
		version = data.version,
	}
end

local function syncDataWithClient(player)
	local data = playerDataCache[player]
	if data then
		updateStatsRemote:FireClient(player, getClientSafeData(data))
	end
end

-- =====================================
-- CARREGAR DADOS
-- =====================================

local function loadPlayerData(player)
	local userId = tostring(player.UserId)
	local attempts = 0
	local maxAttempts = 3

	while attempts < maxAttempts do
		attempts = attempts + 1

		local success, result = pcall(function()
			return playerDataStore:GetAsync(userId)
		end)

		if success then
			local data = validateData(result)
			playerDataCache[player] = data

			-- Se migrou de V3, salvar imediatamente
			if result and isOldFormat(result.ownedCharacters) then
				print("[DATA V4] Salvando dados migrados de " .. player.Name)
				task.spawn(function()
					local ok, err = pcall(function()
						playerDataStore:SetAsync(userId, data)
					end)
					if ok then
						print("[DATA V4] Dados migrados salvos: " .. player.Name)
					else
						warn("[DATA V4] Erro ao salvar migração: " .. tostring(err))
					end
				end)
			end

			print(
				"[DATA V4] Dados carregados: "
					.. player.Name
					.. " ("
					.. #data.ownedCharacters
					.. " personagens)"
			)
			return data
		else
			warn(
				"[DATA V4] Erro ao carregar dados de "
					.. player.Name
					.. " (tentativa "
					.. attempts
					.. "): "
					.. tostring(result)
			)
			if attempts < maxAttempts then
				task.wait(2)
			end
		end
	end

	playerDataCache[player] = getDefaultData()
	warn("[DATA V4] Usando dados padrão para " .. player.Name)
	return playerDataCache[player]
end

-- =====================================
-- SALVAR DADOS
-- =====================================

local function savePlayerData(player, isLeaving)
	if isSaving[player] then
		if not isLeaving then
			return
		end
		local timeout = 0
		while isSaving[player] and timeout < 5 do
			task.wait(0.1)
			timeout = timeout + 0.1
		end
	end

	isSaving[player] = true

	local userId = tostring(player.UserId)
	local data = playerDataCache[player]

	if not data then
		isSaving[player] = false
		return false
	end

	-- Limpar ao salvar
	data.equippedCharacter = nil
	if data.stats then
		data.stats.playtime = nil
	end

	local attempts = 0
	local maxAttempts = isLeaving and 5 or 3

	while attempts < maxAttempts do
		attempts = attempts + 1

		local success, err = pcall(function()
			playerDataStore:SetAsync(userId, data)
		end)

		if success then
			print("[DATA V4] Dados salvos: " .. player.Name)
			isSaving[player] = false
			return true
		else
			warn(
				"[DATA V4] Erro ao salvar "
					.. player.Name
					.. " (tentativa "
					.. attempts
					.. "): "
					.. tostring(err)
			)
			if attempts < maxAttempts then
				task.wait(1)
			end
		end
	end

	isSaving[player] = false
	return false
end

-- =====================================
-- FUNÇÕES DE BUSCA DE PERSONAGENS
-- =====================================

local function findCharacterByName(playerData, characterName)
	if not playerData or not playerData.ownedCharacters then
		return nil, nil
	end
	for i, charObj in ipairs(playerData.ownedCharacters) do
		if charObj.name == characterName then
			return charObj, i
		end
	end
	return nil, nil
end

local function findCharacterById(playerData, charId)
	if not playerData or not playerData.ownedCharacters then
		return nil, nil
	end
	for i, charObj in ipairs(playerData.ownedCharacters) do
		if charObj.id == charId then
			return charObj, i
		end
	end
	return nil, nil
end

local function playerOwnsCharacterByName(playerData, characterName)
	local charObj = findCharacterByName(playerData, characterName)
	return charObj ~= nil
end

local function getTradeableCharacters(playerData)
	local result = {}
	if not playerData or not playerData.ownedCharacters then
		return result
	end
	for _, charObj in ipairs(playerData.ownedCharacters) do
		if charObj.tradeable then
			table.insert(result, charObj)
		end
	end
	return result
end

local function getSellableCharacters(playerData)
	local result = {}
	if not playerData or not playerData.ownedCharacters then
		return result
	end
	for _, charObj in ipairs(playerData.ownedCharacters) do
		if charObj.sellable and charObj.originalPrice > 0 then
			table.insert(result, charObj)
		end
	end
	return result
end

-- =====================================
-- EVENTOS DE JOGADOR
-- =====================================

local function onPlayerAdded(player)
	local playerData = loadPlayerData(player)

	-- Criar leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = playerData.coins
	coins.Parent = leaderstats

	local bounty = Instance.new("IntValue")
	bounty.Name = "Bounty"
	bounty.Value = playerData.stats.bounty or 0
	bounty.Parent = leaderstats

	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = playerData.stats.deaths or 0
	deaths.Parent = leaderstats

	task.wait(1)
	syncDataWithClient(player)
end

local function onPlayerRemoving(player)
	savePlayerData(player, true)
	playerDataCache[player] = nil
	isSaving[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- =====================================
-- AUTO-SAVE
-- =====================================

task.spawn(function()
	while true do
		task.wait(30)
		local players = Players:GetPlayers()
		for _, player in ipairs(players) do
			task.spawn(function()
				savePlayerData(player, false)
			end)
		end
		if #players > 0 then
			print("[DATA V4] Auto-save: " .. #players .. " jogadores")
		end
	end
end)

-- =====================================
-- BIND TO CLOSE
-- =====================================

game:BindToClose(function()
	print("[DATA V4] Servidor fechando, salvando todos os dados...")
	local players = Players:GetPlayers()

	for _, player in ipairs(players) do
		task.spawn(function()
			savePlayerData(player, true)
		end)
	end

	local timeout = 0
	while timeout < 30 do
		local allDone = true
		for _, player in ipairs(players) do
			if isSaving[player] then
				allDone = false
				break
			end
		end
		if allDone then
			break
		end
		task.wait(0.1)
		timeout = timeout + 0.1
	end

	print("[DATA V4] Shutdown save completo")
end)

-- =====================================
-- API PÚBLICA
-- =====================================

_G.PlayerDataManager = {
	-- Dados brutos
	getPlayerData = function(player)
		return playerDataCache[player]
	end,

	-- Dados formatados para client (retrocompatível)
	getClientData = function(player)
		return getClientSafeData(playerDataCache[player])
	end,

	-- Salvar
	savePlayerData = function(player)
		task.spawn(function()
			savePlayerData(player, false)
			syncDataWithClient(player)
		end)
	end,

	-- Sync com client
	syncWithClient = function(player)
		syncDataWithClient(player)
	end,

	-- ========== MOEDAS ==========

	updateCoins = function(player, amount)
		local data = playerDataCache[player]
		if not data then
			return
		end

		data.coins = math.max(0, data.coins + amount)

		-- Rastrear moedas ganhas (apenas positivo)
		if amount > 0 then
			data.stats.coins_earned_total = (data.stats.coins_earned_total or 0) + amount
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local c = leaderstats:FindFirstChild("Coins")
			if c then
				c.Value = data.coins
			end
		end

		syncDataWithClient(player)
	end,

	-- ========== BOUNTY ==========

	updateBounty = function(player, amount)
		local data = playerDataCache[player]
		if not data then
			return
		end

		data.stats.bounty = math.max(0, (data.stats.bounty or 0) + amount)

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local b = leaderstats:FindFirstChild("Bounty")
			if b then
				b.Value = data.stats.bounty
			end
		end

		syncDataWithClient(player)
	end,

	-- ========== STATS ==========

	incrementStat = function(player, statName, amount)
		local data = playerDataCache[player]
		if not data or not data.stats then
			return
		end
		if statName == "playtime" then
			return
		end

		data.stats[statName] = (data.stats[statName] or 0) + amount

		-- Manter totais acumulativos
		if statName == "kills" then
			data.stats.kills_total = (data.stats.kills_total or 0) + amount
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local capitalized = statName:gsub("^%l", string.upper)
			local stat = leaderstats:FindFirstChild(capitalized)
			if stat then
				stat.Value = data.stats[statName]
			end
		end

		syncDataWithClient(player)
	end,

	-- ========== PERSONAGENS (NOVO V4) ==========

	-- Adicionar personagem com metadados
	addCharacter = function(player, characterName, source, originalPrice)
		local data = playerDataCache[player]
		if not data then
			return false
		end

		-- Verificar duplicata
		if playerOwnsCharacterByName(data, characterName) then
			return false
		end

		local charObj = createDefaultCharacter(characterName, source or "Shop", originalPrice or 0)
		table.insert(data.ownedCharacters, charObj)

		-- Rastrear compra
		if source == "Shop" then
			data.stats.characters_bought = (data.stats.characters_bought or 0) + 1
		end

		syncDataWithClient(player)
		return true, charObj.id
	end,

	-- Retrocompatível: wrapper para código antigo
	addCharacterToInventory = function(player, characterName)
		local data = playerDataCache[player]
		if not data then
			return false
		end

		if playerOwnsCharacterByName(data, characterName) then
			return false
		end

		-- Tentar determinar source pelo nome
		local source = "Shop"
		local price = 0
		local cfg = MIGRATION_CONFIG

		if table.find(cfg.mandatoryCharacters, characterName) then
			source = "Mandatory"
		elseif cfg.bountyCharacters[characterName] then
			source = "Reward"
		elseif cfg.gamepassCharacters[characterName] then
			source = "Gamepass"
		elseif cfg.badgeCharacters[characterName] then
			source = "Badge"
		else
			price = cfg.characterPrices[characterName] or 0
		end

		local charObj = createDefaultCharacter(characterName, source, price)
		table.insert(data.ownedCharacters, charObj)
		syncDataWithClient(player)
		return true
	end,

	-- Remover personagem por ID (para venda/troca)
	removeCharacterById = function(player, charId)
		local data = playerDataCache[player]
		if not data then
			return false
		end

		local charObj, index = findCharacterById(data, charId)
		if not charObj then
			return false
		end

		table.remove(data.ownedCharacters, index)
		syncDataWithClient(player)
		return true, charObj
	end,

	-- Remover personagem por nome (para código legado)
	removeCharacterByName = function(player, characterName)
		local data = playerDataCache[player]
		if not data then
			return false
		end

		-- Não permitir remover Noob
		if characterName == "Noob" then
			return false
		end

		local charObj, index = findCharacterByName(data, characterName)
		if not charObj then
			return false
		end

		table.remove(data.ownedCharacters, index)
		syncDataWithClient(player)
		return true, charObj
	end,

	-- ========== CONSULTAS ==========

	ownsCharacter = function(player, characterName)
		local data = playerDataCache[player]
		if not data then
			return false
		end
		return playerOwnsCharacterByName(data, characterName)
	end,

	getCharacterByName = function(player, characterName)
		local data = playerDataCache[player]
		if not data then
			return nil
		end
		return findCharacterByName(data, characterName)
	end,

	getCharacterById = function(player, charId)
		local data = playerDataCache[player]
		if not data then
			return nil
		end
		return findCharacterById(data, charId)
	end,

	getTradeableCharacters = function(player)
		local data = playerDataCache[player]
		if not data then
			return {}
		end
		return getTradeableCharacters(data)
	end,

	getSellableCharacters = function(player)
		local data = playerDataCache[player]
		if not data then
			return {}
		end
		return getSellableCharacters(data)
	end,

	-- ========== DESPERTAR (mantido) ==========

	addAwakenedCharacter = function(player, originalName)
		local data = playerDataCache[player]
		if not data then
			return false
		end
		if not data.awakenedCharacters then
			data.awakenedCharacters = {}
		end
		if table.find(data.awakenedCharacters, originalName) then
			return false
		end
		table.insert(data.awakenedCharacters, originalName)
		syncDataWithClient(player)
		return true
	end,

	hasAwakening = function(player, originalName)
		local data = playerDataCache[player]
		if data and data.awakenedCharacters then
			return table.find(data.awakenedCharacters, originalName) ~= nil
		end
		return false
	end,

	-- ========== TROCAS (preparado) ==========

	addTradeToHistory = function(player, tradeId)
		local data = playerDataCache[player]
		if not data then
			return
		end
		if not data.tradeHistory then
			data.tradeHistory = {}
		end
		table.insert(data.tradeHistory, 1, tradeId)
		-- Manter apenas últimos 50
		while #data.tradeHistory > 50 do
			table.remove(data.tradeHistory)
		end
		data.stats.trades_completed = (data.stats.trades_completed or 0) + 1
	end,

	-- ========== RESET ==========

	resetPlayerData = function(player)
		local data = getDefaultData()
		playerDataCache[player] = data

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local c = leaderstats:FindFirstChild("Coins")
			if c then
				c.Value = 0
			end
			local b = leaderstats:FindFirstChild("Bounty")
			if b then
				b.Value = 0
			end
			local d = leaderstats:FindFirstChild("Deaths")
			if d then
				d.Value = 0
			end
		end

		syncDataWithClient(player)
		savePlayerData(player, false)
	end,

	-- ========== CONFIGURAÇÃO ==========

	SOURCE_PERMISSIONS = SOURCE_PERMISSIONS,
	MIGRATION_CONFIG = MIGRATION_CONFIG,
	createDefaultCharacter = createDefaultCharacter,
}

print([[
╔══════════════════════════════════════════════════════╗
║  DATA MANAGER SERVER V4 — CARREGADO                 ║
╠══════════════════════════════════════════════════════╣
║  SUBSTITUI: DataManager_Server_Script_V3            ║
║  REMOVER:   DataManager_Server_Script_V3            ║
╠══════════════════════════════════════════════════════╣
║  NOVIDADES V4:                                       ║
║  * Personagens como objetos com metadados            ║
║  * Source: Mandatory/Shop/Reward/Gamepass/Badge/etc   ║
║  * Migração automática V3 → V4                       ║
║  * API expandida: addCharacter, removeCharacterById  ║
║  * getTradeableCharacters, getSellableCharacters     ║
║  * Retrocompatível com clients antigos               ║
║  * Preparado para trocas e missões                   ║
╚══════════════════════════════════════════════════════╝
]])
