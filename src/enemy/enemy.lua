local StateMachine = require("src.utils.state_machine")
local Sfx = require("src.sfx")

local Enemy = {}
Enemy.__index = Enemy

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

	self.enemyFilter = function(_, other)
		if other.id == "Hitbox" then
			return "cross"
		else
			return "slide"
		end
	end
	self.hitboxFilter = function(_, _)
		return "cross"
	end

	return self
end

function Enemy:applyKnockback(x_offset)
	local _, _, cols, len = self.world:check(self, self.x, self.y, self.enemyFilter)

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
		self.world:move(self, self.x + x_offset * -hitbox_direction, self.y, self.enemyFilter)
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
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, self.enemyFilter)

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
	local function gravityFilter(item, other)
		if other.id == "Collision" or other.id == "Enemy" or other.id == "Player" then
			return "slide"
		end
	end
	local _, actual_y, cols, len = self.world:check(self, self.x, goal_y, gravityFilter)

	if len > 0 then
		self.y_velocity = 0
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

function Enemy:isPathTo(dt)
	if not self.target_x and self.target_y then
		return false
	end

	local sightFilter = function(item)
		return item.id ~= "Enemy"
	end

	local items, len = self.world:querySegment(self.x, self.y + self.h, self.target_x, self.y + self.h, sightFilter)

	-- TODO: factor in gravity and jumping

	-- local max_jump_height = 50 -- Maximum height the enemy can jump
	-- local gravity = 9.8
	-- local move_speed = 30 -- Horizontal movement speed of the enemy
	-- local time_step = 0.1 -- Simulation time step
	-- local max_attempts = 100 -- Maximum number of simulation steps
	--
	-- -- Starting position
	-- local x, y = self.x, self.y
	-- local vy = 0 -- Vertical velocity, used for jumping/falling
	--
	-- for i = 1, max_attempts do
	-- 	-- Calculate target direction
	-- 	local dx = self.target_x - x
	-- 	local dy = self.target_y - y
	--
	-- 	-- If close enough to target, return true
	-- 	if math.abs(dx) < 1 and math.abs(dy) < 1 then
	-- 		return true
	-- 	end
	--
	-- 	-- Horizontal movement towards target
	-- 	local stepX = math.min(math.abs(dx), move_speed * time_step) * (dx > 0 and 1 or -1)
	--
	-- 	-- Apply gravity for falling
	-- 	vy = vy + gravity * time_step
	-- 	local stepY = vy * time_step
	--
	-- 	-- Check if a jump is needed (if obstacle ahead and below target)
	-- 	if math.abs(dx) < move_speed * time_step and dy < max_jump_height then
	-- 		vy = -math.sqrt(2 * gravity * max_jump_height) -- Jump with enough force to reach max height
	-- 	end
	--
	-- 	-- Check for collisions at next position
	-- 	local futureX, futureY = x + stepX, y + stepY
	-- 	local actualX, actualY, cols, len = self.world:check(self, futureX, futureY)
	--
	-- 	if len > 0 then
	-- 		-- If collision occurs and is not a valid path, return false
	-- 		for _, col in ipairs(cols) do
	-- 			if col.other.isObstacle then
	-- 				return false -- Path blocked by an obstacle
	-- 			end
	-- 		end
	-- 	else
	-- 		-- Update position if no collision
	-- 		x, y = actualX, actualY
	-- 	end
	-- end

	-- Return false if maximum steps are reached without a clear path
	return false
end

function Enemy:addHitboxToWorld(hitboxFilter)
	local hixbox_x = (self.direction == -1) and self.x - self.hitbox_w or self.x + self.w
	hitboxFilter = hitboxFilter or self.hitboxFilter

	local function update()
		if not self.hitbox.is_active then
			return
		end

		self.world:update(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
		local _, _, cols, len = self.world:check(self.hitbox, self.hitbox.x, self.hitbox.y, hitboxFilter)
		for i = 1, len do
			local other = cols[i].other
			if other.id == "Player" and self.hitbox.is_active then
				other:hit(self.atk)
				self.hitbox.is_active = false
				break
			end
		end
		self:removeHitbox()
	end

	self.hitbox = {
		id = "Hitbox",
		x = hixbox_x,
		y = self.y - self.hitbox_h,
		w = self.hitbox_w,
		h = self.h + self.hitbox_h,
		is_active = true,
		update = update,
		enemy = self,
	}
	self.world:add(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
end

function Enemy:removeHitbox()
	self.world:remove(self.hitbox)
	self.hitbox = {}
end

function Enemy:attack()
	Sfx:play("enemy.attack")
	self:addHitboxToWorld()
end

function Enemy:update(dt)
	self.state_machine:update(dt)
	if self.curr_animation then
		self:applyGravity(dt)
		self.curr_animation:update(dt)
	end
end

return Enemy
