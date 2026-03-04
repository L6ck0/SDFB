local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local InventoryService = {}

local function getOrCreateRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function getOrCreateDeleteEvent()
	local remotes = getOrCreateRemotesFolder()
	local deleteEvent = remotes:FindFirstChild("DeleteBrainrot")
	if not deleteEvent then
		deleteEvent = Instance.new("RemoteEvent")
		deleteEvent.Name = "DeleteBrainrot"
		deleteEvent.Parent = remotes
	end
	return deleteEvent
end

local function getOrCreateShowDeleteConfirmEvent()
	local remotes = getOrCreateRemotesFolder()
	local showConfirmEvent = remotes:FindFirstChild("ShowDeleteConfirm")
	if not showConfirmEvent then
		showConfirmEvent = Instance.new("RemoteEvent")
		showConfirmEvent.Name = "ShowDeleteConfirm"
		showConfirmEvent.Parent = remotes
	end
	return showConfirmEvent
end

local function getOrCreateNoBaseNoticeEvent()
	local remotes = getOrCreateRemotesFolder()
	local noBaseEvent = remotes:FindFirstChild("NoBaseNotice")
	if not noBaseEvent then
		noBaseEvent = Instance.new("RemoteEvent")
		noBaseEvent.Name = "NoBaseNotice"
		noBaseEvent.Parent = remotes
	end
	return noBaseEvent
end

function InventoryService.Init()
	local deleteEvent = getOrCreateDeleteEvent()
	getOrCreateShowDeleteConfirmEvent()
	getOrCreateNoBaseNoticeEvent()
	deleteEvent.OnServerEvent:Connect(function(player, brainrotId)
		local ok = PlayerDataService.DeleteOwnedBrainrotById(player, brainrotId)
		if ok then
			BaseService.RefreshPlayerBase(player)
		end
	end)
end

return InventoryService
