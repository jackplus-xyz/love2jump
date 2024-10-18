local Anim8 = require("lib.anim8.anim8")
local Fonts = require("src.assets.fonts")

local Hud = {}
Hud.__index = Hud

function Hud.new(player)
	local instance = setmetatable({}, Hud)
	instance.player = {}
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
	self.coin_grid = Anim8.newGrid(sprite_width, sprite_height, self.coin_image:getWidth(), sprite_height)
	self.animations.coin = Anim8.newAnimation(self.coin_grid("1-10", 1), 0.1)

	local big_heart_idle_grid =
		Anim8.newGrid(sprite_width, sprite_height, self.big_heart_idle_image:getWidth(), sprite_height)
	local big_heart_hit_grid =
		Anim8.newGrid(sprite_width, sprite_height, self.big_heart_hit_image:getWidth(), sprite_height)

	Hud.live_bar_animations = {
		big_heart_idle = Anim8.newAnimation(big_heart_idle_grid("1-8", 1), 0.1),
		big_heart_hit = Anim8.newAnimation(big_heart_hit_grid("1-2", 1), 0.1),
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
	local start_x, start_y = GRID_SIZE / 2, GRID_SIZE / 2
	local offset_x, offset_y = 12, 11
	local heart_offset = 12

	love.graphics.push()

	love.graphics.scale(SCALE)
	love.graphics.draw(self.live_bar_image, start_x, start_y)

	for i = 1, self.player.health do
		local anim_offset = (i - 1) * 0.1

		self.live_bar_animations.big_heart_idle:update(-anim_offset)

		self.live_bar_animations.big_heart_idle:draw(
			self.big_heart_idle_image,
			start_x + offset_x + (i - 1) * heart_offset,
			start_y + offset_y,
			0,
			0.8,
			0.8
		)

		self.live_bar_animations.big_heart_idle:update(anim_offset)
	end

	self.animations.coin:draw(self.coin_image, love.graphics.getWidth() / SCALE - start_x * 4, start_y)
	love.graphics.setFont(Fonts.heading_1)
	love.graphics.print(self.player.coins, love.graphics.getWidth() / SCALE - start_x * SCALE, start_y, 0, 0.25, 0.25)

	love.graphics.pop()
end

return Hud
