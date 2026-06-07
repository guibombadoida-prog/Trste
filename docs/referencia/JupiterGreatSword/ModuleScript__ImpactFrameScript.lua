--Made By ICAN_REA0
--Date By May 29 2024
--Time By 10:27,10:31,4:57

Lighting = game:GetService("Lighting")

Exposure = Lighting.ExposureCompensation;


return function(Position,Duration)
	local Part = Instance.new("Part")
	Part.Name = "IT"
	Part.Position = Position
	Part.CanCollide = false
	Part.Anchored = true
	Part.Transparency = 1
	Part.Size = Vector3.new(1,1,1)
	Part.Parent = workspace
	local HitBoard = script.HitBoard:Clone()
	HitBoard.Parent = Part
	HitBoard.Enabled = true
	local Invert = script.Invert:Clone()
	Invert.Parent = game.Lighting
	local Sky = script.Sky:Clone()
	Sky.Parent = game.Lighting
	Lighting.ExposureCompensation = -100
	local Impact_SFX = script.Impact_Sound:Clone()
	Impact_SFX:Play()
	Impact_SFX.Parent = game.Workspace
	local Highlights = script.FX.WhiteBlack:Clone()
	Highlights.Parent = game.Workspace
	Highlights.Enabled = true
	Highlights.Adornee = game.Workspace
	game:GetService("Debris"):AddItem(Impact_SFX,10)
	wait(Duration)
	HitBoard:Destroy()
	Invert:Destroy()
	Sky:Destroy()
	Highlights:Destroy()
	Lighting.ExposureCompensation = 0
end
