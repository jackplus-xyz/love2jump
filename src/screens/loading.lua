local screen = {}

local Ui = require("src.ui")
local Sfx = require("src.sfx")

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	Ui.loading:init()
	self.screenManager = ScreenManager
	self.screenManager.shared = { is_load_save = true }
end

function screen:Draw()
	Ui.loading:draw()
end

function screen:Update(dt)
	Ui.loading:update(dt)
	if Ui.loading.loading_timer < 0 then
		self.screenManager:SwitchStates("gameplay")
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key, u) end

function screen:KeyReleased(key) end

return screen
