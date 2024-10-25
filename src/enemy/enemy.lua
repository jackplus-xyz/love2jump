local StateMachine = require("src.utils.state_machine")

local Enemy = {}
Enemy.__index = Enemy

local enemy_filter = function(item, other)
	if other.id == "Hitbox" then
		return "cross"
	else
		return "slide"
	end
end

function Enemy.new(entity, world)
	local self = setmetatable({}, Enemy)

	self.iid = entity.iid
	self.id = "Enemy"
	self.type = entity.props.Enemy
	self.x = entity.x
	self.y = entity.y
	self.max_health = entity.props.max_health
	self.health = self.max_health
	self.world = world

	self.is_active = true

	self.image_map = {}
	self.animations = {}
	self.curr_animation = nil
	self.state_machine = StateMachine.new()
	self.enemy_filter = enemy_filter

	return self
end

function Enemy:addToWorld()
	self.world:add(self, self.x - self.w, self.y - self.h, self.w, self.h, self.enemy_filter)
end

function Enemy:hit(atk)
	self.health = self.health - atk
	self.state_machine:setState("hit")
end

function Enemy:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y)

	if goal_x > self.x then
		self.direction = 1
	else
		self.direction = -1
	end

	self.x, self.y = actual_x, actual_y
end

function Enemy:applyGravity(dt)
	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_y = self.y + self.y_velocity * dt
	local _, _, _, len = self.world:check(self, self.x, goal_y)

	if len > 0 then
		self.y_velocity = 0
	else
		self:move(self.x, goal_y)
	end
end

function Enemy:setAirborneAnimation()
	self.curr_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
end

function Enemy:update(dt)
	self.state_machine:update(dt)
	if self.curr_animation then
		self:applyGravity(dt)
		self.curr_animation:update(dt)
	end
end

function Enemy:draw() end

return Enemy
