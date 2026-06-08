--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Orb Charge/Disbursal for convenience.
	
	
]]
local Debris = (game:FindFirstChild("Debris") or game:GetService("Debris"));
local RunService = (game:FindService("RunService") or game:GetService("RunService"));

local Seed = Random.new(os.clock() * 10^6)

return function(Position, Duration, Size, Color, Number_Of_Orbs, Gather, Pitch, Rotation_Per_Second, Radius)
	
	Position = Position or Vector3.new(0,5,0);
	Duration = Duration or .5;
	Size = Size or 1;
	Color = Color or Color3.fromRGB(255, 255, 255);
	Number_Of_Orbs = Number_Of_Orbs or 1;
	Gather = Gather 
	
	local Sphere = Instance.new("Part");
	Sphere.Name = "Orb";
	Sphere.Locked = true;
	Sphere.Anchored = true;
	Sphere.CanCollide = false;
	Sphere.Shape = Enum.PartType.Ball;
	Sphere.Size = Vector3.new(1, 1, 1) * Size;
	Sphere.Color = Color
	Sphere.Material = Enum.Material.Neon;
	
	
	Pitch = Pitch or Seed:NextNumber(-360,360);
	Rotation_Per_Second = Rotation_Per_Second or Seed:NextNumber(-90,90)
	Radius = Radius or Seed:NextNumber(150,200);
	
	
	
	do
		local Light = Instance.new("PointLight");
		Light.Name = "Light";
		Light.Brightness = 0.001;
		Light.Range = 0.001;
		Light.Parent = Sphere;
	end

	do
		local Top = Instance.new("Attachment");
		Top.Name = "Top";
		Top.Position = Vector3.new(0,Sphere.Size.Y*.5,0);
		Top.Parent = Sphere;
		
		
		
		local Bottom = Instance.new("Attachment");
		Bottom.Name = "Bottom";
		Bottom.Position = Vector3.new(0,-Sphere.Size.Y*.5,0);
		Bottom.Parent = Sphere;

		local Trail = script.Orb_Trail:Clone();
		Trail.Color = ColorSequence.new(Color)
		Trail.Attachment0 = Top;
		Trail.Attachment1 = Bottom;
		Trail.Parent = Sphere;
		Trail.Enabled = true;
	end
	
	for i= 1,Number_Of_Orbs do
		--for i = 1,RNG(2,4),1 do
		
		if typeof(Color) == "table" then
			
			Color = Color[Seed:NextInteger(1,#Color)]
			
		end
		
		local S_Orb = Sphere:Clone();
		S_Orb.Orb_Trail.Color = ColorSequence.new(Color);
		S_Orb.Color = Color;
		S_Orb.Light.Color = Color;



		local Current_Time = 0;

		coroutine.wrap(function()
			local CurrentAngle,Pitch,Rotation_Per_Sec,Radius = 0, Pitch, Rotation_Per_Second, Radius;

			repeat
				
				if Gather == true then
					S_Orb.CFrame = CFrame.new(Position) * CFrame.Angles(math.rad(Pitch),math.rad(CurrentAngle),0) * CFrame.new(0,0,-Radius*(1-(Current_Time/Duration)))
				elseif Gather == false then
					S_Orb.CFrame = CFrame.new(Position) * CFrame.Angles(math.rad(Pitch),math.rad(CurrentAngle),0) * CFrame.new(0,0,-Radius*((Current_Time/Duration)))
				end
				local delta = RunService.Heartbeat:Wait();
				CurrentAngle = CurrentAngle + (Rotation_Per_Sec * delta);
				Pitch = Pitch + (50 * delta);

				Current_Time += delta

			until (Current_Time) >= Duration or not S_Orb or not S_Orb.Parent

			if S_Orb then
				S_Orb.Transparency = 1;
				S_Orb.Size = Vector3.new()
			end

		end)()

		S_Orb.Parent = workspace
		Debris:AddItem(S_Orb,Duration + 5);

		--Heartbeat:Wait();

		--end
	end
	
end