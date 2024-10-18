local screen = {}

local Ui = require("src.ui")
local Sfx = require("src.sfx")
local n_keysdown = 0

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
end

function screen:Draw()
	Ui.landing:draw()
end

function screen:Update(dt)
	Ui.landing:update(dt)
	if Ui.landing.landing_instruction_timer <= 0 and n_keysdown > 0 then
		return "gameplay"
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key, u)
	Sfx:play("ui.confirm")
	n_keysdown = n_keysdown + 1
end

function screen:KeyReleased(key) end

return screen
