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

function ui:update(dt)
	for _, anim in pairs(self.live_bar_animations) do
		anim:update(dt)
	end
end

function ui:drawHUD(health)
	local x, y = GRID_SIZE, GRID_SIZE / 2
	local offset_x, offset_y = 11, 9
	local heart_offset = 11

	love.graphics.push()

	love.graphics.scale(2)
	love.graphics.draw(live_bar_image, x, y)

	for i = 1, health do
		self.live_bar_animations.big_heart_idle:gotoFrame(i)
		self.live_bar_animations.big_heart_idle:draw(
			big_heart_idle_image,
			x + offset_x + (i - 1) * heart_offset,
			y + offset_y
		)
	end

	love.graphics.pop()
end

return ui
