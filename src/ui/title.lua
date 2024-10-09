local fonts = require("src.assets.fonts")
local title_y = 0
local title_duration = 2
local title_timer = title_duration

local TITLE = {}
TITLE.__index = TITLE

function TITLE.new()
	local self = setmetatable({}, TITLE)
	self:init()

	return self
end

function TITLE:init() end

function TITLE:update(dt)
	print("Hello!")
	if title_timer >= 0 then
		title_timer = title_timer - dt
		title_y = (title_duration - title_timer) / title_duration * love.graphics.getHeight() / 2
	end
end

function TITLE:draw()
	love.graphics.push()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	local title = "Love Arcade"
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		title,
		(love.graphics.getWidth() - fonts.title:getWidth(title)) / 2,
		title_y - fonts.title:getHeight()
	)

	local instruction = "Press Any Key to Begin"
	if title_timer <= 0 then
		love.graphics.print(
			instruction,
			love.graphics.getWidth() / 2 - fonts.title:getWidth(instruction) / 4,
			title_y + 20,
			0,
			0.5,
			0.5
		)
	end

	love.graphics.pop()
end

return TITLE
