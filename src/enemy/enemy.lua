local StateMachine = require("src.utils.state_machine")

local Enemy = {}
Enemy.__index = Enemy

local enemyFilter = function(item, other)
	if other.id == "Hitbox" then
		return "cross"
	else
		return "slide"
	end
end

function Enemy.new(entity)
	local self = setmetatable({}, Enemy)

	self.iid = entity.iid
	self.id = "Enemy"
	self.type = entity.props.Enemy
	self.x = entity.x
	self.y = entity.y
	self.max_health = entity.props.max_health
	self.health = self.max_health
	self.atk = entity.props.atk

	self.is_active = true

	self.image_map = {}
	self.animations = {}
	self.curr_animation = nil
	self.state_machine = StateMachine.new()
	self.enemy_filter = enemyFilter

	return self
end

function Enemy:applyKnockback(x_offset)
	local _, _, cols, len = self.world:check(self, self.x, self.y, self.enemy_filter)

	x_offset = x_offset or 0
	local hitbox_direction = 0
	for i = 1, len do
		local other = cols[i].other
		if other.id == "Hitbox" and other.player then
			if other.player.x > self.x then
				hitbox_direction = 1
				break
			else
				hitbox_direction = -1
				break
			end
		end
	end

	-- flip the hitbox_direction
	local actual_x, actual_y, _, _ =
		self.world:move(self, self.x + x_offset * -hitbox_direction, self.y, self.enemy_filter)
	self.x, self.y = actual_x, actual_y
	self.direction = hitbox_direction
end

function Enemy:hit(atk)
	self.health = self.health - atk
	if self.health <= 0 then
		self.state_machine:setState("dead")
		self:applyKnockback(self.knock_back_offset)
	else
		self.state_machine:setState("hit")
	end
end

function Enemy:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, self.enemy_filter)

	if actual_x > self.x then
		self.direction = 1
	else
		self.direction = -1
	end

	self.x, self.y = actual_x, actual_y
end

function Enemy:applyGravity(dt)
	if self.jump_cooldown > 0 then
		self.jump_cooldown = self.jump_cooldown - dt
	end

	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_y = self.y + self.y_velocity * dt
	local _, actual_y, cols, len = self.world:check(self, self.x, goal_y, self.enemy_filter)

	if len > 0 then
		for i = 1, len do
			local other = cols[i].other
			if other.id == "Collision" then
				if cols[i].normal.y < 0 then
					self.y_velocity = 0
					return
				end
			end
		end
	end

	self:move(self.x, actual_y)
end

function Enemy:setAirborneAnimation()
	self.curr_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
end

function Enemy:dropItem(item, x_velocity)
	self.spawnDrop(item)

	x_velocity = math.random(-1, 1) * x_velocity
	item:spawn(x_velocity)
end

function Enemy:update(dt)
	self.state_machine:update(dt)
	if self.curr_animation then
		self:applyGravity(dt)
		self.curr_animation:update(dt)
	end
end

return Enemy
