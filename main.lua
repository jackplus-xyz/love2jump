local keymaps = require("config.keymaps")

local ui = require("src.ui")
local bgm = require("src.bgm")
local sfx = require("src.sfx")
local player = require("src.player")
local enemy = require("src.enemy")
local door = require("src.door")
local debug = require("src.debug")

IsDebug = false
CameraManager = require("lib.CameraMgr.CameraMgr").newManager()

-- Constants
GRID_SIZE = 32
SCALE = 2

-- Libraries
local ldtk = require("lib.ldtk-love.ldtk")
local bump = require("lib.bump.bump")

local world = bump.newWorld(GRID_SIZE)
local level_elements = {}
local level_entities = { doors = {} }
local enemies = {}

--- Helper function to print the content of a table
function PrintTable(t)
	for k, v in pairs(t) do
		print(k, v)
	end
end

-- Debug Blocks
local blocks = {}

local function addBlock(x, y, w, h)
	local block = { x = x, y = y, w = w, h = h }
	blocks[#blocks + 1] = block
	world:add(block, x, y, w, h)
end

local function drawBox(box, r, g, b)
	love.graphics.setColor(r, g, b, 0.25)
	love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
	love.graphics.setColor(r, g, b)
	love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end

local function drawBlocks()
	for _, block in ipairs(blocks) do
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
		Player = player.new(entity.x, entity.y, world)
	elseif entity.id == "Enemy" then
		local new_enemy = enemy.new(entity.x, entity.y, world)
		table.insert(enemies, new_enemy)
	elseif entity.id == "Door" then
		-- PrintTable(entity.props.Entity_ref)
		local new_door = door.new(entity.x, entity.y, world, entity.props.nextLevelId)
		table.insert(level_entities.doors, new_door)
	else
		-- Draw other entites as a rectangle
		local new_object = object(entity)
		table.insert(level_elements, new_object)
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
	table.insert(level_elements, layer) --adding layer to the table we use to draw
end

local function onLevelLoaded(level)
	for _, block in pairs(blocks) do
		world:remove(block)
	end

	--removing all objects so we have a blank level
	level_elements = {}
	level_entities = { doors = {} }
	enemies = {}
	blocks = {}

	--changing background color to the one defined in LDtk
	love.graphics.setBackgroundColor(level.backgroundColor)

	curr_level_width = level.width
	curr_level_height = level.height

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
end
--------------------------------------------

function love.load()
	-- setup love 2d for pixel art
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	--load the data and resources
	require("src.assets.fonts")

	local max_health = 3
	ui:init(max_health)

	sfx:load()
	bgm:load()
	bgm:play()

	-- TODO: Add game menu

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
	CameraManager.setCoords(Player.x + Player.width / SCALE, Player.y - Player.height * SCALE)

	-- TODO: Add game states(load/save/pause)
	-- TODO: Score system

	if IsDebug then
		debug:init(world)
	end
end

function love.update(dt)
	Player:update(dt, world)

	for _, level_enemy in ipairs(enemies) do
		level_enemy:update(dt, world)
	end

	for _, level_door in ipairs(level_entities.doors) do
		level_door:update(dt)
	end

	-- FIXME: handle level changing
	-- 	ldtk:next()

	CameraManager.setTarget(Player.x + Player.width / 2, Player.y + Player.height / 2)
	CameraManager.update(dt)

	ui:update(dt)

	if IsDebug then
		debug:update()
	end
end

function love.draw()
	CameraManager.attach()

	for _, level_element in ipairs(level_elements) do
		level_element:draw()
	end

	for _, level_door in ipairs(level_entities.doors) do
		level_door:draw()
	end

	for _, level_enemy in ipairs(enemies) do
		level_enemy:draw()
	end

	Player:draw()

	if IsDebug then
		drawBlocks()
	end

	CameraManager.detach()

	ui:drawHUD(Player.health)

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
