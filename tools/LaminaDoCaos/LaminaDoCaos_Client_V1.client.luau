-- ============================================================================
-- LaminaDoCaos_Client_V1  (LocalScript)  ·  FICA DENTRO DA TOOL "LaminaDoCaos"
--
-- Cria os BOTOES das habilidades (sem GUI/hub) e envia os inputs ao servidor.
--
-- REUTILIZACAO (obrigatorio avisar a origem):
--   * Padrao de botoes (BindAction/SetTitle/SetPosition) ... script de botoes
--     FORNECIDO por voce + Client da "Sword of Space".
--
-- REGRAS:
--   * Botoes permitidos pois a Tool tem habilidades Extra (Q/E/R).
--   * Sem GUI/hub. Sem math.random (tremor usa math.noise).
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Services = {
	Players = Players,
	Input = (game:FindService("ContextActionService") or game:GetService("ContextActionService")),
}

local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote") -- RemoteEvent (Client -> Server)
local CameraShake = Tool:WaitForChild("CameraShake") -- RemoteEvent (Server -> Client)

local Player, Character, Humanoid

-- Calcula a posicao mirada pelo mouse/toque (para as habilidades miradas)
local function getMira()
	local p = Services.Players.LocalPlayer
	local mouse = p and p:GetMouse()
	if mouse and mouse.Hit then
		return mouse.Hit.Position
	end
	return nil
end

-- Dispara uma habilidade para o servidor (com a mira)
local function ativar(tecla)
	Remote:FireServer(tecla, getMira())
end

-- Acoes dos botoes (padrao do script fornecido: Primary/Secondary/Thirdary)
local function Primary(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ativar(Enum.KeyCode.Q)
	end
end
local function Secondary(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ativar(Enum.KeyCode.E)
	end
end
local function Thirdary(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ativar(Enum.KeyCode.R)
	end
end

function Equipped()
	Player = Services.Players.LocalPlayer
	Character = Player.Character
	Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid or not Humanoid.Parent or Humanoid.Health <= 0 then
		return
	end

	-- Criacao dos botoes (com botao de toque para mobile = 3o argumento true)
	Services.Input:BindAction("Primary", Primary, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonX)
	Services.Input:BindAction("Secondary", Secondary, true, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
	Services.Input:BindAction("Thirdary", Thirdary, true, Enum.KeyCode.R, Enum.KeyCode.ButtonA)

	Services.Input:SetTitle("Primary", "Onda de Caos")
	Services.Input:SetTitle("Secondary", "Projetil do Caos")
	Services.Input:SetTitle("Thirdary", "Salto Dimensional")

	Services.Input:SetPosition("Primary", UDim2.new(0.5, 0, -0.5, 0))
	Services.Input:SetPosition("Secondary", UDim2.new(0.5, 0, -0.25, 0))
	Services.Input:SetPosition("Thirdary", UDim2.new(0.5, 0, 0, 0))
end

function Unequipped()
	-- Remove os botoes quando a Tool e desequipada
	Services.Input:UnbindAction("Primary")
	Services.Input:UnbindAction("Secondary")
	Services.Input:UnbindAction("Thirdary")
end

Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)

-- ===================== TREMOR DE CAMERA (sem random) ========================
CameraShake.OnClientEvent:Connect(function(intensidade, duracao)
	intensidade = intensidade or 1
	duracao = duracao or 0.4
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local t = 0
	local con
	con = RunService.RenderStepped:Connect(function(dt)
		t += dt
		if t >= duracao then
			con:Disconnect()
			return
		end
		local forca = (1 - t / duracao) * intensidade * 0.5
		-- math.noise = ruido Perlin (deterministico, NAO e random)
		local ox = math.noise(t * 25, 0) * forca
		local oy = math.noise(0, t * 25) * forca
		camera.CFrame = camera.CFrame * CFrame.new(ox, oy, 0)
	end)
end)
