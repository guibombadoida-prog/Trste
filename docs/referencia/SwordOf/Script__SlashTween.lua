local tweenservice = game:GetService("TweenService") or game:FindService("TweenService")

-- Tween for size with 0.2 second duration
local sizeTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local sizeTween = tweenservice:Create(script.Parent, sizeTweenInfo, {Size = Vector3.new(0.01, 20, 0.01)})

-- Tween for transparency with 1 second duration
local transparencyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local transparencyTween = tweenservice:Create(script.Parent, transparencyTweenInfo, {Transparency = 1})

-- Play both tweens
sizeTween:Play()
transparencyTween:Play()