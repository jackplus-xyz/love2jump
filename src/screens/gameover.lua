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

	if key == Keymaps.up or key == Keymaps.left then
		ui:selectNextOption(-1)
	elseif key == Keymaps.down or key == Keymaps.right then
		ui:selectNextOption()
	elseif key == Keymaps.confirm then
		Sfx:play("ui.confirm")
		if ui.selected_option == "Restart" then
			-- TODO: add restart logic
			self.screenManager.shared = { is_load_save = true }
			self.screenManager:SwitchStates("gameplay")
		elseif ui.selected_option == "Quit" then
			love.event.quit()
		end
	end
end

function screen:KeyReleased(key) end

return screen
