local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))
local MapLoaderService = require(script.Parent:WaitForChild("MapLoaderService"))

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

local function getDisasterSettings(disasterId)
	if not Config.DisasterSettings then
		return nil
	end
	return Config.DisasterSettings[disasterId]
end

local function startRisingLava(roundDurationSeconds)
	local settings = getDisasterSettings("RisingLava") or {}
	local bottomY = settings.StartHeight or -35
	local targetTopY = settings.TargetHeight or 25
	if targetTopY <= bottomY then
		targetTopY = bottomY + 1
	end

	local startThickness = settings.StartThickness or 8
	local riseSpeed = settings.Speed or (40 / math.max(1, roundDurationSeconds))

	local lava = Instance.new("Part")
	lava.Name = "DisasterLava"
	lava.Anchored = true
	lava.CanCollide = true
	lava.Color = Color3.fromRGB(255, 85, 0)
	lava.Material = Enum.Material.Neon
	lava.Size = Vector3.new(700, math.max(1, startThickness), 700)
	lava.Parent = Workspace

	local function updateLavaHeight(newTopY)
		local clampedTop = math.max(newTopY, bottomY + 0.5)
		local height = clampedTop - bottomY
		lava.Size = Vector3.new(700, height, 700)
		lava.CFrame = CFrame.new(0, bottomY + height * 0.5, 0)
	end

	updateLavaHeight(math.min(bottomY + startThickness, targetTopY))

	lava.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)

	local running = true
	local currentTop = bottomY + lava.Size.Y
	task.spawn(function()
		while running and lava.Parent do
			if currentTop >= targetTopY then
				task.wait(0.2)
				continue
			end
			local delta = math.min(riseSpeed * 0.2, targetTopY - currentTop)
			currentTop += delta
			updateLavaHeight(currentTop)
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

local function gatherZoneParts(container, parts, seen, includeFoldersOnly)
	if not container then
		return
	end

	local function addZonePart(part)
		if not part:IsA("BasePart") or seen[part] then
			return
		end
		seen[part] = true
		if part:IsDescendantOf(Workspace) then
			part.CanCollide = false
			part.CanQuery = false
		end
		table.insert(parts, part)
	end

	if container:IsA("BasePart") then
		addZonePart(container)
		return
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "MeteorSpawnZones" then
			for _, zonePart in ipairs(descendant:GetDescendants()) do
				if zonePart:IsA("BasePart") then
					addZonePart(zonePart)
				end
			end
		elseif not includeFoldersOnly and descendant:IsA("BasePart") then
			if descendant.Name == "MeteorSpawnZone" or descendant:GetAttribute("IsMeteorSpawnZone") then
				addZonePart(descendant)
			end
		end
	end
end

local function getMeteorSpawnZones()
	local parts = {}
	local seen = {}

	gatherZoneParts(Workspace:FindFirstChild("MeteorSpawnZones"), parts, seen, true)

	local overlay = MapLoaderService.GetActiveOverlay()
	if overlay then
		gatherZoneParts(overlay, parts, seen, false)
	end

	if active.id then
		local modulesFolder = ReplicatedStorage:FindFirstChild("DisasterModules")
		local template = modulesFolder and modulesFolder:FindFirstChild(active.id)
		if template then
			gatherZoneParts(template, parts, seen, false)
		end
	end

	if #parts > 0 then
		return parts
	end

	return nil
end

local function randomBetween(min, max)
	return min + math.random() * (max - min)
end

local function chooseMeteorSpawnPosition()
	local zones = getMeteorSpawnZones()
	if zones then
		local zone = zones[math.random(1, #zones)]
		local halfSize = zone.Size * 0.5
		local offset = Vector3.new(
			randomBetween(-halfSize.X, halfSize.X),
			0,
			randomBetween(-halfSize.Z, halfSize.Z)
		)
		local basePosition = (zone.CFrame * CFrame.new(offset)).Position
		local height = zone:GetAttribute("MeteorSpawnHeight")
		if height then
			return Vector3.new(basePosition.X, height, basePosition.Z)
		end
		return Vector3.new(basePosition.X, math.max(basePosition.Y + 80, 120), basePosition.Z)
	end

	return Vector3.new(math.random(-220, 220), 120, math.random(-220, 220))
end

local function spawnMeteor()
	local position = chooseMeteorSpawnPosition()

	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Material = Enum.Material.Neon
	meteor.Color = Color3.fromRGB(255, 130, 30)
	meteor.Size = Vector3.new(6, 6, 6)
	meteor.CanCollide = false
	meteor.CanQuery = false
	meteor.Position = position
	meteor.Parent = Workspace

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	velocity.Velocity = Vector3.new(math.random(-8, 8), -110, math.random(-8, 8))
	velocity.Parent = meteor

	meteor.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if hit and hit.GetAttribute and hit:GetAttribute("IsIntermissionGate") then
			return
		end
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

local function startTsunami()
	local settings = getDisasterSettings("Tsunami") or {}
	local waveSize = settings.WaveSize or Vector3.new(220, 80, 30)
	local startPosition = settings.StartPosition or Vector3.new(-260, waveSize.Y * 0.5, 0)
	local endPosition = settings.EndPosition or Vector3.new(260, waveSize.Y * 0.5, 0)
	local travelTime = settings.TravelTime or 12
	local interval = settings.Interval or 8

	local running = true
	local activeWaves = {}

	local function spawnWave()
		if not running then
			return
		end
		local wave = Instance.new("Part")
		wave.Name = "TsunamiWave"
		wave.Size = waveSize
		wave.Anchored = true
		wave.CanCollide = true
		wave.CanQuery = true
		wave.Material = Enum.Material.Water
		wave.Color = Color3.fromRGB(80, 170, 255)
		wave.CFrame = CFrame.new(startPosition)
		wave.Parent = Workspace
		table.insert(activeWaves, wave)

		wave.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end)

		local tween = TweenService:Create(
			wave,
			TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
			{ CFrame = CFrame.new(endPosition) }
		)
		tween.Completed:Connect(function()
			wave:Destroy()
		end)
		tween:Play()
	end

	task.spawn(function()
		while running do
			spawnWave()
			task.wait(interval)
		end
	end)

	return function()
		running = false
		for _, wave in ipairs(activeWaves) do
			if wave then
				wave:Destroy()
			end
		end
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
	elseif selected.id == "Tsunami" then
		active.cleanup = startTsunami()
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
