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

local function createZone(folder, name, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(14, 1, 14)
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Color = Color3.fromRGB(70, 200, 120)
	part.Transparency = 0.2
	part.Parent = folder

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

function RescueService.EnsureZones()
	local folder = getOrCreateFolder()
	if folder:FindFirstChild("ZoneA") then
		return
	end

	createZone(folder, "ZoneA", Vector3.new(40, 1, 40))
	createZone(folder, "ZoneB", Vector3.new(-40, 1, 40))
	createZone(folder, "ZoneC", Vector3.new(0, 1, -60))
end

return RescueService
