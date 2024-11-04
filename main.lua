-- Constants
GRID_SIZE = 32
SCALE = 2
LEVEL_BG_COLOR = {
	0.24705882352941,
	0.21960784313725,
	0.31764705882353,
}

-- Global Variables
IsDebug = false

-- Libraries
local ScreenManager = require("lib.Yonder").ScreenManager
local bump = require("lib.bump.bump")

-- Source
local Ui = require("src.ui")
local Bgm = require("src.bgm")
local Sfx = require("src.sfx")

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
	Ui:init()
	Sfx:load()
	Bgm:load()

	ScreenManager:SwitchStates("title")
end

function love.update(dt)
	ScreenManager:Update(dt)
end

function love.draw()
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
