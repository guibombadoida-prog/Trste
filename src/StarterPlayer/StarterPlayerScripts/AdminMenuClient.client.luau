-- ============================================
-- ADMIN MENU CLIENT V6
-- Coloque em StarterPlayer > StarterPlayerScripts
-- Nome: "AdminMenuClient"
-- SUBSTITUI: ADMIN_MENU_CLIENT_V4
-- ============================================
-- CORRECOES V5:
-- • REMOVIDO UserInputService / KeyCode.F9 (PROIBIDO - conflita com keybinds de Tool)
-- • selectButton na aba Jogadores agora atualiza TODOS os inputs (playerInput, charPlayerInput, actionsPlayerInput)
-- • spawn() -> task.spawn() / wait() -> task.wait()
-- • Interface criada UMA VEZ apenas (sem re-criar no CharacterAdded)
-- • Aba Jogadores exibe kills, personagem equipado e total do inventario
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Verificacao de admin antes de qualquer coisa
local ADMIN_IDS = { 1595442496, 8833465560, 1832521992 }
if not table.find(ADMIN_IDS, player.UserId) then
	return
end

-- =====================================
-- AGUARDAR REMOTES
-- =====================================

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local adminGiveCoins = remotes:WaitForChild("AdminGiveCoins")
local adminGiveBounty = remotes:WaitForChild("AdminGiveBounty")
local adminGiveCharacter = remotes:WaitForChild("AdminGiveCharacter")
local adminGiveAllCharacters = remotes:WaitForChild("AdminGiveAllCharacters")
local adminResetData = remotes:WaitForChild("AdminResetData")
local adminTeleport = remotes:WaitForChild("AdminTeleport")
local adminKill = remotes:WaitForChild("AdminKill")
local adminKick = remotes:WaitForChild("AdminKick")
local getPlayerList = remotes:WaitForChild("GetPlayerList")

-- =====================================
-- SONS
-- =====================================

local sounds = {
	hover = "rbxassetid://12846056",
	click = "rbxassetid://156785206",
	open = "rbxassetid://157167203",
	close = "rbxassetid://157167205",
}

local function playSound(soundId)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound.Parent = nil
		end)
	end)
end

-- =====================================
-- CORES
-- =====================================

local COLORS = {
	background = Color3.fromRGB(20, 20, 20),
	panel = Color3.fromRGB(30, 30, 30),
	header = Color3.fromRGB(139, 0, 0),
	border = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(0, 200, 0),
	error = Color3.fromRGB(200, 0, 0),
	warning = Color3.fromRGB(255, 200, 0),
}

-- =====================================
-- INTERFACE
-- =====================================

local isOpen = false
local screenGui = nil
local mainFrame = nil

-- Referencias globais dos inputs para uso em todos os tabs
local playerInput = nil
local charPlayerInput = nil
local actionsPlayerInput = nil

local function createAdminInterface()
	if screenGui then
		screenGui.Parent = nil
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminMenuV6"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui

	-- Botao de abrir (unico modo de abrir - SEM keybind de teclado)
	-- openButton REMOVIDO (Menu Unificado controla)

	-- openCorner REMOVIDO

	-- Frame principal
	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0.6, 0, 0.82, 0)
	mainFrame.Position = UDim2.new(0.2, 0, 0.09, 0)
	mainFrame.BackgroundColor3 = COLORS.background
	mainFrame.BorderColor3 = COLORS.border
	mainFrame.BorderSizePixel = 4
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 6)
	mainCorner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.08, 0)
	header.BackgroundColor3 = COLORS.header
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.82, 0, 1, 0)
	title.Position = UDim2.new(0.02, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "PAINEL ADMINISTRATIVO"
	title.TextColor3 = COLORS.border
	title.TextScaled = true
	title.Font = Enum.Font.Arcade
	title.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.05, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.94, 0, 0.1, 0)
	closeButton.BackgroundColor3 = COLORS.error
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = COLORS.border
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = header

	-- Tabs
	local tabsFrame = Instance.new("Frame")
	tabsFrame.Size = UDim2.new(1, 0, 0.07, 0)
	tabsFrame.Position = UDim2.new(0, 0, 0.08, 0)
	tabsFrame.BackgroundColor3 = COLORS.panel
	tabsFrame.BorderSizePixel = 0
	tabsFrame.Parent = mainFrame

	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(0.98, 0, 0.84, 0)
	contentFrame.Position = UDim2.new(0.01, 0, 0.15, 0)
	contentFrame.BackgroundColor3 = COLORS.panel
	contentFrame.BorderColor3 = COLORS.border
	contentFrame.BorderSizePixel = 2
	contentFrame.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 4)
	contentCorner.Parent = contentFrame

	local tabNames = { "Moedas", "Personagens", "Jogadores", "Acoes" }
	local tabContents = {}
	local tabButtons = {}
	local activeTab = 1

	local function setActiveTab(index)
		activeTab = index
		for i, btn in ipairs(tabButtons) do
			btn.BackgroundColor3 = i == index and COLORS.warning or COLORS.panel
			btn.TextColor3 = i == index and COLORS.background or COLORS.border
		end
		for i, cont in ipairs(tabContents) do
			cont.Visible = i == index
		end
	end

	for i, tabName in ipairs(tabNames) do
		local tabButton = Instance.new("TextButton")
		tabButton.Size = UDim2.new(0.24, 0, 0.9, 0)
		tabButton.Position = UDim2.new(0.005 + (i - 1) * 0.248, 0, 0.05, 0)
		tabButton.BackgroundColor3 = i == 1 and COLORS.warning or COLORS.panel
		tabButton.BorderColor3 = COLORS.border
		tabButton.BorderSizePixel = 1
		tabButton.Text = tabName:upper()
		tabButton.TextColor3 = i == 1 and COLORS.background or COLORS.border
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.Arcade
		tabButton.Parent = tabsFrame

		tabButtons[i] = tabButton

		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundTransparency = 1
		content.Visible = i == 1
		content.Parent = contentFrame
		tabContents[i] = content

		local capturedIndex = i
		tabButton.MouseButton1Click:Connect(function()
			playSound(sounds.click)
			setActiveTab(capturedIndex)
		end)
	end

	-- ============================
	-- TAB 1: MOEDAS
	-- ============================

	local coinsContent = tabContents[1]

	local coinsTitle = Instance.new("TextLabel")
	coinsTitle.Size = UDim2.new(1, 0, 0.08, 0)
	coinsTitle.BackgroundTransparency = 1
	coinsTitle.Text = "[ GERENCIAR MOEDAS E BOUNTY ]"
	coinsTitle.TextColor3 = COLORS.warning
	coinsTitle.TextScaled = true
	coinsTitle.Font = Enum.Font.Arcade
	coinsTitle.Parent = coinsContent

	-- Input: Jogador
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
	playerLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
	playerLabel.BackgroundTransparency = 1
	playerLabel.Text = "JOGADOR:"
	playerLabel.TextColor3 = COLORS.border
	playerLabel.TextScaled = true
	playerLabel.Font = Enum.Font.Arcade
	playerLabel.Parent = coinsContent

	playerInput = Instance.new("TextBox")
	playerInput.Size = UDim2.new(0.7, 0, 0.08, 0)
	playerInput.Position = UDim2.new(0.26, 0, 0.12, 0)
	playerInput.BackgroundColor3 = COLORS.background
	playerInput.BorderColor3 = COLORS.border
	playerInput.BorderSizePixel = 2
	playerInput.Text = ""
	playerInput.PlaceholderText = "Nome do jogador..."
	playerInput.TextColor3 = COLORS.border
	playerInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	playerInput.TextScaled = true
	playerInput.Font = Enum.Font.Arcade
	playerInput.Parent = coinsContent

	-- Input: Quantidade
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
	amountLabel.Position = UDim2.new(0.05, 0, 0.23, 0)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = "QTDE:"
	amountLabel.TextColor3 = COLORS.border
	amountLabel.TextScaled = true
	amountLabel.Font = Enum.Font.Arcade
	amountLabel.Parent = coinsContent

	local amountInput = Instance.new("TextBox")
	amountInput.Size = UDim2.new(0.7, 0, 0.08, 0)
	amountInput.Position = UDim2.new(0.26, 0, 0.23, 0)
	amountInput.BackgroundColor3 = COLORS.background
	amountInput.BorderColor3 = COLORS.border
	amountInput.BorderSizePixel = 2
	amountInput.Text = ""
	amountInput.PlaceholderText = "Numero..."
	amountInput.TextColor3 = COLORS.border
	amountInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	amountInput.TextScaled = true
	amountInput.Font = Enum.Font.Arcade
	amountInput.Parent = coinsContent

	-- Botoes: Dar Moedas / Dar Bounty
	local giveCoinsBtn = Instance.new("TextButton")
	giveCoinsBtn.Size = UDim2.new(0.42, 0, 0.11, 0)
	giveCoinsBtn.Position = UDim2.new(0.04, 0, 0.35, 0)
	giveCoinsBtn.BackgroundColor3 = COLORS.success
	giveCoinsBtn.BorderColor3 = COLORS.border
	giveCoinsBtn.BorderSizePixel = 2
	giveCoinsBtn.Text = "+ MOEDAS"
	giveCoinsBtn.TextColor3 = COLORS.background
	giveCoinsBtn.TextScaled = true
	giveCoinsBtn.Font = Enum.Font.Arcade
	giveCoinsBtn.Parent = coinsContent

	local giveBountyBtn = Instance.new("TextButton")
	giveBountyBtn.Size = UDim2.new(0.42, 0, 0.11, 0)
	giveBountyBtn.Position = UDim2.new(0.54, 0, 0.35, 0)
	giveBountyBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	giveBountyBtn.BorderColor3 = COLORS.border
	giveBountyBtn.BorderSizePixel = 2
	giveBountyBtn.Text = "+ BOUNTY"
	giveBountyBtn.TextColor3 = COLORS.background
	giveBountyBtn.TextScaled = true
	giveBountyBtn.Font = Enum.Font.Arcade
	giveBountyBtn.Parent = coinsContent

	giveCoinsBtn.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		local name = playerInput.Text
		local amount = tonumber(amountInput.Text)
		if name ~= "" and amount then
			adminGiveCoins:FireServer(name, amount)
			amountInput.Text = ""
		end
	end)

	giveBountyBtn.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		local name = playerInput.Text
		local amount = tonumber(amountInput.Text)
		if name ~= "" and amount then
			adminGiveBounty:FireServer(name, amount)
			amountInput.Text = ""
		end
	end)

	-- ============================
	-- TAB 2: PERSONAGENS
	-- ============================

	local charsContent = tabContents[2]

	local charsTitle = Instance.new("TextLabel")
	charsTitle.Size = UDim2.new(1, 0, 0.08, 0)
	charsTitle.BackgroundTransparency = 1
	charsTitle.Text = "[ GERENCIAR PERSONAGENS ]"
	charsTitle.TextColor3 = COLORS.warning
	charsTitle.TextScaled = true
	charsTitle.Font = Enum.Font.Arcade
	charsTitle.Parent = charsContent

	local charPlayerLabel = Instance.new("TextLabel")
	charPlayerLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
	charPlayerLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
	charPlayerLabel.BackgroundTransparency = 1
	charPlayerLabel.Text = "JOGADOR:"
	charPlayerLabel.TextColor3 = COLORS.border
	charPlayerLabel.TextScaled = true
	charPlayerLabel.Font = Enum.Font.Arcade
	charPlayerLabel.Parent = charsContent

	charPlayerInput = Instance.new("TextBox")
	charPlayerInput.Size = UDim2.new(0.7, 0, 0.08, 0)
	charPlayerInput.Position = UDim2.new(0.26, 0, 0.12, 0)
	charPlayerInput.BackgroundColor3 = COLORS.background
	charPlayerInput.BorderColor3 = COLORS.border
	charPlayerInput.BorderSizePixel = 2
	charPlayerInput.Text = ""
	charPlayerInput.PlaceholderText = "Nome do jogador..."
	charPlayerInput.TextColor3 = COLORS.border
	charPlayerInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	charPlayerInput.TextScaled = true
	charPlayerInput.Font = Enum.Font.Arcade
	charPlayerInput.Parent = charsContent

	local charNameLabel = Instance.new("TextLabel")
	charNameLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
	charNameLabel.Position = UDim2.new(0.05, 0, 0.23, 0)
	charNameLabel.BackgroundTransparency = 1
	charNameLabel.Text = "PERSONAGEM:"
	charNameLabel.TextColor3 = COLORS.border
	charNameLabel.TextScaled = true
	charNameLabel.Font = Enum.Font.Arcade
	charNameLabel.Parent = charsContent

	local charNameInput = Instance.new("TextBox")
	charNameInput.Size = UDim2.new(0.7, 0, 0.08, 0)
	charNameInput.Position = UDim2.new(0.26, 0, 0.23, 0)
	charNameInput.BackgroundColor3 = COLORS.background
	charNameInput.BorderColor3 = COLORS.border
	charNameInput.BorderSizePixel = 2
	charNameInput.Text = ""
	charNameInput.PlaceholderText = "Nome exato do personagem..."
	charNameInput.TextColor3 = COLORS.border
	charNameInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	charNameInput.TextScaled = true
	charNameInput.Font = Enum.Font.Arcade
	charNameInput.Parent = charsContent

	local giveCharBtn = Instance.new("TextButton")
	giveCharBtn.Size = UDim2.new(0.42, 0, 0.11, 0)
	giveCharBtn.Position = UDim2.new(0.04, 0, 0.35, 0)
	giveCharBtn.BackgroundColor3 = COLORS.success
	giveCharBtn.BorderColor3 = COLORS.border
	giveCharBtn.BorderSizePixel = 2
	giveCharBtn.Text = "DAR PERSONAGEM"
	giveCharBtn.TextColor3 = COLORS.background
	giveCharBtn.TextScaled = true
	giveCharBtn.Font = Enum.Font.Arcade
	giveCharBtn.Parent = charsContent

	local giveAllBtn = Instance.new("TextButton")
	giveAllBtn.Size = UDim2.new(0.42, 0, 0.11, 0)
	giveAllBtn.Position = UDim2.new(0.54, 0, 0.35, 0)
	giveAllBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	giveAllBtn.BorderColor3 = COLORS.border
	giveAllBtn.BorderSizePixel = 2
	giveAllBtn.Text = "DAR TODOS"
	giveAllBtn.TextColor3 = COLORS.border
	giveAllBtn.TextScaled = true
	giveAllBtn.Font = Enum.Font.Arcade
	giveAllBtn.Parent = charsContent

	giveCharBtn.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		local name = charPlayerInput.Text
		local charName = charNameInput.Text
		if name ~= "" and charName ~= "" then
			adminGiveCharacter:FireServer(name, charName)
			charNameInput.Text = ""
		end
	end)

	giveAllBtn.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		local name = charPlayerInput.Text
		if name ~= "" then
			adminGiveAllCharacters:FireServer(name)
		end
	end)

	-- ============================
	-- TAB 3: JOGADORES
	-- ============================

	local playersContent = tabContents[3]

	local playersTitle = Instance.new("TextLabel")
	playersTitle.Size = UDim2.new(0.7, 0, 0.08, 0)
	playersTitle.BackgroundTransparency = 1
	playersTitle.Text = "[ JOGADORES ONLINE ]"
	playersTitle.TextColor3 = COLORS.warning
	playersTitle.TextScaled = true
	playersTitle.Font = Enum.Font.Arcade
	playersTitle.Parent = playersContent

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0.18, 0, 0.07, 0)
	refreshBtn.Position = UDim2.new(0.8, 0, 0.005, 0)
	refreshBtn.BackgroundColor3 = COLORS.panel
	refreshBtn.BorderColor3 = COLORS.border
	refreshBtn.BorderSizePixel = 2
	refreshBtn.Text = "ATUALIZAR"
	refreshBtn.TextColor3 = COLORS.warning
	refreshBtn.TextScaled = true
	refreshBtn.Font = Enum.Font.Arcade
	refreshBtn.Parent = playersContent

	local playersList = Instance.new("ScrollingFrame")
	playersList.Size = UDim2.new(0.98, 0, 0.88, 0)
	playersList.Position = UDim2.new(0.01, 0, 0.1, 0)
	playersList.BackgroundColor3 = COLORS.background
	playersList.BorderColor3 = COLORS.border
	playersList.BorderSizePixel = 2
	playersList.ScrollBarThickness = 8
	playersList.ScrollBarImageColor3 = COLORS.border
	playersList.Parent = playersContent

	local function updatePlayersList()
		for _, child in pairs(playersList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local ok, playerData = pcall(function()
			return getPlayerList:InvokeServer()
		end)

		if not ok or not playerData then
			return
		end

		local yPos = 5
		for _, data in ipairs(playerData) do
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0.95, 0, 0, 60)
			card.Position = UDim2.new(0.025, 0, 0, yPos)
			card.BackgroundColor3 = COLORS.panel
			card.BorderColor3 = COLORS.border
			card.BorderSizePixel = 2
			card.Parent = playersList

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 4)
			cardCorner.Parent = card

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.28, 0, 0.5, 0)
			nameLabel.Position = UDim2.new(0.01, 0, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = data.name
			nameLabel.TextColor3 = COLORS.border
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.Arcade
			nameLabel.Parent = card

			-- Linha 1: moedas e bounty
			local statsLine1 = Instance.new("TextLabel")
			statsLine1.Size = UDim2.new(0.5, 0, 0.45, 0)
			statsLine1.Position = UDim2.new(0.3, 0, 0, 0)
			statsLine1.BackgroundTransparency = 1
			statsLine1.Text =
				string.format("$ %d | B %d | K %d", data.coins, data.bounty, data.kills)
			statsLine1.TextColor3 = COLORS.warning
			statsLine1.TextScaled = true
			statsLine1.Font = Enum.Font.Arcade
			statsLine1.Parent = card

			-- Linha 2: personagem equipado e inventário
			local statsLine2 = Instance.new("TextLabel")
			statsLine2.Size = UDim2.new(0.5, 0, 0.45, 0)
			statsLine2.Position = UDim2.new(0.3, 0, 0.5, 0)
			statsLine2.BackgroundTransparency = 1
			statsLine2.Text = string.format(
				"Char: %s | Inv: %d",
				data.equippedChar or "Nenhum",
				data.ownedCount or 0
			)
			statsLine2.TextColor3 = Color3.fromRGB(180, 180, 180)
			statsLine2.TextScaled = true
			statsLine2.Font = Enum.Font.Arcade
			statsLine2.Parent = card

			-- Botao SELECIONAR: preenche TODOS os inputs de todos os tabs
			local selectBtn = Instance.new("TextButton")
			selectBtn.Size = UDim2.new(0.13, 0, 0.7, 0)
			selectBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
			selectBtn.BackgroundColor3 = COLORS.success
			selectBtn.BorderColor3 = COLORS.border
			selectBtn.BorderSizePixel = 1
			selectBtn.Text = "USAR"
			selectBtn.TextColor3 = COLORS.background
			selectBtn.TextScaled = true
			selectBtn.Font = Enum.Font.Arcade
			selectBtn.Parent = card

			local capturedName = data.name
			selectBtn.MouseButton1Click:Connect(function()
				playSound(sounds.click)
				-- Sincroniza com TODOS os campos de input do painel
				playerInput.Text = capturedName
				charPlayerInput.Text = capturedName
				actionsPlayerInput.Text = capturedName
			end)

			yPos = yPos + 65
		end

		playersList.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
	end

	refreshBtn.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		updatePlayersList()
	end)

	-- ============================
	-- TAB 4: ACOES
	-- ============================

	local actionsContent = tabContents[4]

	local actionsTitle = Instance.new("TextLabel")
	actionsTitle.Size = UDim2.new(1, 0, 0.08, 0)
	actionsTitle.BackgroundTransparency = 1
	actionsTitle.Text = "[ ACOES RAPIDAS ]"
	actionsTitle.TextColor3 = COLORS.warning
	actionsTitle.TextScaled = true
	actionsTitle.Font = Enum.Font.Arcade
	actionsTitle.Parent = actionsContent

	local actionsPlayerLabel = Instance.new("TextLabel")
	actionsPlayerLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
	actionsPlayerLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
	actionsPlayerLabel.BackgroundTransparency = 1
	actionsPlayerLabel.Text = "JOGADOR:"
	actionsPlayerLabel.TextColor3 = COLORS.border
	actionsPlayerLabel.TextScaled = true
	actionsPlayerLabel.Font = Enum.Font.Arcade
	actionsPlayerLabel.Parent = actionsContent

	actionsPlayerInput = Instance.new("TextBox")
	actionsPlayerInput.Size = UDim2.new(0.7, 0, 0.08, 0)
	actionsPlayerInput.Position = UDim2.new(0.26, 0, 0.12, 0)
	actionsPlayerInput.BackgroundColor3 = COLORS.background
	actionsPlayerInput.BorderColor3 = COLORS.border
	actionsPlayerInput.BorderSizePixel = 2
	actionsPlayerInput.Text = ""
	actionsPlayerInput.PlaceholderText = "Nome do jogador..."
	actionsPlayerInput.TextColor3 = COLORS.border
	actionsPlayerInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	actionsPlayerInput.TextScaled = true
	actionsPlayerInput.Font = Enum.Font.Arcade
	actionsPlayerInput.Parent = actionsContent

	local actions = {
		{
			text = "KILL",
			color = COLORS.error,
			pos = UDim2.new(0.04, 0, 0.28, 0),
			cmd = function()
				if actionsPlayerInput.Text ~= "" then
					adminKill:FireServer(actionsPlayerInput.Text)
				end
			end,
		},
		{
			text = "KICK",
			color = Color3.fromRGB(150, 0, 0),
			pos = UDim2.new(0.54, 0, 0.28, 0),
			cmd = function()
				if actionsPlayerInput.Text ~= "" then
					adminKick:FireServer(actionsPlayerInput.Text, "Expulso por admin")
				end
			end,
		},
		{
			text = "TP SAFEZONE",
			color = Color3.fromRGB(0, 100, 200),
			pos = UDim2.new(0.04, 0, 0.44, 0),
			cmd = function()
				if actionsPlayerInput.Text ~= "" then
					adminTeleport:FireServer(actionsPlayerInput.Text, "SafeZone")
				end
			end,
		},
		{
			text = "TP SPAWN",
			color = Color3.fromRGB(0, 80, 160),
			pos = UDim2.new(0.54, 0, 0.44, 0),
			cmd = function()
				if actionsPlayerInput.Text ~= "" then
					adminTeleport:FireServer(actionsPlayerInput.Text, "Spawn")
				end
			end,
		},
		{
			text = "RESET DADOS",
			color = COLORS.error,
			pos = UDim2.new(0.04, 0, 0.60, 0),
			cmd = function()
				if actionsPlayerInput.Text ~= "" then
					adminResetData:FireServer(actionsPlayerInput.Text)
				end
			end,
		},
	}

	for _, action in ipairs(actions) do
		local actionButton = Instance.new("TextButton")
		actionButton.Size = UDim2.new(0.4, 0, 0.12, 0)
		actionButton.Position = action.pos
		actionButton.BackgroundColor3 = action.color
		actionButton.BorderColor3 = COLORS.border
		actionButton.BorderSizePixel = 2
		actionButton.Text = action.text
		actionButton.TextColor3 = COLORS.border
		actionButton.TextScaled = true
		actionButton.Font = Enum.Font.Arcade
		actionButton.Parent = actionsContent

		local actionCorner = Instance.new("UICorner")
		actionCorner.CornerRadius = UDim.new(0, 4)
		actionCorner.Parent = actionButton

		local capturedCmd = action.cmd
		actionButton.MouseButton1Click:Connect(function()
			playSound(sounds.click)
			capturedCmd()
		end)
	end

	-- ============================
	-- LOGICA DE ABRIR/FECHAR
	-- ============================

	local function toggleMenu()
		isOpen = not isOpen
		mainFrame.Visible = isOpen
		playSound(isOpen and sounds.open or sounds.close)
		if isOpen then
			task.spawn(updatePlayersList)
		end
	end

	-- openButton.Click REMOVIDO (Menu Unificado controla)
	closeButton.MouseButton1Click:Connect(toggleMenu)

	-- Auto-refresh da lista de jogadores a cada 5s enquanto aberto
	task.spawn(function()
		while screenGui and screenGui.Parent do
			task.wait(5)
			if isOpen then
				pcall(updatePlayersList)
			end
		end
	end)

	-- Carga inicial
	task.spawn(updatePlayersList)
end

-- Criar interface uma unica vez
createAdminInterface()

print([[
╔════════════════════════════════════════════════════╗
║  ✅ ADMIN MENU CLIENT V6 CARREGADO                ║
╠════════════════════════════════════════════════════╣
║  SUBSTITUI: ADMIN_MENU_CLIENT_V4                  ║
╠════════════════════════════════════════════════════╣
║  CORRECOES V5:                                     ║
║  • REMOVIDO keybind F9 (conflitava com Tools)     ║
║  • selectButton sincroniza TODOS os inputs        ║
║  • task.spawn / task.wait                         ║
║  • Criado apenas uma vez (sem duplicatas)         ║
║  • Aba Jogadores com kills + char + inventario    ║
╚════════════════════════════════════════════════════╝
]])

-- =====================================
-- REGISTRAR NO MENU UNIFICADO
-- =====================================

_G.OpenAdminMenu = function()
	if not screenGui or not screenGui.Parent then
		createAdminInterface()
	end
	if mainFrame then
		mainFrame.Visible = true
		isOpen = true
	end
end

_G.CloseAdminMenu = function()
	if mainFrame then
		mainFrame.Visible = false
		isOpen = false
	end
end

task.spawn(function()
	local timeout = 0
	while not _G.RegisterMenuCategory and timeout < 15 do
		task.wait(0.5)
		timeout = timeout + 0.5
	end
	if _G.RegisterMenuCategory then
		_G.RegisterMenuCategory("ADMIN", "⚙️", function()
			if _G.OpenAdminMenu then
				_G.OpenAdminMenu()
			end
		end, function()
			if _G.CloseAdminMenu then
				_G.CloseAdminMenu()
			end
		end, 9)
		print("[ADMIN V6] Registrado no Menu Unificado: ADMIN")
	end
end)
