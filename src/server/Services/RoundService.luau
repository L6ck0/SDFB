local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local RescueService = require(script.Parent:WaitForChild("RescueService"))
local DisasterService = require(script.Parent:WaitForChild("DisasterService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local RoundService = {}

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

function RoundService.Start()
	if RoundService._running then
		return
	end
	RoundService._running = true
	local stateFolder = getOrCreateStateFolder()
	RescueService.EnsureZones()

	task.spawn(function()
		while RoundService._running do
			print("Intermission...")
			setPhase(stateFolder, "Intermission")
			setDisasterName(stateFolder, "None")
			for t = Config.IntermissionSeconds, 0, -1 do
				setTimeLeft(stateFolder, t)
				task.wait(1)
			end

			print("Round start")
			setPhase(stateFolder, "ActiveRound")
			BrainrotService.SpawnBrainrots()
			local disaster = DisasterService.StartDisaster(Config.RoundDurationSeconds)
			setDisasterName(stateFolder, disaster and disaster.displayName or "Unknown")

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
			PlayerDataService.CommitRoundRescues()
			BaseService.RefreshAllBases()
		end
	end)
end

return RoundService
