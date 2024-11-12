local Anim8 = require("lib.anim8.anim8")
local Entity = require("src.entity.entity")
local Sfx = require("src.sfx")

local Bomb = {}
Bomb.__index = Bomb
setmetatable(Bomb, Entity)

local coinFilter = function(item, other)
	if other.id == "Collision" then
		return "slide"
	else
		return "cross"
	end
end

local sprite_w = 52
local sprite_h = 56

function Bomb.new(entity)
	local self = Entity.new(entity)
	setmetatable(self, Bomb)

	self.w = 13
	self.h = 14
	self.x_offset = self.w / 2
	self.y_offset = self.h
	self.x_velocity = 0
	self.y_velocity = 0
	self.atk = entity.props.atk or 0
	self.jump_strength = -250
	self.friction = 100
	self.gravity = 800

	self.is_on = false
	self.is_exploded = false

	self.timer = 0.1
	self.countdown_timer = 1
	self.explode_timer = 3

	self:init()

	return self
end

function Bomb:init()
	self:loadAnimations()
end

function Bomb:loadAnimations()
	self.idle_image = love.graphics.newImage("assets/sprites/09-bomb/bomb-idle.png")
	self.on_image = love.graphics.newImage("assets/sprites/09-bomb/bomb-on.png")
	self.explode_image = love.graphics.newImage("assets/sprites/09-bomb/bomb-explode.png")

	self.idle_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_image:getWidth(), sprite_h)
	self.on_grid = Anim8.newGrid(sprite_w, sprite_h, self.on_image:getWidth(), sprite_h)
	self.explode_grid = Anim8.newGrid(sprite_w, sprite_h, self.explode_image:getWidth(), sprite_h)

	self.animations.idle = Anim8.newAnimation(self.idle_grid("1-1", 1), 0.1)
	self.animations.on = Anim8.newAnimation(self.on_grid("1-4", 1), 0.1)
	self.animations.explode = Anim8.newAnimation(self.explode_grid("1-6", 1), 0.1, "pauseAtEnd")

	self.image_map = {
		[self.animations.idle] = self.idle_image,
		[self.animations.on] = self.on_image,
		[self.animations.explode] = self.explode_image,
	}

	self.curr_animation = self.animations.idle
end

function Bomb:explode()
	Sfx:play("bomb.explode")
	self.curr_animation = self.animations.explode
	local function bombFilter(item)
		return item.id == "Player" or item.id == "Enemy"
	end
	local items, len = self.world:queryRect(self.x, self.y, self.x + self.w, self.y + self.h, bombFilter)
	if len > 0 then
		for _, item in ipairs(items) do
			item:hit(self)
		end
	end

	self:removeFromWorld()
	self.is_exploded = true
end

function Bomb:on()
	Sfx:play("bomb.on")
	self.curr_animation = self.animations.on
	self.is_on = true
end

function Bomb:applyGravity(dt)
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

function Bomb:spawn(x_velocity)
	self.x_velocity = x_velocity or 0
	self.y_velocity = self.jump_strength
	Sfx:play("bomb.spawn")
end

function Bomb:updateInactive(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
	end
end

function Bomb:updateTimers(dt)
	if self.countdown_timer >= 0 then
		self.countdown_timer = self.countdown_timer - dt
		return
	end

	if not self.is_on then
		self:on()
	end

	if self.explode_timer >= 0 then
		self.explode_timer = self.explode_timer - dt
	else
		if not self.is_exploded then
			self:explode()
		end
	end
end

function Bomb:updateAnimations(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Bomb:update(dt)
	if not self.is_active then
		self:updateInactive(dt)
		return
	end

	self:applyGravity(dt)
	self:updateTimers(dt)
	self:updateAnimations(dt)
end

function Bomb:draw()
	local offset_x = 20
	local offset_y = 25
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	-- TODO: add animation offset across bombs
	if self.timer > 0 then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, 1, 1, offset_x, offset_y)
	end
end

return Bomb
