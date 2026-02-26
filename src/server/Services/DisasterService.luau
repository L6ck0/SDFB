local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local DisasterService = {}

local active = {
	id = nil,
	displayName = "None",
	cleanup = nil,
}

local function chooseDisaster()
	local totalWeight = 0
	for _, disaster in ipairs(Config.Disasters) do
		totalWeight += disaster.weight or 0
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, disaster in ipairs(Config.Disasters) do
		cursor += disaster.weight or 0
		if roll <= cursor then
			return disaster
		end
	end

	return Config.Disasters[1]
end

local function startRisingLava(roundDurationSeconds)
	local lava = Instance.new("Part")
	lava.Name = "DisasterLava"
	lava.Anchored = true
	lava.CanCollide = true
	lava.Color = Color3.fromRGB(255, 85, 0)
	lava.Material = Enum.Material.Neon
	lava.Size = Vector3.new(700, 10, 700)
	lava.Position = Vector3.new(0, -35, 0)
	lava.Parent = Workspace

	lava.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)

	local risePerSecond = 40 / math.max(1, roundDurationSeconds)
	local running = true
	task.spawn(function()
		while running and lava.Parent do
			lava.Position += Vector3.new(0, risePerSecond * 0.2, 0)
			task.wait(0.2)
		end
	end)

	return function()
		running = false
		if lava then
			lava:Destroy()
		end
	end
end

local function spawnMeteor()
	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Material = Enum.Material.Neon
	meteor.Color = Color3.fromRGB(255, 130, 30)
	meteor.Size = Vector3.new(6, 6, 6)
	meteor.CanCollide = true
	meteor.Position = Vector3.new(math.random(-220, 220), 120, math.random(-220, 220))
	meteor.Parent = Workspace

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	velocity.Velocity = Vector3.new(math.random(-8, 8), -110, math.random(-8, 8))
	velocity.Parent = meteor

	meteor.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
		local blast = Instance.new("Explosion")
		blast.BlastRadius = 8
		blast.BlastPressure = 0
		blast.Position = meteor.Position
		blast.Parent = Workspace
		meteor:Destroy()
	end)

	Debris:AddItem(meteor, 5)
end

local function startMeteorShower()
	local running = true
	task.spawn(function()
		while running do
			for _ = 1, 3 do
				spawnMeteor()
			end
			task.wait(1.25)
		end
	end)

	return function()
		running = false
	end
end

local function startStormWinds()
	local running = true
	task.spawn(function()
		while running do
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
				local hrp = character and character:FindFirstChild("HumanoidRootPart") or nil
				if humanoid and hrp then
					hrp.AssemblyLinearVelocity += Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
				end
			end
			task.wait(0.8)
		end
	end)

	return function()
		running = false
	end
end

function DisasterService.StartDisaster(roundDurationSeconds)
	DisasterService.EndDisaster()

	local selected = chooseDisaster()
	active.id = selected.id
	active.displayName = selected.displayName

	if selected.id == "RisingLava" then
		active.cleanup = startRisingLava(roundDurationSeconds)
	elseif selected.id == "MeteorShower" then
		active.cleanup = startMeteorShower()
	elseif selected.id == "StormWinds" then
		active.cleanup = startStormWinds()
	else
		active.cleanup = nil
	end

	return {
		id = active.id,
		displayName = active.displayName,
	}
end

function DisasterService.EndDisaster()
	if active.cleanup then
		active.cleanup()
	end
	active.id = nil
	active.displayName = "None"
	active.cleanup = nil
end

return DisasterService
