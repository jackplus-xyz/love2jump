local serpent = require("lib.serpent.src.serpent")
local GameProgress = {}
-- Define the save directory and ensure it exists
local SAVE_DIR = "saves"
love.filesystem.createDirectory(SAVE_DIR)

-- Helper function to get the full save path
local function getSavePath(slot)
	return SAVE_DIR .. "/save_" .. tostring(slot) .. ".sav"
end

-- -- Function to get current game state
-- function GameProgress.getGameState()
-- 	-- Customize this table based on what you need to save
-- 	return {
-- 		player = {
-- 			position = {
-- 				x = player.x,
-- 				y = player.y,
-- 			},
-- 			health = player.health,
-- 			inventory = player.inventory,
-- 			-- Add other player states
-- 		},
-- 		world = {
-- 			-- Add world state, enemy positions, etc.
-- 		},
-- 		gameplay = {
-- 			score = score,
-- 			time_played = time_played,
-- 			-- Add other gameplay states
-- 		},
-- 	}
-- end

-- Function to save game state
function GameProgress.saveGame(slot, game_state)
	-- Add metadata
	local state = {
		data = game_state,
		metadata = {
			timestamp = os.time(),
			version = "1.0",
			save_slot = slot,
		},
	}

	local serialized = serpent.dump(state, {
		indent = "  ",
		sortkeys = true,
		comment = false,
	})

	local success, message = love.filesystem.write(getSavePath(slot), serialized)
	return success, message
end

-- Function to load game
function GameProgress.loadGame(slot)
	local save_path = getSavePath(slot)

	if not love.filesystem.getInfo(save_path) then
		return false, "No save file found in slot " .. tostring(slot)
	end

	local content = love.filesystem.read(save_path)
	if not content then
		return false, "Failed to read save file"
	end

	local success, state = serpent.load(content, { safe = true })
	if not success then
		return false, "Failed to load save file: " .. tostring(state)
	end

	-- Verify metadata and version compatibility
	if not state.metadata or state.metadata.version ~= "1.0" then
		return false, "Incompatible save file version"
	end

	return true, state.data
end

function GameProgress.testLoadSaveGame(slot)
	local a = {
		1,
		nil,
		3,
		x = 1,
		["true"] = 2,
		[not true] = 3,
		metadata = {
			timestamp = os.time(),
			version = "1.0",
			save_slot = slot,
		},
	}
	love.filesystem.write(getSavePath(slot), serpent.dump(a))

	local save_path = getSavePath(slot)
	local content = love.filesystem.read(save_path)
	local success, state = serpent.load(content, { safe = true })

	print("Unserialzed")
	print(success, state)

	local serialized = serpent.dump(a, {
		indent = "  ",
		sortkeys = true,
		comment = false,
	})

	love.filesystem.write(getSavePath(slot), serialized)
	content = love.filesystem.read(save_path)
	success, state = serpent.load(content, { safe = true })
	print("Serialzed")
	print(success, state)
end

return GameProgress
