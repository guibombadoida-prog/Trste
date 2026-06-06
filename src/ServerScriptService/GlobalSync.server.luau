-- ============================================
-- SISTEMA DE SINCRONIZAÇÃO GLOBAL
-- Coloque em ServerScriptService
-- Nome: "GlobalSync"
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Aguardar todos os sistemas
repeat
	wait()
until _G.PlayerDataManager
repeat
	wait()
until _G.SetSpectatorMode
repeat
	wait()
until _G.GetPlayerTeam

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateStatsRemote = remotes:WaitForChild("UpdateStats")

-- =====================================
-- SINCRONIZAÇÃO PERIÓDICA
-- =====================================

local function syncAllPlayerData()
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local data = _G.PlayerDataManager.getPlayerData(player)
			if data then
				-- Adicionar informações extras
				local team = _G.GetPlayerTeam(player)
				if team then
					data.currentTeam = {
						name = team.name,
						color = team.color,
						members = #team.members,
						isLeader = team.leader == player,
					}
				end

				updateStatsRemote:FireClient(player, data)
			end
		end)
	end
end

-- Loop de sincronização
spawn(function()
	while true do
		wait(5) -- A cada 5 segundos
		syncAllPlayerData()
	end
end)

-- =====================================
-- INTEGRAÇÃO DE EVENTOS
-- =====================================

local function onPlayerDataChanged(player)
	wait(0.1)
	pcall(function()
		local data = _G.PlayerDataManager.getPlayerData(player)
		if data then
			updateStatsRemote:FireClient(player, data)
		end
	end)
end

-- Monitorar mudanças em leaderstats
Players.PlayerAdded:Connect(function(player)
	wait(2)

	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		for _, stat in pairs(leaderstats:GetChildren()) do
			if stat:IsA("IntValue") or stat:IsA("NumberValue") then
				stat.Changed:Connect(function()
					onPlayerDataChanged(player)
				end)
			end
		end
	end

	-- Sincronizar dados iniciais
	onPlayerDataChanged(player)
end)

-- =====================================
-- COMANDOS DE DEBUG
-- =====================================

_G.DebugPlayerStatus = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		print("Jogador não encontrado: " .. playerName)
		return
	end

	print("========== DEBUG: " .. playerName .. " ==========")

	-- Dados do jogador
	local data = _G.PlayerDataManager.getPlayerData(player)
	if data then
		print("💰 Coins:", data.coins)
		print("⚔️ Bounty:", data.stats.bounty)
		print("💀 Deaths:", data.stats.deaths)
		print("🎮 Personagem:", data.equippedCharacter or "Nenhum")
		print("📦 Inventário:", table.concat(data.ownedCharacters, ", "))
	end

	-- Time
	local team = _G.GetPlayerTeam(player)
	if team then
		print("👥 Time:", team.name)
		print("   Líder:", team.leader.Name)
		print("   Membros:", #team.members)
	else
		print("👥 Time: Nenhum")
	end

	-- Estado do personagem
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			print("❤️ HP:", humanoid.Health .. "/" .. humanoid.MaxHealth)
			print("🏃 Speed:", humanoid.WalkSpeed)
		end

		local inSafeZone = player.Character:FindFirstChild("InSafeZone")
		print("🛡️ Zona Segura:", inSafeZone and "Sim" or "Não")
	end

	print("=====================================")
end

_G.TeleportToSafeZone = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player and player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(0, 505, 0)
			print(playerName .. " teleportado para zona segura")
		end
	end
end

_G.ForceSelectCharacter = function(playerName, characterName)
	local player = Players:FindFirstChild(playerName)
	if player then
		if _G.OnCharacterSelected then
			_G.OnCharacterSelected(player, characterName)
			print(playerName .. " forçado a equipar " .. characterName)
		end
	end
end

print([[
╔════════════════════════════════════════════╗
║     SINCRONIZAÇÃO GLOBAL ATIVA            ║
╠════════════════════════════════════════════╣
║  Comandos de Debug Disponíveis:           ║
║  _G.DebugPlayerStatus("Nome")              ║
║  _G.TeleportToSafeZone("Nome")            ║
║  _G.ForceSelectCharacter("Nome", "Char")  ║
╚════════════════════════════════════════════╝
]])
