local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local RescueService = require(script.Parent:WaitForChild("RescueService"))
local DisasterService = require(script.Parent:WaitForChild("DisasterService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local MapLoaderService = require(script.Parent:WaitForChild("MapLoaderService"))

local RoundService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local noBaseNoticeEvent = remotes:WaitForChild("NoBaseNotice")
local gateTouchedConnections = setmetatable({}, { __mode = "k" })
local lastGateNoticeAt = setmetatable({}, { __mode = "k" })
local GATE_NOTICE_COOLDOWN = 4

local function getOrCreateStateFolder()
	local folder = ReplicatedStorage:FindFirstChild("RoundState")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RoundState"
		folder.Parent = ReplicatedStorage

		local phase = Instance.new("StringValue")
		phase.Name = "Phase"
		phase.Value = "Boot"
		phase.Parent = folder

		local timeLeft = Instance.new("IntValue")
		timeLeft.Name = "TimeLeft"
		timeLeft.Value = 0
		timeLeft.Parent = folder

		local disasterName = Instance.new("StringValue")
		disasterName.Name = "DisasterName"
		disasterName.Value = "None"
		disasterName.Parent = folder
	end
	return folder
end

local function setPhase(folder, value)
	folder:FindFirstChild("Phase").Value = value
end

local function setTimeLeft(folder, value)
	folder:FindFirstChild("TimeLeft").Value = value
end

local function setDisasterName(folder, value)
	folder:FindFirstChild("DisasterName").Value = value
end

local function gatherZoneParts(container, list)
	if not container then
		return
	end
	if container:IsA("BasePart") then
		table.insert(list, container)
		return
	end
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(list, descendant)
		end
	end
end

local function getDisasterIslandZones()
	local zones = {}
	gatherZoneParts(Workspace:FindFirstChild("DisasterIslandZones"), zones)
	local overlay = MapLoaderService.GetActiveOverlay()
	if overlay then
		local overlayZones = overlay:FindFirstChild("DisasterIslandZones")
		gatherZoneParts(overlayZones, zones)
	end
	if #zones == 0 then
		return nil
	end
	return zones
end

local function isPointInsidePart(part, position)
	local localPos = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size * 0.5 + Vector3.new(0.1, 0.1, 0.1)
	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

local function isPlayerOnDisasterIsland(player, zoneParts)
	zoneParts = zoneParts or getDisasterIslandZones()
	if not zoneParts then
		return true
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	for _, part in ipairs(zoneParts) do
		if isPointInsidePart(part, hrp.Position) then
			return true
		end
	end
	return false
end

local function teleportPlayersOffDisasterIsland()
	local zones = getDisasterIslandZones()
	if not zones then
		BaseService.TeleportAllPlayersToLobby()
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerOnDisasterIsland(player, zones) then
			BaseService.TeleportPlayerToLobby(player)
		end
	end
end

local function setGateState(isIntermission)
	local folder = Workspace:FindFirstChild("IntermissionGates")
	if not folder then
		return
	end
	for _, gate in ipairs(folder:GetDescendants()) do
		if gate:IsA("BasePart") then
			gate.CanCollide = isIntermission
			gate.CanQuery = isIntermission
			gate:SetAttribute("GateIsOpen", not isIntermission)
			if gate:GetAttribute("IsIntermissionGate") ~= true then
				gate:SetAttribute("IsIntermissionGate", true)
			end
			if not gateTouchedConnections[gate] then
				gateTouchedConnections[gate] = gate.Touched:Connect(function(hit)
					local gateIsOpen = gate:GetAttribute("GateIsOpen") == true
					local character = hit.Parent
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if not humanoid then
						return
					end
					local player = Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end
					if player:GetAttribute("HasClaimedBase") then
						return
					end
					if gateIsOpen then
						BaseService.TeleportPlayerToLobby(player)
					end
					local now = os.clock()
					local last = lastGateNoticeAt[player] or 0
					if (now - last) >= GATE_NOTICE_COOLDOWN then
						lastGateNoticeAt[player] = now
						noBaseNoticeEvent:FireClient(player)
					end
				end)
			end
		end
	end
end

function RoundService.Start()
	if RoundService._running then
		return
	end
	RoundService._running = true
	local stateFolder = getOrCreateStateFolder()
	RescueService.EnsureZones()
	MapLoaderService.Init()
	setGateState(true)

	task.spawn(function()
		while RoundService._running do
			print("Intermission...")
			setPhase(stateFolder, "Intermission")
			setDisasterName(stateFolder, "None")
			setGateState(true)
			teleportPlayersOffDisasterIsland()
			for t = Config.IntermissionSeconds, 0, -1 do
				setTimeLeft(stateFolder, t)
				task.wait(1)
			end

			print("Round start")
			setGateState(false)
			setPhase(stateFolder, "ActiveRound")
			local disaster = DisasterService.StartDisaster(Config.RoundDurationSeconds)
			setDisasterName(stateFolder, disaster and disaster.displayName or "Unknown")
			MapLoaderService.LoadDisasterMap(disaster and disaster.id or nil)
			local spawnMarkers = MapLoaderService.GetBrainrotSpawnMarkers()
			BrainrotService.SpawnBrainrots(spawnMarkers)

			for t = Config.RoundDurationSeconds, 0, -1 do
				setTimeLeft(stateFolder, t)
				task.wait(1)
			end

			print("Round end")
			setPhase(stateFolder, "RoundEnd")
			DisasterService.EndDisaster()
			setDisasterName(stateFolder, "None")
			CarryService.ClearAll()
			BrainrotService.ClearBrainrots()
			MapLoaderService.ClearActiveMap()
			PlayerDataService.CommitRoundRescues()
			BaseService.RefreshAllBases()
		end
	end)
end

return RoundService
