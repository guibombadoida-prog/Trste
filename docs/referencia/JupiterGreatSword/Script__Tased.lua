do
	
	--Stickmasterluke
	
	local tick = os.clock;

	local Character = script.Parent;

	local Tased_Duration = script:WaitForChild("Duration");
	local Rate = .5;

	local Debris = require(6076058910);--(game:FindService("Debris") or game:GetService("Debris"));
	local RunService = (game:FindService("RunService") or game:GetService("RunService"));

	local s = Instance.new("Sound")
	s.SoundId = "http://www.roblox.com/asset/?id=82277505"
	s.Volume = 1
	s.Looped = true

	local Gear_Manager = require(6645113937)

	local Seed = Random.new(os.clock())

	local joints = {};
	
	local Shock = script.Shock:Clone();
	
	local Torso= Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")
	if Torso and Torso:IsA("BasePart") then
		
		Shock.Parent = Torso;
		Shock.Enabled = true;
		
		s.Parent = Torso
		s:Play()
		for i,v in ipairs(Character:GetChildren()) do
			--if v.className=="Motor" or v.className=="Motor6D" or v.className=="Weld" or v.className=="ManualWeld" then
			if v:IsA("BasePart") then
				for i,v in ipairs(v:GetJoints()) do
					if v:IsA("Motor6D") then
						local Info = {
							Joint = v;
							DesiredAngle = v.DesiredAngle;
							CurrentAngle = v.CurrentAngle;
							MaxVelocity = v.MaxVelocity;
						}
						joints[#joints + 1] = Info
					end

				end
			end


			--end
		end
	end

	if #joints>=1 then

		if Character:FindFirstChildWhichIsA("Humanoid") then Character:FindFirstChildWhichIsA("Humanoid").Sit = true end

		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

		local trippy = script.Trippy:Clone();
		trippy.Parent = Humanoid;
		trippy.Disabled = false;
		
		local On_Duration = true;
		
		task.defer(function()
			
			repeat
				
				if not On_Duration then
					break
				end
				
				for i,v in ipairs(joints) do
					if v and v.Joint then

						v.Joint.CurrentAngle = Seed:NextNumber(-10,10)
						v.Joint.DesiredAngle = Seed:NextNumber(-10,10);
						v.Joint.MaxVelocity = 1000

					end
				end
				
				Humanoid.Sit = true
				
				Gear_Manager:Halt()
				
			until (not Humanoid or Humanoid.Health <= 0)
			
		end)
		
		repeat
			
			if Tased_Duration.Value == math.huge then
				RunService.Stepped:Wait();
			else
				Tased_Duration.Value -= .5;
				Gear_Manager:Halt(.5);
			end
			
		until (Tased_Duration.Value <= 0 or not Humanoid or Humanoid.Health <= 0);
		
		if Shock then
			Shock.Enabled = false;
		end
		
		Debris:AddItem(Shock,2);
		
		On_Duration = false;

		for i,v in pairs(joints) do
			if v and v.Joint then

				v.Joint.CurrentAngle = v.CurrentAngle;
				v.Joint.DesiredAngle = v.DesiredAngle;
				v.Joint.MaxVelocity = 0.1;

			end
		end
		
		if trippy then
			trippy:Destroy();
		end
		
	end
	if s then s:Stop();s:Destroy();s = nil end

	task.wait(2)

	script:Destroy()
	
end