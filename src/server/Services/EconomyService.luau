local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local EconomyService = {}

function EconomyService.Start()
	if EconomyService._running then
		return
	end
	EconomyService._running = true

	task.spawn(function()
		while EconomyService._running do
			for _, player in ipairs(Players:GetPlayers()) do
				local incomePerSecond = PlayerDataService.GetIncomePerSecond(player)
				local amount = incomePerSecond * Config.EconomyTickSeconds
				if amount > 0 then
					PlayerDataService.AddCashFromIncome(player, amount)
				end
			end
			task.wait(Config.EconomyTickSeconds)
		end
	end)
end

return EconomyService
