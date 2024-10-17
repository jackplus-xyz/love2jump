local Ui = require("src.ui")
local Keymaps = require("config.keymaps")
local Fonts = require("src.assets.fonts")

local screen = {}
local n_keysdown = 0
local is_save_file = false
local next_screen = nil

function screen:CheckForSaveFile()
	-- TODO: check if save file exists
	return true
end

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	love.graphics.setFont(Fonts.title)

	-- Initialize the title screen with options
	is_save_file = self:CheckForSaveFile()
	Ui.title:setOptions(is_save_file)
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
			return "landing"
		end
	end

	if Ui.title.is_show_options then
		if next_screen then
			return next_screen
		end
	end
end

function screen:KeyPressed(key)
	if Ui.title.title_timer <= 0 then
		if n_keysdown < 1 then
			n_keysdown = n_keysdown + 1
			return
		end

		if key == Keymaps.up then
			Ui.title:selectNextOption(-1)
		elseif key == Keymaps.down then
			Ui.title:selectNextOption()
		elseif key == Keymaps.confirm then
			-- TODO: Implement logic for start a new game/load game
			if Ui.title.selected_option == "New Game" then
				next_screen = "landing"
			elseif Ui.title.selected_option == "Load Game" then
				next_screen = "gameplay"
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
