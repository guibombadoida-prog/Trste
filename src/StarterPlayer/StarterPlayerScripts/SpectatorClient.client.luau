-- ============================================
-- SPECTATOR CLIENT EB V1
-- LOCAL: StarterPlayer → StarterPlayerScripts
-- NOME:  "SpectatorClient"
-- Sistema de câmera livre no modo espectador
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()

local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local spectatorRemote = remotes:WaitForChild("SpectatorMode", 10)
local spawnStateRemote = remotes:WaitForChild("SpawnStateChanged", 10)

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isSpectating = false
local spectatorConn = nil

-- ── Modo espectador: câmera livre ────────────────────────
local function enableSpectatorCamera()
	if isSpectating then
		return
	end
	isSpectating = true

	camera.CameraType = Enum.CameraType.Scriptable

	local camPos = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local speed = 20
	local sensitivity = 0.003

	-- Mostra HUD de espectador
	local playerGui = player:WaitForChild("PlayerGui")
	local specGui = Instance.new("ScreenGui")
	specGui.Name = "SpectatorHUD"
	specGui.ResetOnSpawn = false
	specGui.Parent = playerGui

	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0, 280, 0, 36)
	banner.Position = UDim2.new(0.5, -140, 0, isMobile and 60 or 100)
	banner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	banner.BorderColor3 = Color3.fromRGB(0, 150, 255)
	banner.BorderSizePixel = 2
	banner.Parent = specGui

	local bannerLbl = Instance.new("TextLabel")
	bannerLbl.Size = UDim2.new(1, 0, 1, 0)
	bannerLbl.BackgroundTransparency = 1
	bannerLbl.Text = "👁️ MODO ESPECTADOR — Escolha um personagem"
	bannerLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
	bannerLbl.TextScaled = true
	bannerLbl.Font = Enum.Font.SourceSansBold
	bannerLbl.Parent = banner

	-- Pisca o banner
	task.spawn(function()
		while specGui.Parent and isSpectating do
			bannerLbl.TextTransparency = 0
			task.wait(0.9)
			bannerLbl.TextTransparency = 0.5
			task.wait(0.5)
		end
	end)

	local mouseDelta = Vector2.new(0, 0)
	local pitch = 0
	local yaw = 0

	-- Extrai ângulos atuais da câmera
	local lookDir = camera.CFrame.LookVector
	pitch = math.asin(-lookDir.Y)
	yaw = math.atan2(-lookDir.X, -lookDir.Z)

	local inputConn = UserInputService.InputChanged:Connect(function(inp)
		if not isSpectating then
			return
		end
		if inp.UserInputType == Enum.UserInputType.MouseMovement then
			mouseDelta = inp.Delta
		end
	end)

	spectatorConn = RunService.RenderStepped:Connect(function(dt)
		if not isSpectating then
			return
		end

		local d = UserInputService:GetMouseDelta()
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end

		yaw = yaw - d.X * sensitivity
		pitch = math.clamp(pitch - d.Y * sensitivity, -math.pi / 2 + 0.05, math.pi / 2 - 0.05)

		local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local forward = rot.LookVector
		local right = rot.RightVector
		local up = Vector3.new(0, 1, 0)

		local moveDir = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + forward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir - forward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir - right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			moveDir = moveDir + up
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			moveDir = moveDir - up
		end

		-- Shift = mais rápido
		local currentSpeed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and speed * 2
			or speed

		if moveDir.Magnitude > 0 then
			camPos = camPos + moveDir.Unit * currentSpeed * dt
		end

		camera.CFrame = CFrame.new(camPos) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	end)

	-- Mobile: joystick de câmera (simplificado)
	if isMobile then
		-- Mobile usa apenas o toque para girar
		spectatorConn:Disconnect()
		spectatorConn = RunService.RenderStepped:Connect(function(dt)
			if not isSpectating then
				return
			end
			-- Em mobile, apenas mostra a câmera na posição do personagem
			local charLocal = player.Character
			if charLocal and charLocal:FindFirstChild("HumanoidRootPart") then
				local root = charLocal.HumanoidRootPart
				camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 15, 20), root.Position)
			end
		end)
	end

	-- Garante limpeza dos eventos
	if inputConn then
		task.spawn(function()
			while isSpectating do
				task.wait(0.5)
			end
			inputConn:Disconnect()
		end)
	end

	-- Remove HUD de espectador ao sair do modo
	task.spawn(function()
		while isSpectating do
			task.wait(0.3)
		end
		if specGui.Parent then
			specGui.Parent = nil
		end
	end)
end

local function disableSpectatorCamera()
	if not isSpectating then
		return
	end
	isSpectating = false

	if spectatorConn then
		spectatorConn:Disconnect()
		spectatorConn = nil
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	camera.CameraType = Enum.CameraType.Custom

	-- Volta a câmera para o personagem
	local charLocal = player.Character
	if charLocal then
		camera.CameraSubject = charLocal:FindFirstChild("Humanoid")
			or charLocal:FindFirstChild("HumanoidRootPart")
	end
end

-- ── Recebe eventos do servidor ────────────────────────────
if spectatorRemote then
	spectatorRemote.OnClientEvent:Connect(function(enable)
		if enable then
			enableSpectatorCamera()
		else
			disableSpectatorCamera()
		end
	end)
end

if spawnStateRemote then
	spawnStateRemote.OnClientEvent:Connect(function(state, characterName)
		if state == "lobby" or state == "spectator" then
			-- Garante câmera livre no lobby
			task.wait(0.5)
			if state == "spectator" then
				enableSpectatorCamera()
			end
		elseif state == "battle" then
			disableSpectatorCamera()
		end
	end)
end

-- ── Recria ao respawnar ───────────────────────────────────
player.CharacterAdded:Connect(function(character)
	char = character
	isSpectating = false
	if spectatorConn then
		spectatorConn:Disconnect()
		spectatorConn = nil
	end
	camera.CameraType = Enum.CameraType.Custom
end)

print("[SPECTATOR CLIENT EB V1] Carregado — câmera livre no lobby")
