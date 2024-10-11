-- Libraries
local Ldtk = require("lib.ldtk-love.ldtk")
local Bump = require("lib.bump.bump")
local Fonts = require("src.assets.fonts")
local World = Bump.newWorld(GRID_SIZE)
local CameraManager = require("lib.CameraMgr.CameraMgr").newManager()
local screen = {}

-- Config
local Keymaps = require("config.keymaps")

-- Source
local Ui = require("src.ui")
local Bgm = require("src.bgm")
local Sfx = require("src.sfx")
local Player = require("src.player")
local Enemy = require("src.enemy")
local Door = require("src.door")
local Coin = require("src.coin")
local Debug = require("src.debug")

local class = require("classic")
local object = class:extend()

function object:new(entity)
	-- setting up the object using the entity data
	self.x, self.y = entity.x, entity.y
	self.w, self.h = entity.width, entity.height
	self.visible = entity.visible
end

function object:draw()
	if self.visible then
		--draw a rectangle to represent the entity
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	end
end

-- Vars
local player = {}
local level_blocks = {}
local level_entities = {}
local level_enemies = {}
local world_items = {}

local is_paused = false
local is_entering = false

-------- Debug --------
local function addBlock(x, y, w, h)
	local block = { x = x, y = y, w = w, h = h }
	World:add(block, x, y, w, h)
end

local function drawBox(box, r, g, b)
	love.graphics.push()

	love.graphics.setColor(r, g, b, 0.25)
	love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
	love.graphics.setColor(r, g, b)
	love.graphics.rectangle("line", box.x, box.y, box.w, box.h)

	love.graphics.pop()
end
--------- LOVE-LDTK CALLBACKS ----------
local function onEntity(entity)
	-- Ensure the player is already created
	if entity.id == "Player" and not player.is_player then
		player = Player.new(entity.x, entity.y, World)
		World:add(player, player.x - player.width / 2, player.y - player.height, player.width, player.height)
	elseif entity.id == "Enemy" then
		local new_enemy = Enemy.new(entity.x, entity.y, entity.props, World)
		World:add(
			new_enemy,
			new_enemy.x - new_enemy.width,
			new_enemy.y - new_enemy.height,
			new_enemy.width,
			new_enemy.height
		)
		table.insert(level_enemies, new_enemy)
	elseif entity.id == "Door" then
		local new_door = Door.new(entity.x, entity.y, entity.props, World)
		World:add(
			new_door,
			new_door.x - new_door.x_offset,
			new_door.y - new_door.y_offset,
			new_door.width,
			new_door.height
		)
		table.insert(level_entities, new_door)
	elseif entity.id == "Coin" then
		local new_coin = Coin.new(entity.x, entity.y, World)
		World:add(
			new_coin,
			new_coin.x - new_coin.x_offset,
			new_coin.y - new_coin.y_offset,
			new_coin.width,
			new_coin.height
		)
		table.insert(level_entities, new_coin)
	else
		-- Draw other entites as a rectangle
		-- local new_object = object(entity)
		-- table.insert(level_blocks, new_object)
	end
end

local function onLayer(layer)
	-- Here we treated the layer as an object and added it to the table we use to draw.
	-- Generally, you would create a new object and use that object to draw the layer.

	if layer.id == "Collision" then
		for i in ipairs(layer.tiles) do
			addBlock(layer.tiles[i].px[1], layer.tiles[i].px[2], GRID_SIZE, GRID_SIZE)
		end
	end
	table.insert(level_blocks, layer) --adding layer to the table we use to draw
end

local function onLevelLoaded(level)
	local _, len = World:getItems()

	-- removing all objects so we have a blank level
	for _, world_item in pairs(world_items) do
		if World:hasItem(world_item) then
			World:remove(world_item)
		end
	end

	level_blocks = {}
	level_entities = {}
	level_enemies = {}

	CameraManager.unsetBounds()
	CameraManager.unsetDeadzone()

	--changing background color to the one defined in LDtk
	love.graphics.setBackgroundColor(level.backgroundColor)
end

local function onLevelCreated(level)
	--Here we use a string defined in LDtk as a function
	if level.props.create then
		load(level.props.create)()
	end

	if player then
		for _, entity in pairs(level_entities) do
			if entity.is_door and not entity.is_next then
				player.x, player.y = entity.x - player.width / 2, entity.y - player.height
			end
		end
	end

	local window_width = love.graphics.getWidth()
	local window_height = love.graphics.getHeight()
	CameraManager.setBounds(
		-window_width / 2 / SCALE,
		-window_height / 2 / SCALE,
		level.width + window_width / 2 / SCALE,
		level.height + window_height / 2 / SCALE
	)
end
--------------------------------------------

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	-- load ldtk maps
	Ldtk:load("assets/maps/kings-and-pigs.ldtk")
	Ldtk:setFlipped(true)
	Ldtk.onLayer = onLayer
	Ldtk.onEntity = onEntity
	Ldtk.onLevelLoaded = onLevelLoaded
	Ldtk.onLevelCreated = onLevelCreated
	Ldtk:goTo(1)

	CameraManager.setScale(SCALE)
	CameraManager.setDeadzone(-GRID_SIZE, -GRID_SIZE, GRID_SIZE, GRID_SIZE)
	CameraManager.setLerp(0.01)
	CameraManager.setCoords(player.x + player.width / SCALE, player.y - player.height * SCALE)

	Ui:init()
	Ui.hud.player = player
	Ui.fade_in = Ui.fade:new("in", 1)
	Ui.fade_out = Ui.fade:new("out", 1)

	Sfx:load()
	Bgm:load()
	Bgm:play()

	Debug:init(World, CameraManager, player)
end

function screen:Update(dt)
	if player.is_player and player.state_machine:getState("entering") then
		is_entering = true
		if Ui.fade_in.is_active then
			Ui.fade_in:update(dt)
			return
		else
			if player.is_next_level then
				Ldtk:next()
			else
				Ldtk:previous()
			end
			is_entering = false
			Ui.fade_in:reset()
			player:update(dt)
			player.state_machine:setState("grounded")
		end
	end

	if is_paused then
		return
	end

	for _, level_enemy in ipairs(level_enemies) do
		level_enemy:update(dt)
	end

	for _, level_entity in ipairs(level_entities) do
		level_entity:update(dt)
	end

	player:update(dt, World)

	Ui.hud:update(dt)

	-- TODO: add gameover screen
	-- if player.health <= 0 then
	--  return "gameover"
	-- end

	CameraManager.setTarget(player.x + player.width / 2, player.y + player.height / 2)
	CameraManager.update(dt)

	if IsDebug then
		world_items, _ = World:getItems()
		Debug:update()
	end
end

function screen:Draw()
	CameraManager.attach()

	for _, level_block in ipairs(level_blocks) do
		level_block:draw()
	end

	for _, level_entity in ipairs(level_entities) do
		level_entity:draw()
	end

	for _, level_enemy in ipairs(level_enemies) do
		level_enemy:draw()
	end

	player:draw()

	if IsDebug then
		love.graphics.push("all")
		for _, item in pairs(world_items) do
			if item.x and item.y and item.w and item.h then
				love.graphics.setColor(1, 0, 0, 0.25)
				love.graphics.rectangle("fill", item.x, item.y, item.w, item.h)
				love.graphics.setColor(1, 0, 0)
				love.graphics.rectangle("line", item.x, item.y, item.w, item.h)
			else
				local x, y, w, h = World:getRect(item)
				love.graphics.setColor(1, 0, 0, 0.25)
				love.graphics.rectangle("fill", x, y, w, h)
				love.graphics.setColor(1, 0, 0)
				love.graphics.rectangle("line", x, y, w, h)
			end
		end
		love.graphics.pop()
	end

	CameraManager.detach()

	Ui.hud:draw()

	if is_entering then
		Ui.fade_in:draw()
	end

	if IsDebug then
		-- CameraManager.debug()
		Debug:draw()
	end

	if is_paused then
		love.graphics.push("all")
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(Fonts.title)

		local paused = "Paused"
		love.graphics.print(
			paused,
			(love.graphics.getWidth() - Fonts.title:getWidth(paused)) / 2,
			love.graphics.getHeight() / 2 - Fonts.title:getHeight()
		)
		love.graphics.pop()
	end
end

function screen:KeyPressed(key)
	-- TODO: Add game states(load/save/pause)
	if key == Keymaps.escape then
		-- TODO: add pause and setttings menu
		-- love.event.quit()
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
