-- ============================================================================
-- Client  (LocalScript)  ·  FICA DENTRO DA TOOL "Multiplas Bombas"
--
-- Só trata o TREMOR DE CÂMERA (a habilidade é só clique, sem botões extras).
-- Sem GUI/hub. Sem math.random (tremor usa math.noise, determinístico).
-- ============================================================================

local RunService = game:GetService("RunService")

local Tool = script.Parent
local CameraShake = Tool:WaitForChild("CameraShake") -- RemoteEvent (Server -> Client)

CameraShake.OnClientEvent:Connect(function(intensidade, duracao)
	intensidade = intensidade or 1
	duracao = duracao or 0.3
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local t = 0
	local con
	con = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		if t >= duracao then
			con:Disconnect()
			return
		end
		local forca = (1 - t / duracao) * intensidade * 0.4
		-- math.noise = ruido Perlin (deterministico, NAO e random)
		local n = t * 32
		local ox = math.noise(n, 0.0) * forca
		local oy = math.noise(0.0, n) * forca
		camera.CFrame = camera.CFrame * CFrame.new(ox, oy, 0)
	end)
end)
