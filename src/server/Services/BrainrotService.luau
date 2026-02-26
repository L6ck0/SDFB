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

local function rollFromWeights(weights)
	local totalWeight = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		totalWeight += weights[rarity] or 0
	end
	if totalWeight <= 0 then
		return "Common"
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		cursor += weights[rarity] or 0
		if roll <= cursor then
			return rarity
		end
	end

	return "Common"
end

local function defaultRarityWeights()
	return Config.RaritySpawnWeights
end

local function chooseBrainrotName(rarity)
	local pool = Config.BrainrotNamesByRarity[rarity]
	if not pool or #pool == 0 then
		return rarity .. " Brainrot"
	end
	return pool[math.random(1, #pool)]
end

local function getSpawnProfileName(marker)
	local explicit = marker:GetAttribute("SpawnProfile")
	if type(explicit) == "string" and explicit ~= "" then
		return explicit
	end

	local name = marker.Name
	local prefix = "BrainrotSpawn_"
	if string.sub(name, 1, #prefix) ~= prefix then
		return "Any"
	end
	local suffix = string.sub(name, #prefix + 1)
	local profile = string.match(suffix, "^[^_]+")
	return profile or "Any"
end

local function parseAllowedRarities(marker)
	local raw = marker:GetAttribute("AllowedRarities")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end

	local allowed = {}
	for token in string.gmatch(raw, "[^,]+") do
		local trimmed = string.gsub(token, "^%s*(.-)%s*$", "%1")
		if trimmed ~= "" then
			allowed[trimmed] = true
		end
	end
	return allowed
end

local function getRarityWeightsForMarker(marker)
	local profileName = getSpawnProfileName(marker)
	local profileWeights = Config.SpawnProfiles[profileName] or Config.SpawnProfiles.Any or defaultRarityWeights()
	local allowed = parseAllowedRarities(marker)

	local out = {}
	for _, rarity in ipairs(Config.RarityOrder) do
		local weight = profileWeights[rarity] or 0
		local override = marker:GetAttribute("RarityWeight_" .. rarity)
		if type(override) == "number" then
			weight = override
		end
		if allowed and not allowed[rarity] then
			weight = 0
		end
		out[rarity] = math.max(0, weight)
	end
	return out
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

local function chooseSpawnMarker(markers)
	local total = 0
	local weighted = {}
	for _, marker in ipairs(markers) do
		if marker:IsA("BasePart") then
			local area = math.max(1, marker.Size.X * marker.Size.Z)
			local multiplier = marker:GetAttribute("SpawnWeight")
			if type(multiplier) ~= "number" then
				multiplier = 1
			end
			local weight = area * math.max(0, multiplier)
			if weight > 0 then
				total += weight
				weighted[#weighted + 1] = { marker = marker, weight = weight }
			end
		end
	end

	if total <= 0 then
		return nil
	end

	local roll = math.random() * total
	local cursor = 0
	for _, node in ipairs(weighted) do
		cursor += node.weight
		if roll <= cursor then
			return node.marker
		end
	end

	return weighted[#weighted].marker
end

local function getRandomPointOnMarker(marker)
	local halfX = marker.Size.X * 0.5
	local halfZ = marker.Size.Z * 0.5
	local localOffset = Vector3.new(
		math.random() * marker.Size.X - halfX,
		(marker.Size.Y * 0.5) + 1.2,
		math.random() * marker.Size.Z - halfZ
	)
	return (marker.CFrame * CFrame.new(localOffset)).Position
end

local function isFarEnough(position, existingPositions, minDistance)
	for _, other in ipairs(existingPositions) do
		if (other - position).Magnitude < minDistance then
			return false
		end
	end
	return true
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

function BrainrotService.SpawnBrainrots(spawnMarkers)
	BrainrotService.ClearBrainrots()
	local folder = getOrCreateFolder()
	local useMarkers = spawnMarkers and #spawnMarkers > 0
	local placedPositions = {}

	for i = 1, Config.BrainrotSpawnCount do
		local chosenMarker = nil
		local chosenPosition = nil
		local rarityWeights = defaultRarityWeights()

		for attempt = 1, Config.BrainrotSpawnMaxAttempts do
			local marker = nil
			local candidatePosition

			if useMarkers then
				marker = chooseSpawnMarker(spawnMarkers)
				if marker then
					candidatePosition = getRandomPointOnMarker(marker)
				end
			end

			if not candidatePosition then
				candidatePosition = Vector3.new(
					math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius),
					5,
					math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius)
				)
			end

			if isFarEnough(candidatePosition, placedPositions, Config.BrainrotMinSpawnSpacing) then
				chosenMarker = marker
				chosenPosition = candidatePosition
				break
			end
		end

		if not chosenPosition then
			if useMarkers then
				chosenMarker = chooseSpawnMarker(spawnMarkers)
				chosenPosition = chosenMarker and getRandomPointOnMarker(chosenMarker) or Vector3.new(0, 5, 0)
			else
				chosenPosition = Vector3.new(
					math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius),
					5,
					math.random(-Config.BrainrotSpawnRadius, Config.BrainrotSpawnRadius)
				)
			end
		end

		if chosenMarker then
			rarityWeights = getRarityWeightsForMarker(chosenMarker)
		end

		local rarity = rollFromWeights(rarityWeights)
		local brainrotName = chooseBrainrotName(rarity)
		local incomePerSecond = Config.RarityIncomePerSecond[rarity] or 0
		local part = Instance.new("Part")
		part.Name = "Brainrot"
		part.Size = Vector3.new(2, 2, 2)
		part.Anchored = true
		part.Color = rarityColors[rarity] or rarityColors.Common
		part.Position = chosenPosition
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

		table.insert(placedPositions, chosenPosition)
	end
end

return BrainrotService
