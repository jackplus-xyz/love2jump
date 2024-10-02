local anim8 = require("lib.anim8")
local keymaps = require("config.keymaps")
local heart_animation_offset = 0.1

local ui = {}
local sprite_width = 18
local sprite_height = 14

local live_bar_image = love.graphics.newImage("assets/sprites/12-live-and-coins/live-bar.png")
local big_heart_idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-idle.png")
local big_heart_hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-hit.png")

local big_heart_idle_grid = anim8.newGrid(sprite_width, sprite_height, big_heart_idle_image:getWidth(), sprite_height)
local big_heart_hit_grid = anim8.newGrid(sprite_width, sprite_height, big_heart_hit_image:getWidth(), sprite_height)

ui.live_bar_animations = {
	big_heart_idle = anim8.newAnimation(big_heart_idle_grid("1-8", 1), 0.1),
	big_heart_hit = anim8.newAnimation(big_heart_hit_grid("1-2", 1), 0.1),
}

ui.heart_offsets = {}

function ui:init(max_health)
	for i = 1, max_health do
		self.heart_offsets[i] = love.math.random() * 0.1 -- Random offset between 0 and 0.1 seconds
	end
end

function ui:update(dt)
	for i, offset in ipairs(self.heart_offsets) do
		local adjusted_dt = (dt + offset) % 0.8 -- 0.8 is the total duration of the animation (8 frames * 0.1 seconds)
		self.live_bar_animations.big_heart_idle:update(adjusted_dt)
	end
	self.live_bar_animations.big_heart_hit:update(dt)
end

function ui:drawHUD(health)
	local x, y = GRID_SIZE, GRID_SIZE / 2
	local offset_x, offset_y = 11, 9
	local heart_offset = 11

	love.graphics.push()

	love.graphics.scale(2)
	love.graphics.draw(live_bar_image, x, y)

	for i = 1, health do
		local anim = self.live_bar_animations.big_heart_idle:clone()
		anim:update(self.heart_offsets[i])
		anim:draw(big_heart_idle_image, x + offset_x + (i - 1) * heart_offset, y + offset_y)
	end

	love.graphics.pop()
end

return ui
