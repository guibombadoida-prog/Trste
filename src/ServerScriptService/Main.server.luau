--!strict
-- EXEMPLO (pode apagar quando seus scripts de verdade chegarem).
--
-- Script do SERVIDOR: roda no servidor assim que o jogo abre.
-- No Roblox Studio, este arquivo vira:
--   ServerScriptService > Script chamado "Main"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Pega o módulo compartilhado Config (mora em ReplicatedStorage).
local Config = require(ReplicatedStorage:WaitForChild("Config"))

print(string.format("[Servidor] %s v%s iniciado!", Config.NOME_DO_JOGO, Config.VERSAO))

local function aoEntrar(player: Player)
	print(string.format("[Servidor] %s entrou. Vida maxima: %d", player.Name, Config.VIDA_MAXIMA))
end

Players.PlayerAdded:Connect(aoEntrar)
