-- LocalScript_GranadaTatica_V1.lua
-- Coloque DENTRO da Tool "GranadaTatica" com o nome "Client"
-- NOVO SCRIPT (não substitui nenhum)
--
-- REUTILIZAÇÃO:
--   Botão Mobile     → Origem: LocalScript_Katana_V1.lua (ContextActionService)
--   Screen Shake     → Origem: LocalScript_Brawler_V1.lua (performScreenShake)
--
-- COMPATÍVEL COM:
--   PC (click + F + G), Mobile (botões CAS), Console (Gamepad)
--   R6 character model

--[[
═══════════════════════════════════════════════════════════════
        GRANADA TÁTICA - LOCAL SCRIPT V1
═══════════════════════════════════════════════════════════════
FUNCIONALIDADES:
- ✅ Clique → Bomba Doida (persegue inimigos)
- ✅ Botão F / Mobile → Fila de Bombas (7 bombas no chão)
- ✅ Botão G / Mobile → Auto Destruição (explosão no próprio jogador)
- ✅ Screen Shake recebido via RemoteEvent
- ✅ Gamepad: ButtonX = Fila de Bombas, ButtonY = Auto Destruição
- ✅ Sem APIs deprecadas
═══════════════════════════════════════════════════════════════
--]]

-- ═══════════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════════
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════════════
-- VARIÁVEIS
-- ═══════════════════════════════════════════════════════════
local tool = script.Parent
local remoteEvent = tool:WaitForChild("RemoteEvent")
local skill1Event = tool:WaitForChild("Skill1")
local skill2Event = tool:WaitForChild("Skill2")
local skill3Event = tool:WaitForChild("Skill3")
local skill4Event = tool:WaitForChild("Skill4")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
-- SCREEN SHAKE SYSTEM (reutilizado de LocalScript_Brawler_V1)
-- ═══════════════════════════════════════════════════════════
local isShaking = false

local function performScreenShake(intensity, duration)
	if isShaking then
		return
	end
	isShaking = true

	local elapsed = 0

	while elapsed < duration do
		local decay = 1 - (elapsed / duration)
		local strength = intensity * decay

		-- math.noise = ruido Perlin (deterministico, NAO e random)
		local n = elapsed * 35
		local offsetX = math.noise(n, 0.0) * strength
		local offsetY = math.noise(0.0, n) * strength
		local offsetZ = math.noise(n, n) * strength

		camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, offsetZ)

		elapsed = elapsed + RunService.RenderStepped:Wait()
	end

	isShaking = false
end

-- ═══════════════════════════════════════════════════════════
-- RECEBER EVENTOS DO SERVIDOR
-- ═══════════════════════════════════════════════════════════
remoteEvent.OnClientEvent:Connect(function(action, ...)
	if action == "ScreenShake" then
		local intensity, duration = ...
		local charLocal = player.Character
		if charLocal and charLocal:FindFirstChild("HumanoidRootPart") then
			task.spawn(function()
				performScreenShake(intensity or 0.5, duration or 0.2)
			end)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- CLIQUE → BOMBA DOIDA
-- ═══════════════════════════════════════════════════════════
tool.Activated:Connect(function()
	remoteEvent:FireServer("BombaDoida")
end)

-- ═══════════════════════════════════════════════════════════
-- BOTÃO 1 (F / ButtonX / Mobile) → FILA DE BOMBAS
-- ═══════════════════════════════════════════════════════════
local function onFilaBombasAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		skill1Event:FireServer()
	end
end

-- ═══════════════════════════════════════════════════════════
-- BOTÃO 2 (G / ButtonY / Mobile) → AUTO DESTRUIÇÃO
-- ═══════════════════════════════════════════════════════════
local function onAutoDestruicaoAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		skill2Event:FireServer()
	end
end

-- ═══════════════════════════════════════════════════════════
-- MIRA (posição do mouse/toque) para Cluster e Meteoros
-- ═══════════════════════════════════════════════════════════
local function getAimPosition()
	local mouse = player:GetMouse()
	if mouse and mouse.Hit then
		return mouse.Hit.Position
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════
-- BOTÃO 3 (R / ButtonB) → CLUSTER DE PLASMA (mirado)
-- ═══════════════════════════════════════════════════════════
local function onClusterAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		skill3Event:FireServer(getAimPosition())
	end
end

-- ═══════════════════════════════════════════════════════════
-- BOTÃO 4 (T / ButtonL1) → CHUVA DE METEOROS (mirado)
-- ═══════════════════════════════════════════════════════════
local function onMeteorAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		skill4Event:FireServer(getAimPosition())
	end
end

-- ═══════════════════════════════════════════════════════════
-- EQUIPAR → CRIAR BOTÕES MOBILE
-- ═══════════════════════════════════════════════════════════
tool.Equipped:Connect(function()
	-- Botão 1: Fila de Bombas (F / ButtonX)
	ContextActionService:BindAction(
		"GranadaTatica_FilaBombas",
		onFilaBombasAction,
		true, -- criar botão mobile
		Enum.KeyCode.F,
		Enum.KeyCode.ButtonX
	)
	ContextActionService:SetTitle("GranadaTatica_FilaBombas", "💣 Fila")
	ContextActionService:SetPosition("GranadaTatica_FilaBombas", UDim2.new(0.85, -60, 0.10, -60))

	-- Botão 2: Auto Destruição (G / ButtonY)
	ContextActionService:BindAction(
		"GranadaTatica_AutoDestruicao",
		onAutoDestruicaoAction,
		true, -- criar botão mobile
		Enum.KeyCode.G,
		Enum.KeyCode.ButtonY
	)
	ContextActionService:SetTitle("GranadaTatica_AutoDestruicao", "💥 Auto Destruição")
	ContextActionService:SetPosition(
		"GranadaTatica_AutoDestruicao",
		UDim2.new(0.85, -60, 0.25, -60)
	)

	-- Botão 3: Cluster de Plasma (R / ButtonB)
	ContextActionService:BindAction(
		"GranadaTatica_Cluster",
		onClusterAction,
		true,
		Enum.KeyCode.R,
		Enum.KeyCode.ButtonB
	)
	ContextActionService:SetTitle("GranadaTatica_Cluster", "⚡ Cluster")
	ContextActionService:SetPosition("GranadaTatica_Cluster", UDim2.new(0.85, -60, 0.40, -60))

	-- Botão 4: Chuva de Meteoros (T / ButtonL1)
	ContextActionService:BindAction(
		"GranadaTatica_Meteoros",
		onMeteorAction,
		true,
		Enum.KeyCode.T,
		Enum.KeyCode.ButtonL1
	)
	ContextActionService:SetTitle("GranadaTatica_Meteoros", "☄️ Meteoros")
	ContextActionService:SetPosition("GranadaTatica_Meteoros", UDim2.new(0.85, -60, 0.55, -60))
end)

-- ═══════════════════════════════════════════════════════════
-- DESEQUIPAR → REMOVER BOTÕES MOBILE
-- ═══════════════════════════════════════════════════════════
tool.Unequipped:Connect(function()
	ContextActionService:UnbindAction("GranadaTatica_FilaBombas")
	ContextActionService:UnbindAction("GranadaTatica_AutoDestruicao")
	ContextActionService:UnbindAction("GranadaTatica_Cluster")
	ContextActionService:UnbindAction("GranadaTatica_Meteoros")
end)

--[[
═══════════════════════════════════════════════════════════════
INSTRUÇÕES DE USO:

1. PC:
   - Click: Bomba Doida (persegue inimigos, fica vermelha/rápida)
   - F: Fila de Bombas (7 bombas no chão, explodem em sequência)
   - G: Auto Destruição (explosão no próprio jogador após 2s)

2. MOBILE:
   - Toque na tela: Bomba Doida
   - Botão "💣 Fila": Fila de Bombas
   - Botão "💥 Auto Destruição": Auto Destruição

3. GAMEPAD:
   - RT: Bomba Doida
   - ButtonX: Fila de Bombas
   - ButtonY: Auto Destruição

COOLDOWNS:
   Bomba Doida:     4 segundos
   Fila de Bombas:  8 segundos
   Auto Destruição: 15 segundos
═══════════════════════════════════════════════════════════════

ESTRUTURA DA TOOL:
Tool (GranadaTatica)
├─ Handle (Part ou MeshPart)
├─ Script       → ServerScript_GranadaTatica_V1.lua
├─ Client       → LocalScript_GranadaTatica_V1.lua  (este)
├─ RemoteEvent  → clique principal (BombaDoida) + feedback
├─ Skill1       → RemoteEvent (Fila de Bombas)
└─ Skill2       → RemoteEvent (Auto Destruição)
═══════════════════════════════════════════════════════════════
--]]
