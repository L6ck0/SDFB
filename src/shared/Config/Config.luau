local Config = {}

Config.RoundDurationSeconds = 75
Config.IntermissionSeconds = 3
Config.BrainrotSpawnCount = 12
Config.BrainrotSpawnRadius = 180
Config.BrainrotCarrySpeedMultiplier = 0.8
Config.SharedPromptHoldSeconds = 0.45
Config.BrainrotPickupCooldownSeconds = 0.35
Config.BrainrotPickupDistance = 5
Config.BrainrotMinSpawnSpacing = 4
Config.BrainrotSpawnMaxAttempts = 18
Config.EconomyTickSeconds = 1
Config.BaseCapacity = 8
Config.WorldLabelMaxDistance = 45
Config.BaseLabelMaxDistance = 35

Config.RarityOrder = { "Common", "Rare", "Epic", "Mythic", "Secret" }
Config.RaritySpawnWeights = {
	Common = 70,
	Rare = 20,
	Epic = 7,
	Mythic = 2.5,
	Secret = 0.5,
}
Config.SpawnProfiles = {
	Any = {
		Common = 70,
		Rare = 20,
		Epic = 7,
		Mythic = 2.5,
		Secret = 0.5,
	},
	Ground = {
		Common = 75,
		Rare = 18,
		Epic = 5,
		Mythic = 1.8,
		Secret = 0.2,
	},
	High = {
		Common = 45,
		Rare = 28,
		Epic = 17,
		Mythic = 8,
		Secret = 2,
	},
	SecretOnly = {
		Common = 0,
		Rare = 0,
		Epic = 0,
		Mythic = 0,
		Secret = 100,
	},
}
Config.RarityIncomePerSecond = {
	Common = 1,
	Rare = 3,
	Epic = 8,
	Mythic = 20,
	Secret = 60,
}
Config.BrainrotNamesByRarity = {
	Common = { "Niblet", "Boingo", "Pufflet", "Chompy", "Wobbo" },
	Rare = { "Glintroll", "Zappin", "Shiveroo", "Blinkbit", "Rumblet" },
	Epic = { "Voltessa", "Frostbyte", "Nebulurk", "Sparkjaw", "Warpfin" },
	Mythic = { "Aetheron", "Pyroxis", "Chronara", "Oblivisk", "Stormath" },
	Secret = { "Nullshade", "Crownix", "Paradoxon", "Eclipsex", "Voidling Prime" },
}

Config.Disasters = {
	{
		id = "RisingLava",
		displayName = "Rising Lava",
		weight = 50,
	},
	{
		id = "MeteorShower",
		displayName = "Meteor Shower",
		weight = 35,
	},
	{
		id = "StormWinds",
		displayName = "Storm Winds",
		weight = 15,
	},
}

return Config
