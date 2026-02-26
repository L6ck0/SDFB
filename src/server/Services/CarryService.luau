local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Config"))

local CarryService = {}

local carriedByPlayer = {}
local baseSpeedByPlayer = {}
local lastPickupAtByPlayer = {}

local function getRootPosition(player)
	local character = player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	return hrp.Position
end

local function setCarrierSpeed(player, isCarrying)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if isCarrying then
		if not baseSpeedByPlayer[player] then
			baseSpeedByPlayer[player] = humanoid.WalkSpeed
		end
		humanoid.WalkSpeed = baseSpeedByPlayer[player] * Config.BrainrotCarrySpeedMultiplier
	else
		if baseSpeedByPlayer[player] then
			humanoid.WalkSpeed = baseSpeedByPlayer[player]
			baseSpeedByPlayer[player] = nil
		end
	end
end

local function bindDropOnDeath(player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		if CarryService.IsCarrying(player) then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local dropPosition = hrp and hrp.Position or nil
			CarryService.Drop(player, dropPosition)
		end
	end)
end

local function attachToCharacter(player, brainrot)
	local character = player.Character
	if not character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	brainrot.Anchored = false
	brainrot.CanCollide = false
	brainrot.Parent = character
	brainrot.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = brainrot
	weld.Part1 = hrp
	weld.Parent = brainrot

	return true
end

local function detachFromCharacter(player, brainrot, dropPosition)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") or nil
	local weld = brainrot:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end

	brainrot.Parent = Workspace:FindFirstChild("Brainrots") or Workspace
	brainrot.Anchored = true
	brainrot.CanCollide = true

	if dropPosition then
		brainrot.Position = dropPosition + Vector3.new(0, 2, 0)
	elseif hrp then
		brainrot.CFrame = hrp.CFrame * CFrame.new(0, -2, -4)
	end
end

function CarryService.IsCarrying(player)
	return carriedByPlayer[player] ~= nil
end

function CarryService.GetCarried(player)
	return carriedByPlayer[player]
end

function CarryService.Pickup(player, brainrot)
	if not player or not brainrot then
		return false
	end

	local now = os.clock()
	local lastPickupAt = lastPickupAtByPlayer[player] or 0
	if (now - lastPickupAt) < Config.BrainrotPickupCooldownSeconds then
		return false
	end

	if brainrot:GetAttribute("Carried") then
		if brainrot:GetAttribute("CarriedBy") == player.UserId then
			return true
		end
		return false
	end

	if CarryService.IsCarrying(player) then
		local dropPosition = getRootPosition(player)
		CarryService.Drop(player, dropPosition)
	end

	local ok = attachToCharacter(player, brainrot)
	if not ok then
		return false
	end

	carriedByPlayer[player] = brainrot
	brainrot:SetAttribute("Carried", true)
	brainrot:SetAttribute("CarriedBy", player.UserId)

	local prompt = brainrot:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	setCarrierSpeed(player, true)
	lastPickupAtByPlayer[player] = now
	return true
end

function CarryService.Drop(player, dropPosition)
	local brainrot = carriedByPlayer[player]
	if not brainrot then
		return
	end

	carriedByPlayer[player] = nil
	brainrot:SetAttribute("Carried", false)
	brainrot:SetAttribute("CarriedBy", nil)

	detachFromCharacter(player, brainrot, dropPosition)

	local prompt = brainrot:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end

	setCarrierSpeed(player, false)
end

function CarryService.Rescue(player)
	local brainrot = carriedByPlayer[player]
	if not brainrot then
		return nil
	end

	local rarity = brainrot:GetAttribute("Rarity") or "Common"
	local brainrotName = brainrot:GetAttribute("BrainrotName") or (rarity .. " Brainrot")
	local incomePerSecond = brainrot:GetAttribute("IncomePerSecond") or (Config.RarityIncomePerSecond[rarity] or 0)
	carriedByPlayer[player] = nil
	setCarrierSpeed(player, false)

	brainrot:Destroy()
	return {
		rarity = rarity,
		brainrotName = brainrotName,
		incomePerSecond = incomePerSecond,
	}
end

function CarryService.ClearAll()
	for player, _ in pairs(carriedByPlayer) do
		CarryService.Drop(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	carriedByPlayer[player] = nil
	baseSpeedByPlayer[player] = nil
	lastPickupAtByPlayer[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		bindDropOnDeath(player)
	end)
end)

return CarryService
