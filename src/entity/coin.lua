local Anim8 = require("lib.anim8.anim8")
local Entity = require("src.entity.entity")
local Sfx = require("src.sfx")

local Coin = {}
Coin.__index = Coin
setmetatable(Coin, Entity)

local sprite_w = 18
local sprite_h = 14

function Coin.new(entity, world)
	local self = Entity.new(entity, world)
	setmetatable(self, Coin)

	self.w = 11
	self.h = 14
	self.x_offset = self.w
	self.y_offset = self.h
	self.timer = 1

	self:init()

	return self
end

function Coin:addToWorld()
	self.is_active = true
	self.world:add(self, self.x - self.w / 2, self.y - self.y_offset, self.w, self.h)
end

function Coin:init()
	self:loadAnimations()
end

function Coin:loadAnimations()
	self.idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-idle.png")
	self.hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-hit.png")

	self.idle_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_image:getWidth(), sprite_h)
	self.hit_grid = Anim8.newGrid(sprite_w, sprite_h, self.hit_image:getWidth(), sprite_h)

	self.animations.idle = Anim8.newAnimation(self.idle_grid("1-10", 1), 0.1)
	self.animations.hit = Anim8.newAnimation(self.hit_grid("1-2", 1), 0.1)

	self.image_map = {
		[self.animations.idle] = self.idle_image,
		[self.animations.hit] = self.hit_image,
	}

	self.curr_animation = self.animations.idle
end

function Coin:collect()
	Sfx:play("coin.collect")
	self.curr_animation = self.animations.hit
	self:removeFromWorld()
end

function Coin:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end

	-- Allow the coin to remain visible for a short duration before disappearing
	if not self.is_active and self.timer >= 0 then
		self.timer = self.timer - dt
	end
end

function Coin:draw()
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	-- TODO: add animation offset across coins
	if self.is_active or self.timer >= 0 then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, 1, 1, self.x_offset, self.y_offset)
	end
end

return Coin
