-- ============================================
-- SISTEMA PRINCIPAL DE INICIALIZAÇÃO E CONEXÃO
-- Coloque em ServerScriptService
-- Nome: "MainSystemInitializer"
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print([[
╔════════════════════════════════════════════╗
║     INICIALIZANDO SISTEMA PRINCIPAL       ║
╚════════════════════════════════════════════╝
]])

-- =====================================
-- CRIAR ESTRUTURA DE PASTAS
-- =====================================

local function createFolderStructure()
	print("[INIT] Criando estrutura de pastas...")

	local folders = {
		-- ReplicatedStorage
		{ parent = ReplicatedStorage, name = "Remotes" },
		{ parent = ReplicatedStorage, name = "Events" },
		{ parent = ReplicatedStorage, name = "Characters" },
		{ parent = ReplicatedStorage, name = "Assets" },
		{ parent = ReplicatedStorage, name = "Modules" },

		-- ServerStorage
		{ parent = ServerStorage, name = "ServerAssets" },
		{ parent = ServerStorage, name = "ServerModules" },
		{ parent = ServerStorage, name = "PlayerData" },
		{ parent = ServerStorage, name = "TeamData" },
	}

	for _, folderInfo in ipairs(folders) do
		local folder = folderInfo.parent:FindFirstChild(folderInfo.name)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = folderInfo.name
			folder.Parent = folderInfo.parent
			print("  ✓ Pasta criada: " .. folderInfo.name)
		end
	end

	return true
end

-- =====================================
-- CRIAR TODOS OS REMOTES
-- =====================================

local function createAllRemotes()
	print("[INIT] Criando RemoteEvents e RemoteFunctions...")

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local events = ReplicatedStorage:WaitForChild("Events")

	local remoteList = {
		-- RemoteFunctions (para requisições com resposta)
		{ type = "RemoteFunction", name = "SelectCharacter", parent = remotes },
		{ type = "RemoteFunction", name = "GetPlayerData", parent = remotes },
		{ type = "RemoteFunction", name = "CreateTeam", parent = remotes },
		{ type = "RemoteFunction", name = "ClaimDailyReward", parent = remotes },
		{ type = "RemoteFunction", name = "GetDailyRewardStatus", parent = remotes },
		{ type = "RemoteFunction", name = "CheckBadge", parent = remotes },

		-- RemoteEvents (para comunicação unidirecional)
		{ type = "RemoteEvent", name = "PurchaseCharacter", parent = remotes },
		{ type = "RemoteEvent", name = "UpdateStats", parent = remotes },
		{ type = "RemoteEvent", name = "SyncCharacterState", parent = remotes },
		{ type = "RemoteEvent", name = "SpectatorMode", parent = remotes },
		{ type = "RemoteEvent", name = "ToggleSpectator", parent = remotes },
		{ type = "RemoteEvent", name = "UpdateCharacterState", parent = remotes },
		{ type = "RemoteEvent", name = "InviteToTeam", parent = remotes },
		{ type = "RemoteEvent", name = "RespondToInvite", parent = remotes },
		{ type = "RemoteEvent", name = "LeaveTeam", parent = remotes },
		{ type = "RemoteEvent", name = "UpdateTeamList", parent = remotes },
		{ type = "RemoteEvent", name = "TutorialComplete", parent = remotes },
		{ type = "RemoteEvent", name = "ForceSpawn", parent = remotes },
		{ type = "RemoteEvent", name = "RedeemGamepassCharacter", parent = remotes },

		-- Events (para eventos do jogo)
		{ type = "RemoteEvent", name = "PlayerKilled", parent = events },
		{ type = "RemoteEvent", name = "ShowNotification", parent = events },
		{ type = "RemoteEvent", name = "GameStateChanged", parent = events },

		-- Admin Remotes
		{ type = "RemoteEvent", name = "AdminGiveCoins", parent = remotes },
		{ type = "RemoteEvent", name = "AdminGiveBounty", parent = remotes },
		{ type = "RemoteEvent", name = "AdminGiveCharacter", parent = remotes },
		{ type = "RemoteEvent", name = "AdminGiveAllCharacters", parent = remotes },
		{ type = "RemoteEvent", name = "AdminResetData", parent = remotes },
		{ type = "RemoteEvent", name = "AdminTeleport", parent = remotes },
	}

	local createdCount = 0
	for _, remoteInfo in ipairs(remoteList) do
		local remote = remoteInfo.parent:FindFirstChild(remoteInfo.name)
		if not remote then
			if remoteInfo.type == "RemoteFunction" then
				remote = Instance.new("RemoteFunction")
			else
				remote = Instance.new("RemoteEvent")
			end
			remote.Name = remoteInfo.name
			remote.Parent = remoteInfo.parent
			createdCount = createdCount + 1
			print("  ✓ Remote criado: " .. remoteInfo.name)
		end
	end

	print("  Total de remotes criados: " .. createdCount)
	return true
end

-- =====================================
-- VERIFICAR SISTEMAS CARREGADOS
-- =====================================

local function waitForSystems()
	print("[INIT] Aguardando sistemas carregarem...")

	local systems = {
		{ name = "PlayerDataManager", global = "_G.PlayerDataManager" },
		{ name = "SetSpectatorMode", global = "_G.SetSpectatorMode", optional = true },
		{ name = "OnCharacterSelected", global = "_G.OnCharacterSelected", optional = true },
		{ name = "GetPlayerTeam", global = "_G.GetPlayerTeam", optional = true },
		{ name = "RegisterAttack", global = "_G.RegisterAttack", optional = true },
	}

	for _, system in ipairs(systems) do
		local startTime = tick()
		local timeout = system.optional and 5 or 30

		while not _G[system.name:gsub("_G.", "")] do
			wait(0.1)
			if tick() - startTime > timeout then
				if system.optional then
					print("  ⚠️ Sistema opcional não encontrado: " .. system.name)
					break
				else
					warn("  ❌ ERRO: Sistema obrigatório não carregou: " .. system.name)
					return false
				end
			end
		end

		if _G[system.name:gsub("_G.", "")] then
			print("  ✓ Sistema carregado: " .. system.name)
		end
	end

	return true
end

-- =====================================
-- CONECTAR SISTEMAS
-- =====================================

local function connectSystems()
	print("[INIT] Conectando sistemas...")

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local selectCharacterRemote = remotes:WaitForChild("SelectCharacter")

	-- Conectar seleção de personagem com zona segura
	if _G.SelectCharacterFunction and _G.OnCharacterSelected then
		local originalSelect = _G.SelectCharacterFunction

		_G.SelectCharacterFunction = function(player, characterName)
			-- Chamar função original
			local success, result = originalSelect(player, characterName)

			if success then
				-- Notificar zona segura
				if _G.OnCharacterSelected then
					_G.OnCharacterSelected(player, characterName)
				end

				-- Atualizar estado do jogador
				if _G.SetSpectatorMode then
					_G.SetSpectatorMode(player, false)
				end

				print("  [CONNECT] " .. player.Name .. " selecionou " .. characterName)
			end

			return success, result
		end

		print("  ✓ Sistema de personagens conectado com zona segura")
	end

	-- Conectar sistema de kill com registro de ataques
	if _G.RegisterAttack then
		print("  ✓ Sistema de kill detection conectado")
	end

	-- Conectar sistema de times
	if _G.GetPlayerTeam then
		print("  ✓ Sistema de times conectado")
	end

	return true
end

-- =====================================
-- SINCRONIZAÇÃO GLOBAL
-- =====================================

local function setupGlobalSync()
	print("[INIT] Configurando sincronização global...")

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local updateStatsRemote = remotes:WaitForChild("UpdateStats")

	-- Sincronizar dados periodicamente
	spawn(function()
		while true do
			wait(5) -- A cada 5 segundos

			for _, player in pairs(Players:GetPlayers()) do
				pcall(function()
					if _G.PlayerDataManager then
						local data = _G.PlayerDataManager.getPlayerData(player)
						if data then
							-- Adicionar informações extras
							if _G.GetPlayerTeam then
								local team = _G.GetPlayerTeam(player)
								if team then
									data.currentTeam = {
										name = team.name,
										color = team.color,
										members = #team.members,
										isLeader = team.leader == player,
									}
								end
							end

							-- Enviar para cliente
							updateStatsRemote:FireClient(player, data)
						end
					end
				end)
			end
		end
	end)

	print("  ✓ Sincronização configurada")
	return true
end

-- =====================================
-- COMANDOS DE DEBUG
-- =====================================

local function setupDebugCommands()
	print("[INIT] Configurando comandos de debug...")

	-- Debug de status do jogador
	_G.DebugPlayerStatus = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("❌ Jogador não encontrado: " .. playerName)
			return
		end

		print("\n========== DEBUG: " .. playerName .. " ==========")

		-- Dados do jogador
		if _G.PlayerDataManager then
			local data = _G.PlayerDataManager.getPlayerData(player)
			if data then
				print("💰 Moedas: " .. tostring(data.coins))
				print("⚔️ Bounty: " .. tostring(data.stats.bounty or 0))
				print("💀 Mortes: " .. tostring(data.stats.deaths or 0))
				print("🎮 Personagem: " .. tostring(data.equippedCharacter or "Nenhum"))
				print("📦 Inventário: " .. table.concat(data.ownedCharacters or {}, ", "))
			end
		end

		-- Time
		if _G.GetPlayerTeam then
			local team = _G.GetPlayerTeam(player)
			if team then
				print("👥 Time: " .. team.name)
				print("   Líder: " .. team.leader.Name)
				print("   Membros: " .. #team.members)
			else
				print("👥 Time: Nenhum")
			end
		end

		-- Estado do personagem
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				print("❤️ HP: " .. humanoid.Health .. "/" .. humanoid.MaxHealth)
				print("🏃 Speed: " .. humanoid.WalkSpeed)
				print("⬆️ Jump: " .. humanoid.JumpPower)
			end

			local inSafeZone = player.Character:FindFirstChild("InSafeZone")
			print("🛡️ Zona Segura: " .. (inSafeZone and "Sim" or "Não"))

			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				print(
					"📍 Posição: "
						.. string.format(
							"%.1f, %.1f, %.1f",
							hrp.Position.X,
							hrp.Position.Y,
							hrp.Position.Z
						)
				)
			end
		end

		print("=====================================\n")
	end

	-- Teleporte para zona segura
	_G.TeleportToSafeZone = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(0, 503, 0)
				print("✓ " .. playerName .. " teleportado para zona segura")
			end
		else
			print("❌ Erro ao teleportar " .. playerName)
		end
	end

	-- Forçar seleção de personagem
	_G.ForceSelectCharacter = function(playerName, characterName)
		local player = Players:FindFirstChild(playerName)
		if player then
			if _G.OnCharacterSelected then
				_G.OnCharacterSelected(player, characterName)
				print("✓ " .. playerName .. " forçado a equipar " .. characterName)
			end
		else
			print("❌ Jogador não encontrado")
		end
	end

	-- Resetar barreira
	_G.ResetPlayerBarrier = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			if _G.SetSpectatorMode then
				_G.SetSpectatorMode(player, true)
				wait(0.5)
				_G.SetSpectatorMode(player, false)
				print("✓ Barreira resetada para " .. playerName)
			end
		end
	end

	-- Listar jogadores e estados
	_G.ListAllPlayers = function()
		print("\n========== LISTA DE JOGADORES ==========")
		for _, player in pairs(Players:GetPlayers()) do
			local status = "❓ Desconhecido"

			if player.Character then
				local inSafeZone = player.Character:FindFirstChild("InSafeZone")
				if inSafeZone then
					status = "🛡️ Zona Segura"
				else
					status = "⚔️ Em Jogo"
				end
			else
				status = "💀 Sem Personagem"
			end

			print(string.format("%-20s %s", player.Name, status))
		end
		print("=====================================\n")
	end

	print("  ✓ Comandos de debug configurados")
	return true
end

-- =====================================
-- MONITORAR CONEXÕES
-- =====================================

local function monitorConnections()
	spawn(function()
		while true do
			wait(10)

			-- Verificar se sistemas ainda estão ativos
			local systemsOk = true

			if not _G.PlayerDataManager then
				warn("[MONITOR] ⚠️ PlayerDataManager desconectado!")
				systemsOk = false
			end

			if not systemsOk then
				print("[MONITOR] Tentando reconectar sistemas...")
				waitForSystems()
				connectSystems()
			end
		end
	end)
end

-- =====================================
-- INICIALIZAÇÃO PRINCIPAL
-- =====================================

local function initialize()
	local startTime = tick()

	print("\n🚀 INICIANDO SISTEMA PRINCIPAL...")

	-- Passo 1: Criar estrutura
	if not createFolderStructure() then
		warn("❌ ERRO: Falha ao criar estrutura de pastas")
		return
	end

	-- Passo 2: Criar remotes
	if not createAllRemotes() then
		warn("❌ ERRO: Falha ao criar remotes")
		return
	end

	-- Passo 3: Aguardar sistemas
	wait(2) -- Dar tempo para outros scripts carregarem
	if not waitForSystems() then
		warn("❌ ERRO: Sistemas obrigatórios não carregaram")
		return
	end

	-- Passo 4: Conectar sistemas
	if not connectSystems() then
		warn("❌ ERRO: Falha ao conectar sistemas")
		return
	end

	-- Passo 5: Configurar sincronização
	if not setupGlobalSync() then
		warn("❌ ERRO: Falha ao configurar sincronização")
		return
	end

	-- Passo 6: Configurar debug
	if not setupDebugCommands() then
		warn("❌ ERRO: Falha ao configurar debug")
		return
	end

	-- Passo 7: Iniciar monitoramento
	monitorConnections()

	local loadTime = tick() - startTime

	print(string.format(
		[[
╔════════════════════════════════════════════════════╗
║       ✅ SISTEMA PRINCIPAL CARREGADO              ║
╠════════════════════════════════════════════════════╣
║  Tempo de carregamento: %.2f segundos             ║
╠════════════════════════════════════════════════════╣
║  COMANDOS DE DEBUG DISPONÍVEIS:                   ║
║  • _G.DebugPlayerStatus("Nome")                   ║
║  • _G.TeleportToSafeZone("Nome")                  ║
║  • _G.ForceSelectCharacter("Nome", "Personagem")  ║
║  • _G.ResetPlayerBarrier("Nome")                  ║
║  • _G.ListAllPlayers()                            ║
╚════════════════════════════════════════════════════╝
]],
		loadTime
	))
end

-- Iniciar
initialize()
