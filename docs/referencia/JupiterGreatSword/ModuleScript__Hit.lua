--[[ 
	
	Scripted by TakeoHonorable. (2/18/2021)
	
	Modularized Smash-esque hit VFX.
]]

-- SERVICES

local Debris = (game:FindService("Debris") or game:GetService("Debris"));

-- VARIABLES

local Camera = workspace.CurrentCamera;

local Lightning = require(script:WaitForChild("LightningBoltParts", math.huge));
local Lightning_Explosion = require(script["LightningBoltParts"]:WaitForChild("LightningExplosion", math.huge));

local BaseUrl = "rbxassetid://";

local Functions = {};

local Hit;

-- FUNCTIONS

function Functions.Medium(Args)
	-- Args[1] = Hit Position, Args[2] = Directory
	local Pos = Args[1];
	local Directory = Args[2];
	local Seed = Random.new();
	
	--warn("Medium hit!");
	coroutine.wrap(function()
		local Impact = script.Impact:Clone();
		Debris:AddItem(Impact, Impact.Lifetime.Max);
		local Color_1 = Color3.fromRGB( Seed:NextInteger(0, 255), Seed:NextInteger(0, 255), Seed:NextInteger(0, 255) );
		local Color_2 = Color3.fromRGB( Seed:NextInteger(0, 255), Seed:NextInteger(0, 255), Seed:NextInteger(0, 255) );
		Impact.Color = ColorSequence.new(Color_1, Color_2);
		Impact.Parent = Directory;
		Impact:Emit(1);
	end)()
end

function Functions.Strong(Args)
	-- Args[1] = Hit Position, Args[2] = Directory
	local Pos = Args[1];
	local Directory = Args[2];
	local Seed = Random.new();
	
	--warn("Strong hit!!");
	Lightning_Explosion.new(Pos, 1, 10, Color3.new(1, 0, 0), ColorSequence.new(Color3.new(1,0,0), Color3.new(1,1,1)), Vector3.new(0, 1, 0) );

	Lightning_Explosion.new(Pos, 1, 10, Color3.new(0, 0, 0), ColorSequence.new(Color3.new(1,0,0), Color3.new(0,0,0)), Vector3.new(0, 1, 0) );
end

Hit = function(Method, ...)

	local Args = table.pack(...);

	-- print(Method, Args);

	assert(typeof(Method) == "string", "Method is not a string.");

	assert(Functions[Method], "'" .. "' is not a valid function.");

	Functions[Method](Args);

end

-- EVENTS


-- MAIN CODE


return Hit;