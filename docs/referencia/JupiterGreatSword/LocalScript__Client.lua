--majority of code by TakeoHonorable
local Tool = script.Parent

local Remote = Tool:WaitForChild("Remote",10)

local MouseInput = Tool:WaitForChild("MouseInput",10)

local Services = {
	Players = (game:FindService("Players") or game:GetService("Players")),
	TweenService = (game:FindService("TweenService") or game:GetService("TweenService")),
	RunService = (game:FindService("RunService") or game:GetService("RunService")),
	Input = (game:FindService("ContextActionService") or game:GetService("ContextActionService"))
}

local Player,Character,Humanoid

function BladePrimary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then 
		Remote:FireServer(Enum.KeyCode.E)
	end
end

function BladeSecondary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then 
		Remote:FireServer(Enum.KeyCode.Q)
	end
end

function BladeTertiary(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then 
		Remote:FireServer(Enum.KeyCode.X)
	end
end

function Equipped()
	Player = Services.Players.LocalPlayer
	Character = Player.Character
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid or not Humanoid.Parent or Humanoid.Health <= 0 then return end

	Services.Input:BindAction("BladePrimary",BladePrimary,true,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
	Services.Input:BindAction("BladeSecondary",BladeSecondary,true,Enum.KeyCode.Q,Enum.KeyCode.ButtonY)
	Services.Input:BindAction("BladeTertiary",BladeTertiary,true,Enum.KeyCode.X,Enum.KeyCode.ButtonL1)
	Services.Input:SetTitle("BladePrimary","🌟Unwing🌟")
	Services.Input:SetTitle("BladeSecondary","🌟Jupiter🌟")
	Services.Input:SetTitle("BladeTertiary","🌟Jovadian Domain🌟")
	Services.Input:SetPosition("BladePrimary",UDim2.new(.5,0,-.5,0))
	Services.Input:SetPosition("BladeSecondary",UDim2.new(.5,0,-.25,0))
	Services.Input:SetPosition("BladeTertiary",UDim2.new(.5,0,0,0))
	
	if Player.Name == "ICAN_REA0" or Player.Name == "TizRuss" then
		Services.Input:SetTitle("BladePrimary","🌟羽のない🌟")
		Services.Input:SetTitle("BladeSecondary","🌟木星🌟")
		Services.Input:SetTitle("BladeTertiary","🌟ジョヴァディアン領🌟")
	end
	
	if Player.Name == "huy_VN77" then
		Services.Input:SetTitle("BladePrimary","🌟Không cánh🌟")
		Services.Input:SetTitle("BladeSecondary","🌟Sao Mộc🌟")
		Services.Input:SetTitle("BladeTertiary","🌟Miền Jovadian🌟")
	end
	
	if Player.Name == "GUIBOMBADOIDA" then
		Services.Input:SetTitle("BladePrimary","🌟Desasasinar🌟")
		Services.Input:SetTitle("BladeSecondary","🌟Júpiter🌟")
		Services.Input:SetTitle("BladeTertiary","🌟Domínio Jovadiano🌟")
	end
	
end

function Unequipped()
	Services.Input:UnbindAction("BladePrimary")
	Services.Input:UnbindAction("BladeSecondary")	
	Services.Input:UnbindAction("BladeTertiary")	
  --  Gui:Destroy()	
end

Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)


function MouseInput.OnClientInvoke()
	return game.Players.LocalPlayer:GetMouse().Hit.p
end