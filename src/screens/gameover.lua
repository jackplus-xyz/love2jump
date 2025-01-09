local Ui = require("src.ui")
local Keymaps = require("config.keymaps")
local Sfx = require("src.sfx")

local ui = {}
local screen = {}

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	Ui.gameover:init()
	ui = Ui.gameover
	self.screenManager = ScreenManager
	self.screenManager.shared = { is_load_save = true }
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
	if ui.timer > 0 then
		return
	end

	-- TODO: end game
end

function screen:KeyReleased(key) end

return screen
