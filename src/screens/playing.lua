-- Libraries
local ldtk = require("lib.ldtk-love.ldtk")
local bump = require("lib.bump.bump")
local World = bump.newWorld(GRID_SIZE)
local CameraManager = require("lib.CameraMgr.CameraMgr").newManager()
local screen = {}

local Fade = require("src.ui.fade")

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

-- Vars
local new_player = {}
local level_blocks = {}
local level_entities = {}
local level_enemies = {}
local is_paused = false

-------- Debug --------
local debug_blocks = {}

local function addBlock(x, y, w, h)
	local block = { x = x, y = y, w = w, h = h }
	debug_blocks[#debug_blocks + 1] = block
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

local function drawDebugBlocks()
	for _, block in ipairs(debug_blocks) do
		drawBox(block, 1, 0, 0)
	end
end

--------- LOVE-LDTK CALLBACKS ----------
local function onEntity(entity)
	if entity.id == "Player" then
		new_player = Player.new(entity.x, entity.y, World)
		World:add(
			new_player,
			new_player.x - new_player.width / 2,
			new_player.y - new_player.height,
			new_player.width,
			new_player.height
		)
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
		local new_door = Door.new(entity.x, entity.y, entity.props)
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
		local new_object = object(entity)
		table.insert(level_blocks, new_object)
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
	-- removing all objects so we have a blank level
	local function clearWorld(items)
		for _, item in pairs(items) do
			if World:hasItem(item) then
				World:remove(item)
			end
		end
	end

	clearWorld(level_blocks)
	clearWorld(level_entities)
	clearWorld(level_enemies)
	clearWorld(debug_blocks)

	level_blocks = {}
	level_entities = {}
	level_enemies = {}
	debug_blocks = {}

	--changing background color to the one defined in LDtk
	love.graphics.setBackgroundColor(level.backgroundColor)

	local window_width = love.graphics.getWidth()
	local window_height = love.graphics.getHeight()

	CameraManager.setBounds(
		-window_width / 2 / SCALE,
		-window_height / 2 / SCALE,
		level.width + window_width / 2 / SCALE,
		level.height + window_height / 2 / SCALE
	)
end

local function onLevelCreated(level)
	--Here we use a string defined in LDtk as a function
	if level.props.create then
		load(level.props.create)()
	end

	if new_player then
		for _, entity in pairs(level_entities) do
			if entity.is_door and not entity.is_next then
				new_player.x, new_player.y = entity.x, entity.y - new_player.height
			end
		end
	end
end
--------------------------------------------

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	-- load ldtk maps
	ldtk:load("assets/maps/kings-and-pigs.ldtk")
	ldtk:setFlipped(true)
	ldtk.onLayer = onLayer
	ldtk.onEntity = onEntity
	ldtk.onLevelLoaded = onLevelLoaded
	ldtk.onLevelCreated = onLevelCreated
	ldtk:goTo(1)

	CameraManager.setScale(SCALE)
	CameraManager.setDeadzone(-GRID_SIZE, -GRID_SIZE, GRID_SIZE, GRID_SIZE)
	CameraManager.setLerp(0.01)
	CameraManager.setCoords(new_player.x + new_player.width / SCALE, new_player.y - new_player.height * SCALE)

	Debug:init(World, CameraManager, new_player)
end

function screen:Update(dt)
	if is_paused then
		Fade:update(dt)
		return
	end

	new_player:update(dt, World)

	for _, level_enemy in ipairs(level_enemies) do
		level_enemy:update(dt)
	end

	for _, level_entity in ipairs(level_entities) do
		level_entity:update(dt)
	end

	CameraManager.setTarget(new_player.x + new_player.width / 2, new_player.y + new_player.height / 2)
	CameraManager.update(dt)

	Ui:update(dt)

	if IsDebug then
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

	new_player:draw()

	if IsDebug then
		drawDebugBlocks()
	end

	-- FIXME: animation image is overlapped with the matte
	if is_paused then
		Fade:draw()
	end

	CameraManager.detach()

	if IsDebug then
		Debug:draw(0)
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

	new_player:keypressed(key)
end

function screen:KeyReleased(key) end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

return screen
