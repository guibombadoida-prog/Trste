--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Lightning Explosion for convenience.
	
	
]]
local ReplicatedStorage = game:FindService("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local Derbis = game:FindService("Debris") or game:GetService("Debris")

if ReplicatedStorage and ReplicatedStorage:FindFirstChild("LightningBolt") then
	LightningBolt = require(ReplicatedStorage:WaitForChild("LightningBolt"))
	LightningExplosion = require(ReplicatedStorage:WaitForChild("LightningBolt"):WaitForChild("LightningExplosion"))
	LightningSparks = require(ReplicatedStorage:WaitForChild("LightningBolt"):WaitForChild("LightningSparks"))
else
	LightningBolt = require(script:WaitForChild("LightningBolt"))
	LightningExplosion = require(script:WaitForChild("LightningBolt"):WaitForChild("LightningExplosion"))
	LightningSparks = require(script:WaitForChild("LightningBolt"):WaitForChild("LightningSparks"))
end

return function(Position, Size, Number_Of_Bolts, Color, Bolt_Color, UpVector)
	Position = Position or Vector3.new(0,5,0)
	Size = Size or 10;
	Color = Color or Color3.fromRGB(255,255,255)
	Bolt_Color = Bolt_Color or Color;
	UpVector = UpVector or Vector3.new(0,1,0)
	
	local ExplosionAura = LightningExplosion.new(Position,Size,Number_Of_Bolts,Color,Bolt_Color,UpVector)
end



