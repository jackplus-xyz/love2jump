local fonts = require("src.assets.fonts")

local Title = {}
Title.__index = Title

function Title:new()
	local instance = setmetatable({}, Title)
	instance:init()
	return instance
end

function Title:init()
	self.title_y = 0
	self.title_duration = 2
	self.title_timer = self.title_duration
	self.flash_interval = 0.8
	self.flash_timer = 0
	self.is_flash_visible = true
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

function Title:draw()
	local title = "Title"
	local instruction = "Press Any Key to Begin"

	love.graphics.push()

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		title,
		(love.graphics.getWidth() - fonts.title:getWidth(title)) / 2,
		self.title_y - fonts.title:getHeight()
	)

	if self.is_flash_visible and self.title_timer <= 0 then
		love.graphics.print(
			instruction,
			love.graphics.getWidth() / 2 - fonts.title:getWidth(instruction) / 4,
			self.title_y + 20,
			0,
			0.5,
			0.5
		)
	end

	love.graphics.pop()
end

return Title
