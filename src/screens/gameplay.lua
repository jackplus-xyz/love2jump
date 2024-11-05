-- Libraries
local Bump = require("lib.bump.bump")
local Ldtk = require("lib.ldtk-love.ldtk")
local CameraManager = require("lib.CameraMgr.CameraMgr").newManager()

-- Config
local Keymaps = require("config.keymaps")

-- Utilities
local GameProgress = require("src.utils.game_progress")
local world_helpers = require("src.utils.world_helpers")

-- Source Modules
local Ui = require("src.ui")
local Bgm = require("src.bgm")
local Sfx = require("src.sfx")
local Debug = require("src.debug")
local Player = require("src.player")
local Entity = require("src.entity")
local EnemyFactory = require("src.enemy.enemy_factory")

-- Screen State
local screen = {}

-- Game State Variables
local game_state = {
	curr_level_index = nil,
	player_state = {},
	inactive_entities = {},
}
local player = {}
local layers = {}
local collisions = {}
local entities = {}
local inactive_entities = {}
local world
local world_items = {}
local excluded_items = { Collision = true, Hitbox = true }
local default_slot = 1
local default_level_index = 1

-- Level and Game Flow Control
local prev_level_index = nil
local curr_level_index = nil
local is_confirm_quit = false
local is_paused = false
local is_entering = false

--------- LOVE-LDTK CALLBACKS ----------

local function updateInactiveEntities()
	inactive_entities = inactive_entities or {}

	if not prev_level_index then
		if curr_level_index then
			prev_level_index = curr_level_index
		end
	end

	if not inactive_entities[prev_level_index] and prev_level_index then
		inactive_entities[prev_level_index] = {}
	end

	for i, entity in ipairs(entities) do
		-- Add inactive entities to the inactive_entities list
		if not entity.is_active then
			inactive_entities[prev_level_index][entity.iid] = true
		end
	end
end

-- Called just before any other callback when a new level is about to be created
local function onLevelLoaded(level)
	curr_level_index = Ldtk:getCurrent()
	updateInactiveEntities()

	world = Bump.newWorld(GRID_SIZE)
	layers = {}
	collisions = {}
	entities = {}

	CameraManager.unsetBounds()
	CameraManager.unsetDeadzone()
end

local function onLayer(layer)
	if layer.id == "Collision" then
		for _, tile in ipairs(layer.tiles) do
			local collision = {
				id = "Collision",
				x = tile.px[1],
				y = tile.px[2],
				w = GRID_SIZE,
				h = GRID_SIZE,
			}
			world:add(collision, collision.x, collision.y, collision.w, collision.h)
		end
	end
	table.insert(layers, layer) -- Add layer to the table we use to draw
end

local function onEntity(entity)
	if inactive_entities[curr_level_index] and inactive_entities[curr_level_index][entity.iid] then
		return
	end

	if entity.id == "Player" then
		player = Player.new(entity)
	elseif entity.props.Enemy then
		local new_enemy = EnemyFactory.create(entity)
		new_enemy.spawnDrop = function(item)
			item.addToWorld = world_helpers.addToWorld
			item.removeFromWorld = world_helpers.removeFromWorld
			item:addToWorld(world)
			table.insert(entities, item)
		end
		table.insert(entities, new_enemy)
	elseif entity.id == "Door" then
		local new_door = Entity.Door.new(entity)
		table.insert(entities, new_door)
	elseif entity.id == "Coin" then
		local new_coin = Entity.Coin.new(entity)
		table.insert(entities, new_coin)
	end
end

-- Called just after all other callbacks when a new level is created
local function onLevelCreated(level)
	player:addToWorld(world) -- update the player to new world

	for _, entity in pairs(entities) do
		entity.addToWorld = world_helpers.addToWorld
		entity.removeFromWorld = world_helpers.removeFromWorld
		entity:addToWorld(world)

		-- Set player's new location at the door
		if player.next_door and player.next_door.entityIid == entity.iid then
			entity:close()
			local goal_x = entity.x + entity.w / 2 - player.w / 2
			local goal_y = entity.y + entity.h - player.h
			player.x, player.y = goal_x, goal_y
		end
	end

	local window_w = love.graphics.getWidth()
	local window_h = love.graphics.getHeight()
	CameraManager.setBounds(
		-window_w / 2 / SCALE,
		-window_h / 2 / SCALE,
		level.width + window_w / 2 / SCALE,
		level.height + window_h / 2 / SCALE
	)

	love.graphics.setBackgroundColor(level.backgroundColor)
end

--------- Helper Functions  ----------

local function saveGame(slot)
	updateInactiveEntities()
	slot = slot or default_slot
	game_state = {
		curr_level_index = Ldtk:getCurrent(),
		player_state = player:getState(),
		inactive_entities = inactive_entities,
	}

	local success, message = GameProgress.saveGame(slot, game_state)
	if success then
		Sfx:play("ui.confirm")
	else
		Sfx:play("ui.error")
		if IsDebug then
			print(message)
		end
	end

	return success, message
end

local function loadGame(slot)
	slot = slot or default_slot

	local result = GameProgress.loadGame(slot)

	if result then
		game_state = result
		-- Apply the loaded state
		player:setState(game_state.player_state)
		inactive_entities = game_state.inactive_entities
		if not prev_level_index then
			prev_level_index = tonumber(game_state.curr_level_index)
		end
		Ldtk:goTo(tonumber(game_state.curr_level_index))

		Sfx:play("ui.confirm")
	else
		Sfx:play("ui.error")
	end
end

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	self.screenManager = ScreenManager
	local is_load_save = self.screenManager.shared.is_load_save

	-- load ldtk maps
	Ldtk:load("assets/maps/kings-and-pigs.ldtk")
	Ldtk:setFlipped(true)
	Ldtk.onLayer = onLayer
	Ldtk.onEntity = onEntity
	Ldtk.onLevelLoaded = onLevelLoaded
	Ldtk.onLevelCreated = onLevelCreated

	-- TODO: add tutorial
	Ldtk:goTo(default_level_index)
	if is_load_save then
		loadGame()
	end

	Ui.fade_in = Ui.fade:new("in", 1)
	Ui.fade_out = Ui.fade:new("out", 1)
	Ui.hud.player = player

	CameraManager.setScale(SCALE)
	CameraManager.setDeadzone(-GRID_SIZE, -GRID_SIZE, GRID_SIZE, GRID_SIZE)
	CameraManager.setLerp(0.01)
	CameraManager.setCoords(player.x + player.w / SCALE, player.y - player.h * SCALE)

	-- TODO: add fade in to bgm
	Bgm:play()

	Debug:init(world, CameraManager, player)
end

function screen:openDoor(dt)
	is_entering = true
	if Ui.fade_in.is_active then
		Ui.fade_in:update(dt)
		return
	else
		prev_level_index = Ldtk:getCurrent()
		local next_level_index = Ldtk.getIndexByIid(player.next_door.levelIid)
		Ldtk:goTo(next_level_index)
		player.state_machine:setState("door.close")
	end
end

function screen:closeDoor(dt)
	if Ui.fade_out.is_active then
		Ui.fade_out:update(dt)
	else
		is_entering = false
		player.state_machine:setState("grounded")
		Ui.fade_in:reset()
		Ui.fade_out:reset()
	end
end

function screen:handleLevelTransition(dt)
	if player.is_player and player.state_machine:getState("door.open") then
		self:openDoor(dt)
	elseif is_entering then
		self:closeDoor(dt)
	end
end

function screen:Update(dt)
	if is_paused then
		Ui.menu:update(dt)
		Bgm:pause()
		return
	end

	self:handleLevelTransition(dt)

	player:update(dt)

	for _, entity in ipairs(entities) do
		if not entity.is_invisible then
			entity:update(dt)
		end
	end

	for _, collision in ipairs(collisions) do
		collision:update()
	end

	Ui.hud:update(dt)

	if player.state_machine:getState("dead") then
		-- TODO: add fade in to gameover
		self.screenManager:SwitchStates("gameover")
		return
	end

	CameraManager.setTarget(player.x + player.w / 2, player.y + player.h / 2)
	CameraManager.update(dt)

	if IsDebug then
		Debug:update(world)
	end
end

function screen:Draw()
	CameraManager.attach()

	for _, layer in ipairs(layers) do
		layer:draw()
	end

	for _, collision in ipairs(collisions) do
		collision:draw()
	end

	for _, entity in ipairs(entities) do
		if not entity.is_invisible then
			entity:draw()
		end
	end

	player:draw()

	if IsDebug then
		love.graphics.push("all")
		world_items = world:getItems()
		for _, item in pairs(world_items) do
			local x, y, w, h = world:getRect(item)
			if item.id == "Hitbox" then
				love.graphics.setColor(0, 1, 1, 0.1)
				love.graphics.rectangle("fill", x, y, w, h)
				love.graphics.setColor(0, 1, 1)
				love.graphics.rectangle("line", x, y, w, h)
				love.graphics.setColor(1, 1, 1)
				love.graphics.circle("fill", x, y, 1)
			else
				love.graphics.setColor(1, 0, 0, 0.25)
				love.graphics.rectangle("fill", x, y, w, h)
				love.graphics.setColor(1, 0, 0)
				love.graphics.rectangle("line", x, y, w, h)
				love.graphics.setColor(0, 0, 0)
				love.graphics.circle("fill", x, y, 2)
				love.graphics.setColor(1, 1, 1)
				love.graphics.circle("fill", item.x, item.y, 1)
			end
		end
		love.graphics.pop()
	end

	CameraManager.detach()

	Ui.hud:draw()

	if is_entering then
		if Ui.fade_in.is_active then
			Ui.fade_in:draw()
		else
			Ui.fade_out:draw()
		end
	end

	if IsDebug then
		-- CameraManager.debug()
		Debug:draw()
	end

	if is_paused then
		Ui.menu:draw(is_confirm_quit)
	end
end

function screen:KeyPressed(key)
	if is_paused and key == Keymaps.escape then
		is_paused = false
		Bgm:play()
		return
	end

	if is_confirm_quit then
		if key == Keymaps.up or key == Keymaps.down then
			Ui.menu:selectNextChoice()
		elseif key == Keymaps.confirm then
			if Ui.menu.selected_choice then
				love.event.quit()
			else
				Sfx:play("ui.cancel")
				is_confirm_quit = false
			end
		end
	end

	if is_paused then
		if key == Keymaps.confirm then
			if Ui.menu.selected_option == "Resume" then
				is_paused = false
				Bgm:play()
			elseif Ui.menu.selected_option == "Settings" then
			-- TODO: add settings UI
			elseif Ui.menu.selected_option == "Save Game" then
				-- TODO: add slot selection
				local slot
				local success, message = saveGame(slot)
				if success then
					Sfx:play("ui.confirm")
				else
					Sfx:play("ui.error")
					if IsDebug then
						print(message)
					end
				end
			elseif Ui.menu.selected_option == "Load Game" then
				self.screenManager:SwitchStates("loading")
			elseif Ui.menu.selected_option == "Quit" then
				Sfx:play("ui.warning")
				is_confirm_quit = true
				-- love.event.quit()
			end
		end

		if key == Keymaps.up then
			Ui.menu:selectNextOption(-1)
		elseif key == Keymaps.down then
			Ui.menu:selectNextOption()
		end

		return
	end

	if key == Keymaps.escape then
		is_paused = not is_paused
	elseif key == Keymaps.debug then
		IsDebug = not IsDebug
	end

	player:keypressed(key)
end

function screen:KeyReleased(key) end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

return screen
