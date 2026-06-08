-- ============================================
-- TELA DE CARREGAMENTO HIPER AVANÇADA (CLIENT)
-- ReplicatedFirst > LoadingScreen (LocalScript)
-- ============================================
-- Arquitetura server + client:
--   • Mostra a tela IMEDIATAMENTE (DisplayOrder máximo, fundo opaco)
--   • Some só quando: jogo carregado (game:IsLoaded) E servidor sinaliza
--     que o jogador está pronto (Remotes.LoadingReady) E tempo mínimo
--   • Estágios reais vindos do servidor (Remotes.LoadingStage)
--   • Anti-trava: nunca fica preso (MAX_WAIT)
--   • Visual: gradiente animado, scanlines, spinner, brilho, barra suave
-- ============================================

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

print("[LOADING] script iniciado")

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local MIN_DISPLAY = 4 -- segundos mínimos visíveis
local MAX_WAIT = 30 -- limite anti-trava

-- LocalPlayer (sem travar)
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")

local startTime = os.clock()

-- ===================== PALETA =====================
local COR_FUNDO = Color3.fromRGB(8, 6, 20)
local COR_FUNDO2 = Color3.fromRGB(20, 10, 40)
local COR_NEON = Color3.fromRGB(0, 255, 170)
local COR_NEON2 = Color3.fromRGB(255, 0, 120)
local COR_TEXTO = Color3.fromRGB(235, 235, 245)

-- ===================== GUI =====================
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ResetOnSpawn = false
gui.Enabled = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local fundo = Instance.new("Frame")
fundo.Name = "Fundo"
fundo.Size = UDim2.fromScale(1, 1)
fundo.BackgroundColor3 = COR_FUNDO
fundo.BorderSizePixel = 0
fundo.Active = true
fundo.ZIndex = 1
fundo.Parent = gui

-- Gradiente animado de fundo
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new(COR_FUNDO, COR_FUNDO2)
grad.Parent = fundo

-- Scanlines (linhas retro)
local scan = Instance.new("Frame")
scan.Name = "Scanlines"
scan.Size = UDim2.fromScale(1, 1)
scan.BackgroundTransparency = 1
scan.ZIndex = 1
scan.Parent = fundo
do
	-- algumas linhas horizontais semi-transparentes (sem custo de imagem)
	for i = 1, 40 do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.fromScale(0, i / 40)
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = 0.85
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = scan
	end
end

-- Título
local titulo = Instance.new("TextLabel")
titulo.Name = "Titulo"
titulo.AnchorPoint = Vector2.new(0.5, 0.5)
titulo.Position = UDim2.fromScale(0.5, 0.36)
titulo.Size = UDim2.fromScale(0.9, 0.18)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.Arcade
titulo.Text = "CAMPO DE BATALHA / DO CHAOS"
titulo.TextScaled = true
titulo.TextColor3 = COR_NEON
titulo.ZIndex = 3
titulo.Parent = fundo

local tituloStroke = Instance.new("UIStroke")
tituloStroke.Color = COR_NEON2
tituloStroke.Thickness = 2
tituloStroke.Parent = titulo

-- Spinner (arco girando)
local spinner = Instance.new("TextLabel")
spinner.Name = "Spinner"
spinner.AnchorPoint = Vector2.new(0.5, 0.5)
spinner.Position = UDim2.fromScale(0.5, 0.52)
spinner.Size = UDim2.fromScale(0.1, 0.08)
spinner.BackgroundTransparency = 1
spinner.Font = Enum.Font.Code
spinner.Text = "◜"
spinner.TextScaled = true
spinner.TextColor3 = COR_NEON
spinner.ZIndex = 3
spinner.Parent = fundo

-- Estágio (texto do servidor)
local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.62)
status.Size = UDim2.fromScale(0.7, 0.06)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.Text = "Iniciando..."
status.TextScaled = true
status.TextColor3 = COR_TEXTO
status.ZIndex = 3
status.Parent = fundo

-- Trilho da barra
local trilho = Instance.new("Frame")
trilho.Name = "Trilho"
trilho.AnchorPoint = Vector2.new(0.5, 0.5)
trilho.Position = UDim2.fromScale(0.5, 0.71)
trilho.Size = UDim2.fromScale(0.6, 0.035)
trilho.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
trilho.BorderSizePixel = 0
trilho.ZIndex = 3
trilho.Parent = fundo

local trilhoCorner = Instance.new("UICorner")
trilhoCorner.CornerRadius = UDim.new(1, 0)
trilhoCorner.Parent = trilho

local trilhoStroke = Instance.new("UIStroke")
trilhoStroke.Color = COR_NEON
trilhoStroke.Thickness = 2
trilhoStroke.Parent = trilho

-- Preenchimento
local barra = Instance.new("Frame")
barra.Name = "Barra"
barra.Size = UDim2.fromScale(0, 1)
barra.BackgroundColor3 = COR_NEON
barra.BorderSizePixel = 0
barra.ZIndex = 4
barra.Parent = trilho

local barraCorner = Instance.new("UICorner")
barraCorner.CornerRadius = UDim.new(1, 0)
barraCorner.Parent = barra

local barraGrad = Instance.new("UIGradient")
barraGrad.Color = ColorSequence.new(COR_NEON, COR_NEON2)
barraGrad.Parent = barra

-- Porcentagem
local porcento = Instance.new("TextLabel")
porcento.Name = "Porcento"
porcento.AnchorPoint = Vector2.new(0.5, 0.5)
porcento.Position = UDim2.fromScale(0.5, 0.78)
porcento.Size = UDim2.fromScale(0.3, 0.05)
porcento.BackgroundTransparency = 1
porcento.Font = Enum.Font.Code
porcento.Text = "0%"
porcento.TextScaled = true
porcento.TextColor3 = COR_NEON
porcento.ZIndex = 3
porcento.Parent = fundo

print("[LOADING] tela criada e exibida")

-- ===================== ESTADO =====================
local rodando = true
local serverReady = false
local serverFraction = 0 -- progresso reportado pelo servidor (0..1)
local mostrado = 0 -- progresso exibido (suavizado)

-- ===================== ANIMAÇÕES =====================
-- Spinner girando
task.spawn(function()
	local frames = { "◜", "◝", "◞", "◟" }
	local i = 1
	while rodando do
		spinner.Text = frames[i]
		i = (i % #frames) + 1
		task.wait(0.12)
	end
end)

-- Gradiente do fundo respirando
task.spawn(function()
	while rodando do
		TweenService:Create(grad, TweenInfo.new(2), { Offset = Vector2.new(0, 0.15) }):Play()
		task.wait(2)
		TweenService:Create(grad, TweenInfo.new(2), { Offset = Vector2.new(0, -0.15) }):Play()
		task.wait(2)
	end
end)

-- Pulso de brilho no título
task.spawn(function()
	while rodando do
		TweenService:Create(tituloStroke, TweenInfo.new(0.8), { Thickness = 4 }):Play()
		task.wait(0.8)
		TweenService:Create(tituloStroke, TweenInfo.new(0.8), { Thickness = 2 }):Play()
		task.wait(0.8)
	end
end)

-- Atualização suave da barra (combina tempo + progresso do servidor)
RunService.Heartbeat:Connect(function()
	if not rodando then
		return
	end
	local porTempo = (os.clock() - startTime) / MIN_DISPLAY
	local alvo = math.max(serverFraction, math.min(porTempo, 0.95))
	mostrado = mostrado + (alvo - mostrado) * 0.08
	local f = math.clamp(mostrado, 0, 1)
	barra.Size = UDim2.fromScale(f, 1)
	porcento.Text = string.format("%d%%", math.floor(f * 100))
end)

-- ===================== HANDSHAKE COM O SERVIDOR =====================
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 12)
	if not remotes then
		print("[LOADING] Remotes nao encontrado; seguindo no modo tempo")
		return
	end

	local stageEvent = remotes:FindFirstChild("LoadingStage")
	if stageEvent and stageEvent:IsA("RemoteEvent") then
		stageEvent.OnClientEvent:Connect(function(texto, fracao)
			if type(texto) == "string" then
				status.Text = texto
			end
			if type(fracao) == "number" then
				serverFraction = math.clamp(fracao, 0, 1)
			end
		end)
	end

	local readyEvent = remotes:FindFirstChild("LoadingReady")
	if readyEvent and readyEvent:IsA("RemoteEvent") then
		readyEvent.OnClientEvent:Connect(function()
			serverReady = true
		end)
	end

	-- Poll de segurança (caso o evento tenha disparado antes de conectarmos)
	local queryFn = remotes:FindFirstChild("QueryLoadingReady")
	if queryFn and queryFn:IsA("RemoteFunction") then
		while not serverReady and rodando do
			local ok, res = pcall(function()
				return queryFn:InvokeServer()
			end)
			if ok and res == true then
				serverReady = true
				break
			end
			task.wait(0.3)
		end
	end
end)

-- ===================== ESPERA PRINCIPAL =====================
-- Jogo carregado (sem travar)
local gameLoaded = game:IsLoaded()
if not gameLoaded then
	task.spawn(function()
		game.Loaded:Wait()
		gameLoaded = true
	end)
end

-- Espera: jogo carregado E servidor pronto E tempo mínimo — limitado por MAX_WAIT
while rodando do
	local elapsed = os.clock() - startTime
	local prontoTudo = gameLoaded and serverReady and elapsed >= MIN_DISPLAY
	if prontoTudo or elapsed >= MAX_WAIT then
		break
	end
	task.wait(0.1)
end

-- ===================== FINAL =====================
serverFraction = 1
status.Text = "Pronto!"
task.wait(0.4)
rodando = false

print("[LOADING] sumindo")

local fade = TweenService:Create(fundo, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1,
})
for _, item in fundo:GetDescendants() do
	if item:IsA("TextLabel") then
		TweenService:Create(item, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
	elseif item:IsA("Frame") then
		TweenService:Create(item, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	elseif item:IsA("UIStroke") then
		TweenService:Create(item, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	end
end
fade:Play()
fade.Completed:Wait()
gui:Destroy()
