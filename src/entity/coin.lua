local Anim8 = require("lib.anim8.anim8")
local Entity = require("src.entity.entity")
local Sfx = require("src.sfx")

local Coin = {}
Coin.__index = Coin
setmetatable(Coin, Entity)

local coinFilter = function(item, other)
	if other.id == "Player" or other.id == "Coin" then
		return "cross"
	else
		return "slide"
	end
end

local sprite_w = 18
local sprite_h = 14

function Coin.new(entity)
	local self = Entity.new(entity)
	setmetatable(self, Coin)

	self.w = 12
	self.h = 10
	self.x_offset = self.w / 2
	self.y_offset = self.h
	self.timer = 1
	self.x_velocity = 0
	self.y_velocity = 0
	self.jump_strength = -250
	self.friction = 100
	self.gravity = 800

	self:init()

	return self
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

function Coin:applyGravity(dt)
	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_x = self.x + self.x_velocity * dt
	local goal_y = self.y + self.y_velocity * dt
	local actual_x, actual_y, cols, len = self.world:check(self, goal_x, goal_y, coinFilter)

	if len > 0 then
		for i = 1, len do
			local other = cols[i].other
			if other.id == "Collision" then
				if cols[i].normal.y < 0 then
					self.x_velocity = 0
					self.y_velocity = 0
				end
			end
		end
	end

	self:move(actual_x, actual_y, coinFilter)
end

function Coin:spawn(x_velocity)
	self.is_spawn = true
	self.x_velocity = x_velocity or 0
	self.y_velocity = self.jump_strength
	Sfx:play("coin.spawn")
end

function Coin:update(dt)
	if self.is_active and self.is_spawn then
		self:applyGravity(dt)
	end

	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end

	-- Allow the coin to remain visible for a short duration before disappearing
	if not self.is_active and self.timer >= 0 then
		self.timer = self.timer - dt
	end
end

function Coin:draw()
	local offset_x = 5
	local offset_y = 2
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	-- TODO: add animation offset across coins
	if self.is_active or self.timer >= 0 then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, 1, 1, offset_x, offset_y)
	end
end

return Coin
