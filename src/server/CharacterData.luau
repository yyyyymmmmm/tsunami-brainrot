-- CharacterData: the brainrot cast, the rarity ladder and the game's tuning numbers.
-- One job: hold the data every other module reads. Nothing in here runs.

local CharacterData = {}

-- The rarity ladder. LabelColor paints the name over a character's head;
-- SpawnWeight steers wild spawns, EggWeight steers the egg machine.
CharacterData.RARITIES = {
	Common = { Order = 1, LabelColor = Color3.fromRGB(215, 215, 215), SpawnWeight = 55, EggWeight = 45 },
	Rare = { Order = 2, LabelColor = Color3.fromRGB(85, 165, 255), SpawnWeight = 25, EggWeight = 30 },
	Epic = { Order = 3, LabelColor = Color3.fromRGB(178, 102, 255), SpawnWeight = 12, EggWeight = 16 },
	Legendary = { Order = 4, LabelColor = Color3.fromRGB(255, 192, 45), SpawnWeight = 6, EggWeight = 7 },
	Mythic = { Order = 5, LabelColor = Color3.fromRGB(255, 84, 164), SpawnWeight = 2, EggWeight = 2 },
}

-- The cast: twelve original absurd creatures, invented for this bay.
-- BodyShape and Accessory tell CharacterFactory how to build each one from parts.
CharacterData.CHARACTERS = {
	{ Name = "Patatino Fritto", Rarity = "Common", CashPerSecond = 1, Scale = 0.9,
		BodyColor = Color3.fromRGB(199, 150, 74), AccentColor = Color3.fromRGB(240, 205, 130),
		BodyShape = "Ball", Accessory = "None" },
	{ Name = "Gattino Pizzaiolo", Rarity = "Common", CashPerSecond = 2, Scale = 1.0,
		BodyColor = Color3.fromRGB(233, 141, 62), AccentColor = Color3.fromRGB(255, 240, 214),
		BodyShape = "Block", Accessory = "ChefHat" },
	{ Name = "Ranocchio Gelato", Rarity = "Common", CashPerSecond = 3, Scale = 0.95,
		BodyColor = Color3.fromRGB(97, 188, 92), AccentColor = Color3.fromRGB(255, 170, 200),
		BodyShape = "Ball", Accessory = "EyeStalks" },
	{ Name = "Pinguino Espresso", Rarity = "Rare", CashPerSecond = 6, Scale = 1.0,
		BodyColor = Color3.fromRGB(42, 46, 68), AccentColor = Color3.fromRGB(245, 245, 240),
		BodyShape = "Block", Accessory = "Belly" },
	{ Name = "Mucca Burrata", Rarity = "Rare", CashPerSecond = 10, Scale = 1.1,
		BodyColor = Color3.fromRGB(240, 238, 230), AccentColor = Color3.fromRGB(245, 160, 180),
		BodyShape = "Block", Accessory = "Horns" },
	{ Name = "Squalo Surfista", Rarity = "Epic", CashPerSecond = 18, Scale = 1.1,
		BodyColor = Color3.fromRGB(70, 130, 212), AccentColor = Color3.fromRGB(170, 215, 250),
		BodyShape = "Block", Accessory = "Fin" },
	{ Name = "Fenicottero DJ", Rarity = "Epic", CashPerSecond = 26, Scale = 0.95,
		BodyColor = Color3.fromRGB(246, 121, 172), AccentColor = Color3.fromRGB(60, 60, 70),
		BodyShape = "Block", Accessory = "LongNeck" },
	{ Name = "Drago Spaghetto", Rarity = "Legendary", CashPerSecond = 48, Scale = 1.15,
		BodyColor = Color3.fromRGB(62, 172, 92), AccentColor = Color3.fromRGB(250, 214, 90),
		BodyShape = "Block", Accessory = "Wings" },
	{ Name = "Leone Limonata", Rarity = "Legendary", CashPerSecond = 70, Scale = 1.1,
		BodyColor = Color3.fromRGB(242, 201, 62), AccentColor = Color3.fromRGB(226, 128, 40),
		BodyShape = "Ball", Accessory = "Mane" },
	{ Name = "Re Polpo d'Oro", Rarity = "Mythic", CashPerSecond = 130, Scale = 1.15,
		BodyColor = Color3.fromRGB(246, 190, 42), AccentColor = Color3.fromRGB(214, 48, 49),
		BodyShape = "Ball", Accessory = "Crown", Accessory2 = "Tentacles" },
	{ Name = "Unicorno Cannolo", Rarity = "Mythic", CashPerSecond = 180, Scale = 1.05,
		BodyColor = Color3.fromRGB(250, 240, 216), AccentColor = Color3.fromRGB(246, 150, 190),
		BodyShape = "Block", Accessory = "Horn" },
	{ Name = "Galassia Gelatina", Rarity = "Mythic", CashPerSecond = 260, Scale = 1.2,
		BodyColor = Color3.fromRGB(152, 92, 222), AccentColor = Color3.fromRGB(110, 230, 240),
		BodyShape = "Ball", Accessory = "Tentacles" },
}

-- Characters grouped by rarity name, filled in once for the spawner and the egg machine.
CharacterData.BY_RARITY = {}
for _, character in ipairs(CharacterData.CHARACTERS) do
	local bucket = CharacterData.BY_RARITY[character.Rarity]
	if not bucket then
		bucket = {}
		CharacterData.BY_RARITY[character.Rarity] = bucket
	end
	table.insert(bucket, character)
end

-- Tuning: money, caps and the tsunami clock, all in one place.
CharacterData.CONFIG = {
	StartCash = 100,
	EggCost = 100,
	WanderCap = 18, -- wild characters roaming the field at once
	ActiveCap = 40, -- wild plus carried characters at once
	PadsPerBase = 6, -- banked characters a base can hold
	BaseCount = 8,
	TsunamiInterval = 85, -- calm seconds between waves
	TsunamiWarning = 10, -- countdown seconds before a wave lands
	WaveTravelTime = 7, -- seconds the wave takes to cross the bay
	RebirthBaseCost = 2500,
	RebirthCostGrowth = 5,
}

return CharacterData
