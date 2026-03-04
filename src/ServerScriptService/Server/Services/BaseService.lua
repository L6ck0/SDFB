local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local BaseService = {}

local plotsByPlayer = {}
local deleteConfirmEvent
local DEFAULT_PAD_SIZE = Config.BasePlotSize or Vector3.new(48, 1, 48)
local DISPLAY_COLUMNS = 10
local DISPLAY_SPACING = 4
local DISPLAY_EDGE_MARGIN = 4
local COLLECT_COOLDOWN = Config.BrainrotCollectCooldownSeconds or 1
local collectCooldownByPad = setmetatable({}, { __mode = "k" })
local lobbySpawnPosition = Vector3.new(0, 3, 0)
local playerTeleportsPending = setmetatable({}, { __mode = "k" })

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

local function getLobbySpawnPosition()
	local spawn = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("LobbySpawn")
	if spawn and spawn:IsA("BasePart") then
		return spawn.Position + Vector3.new(0, 3, 0)
	end
	return Vector3.new(0, 3, 0)
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

local function createPlot(name, baseCFrame, parent, padSize)
	local plot = Instance.new("Folder")
	plot.Name = name
	plot:SetAttribute("OwnerUserId", 0)
	plot.Parent = parent

	local targetCFrame = baseCFrame or CFrame.new(Vector3.new(0, 0.5, 0))
	local padSizeVector = padSize or DEFAULT_PAD_SIZE
	local padHeight = padSizeVector.Y > 0 and padSizeVector.Y or 1
	local padVector = Vector3.new(padSizeVector.X, padHeight, padSizeVector.Z)

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Size = padVector
	pad.Anchored = true
	pad.CFrame = targetCFrame
	pad.Color = Color3.fromRGB(60, 60, 70)
	pad.Parent = plot

	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Size = Vector3.new(3, 1, 3)
	spawnPoint.Anchored = true
	spawnPoint.CFrame = targetCFrame * CFrame.new(0, (padVector.Y * 0.5) + 1.5, 0)
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
	claimPrompt.MaxActivationDistance = 12
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
	claimMarker.CFrame = targetCFrame * CFrame.new(0, (padVector.Y * 0.5) + 8, 0)
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

local function getMapAnchors(subFolder)
	local anchorsRoot = Workspace:FindFirstChild("MapAnchors")
	if not anchorsRoot then
		return {}
	end
	local folder = anchorsRoot:FindFirstChild(subFolder)
	if not folder then
		return {}
	end

	local anchors = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(anchors, child)
		end
	end

	table.sort(anchors, function(a, b)
		return a.Name < b.Name
	end)

	return anchors
end

local function ensurePlots()
	local folder = getOrCreateBasesFolder()
	local anchors = getMapAnchors("BasePlots")
	if #anchors > 0 then
		folder:ClearAllChildren()
		for index, anchor in ipairs(anchors) do
			local name = anchor:GetAttribute("PlotName") or anchor.Name
			if name == "" then
				name = ("Plot%02d"):format(index)
			end
			local sizeX = anchor:GetAttribute("PadSizeX") or DEFAULT_PAD_SIZE.X
			local sizeY = anchor:GetAttribute("PadSizeY") or DEFAULT_PAD_SIZE.Y
			local sizeZ = anchor:GetAttribute("PadSizeZ") or DEFAULT_PAD_SIZE.Z
			local padSizeVector = Vector3.new(sizeX, sizeY, sizeZ)
			createPlot(name, anchor.CFrame, folder, padSizeVector)
		end
		return folder
	end

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
		createPlot(("Plot%02d"):format(i), CFrame.new(position), folder, DEFAULT_PAD_SIZE)
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
	player:SetAttribute("HasClaimedBase", true)
	BaseService.RefreshPlayerBase(player)
	return plot
end

function BaseService.ReleasePlot(player)
	local plot = plotsByPlayer[player]
	if not plot then
		return
	end

	local pendingTeleport = playerTeleportsPending[player]
	if pendingTeleport then
		pendingTeleport:Disconnect()
		playerTeleportsPending[player] = nil
	end

	PlayerDataService.ResetBrainrotAccrual(player)
	plot:SetAttribute("OwnerUserId", 0)
	setPlotLabel(plot, "Unclaimed Base")
	setClaimPromptEnabled(plot, true)
	local display = plot:FindFirstChild("Display")
	if display then
		display:ClearAllChildren()
	end
	plotsByPlayer[player] = nil
	player:SetAttribute("HasClaimedBase", false)
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
	local padCFrame = pad.CFrame
	local padSize = pad.Size
	local startX = -(padSize.X * 0.5) + DISPLAY_EDGE_MARGIN
	local startZ = -(padSize.Z * 0.5) + DISPLAY_EDGE_MARGIN
	local heightOffset = (padSize.Y * 0.5) + 2

	for _, entry in ipairs(entries) do
		if created >= maxVisuals then
			return
		end

		local index = created
		local col = index % DISPLAY_COLUMNS
		local row = math.floor(index / DISPLAY_COLUMNS)
		local x = startX + (col * DISPLAY_SPACING)
		local z = startZ + (row * DISPLAY_SPACING)
		local modelCFrame = padCFrame * CFrame.new(x, heightOffset, z)

		local rarity = entry.rarity
		local color = rarityColors[rarity] or rarityColors.Common
		local brainrotName = entry.brainrotName or (rarity .. " Brainrot")
		local incomePerSecond = entry.incomePerSecond or (Config.RarityIncomePerSecond[rarity] or 0)

	local modelPart = Instance.new("Part")
	modelPart.Name = ("Brainrot_%s"):format(entry.id)
	modelPart.Size = Vector3.new(2.5, 2.5, 2.5)
	modelPart.Anchored = true
	modelPart.Color = color
	modelPart.CFrame = modelCFrame
	modelPart.Parent = display

	local collectPad = Instance.new("Part")
	collectPad.Name = ("CollectPad_%s"):format(entry.id)
	collectPad.Size = Vector3.new(2.6, 0.4, 2.6)
	collectPad.Anchored = true
	collectPad.CanCollide = false
	collectPad.CanQuery = false
	collectPad.Transparency = 0.25
	collectPad.Color = Color3.fromRGB(90, 255, 160)
	collectPad.Material = Enum.Material.Neon
	collectPad.CFrame = modelCFrame * CFrame.new(0, -1.3, 2.2)
	collectPad.Parent = display

	local collectBillboard = Instance.new("BillboardGui")
	collectBillboard.Size = UDim2.fromOffset(160, 32)
	collectBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
	collectBillboard.AlwaysOnTop = true
	collectBillboard.Parent = collectPad

	local collectLabel = Instance.new("TextLabel")
	collectLabel.Size = UDim2.fromScale(1, 1)
	collectLabel.BackgroundTransparency = 1
	collectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectLabel.TextStrokeTransparency = 0.2
	collectLabel.Font = Enum.Font.GothamBold
	collectLabel.TextScaled = true
	collectLabel.Text = "+0"
	collectLabel.Parent = collectBillboard

	local labelAlive = true
	task.spawn(function()
		while labelAlive and collectPad.Parent do
			local pending = PlayerDataService.AccumulateBrainrotIncome(player, entry.id)
			collectLabel.Text = string.format("+%d", math.floor(pending + 0.5))
			task.wait(1)
		end
	end)
	collectPad.AncestryChanged:Connect(function(_, parent)
		if not parent then
			labelAlive = false
		end
	end)

	collectPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local touchingPlayer = Players:GetPlayerFromCharacter(character)
		if touchingPlayer ~= player then
			return
		end
		local now = os.clock()
		local nextAllowed = collectCooldownByPad[collectPad] or 0
		if now < nextAllowed then
			return
		end
		collectCooldownByPad[collectPad] = now + COLLECT_COOLDOWN
		local amount = PlayerDataService.CollectBrainrotIncome(player, entry.id)
		if amount > 0 then
			PlayerDataService.AddCashFromIncome(player, amount)
			local pending = PlayerDataService.GetBrainrotBankedIncome(player, entry.id)
			collectLabel.Text = string.format("+%d", math.floor(pending + 0.5))
		end
	end)

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

function BaseService.GetLobbySpawnPosition()
	return lobbySpawnPosition
end

function BaseService.TeleportPlayerToLobby(player)
	if not player then
		return
	end
	local function doTeleport(character)
		teleportCharacter(character, lobbySpawnPosition or getLobbySpawnPosition())
		playerTeleportsPending[player] = nil
	end
	local character = player.Character
	if character then
		doTeleport(character)
	else
		local conn
		conn = player.CharacterAdded:Connect(function(char)
			if conn then
				conn:Disconnect()
				conn = nil
			end
			doTeleport(char)
		end)
		playerTeleportsPending[player] = conn
	end
end

function BaseService.TeleportAllPlayersToLobby()
	for _, player in ipairs(Players:GetPlayers()) do
		BaseService.TeleportPlayerToLobby(player)
	end
end

function BaseService.TeleportPlayerToBase(player)
	if not player then
		return
	end
	local plot = plotsByPlayer[player]
	local spawnPos = plot and getPlotSpawnPosition(plot)
	if not spawnPos then
		BaseService.TeleportPlayerToLobby(player)
		return
	end
	local function doTeleport(character)
		teleportCharacter(character, spawnPos)
		playerTeleportsPending[player] = nil
	end
	local character = player.Character
	if character then
		doTeleport(character)
	else
		local conn
		conn = player.CharacterAdded:Connect(function(char)
			if conn then
				conn:Disconnect()
				conn = nil
			end
			doTeleport(char)
		end)
		playerTeleportsPending[player] = conn
	end
end

function BaseService.TeleportAllPlayersToBase()
	for _, player in ipairs(Players:GetPlayers()) do
		BaseService.TeleportPlayerToBase(player)
	end
end

function BaseService.Init()
	ensurePlots()
	deleteConfirmEvent = getOrCreateDeleteConfirmEvent()
	lobbySpawnPosition = getLobbySpawnPosition()

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("HasClaimedBase", false)
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local playerPlot = plotsByPlayer[player]
				local spawnPos = playerPlot and getPlotSpawnPosition(playerPlot) or lobbySpawnPosition
				teleportCharacter(character, spawnPos)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		BaseService.ReleasePlot(player)
	end)

	for _, player in Players:GetPlayers() do
		if player:GetAttribute("HasClaimedBase") == nil then
			player:SetAttribute("HasClaimedBase", false)
		end
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local playerPlot = plotsByPlayer[player]
				local spawnPos = playerPlot and getPlotSpawnPosition(playerPlot) or lobbySpawnPosition
				teleportCharacter(character, spawnPos)
			end)
		end)
	end
end

return BaseService
