local Ui = require("src.ui")
local Keymaps = require("config.keymaps")
local Sfx = require("src.sfx")

local ui = {}
local screen = {}
Bgm = require("src.utils.bgm.init")

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	Ui.credits:init()
	ui = Ui.credits
	self.screenManager = ScreenManager
	self.screenManager.shared = { is_load_save = true }
	Bgm:play("credits")
end

function screen:Draw()
	ui:draw()
end

function screen:Update(dt)
	ui:update(dt)
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key)
	if ui.is_last_line then
		love.event.quit()
	end
end

function screen:KeyReleased(key) end

return screen
