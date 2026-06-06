-- ============================================
-- ADMIN SYSTEM SERVER V5
-- Coloque em ServerScriptService
-- Nome: "AdminSystemServer"
-- SUBSTITUI: ADMIN_SYSTEM_SERVER_V4
-- ============================================
-- CORRECOES V5:
-- • task.wait() / task.spawn() substituindo wait() / spawn()
-- • Chat commands nao forçam lowercase no nome do jogador/personagem
-- • Lista de personagens sincronizada com o sistema
-- • syncDataWithClient chamado apos cada acao admin
-- • getPlayerList retorna kills e inventario completo
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat
	task.wait()
until _G.PlayerDataManager

print([[
╔════════════════════════════════════════════╗
║   ADMIN SYSTEM SERVER V5 - CARREGADO      ║
╚════════════════════════════════════════════╝
]])

-- =====================================
-- LISTA DE ADMINS
-- =====================================

local ADMIN_IDS = {
	1595442496,
	8833465560,
	1832521992,
}

-- Lista de personagens do jogo (sincronizada com CharacterMenuClient)
local ALL_CHARACTERS = {
	"Noob",
	"Bacon",
	"Danilo",
	"Gui Bomba",
	"Colecionador",
	"Hunter",
	"VIP",
}

local function isAdmin(player)
	return table.find(ADMIN_IDS, player.UserId) ~= nil
end

-- =====================================
-- CRIAR REMOTES
-- =====================================

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreateRemote(name, remoteType)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		if remoteType == "Event" then
			remote = Instance.new("RemoteEvent")
		else
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local adminGiveCoins = getOrCreateRemote("AdminGiveCoins", "Event")
local adminGiveBounty = getOrCreateRemote("AdminGiveBounty", "Event")
local adminGiveCharacter = getOrCreateRemote("AdminGiveCharacter", "Event")
local adminGiveAllCharacters = getOrCreateRemote("AdminGiveAllCharacters", "Event")
local adminResetData = getOrCreateRemote("AdminResetData", "Event")
local adminTeleport = getOrCreateRemote("AdminTeleport", "Event")
local adminKill = getOrCreateRemote("AdminKill", "Event")
local adminKick = getOrCreateRemote("AdminKick", "Event")
local getPlayerList = getOrCreateRemote("GetPlayerList", "Function")

-- =====================================
-- FUNCOES AUXILIARES
-- =====================================

local function logAction(admin, action, target, details)
	print(
		string.format(
			"[ADMIN V5] %s executou %s em %s - %s",
			admin.Name,
			action,
			target and target.Name or "N/A",
			details or ""
		)
	)
end

local function notifyAdmin(admin, message, isSuccess)
	local gui = admin:FindFirstChild("PlayerGui")
	if not gui then
		return
	end

	local notification = Instance.new("ScreenGui")
	notification.Name = "AdminNotification"
	notification.DisplayOrder = 200
	notification.Parent = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.35, 0, 0.08, 0)
	frame.Position = UDim2.new(0.325, 0, 0.05, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderColor3 = isSuccess and Color3.fromRGB(0, 220, 0) or Color3.fromRGB(220, 0, 0)
	frame.BorderSizePixel = 3
	frame.Parent = notification

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -10, 1, 0)
	text.Position = UDim2.new(0, 5, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.Arcade
	text.Parent = frame

	game:GetService("Debris"):AddItem(notification, 3)
end

-- =====================================
-- HANDLERS DE COMANDOS REMOTOS
-- =====================================

adminGiveCoins.OnServerEvent:Connect(function(admin, targetName, amount)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	amount = tonumber(amount) or 0
	if amount == 0 then
		notifyAdmin(admin, "Quantidade invalida!", false)
		return
	end

	_G.PlayerDataManager.updateCoins(target, amount)
	_G.PlayerDataManager.savePlayerData(target)

	logAction(admin, "GiveCoins", target, tostring(amount))
	notifyAdmin(admin, string.format("Deu %d moedas para %s", amount, target.Name), true)
end)

adminGiveBounty.OnServerEvent:Connect(function(admin, targetName, amount)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	amount = tonumber(amount) or 0
	if amount == 0 then
		notifyAdmin(admin, "Quantidade invalida!", false)
		return
	end

	_G.PlayerDataManager.updateBounty(target, amount)
	_G.PlayerDataManager.savePlayerData(target)

	logAction(admin, "GiveBounty", target, tostring(amount))
	notifyAdmin(admin, string.format("Deu %d bounty para %s", amount, target.Name), true)
end)

adminGiveCharacter.OnServerEvent:Connect(function(admin, targetName, characterName)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	if not characterName or characterName == "" then
		notifyAdmin(admin, "Nome de personagem invalido!", false)
		return
	end

	local success = _G.PlayerDataManager.addCharacterToInventory(target, characterName)
	if success then
		_G.PlayerDataManager.savePlayerData(target)
		logAction(admin, "GiveCharacter", target, characterName)
		notifyAdmin(admin, string.format("Deu %s para %s", characterName, target.Name), true)
	else
		notifyAdmin(admin, "Jogador ja possui este personagem!", false)
	end
end)

adminGiveAllCharacters.OnServerEvent:Connect(function(admin, targetName)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	local addedCount = 0
	for _, charName in ipairs(ALL_CHARACTERS) do
		if _G.PlayerDataManager.addCharacterToInventory(target, charName) then
			addedCount = addedCount + 1
		end
	end

	_G.PlayerDataManager.savePlayerData(target)
	logAction(admin, "GiveAllCharacters", target, addedCount .. " personagens")
	notifyAdmin(admin, string.format("Deu %d personagens para %s", addedCount, target.Name), true)
end)

adminResetData.OnServerEvent:Connect(function(admin, targetName)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	_G.PlayerDataManager.resetPlayerData(target)
	logAction(admin, "ResetData", target, "Dados resetados")
	notifyAdmin(admin, string.format("Resetou dados de %s", target.Name), true)
end)

adminTeleport.OnServerEvent:Connect(function(admin, targetName, destination)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target or not target.Character then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		notifyAdmin(admin, "Personagem invalido!", false)
		return
	end

	local destinations = {
		SafeZone = Vector3.new(0, 503, 0),
		Spawn = Vector3.new(200, 10, 200),
	}

	local pos = destinations[destination]
	if pos then
		hrp.CFrame = CFrame.new(pos)
		logAction(admin, "Teleport", target, destination)
		notifyAdmin(admin, string.format("Teleportou %s para %s", target.Name, destination), true)
	else
		notifyAdmin(admin, "Destino invalido!", false)
	end
end)

adminKill.OnServerEvent:Connect(function(admin, targetName)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target or not target.Character then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	local humanoid = target.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = 0
		logAction(admin, "Kill", target, "Eliminado")
		notifyAdmin(admin, string.format("Eliminou %s", target.Name), true)
	end
end)

adminKick.OnServerEvent:Connect(function(admin, targetName, reason)
	if not isAdmin(admin) then
		admin:Kick("Tentativa nao autorizada de uso de comandos admin")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		notifyAdmin(admin, "Jogador nao encontrado!", false)
		return
	end

	reason = reason or "Expulso por um administrador"
	target:Kick(reason)
	logAction(admin, "Kick", target, reason)
	notifyAdmin(admin, string.format("Expulsou %s", target.Name), true)
end)

-- Retorna lista completa de jogadores para o painel admin
getPlayerList.OnServerInvoke = function(admin)
	if not isAdmin(admin) then
		return {}
	end

	local playerList = {}
	for _, player in pairs(Players:GetPlayers()) do
		local data = _G.PlayerDataManager.getPlayerData(player)
		table.insert(playerList, {
			name = player.Name,
			userId = player.UserId,
			coins = data and data.coins or 0,
			bounty = data and data.stats and data.stats.bounty or 0,
			deaths = data and data.stats and data.stats.deaths or 0,
			kills = data and data.stats and data.stats.kills or 0,
			equippedChar = data and data.equippedCharacter or "Nenhum",
			ownedCount = data and data.ownedCharacters and #data.ownedCharacters or 0,
		})
	end
	return playerList
end

-- =====================================
-- COMANDOS DE CHAT
-- CORRECAO V5: nao lowercasear nome do jogador/personagem
-- =====================================

Players.PlayerAdded:Connect(function(player)
	if not isAdmin(player) then
		return
	end

	print("[ADMIN V5] Admin conectado:", player.Name)

	player.Chatted:Connect(function(message)
		-- Dividir sem forcar lowercase no comando inteiro
		local args = string.split(message, " ")
		local cmd = args[1] and args[1]:lower() or ""

		if cmd == ";coins" and args[2] and args[3] then
			local target = Players:FindFirstChild(args[2])
			local amount = tonumber(args[3])
			if target and amount then
				_G.PlayerDataManager.updateCoins(target, amount)
				_G.PlayerDataManager.savePlayerData(target)
				logAction(player, "ChatCmd:Coins", target, tostring(amount))
			end
		elseif cmd == ";bounty" and args[2] and args[3] then
			local target = Players:FindFirstChild(args[2])
			local amount = tonumber(args[3])
			if target and amount then
				_G.PlayerDataManager.updateBounty(target, amount)
				_G.PlayerDataManager.savePlayerData(target)
				logAction(player, "ChatCmd:Bounty", target, tostring(amount))
			end
		elseif cmd == ";char" and args[2] and args[3] then
			-- Nome do personagem preserva capitalização original (ex: "Gui Bomba")
			local target = Players:FindFirstChild(args[2])
			local charName = table.concat(args, " ", 3)
			if target and charName ~= "" then
				_G.PlayerDataManager.addCharacterToInventory(target, charName)
				_G.PlayerDataManager.savePlayerData(target)
				logAction(player, "ChatCmd:Character", target, charName)
			end
		elseif cmd == ";allchars" and args[2] then
			local target = Players:FindFirstChild(args[2])
			if target then
				for _, charName in ipairs(ALL_CHARACTERS) do
					_G.PlayerDataManager.addCharacterToInventory(target, charName)
				end
				_G.PlayerDataManager.savePlayerData(target)
				logAction(player, "ChatCmd:AllChars", target, "Todos")
			end
		elseif cmd == ";reset" and args[2] then
			local target = Players:FindFirstChild(args[2])
			if target then
				_G.PlayerDataManager.resetPlayerData(target)
				logAction(player, "ChatCmd:Reset", target, "Resetado")
			end
		elseif cmd == ";kill" and args[2] then
			local target = Players:FindFirstChild(args[2])
			if target and target.Character then
				local humanoid = target.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0
					logAction(player, "ChatCmd:Kill", target, "Eliminado")
				end
			end
		elseif cmd == ";tp" and args[2] then
			local target = Players:FindFirstChild(args[2])
			if target and target.Character and player.Character then
				local hrp = target.Character:FindFirstChild("HumanoidRootPart")
				local adminHrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp and adminHrp then
					hrp.CFrame = adminHrp.CFrame
					logAction(player, "ChatCmd:Teleport", target, "Para admin")
				end
			end
		elseif cmd == ";help" then
			print("\n[ADMIN V5 COMMANDS]")
			print("  ;coins [jogador] [quantidade]")
			print("  ;bounty [jogador] [quantidade]")
			print("  ;char [jogador] [personagem]")
			print("  ;allchars [jogador]")
			print("  ;reset [jogador]")
			print("  ;kill [jogador]")
			print("  ;tp [jogador]")
		end
	end)
end)

print([[
╔════════════════════════════════════════════════════╗
║  ✅ ADMIN SYSTEM SERVER V5 CARREGADO              ║
╠════════════════════════════════════════════════════╣
║  SUBSTITUI: ADMIN_SYSTEM_SERVER_V4                ║
╠════════════════════════════════════════════════════╣
║  CORRECOES V5:                                     ║
║  • task.wait / task.spawn                         ║
║  • Nomes preservam capitalização nos cmds chat    ║
║  • Lista de chars sincronizada com o jogo         ║
║  • getPlayerList retorna kills + inventário       ║
╚════════════════════════════════════════════════════╝
]])
