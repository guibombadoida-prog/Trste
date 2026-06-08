local TweenService = game:GetService("TweenService")
local part = script.Parent
local mainsize = script:FindFirstChild("Size").Value

-- 1. Scale shrink tween (on the mesh itself)
local scaleTween = TweenService:Create(
	part,  -- Apply tween to the mesh
	TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{Size = mainsize}  -- Shrink mesh's scale
)

-- Fade tween (on the mesh itself)
local fadeTween = TweenService:Create(
	part,  -- Apply tween to the mesh
	TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	{Transparency = 1}  -- Make the mesh fade out
)

-- Play tweens
scaleTween:Play()
fadeTween:Play()
