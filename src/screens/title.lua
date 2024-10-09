local screen = {}
local screen_manager = {}

local ui = require("src.ui")
local fonts = require("src.assets.fonts")

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
	ui.title:update(dt)
	if ui.title.title_timer <= 0 and n_keysdown > 0 then
		return "landing"
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key, u)
	-- TODO: Add game states(load/save/pause)
	if ui.title.title_timer <= 0 then
		n_keysdown = n_keysdown + 1
	end
end

function screen:KeyReleased(key) end

return screen
