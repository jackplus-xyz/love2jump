local Fonts = require("src.assets.fonts")

local Gameover = {}
Gameover.__index = Gameover

function Gameover:new()
	local instance = setmetatable({}, Gameover)
	instance:init()
	return instance
end

function Gameover:init()
	self.loading_timer = 1
end

function Gameover:update(dt)
	if self.loading_timer > 0 then
		self.loading_timer = self.loading_timer - dt
	end
end

function Gameover:draw()
	local title = "Gameover"
	local center_x = love.graphics.getWidth() / 2 - Fonts.heading_1:getWidth(title) / 4
	local center_y = love.graphics.getHeight() / 2 - Fonts.heading_1:getHeight() / 2

	love.graphics.push()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(Fonts.heading_2)
	love.graphics.print(title, center_x, center_y)

	love.graphics.pop()
end

return Gameover
