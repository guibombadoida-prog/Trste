--!strict
-- EXEMPLO (pode apagar quando seus scripts de verdade chegarem).
--
-- ModuleScript COMPARTILHADO: valores que o servidor E o cliente precisam ler.
-- No Roblox Studio, este arquivo vira:
--   ReplicatedStorage > ModuleScript chamado "Config"

local Config = {
	NOME_DO_JOGO = "Campo de Batalha / Do Chaos",
	VERSAO = "0.1.0",
	VIDA_MAXIMA = 100,
	TEMPO_DE_RESPAWN = 5, -- segundos
}

return Config
