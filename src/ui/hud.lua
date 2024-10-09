local anim8 = require("lib.anim8.anim8")

local Hud = {}
Hud.__index = Hud

function Hud.new()
	local instance = setmetatable({}, Hud)
	instance:init()
	return instance
end

function Hud:init()
	local sprite_width = 18
	local sprite_height = 14
	self.live_bar_image = love.graphics.newImage("assets/sprites/12-live-and-coins/live-bar-no-outline.png")
	self.big_heart_idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-idle.png")
	self.big_heart_hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-heart-hit.png")

	self.animations = {}
	self.coin_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-idle.png")
	self.coin_grid = anim8.newGrid(sprite_width, sprite_height, self.coin_image:getWidth(), sprite_height)
	self.animations.coin = anim8.newAnimation(self.coin_grid("1-10", 1), 0.1)

	local big_heart_idle_grid =
		anim8.newGrid(sprite_width, sprite_height, self.big_heart_idle_image:getWidth(), sprite_height)
	local big_heart_hit_grid =
		anim8.newGrid(sprite_width, sprite_height, self.big_heart_hit_image:getWidth(), sprite_height)

	Hud.live_bar_animations = {
		big_heart_idle = anim8.newAnimation(big_heart_idle_grid("1-8", 1), 0.1),
		big_heart_hit = anim8.newAnimation(big_heart_hit_grid("1-2", 1), 0.1),
	}
end

function Hud:update(dt)
	for _, animation in pairs(self.live_bar_animations) do
		animation:update(dt)
	end

	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Hud:draw()
	local x, y = GRID_SIZE / 2, GRID_SIZE / 2
	local offset_x, offset_y = 12, 11
	local heart_offset = 12

	love.graphics.push()

	love.graphics.scale(SCALE)
	love.graphics.draw(self.live_bar_image, x, y)

	for i = 1, Player.health do
		local anim_offset = (i - 1) * 0.1

		self.live_bar_animations.big_heart_idle:update(-anim_offset)

		self.live_bar_animations.big_heart_idle:draw(
			self.big_heart_idle_image,
			x + offset_x + (i - 1) * heart_offset,
			y + offset_y,
			0,
			0.8,
			0.8
		)

		self.live_bar_animations.big_heart_idle:update(anim_offset)
	end

	self.animations.coin:draw(self.coin_image, love.graphics.getWidth() / SCALE - x * 4, y)
	love.graphics.print(Player.coins, love.graphics.getWidth() / SCALE - x * SCALE, y)

	love.graphics.pop()
end

return Hud
