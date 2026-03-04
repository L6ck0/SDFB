local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

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

local function ensureBaseSpawnMarkers()
	local folder = Workspace:FindFirstChild("BrainrotSpawnMarkers_Base")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BrainrotSpawnMarkers_Base"
		folder.Parent = Workspace
	end
	-- Designers manually place Part markers under this folder. BrainrotService
	-- reads attributes such as SpawnProfile, SpawnWeight, AllowedRarities, and
	-- per-rarity overrides straight from those instances.
end

local function applyDisasterSettings(disasterId, overlay)
	local settings = Config.DisasterSettings and Config.DisasterSettings[disasterId]
	if not settings or not overlay then
		return
	end
	if disasterId == "RisingLava" and settings.PlatformHeight then
		local platform = overlay:FindFirstChild("LavaPlatform", true)
		if platform and platform:IsA("BasePart") then
			local cf = platform.CFrame
			local pos = Vector3.new(cf.Position.X, settings.PlatformHeight, cf.Position.Z)
			platform.CFrame = CFrame.fromMatrix(pos, cf.RightVector, cf.UpVector, cf.LookVector)
		end
	end
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
	applyDisasterSettings(disasterId, activeOverlay)
	return activeOverlay
end

function MapLoaderService.Init()
	ensureBaseSpawnMarkers()
end

function MapLoaderService.GetActiveOverlay()
	return activeOverlay
end

return MapLoaderService
