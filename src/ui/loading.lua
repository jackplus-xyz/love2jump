local Fonts = require("src.assets.fonts")
local keymaps = require("config.keymaps")

local Loading = {}
Loading.__index = Loading

function Loading:new()
	local instance = setmetatable({}, Loading)
	instance:init()
	return instance
end

function Loading:init()
	self.loading_timer = 1
end

function Loading:update(dt)
	if self.loading_timer > 0 then
		self.loading_timer = self.loading_timer - dt
	end
end

function Loading:draw()
	local title = "Loading..."
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

return Loading
