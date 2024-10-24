local StateMachine = require("src.utils.state_machine")

---@class Enemy
local enemy = {}

-- class table
local Enemy = {}

function enemy.new(entity, world)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.iid = entity.iid
	self.id = "Enemy"
	self.type = entity.props.Enemy
	self.x = entity.x
	self.y = entity.y
	self.world = world
	self.max_health = entity.props.max_health
	self.health = self.max_health

	self.current_animation = nil
	self.animations = {}
	self.state_machine = StateMachine.new()

	self:init()

	return self
end

function Enemy:init() end

function Enemy:addToWorld() end

function Enemy:loadAnimations() end

function Enemy:setupStates() end

function Enemy:attacked(atk)
	self.health = self.health - atk
	self.state_machine:setState("attacked")
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
	self.current_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
end

function Enemy:update(dt)
	self.state_machine:update(dt)
	if self.current_animation then
		self:applyGravity(dt)
		self.current_animation:update(dt)
	end
end

function Enemy:draw() end

return enemy
