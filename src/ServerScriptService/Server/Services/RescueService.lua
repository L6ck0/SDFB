local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryService = require(script.Parent:WaitForChild("CarryService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local RescueService = {}

local function getOrCreateBaseFullEvent()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local event = remotes:FindFirstChild("BaseFullNotice")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "BaseFullNotice"
		event.Parent = remotes
	end

	return event
end

local baseFullEvent = getOrCreateBaseFullEvent()

local function getOrCreateFolder()
	local folder = Workspace:FindFirstChild("RescueZones")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RescueZones"
		folder.Parent = Workspace
	end
	return folder
end

local function bindZonePart(part)
	if part:GetAttribute("RescueBound") then
		return
	end
	part:SetAttribute("RescueBound", true)
	part.Anchored = true
	-- Respect whatever collision setting the designer used in Studio.

	local debounce = {}
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
		if not humanoid then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		if debounce[player] then
			return
		end
		debounce[player] = true

		if CarryService.IsCarrying(player) then
			if PlayerDataService.HasBaseCapacity(player) then
				local rescueData = CarryService.Rescue(player)
				local added = PlayerDataService.AddRoundRescue(player, rescueData)
				if added then
					BaseService.RefreshPlayerBase(player)
				end
			else
				baseFullEvent:FireClient(player)
			end
		end

		task.delay(0.5, function()
			debounce[player] = nil
		end)
	end)
end

local function createZone(folder, name, cframe, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size or Vector3.new(14, 1, 14)
	part.CFrame = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	part.Color = Color3.fromRGB(70, 200, 120)
	part.Transparency = 0.2
	part.Parent = folder
	bindZonePart(part)
end

function RescueService.EnsureZones()
	local folder = getOrCreateFolder()
	local disableFallback = folder:GetAttribute("SkipAutoZones") == true
	local existing = false

	local function bindChildren()
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("BasePart") then
				bindZonePart(child)
				existing = true
			end
		end
	end

	bindChildren()
	folder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			bindZonePart(child)
		end
	end)

	if existing or disableFallback then
		return
	end

	local anchorsRoot = Workspace:FindFirstChild("MapAnchors")
	local rescueAnchors = {}
	if anchorsRoot then
		local anchorFolder = anchorsRoot:FindFirstChild("RescueZones")
		if anchorFolder then
			for _, anchor in ipairs(anchorFolder:GetChildren()) do
				if anchor:IsA("BasePart") then
					table.insert(rescueAnchors, anchor)
				end
			end
		end
	end

	if #rescueAnchors > 0 then
		table.sort(rescueAnchors, function(a, b)
			return a.Name < b.Name
		end)

		for index, anchor in ipairs(rescueAnchors) do
			local zoneName = anchor:GetAttribute("ZoneName") or anchor.Name
			if zoneName == "" then
				zoneName = ("Zone%d"):format(index)
			end
			local sizeX = anchor:GetAttribute("ZoneSizeX") or 14
			local sizeZ = anchor:GetAttribute("ZoneSizeZ") or 14
			local zoneSize = Vector3.new(sizeX, 1, sizeZ)
			createZone(folder, zoneName, anchor.CFrame, zoneSize)
		end
		return
	end

	createZone(folder, "ZoneA", CFrame.new(40, 1, 40), Vector3.new(14, 1, 14))
	createZone(folder, "ZoneB", CFrame.new(-40, 1, 40), Vector3.new(14, 1, 14))
	createZone(folder, "ZoneC", CFrame.new(0, 1, -60), Vector3.new(14, 1, 14))
end

return RescueService
