local Players = game:GetService("Players")

local PlayerService = {}

function PlayerService.Init()
	Players.PlayerAdded:Connect(function(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local rescued = Instance.new("IntValue")
		rescued.Name = "Rescued"
		rescued.Value = 0
		rescued.Parent = leaderstats
	end)
end

return PlayerService