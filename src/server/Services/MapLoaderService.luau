local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapLoaderService = {}

local activeOverlay = nil

local function getOrCreateDisasterModulesFolder()
	local folder = ReplicatedStorage:FindFirstChild("DisasterModules")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DisasterModules"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function createSpawnMarker(parent, name, position)
	local marker = Instance.new("Part")
	marker.Name = name
	marker.Size = Vector3.new(2, 0.4, 2)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Transparency = 0.6
	marker.Color = Color3.fromRGB(50, 255, 150)
	marker.Material = Enum.Material.Neon
	marker.Position = position
	-- Optional attributes for modular control:
	-- SpawnProfile (string): Any/Ground/High/SecretOnly or custom profile from Config.SpawnProfiles
	-- SpawnWeight (number): relative spawn frequency for this marker
	-- AllowedRarities (string): comma list, e.g. "Epic,Mythic,Secret"
	-- RarityWeight_<Rarity> (number): per-marker override, e.g. RarityWeight_Secret = 50
	marker.Parent = parent
	return marker
end

local function ensureBaseSpawnMarkers()
	local folder = Workspace:FindFirstChild("BrainrotSpawnMarkers_Base")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BrainrotSpawnMarkers_Base"
		folder.Parent = Workspace
	end
	if #folder:GetChildren() > 0 then
		return
	end

	createSpawnMarker(folder, "BrainrotSpawn_Ground_A", Vector3.new(-30, 4, -20))
	createSpawnMarker(folder, "BrainrotSpawn_Ground_B", Vector3.new(30, 4, -20))
	createSpawnMarker(folder, "BrainrotSpawn_Ground_C", Vector3.new(0, 4, 30))
	createSpawnMarker(folder, "BrainrotSpawn_Ground_D", Vector3.new(-55, 4, 45))
	createSpawnMarker(folder, "BrainrotSpawn_Ground_E", Vector3.new(55, 4, 45))
end

local function createDefaultDisasterModel(modulesFolder, disasterId)
	local model = Instance.new("Model")
	model.Name = disasterId
	model.Parent = modulesFolder

	local spawns = Instance.new("Folder")
	spawns.Name = "BrainrotSpawnMarkers"
	spawns.Parent = model

	if disasterId == "RisingLava" then
		local platform = Instance.new("Part")
		platform.Name = "LavaPlatform"
		platform.Size = Vector3.new(50, 2, 50)
		platform.Anchored = true
		platform.Color = Color3.fromRGB(120, 120, 120)
		platform.Position = Vector3.new(0, 18, 0)
		platform.Parent = model

		createSpawnMarker(spawns, "BrainrotSpawn_High_A", Vector3.new(-10, 20, -10))
		createSpawnMarker(spawns, "BrainrotSpawn_High_B", Vector3.new(10, 20, -10))
		createSpawnMarker(spawns, "BrainrotSpawn_High_C", Vector3.new(0, 20, 10))
	elseif disasterId == "MeteorShower" then
		local shelter = Instance.new("Part")
		shelter.Name = "MeteorShelter"
		shelter.Size = Vector3.new(24, 14, 24)
		shelter.Anchored = true
		shelter.Color = Color3.fromRGB(80, 80, 90)
		shelter.Position = Vector3.new(0, 8, -45)
		shelter.Parent = model

		createSpawnMarker(spawns, "BrainrotSpawn_Shelter_A", Vector3.new(0, 4, -45))
		createSpawnMarker(spawns, "BrainrotSpawn_Shelter_B", Vector3.new(8, 4, -45))
		createSpawnMarker(spawns, "BrainrotSpawn_Shelter_C", Vector3.new(-8, 4, -45))
	elseif disasterId == "StormWinds" then
		local tower = Instance.new("Part")
		tower.Name = "WindTower"
		tower.Size = Vector3.new(16, 24, 16)
		tower.Anchored = true
		tower.Color = Color3.fromRGB(120, 120, 140)
		tower.Position = Vector3.new(0, 13, 55)
		tower.Parent = model

		createSpawnMarker(spawns, "BrainrotSpawn_Tower_A", Vector3.new(0, 25, 55))
		createSpawnMarker(spawns, "BrainrotSpawn_Tower_B", Vector3.new(6, 25, 55))
		createSpawnMarker(spawns, "BrainrotSpawn_Tower_C", Vector3.new(-6, 25, 55))
	end
end

local function ensureDefaultDisasterModules()
	local modulesFolder = getOrCreateDisasterModulesFolder()
	if #modulesFolder:GetChildren() > 0 then
		return
	end

	createDefaultDisasterModel(modulesFolder, "RisingLava")
	createDefaultDisasterModel(modulesFolder, "MeteorShower")
	createDefaultDisasterModel(modulesFolder, "StormWinds")
end

function MapLoaderService.GetBrainrotSpawnMarkers()
	local markers = {}

	local baseMarkers = Workspace:FindFirstChild("BrainrotSpawnMarkers_Base")
	if baseMarkers then
		for _, child in ipairs(baseMarkers:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(markers, child)
			end
		end
	end

	if activeOverlay then
		local overlayMarkers = activeOverlay:FindFirstChild("BrainrotSpawnMarkers")
		if overlayMarkers then
			for _, child in ipairs(overlayMarkers:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(markers, child)
				end
			end
		end
	end

	return markers
end

function MapLoaderService.ClearActiveMap()
	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
	end
end

function MapLoaderService.LoadDisasterMap(disasterId)
	MapLoaderService.ClearActiveMap()
	if not disasterId then
		return nil
	end

	local modulesFolder = getOrCreateDisasterModulesFolder()
	local template = modulesFolder:FindFirstChild(disasterId)
	if not template then
		return nil
	end

	local overlayContainer = Workspace:FindFirstChild("DisasterOverlay")
	if not overlayContainer then
		overlayContainer = Instance.new("Folder")
		overlayContainer.Name = "DisasterOverlay"
		overlayContainer.Parent = Workspace
	end

	activeOverlay = template:Clone()
	activeOverlay.Name = "Active_" .. disasterId
	activeOverlay.Parent = overlayContainer
	return activeOverlay
end

function MapLoaderService.Init()
	ensureBaseSpawnMarkers()
	ensureDefaultDisasterModules()
end

return MapLoaderService
