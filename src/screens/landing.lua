local screen = {}

local ui = require("src.ui")
local n_keysdown = 0

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
end

function screen:Draw()
	ui.landing:draw()
end

function screen:Update(dt)
	ui.landing:update(dt)
	if ui.landing.landing_instruction_timer <= 0 and n_keysdown > 0 then
		return "gameplay"
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key, u)
	n_keysdown = n_keysdown + 1
end

function screen:KeyReleased(key) end

return screen
