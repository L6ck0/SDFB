local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.Size = UDim2.fromOffset(360, 60)
roundLabel.Position = UDim2.fromOffset(16, 16)
roundLabel.BackgroundTransparency = 0.25
roundLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
roundLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundLabel.TextSize = 20
roundLabel.Font = Enum.Font.GothamBold
roundLabel.Text = "Loading..."
roundLabel.Parent = screenGui

local disasterLabel = Instance.new("TextLabel")
disasterLabel.Name = "DisasterLabel"
disasterLabel.Size = UDim2.fromOffset(420, 40)
disasterLabel.Position = UDim2.new(0.5, -210, 0, 16)
disasterLabel.BackgroundTransparency = 0.2
disasterLabel.BackgroundColor3 = Color3.fromRGB(70, 25, 25)
disasterLabel.TextColor3 = Color3.fromRGB(255, 230, 200)
disasterLabel.TextSize = 22
disasterLabel.Font = Enum.Font.GothamBold
disasterLabel.Text = "Disaster: None"
disasterLabel.Parent = screenGui

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Size = UDim2.fromOffset(180, 40)
menuButton.Position = UDim2.fromOffset(16, 84)
menuButton.BackgroundColor3 = Color3.fromRGB(52, 94, 200)
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.TextSize = 16
menuButton.Font = Enum.Font.GothamBold
menuButton.Text = "Base Menu (M)"
menuButton.Parent = screenGui

local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.fromOffset(140, 40)
shopButton.Position = UDim2.fromOffset(204, 84)
shopButton.BackgroundColor3 = Color3.fromRGB(208, 146, 40)
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 16
shopButton.Font = Enum.Font.GothamBold
shopButton.Text = "Robux Shop"
shopButton.Parent = screenGui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.fromOffset(120, 40)
rebirthButton.Position = UDim2.fromOffset(352, 84)
rebirthButton.BackgroundColor3 = Color3.fromRGB(65, 146, 116)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 16
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.Text = "Rebirth"
rebirthButton.Parent = screenGui

local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.fromOffset(120, 40)
settingsButton.Position = UDim2.fromOffset(480, 84)
settingsButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.TextSize = 16
settingsButton.Font = Enum.Font.GothamBold
settingsButton.Text = "Settings"
settingsButton.Parent = screenGui

local menuFrame = Instance.new("Frame")
menuFrame.Name = "BaseMenuFrame"
menuFrame.Size = UDim2.fromOffset(420, 420)
menuFrame.Position = UDim2.fromOffset(16, 132)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
menuFrame.Visible = false
menuFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "My Base Brainrots"
title.Parent = menuFrame

local cashLine = Instance.new("TextLabel")
cashLine.Name = "CashLine"
cashLine.Size = UDim2.new(1, -20, 0, 26)
cashLine.Position = UDim2.fromOffset(10, 52)
cashLine.BackgroundTransparency = 1
cashLine.TextColor3 = Color3.fromRGB(220, 220, 220)
cashLine.TextSize = 16
cashLine.Font = Enum.Font.Gotham
cashLine.TextXAlignment = Enum.TextXAlignment.Left
cashLine.Text = "Cash: 0 | Income: 0/s | In Base: 0"
cashLine.Parent = menuFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "BrainrotList"
scroll.Size = UDim2.new(1, -20, 1, -96)
scroll.Position = UDim2.fromOffset(10, 86)
scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scroll

local function createCloseButton(parent)
	local button = Instance.new("TextButton")
	button.Name = "CloseButton"
	button.Size = UDim2.fromOffset(34, 34)
	button.Position = UDim2.new(1, -44, 0, 8)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.Text = "X"
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

local function createPanel(name, titleText, bodyText)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.fromOffset(360, 220)
	frame.Position = UDim2.fromOffset(16, 132)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	frame.Visible = false
	frame.Parent = screenGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 40)
	titleLabel.Position = UDim2.fromOffset(10, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = titleText
	titleLabel.Parent = frame

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.Size = UDim2.new(1, -20, 1, -64)
	bodyLabel.Position = UDim2.fromOffset(10, 52)
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	bodyLabel.TextSize = 16
	bodyLabel.Font = Enum.Font.Gotham
	bodyLabel.TextWrapped = true
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.Text = bodyText
	bodyLabel.Parent = frame

	local closeButton = createCloseButton(frame)

	return frame, closeButton
end

local menuCloseButton = createCloseButton(menuFrame)
local shopFrame, shopCloseButton = createPanel("ShopFrame", "Robux Shop", "Placeholder: add gamepasses/dev products and purchase buttons here.")
local rebirthFrame, rebirthCloseButton = createPanel("RebirthFrame", "Rebirth", "Placeholder: show rebirth requirement, multiplier reward, and confirm button.")
local settingsFrame, settingsCloseButton = createPanel("SettingsFrame", "Settings", "Placeholder: add toggles for music, SFX, and UI options.")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local deleteEvent = remotes:WaitForChild("DeleteBrainrot")
local baseFullNoticeEvent = remotes:WaitForChild("BaseFullNotice")
local showDeleteConfirmEvent = remotes:WaitForChild("ShowDeleteConfirm")
local noBaseNoticeEvent = remotes:WaitForChild("NoBaseNotice")

local stateFolder = ReplicatedStorage:WaitForChild("RoundState")
local phase = stateFolder:WaitForChild("Phase")
local timeLeft = stateFolder:WaitForChild("TimeLeft")
local disasterName = stateFolder:WaitForChild("DisasterName")

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local runtimeStats = player:WaitForChild("RuntimeStats")
local cashPerSecond = runtimeStats:WaitForChild("CashPerSecond")
local baseBrainrots = player:WaitForChild("BaseBrainrots")

local rowById = {}
local warningToken = 0
local pendingDeleteId = nil
local activePanel = "none"
local panelBeforeConfirm = "none"
local setMenuVisible

local function updateRoundLabel()
	roundLabel.Text = string.format("%s | %ds", phase.Value, timeLeft.Value)
end

local warningLabel = Instance.new("TextLabel")
warningLabel.Name = "WarningLabel"
warningLabel.Size = UDim2.fromOffset(420, 44)
warningLabel.Position = UDim2.new(0.5, -210, 0, 64)
warningLabel.BackgroundTransparency = 0.2
warningLabel.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
warningLabel.TextColor3 = Color3.fromRGB(255, 245, 245)
warningLabel.TextSize = 20
warningLabel.Font = Enum.Font.GothamBold
warningLabel.Visible = false
warningLabel.Text = ""
warningLabel.Parent = screenGui

local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.Size = UDim2.fromOffset(520, 36)
hintLabel.Position = UDim2.new(0.5, -260, 0, 112)
hintLabel.BackgroundTransparency = 0.35
hintLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hintLabel.TextColor3 = Color3.fromRGB(210, 255, 220)
hintLabel.TextStrokeTransparency = 0.7
hintLabel.TextSize = 18
hintLabel.Font = Enum.Font.GothamBold
hintLabel.Text = "Find a green CLAIM BASE marker and press E to claim your base."
hintLabel.Parent = screenGui

local claimRequiredLabel = Instance.new("TextLabel")
claimRequiredLabel.Name = "ClaimRequiredLabel"
claimRequiredLabel.Size = UDim2.new(1, -20, 0, 56)
claimRequiredLabel.Position = UDim2.fromOffset(10, 88)
claimRequiredLabel.BackgroundTransparency = 1
claimRequiredLabel.TextColor3 = Color3.fromRGB(255, 220, 160)
claimRequiredLabel.TextSize = 18
claimRequiredLabel.Font = Enum.Font.GothamBold
claimRequiredLabel.TextWrapped = true
claimRequiredLabel.Visible = false
claimRequiredLabel.Text = "Claim a base first to store, compare, and manage brainrots."
claimRequiredLabel.Parent = menuFrame

local function showWarning(text)
	warningToken += 1
	local token = warningToken

	warningLabel.Text = text
	warningLabel.Visible = true

	task.delay(2, function()
		if warningToken == token then
			warningLabel.Visible = false
		end
	end)
end

local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "DeleteConfirmFrame"
confirmFrame.Size = UDim2.fromOffset(420, 190)
confirmFrame.Position = UDim2.new(0.5, -210, 0.5, -95)
confirmFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
confirmFrame.Visible = false
confirmFrame.Parent = screenGui

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -20, 0, 40)
confirmTitle.Position = UDim2.fromOffset(10, 10)
confirmTitle.BackgroundTransparency = 1
confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmTitle.TextSize = 22
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.Text = "Delete Brainrot?"
confirmTitle.Parent = confirmFrame

local confirmBody = Instance.new("TextLabel")
confirmBody.Size = UDim2.new(1, -20, 0, 72)
confirmBody.Position = UDim2.fromOffset(10, 50)
confirmBody.BackgroundTransparency = 1
confirmBody.TextColor3 = Color3.fromRGB(220, 220, 220)
confirmBody.TextSize = 16
confirmBody.Font = Enum.Font.Gotham
confirmBody.TextWrapped = true
confirmBody.TextXAlignment = Enum.TextXAlignment.Left
confirmBody.TextYAlignment = Enum.TextYAlignment.Top
confirmBody.Text = "Are you sure?"
confirmBody.Parent = confirmFrame

local confirmYes = Instance.new("TextButton")
confirmYes.Size = UDim2.fromOffset(160, 40)
confirmYes.Position = UDim2.new(0.5, -170, 1, -52)
confirmYes.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
confirmYes.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmYes.TextSize = 16
confirmYes.Font = Enum.Font.GothamBold
confirmYes.Text = "Yes, Delete"
confirmYes.Parent = confirmFrame

local confirmNo = Instance.new("TextButton")
confirmNo.Size = UDim2.fromOffset(160, 40)
confirmNo.Position = UDim2.new(0.5, 10, 1, -52)
confirmNo.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
confirmNo.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmNo.TextSize = 16
confirmNo.Font = Enum.Font.GothamBold
confirmNo.Text = "Cancel"
confirmNo.Parent = confirmFrame

local function reopenPanel(panelName)
	if panelName == "base" then
		setMenuVisible(true)
	elseif panelName == "shop" then
		shopFrame.Visible = true
		activePanel = "shop"
	elseif panelName == "rebirth" then
		rebirthFrame.Visible = true
		activePanel = "rebirth"
	elseif panelName == "settings" then
		settingsFrame.Visible = true
		activePanel = "settings"
	end
end

local function closeDeleteConfirm(restorePrevious)
	pendingDeleteId = nil
	confirmFrame.Visible = false
	if activePanel == "confirm" then
		activePanel = "none"
	end
	local previous = panelBeforeConfirm
	panelBeforeConfirm = "none"
	if restorePrevious and previous ~= "none" then
		reopenPanel(previous)
	end
end

local function openDeleteConfirm(brainrotId, brainrotName, source)
	local previous = activePanel
	if previous == "confirm" then
		previous = panelBeforeConfirm
	end
	if previous == nil then
		previous = "none"
	end
	panelBeforeConfirm = previous

	menuFrame.Visible = false
	shopFrame.Visible = false
	rebirthFrame.Visible = false
	settingsFrame.Visible = false
	activePanel = "confirm"
	pendingDeleteId = tostring(brainrotId)
	local fromText = source == "base" and "from your base" or "from your inventory"
	confirmBody.Text = string.format("Are you sure you want to delete '%s' %s?\nThis cannot be undone.", brainrotName or "this brainrot", fromText)
	confirmFrame.Visible = true
end

confirmYes.MouseButton1Click:Connect(function()
	if pendingDeleteId then
		deleteEvent:FireServer(pendingDeleteId)
	end
	closeDeleteConfirm(true)
end)

confirmNo.MouseButton1Click:Connect(function()
	closeDeleteConfirm(true)
end)

local function updateDisasterLabel()
	disasterLabel.Text = "Disaster: " .. disasterName.Value
end

local function updateSummary()
	if player:GetAttribute("HasClaimedBase") ~= true then
		cashLine.Text = "No base claimed yet."
		scroll.Visible = false
		claimRequiredLabel.Visible = true
		return
	end

	local total = 0
	for _, child in ipairs(baseBrainrots:GetChildren()) do
		if child:IsA("StringValue") then
			total += 1
		end
	end
	cashLine.Text = string.format("Cash: %d | Income: %.1f/s | In Base: %d/%d", cash.Value, cashPerSecond.Value, total, Config.BaseCapacity)
	scroll.Visible = true
	claimRequiredLabel.Visible = false
end

local function updateClaimVisuals()
	local hasBase = player:GetAttribute("HasClaimedBase") == true
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		return
	end

	for _, descendant in ipairs(basesFolder:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "ClaimPrompt" then
			descendant.Enabled = not hasBase
		elseif descendant:IsA("Part") and descendant.Name == "ClaimMarker" then
			descendant.LocalTransparencyModifier = hasBase and 1 or 0
		elseif descendant:IsA("BillboardGui") and descendant.Name == "MarkerBillboard" then
			descendant.Enabled = not hasBase
		end
	end
end

local function updateCanvasSize()
	scroll.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
end

local function createRow(item)
	local id = item.Name
	local rarity = item.Value
	local brainrotName = item:GetAttribute("BrainrotName") or (rarity .. " Brainrot")
	local incomePerSecond = item:GetAttribute("IncomePerSecond") or (Config.RarityIncomePerSecond[rarity] or 0)

	local row = Instance.new("Frame")
	row.Name = "Row_" .. id
	row.Size = UDim2.new(1, -8, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
	row.Parent = scroll

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -120, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.format("%s (%s)  +%d/s  #%s", brainrotName, rarity, incomePerSecond, id)
	label.Parent = row

	local deleteButton = Instance.new("TextButton")
	deleteButton.Name = "DeleteButton"
	deleteButton.Size = UDim2.fromOffset(96, 30)
	deleteButton.Position = UDim2.new(1, -104, 0.5, -15)
	deleteButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteButton.TextSize = 14
	deleteButton.Font = Enum.Font.GothamBold
	deleteButton.Text = "Delete"
	deleteButton.Parent = row

	deleteButton.MouseButton1Click:Connect(function()
		openDeleteConfirm(id, brainrotName, "menu")
	end)

	rowById[id] = row
end

local function clearRows()
	for id, row in pairs(rowById) do
		row:Destroy()
		rowById[id] = nil
	end
end

local function rebuildRows()
	clearRows()
	if player:GetAttribute("HasClaimedBase") ~= true then
		updateSummary()
		updateCanvasSize()
		return
	end

	local items = {}
	for _, child in ipairs(baseBrainrots:GetChildren()) do
		if child:IsA("StringValue") then
			items[#items + 1] = child
		end
	end

	table.sort(items, function(a, b)
		local aId = tonumber(a.Name) or 0
		local bId = tonumber(b.Name) or 0
		return aId < bId
	end)

	for _, item in ipairs(items) do
		createRow(item)
	end

	updateSummary()
	updateCanvasSize()
end

function setMenuVisible(visible)
	menuFrame.Visible = visible
	if visible then
		activePanel = "base"
		rebuildRows()
	elseif activePanel == "base" then
		activePanel = "none"
	end
end

local function closePanel(panelName)
	if panelName == "base" then
		if menuFrame.Visible then
			setMenuVisible(false)
		end
		return
	end

	if panelName == "shop" then
		shopFrame.Visible = false
	elseif panelName == "rebirth" then
		rebirthFrame.Visible = false
	elseif panelName == "settings" then
		settingsFrame.Visible = false
	end

	if activePanel == panelName then
		activePanel = "none"
	end
end

local function hideAllPanels()
	menuFrame.Visible = false
	shopFrame.Visible = false
	rebirthFrame.Visible = false
	settingsFrame.Visible = false
	closeDeleteConfirm(false)
	activePanel = "none"
end

menuCloseButton.MouseButton1Click:Connect(function()
	closePanel("base")
end)

shopCloseButton.MouseButton1Click:Connect(function()
	closePanel("shop")
end)

rebirthCloseButton.MouseButton1Click:Connect(function()
	closePanel("rebirth")
end)

settingsCloseButton.MouseButton1Click:Connect(function()
	closePanel("settings")
end)

menuButton.MouseButton1Click:Connect(function()
	local open = activePanel ~= "base"
	hideAllPanels()
	setMenuVisible(open)
end)

task.delay(12, function()
	if hintLabel then
		hintLabel.Visible = false
	end
end)

shopButton.MouseButton1Click:Connect(function()
	local open = activePanel ~= "shop"
	hideAllPanels()
	shopFrame.Visible = open
	if open then
		activePanel = "shop"
	end
end)

rebirthButton.MouseButton1Click:Connect(function()
	local open = activePanel ~= "rebirth"
	hideAllPanels()
	rebirthFrame.Visible = open
	if open then
		activePanel = "rebirth"
	end
end)

settingsButton.MouseButton1Click:Connect(function()
	local open = activePanel ~= "settings"
	hideAllPanels()
	settingsFrame.Visible = open
	if open then
		activePanel = "settings"
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		local open = activePanel ~= "base"
		hideAllPanels()
		setMenuVisible(open)
	end
end)

baseBrainrots.ChildAdded:Connect(function(child)
	if child:IsA("StringValue") then
		rebuildRows()
	end
end)

baseBrainrots.ChildRemoved:Connect(function(child)
	if child:IsA("StringValue") then
		rebuildRows()
	end
end)

phase.Changed:Connect(updateRoundLabel)
timeLeft.Changed:Connect(updateRoundLabel)
disasterName.Changed:Connect(updateDisasterLabel)
cash.Changed:Connect(updateSummary)
cashPerSecond.Changed:Connect(updateSummary)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
baseFullNoticeEvent.OnClientEvent:Connect(function()
	showWarning("Your base is full. Delete a brainrot first.")
end)
noBaseNoticeEvent.OnClientEvent:Connect(function()
	showWarning("First claim a base before picking up brainrots.")
end)
showDeleteConfirmEvent.OnClientEvent:Connect(function(brainrotId, brainrotName, source)
	openDeleteConfirm(brainrotId, brainrotName, source)
end)
player:GetAttributeChangedSignal("HasClaimedBase"):Connect(function()
	updateSummary()
	rebuildRows()
	updateClaimVisuals()
end)

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "ClaimPrompt" or descendant.Name == "ClaimMarker" or descendant.Name == "MarkerBillboard" then
		task.defer(updateClaimVisuals)
	end
end)

updateRoundLabel()
updateDisasterLabel()
rebuildRows()
updateClaimVisuals()
