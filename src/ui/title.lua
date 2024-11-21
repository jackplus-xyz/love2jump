local Fonts = require("src.assets.fonts")
local Sfx = require("src.sfx")

local Title = {}
Title.__index = Title

function Title:new()
	local instance = setmetatable({}, Title)
	instance:init()
	return instance
end

function Title:init()
	self.title_y = 0
	self.title_duration = 1
	self.title_timer = self.title_duration
	self.flash_interval = 0.8
	self.flash_timer = 0
	self.is_flash_visible = true

	-- Menu options and state
	self.options = { "New Game" } -- Default option
	self.is_show_options = false
	self.selected_option = nil
	self.curr_index = 1
end

function Title:setOptions(has_save_file)
	-- Set options based on whether there's a save file
	if has_save_file then
		self.options = { "New Game", "Load Game", "Quit" }
	else
		self.options = { "New Game" }
	end
	self.selected_option = self.options[1]
end

function Title:update(dt)
	if self.title_timer > 0 then
		self.title_timer = self.title_timer - dt
		self.title_y = (self.title_duration - self.title_timer) / self.title_duration * love.graphics.getHeight() / 2
	else
		self.flash_timer = self.flash_timer + dt
		if self.flash_timer >= self.flash_interval then
			self.flash_timer = self.flash_timer - self.flash_interval
			self.is_flash_visible = not self.is_flash_visible
		end
	end
end

function Title:selectNextOption(direction)
	direction = direction or 1
	Sfx:play("ui.select")
	if self.title_timer <= 0 then
		self.curr_index = (self.curr_index - 1 + direction) % #self.options + 1
		self.selected_option = self.options[self.curr_index]
	end
end

function Title:draw()
	local title = "Title"
	local instruction = "Press Any Key to Begin"
	local offset_y = Fonts.heading_3:getHeight()

	love.graphics.push("all")

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(Fonts.heading_1)
	love.graphics.print(
		title,
		(love.graphics.getWidth() - Fonts.heading_1:getWidth(title)) / 2,
		self.title_y - Fonts.heading_1:getHeight()
	)

	if self.title_timer <= 0 then
		love.graphics.setFont(Fonts.heading_3)
		if self.is_show_options then
			for i, option in ipairs(self.options) do
				local is_selected = (self.selected_option == option)
				local y = self.title_y + (i * offset_y)
				love.graphics.setColor(0.4, 0.4, 0.4)
				if is_selected then
					love.graphics.setColor(1, 1, 1) -- Highlight selected option
				end
				love.graphics.print(option, love.graphics.getWidth() / 2 - Fonts.heading_3:getWidth(option) / 2, y)
			end
		else
			if self.is_flash_visible then
				love.graphics.print(
					instruction,
					love.graphics.getWidth() / 2 - Fonts.heading_3:getWidth(instruction) / 2,
					self.title_y + offset_y
				)
			end
		end
	end

	love.graphics.pop()
end

return Title
