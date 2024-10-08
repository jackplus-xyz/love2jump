-- Constants
GRID_SIZE = 32
SCALE = 2

-- Libraries
local ldtk = require("lib.ldtk-love.ldtk")
local bump = require("lib.bump.bump")

-- Global Variables
IsDebug = false

World = bump.newWorld(GRID_SIZE)
CameraManager = require("lib.CameraMgr.CameraMgr").newManager()

local level_blocks = {}
local level_entities = {}
local level_enemies = {}

-- Config
local keymaps = require("config.keymaps")

-- Source
local ui = require("src.ui")
local bgm = require("src.bgm")
local sfx = require("src.sfx")
local player = require("src.player")
local enemy = require("src.enemy")
local door = require("src.door")
local coin = require("src.coin")
local debug = require("src.debug")

--- Helper function to print the content of a table
function PrintTable(t)
	for k, v in pairs(t) do
		print(k, v)
	end
end

-- Debug Blocks
local debug_blocks = {}

local function addBlock(x, y, w, h)
	local block = { x = x, y = y, w = w, h = h }
	debug_blocks[#debug_blocks + 1] = block
	World:add(block, x, y, w, h)
end

local function drawBox(box, r, g, b)
	love.graphics.setColor(r, g, b, 0.25)
	love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
	love.graphics.setColor(r, g, b)
	love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end

local function drawDebugBlocks()
	for _, block in ipairs(debug_blocks) do
		drawBox(block, 1, 0, 0)
	end
end

-------- ENTITIES --------
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
--------------------------

--------- CALLBACKS FOR LOVE-LDTK ----------
local function onEntity(entity)
	if entity.id == "Player" and not Player then
		Player = player.new(entity.x, entity.y)
		World:add(Player, Player.x - Player.width / 2, Player.y - Player.height, Player.width, Player.height)
	elseif entity.id == "Enemy" then
		local new_enemy = enemy.new(entity.x, entity.y, entity.props)
		if entity.props.testString then
			print(entity.props.testString)
		end
		World:add(
			new_enemy,
			new_enemy.x - new_enemy.width,
			new_enemy.y - new_enemy.height,
			new_enemy.width,
			new_enemy.height
		)
		table.insert(level_enemies, new_enemy)
	elseif entity.id == "Door" then
		local new_door = door.new(entity.x, entity.y, entity.props)
		World:add(
			new_door,
			new_door.x - new_door.x_offset,
			new_door.y - new_door.y_offset,
			new_door.width,
			new_door.height
		)
		table.insert(level_entities, new_door)
	elseif entity.id == "Coin" then
		local new_coin = coin.new(entity.x, entity.y)
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
	--removing all objects so we have a blank level
	-- local function clearWorld(items)
	-- 	for _, item in pairs(items) do
	-- 		World:remove(items)
	-- 	end
	-- end

	-- clearWorld(level_blocks)
	-- clearWorld(level_entities)
	-- clearWorld(level_enemies)
	-- clearWorld(debug_blocks)

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

	if Player then
		for _, entity in pairs(level_entities) do
			if entity.is_door and not entity.is_next then
				Player.x, Player.y = entity.x, entity.y - Player.height
			end
		end
	end
end
--------------------------------------------

function love.load()
	-- setup love 2d for pixel art
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")

	--load the data and resources
	require("src.assets.fonts")

	sfx:load()
	bgm:load()
	-- bgm:play()

	-- TODO: Add game menu

	-- load ldtk maps
	ldtk:load("assets/maps/kings-and-pigs.ldtk")
	ldtk:setFlipped(true)
	ldtk.onLayer = onLayer
	ldtk.onEntity = onEntity
	ldtk.onLevelLoaded = onLevelLoaded
	ldtk.onLevelCreated = onLevelCreated
	ldtk:goTo(1)

	ui:init()

	CameraManager.setScale(SCALE)
	CameraManager.setDeadzone(-GRID_SIZE, -GRID_SIZE, GRID_SIZE, GRID_SIZE)
	CameraManager.setLerp(0.01)
	CameraManager.setCoords(Player.x + Player.width / SCALE, Player.y - Player.height * SCALE)

	-- TODO: Add game states(load/save/pause)
	-- TODO: Score system

	if IsDebug then
		debug:init(World)
	end
end

function love.update(dt)
	Player:update(dt, World)

	for _, level_enemy in ipairs(level_enemies) do
		level_enemy:update(dt)
	end

	for _, level_entity in ipairs(level_entities) do
		level_entity:update(dt)
	end

	CameraManager.setTarget(Player.x + Player.width / 2, Player.y + Player.height / 2)
	CameraManager.update(dt)

	ui:update(dt)

	if IsDebug then
		debug:update()
	end
end

function love.draw()
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

	Player:draw()

	if IsDebug then
		drawDebugBlocks()
	end

	CameraManager.detach()

	ui:drawHUD()

	if IsDebug then
		-- CameraManager.debug()
		debug:draw(100)
	end
end

function love.keypressed(key)
	if key == keymaps.escape then
		love.event.quit()
	elseif key == keymaps.debug then
		IsDebug = not IsDebug
	end

	Player:keypressed(key, level_entities)
end
