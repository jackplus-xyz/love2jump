local Fonts = require("src.assets.fonts")
local Sfx = require("src.sfx")

local Menu = {}
Menu.__index = Menu

function Menu.new()
	local instance = setmetatable({}, Menu)

	instance.is_confirm_quit = false
	instance.options = {
		"Resume",
		"Save Game",
		"Load Game",
		"Settings",
		"Quit",
	}
	instance.confirm_choices = {
		"Yes",
		"No",
	}

	instance.current_index = 1
	instance.selected_option = instance.options[instance.current_index]
	instance.selected_choice = true

	return instance
end

function Menu:selectNextOption(direction)
	direction = direction or 1
	Sfx:play("ui.select")
	self.current_index = (self.current_index - 1 + direction) % #self.options + 1
	self.selected_option = self.options[self.current_index]
end

function Menu:selectNextChoice()
	Sfx:play("ui.select")
	self.selected_choice = not self.selected_choice
end

function Menu:update(dt) end

function Menu:draw(is_confirm_quit)
	is_confirm_quit = is_confirm_quit or false
	local title = "Menu"
	local window_w = love.graphics.getWidth()
	local window_h = love.graphics.getHeight()
	local rec_w, rec_h = Fonts.heading_3:getWidth(title) * 2.5, (#self.options + 1) * Fonts.heading_3:getHeight()
	local rec_x, rec_y = (window_w - rec_w) / 2, (window_h - rec_h) / 2

	love.graphics.push("all")

	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 0, 0, window_w, window_h)

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", rec_x, rec_y, rec_w, rec_h)

	if is_confirm_quit then
		title = "Confirm?"
		local confirm_quit = "Are you sure you want to Quit without saving? All the unsaved progress will be loss."

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(Fonts.heading_3)
		love.graphics.print(
			title,
			rec_x + (rec_w - Fonts.heading_3:getWidth(title)) / 2,
			rec_y + Fonts.heading_3:getHeight() / 4
		)

		love.graphics.setFont(Fonts.heading_4)
		for i, choice in ipairs(self.confirm_choices) do
			local is_selected = (self.selected_choice and choice == "Yes")
				or (not self.selected_choice and choice == "No")
			love.graphics.setColor(0.4, 0.4, 0.4)
			if is_selected then
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print(
				choice,
				rec_x + (rec_w - Fonts.heading_4:getWidth(choice)) / 2,
				rec_y + (Fonts.heading_4:getHeight()) * (i + 1)
			)
		end
	else
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(Fonts.heading_3)
		love.graphics.print(
			title,
			rec_x + (rec_w - Fonts.heading_3:getWidth(title)) / 2,
			rec_y + Fonts.heading_3:getHeight() / 4
		)

		love.graphics.setFont(Fonts.heading_4)
		for i, option in ipairs(self.options) do
			local is_selected = (self.selected_option == option)
			love.graphics.setColor(0.4, 0.4, 0.4)
			if is_selected then
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print(
				option,
				rec_x + (rec_w - Fonts.heading_4:getWidth(option)) / 2,
				rec_y + (Fonts.heading_4:getHeight()) * (i + 1)
			)
		end
	end

	love.graphics.pop()
end

return Menu
