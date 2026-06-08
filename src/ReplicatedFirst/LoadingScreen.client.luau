--!strict
-- ============================================
-- TELA DE CARREGAMENTO — Campo de Batalha / Do Chaos
-- Coloque em: ReplicatedFirst   ·   Nome: "LoadingScreen" (LocalScript)
-- ============================================
-- APARECIMENTO FORÇADO:
--  • GUI criada imediatamente, DisplayOrder máximo, fundo opaco que cobre tudo
--  • Tempo MÍNIMO garantido na tela (mesmo se o jogo já estiver carregado)
--  • Limite anti-trava (nunca fica preso esperando o jogo carregar)
-- ============================================

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

print("[LOADING] script iniciado")

-- Remove a tela de carregamento padrao do Roblox (protegido).
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local MIN_DISPLAY = 5 -- segundos MÍNIMOS visíveis (forçado)
local MAX_WAIT = 25 -- nunca trava esperando o jogo carregar

-- LocalPlayer pode ainda nao estar disponivel em ReplicatedFirst.
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")

local startTime = os.clock()

-- Paleta retro.
local COR_FUNDO = Color3.fromRGB(10, 8, 24)
local COR_NEON = Color3.fromRGB(0, 255, 170)
local COR_NEON2 = Color3.fromRGB(255, 0, 120)
local COR_TEXTO = Color3.fromRGB(235, 235, 245)

-- ScreenGui em PRIMEIRO PLANO ABSOLUTO.
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647 -- máximo: fica acima de qualquer outra GUI
gui.ResetOnSpawn = false
gui.Enabled = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local fundo = Instance.new("Frame")
fundo.Name = "Fundo"
fundo.Size = UDim2.fromScale(1, 1)
fundo.BackgroundColor3 = COR_FUNDO
fundo.BackgroundTransparency = 0
fundo.BorderSizePixel = 0
fundo.Active = true -- bloqueia cliques no que está atrás
fundo.ZIndex = 1
fundo.Parent = gui

-- Titulo do jogo.
local titulo = Instance.new("TextLabel")
titulo.Name = "Titulo"
titulo.AnchorPoint = Vector2.new(0.5, 0.5)
titulo.Position = UDim2.fromScale(0.5, 0.38)
titulo.Size = UDim2.fromScale(0.9, 0.18)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.Arcade
titulo.Text = "CAMPO DE BATALHA / DO CHAOS"
titulo.TextScaled = true
titulo.TextColor3 = COR_NEON
titulo.ZIndex = 2
titulo.Parent = fundo

local tituloStroke = Instance.new("UIStroke")
tituloStroke.Color = COR_NEON2
tituloStroke.Thickness = 2
tituloStroke.Parent = titulo

-- Texto "CARREGANDO".
local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.56)
status.Size = UDim2.fromScale(0.6, 0.06)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.Text = "CARREGANDO"
status.TextScaled = true
status.TextColor3 = COR_TEXTO
status.ZIndex = 2
status.Parent = fundo

-- Trilho da barra de progresso.
local trilho = Instance.new("Frame")
trilho.Name = "Trilho"
trilho.AnchorPoint = Vector2.new(0.5, 0.5)
trilho.Position = UDim2.fromScale(0.5, 0.66)
trilho.Size = UDim2.fromScale(0.6, 0.04)
trilho.BackgroundColor3 = Color3.fromRGB(30, 26, 50)
trilho.BorderSizePixel = 0
trilho.ZIndex = 2
trilho.Parent = fundo

local trilhoStroke = Instance.new("UIStroke")
trilhoStroke.Color = COR_NEON
trilhoStroke.Thickness = 2
trilhoStroke.Parent = trilho

-- Preenchimento da barra.
local barra = Instance.new("Frame")
barra.Name = "Barra"
barra.Size = UDim2.fromScale(0, 1)
barra.BackgroundColor3 = COR_NEON
barra.BorderSizePixel = 0
barra.ZIndex = 3
barra.Parent = trilho

-- Porcentagem do carregamento.
local porcento = Instance.new("TextLabel")
porcento.Name = "Porcento"
porcento.AnchorPoint = Vector2.new(0.5, 0.5)
porcento.Position = UDim2.fromScale(0.5, 0.73)
porcento.Size = UDim2.fromScale(0.3, 0.05)
porcento.BackgroundTransparency = 1
porcento.Font = Enum.Font.Code
porcento.Text = "0%"
porcento.TextScaled = true
porcento.TextColor3 = COR_NEON
porcento.ZIndex = 2
porcento.Parent = fundo

print("[LOADING] tela criada e exibida")

-- Animacao de "..." no texto de status.
local rodando = true
task.spawn(function()
	local pontos = 0
	while rodando do
		pontos = (pontos % 3) + 1
		status.Text = "CARREGANDO" .. string.rep(".", pontos)
		task.wait(0.4)
	end
end)

-- Pulso de brilho neon no titulo (efeito retro).
task.spawn(function()
	while rodando do
		TweenService:Create(tituloStroke, TweenInfo.new(0.8), { Thickness = 4 }):Play()
		task.wait(0.8)
		TweenService:Create(tituloStroke, TweenInfo.new(0.8), { Thickness = 2 }):Play()
		task.wait(0.8)
	end
end)

local function definirProgresso(fracao: number)
	local f = math.clamp(fracao, 0, 1)
	porcento.Text = string.format("%d%%", math.floor(f * 100))
	TweenService:Create(barra, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(f, 1),
	}):Play()
end

-- Barra acompanha o tempo mínimo + carregamento (sobe ate 90% sozinha).
task.spawn(function()
	while rodando do
		local porTempo = (os.clock() - startTime) / MIN_DISPLAY
		definirProgresso(math.min(porTempo, 0.9))
		task.wait(0.1)
	end
end)

-- Esperar o jogo carregar SEM TRAVAR (limite de MAX_WAIT).
local loaded = game:IsLoaded()
if not loaded then
	task.spawn(function()
		game.Loaded:Wait()
		loaded = true
	end)
end
while not loaded and (os.clock() - startTime) < MAX_WAIT do
	task.wait(0.1)
end

-- FORÇA o tempo mínimo de exibição (mesmo se o jogo já estava carregado).
while (os.clock() - startTime) < MIN_DISPLAY do
	task.wait(0.1)
end

rodando = false
definirProgresso(1)
status.Text = "PRONTO!"
task.wait(0.5)

print("[LOADING] sumindo")

-- Desaparece suavemente e remove a GUI.
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
