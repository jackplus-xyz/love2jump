-- Constants
GRID_SIZE = 32
SCALE = 2

-- Global Variables
IsDebug = false

-- Libraries
local ScreenManager = require("lib.Yonder").ScreenManager
local bump = require("lib.bump.bump")
local World = bump.newWorld(GRID_SIZE)
local CameraManager = require("lib.CameraMgr.CameraMgr").newManager()

-- Source
local ui = require("src.ui")
local bgm = require("src.bgm")
local sfx = require("src.sfx")
local debug = require("src.debug")

--- Helper function to print the content of a table
function PrintTable(t)
	for k, v in pairs(t) do
		print(k, v)
	end
end

function love.load()
	-- setup love 2d for pixel art
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")

	-- load the data and resources
	ui:init()
	sfx:load()
	bgm:load()
	bgm:play()

	ScreenManager:SwitchStates("title")

	if IsDebug then
		debug:init(World, CameraManager)
	end
end

function love.update(dt)
	ScreenManager:Update(dt)
end

function love.draw()
	-- if IsDebug then
	-- 	CameraManager.debug()
	-- 	debug:draw(100)
	-- end

	ScreenManager:Draw()
end

function love.keypressed(key)
	ScreenManager:KeyPressed(key)
end

function love.keyreleased(key)
	ScreenManager:KeyReleased(key)
end

function love.mousepressed(x, y, button)
	ScreenManager:MousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
	ScreenManager:MouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
	ScreenManager:MouseMoved(x, y, dx, dy, istouch)
end
