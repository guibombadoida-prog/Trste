local victim = script.Parent:FindFirstChildOfClass("Humanoid")




game:GetService("TweenService"):Create(script.Time,TweenInfo.new(script.Lasting.Value,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false,0),{Value = 0}):Play()


repeat 
	task.wait(.01)
	local offset = Vector3.new(math.random(script.Time.Value * -1,script.Time.Value),math.random(script.Time.Value * -1,script.Time.Value),math.random(script.Time.Value * -1,script.Time.Value))
	victim.CameraOffset = victim.CameraOffset:Lerp(offset,script.Time.Value * 0.25)
until script.Time.Value == 0
victim.CameraOffset = Vector3.new(0,0,0)
script:Destroy()