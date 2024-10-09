local ui = require("src.ui")
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
	ui.title:draw()
end

function screen:Update(dt)
	if n_keysdown > 0 then
		screen_manager:SwitchStates("playing")
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key, u)
	n_keysdown = n_keysdown + 1
end

function screen:KeyReleased(key) end

return screen
