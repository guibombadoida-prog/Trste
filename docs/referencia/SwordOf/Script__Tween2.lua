local TweenService = game:GetService("TweenService")
local part = script.Parent

-- 1. Scale shrink tween (on the mesh itself)
local scaleTween = TweenService:Create(
	part,  -- Apply tween to the mesh
	TweenInfo.new(1.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{Size = Vector3.new(150, 10, 150)}  -- Shrink mesh's scale
)

-- 2. Slow spin behavior (consistent speed)
local slowSpin = 200  -- Fixed rotation speed (in degrees)
local spinTime = 3  -- Fixed time for the slow spin

local spinTween = TweenService:Create(
	part,  -- Apply tween to the mesh
	TweenInfo.new(spinTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	{Orientation = Vector3.new(0, slowSpin, 0)}  -- Apply rotation to mesh
)

-- Fade tween (on the mesh itself)
local fadeTween = TweenService:Create(
	part,  -- Apply tween to the mesh
	TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	{Transparency = 1}  -- Make the mesh fade out
)

-- Play tweens
scaleTween:Play()
spinTween:Play()
fadeTween:Play()