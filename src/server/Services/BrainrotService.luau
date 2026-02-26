local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local BrainrotService = {}

local rarityColors = {
	Common = Color3.fromRGB(255, 190, 70),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(200, 90, 255),
	Mythic = Color3.fromRGB(255, 120, 120),
	Secret = Color3.fromRGB(255, 255, 255),
}

local function rollRarity()
	local totalWeight = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		totalWeight += Config.RaritySpawnWeights[rarity] or 0
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		cursor += Config.RaritySpawnWeights[rarity] or 0
		if roll <= cursor then
			return rarity
		end
	end

	return "Common"
end

local function chooseBrainrotName(rarity)
	local pool = Config.BrainrotNamesByRarity[rarity]
	if not pool or #pool == 0 then
		return rarity .. " Brainrot"
	end
	return pool[math.random(1, #pool)]
end

local function getOrCreateFolder()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = Workspace
	end
	return folder
end

local function addWorldLabel(part, brainrotName, incomePerSecond)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoBillboard"
	billboard.Size = UDim2.fromOffset(190, 44)
	billboard.StudsOffset = Vector3.new(0, 2.9, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = Config.WorldLabelMaxDistance
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(90, 255, 130)
	label.TextStrokeColor3 = Color3.fromRGB(10, 40, 20)
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Text = string.format("%s\n+%d/s", brainrotName, incomePerSecond)
	label.Parent = billboard
end

local function addPickupPrompt(part)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Brainrot"
	prompt.HoldDuration = Config.SharedPromptHoldSeconds
	prompt.MaxActivationDistance = Config.BrainrotPickupDistance
	prompt.Parent = part
	return prompt
end

function BrainrotService.ClearBrainrots()
	local folder = Workspace:FindFirstChild("Brainrots")
	if folder then
		folder:Destroy()
	end
end

function BrainrotService.SpawnBrainrots()
	BrainrotService.ClearBrainrots()
	local folder = getOrCreateFolder()
	for i = 1, Config.BrainrotSpawnCount do
		local rarity = rollRarity()
		local brainrotName = chooseBrainrotName(rarity)
		local incomePerSecond = Config.RarityIncomePerSecond[rarity] or 0
		local part = Instance.new("Part")
		part.Name = "Brainrot"
		part.Size = Vector3.new(2, 2, 2)
		part.Anchored = true
		part.Color = rarityColors[rarity] or rarityColors.Common
		part.Position = Vector3.new(
			math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius),
			5,
			math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius)
		)
		part:SetAttribute("Rarity", rarity)
		part:SetAttribute("BrainrotName", brainrotName)
		part:SetAttribute("IncomePerSecond", incomePerSecond)
		part.Parent = folder
		addWorldLabel(part, brainrotName, incomePerSecond)

		local prompt = addPickupPrompt(part)
		prompt.ObjectText = brainrotName
		prompt.Triggered:Connect(function(player)
			local CarryService = require(script.Parent:WaitForChild("CarryService"))
			CarryService.Pickup(player, part)
		end)
	end
end

return BrainrotService
