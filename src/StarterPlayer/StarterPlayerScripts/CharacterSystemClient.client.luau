-- ============================================
-- CHARACTER SYSTEM CLIENT V3 — SEM BOTÕES PRÓPRIOS
-- Coloque em StarterPlayer > StarterPlayerScripts
-- Nome: "CharacterSystemClient"
-- SUBSTITUI: CHARACTER_SYSTEM_CLIENT_V2
-- REMOVER:   CHARACTER_SYSTEM_CLIENT_V2
-- ============================================
-- NOVIDADES V3:
-- * BOTÕES PRÓPRIOS REMOVIDOS (usa Menu Unificado)
-- * Registra LOJA e INVENTÁRIO via _G.RegisterMenuCategory
-- * _G.OpenCharacterShop() / _G.OpenCharacterInventory()
-- * Mantém: Venda 25%, popups, despertar, metadados V4
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[CHAR SYSTEM V2] Inicializando sistema unificado com venda...")

-- =====================================
-- DETECÇÃO DE PLATAFORMA
-- =====================================

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isTablet = isMobile and (workspace.CurrentCamera.ViewportSize.X > 600)

-- =====================================
-- AGUARDAR REMOTES
-- =====================================

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local selectCharacterRemote = remotes:WaitForChild("SelectCharacter")
local purchaseCharacterRemote = remotes:WaitForChild("PurchaseCharacter")
local getPlayerDataRemote = remotes:WaitForChild("GetPlayerData")
local checkAwakeningRemote = remotes:WaitForChild("CheckAwakening", 10)
local equipAwakeningRemote = remotes:WaitForChild("EquipAwakening", 10)
local syncCharacterStateRemote = remotes:WaitForChild("SyncCharacterState", 10)
local sellCharacterRemote = remotes:WaitForChild("SellCharacter", 10)

-- =====================================
-- SISTEMA DE IMAGENS
-- =====================================

local CharacterImages = ReplicatedStorage:WaitForChild("CharacterImages", 10)
if not CharacterImages then
	CharacterImages = Instance.new("Folder")
	CharacterImages.Name = "CharacterImages"
	CharacterImages.Parent = ReplicatedStorage
end

local function getCharacterImageId(characterName)
	if not CharacterImages then
		return nil
	end
	local obj = CharacterImages:FindFirstChild(characterName)
	if obj and obj:IsA("ImageLabel") then
		return obj.Image
	end
	if obj and obj:IsA("StringValue") then
		return obj.Value
	end
	return nil
end

local function createCharacterImage(characterName, parentFrame)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.Parent = parentFrame

	local imageId = getCharacterImageId(characterName)

	if imageId and imageId ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(1, 0, 1, 0)
		img.BackgroundTransparency = 1
		img.Image = imageId
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = container
	else
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.new(1, 0, 0.75, 0)
		placeholder.BackgroundTransparency = 1
		placeholder.Text = "?"
		placeholder.TextColor3 = Color3.fromRGB(100, 100, 100)
		placeholder.TextScaled = true
		placeholder.Font = Enum.Font.Arcade
		placeholder.Parent = container
	end

	return container
end

-- =====================================
-- SONS
-- =====================================

local sounds = {
	hover = "rbxassetid://12846056",
	click = "rbxassetid://156785206",
	purchase = "rbxassetid://5031873608",
	error = "rbxassetid://2865228021",
	open = "rbxassetid://157167203",
	close = "rbxassetid://157167205",
	info = "rbxassetid://156785206",
	awakening = "rbxassetid://5031873608",
	sell = "rbxassetid://5031873608",
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
-- SISTEMA DE TAMANHOS
-- =====================================

local UI_SIZES = { SMALL = "Pequeno", MEDIUM = "Médio", LARGE = "Grande" }
local currentUISize = UI_SIZES.MEDIUM

local function getUIScale()
	local viewport = workspace.CurrentCamera.ViewportSize
	local baseScale

	if isTablet then
		baseScale = {
			menu = { small = 0.75, medium = 0.85, large = 0.95 },
			button = { small = 0.10, medium = 0.12, large = 0.14 },
			card = {
				width = { small = 140, medium = 160, large = 180 },
				height = { small = 240, medium = 260, large = 280 },
				columns = 3,
				spacing = { small = 8, medium = 10, large = 12 },
			},
		}
	elseif isMobile then
		baseScale = {
			menu = { small = 0.85, medium = 0.92, large = 0.98 },
			button = { small = 0.12, medium = 0.15, large = 0.18 },
			card = {
				width = {
					small = math.floor(viewport.X * 0.40),
					medium = math.floor(viewport.X * 0.45),
					large = math.floor(viewport.X * 0.48),
				},
				height = { small = 220, medium = 240, large = 260 },
				columns = 2,
				spacing = { small = 8, medium = 10, large = 15 },
			},
		}
	else
		baseScale = {
			menu = { small = 0.65, medium = 0.75, large = 0.85 },
			button = { small = 0.08, medium = 0.10, large = 0.12 },
			card = {
				width = { small = 110, medium = 130, large = 150 },
				height = { small = 220, medium = 240, large = 260 },
				columns = 4,
				spacing = { small = 6, medium = 8, large = 10 },
			},
		}
	end

	local size = currentUISize == UI_SIZES.SMALL and "small"
		or (currentUISize == UI_SIZES.LARGE and "large" or "medium")

	return {
		menu = UDim2.new(baseScale.menu[size], 0, baseScale.menu[size], 0),
		button = UDim2.new(baseScale.button[size], 0, baseScale.button[size] * 0.65, 0),
		card = {
			width = baseScale.card.width[size],
			height = baseScale.card.height[size],
			columns = baseScale.card.columns,
			spacing = baseScale.card.spacing[size],
		},
	}
end

local uiScale = getUIScale()

-- =====================================
-- RARIDADES
-- =====================================

local rarities = {
	ROBLOXIANOS = { color = Color3.fromRGB(100, 100, 100), order = 1 },
	HEROXIANOS = { color = Color3.fromRGB(0, 170, 255), order = 2 },
	NULLXIANOS = { color = Color3.fromRGB(170, 0, 170), order = 3 },
	BTUDIOS = { color = Color3.fromRGB(255, 170, 0), order = 4 },
	BOSSXIANOS = { color = Color3.fromRGB(255, 0, 0), order = 5 },
	SUPREMO = { color = Color3.fromRGB(255, 215, 0), order = 6, glow = true },
	AWAKENED = { color = Color3.fromRGB(255, 0, 255), order = 7, glow = true, special = true },
}

-- =====================================
-- DADOS DE PERSONAGENS
-- =====================================

local characterData = {
	Loja = {
		{
			name = "Noob",
			price = 0,
			description = "Personagem inicial",
			rarity = "ROBLOXIANOS",
		},
		{
			name = "Guest",
			price = 50,
			description = "Personagem comum",
			rarity = "ROBLOXIANOS",
		},
		{
			name = "Danilo",
			price = 200,
			description = "Personagem Do escudo",
			rarity = "HEROXIANOS",
		},
		{
			name = "Shushuhus8",
			price = 250,
			description = "Personagem Do Som",
			rarity = "HEROXIANOS",
		},
		{
			name = "Gui Bomba",
			price = 300,
			description = "Personagem Da bomba",
			rarity = "HEROXIANOS",
		},
		{
			name = "Dark Jc",
			price = 500,
			description = "Personagem Do Void",
			rarity = "HEROXIANOS",
		},
	},
	Recompensa = {
		-- Adicione personagens de bounty aqui (veja GUIA_ADICIONAR_PERSONAGENS.md)
		-- Exemplo: {name = "Maria", bounty = 2500, price = 0, description = "Personagem de recompensa", rarity = "HEROXIANOS"},
	},
	Gamepass = {
		{
			name = "Faker Gui",
			price = 0,
			description = "Solidão.....",
			rarity = "NULLXIANOS",
			gamepassId = 1247245466,
		},
		{
			name = "Alma Perdida",
			price = 0,
			description = "Corrupção.....",
			rarity = "NULLXIANOS",
			gamepassId = 1161544217,
		},
	},
}

local characterInfo = {
	Noob = {
		abilities = {
			"🗡️ Espada Classica",
			"🛡️ Escudo noob",
			"🥤 Bloxy Cola",
			"💣 Bomba Classica",
			"🪃 Estilingue Classico",
			"🚀 Lança Foguetes",
		},
		stats = "❤️ HP: 100 | ⚔️ Dano: Médio |🛡️ Defesa: Basica ",
		lore = "O clássico aventureiro do Roblox.",
	},
}

local defaultInfo = {
	abilities = { "❓ Desconhecido" },
	stats = "❤️ HP: ???",
	lore = "Sem informações.",
}

-- =====================================
-- VARIÁVEIS
-- =====================================

local playerData = {
	coins = 0,
	ownedCharacters = { "Noob" },
	ownedCharactersDetailed = {}, -- NOVO V2: lista com metadados
	awakenedCharacters = {},
	equippedCharacter = nil,
	stats = { bounty = 0, deaths = 0 },
}

local systemGui = nil
local mainFrame = nil
local contentFrame = nil
local invFrame = nil
local invScroll = nil

local isMenuOpen = false
local isInvOpen = false
local selectedCategory = "Loja"

-- Forward declarations
local createSystem
local updatePlayerData
local createCharacterCard

-- =====================================
-- NOTIFICAÇÃO
-- =====================================

local function notify(message, isSuccess)
	playSound(isSuccess and sounds.purchase or sounds.error)

	local notification = Instance.new("Frame")
	notification.Size = isMobile and UDim2.new(0.8, 0, 0.12, 0) or UDim2.new(0.4, 0, 0.08, 0)
	notification.Position = isMobile and UDim2.new(0.1, 0, 0.05, 0) or UDim2.new(0.3, 0, 0.05, 0)
	notification.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	notification.BorderColor3 = isSuccess and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	notification.BorderSizePixel = 3
	notification.ZIndex = 50
	notification.Parent = systemGui or playerGui

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.Arcade
	text.ZIndex = 50
	text.Parent = notification

	task.delay(3, function()
		if notification.Parent then
			notification.Parent = nil
		end
	end)
end

-- =====================================
-- ATUALIZAR DADOS DO JOGADOR
-- =====================================

updatePlayerData = function()
	pcall(function()
		local data = getPlayerDataRemote:InvokeServer()
		if data then
			playerData.coins = data.coins or 0
			playerData.ownedCharacters = data.ownedCharacters or { "Noob" }
			playerData.ownedCharactersDetailed = data.ownedCharactersDetailed or {}
			playerData.awakenedCharacters = data.awakenedCharacters or {}
			playerData.stats = data.stats or { bounty = 0, deaths = 0 }
			playerData.equippedCharacter = data.equippedCharacter
		end
	end)
end

local function playerOwnsCharacter(characterName)
	if characterName == "Noob" then
		return true
	end
	return table.find(playerData.ownedCharacters, characterName) ~= nil
end

-- =====================================
-- FUNÇÕES DE METADADOS V4 (NOVO V2)
-- =====================================

-- Buscar metadados detalhados de um personagem
local function getCharacterDetails(characterName)
	for _, charObj in ipairs(playerData.ownedCharactersDetailed) do
		if type(charObj) == "table" and charObj.name == characterName then
			return charObj
		end
	end
	return nil
end

-- Verificar se pode vender
local function canSellCharacter(characterName)
	local details = getCharacterDetails(characterName)
	if not details then
		return false, nil, "Dados não encontrados"
	end
	if not details.sellable then
		return false, nil, "Não vendável"
	end
	if not details.originalPrice or details.originalPrice <= 0 then
		return false, nil, "Sem valor"
	end
	if playerData.equippedCharacter == characterName then
		return false, nil, "Equipado"
	end
	local sellPrice = math.floor(details.originalPrice * 0.25)
	return true, sellPrice, details.id
end

-- =====================================
-- SINCRONIZAÇÃO DO SERVIDOR
-- =====================================

if syncCharacterStateRemote then
	syncCharacterStateRemote.OnClientEvent:Connect(function(characterName, isEquipped)
		if isEquipped then
			playerData.equippedCharacter = characterName
		else
			playerData.equippedCharacter = nil
		end
		if systemGui and mainFrame and mainFrame.Visible then
			local f = systemGui:FindFirstChild("RefreshCategory", true)
			if f and f:IsA("BindableFunction") then
				pcall(function()
					f:Invoke()
				end)
			end
		end
		if systemGui and invFrame and invFrame.Visible then
			local f = systemGui:FindFirstChild("RefreshInventory", true)
			if f and f:IsA("BindableFunction") then
				pcall(function()
					f:Invoke()
				end)
			end
		end
	end)
end

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		playerData.equippedCharacter = nil
		task.wait(1)
		updatePlayerData()
		if systemGui then
			local f = systemGui:FindFirstChild("RefreshCategory", true)
			if f and f:IsA("BindableFunction") then
				pcall(function()
					f:Invoke()
				end)
			end
			local g = systemGui:FindFirstChild("RefreshInventory", true)
			if g and g:IsA("BindableFunction") then
				pcall(function()
					g:Invoke()
				end)
			end
		end
	end)
end)

-- =====================================
-- POPUP - CONFIRMAÇÃO DE VENDA (NOVO V2)
-- =====================================

local function createSellConfirmPopup(characterName, sellPrice, charId)
	playSound(sounds.info)

	local sellGui = Instance.new("ScreenGui")
	sellGui.Name = "SellConfirmPopup"
	sellGui.DisplayOrder = 150
	sellGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = sellGui

	local popup = Instance.new("Frame")
	popup.Size = isMobile and UDim2.new(0.85, 0, 0.4, 0) or UDim2.new(0.4, 0, 0.35, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	popup.BorderColor3 = Color3.fromRGB(255, 200, 0)
	popup.BorderSizePixel = 4
	popup.Parent = sellGui

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.2, 0)
	header.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	header.BorderSizePixel = 0
	header.Parent = popup

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "💰 VENDER PERSONAGEM"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Parent = header

	-- Conteúdo
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Vender " .. characterName .. "?"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = popup

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	priceLabel.Position = UDim2.new(0.05, 0, 0.42, 0)
	priceLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	priceLabel.BorderSizePixel = 0
	priceLabel.Text = "Você receberá: 💰 " .. sellPrice .. " moedas (25%)"
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.SourceSansBold
	priceLabel.Parent = popup

	local warningLabel = Instance.new("TextLabel")
	warningLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	warningLabel.Position = UDim2.new(0.05, 0, 0.58, 0)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Text = "Esta ação é irreversível!"
	warningLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	warningLabel.TextScaled = true
	warningLabel.Font = Enum.Font.SourceSans
	warningLabel.Parent = popup

	-- Botão Confirmar
	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(0.4, 0, 0.15, 0)
	confirmButton.Position = UDim2.new(0.05, 0, 0.72, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	confirmButton.BorderSizePixel = 0
	confirmButton.Text = "✅ CONFIRMAR"
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	confirmButton.TextScaled = true
	confirmButton.Font = Enum.Font.Arcade
	confirmButton.Parent = popup

	-- Botão Cancelar
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0.4, 0, 0.15, 0)
	cancelButton.Position = UDim2.new(0.55, 0, 0.72, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "❌ CANCELAR"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.Arcade
	cancelButton.Parent = popup

	local processing = false

	confirmButton.MouseButton1Click:Connect(function()
		if processing then
			return
		end
		processing = true
		confirmButton.Text = "..."

		if sellCharacterRemote then
			local ok, success, message, finalPrice = pcall(function()
				return sellCharacterRemote:InvokeServer(charId)
			end)

			if ok and success then
				playSound(sounds.sell)
				notify("✅ " .. (message or "Vendido com sucesso!"), true)
				task.wait(0.3)
				updatePlayerData()
				if systemGui then
					local f = systemGui:FindFirstChild("RefreshInventory", true)
					if f and f:IsA("BindableFunction") then
						pcall(function()
							f:Invoke()
						end)
					end
					local g = systemGui:FindFirstChild("RefreshCategory", true)
					if g and g:IsA("BindableFunction") then
						pcall(function()
							g:Invoke()
						end)
					end
				end
			else
				notify("❌ " .. (message or "Erro na venda"), false)
			end
		else
			notify("❌ Sistema de venda indisponível!", false)
		end

		sellGui.Parent = nil
	end)

	cancelButton.MouseButton1Click:Connect(function()
		playSound(sounds.close)
		sellGui.Parent = nil
	end)

	background.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			playSound(sounds.close)
			sellGui.Parent = nil
		end
	end)
end

-- =====================================
-- POPUPS - HABILIDADES / LORE / DESPERTAR
-- (Mantidos iguais ao V1)
-- =====================================

local function createAbilitiesPopup(characterName)
	playSound(sounds.info)
	local info = characterInfo[characterName] or defaultInfo
	local infoGui = Instance.new("ScreenGui")
	infoGui.Name = "AbilitiesPopup"
	infoGui.DisplayOrder = 100
	infoGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = infoGui

	local popup = Instance.new("Frame")
	popup.Size = isMobile and UDim2.new(0.9, 0, 0.7, 0) or UDim2.new(0.5, 0, 0.6, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	popup.BorderColor3 = Color3.fromRGB(0, 200, 0)
	popup.BorderSizePixel = 4
	popup.Parent = infoGui

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.15, 0)
	header.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	header.BorderSizePixel = 0
	header.Parent = popup

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.85, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ " .. characterName:upper() .. " - HABILIDADES"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.1, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.88, 0, 0.1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = header

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(0.96, 0, 0.12, 0)
	statsLabel.Position = UDim2.new(0.02, 0, 0.17, 0)
	statsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statsLabel.BorderSizePixel = 0
	statsLabel.Text = info.stats
	statsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.SourceSansBold
	statsLabel.Parent = popup

	local abilitiesScroll = Instance.new("ScrollingFrame")
	abilitiesScroll.Size = UDim2.new(0.96, 0, 0.65, 0)
	abilitiesScroll.Position = UDim2.new(0.02, 0, 0.31, 0)
	abilitiesScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	abilitiesScroll.BorderSizePixel = 0
	abilitiesScroll.ScrollBarThickness = 8
	abilitiesScroll.Parent = popup

	local yPos = 5
	for _, ability in ipairs(info.abilities) do
		local abilityFrame = Instance.new("Frame")
		abilityFrame.Size = UDim2.new(0.96, 0, 0, 50)
		abilityFrame.Position = UDim2.new(0.02, 0, 0, yPos)
		abilityFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		abilityFrame.BorderSizePixel = 0
		abilityFrame.Parent = abilitiesScroll

		local abilityText = Instance.new("TextLabel")
		abilityText.Size = UDim2.new(0.95, 0, 1, 0)
		abilityText.Position = UDim2.new(0.025, 0, 0, 0)
		abilityText.BackgroundTransparency = 1
		abilityText.Text = ability
		abilityText.TextColor3 = Color3.new(1, 1, 1)
		abilityText.TextScaled = true
		abilityText.Font = Enum.Font.SourceSans
		abilityText.TextXAlignment = Enum.TextXAlignment.Left
		abilityText.Parent = abilityFrame

		yPos = yPos + 55
	end
	abilitiesScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)

	closeButton.MouseButton1Click:Connect(function()
		playSound(sounds.close)
		infoGui.Parent = nil
	end)
	background.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			infoGui.Parent = nil
		end
	end)
end

local function createLorePopup(characterName)
	playSound(sounds.info)
	local info = characterInfo[characterName] or defaultInfo
	local infoGui = Instance.new("ScreenGui")
	infoGui.Name = "LorePopup"
	infoGui.DisplayOrder = 100
	infoGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = infoGui

	local popup = Instance.new("Frame")
	popup.Size = isMobile and UDim2.new(0.9, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.4, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	popup.BorderColor3 = Color3.fromRGB(200, 150, 0)
	popup.BorderSizePixel = 4
	popup.Parent = infoGui

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.2, 0)
	header.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
	header.BorderSizePixel = 0
	header.Parent = popup

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.85, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📖 " .. characterName:upper()
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.12, 0, 0.75, 0)
	closeButton.Position = UDim2.new(0.86, 0, 0.125, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = header

	local loreText = Instance.new("TextLabel")
	loreText.Size = UDim2.new(0.9, 0, 0.7, 0)
	loreText.Position = UDim2.new(0.05, 0, 0.25, 0)
	loreText.BackgroundTransparency = 1
	loreText.Text = info.lore
	loreText.TextColor3 = Color3.new(1, 1, 1)
	loreText.TextScaled = true
	loreText.Font = Enum.Font.SourceSans
	loreText.TextWrapped = true
	loreText.Parent = popup

	closeButton.MouseButton1Click:Connect(function()
		playSound(sounds.close)
		infoGui.Parent = nil
	end)
	background.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			infoGui.Parent = nil
		end
	end)
end

-- =====================================
-- BOTÃO DE DESPERTAR (mantido V1)
-- =====================================

local function createAwakeningButton(charData, card)
	if not checkAwakeningRemote then
		return
	end

	local success, awakeningInfo = pcall(function()
		return checkAwakeningRemote:InvokeServer(charData.name)
	end)
	if not success or not awakeningInfo or not awakeningInfo.exists then
		return
	end

	local awakeningButton = Instance.new("TextButton")
	awakeningButton.Size = UDim2.new(0.45, 0, 0.07, 0)
	awakeningButton.Position = UDim2.new(0.05, 0, 0.915, 0)
	awakeningButton.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
	awakeningButton.BorderColor3 = Color3.fromRGB(255, 0, 255)
	awakeningButton.BorderSizePixel = 2
	awakeningButton.TextScaled = true
	awakeningButton.Font = Enum.Font.Arcade
	awakeningButton.ZIndex = 10
	awakeningButton.Parent = card

	if awakeningInfo.hasAwakening then
		if awakeningInfo.hasOriginal then
			awakeningButton.Text = "⚡ DESPERTAR"
			awakeningButton.TextColor3 = Color3.fromRGB(255, 255, 0)
		else
			awakeningButton.Text = "🔒 VER"
			awakeningButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	else
		awakeningButton.Text = "❓ INFO"
		awakeningButton.TextColor3 = Color3.fromRGB(100, 100, 100)
	end

	awakeningButton.MouseButton1Click:Connect(function()
		playSound(sounds.awakening)
		if awakeningInfo.hasAwakening and awakeningInfo.hasOriginal and awakeningInfo.canEquip then
			if equipAwakeningRemote then
				equipAwakeningRemote:FireServer(charData.name)
				notify("⚡ Despertar equipado!", true)
			end
		else
			-- Não chamamos createAwakeningPopup aqui para manter V2 leve
			-- Pode ser adicionado novamente se necessário
			notify(
				"⚡ "
					.. (
						awakeningInfo.awakening and awakeningInfo.awakening.displayName
						or "Despertar"
					),
				true
			)
		end
	end)

	if awakeningInfo.hasAwakening and awakeningInfo.hasOriginal then
		task.spawn(function()
			while awakeningButton.Parent do
				TweenService:Create(
					awakeningButton,
					TweenInfo.new(1, Enum.EasingStyle.Sine),
					{ BackgroundColor3 = Color3.fromRGB(150, 0, 150) }
				):Play()
				task.wait(1)
				TweenService:Create(
					awakeningButton,
					TweenInfo.new(1, Enum.EasingStyle.Sine),
					{ BackgroundColor3 = Color3.fromRGB(100, 0, 100) }
				):Play()
				task.wait(1)
			end
		end)
	end
end

-- =====================================
-- CARD DE PERSONAGEM V2
-- Agora com botão VENDER no inventário
-- =====================================

createCharacterCard = function(charData, parentFrame, cardConfig, isInventoryMode)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, cardConfig.width, 0, cardConfig.height)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	card.Parent = parentFrame

	local rarityColor = rarities[charData.rarity] and rarities[charData.rarity].color
		or Color3.fromRGB(100, 100, 100)
	card.BorderColor3 = rarityColor
	card.BorderSizePixel = 3

	-- Efeito AWAKENED
	if charData.rarity == "AWAKENED" then
		task.spawn(function()
			while card.Parent do
				TweenService:Create(
					card,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine),
					{ BorderColor3 = Color3.fromRGB(200, 0, 200) }
				):Play()
				task.wait(1.5)
				TweenService:Create(
					card,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine),
					{ BorderColor3 = Color3.fromRGB(255, 0, 255) }
				):Play()
				task.wait(1.5)
			end
		end)
	end

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.15, 0)
	header.BackgroundColor3 = rarityColor
	header.BorderSizePixel = 0
	header.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = charData.name:upper()
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Arcade
	nameLabel.Parent = header

	-- Imagem
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0.96, 0, 0.38, 0)
	imageContainer.Position = UDim2.new(0.02, 0, 0.17, 0)
	imageContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	imageContainer.BorderSizePixel = 0
	imageContainer.ClipsDescendants = true
	imageContainer.Parent = card

	createCharacterImage(charData.name, imageContainer)

	-- Descrição
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.96, 0, 0.07, 0)
	descLabel.Position = UDim2.new(0.02, 0, 0.56, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = charData.description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.Parent = card

	-- Raridade
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.96, 0, 0.05, 0)
	rarityLabel.Position = UDim2.new(0.02, 0, 0.64, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = charData.rarity
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = card

	-- Status / Preço
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.96, 0, 0.06, 0)
	statusLabel.Position = UDim2.new(0.02, 0, 0.70, 0)
	statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	statusLabel.BorderSizePixel = 0
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSansBold
	statusLabel.Parent = card

	local isOwned = playerOwnsCharacter(charData.name)
	local isEquipped = playerData.equippedCharacter == charData.name

	if isInventoryMode then
		statusLabel.Text = "✅ ADQUIRIDO"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	else
		statusLabel.Text = "💰 " .. (charData.price or 0)
		statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	end

	-- ========== BOTÕES DE AÇÃO ==========

	local isEquippedNow = isEquipped

	-- Botão EQUIPAR / COMPRAR
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(0.44, 0, 0.07, 0)
	actionButton.Position = UDim2.new(0.02, 0, 0.78, 0)
	actionButton.TextScaled = true
	actionButton.Font = Enum.Font.Arcade
	actionButton.BorderSizePixel = 0
	actionButton.Parent = card

	if isEquippedNow then
		actionButton.Text = "✅ EQUIPADO"
		actionButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
		actionButton.TextColor3 = Color3.new(1, 1, 1)
	elseif isOwned or isInventoryMode then
		actionButton.Text = "▶ EQUIPAR"
		actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		actionButton.TextColor3 = Color3.new(1, 1, 1)
	else
		actionButton.Text = "💰 COMPRAR"
		actionButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		actionButton.TextColor3 = Color3.new(1, 1, 1)
	end

	actionButton.MouseButton1Click:Connect(function()
		playSound(sounds.click)
		if isEquippedNow then
			return
		end

		if isOwned or isInventoryMode then
			local ok, result = pcall(function()
				return selectCharacterRemote:InvokeServer(charData.name)
			end)
			if ok and result then
				notify("✅ " .. charData.name .. " equipado!", true)
				task.wait(0.5)
				updatePlayerData()
				if systemGui then
					local f = systemGui:FindFirstChild("RefreshCategory", true)
					if f and f:IsA("BindableFunction") then
						pcall(function()
							f:Invoke()
						end)
					end
					local g = systemGui:FindFirstChild("RefreshInventory", true)
					if g and g:IsA("BindableFunction") then
						pcall(function()
							g:Invoke()
						end)
					end
				end
			else
				notify("❌ " .. (result or "Erro ao equipar"), false)
			end
		else
			local ok, result = pcall(function()
				return purchaseCharacterRemote:InvokeServer(charData.name)
			end)
			if ok and result then
				notify("✅ " .. charData.name .. " comprado!", true)
				updatePlayerData()
				if systemGui then
					local f = systemGui:FindFirstChild("RefreshCategory", true)
					if f and f:IsA("BindableFunction") then
						pcall(function()
							f:Invoke()
						end)
					end
				end
			else
				notify("❌ " .. (result or "Erro na compra"), false)
			end
		end
	end)

	-- ========== BOTÃO VENDER (NOVO V2) ==========
	-- Só aparece no inventário

	if isInventoryMode and sellCharacterRemote then
		local canSell, sellPrice, charId = canSellCharacter(charData.name)

		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0.25, 0, 0.07, 0)
		sellButton.Position = UDim2.new(0.48, 0, 0.78, 0)
		sellButton.TextScaled = true
		sellButton.Font = Enum.Font.Arcade
		sellButton.BorderSizePixel = 0
		sellButton.Parent = card

		if canSell and sellPrice and sellPrice > 0 then
			sellButton.Text = "💰 " .. sellPrice
			sellButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
			sellButton.TextColor3 = Color3.new(1, 1, 1)

			sellButton.MouseButton1Click:Connect(function()
				playSound(sounds.click)
				createSellConfirmPopup(charData.name, sellPrice, charId)
			end)
		else
			sellButton.Text = "🔒"
			sellButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			sellButton.TextColor3 = Color3.fromRGB(100, 100, 100)
			-- Sem ação — não vendável
		end

		-- Reposicionar botões ⚔️ e 📖 para dar espaço
		local infoButton = Instance.new("TextButton")
		infoButton.Size = UDim2.new(0.12, 0, 0.07, 0)
		infoButton.Position = UDim2.new(0.75, 0, 0.78, 0)
		infoButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		infoButton.BorderSizePixel = 0
		infoButton.Text = "⚔️"
		infoButton.TextScaled = true
		infoButton.Font = Enum.Font.SourceSansBold
		infoButton.Parent = card

		infoButton.MouseButton1Click:Connect(function()
			createAbilitiesPopup(charData.name)
		end)

		local loreButton = Instance.new("TextButton")
		loreButton.Size = UDim2.new(0.12, 0, 0.07, 0)
		loreButton.Position = UDim2.new(0.87, 0, 0.78, 0)
		loreButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
		loreButton.BorderSizePixel = 0
		loreButton.Text = "📖"
		loreButton.TextScaled = true
		loreButton.Font = Enum.Font.SourceSansBold
		loreButton.Parent = card

		loreButton.MouseButton1Click:Connect(function()
			createLorePopup(charData.name)
		end)
	else
		-- Layout padrão (loja) — sem botão vender
		local infoButton = Instance.new("TextButton")
		infoButton.Size = UDim2.new(0.2, 0, 0.07, 0)
		infoButton.Position = UDim2.new(0.52, 0, 0.78, 0)
		infoButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		infoButton.BorderSizePixel = 0
		infoButton.Text = "⚔️"
		infoButton.TextScaled = true
		infoButton.Font = Enum.Font.SourceSansBold
		infoButton.Parent = card

		infoButton.MouseButton1Click:Connect(function()
			createAbilitiesPopup(charData.name)
		end)

		local loreButton = Instance.new("TextButton")
		loreButton.Size = UDim2.new(0.2, 0, 0.07, 0)
		loreButton.Position = UDim2.new(0.75, 0, 0.78, 0)
		loreButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
		loreButton.BorderSizePixel = 0
		loreButton.Text = "📖"
		loreButton.TextScaled = true
		loreButton.Font = Enum.Font.SourceSansBold
		loreButton.Parent = card

		loreButton.MouseButton1Click:Connect(function()
			createLorePopup(charData.name)
		end)
	end

	-- Despertar
	createAwakeningButton(charData, card)

	return card
end

-- =====================================
-- CRIAR SISTEMA UNIFICADO V2
-- =====================================

createSystem = function()
	if systemGui then
		systemGui.Parent = nil
	end

	systemGui = Instance.new("ScreenGui")
	systemGui.Name = "CharacterSystemV3"
	systemGui.ResetOnSpawn = false
	systemGui.IgnoreGuiInset = true
	systemGui.Parent = playerGui

	-- ─────────────────────────────────────
	-- BOTÕES REMOVIDOS (Menu Unificado controla)
	-- ─────────────────────────────────────

	-- ─────────────────────────────────────
	-- FRAME PRINCIPAL - LOJA
	-- ─────────────────────────────────────

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = uiScale.menu
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.BorderSizePixel = 4
	mainFrame.Visible = false
	mainFrame.Parent = systemGui

	local menuHeader = Instance.new("Frame")
	menuHeader.Size = UDim2.new(1, 0, 0.08, 0)
	menuHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	menuHeader.BorderSizePixel = 0
	menuHeader.Parent = mainFrame

	local menuTitle = Instance.new("TextLabel")
	menuTitle.Size = UDim2.new(0.7, 0, 1, 0)
	menuTitle.BackgroundTransparency = 1
	menuTitle.Text = "🧑 MENU DE PERSONAGENS"
	menuTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	menuTitle.TextScaled = true
	menuTitle.Font = Enum.Font.Arcade
	menuTitle.Parent = menuHeader

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
	coinsLabel.Position = UDim2.new(0.70, 0, 0.1, 0)
	coinsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	coinsLabel.BorderSizePixel = 0
	coinsLabel.Text = "💰 " .. playerData.coins
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.Arcade
	coinsLabel.Parent = menuHeader

	local menuClose = Instance.new("TextButton")
	menuClose.Size = UDim2.new(0.08, 0, 0.8, 0)
	menuClose.Position = UDim2.new(0.91, 0, 0.1, 0)
	menuClose.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	menuClose.BorderSizePixel = 0
	menuClose.Text = "X"
	menuClose.TextColor3 = Color3.new(1, 1, 1)
	menuClose.TextScaled = true
	menuClose.Font = Enum.Font.Arcade
	menuClose.Parent = menuHeader

	-- Tabs de categoria
	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(1, 0, 0.06, 0)
	tabFrame.Position = UDim2.new(0, 0, 0.08, 0)
	tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tabFrame.BorderSizePixel = 0
	tabFrame.Parent = mainFrame

	local categories = { "Loja", "Recompensa", "Gamepass" }
	local tabWidth = 1 / #categories

	contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Size = UDim2.new(0.98, 0, 0.84, 0)
	contentFrame.Position = UDim2.new(0.01, 0, 0.15, 0)
	contentFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	contentFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.BorderSizePixel = 2
	contentFrame.ScrollBarThickness = isMobile and 8 or 12
	contentFrame.Parent = mainFrame

	for i, category in ipairs(categories) do
		local tabButton = Instance.new("TextButton")
		tabButton.Size = UDim2.new(tabWidth, 0, 1, 0)
		tabButton.Position = UDim2.new((i - 1) * tabWidth, 0, 0, 0)
		tabButton.BackgroundColor3 = selectedCategory == category and Color3.fromRGB(200, 150, 0)
			or Color3.fromRGB(40, 40, 40)
		tabButton.BorderSizePixel = 0
		tabButton.Text = category:upper()
		tabButton.TextColor3 = selectedCategory == category and Color3.fromRGB(20, 20, 20)
			or Color3.new(1, 1, 1)
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.Arcade
		tabButton.Parent = tabFrame

		tabButton.MouseButton1Click:Connect(function()
			playSound(sounds.click)
			selectedCategory = category
			for _, btn in pairs(tabFrame:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					btn.TextColor3 = Color3.new(1, 1, 1)
				end
			end
			tabButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
			tabButton.TextColor3 = Color3.fromRGB(20, 20, 20)
			local f = systemGui:FindFirstChild("RefreshCategory")
			if f and f:IsA("BindableFunction") then
				pcall(function()
					f:Invoke()
				end)
			end
		end)
	end

	-- Refresh loja
	local refreshCategory = Instance.new("BindableFunction")
	refreshCategory.Name = "RefreshCategory"
	refreshCategory.Parent = systemGui

	refreshCategory.OnInvoke = function()
		for _, child in pairs(contentFrame:GetChildren()) do
			if child:IsA("Frame") then
				child.Parent = nil
			end
		end

		updatePlayerData()
		coinsLabel.Text = "💰 " .. playerData.coins

		local chars = characterData[selectedCategory] or {}
		local cardConfig = uiScale.card
		local spacing = cardConfig.spacing
		local index = 0

		for _, charInfo in ipairs(chars) do
			if not playerOwnsCharacter(charInfo.name) then
				local col = index % cardConfig.columns
				local row = math.floor(index / cardConfig.columns)
				local card = createCharacterCard(charInfo, contentFrame, cardConfig, false)
				card.Position = UDim2.new(
					0,
					spacing + col * (cardConfig.width + spacing),
					0,
					spacing + row * (cardConfig.height + spacing)
				)
				index = index + 1
			end
		end

		local rows = math.ceil(index / cardConfig.columns)
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, rows * (cardConfig.height + spacing) + spacing)
	end

	-- ─────────────────────────────────────
	-- FRAME INVENTÁRIO
	-- ─────────────────────────────────────

	invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.Size = isMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0.7, 0, 0.75, 0)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	invFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	invFrame.BorderSizePixel = 4
	invFrame.Visible = false
	invFrame.Parent = systemGui

	local invHeader = Instance.new("Frame")
	invHeader.Size = UDim2.new(1, 0, 0.08, 0)
	invHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	invHeader.BorderSizePixel = 0
	invHeader.Parent = invFrame

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(0.9, 0, 1, 0)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "📦 INVENTÁRIO — 💰 Clique no preço para vender"
	invTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	invTitle.TextScaled = true
	invTitle.Font = Enum.Font.Arcade
	invTitle.Parent = invHeader

	local invClose = Instance.new("TextButton")
	invClose.Size = UDim2.new(0.08, 0, 0.8, 0)
	invClose.Position = UDim2.new(0.91, 0, 0.1, 0)
	invClose.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	invClose.BorderSizePixel = 0
	invClose.Text = "X"
	invClose.TextColor3 = Color3.new(1, 1, 1)
	invClose.TextScaled = true
	invClose.Font = Enum.Font.Arcade
	invClose.Parent = invHeader

	invScroll = Instance.new("ScrollingFrame")
	invScroll.Size = UDim2.new(0.98, 0, 0.9, 0)
	invScroll.Position = UDim2.new(0.01, 0, 0.09, 0)
	invScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	invScroll.BorderColor3 = Color3.fromRGB(100, 100, 100)
	invScroll.BorderSizePixel = 2
	invScroll.ScrollBarThickness = isMobile and 8 or 12
	invScroll.Parent = invFrame

	-- Refresh inventário
	local refreshInventory = Instance.new("BindableFunction")
	refreshInventory.Name = "RefreshInventory"
	refreshInventory.Parent = systemGui

	refreshInventory.OnInvoke = function()
		for _, child in pairs(invScroll:GetChildren()) do
			if child:IsA("Frame") then
				child.Parent = nil
			end
		end

		updatePlayerData()

		local cardConfig = uiScale.card
		local spacing = cardConfig.spacing
		local index = 0

		for _, characterName in ipairs(playerData.ownedCharacters) do
			local charInfo = nil
			for _, chars in pairs(characterData) do
				for _, char in ipairs(chars) do
					if char.name == characterName then
						charInfo = char
						break
					end
				end
				if charInfo then
					break
				end
			end

			if not charInfo then
				charInfo = {
					name = characterName,
					price = 0,
					description = "Personagem especial",
					rarity = "AWAKENED",
				}
			end

			local col = index % cardConfig.columns
			local row = math.floor(index / cardConfig.columns)
			local card = createCharacterCard(charInfo, invScroll, cardConfig, true)
			card.Position = UDim2.new(
				0,
				spacing + col * (cardConfig.width + spacing),
				0,
				spacing + row * (cardConfig.height + spacing)
			)
			index = index + 1
		end

		local rows = math.ceil(index / cardConfig.columns)
		invScroll.CanvasSize = UDim2.new(0, 0, 0, rows * (cardConfig.height + spacing) + spacing)
	end

	-- ─────────────────────────────────────
	-- FUNÇÕES DE ABERTURA (chamadas pelo Menu Unificado)
	-- ─────────────────────────────────────

	_G.OpenCharacterShop = function()
		if isInvOpen then
			isInvOpen = false
			invFrame.Visible = false
		end
		isMenuOpen = true
		mainFrame.Visible = true
		playSound(sounds.open)
		local f = systemGui:FindFirstChild("RefreshCategory")
		if f and f:IsA("BindableFunction") then
			pcall(function()
				f:Invoke()
			end)
		end
	end

	_G.CloseCharacterShop = function()
		isMenuOpen = false
		mainFrame.Visible = false
	end

	_G.OpenCharacterInventory = function()
		if isMenuOpen then
			isMenuOpen = false
			mainFrame.Visible = false
		end
		isInvOpen = true
		invFrame.Visible = true
		playSound(sounds.open)
		local f = systemGui:FindFirstChild("RefreshInventory")
		if f and f:IsA("BindableFunction") then
			pcall(function()
				f:Invoke()
			end)
		end
	end

	_G.CloseCharacterInventory = function()
		isInvOpen = false
		invFrame.Visible = false
	end

	menuClose.MouseButton1Click:Connect(function()
		playSound(sounds.close)
		isMenuOpen = false
		mainFrame.Visible = false
	end)

	invClose.MouseButton1Click:Connect(function()
		playSound(sounds.close)
		isInvOpen = false
		invFrame.Visible = false
	end)
end

-- =====================================
-- INICIALIZAÇÃO
-- =====================================

player.CharacterAdded:Connect(function()
	task.wait(1)
	createSystem()
	updatePlayerData()
end)

if player.Character then
	createSystem()
	updatePlayerData()
end

-- Sync periódico
task.spawn(function()
	while true do
		task.wait(5)
		if systemGui and systemGui.Parent then
			updatePlayerData()
		end
	end
end)

-- Registrar no Menu Unificado
task.spawn(function()
	-- Esperar Menu Unificado estar disponível
	local timeout = 0
	while not _G.RegisterMenuCategory and timeout < 15 do
		task.wait(0.5)
		timeout = timeout + 0.5
	end

	if _G.RegisterMenuCategory then
		_G.RegisterMenuCategory("LOJA", "🛒", function()
			if _G.OpenCharacterShop then
				_G.OpenCharacterShop()
			end
		end, function()
			if _G.CloseCharacterShop then
				_G.CloseCharacterShop()
			end
		end, 1)

		_G.RegisterMenuCategory("INVENTÁRIO", "📦", function()
			if _G.OpenCharacterInventory then
				_G.OpenCharacterInventory()
			end
		end, function()
			if _G.CloseCharacterInventory then
				_G.CloseCharacterInventory()
			end
		end, 2)

		print("[CHAR SYSTEM V3] Registrado no Menu Unificado: LOJA + INVENTÁRIO")
	end
end)

print([[
╔══════════════════════════════════════════════════════╗
║  CHARACTER SYSTEM CLIENT V3 — CARREGADO             ║
╠══════════════════════════════════════════════════════╣
║  SUBSTITUI: CHARACTER_SYSTEM_CLIENT_V2               ║
║  REMOVER:   CHARACTER_SYSTEM_CLIENT_V2               ║
╠══════════════════════════════════════════════════════╣
║  V3 MUDANÇAS:                                        ║
║  * BOTÕES PRÓPRIOS REMOVIDOS (Menu Unificado)        ║
║  * Registra LOJA + INVENTÁRIO via RegisterCategory   ║
║  * _G.OpenCharacterShop / _G.OpenCharacterInventory  ║
║  * Mantém venda 25%, popups, despertar               ║
╚══════════════════════════════════════════════════════╝
]])
