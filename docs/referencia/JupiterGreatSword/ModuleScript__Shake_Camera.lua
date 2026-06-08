--[[ 
	
	Scripted by TakeoHonorable. (2/15/2021)
	
	Modularized camera shake effect for conveniece.
]]

-- SERVICES

local RunService = (game:FindService("RunService") or game:GetService("RunService"));

-- VARIABLES

local Shake_Camera;

-- FUNCTIONS

Shake_Camera = function(...)
	local Args = table.pack(...);
	-- Arg1 = Amplitude, Arg2 = Duration, Arg3 = Range(Determines how intense the shake will be relative to the point specified), Arg4(Origin of camera shake)
	assert(RunService:IsClient(), "Executor is not a client.");
	-- print(Args);;
	local Camera = workspace.CurrentCamera;
	local Seed = Random.new(tick());
	local current_duration = 0;
	local Center = Camera.CFrame;
	-- local Orig_CFrame = Camera.CFrame
	--print("Camera shake activated!");
	repeat
		local mult = math.clamp(1 - ((Args[4] - Center.Position).Magnitude / Args[3]), 0, 1);
		local amp = Args[1] * mult * (1 - (current_duration / Args[2]));
		Camera.CFrame = Camera.CFrame * CFrame.new(Seed:NextNumber(-amp, amp), Seed:NextNumber(-amp, amp), Seed:NextNumber(-amp, amp));
		current_duration += RunService.RenderStepped:Wait();
	until not current_duration or current_duration >= Args[2];
	-- Camera.CFrame = Args[5]
end

-- EVENTS


-- MAIN CODE

return Shake_Camera;
