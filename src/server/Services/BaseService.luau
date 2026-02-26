local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local BaseService = {}

local plotsByPlayer = {}
local deleteConfirmEvent

local rarityColors = {
	Common = Color3.fromRGB(255, 190, 70),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(200, 90, 255),
	Mythic = Color3.fromRGB(255, 120, 120),
	Secret = Color3.fromRGB(255, 255, 255),
}

local function getOrCreateBasesFolder()
	local folder = Workspace:FindFirstChild("PlayerBases")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PlayerBases"
		folder.Parent = Workspace
	end
	return folder
end

local function getOrCreateDeleteConfirmEvent()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local event = remotes:FindFirstChild("ShowDeleteConfirm")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "ShowDeleteConfirm"
		event.Parent = remotes
	end
	return event
end

local function getOrCreateLobbySpawn()
	local spawn = Workspace:FindFirstChild("LobbySpawn")
	if spawn and spawn:IsA("SpawnLocation") then
		return spawn
	end

	spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Transparency = 0
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Position = Vector3.new(0, 2, 0)
	spawn.Parent = Workspace
	return spawn
end

local function setPlotLabel(plot, text)
	local pad = plot:FindFirstChild("Pad")
	if not pad then
		return
	end
	local billboard = pad:FindFirstChild("OwnerBillboard")
	if not billboard then
		return
	end
	local label = billboard:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function setClaimPromptEnabled(plot, enabled)
	local pad = plot:FindFirstChild("Pad")
	if not pad then
		return
	end
	local prompt = pad:FindFirstChild("ClaimPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = enabled
	end

	local marker = plot:FindFirstChild("ClaimMarker")
	if marker and marker:IsA("Part") then
		marker.Transparency = enabled and 0.15 or 1
	end
	local markerLabel = marker and marker:FindFirstChild("MarkerBillboard")
	if markerLabel and markerLabel:IsA("BillboardGui") then
		markerLabel.Enabled = enabled
	end
end

local function getFreePlot()
	local folder = getOrCreateBasesFolder()
	for _, plot in ipairs(folder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == 0 then
			return plot
		end
	end
	return nil
end

local function getPlotSpawnPosition(plot)
	local spawnPoint = plot and plot:FindFirstChild("SpawnPoint")
	if spawnPoint and spawnPoint:IsA("Part") then
		return spawnPoint.Position + Vector3.new(0, 3, 0)
	end
	return nil
end

local function teleportCharacter(character, position)
	if not character or not position then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hrp = character:WaitForChild("HumanoidRootPart", 5)
	end
	if hrp then
		character:PivotTo(CFrame.new(position))
	end
end

local function createPlot(name, position, parent)
	local plot = Instance.new("Folder")
	plot.Name = name
	plot:SetAttribute("OwnerUserId", 0)
	plot.Parent = parent

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Size = Vector3.new(48, 1, 48)
	pad.Anchored = true
	pad.Position = position
	pad.Color = Color3.fromRGB(60, 60, 70)
	pad.Parent = plot

	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Size = Vector3.new(3, 1, 3)
	spawnPoint.Anchored = true
	spawnPoint.Position = position + Vector3.new(0, 1.5, 0)
	spawnPoint.Transparency = 1
	spawnPoint.Parent = plot

	local display = Instance.new("Folder")
	display.Name = "Display"
	display.Parent = plot

	local ownerBillboard = Instance.new("BillboardGui")
	ownerBillboard.Name = "OwnerBillboard"
	ownerBillboard.Size = UDim2.fromOffset(240, 50)
	ownerBillboard.StudsOffset = Vector3.new(0, 7, 0)
	ownerBillboard.AlwaysOnTop = true
	ownerBillboard.Parent = pad

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "Unclaimed Base"
	label.Parent = ownerBillboard

	local claimPrompt = Instance.new("ProximityPrompt")
	claimPrompt.Name = "ClaimPrompt"
	claimPrompt.ActionText = "Claim"
	claimPrompt.ObjectText = "Base Plot"
	claimPrompt.HoldDuration = Config.SharedPromptHoldSeconds
	claimPrompt.MaxActivationDistance = 28
	claimPrompt.RequiresLineOfSight = false
	claimPrompt.Style = Enum.ProximityPromptStyle.Default
	claimPrompt.Parent = pad

	claimPrompt.Triggered:Connect(function(player)
		BaseService.AssignPlot(player, plot)
	end)

	local claimMarker = Instance.new("Part")
	claimMarker.Name = "ClaimMarker"
	claimMarker.Size = Vector3.new(6, 6, 6)
	claimMarker.Shape = Enum.PartType.Ball
	claimMarker.Anchored = true
	claimMarker.CanCollide = false
	claimMarker.CanQuery = false
	claimMarker.CastShadow = false
	claimMarker.Material = Enum.Material.Neon
	claimMarker.Color = Color3.fromRGB(90, 255, 130)
	claimMarker.Transparency = 0.15
	claimMarker.Position = position + Vector3.new(0, 8, 0)
	claimMarker.Parent = plot

	local markerBillboard = Instance.new("BillboardGui")
	markerBillboard.Name = "MarkerBillboard"
	markerBillboard.Size = UDim2.fromOffset(180, 40)
	markerBillboard.StudsOffset = Vector3.new(0, 4, 0)
	markerBillboard.AlwaysOnTop = true
	markerBillboard.Parent = claimMarker

	local markerLabel = Instance.new("TextLabel")
	markerLabel.Size = UDim2.fromScale(1, 1)
	markerLabel.BackgroundTransparency = 1
	markerLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
	markerLabel.TextStrokeColor3 = Color3.fromRGB(10, 50, 20)
	markerLabel.TextStrokeTransparency = 0.2
	markerLabel.TextScaled = true
	markerLabel.Font = Enum.Font.GothamBlack
	markerLabel.Text = "CLAIM BASE"
	markerLabel.Parent = markerBillboard

	return plot
end

local function ensurePlots()
	local folder = getOrCreateBasesFolder()
	if #folder:GetChildren() > 0 then
		return folder
	end

	local positions = {
		Vector3.new(-180, 0.5, -180),
		Vector3.new(-120, 0.5, -180),
		Vector3.new(-60, 0.5, -180),
		Vector3.new(0, 0.5, -180),
		Vector3.new(60, 0.5, -180),
		Vector3.new(120, 0.5, -180),
		Vector3.new(180, 0.5, -180),
		Vector3.new(180, 0.5, -120),
	}

	for i, position in ipairs(positions) do
		createPlot(("Plot%02d"):format(i), position, folder)
	end

	return folder
end

function BaseService.AssignPlot(player, targetPlot)
	if plotsByPlayer[player] then
		return plotsByPlayer[player]
	end

	local plot = targetPlot or getFreePlot()
	if not plot then
		return nil
	end
	if plot:GetAttribute("OwnerUserId") ~= 0 then
		return nil
	end

	plot:SetAttribute("OwnerUserId", player.UserId)
	setPlotLabel(plot, player.Name .. "'s Base")
	setClaimPromptEnabled(plot, false)
	plotsByPlayer[player] = plot
	BaseService.RefreshPlayerBase(player)
	return plot
end

function BaseService.ReleasePlot(player)
	local plot = plotsByPlayer[player]
	if not plot then
		return
	end

	plot:SetAttribute("OwnerUserId", 0)
	setPlotLabel(plot, "Unclaimed Base")
	setClaimPromptEnabled(plot, true)
	local display = plot:FindFirstChild("Display")
	if display then
		display:ClearAllChildren()
	end
	plotsByPlayer[player] = nil
end

function BaseService.RefreshPlayerBase(player)
	local plot = plotsByPlayer[player]
	if not plot then
		return
	end

	local entries = PlayerDataService.GetOwnedBrainrotEntries(player)
	if not entries then
		return
	end

	local display = plot:FindFirstChild("Display")
	local pad = plot:FindFirstChild("Pad")
	if not display or not pad then
		return
	end

	display:ClearAllChildren()

	local maxVisuals = Config.BaseCapacity
	local created = 0

	for _, entry in ipairs(entries) do
		if created >= maxVisuals then
			return
		end

		local index = created
		local col = index % 10
		local row = math.floor(index / 10)
		local x = -20 + (col * 4)
		local z = -20 + (row * 4)

		local rarity = entry.rarity
		local color = rarityColors[rarity] or rarityColors.Common
		local brainrotName = entry.brainrotName or (rarity .. " Brainrot")
		local incomePerSecond = entry.incomePerSecond or (Config.RarityIncomePerSecond[rarity] or 0)

		local modelPart = Instance.new("Part")
		modelPart.Name = ("Brainrot_%s"):format(entry.id)
		modelPart.Size = Vector3.new(2.5, 2.5, 2.5)
		modelPart.Anchored = true
		modelPart.Color = color
		modelPart.Position = pad.Position + Vector3.new(x, 2, z)
		modelPart.Parent = display

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "InfoBillboard"
		billboard.Size = UDim2.fromOffset(180, 42)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = Config.BaseLabelMaxDistance
		billboard.Parent = modelPart

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.fromScale(1, 1)
		infoLabel.BackgroundTransparency = 1
		infoLabel.TextColor3 = Color3.fromRGB(90, 255, 130)
		infoLabel.TextStrokeColor3 = Color3.fromRGB(10, 40, 20)
		infoLabel.TextStrokeTransparency = 0.2
		infoLabel.TextScaled = true
		infoLabel.Font = Enum.Font.GothamBold
		infoLabel.TextWrapped = true
		infoLabel.Text = string.format("%s\n+%d/s", brainrotName, incomePerSecond)
		infoLabel.Parent = billboard

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Delete"
		prompt.ObjectText = brainrotName
		prompt.HoldDuration = Config.SharedPromptHoldSeconds
		prompt.MaxActivationDistance = 10
		prompt.Parent = modelPart

		local brainrotId = entry.id
		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer ~= player then
				return
			end
			if deleteConfirmEvent then
				deleteConfirmEvent:FireClient(player, brainrotId, brainrotName, "base")
			end
		end)

		created += 1
	end
end

function BaseService.RefreshAllBases()
	for player, _ in pairs(plotsByPlayer) do
		BaseService.RefreshPlayerBase(player)
	end
end

function BaseService.Init()
	ensurePlots()
	deleteConfirmEvent = getOrCreateDeleteConfirmEvent()
	local lobbySpawn = getOrCreateLobbySpawn()

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local playerPlot = plotsByPlayer[player]
				local spawnPos = playerPlot and getPlotSpawnPosition(playerPlot) or (lobbySpawn.Position + Vector3.new(0, 3, 0))
				teleportCharacter(character, spawnPos)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		BaseService.ReleasePlot(player)
	end)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local playerPlot = plotsByPlayer[player]
				local spawnPos = playerPlot and getPlotSpawnPosition(playerPlot) or (lobbySpawn.Position + Vector3.new(0, 3, 0))
				teleportCharacter(character, spawnPos)
			end)
		end)
	end
end

return BaseService
