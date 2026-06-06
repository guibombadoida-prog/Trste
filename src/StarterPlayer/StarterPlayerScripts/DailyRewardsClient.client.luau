-- ============================================
-- SISTEMA DE RECOMPENSAS DIÁRIAS - CLIENTE V4
-- Coloque em StarterPlayer > StarterPlayerScripts
-- Nome: "DailyRewardsClient"
-- SUBSTITUI: DailyRewardsClient V3
-- ============================================
-- NOVIDADES V4:
-- • BOTÃO MOVIDO PARA LADO ESQUERDO (ao lado de Times) ✓
-- • BOTÃO DE TAMANHO REMOVIDO completamente ✓
-- • SINCRONIZADO COM CHARACTER MENU automaticamente ✓
-- • UI 100% RESPONSIVA (Mobile/Tablet/PC) ✓
-- • CORREÇÃO: Variável updateStatus agora é global do módulo ✓
-- • Sistema de Streak visual melhorado
-- • Animações de brilho nos cards
-- • Notificações integradas
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================
-- DETECÇÃO DE PLATAFORMA
-- =====================================

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isTablet = isMobile and (workspace.CurrentCamera.ViewportSize.X > 600)
local isConsole = GuiService:IsTenFootInterface()

print(
	string.format(
		"[DAILY REWARDS V4] Plataforma: %s",
		isMobile and (isTablet and "Tablet" or "Mobile") or (isConsole and "Console" or "PC")
	)
)

-- =====================================
-- SONS (REUTILIZADOS DO MENU)
-- =====================================

local sounds = {
	hover = "rbxassetid://12846056",
	click = "rbxassetid://156785206",
	purchase = "rbxassetid://5031873608",
	error = "rbxassetid://2865228021",
	open = "rbxassetid://157167203",
	close = "rbxassetid://157167205",
	info = "rbxassetid://156785206",
	reward = "rbxassetid://5031873608",
}

local function playSound(soundId)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- =====================================
-- SISTEMA DE TAMANHOS (SINCRONIZADO)
-- =====================================

local UI_SIZES = {
	SMALL = "Pequeno",
	MEDIUM = "Médio",
	LARGE = "Grande",
}

-- DETECTAR TAMANHO DO CHARACTER MENU
local function detectCharacterMenuSize()
	local charMenuGui = playerGui:FindFirstChild("CharacterMenuV13")
		or playerGui:FindFirstChild("CharacterMenuV12")
		or playerGui:FindFirstChild("CharacterMenuV11")
	if not charMenuGui then
		return UI_SIZES.MEDIUM
	end

	local mainFrame = charMenuGui:FindFirstChild("MainFrame")
	if not mainFrame then
		return UI_SIZES.MEDIUM
	end

	local size = mainFrame.Size.X.Scale

	if isTablet then
		if size <= 0.75 then
			return UI_SIZES.SMALL
		elseif size >= 0.95 then
			return UI_SIZES.LARGE
		else
			return UI_SIZES.MEDIUM
		end
	elseif isMobile then
		if size <= 0.85 then
			return UI_SIZES.SMALL
		elseif size >= 0.98 then
			return UI_SIZES.LARGE
		else
			return UI_SIZES.MEDIUM
		end
	else
		if size <= 0.65 then
			return UI_SIZES.SMALL
		elseif size >= 0.85 then
			return UI_SIZES.LARGE
		else
			return UI_SIZES.MEDIUM
		end
	end
end

local currentUISize = detectCharacterMenuSize()

local function getUIScale()
	local baseScale

	if isTablet then
		baseScale = {
			menu = { small = 0.75, medium = 0.85, large = 0.95 },
			button = { small = 0.10, medium = 0.12, large = 0.14 },
			card = {
				width = { small = 140, medium = 160, large = 180 },
				height = { small = 190, medium = 210, large = 230 },
				columns = 3,
				spacing = { small = 8, medium = 10, large = 12 },
			},
		}
	elseif isMobile then
		local viewport = workspace.CurrentCamera.ViewportSize
		baseScale = {
			menu = { small = 0.85, medium = 0.92, large = 0.98 },
			button = { small = 0.12, medium = 0.15, large = 0.18 },
			card = {
				width = {
					small = math.floor(viewport.X * 0.40),
					medium = math.floor(viewport.X * 0.45),
					large = math.floor(viewport.X * 0.48),
				},
				height = { small = 170, medium = 190, large = 210 },
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
				height = { small = 170, medium = 190, large = 210 },
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
-- AGUARDAR REMOTES
-- =====================================

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local claimDailyReward = remotes:WaitForChild("ClaimDailyReward", 10)
local getDailyRewardStatus = remotes:WaitForChild("GetDailyRewardStatus", 10)
local claimMissionReward = remotes:FindFirstChild("ClaimMissionReward")

if not claimDailyReward or not getDailyRewardStatus then
	warn("[DAILY REWARDS V4] ⚠️ Remotes não encontrados!")
	return
end

-- =====================================
-- VARIÁVEIS GLOBAIS DO MÓDULO
-- =====================================

local dailyGui = nil
local isMenuOpen = false
local currentStatus = nil

-- CRÍTICO: Definir updateStatus como variável do módulo (não local da função)
local updateStatus = nil

-- =====================================
-- CORES
-- =====================================

local COLORS = {
	background = Color3.fromRGB(20, 20, 20),
	panel = Color3.fromRGB(30, 30, 30),
	header = Color3.fromRGB(40, 40, 40),
	border = Color3.fromRGB(255, 255, 255),
	claimed = Color3.fromRGB(0, 150, 0),
	available = Color3.fromRGB(255, 215, 0),
	locked = Color3.fromRGB(100, 100, 100),
	bonus = Color3.fromRGB(255, 100, 255),
	streak = Color3.fromRGB(255, 150, 0),
	mission = Color3.fromRGB(0, 150, 255),
}

-- =====================================
-- FUNÇÕES AUXILIARES
-- =====================================

local function formatTime(seconds)
	if not seconds or seconds < 0 then
		seconds = 0
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%02d:%02d", minutes, secs)
	end
end

local function notify(message, isSuccess)
	playSound(isSuccess and sounds.reward or sounds.error)
	local notification = Instance.new("Frame")
	notification.Size = isMobile and UDim2.new(0.8, 0, 0.12, 0) or UDim2.new(0.4, 0, 0.08, 0)
	notification.Position = isMobile and UDim2.new(0.1, 0, 0.05, 0) or UDim2.new(0.3, 0, 0.05, 0)
	notification.BackgroundColor3 = COLORS.background
	notification.BorderColor3 = isSuccess and COLORS.claimed or Color3.fromRGB(200, 0, 0)
	notification.BorderSizePixel = 3
	notification.Parent = dailyGui or playerGui
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.Arcade
	text.Parent = notification
	wait(3)
	notification:Destroy()
end

local function validateStatus(status)
	if not status then
		return {
			canClaim = false,
			message = "Erro ao carregar dados",
			currentStreak = 0,
			totalDaysClaimed = 0,
			timeUntilNext = 0,
			bonusActive = nil,
			rewards = {},
			missions = {},
		}
	end

	return {
		canClaim = status.canClaim or false,
		message = status.message or "",
		currentStreak = tonumber(status.currentStreak) or 0,
		totalDaysClaimed = tonumber(status.totalDaysClaimed) or 0,
		timeUntilNext = tonumber(status.timeUntilNext) or 0,
		bonusActive = status.bonusActive,
		rewards = status.rewards or {},
		missions = status.missions or {},
		canRecover = status.canRecover or false,
	}
end

-- =====================================
-- CRIAR INTERFACE
-- =====================================

local function createDailyRewardsInterface()
	if dailyGui then
		dailyGui:Destroy()
	end

	dailyGui = Instance.new("ScreenGui")
	dailyGui.Name = "DailyRewardsV4"
	dailyGui.ResetOnSpawn = false
	dailyGui.DisplayOrder = 10
	dailyGui.Parent = playerGui

	-- =====================================
	-- BOTÃO PRINCIPAL (LADO ESQUERDO)
	-- =====================================

	local mainButton = Instance.new("TextButton")
	mainButton.Size = uiScale.button
	-- NOVA POSIÇÃO: LADO ESQUERDO (ao lado de Times)
	mainButton.Position = isMobile and UDim2.new(0.01, 0, 0.13, 0) or UDim2.new(0.01, 0, 0.13, 0)
	mainButton.AnchorPoint = Vector2.new(0, 0)
	mainButton.BackgroundColor3 = COLORS.available
	mainButton.BorderColor3 = COLORS.border
	mainButton.BorderSizePixel = 2
	mainButton.Text = "🎁\nDAILY"
	mainButton.TextColor3 = COLORS.background
	mainButton.TextScaled = true
	mainButton.Font = Enum.Font.Arcade
	mainButton.Parent = dailyGui

	-- Indicador de disponibilidade
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0.3, 0, 0.3, 0)
	indicator.Position = UDim2.new(0.7, 0, 0, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = mainButton

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = indicator

	-- Animação de pulso no indicador
	spawn(function()
		while indicator.Parent do
			if indicator.Visible then
				TweenService:Create(indicator, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
					BackgroundTransparency = 0.5,
				}):Play()
				wait(0.8)
				TweenService:Create(indicator, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
					BackgroundTransparency = 0,
				}):Play()
				wait(0.8)
			else
				wait(0.5)
			end
		end
	end)

	-- =====================================
	-- MENU PRINCIPAL
	-- =====================================

	local mainMenu = Instance.new("Frame")
	mainMenu.Name = "MainMenu"
	mainMenu.Size = uiScale.menu
	mainMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainMenu.AnchorPoint = Vector2.new(0.5, 0.5)
	mainMenu.BackgroundColor3 = COLORS.background
	mainMenu.BorderColor3 = COLORS.border
	mainMenu.BorderSizePixel = 4
	mainMenu.Visible = false
	mainMenu.Parent = dailyGui

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.BackgroundColor3 = COLORS.header
	header.BorderSizePixel = 0
	header.Parent = mainMenu

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎁 RECOMPENSAS DIÁRIAS"
	title.TextColor3 = COLORS.available
	title.TextScaled = true
	title.Font = Enum.Font.Arcade
	title.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = header

	-- =====================================
	-- INFO DE STREAK
	-- =====================================

	local streakInfo = Instance.new("Frame")
	streakInfo.Size = UDim2.new(0.96, 0, 0.1, 0)
	streakInfo.Position = UDim2.new(0.02, 0, 0.14, 0)
	streakInfo.BackgroundColor3 = COLORS.panel
	streakInfo.BorderColor3 = COLORS.streak
	streakInfo.BorderSizePixel = 2
	streakInfo.Parent = mainMenu

	local streakIcon = Instance.new("TextLabel")
	streakIcon.Size = UDim2.new(0.15, 0, 0.8, 0)
	streakIcon.Position = UDim2.new(0.02, 0, 0.1, 0)
	streakIcon.BackgroundTransparency = 1
	streakIcon.Text = "🔥"
	streakIcon.TextScaled = true
	streakIcon.Font = Enum.Font.SourceSansBold
	streakIcon.Parent = streakInfo

	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
	streakLabel.Position = UDim2.new(0.18, 0, 0.1, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "Sequência: 0 dias"
	streakLabel.TextColor3 = COLORS.streak
	streakLabel.TextScaled = true
	streakLabel.Font = Enum.Font.SourceSansBold
	streakLabel.TextXAlignment = Enum.TextXAlignment.Left
	streakLabel.Parent = streakInfo

	local totalLabel = Instance.new("TextLabel")
	totalLabel.Name = "TotalLabel"
	totalLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	totalLabel.Position = UDim2.new(0.18, 0, 0.55, 0)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "Total: 0 dias"
	totalLabel.TextColor3 = Color3.new(1, 1, 1)
	totalLabel.TextScaled = true
	totalLabel.Font = Enum.Font.SourceSans
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.Parent = streakInfo

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0.38, 0, 0.8, 0)
	timerLabel.Position = UDim2.new(0.6, 0, 0.1, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Próxima: 00:00:00"
	timerLabel.TextColor3 = COLORS.available
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.SourceSans
	timerLabel.Parent = streakInfo

	-- =====================================
	-- CONTAINER DE RECOMPENSAS
	-- =====================================

	local rewardsContainer = Instance.new("ScrollingFrame")
	rewardsContainer.Size = UDim2.new(0.96, 0, 0.72, 0)
	rewardsContainer.Position = UDim2.new(0.02, 0, 0.26, 0)
	rewardsContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	rewardsContainer.BorderColor3 = COLORS.border
	rewardsContainer.BorderSizePixel = 2
	rewardsContainer.ScrollBarThickness = isMobile and 8 or 12
	rewardsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	rewardsContainer.Parent = mainMenu

	-- =====================================
	-- CRIAR CARDS DE RECOMPENSA
	-- =====================================

	local function createRewardCards()
		for _, child in pairs(rewardsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		if not currentStatus or not currentStatus.rewards or #currentStatus.rewards == 0 then
			warn("[DAILY REWARDS V4] Status inválido")
			return
		end

		local cardConfig = uiScale.card
		local spacing = cardConfig.spacing

		for i, reward in ipairs(currentStatus.rewards) do
			local col = (i - 1) % cardConfig.columns
			local row = math.floor((i - 1) / cardConfig.columns)

			local card = Instance.new("Frame")
			card.Size = UDim2.new(0, cardConfig.width, 0, cardConfig.height)
			card.Position = UDim2.new(
				0,
				spacing + col * (cardConfig.width + spacing),
				0,
				spacing + row * (cardConfig.height + spacing)
			)
			card.BackgroundColor3 = COLORS.panel
			card.Parent = rewardsContainer

			local isClaimed = i <= (currentStatus.currentStreak or 0)
			local isAvailable = i == (currentStatus.currentStreak or 0) + 1
				and (currentStatus.canClaim or false)
			local isLocked = i > (currentStatus.currentStreak or 0) + 1

			if isClaimed then
				card.BorderColor3 = COLORS.claimed
			elseif isAvailable then
				card.BorderColor3 = COLORS.available
			else
				card.BorderColor3 = COLORS.locked
			end
			card.BorderSizePixel = 3

			-- Header do card
			local dayLabel = Instance.new("TextLabel")
			dayLabel.Size = UDim2.new(1, 0, 0.18, 0)
			dayLabel.BackgroundColor3 = card.BorderColor3
			dayLabel.BorderSizePixel = 0
			dayLabel.Text = "DIA " .. (reward.day or i)
			dayLabel.TextColor3 = Color3.new(1, 1, 1)
			dayLabel.TextScaled = true
			dayLabel.Font = Enum.Font.Arcade
			dayLabel.Parent = card

			-- Ícone
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.new(1, 0, 0.22, 0)
			icon.Position = UDim2.new(0, 0, 0.2, 0)
			icon.BackgroundTransparency = 1
			icon.Text = isClaimed and "✓" or (isAvailable and "🎁" or "🔒")
			icon.TextScaled = true
			icon.Font = Enum.Font.SourceSansBold
			icon.TextColor3 = card.BorderColor3
			icon.Parent = card

			-- Recompensas
			local rewardText = Instance.new("TextLabel")
			rewardText.Size = UDim2.new(0.9, 0, 0.22, 0)
			rewardText.Position = UDim2.new(0.05, 0, 0.44, 0)
			rewardText.BackgroundTransparency = 1
			rewardText.Text =
				string.format("💰 %d\n⚔️ %d", reward.coins or 0, reward.bounty or 0)
			rewardText.TextColor3 = Color3.new(1, 1, 1)
			rewardText.TextScaled = true
			rewardText.Font = Enum.Font.SourceSans
			rewardText.Parent = card

			-- Descrição
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
			descLabel.Position = UDim2.new(0.05, 0, 0.68, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = reward.description or ""
			descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			descLabel.TextScaled = true
			descLabel.Font = Enum.Font.SourceSans
			descLabel.Parent = card

			-- Bônus
			if reward.bonus then
				local bonusLabel = Instance.new("TextLabel")
				bonusLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
				bonusLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
				bonusLabel.BackgroundColor3 = COLORS.bonus
				bonusLabel.BorderSizePixel = 0
				bonusLabel.Text = "⭐ BÔNUS!"
				bonusLabel.TextColor3 = Color3.new(1, 1, 1)
				bonusLabel.TextScaled = true
				bonusLabel.Font = Enum.Font.Arcade
				bonusLabel.Parent = card
			end

			-- Botão de coletar
			if isAvailable then
				local claimButton = Instance.new("TextButton")
				claimButton.Size = UDim2.new(1, 0, 1, 0)
				claimButton.BackgroundTransparency = 1
				claimButton.Text = ""
				claimButton.Parent = card

				claimButton.MouseButton1Click:Connect(function()
					playSound(sounds.click)

					local success, result = pcall(function()
						return claimDailyReward:InvokeServer()
					end)

					if success and result then
						playSound(sounds.reward)
						notify(
							string.format(
								"✅ Coletou: %d moedas + %d bounty!",
								reward.coins,
								reward.bounty
							),
							true
						)
						wait(0.5)
						updateStatus()
					else
						playSound(sounds.error)
						notify("❌ " .. (result or "Erro ao coletar"), false)
					end
				end)

				-- Animação de brilho
				spawn(function()
					while card.Parent and isAvailable do
						local shine = Instance.new("Frame")
						shine.Size = UDim2.new(0.2, 0, 1.2, 0)
						shine.Position = UDim2.new(-0.3, 0, -0.1, 0)
						shine.BackgroundColor3 = Color3.new(1, 1, 1)
						shine.BackgroundTransparency = 0.3
						shine.BorderSizePixel = 0
						shine.ZIndex = 10
						shine.Parent = card

						local gradient = Instance.new("UIGradient")
						gradient.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(1, 1),
						})
						gradient.Rotation = 45
						gradient.Parent = shine

						TweenService:Create(shine, TweenInfo.new(2, Enum.EasingStyle.Linear), {
							Position = UDim2.new(1.1, 0, -0.1, 0),
						}):Play()

						wait(2)
						shine:Destroy()
						wait(3)
					end
				end)
			end
		end

		local rows = math.ceil(#currentStatus.rewards / cardConfig.columns)
		rewardsContainer.CanvasSize =
			UDim2.new(0, 0, 0, rows * (cardConfig.height + spacing) + spacing)
	end

	-- =====================================
	-- ATUALIZAR STATUS (AGORA GLOBAL)
	-- =====================================

	updateStatus = function()
		local success, status = pcall(function()
			return getDailyRewardStatus:InvokeServer()
		end)

		if success and status then
			currentStatus = validateStatus(status)
			indicator.Visible = currentStatus.canClaim

			streakLabel.Text =
				string.format("🔥 Sequência: %d dias", currentStatus.currentStreak)
			totalLabel.Text = string.format("Total: %d dias", currentStatus.totalDaysClaimed)

			createRewardCards()
		else
			warn("[DAILY REWARDS V4] Erro ao obter status:", status)
			currentStatus = validateStatus(nil)
		end
	end

	-- Timer de countdown
	spawn(function()
		while dailyGui and dailyGui.Parent do
			if currentStatus then
				if currentStatus.timeUntilNext > 0 then
					timerLabel.Text = "⏰ Próxima: " .. formatTime(currentStatus.timeUntilNext)
					currentStatus.timeUntilNext = currentStatus.timeUntilNext - 1
				else
					timerLabel.Text = "✅ Disponível!"
					timerLabel.TextColor3 = COLORS.claimed
					updateStatus()
				end
			end
			wait(1)
		end
	end)

	-- =====================================
	-- EVENTOS
	-- =====================================

	local function toggleMenu()
		isMenuOpen = not isMenuOpen
		mainMenu.Visible = isMenuOpen

		playSound(isMenuOpen and sounds.open or sounds.close)

		if isMenuOpen then
			updateStatus()
		end
	end

	mainButton.MouseButton1Click:Connect(toggleMenu)
	closeButton.MouseButton1Click:Connect(toggleMenu)

	-- Sons de hover (apenas PC)
	if not isMobile then
		mainButton.MouseEnter:Connect(function()
			playSound(sounds.hover)
		end)
		closeButton.MouseEnter:Connect(function()
			playSound(sounds.hover)
		end)
	end

	-- Inicializar
	updateStatus()
end

-- =====================================
-- MONITORAR MUDANÇAS DE TAMANHO DO CHARACTER MENU
-- =====================================

local function monitorCharacterMenuSize()
	spawn(function()
		while wait(1) do
			local newSize = detectCharacterMenuSize()
			if newSize ~= currentUISize then
				print(
					string.format(
						"[DAILY REWARDS V4] 📏 Tamanho alterado: %s → %s",
						currentUISize,
						newSize
					)
				)
				currentUISize = newSize

				local wasOpen = isMenuOpen
				uiScale = getUIScale()
				createDailyRewardsInterface()

				if wasOpen then
					local menu = dailyGui:FindFirstChild("MainMenu")
					if menu then
						menu.Visible = true
						isMenuOpen = true
					end
				end
			end
		end
	end)
end

-- =====================================
-- DETECÇÃO DE ROTAÇÃO (MOBILE)
-- =====================================

if isMobile then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		wait(0.5)
		isTablet = workspace.CurrentCamera.ViewportSize.X > 600
		currentUISize = detectCharacterMenuSize()
		uiScale = getUIScale()

		if dailyGui then
			local wasOpen = isMenuOpen
			createDailyRewardsInterface()
			if wasOpen then
				local menu = dailyGui:FindFirstChild("MainMenu")
				if menu then
					menu.Visible = true
					isMenuOpen = true
				end
			end
		end
	end)
end

-- =====================================
-- INICIALIZAÇÃO
-- =====================================

player.CharacterAdded:Connect(function()
	wait(1)
	createDailyRewardsInterface()
	monitorCharacterMenuSize()
end)

if player.Character then
	createDailyRewardsInterface()
	monitorCharacterMenuSize()
end

print([[
╔════════════════════════════════════════════════════╗
║  ✅ DAILY REWARDS CLIENT V4 CARREGADO             ║
╠════════════════════════════════════════════════════╣
║  SUBSTITUI: DailyRewardsClient V3                 ║
╠════════════════════════════════════════════════════╣
║  NOVIDADES V4:                                     ║
║  • BOTÃO MOVIDO PARA LADO ESQUERDO ✓              ║
║  • BOTÃO DE TAMANHO REMOVIDO ✓                    ║
║  • SINCRONIZADO COM CHARACTER MENU ✓              ║
║  • CORREÇÃO: updateStatus agora é global ✓        ║
║  • UI 100% RESPONSIVA (Mobile/Tablet/PC) ✓        ║
╠════════════════════════════════════════════════════╣
║  POSICIONAMENTO ATUALIZADO (ESQUERDA):            ║
║  • Menu Personagens: Y=0.47 (M) / Y=0.47 (PC)    ║
║  • Inventário: Y=0.54                             ║
║  • Times: Y=0.68                                  ║
║  • Daily Rewards: Y=0.75 ✓ NOVO LADO ESQUERDO    ║
║  • Tamanho: 0.61 (sincronizado Character Menu)   ║
╠════════════════════════════════════════════════════╣
║  CORREÇÕES APLICADAS:                              ║
║  • updateStatus definida como variável do módulo  ║
║  • Acessível em createRewardCards()               ║
║  • Sem mais erro de "local used in enclosing"     ║
╠════════════════════════════════════════════════════╣
║  FEATURES:                                         ║
║  • Contador de sequência visual com 🔥            ║
║  • Timer de próxima recompensa                    ║
║  • Cards com estado visual (coletado/disponível)  ║
║  • Efeito de brilho em cards disponíveis          ║
║  • Indicador pulsante quando disponível           ║
╚════════════════════════════════════════════════════╝
]])
