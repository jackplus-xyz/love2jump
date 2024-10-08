--[[

CLASS SAMPLE SCREEN

This is a sample screen. In order to make a new gamestate, or screen, you should copy and paste this code
into a new Lua module so you can write the logic for a new gamestate. Be sure to add the gamestate to the ScreenManager!

]]
--

local screen_manager = {}
local fonts = require("src.assets.fonts")
local screen = {}
local title_y = 0
local title_duration = 2
local title_timer = title_duration
local n_keysdown = 0

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	love.graphics.setFont(fonts.title)

	screen_manager = ScreenManager
end

function screen:Draw()
	love.graphics.push()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	local title = "Playing Now"
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		title,
		(love.graphics.getWidth() - fonts.title:getWidth(title)) / 2,
		title_y - fonts.title:getHeight()
	)

	local instruction = "Press Any Key to Begin"
	if title_timer <= 0 then
		love.graphics.print(
			instruction,
			love.graphics.getWidth() / 2 - fonts.title:getWidth(instruction) / 4,
			title_y + 20,
			0,
			0.5,
			0.5
		)
	end

	love.graphics.pop()
end

function screen:Update(dt)
	if title_timer >= 0 then
		title_timer = title_timer - dt
		title_y = (title_duration - title_timer) / title_duration * love.graphics.getHeight() / 2
	end

	if n_keysdown > 0 then
		screen_manager:SwitchStates("playing")
	end
end

function screen:KeyPressed(key, u)
	if title_timer <= 0 then
		n_keysdown = n_keysdown + 1
	end
end

function screen:KeyReleased(key) end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

return screen
