local Ui = require("src.ui")
local Keymaps = require("config.keymaps")
local Sfx = require("src.sfx")

local GameProgress = require("src.utils.game_progress")

local screen = {}
local n_keysdown = 0
local is_save_file = false

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	-- Initialize the title screen with options
	is_save_file = GameProgress.isSaveFile()
	Ui.title:setOptions(is_save_file)
	self.screenManager = ScreenManager
	self.screenManager.shared = self.screenManager.shared or {}
end

function screen:Draw()
	Ui.title:draw()
end

function screen:Update(dt)
	Ui.title:update(dt)
	if Ui.title.title_timer <= 0 and n_keysdown > 0 and not Ui.title.is_show_options then
		if is_save_file then
			Ui.title.is_show_options = true
		else
			self.screenManager:SwitchStates("landing")
		end
	end
end

function screen:KeyPressed(key)
	if Ui.title.title_timer <= 0 then
		if n_keysdown < 1 then
			Sfx:play("ui.confirm")
			n_keysdown = n_keysdown + 1
			return
		end

		if key == Keymaps.up then
			Ui.title:selectNextOption(-1)
		elseif key == Keymaps.down then
			Ui.title:selectNextOption()
		elseif key == Keymaps.confirm then
			Sfx:play("ui.confirm")
			if Ui.title.selected_option == "New Game" then
				self.screenManager:SwitchStates("landing")
			elseif Ui.title.selected_option == "Load Game" then
				self.screenManager.shared = { is_load_save = true }
				self.screenManager:SwitchStates("gameplay")
			elseif Ui.title.selected_option == "Quit" then
				love.event.quit()
			end
		end
	end
end

function screen:KeyReleased(key) end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

return screen
