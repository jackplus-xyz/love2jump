local Fonts = require("src.assets.fonts")
local Sfx = require("src.sfx")

local Gameover = {}
Gameover.__index = Gameover

function Gameover:new()
	local instance = setmetatable({}, Gameover)
	instance:init()
	return instance
end

function Gameover:init()
	self.timer = 1
	self.options = {
		"Restart",
		"Quit",
	}
	self.curr_index = 1
	self.selected_option = self.options[self.curr_index]
end

function Gameover:selectNextOption(direction)
	direction = direction or 1
	Sfx:play("ui.select")
	self.curr_index = (self.curr_index - 1 + direction) % #self.options + 1
	self.selected_option = self.options[self.curr_index]
end

function Gameover:update(dt)
	self.timer = self.timer - dt
end

function Gameover:draw()
	local title = "Gameover"
	local center_x = love.graphics.getWidth() / 2 - Fonts.heading_1:getWidth(title) / 4
	local center_y = love.graphics.getHeight() / 2 - Fonts.heading_1:getHeight() / 2

	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(Fonts.heading_2)
	love.graphics.print(title, center_x, center_y)

	love.graphics.setFont(Fonts.heading_3)
	for i, option in ipairs(self.options) do
		local is_selected = (self.selected_option == option)
		love.graphics.setColor(0.4, 0.4, 0.4)
		if is_selected then
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(option, center_x, center_y + (Fonts.heading_3:getHeight()) * (i + 1))
	end

	love.graphics.pop()
end

return Gameover
