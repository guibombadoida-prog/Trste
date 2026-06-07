local Tool = script.Parent

local Remote = Tool:WaitForChild("Remote", 10)

local Services = {
	Players = (game:FindService("Players") or game:GetService("Players")),
	TweenService = (game:FindService("TweenService") or game:GetService("TweenService")),
	RunService = (game:FindService("RunService") or game:GetService("RunService")),
	Input = (game:FindService("ContextActionService") or game:GetService("ContextActionService"))
}

local Player, Character, Humanoid

function PeriTertiary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		Remote:FireServer(Enum.KeyCode.E)
	end
end

function PeriQuaternary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		Remote:FireServer(Enum.KeyCode.X)
	end
end

function PeriQuinary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		Remote:FireServer(Enum.KeyCode.Q)
	end
end

function Equipped()
	local Player = Services.Players.LocalPlayer
	local Character = Player.Character
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if not Humanoid or not Humanoid.Parent or Humanoid.Health <= 0 then
		return
	end

	Services.Input:BindAction("PeriTertiary", PeriTertiary, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
	Services.Input:BindAction("PeriQuaternary", PeriQuaternary, true, Enum.KeyCode.X, Enum.KeyCode.ButtonL2)
	Services.Input:BindAction("PeriQuinary", PeriQuinary, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonR2)

	Services.Input:SetTitle("PeriTertiary", "Supernova")
	Services.Input:SetPosition("PeriTertiary", UDim2.new(.5,0,-.5,0))

	Services.Input:SetTitle("PeriQuaternary", "Teleport")
	Services.Input:SetPosition("PeriQuaternary", UDim2.new(.5,0,-.25,0))

	Services.Input:SetTitle("PeriQuinary", "Shuriken of Space")
	Services.Input:SetPosition("PeriQuinary", UDim2.new(.5,0,0,0))

end

function Unequipped()
	Services.Input:UnbindAction("PeriTertiary")
	Services.Input:UnbindAction("PeriQuaternary")
	Services.Input:UnbindAction("PeriQuinary")
	Services.RunService.Heartbeat:Wait()
end

Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)

local DirectionInvoker = Tool:WaitForChild("DirectionInvoker", 10)

DirectionInvoker.OnClientInvoke = function()
	local player = game.Players.LocalPlayer
	if not player then return nil end

	local character = player.Character or player.CharacterAdded:Wait()
	local mouse = player:GetMouse()
	if not mouse then return nil end

	local camera = workspace.CurrentCamera
	local mouseRay = camera:ScreenPointToRay(mouse.X, mouse.Y)

	local origin = mouseRay.Origin
	local direction = mouseRay.Direction.Unit * 2000

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, raycastParams)

	if result then
		return {
			Hit = CFrame.new(result.Position),
			Position = result.Position,
			Target = result.Instance
		}
	else
		local skyPosition = origin + direction
		return {
			Hit = CFrame.new(skyPosition),
			Position = skyPosition,
			Target = nil
		}
	end
end

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local connection
local head

Tool:WaitForChild("StartHeadCamera").OnClientEvent:Connect(function(start)
	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if not head then return end

	if start then
		camera.CameraType = Enum.CameraType.Watch
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end)