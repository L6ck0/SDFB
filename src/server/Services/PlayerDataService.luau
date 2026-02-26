local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local PlayerDataService = {}

local dataByPlayer = {}
local brainrotDataStore = DataStoreService:GetDataStore("SDFB_PlayerData_v1")
local SAVE_INTERVAL_SECONDS = 180
local MIN_SECONDS_BETWEEN_SAVES = 60
local CASH_DIRTY_INTERVAL_SECONDS = 60
local MAX_SAVE_RETRIES = 3
local isShuttingDown = false

local function emptyCounts()
	local counts = {}
	for _, rarity in ipairs(Config.RarityOrder) do
		counts[rarity] = 0
	end
	return counts
end

local function ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local rescued = leaderstats:FindFirstChild("Rescued")
	if not rescued then
		rescued = Instance.new("IntValue")
		rescued.Name = "Rescued"
		rescued.Value = 0
		rescued.Parent = leaderstats
	end

	local roundRescued = leaderstats:FindFirstChild("RoundRescued")
	if not roundRescued then
		roundRescued = Instance.new("IntValue")
		roundRescued.Name = "RoundRescued"
		roundRescued.Value = 0
		roundRescued.Parent = leaderstats
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = leaderstats
	end

	return rescued, roundRescued, cash
end

local function ensureBaseBrainrotsFolder(player)
	local folder = player:FindFirstChild("BaseBrainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BaseBrainrots"
		folder.Parent = player
	end
	folder:ClearAllChildren()
	return folder
end

local function ensureRuntimeStats(player)
	local runtimeStats = player:FindFirstChild("RuntimeStats")
	if not runtimeStats then
		runtimeStats = Instance.new("Folder")
		runtimeStats.Name = "RuntimeStats"
		runtimeStats.Parent = player
	end

	local cashPerSecond = runtimeStats:FindFirstChild("CashPerSecond")
	if not cashPerSecond then
		cashPerSecond = Instance.new("NumberValue")
		cashPerSecond.Name = "CashPerSecond"
		cashPerSecond.Value = 0
		cashPerSecond.Parent = runtimeStats
	end

	return runtimeStats
end

local function computeIncomePerSecond(counts)
	local total = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		local amount = counts[rarity] or 0
		local value = Config.RarityIncomePerSecond[rarity] or 0
		total += amount * value
	end
	return total
end

local function getTotalOwnedCount(data)
	local total = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		total += data.ownedCounts[rarity] or 0
	end
	return total
end

local function syncIncomeValueObject(data)
	data.runtimeStats.CashPerSecond.Value = computeIncomePerSecond(data.ownedCounts)
end

local function chooseBrainrotName(rarity)
	local pool = Config.BrainrotNamesByRarity[rarity]
	if not pool or #pool == 0 then
		return rarity .. " Brainrot"
	end
	return pool[math.random(1, #pool)]
end

local function resolveRescueData(rescueData)
	if type(rescueData) == "table" then
		local rarity = rescueData.rarity or "Common"
		if Config.RarityIncomePerSecond[rarity] == nil then
			rarity = "Common"
		end
		local name = tostring(rescueData.brainrotName or chooseBrainrotName(rarity))
		local income = tonumber(rescueData.incomePerSecond) or (Config.RarityIncomePerSecond[rarity] or 0)
		return rarity, name, income
	end

	local rarity = tostring(rescueData or "Common")
	if Config.RarityIncomePerSecond[rarity] == nil then
		rarity = "Common"
	end
	return rarity, chooseBrainrotName(rarity), Config.RarityIncomePerSecond[rarity] or 0
end

local function createBrainrotEntry(data, rarity, brainrotName, incomePerSecond)
	local id = tostring(data.nextBrainrotId)
	data.nextBrainrotId += 1

	local entry = {
		id = id,
		rarity = rarity,
		brainrotName = brainrotName,
		incomePerSecond = incomePerSecond,
	}

	data.brainrots[id] = entry
	data.ownedCounts[rarity] += 1

	local item = Instance.new("StringValue")
	item.Name = id
	item.Value = rarity
	item:SetAttribute("BrainrotName", brainrotName)
	item:SetAttribute("IncomePerSecond", incomePerSecond)
	item.Parent = data.baseBrainrotsFolder
end

local function tryAddOwnedBrainrot(data, rescueData)
	local safeRarity, brainrotName, incomePerSecond = resolveRescueData(rescueData)
	if getTotalOwnedCount(data) >= Config.BaseCapacity then
		return false
	end

	createBrainrotEntry(data, safeRarity, brainrotName, incomePerSecond)
	syncIncomeValueObject(data)
	return true
end

local function addLoadedBrainrotEntry(data, id, rarity, brainrotName, incomePerSecond)
	local safeRarity, safeName, safeIncome = resolveRescueData({
		rarity = rarity,
		brainrotName = brainrotName,
		incomePerSecond = incomePerSecond,
	})

	local stringId = tostring(id)
	local numericId = tonumber(stringId)
	if numericId and numericId >= data.nextBrainrotId then
		data.nextBrainrotId = numericId + 1
	end

	data.brainrots[stringId] = {
		id = stringId,
		rarity = safeRarity,
		brainrotName = safeName,
		incomePerSecond = safeIncome,
	}
	data.ownedCounts[safeRarity] += 1

	local item = Instance.new("StringValue")
	item.Name = stringId
	item.Value = safeRarity
	item:SetAttribute("BrainrotName", safeName)
	item:SetAttribute("IncomePerSecond", safeIncome)
	item.Parent = data.baseBrainrotsFolder
end

local function loadPlayerData(player, data)
	local key = ("player_%d"):format(player.UserId)
	local ok, result = pcall(function()
		return brainrotDataStore:GetAsync(key)
	end)
	if not ok then
		warn(("PlayerData load failed for %s: %s"):format(player.Name, tostring(result)))
		return
	end
	if type(result) ~= "table" then
		return
	end

	if type(result.cash) == "number" then
		data.cash = result.cash
		data.leaderstats.cash.Value = math.floor(data.cash)
	end

	if type(result.nextBrainrotId) == "number" then
		data.nextBrainrotId = math.max(1, math.floor(result.nextBrainrotId))
	end

	if type(result.brainrots) == "table" then
		for _, item in ipairs(result.brainrots) do
			if type(item) == "table" and item.id ~= nil and type(item.rarity) == "string" then
				addLoadedBrainrotEntry(data, item.id, item.rarity, item.brainrotName, item.incomePerSecond)
			end
		end
	end
end

local function serializeBrainrots(data)
	local list = {}
	for id, entry in pairs(data.brainrots) do
		list[#list + 1] = {
			id = id,
			rarity = entry.rarity,
			brainrotName = entry.brainrotName,
			incomePerSecond = entry.incomePerSecond,
		}
	end
	table.sort(list, function(a, b)
		local aId = tonumber(a.id) or 0
		local bId = tonumber(b.id) or 0
		return aId < bId
	end)
	return list
end

local function savePlayer(player)
	local data = dataByPlayer[player]
	if not data then
		return false
	end
	if not data.isDirty and not data.hasUnsavedCash then
		return false
	end

	local now = os.clock()
	if (now - data.lastSaveAt) < MIN_SECONDS_BETWEEN_SAVES then
		return false
	end

	local payload = {
		cash = data.cash,
		nextBrainrotId = data.nextBrainrotId,
		brainrots = serializeBrainrots(data),
	}
	local key = ("player_%d"):format(player.UserId)

	local ok, err = false, nil
	for attempt = 1, MAX_SAVE_RETRIES do
		ok, err = pcall(function()
			brainrotDataStore:SetAsync(key, payload)
		end)
		if ok then
			break
		end
		task.wait(0.4 * attempt)
	end
	if not ok then
		warn(("PlayerData save failed for %s after retries: %s"):format(player.Name, tostring(err)))
		return false
	end

	data.isDirty = false
	data.hasUnsavedCash = false
	data.lastSaveAt = now
	return true
end

local function forceSavePlayer(player)
	local data = dataByPlayer[player]
	if not data then
		return false
	end
	if not data.isDirty and not data.hasUnsavedCash then
		return false
	end

	local payload = {
		cash = data.cash,
		nextBrainrotId = data.nextBrainrotId,
		brainrots = serializeBrainrots(data),
	}
	local key = ("player_%d"):format(player.UserId)

	local ok, err = false, nil
	for attempt = 1, MAX_SAVE_RETRIES do
		ok, err = pcall(function()
			brainrotDataStore:SetAsync(key, payload)
		end)
		if ok then
			break
		end
		task.wait(0.4 * attempt)
	end
	if not ok then
		warn(("PlayerData force save failed for %s after retries: %s"):format(player.Name, tostring(err)))
		return false
	end

	data.isDirty = false
	data.hasUnsavedCash = false
	data.lastSaveAt = os.clock()
	return true
end

local function initPlayer(player)
	player:SetAttribute("DataReady", false)
	local rescuedValue, roundRescuedValue, cashValue = ensureLeaderstats(player)
	local baseBrainrotsFolder = ensureBaseBrainrotsFolder(player)
	local runtimeStats = ensureRuntimeStats(player)

	local data = {
		brainrots = {},
		ownedCounts = emptyCounts(),
		pending = emptyCounts(),
		nextBrainrotId = 1,
		cash = 0,
		leaderstats = {
			rescued = rescuedValue,
			roundRescued = roundRescuedValue,
			cash = cashValue,
		},
		baseBrainrotsFolder = baseBrainrotsFolder,
		runtimeStats = runtimeStats,
		isDirty = false,
		hasUnsavedCash = false,
		lastSaveAt = 0,
		lastCashDirtyAt = 0,
	}

	dataByPlayer[player] = data
	loadPlayerData(player, data)
	data.leaderstats.rescued.Value = getTotalOwnedCount(data)
	syncIncomeValueObject(data)
	player:SetAttribute("DataReady", true)
end

local function getData(player)
	return dataByPlayer[player]
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(initPlayer)
	Players.PlayerRemoving:Connect(function(player)
		if not isShuttingDown then
			forceSavePlayer(player)
		end
		dataByPlayer[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end

	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				savePlayer(player)
			end
		end
	end)

	game:BindToClose(function()
		isShuttingDown = true
		for _, player in ipairs(Players:GetPlayers()) do
			forceSavePlayer(player)
		end
	end)
end

function PlayerDataService.AddRoundRescue(player, rescueData)
	local data = getData(player)
	if not data then
		return false
	end

	local added = tryAddOwnedBrainrot(data, rescueData)
	if not added then
		return false
	end

	data.leaderstats.roundRescued.Value += 1
	data.leaderstats.rescued.Value += 1
	data.isDirty = true
	return true
end

function PlayerDataService.CommitRoundRescues()
	for _, data in pairs(dataByPlayer) do
		for _, rarity in ipairs(Config.RarityOrder) do
			data.pending[rarity] = 0
		end
		data.leaderstats.roundRescued.Value = 0
	end
end

function PlayerDataService.GetOwnedCounts(player)
	local data = getData(player)
	if not data then
		return nil
	end
	return data.ownedCounts
end

function PlayerDataService.HasBaseCapacity(player)
	local data = getData(player)
	if not data then
		return false
	end
	return getTotalOwnedCount(data) < Config.BaseCapacity
end

function PlayerDataService.GetOwnedBrainrotEntries(player)
	local data = getData(player)
	if not data then
		return nil
	end

	local list = {}
	for id, entry in pairs(data.brainrots) do
		list[#list + 1] = {
			id = id,
			rarity = entry.rarity,
			brainrotName = entry.brainrotName,
			incomePerSecond = entry.incomePerSecond,
		}
	end

	table.sort(list, function(a, b)
		local aId = tonumber(a.id) or 0
		local bId = tonumber(b.id) or 0
		return aId < bId
	end)

	return list
end

function PlayerDataService.GetIncomePerSecond(player)
	local data = getData(player)
	if not data then
		return 0
	end
	return computeIncomePerSecond(data.ownedCounts)
end

function PlayerDataService.AddCashFromIncome(player, amount)
	local data = getData(player)
	if not data then
		return
	end
	data.cash += amount
	data.leaderstats.cash.Value = math.floor(data.cash)
	data.hasUnsavedCash = true

	local now = os.clock()
	if (now - data.lastCashDirtyAt) >= CASH_DIRTY_INTERVAL_SECONDS then
		data.isDirty = true
		data.lastCashDirtyAt = now
	end
end

function PlayerDataService.DeleteOwnedBrainrotById(player, brainrotId)
	local data = getData(player)
	if not data then
		return false
	end

	local id = tostring(brainrotId or "")
	local entry = data.brainrots[id]
	if not entry then
		return false
	end

	data.brainrots[id] = nil
	data.ownedCounts[entry.rarity] = math.max(0, (data.ownedCounts[entry.rarity] or 0) - 1)

	local valueObject = data.baseBrainrotsFolder:FindFirstChild(id)
	if valueObject then
		valueObject:Destroy()
	end

	syncIncomeValueObject(data)
	data.isDirty = true
	return true
end

return PlayerDataService
