local EconomyService = {}

function EconomyService.Start()
	if EconomyService._running then
		return
	end
	EconomyService._running = true
	-- Passive payouts removed; income is collected via base pads.
end

return EconomyService
