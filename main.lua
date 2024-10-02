local keymaps = require("config.keymaps")
local Enemy = require("src.enemy")
local debug = require("src.debug")

IsDebug = true
CameraManager = require("lib.CameraMgr.CameraMgr").newManager()

-- Constants
local GRID_SIZE = 32

-- Libraries
local ldtk = require("lib.ldtk-love.ldtk")
local bump = require("lib.bump.bump")

local world = bump.newWorld(GRID_SIZE)
local level_elements = {}
local curr_level_width = 0
local curr_level_height = 0
local cols_len = 0 -- how many collisions are happening

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
	-- Handle other entities as before
	if entity.id == "Player" then
		Player = require("src.Player").new(entity.x, entity.y, world)
	elseif entity.id == "Enemy" then
		local enemy = Enemy.new(entity.x, entity.y, world)
		table.insert(level_elements, enemy)
	else
		-- Draw other entites as a rectabgle
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
	--removing all objects so we have a blank level
	level_elements = {}
	blocks = {}

	--changing background color to the one defined in LDtk
	love.graphics.setBackgroundColor(level.backgroundColor)

	curr_level_width = level.width
	curr_level_height = level.height

	-- TODO: Improve camera bound logic
	CameraManager.setBounds(-level.width / 6, -level.height, level.width, level.height)
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

	-- load ldtk maps
	ldtk:load("assets/maps/kings-and-pigs.ldtk")
	ldtk:setFlipped(true)
	ldtk.onLayer = onLayer
	ldtk.onEntity = onEntity
	ldtk.onLevelLoaded = onLevelLoaded
	ldtk.onLevelCreated = onLevelCreated
	ldtk:goTo(1)

	CameraManager.setScale(2)

	-- TODO: Improve camera dead zone logic
	CameraManager.setDeadzone(-Player.width * 2, -Player.height, Player.width * 2, Player.height * 2)
	CameraManager.setLerp(0.01)
	CameraManager.setCoords(Player.x + Player.width / 2, Player.y - Player.height * 2)

	-- TODO: Add game states(load/save/pause)
	-- TODO: Score system

	if IsDebug then
		debug:init()
	end
end

function love.update(dt)
	Player:update(dt, world)

	-- FIXME: handle level changing
	if Player.x >= curr_level_width - GRID_SIZE * 8 then
		ldtk:next()
	end

	CameraManager.setTarget(Player.x + Player.width / 2, Player.y + Player.height / 2)
	CameraManager.update(dt)

	if IsDebug then
		debug:update()
	end
end

function love.draw()
	CameraManager.attach()

	for _, level_element in ipairs(level_elements) do
		level_element:draw()
	end

	Player:draw()

	if IsDebug then
		drawBlocks()
	end

	CameraManager.detach()

	if IsDebug then
		CameraManager.debug()
		debug:draw(100)
	end
end

function love.keypressed(key)
	if key == keymaps.escape then
		love.event.quit()
	elseif key == keymaps.debug then
		IsDebug = not IsDebug
	end

	Player:keypressed(key)
end
