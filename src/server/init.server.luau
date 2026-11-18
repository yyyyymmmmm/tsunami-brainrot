-- Tsunami Brainrot Bay: server bootstrap.
-- The modules are this script's children; this file only wires them together
-- and starts the game. CharacterData holds the cast, WorldBuilder builds the
-- bay, CharacterFactory builds the creatures, GameManager runs the loop.

local CharacterData = require(script.CharacterData)
local WorldBuilder = require(script.WorldBuilder)
local CharacterFactory = require(script.CharacterFactory)
local GameManager = require(script.GameManager)

GameManager.Start({
	Data = CharacterData,
	World = WorldBuilder,
	Factory = CharacterFactory,
})

print("Tsunami Brainrot Bay is open!")
