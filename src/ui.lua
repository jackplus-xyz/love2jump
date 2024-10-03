local anim8 = require("lib.anim8")
local keymaps = require("config.keymaps")
local heart_animation_offset = 0.1

local ui = {}
local sprite_width = 18
local sprite_height = 14

ui.heart_offsets = {}

function ui:init(max_health)
	for i = 1, max_health do
		self.heart_offsets[i] = love.math.random() * 0.1 -- Random offset between 0 and 0.1 seconds
	end
	self.live_bar_image = love.graphics.newImage("assets/sprites/12-live-and-coins/live-bar-no-outline.png")
	self.big_heart_idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-idle.png")
	self.big_heart_hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-hit.png")

	local big_heart_idle_grid =
		anim8.newGrid(sprite_width, sprite_height, self.big_heart_idle_image:getWidth(), sprite_height)
	local big_heart_hit_grid =
		anim8.newGrid(sprite_width, sprite_height, self.big_heart_hit_image:getWidth(), sprite_height)

	ui.live_bar_animations = {
		big_heart_idle = anim8.newAnimation(big_heart_idle_grid("1-8", 1), 0.1),
		big_heart_hit = anim8.newAnimation(big_heart_hit_grid("1-2", 1), 0.1),
	}
end

function ui:update(dt)
	-- TODO: add offset
	for _, animation in pairs(self.live_bar_animations) do
		animation:update(dt)
	end
end

function ui:drawHUD(health)
	local x, y = GRID_SIZE / 2, GRID_SIZE / 2
	local offset_x, offset_y = 12, 11
	local heart_offset = 12

	love.graphics.push()

	love.graphics.scale(2)
	love.graphics.draw(self.live_bar_image, x, y)

	for i = 1, health do
		self.live_bar_animations.big_heart_idle:draw(
			self.big_heart_idle_image,
			x + offset_x + (i - 1) * heart_offset,
			y + offset_y,
			0,
			0.8,
			0.8
		)
	end

	love.graphics.pop()
end

return ui
