--!strict
-- EXEMPLO (pode apagar quando seus scripts de verdade chegarem).
--
-- LocalScript do CLIENTE: roda na maquina de cada jogador.
-- No Roblox Studio, este arquivo vira:
--   StarterPlayer > StarterPlayerScripts > LocalScript chamado "Main"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- O mesmo modulo Config que o servidor usa (codigo compartilhado).
local Config = require(ReplicatedStorage:WaitForChild("Config"))

print(string.format("[Cliente] Bem-vindo a %s!", Config.NOME_DO_JOGO))
