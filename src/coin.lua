local anim8 = require("lib.anim8.anim8")
local sfx = require("src.sfx")
local ldtk = require("lib.ldtk-love.ldtk")

local Coin = {}
Coin.__index = Coin

local sprite_width = 18
local sprite_height = 14

function Coin.new(x, y)
	local self = setmetatable({}, Coin)
	self.is_coin = true
	self.is_collected = false
	self.timer = 1

	self.x = x
	self.y = y
	self.width = 18
	self.height = 14
	self.x_offset = self.width / SCALE
	self.y_offset = self.height

	self.current_animation = nil
	self.animations = {}

	self:init()

	return self
end

function Coin:init()
	self.idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-idle.png")
	self.hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-hit.png")

	self.idle_grid = anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	self.hit_grid = anim8.newGrid(sprite_width, sprite_height, self.hit_image:getWidth(), sprite_height)

	self.animations.idle = anim8.newAnimation(self.idle_grid("1-10", 1), 0.1)
	self.animations.hit = anim8.newAnimation(self.hit_grid("1-2", 1), 0.1)

	self.current_animation = self.animations.idle
end

function Coin:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end

	if self.is_collected and self.timer >= 0 then
		self.timer = self.timer - dt
	end
end

function Coin:collect()
	sfx:play("coin.collected")
	self.current_animation = self.animations.hit
	self.is_collected = true

	World:remove(self)
end

function Coin:draw()
	-- TODO: add animation offset across coins
	if not self.is_collected or self.timer >= 0 then
		self.current_animation:draw(
			self.current_animation == self.animations.hit and self.hit_image or self.idle_image,
			self.x,
			self.y,
			0,
			1,
			1,
			self.x_offset,
			self.y_offset
		)
	end
end

return Coin
