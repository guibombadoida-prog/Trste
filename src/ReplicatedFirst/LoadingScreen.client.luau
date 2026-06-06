--!strict
-- ============================================
-- TELA DE CARREGAMENTO — Campo de Batalha / Do Chaos
-- Coloque em: ReplicatedFirst
-- Nome: "LoadingScreen"  (tipo: LocalScript)
-- ============================================
-- Mostra uma tela retro enquanto o jogo carrega e some sozinha
-- quando tudo estiver pronto (game:IsLoaded()).
-- ============================================

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Remove a tela de carregamento padrao do Roblox.
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Paleta retro.
local COR_FUNDO = Color3.fromRGB(10, 8, 24)
local COR_NEON = Color3.fromRGB(0, 255, 170)
local COR_NEON2 = Color3.fromRGB(255, 0, 120)
local COR_TEXTO = Color3.fromRGB(235, 235, 245)

-- ScreenGui em primeiro plano.
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local fundo = Instance.new("Frame")
fundo.Name = "Fundo"
fundo.Size = UDim2.fromScale(1, 1)
fundo.BackgroundColor3 = COR_FUNDO
fundo.BorderSizePixel = 0
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
status.Parent = fundo

-- Trilho da barra de progresso.
local trilho = Instance.new("Frame")
trilho.Name = "Trilho"
trilho.AnchorPoint = Vector2.new(0.5, 0.5)
trilho.Position = UDim2.fromScale(0.5, 0.66)
trilho.Size = UDim2.fromScale(0.6, 0.04)
trilho.BackgroundColor3 = Color3.fromRGB(30, 26, 50)
trilho.BorderSizePixel = 0
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
barra.Parent = trilho

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

-- Acompanha o progresso real de carregamento do jogo.
local function definirProgresso(fracao: number)
	local f = math.clamp(fracao, 0, 1)
	TweenService:Create(barra, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(f, 1),
	}):Play()
end

-- Anima a barra subindo gradualmente ate o jogo carregar.
task.spawn(function()
	local progressoFake = 0
	while rodando and not game:IsLoaded() do
		progressoFake = math.min(progressoFake + 0.04, 0.9)
		definirProgresso(progressoFake)
		task.wait(0.15)
	end
end)

-- Espera o jogo terminar de carregar.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

rodando = false
definirProgresso(1)
status.Text = "PRONTO!"
task.wait(0.6)

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
