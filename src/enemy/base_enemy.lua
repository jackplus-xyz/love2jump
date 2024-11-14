local StateMachine = require("src.utils.state_machine")
local Dialogue = require("src.utils.dialogue")
local WorldHelpers = require("src.utils.world_helpers")

local COLLISION_TYPES = {
	Coin = "cross",
	Door = "cross",
	Enemy = "slide",
	Player = "slide",
	Collision = "slide",
}

local ENTITY_TYPES = {
	Player = "Player",
	Enemy = "Enemy",
	Collision = "Collision",
	Hitbox = "Hitbox",
}

local DIRECTION = {
	LEFT = -1,
	RIGHT = 1,
}

local Enemy = {}
Enemy.__index = Enemy

local collision_types = {
	Coin = "cross",
	Door = "cross",
	Enemy = "slide",
	Player = "slide",
	Collision = "slide",
}

function Enemy.new(entity)
	local self = setmetatable({}, Enemy)

	self.iid = entity.iid
	self.id = "Enemy"
	self.type = entity.props.Enemy or nil
	self.x = entity.x
	self.y = entity.y
	self.max_health = entity.props.max_health
	self.health = self.max_health
	self.atk = entity.props.atk
	self.direction = math.random(-1, 1) <= 0 and DIRECTION.RIGHT or DIRECTION.LEFT

	self.is_active = true

	self.image_map = {}
	self.animations = {}
	self.curr_animation = nil
	self.state_machine = StateMachine.new()
	self.dialogue = Dialogue.new()

	self.enemyFilter = function(_, other)
		return collision_types[other.id] or nil -- Return nil for undefined collision_types
	end
	self.hitboxFilter = function(_, _)
		return "cross"
	end

	return self
end

function Enemy:applyKnockback(x_offset, hitbox_direction)
	x_offset = x_offset or 0
	-- flip the hitbox_direction
	local actual_x, actual_y, _, _ =
		self.world:move(self, self.x + x_offset * -hitbox_direction, self.y, self.enemyFilter)
	self.x, self.y = actual_x, actual_y
	self.direction = hitbox_direction
end

function Enemy:hit(other)
	self.health = self.health - other.atk
	local hitbox_direction = other.x > self.x and 1 or -1
	self:applyKnockback(self.knock_back_offset, hitbox_direction)
	if self.health <= 0 then
		self.state_machine:setState("dead")
	else
		self.state_machine:setState("hit")
	end
end

function Enemy:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, self.enemyFilter)

	if actual_x > self.x then
		self.direction = 1
	elseif actual_x < self.x then
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

function Enemy:checkAirborne()
	if self.y_velocity ~= 0 then
		self.state_machine:setState("airborne")
	end
end

function Enemy:setAirborneAnimation()
	self.curr_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
end

--- Drop an item with optional velocity and randomness.
---@param item table: The item to drop.
---@param x_velocity number: The x velocity of the item (optional).
---@param randomness number: The randomness factor (optional).
function Enemy:dropItem(item, x_velocity, randomness)
	randomness = randomness or 1
	x_velocity = x_velocity or 0
	x_velocity = math.random(-randomness, randomness) * x_velocity

	item.addToWorld = WorldHelpers.addToWorld
	item.removeFromWorld = WorldHelpers.removeFromWorld
	item:addToWorld(self.world)
	self.addEntityToGame(item)
	item:spawn(x_velocity)
end

--- Check if the player is in sight.
---@param offset_y number: Distance from top to eye (optional).
---@param range number: Distance to check if Player is in sight (optional).
---@return table|nil: Coordinates of the player if in sight, otherwise nil.
function Enemy:isPlayerInSight(offset_y, range)
	offset_y = offset_y or 0 -- Distance from top to eye
	range = range or 0

	local sightFilter = function(item)
		return item ~= self -- Ignore self
	end

	local items, len = self.world:querySegment(
		self.direction > 0 and self.x + self.w or self.x - range,
		self.y + offset_y,
		self.direction > 0 and self.x + self.w + range or self.x,
		self.y + offset_y,
		sightFilter
	)

	if len > 0 and items[1].id == "Player" then
		return { x = items[1].x, y = items[1].y }
	end
end

--- Check if there is a path to the target coordinates.
---@param target_x number: The target x coordinate.
---@param target_y number: The target y coordinate.
---@param dt number: Delta time.
---@return boolean: True if there is a path, otherwise false.
function Enemy:isPathTo(target_x, target_y, dt)
	local max_jump_height = self.jump_strength * self.jump_strength / self.gravity / 2
	local start_x = self.direction > 0 and self.x + self.w or self.x
	local start_y = self.y + self.h

	local pathFilter = function(item)
		return collision_types[item.id] and collision_types[item.id] ~= "cross"
	end

	local current_x, current_y = start_x, start_y

	if self.max_jump_attempts then
		for i = 1, self.max_jump_attempts do
			local items, len = self.world:querySegment(current_x, current_y, target_x, target_y, pathFilter)

			if len == 0 or max_jump_height >= items[1].h then
				return true
			end

			current_x, current_y = items[1].x, items[1].y + self.h
		end
	end

	return false
end

function Enemy:isPlayerInAttackRange()
	local function playerFilter(item)
		return item.id == "Player"
	end

	local hitbox_x = (self.direction == DIRECTION.LEFT) and self.x - self.hitbox_w or self.x + self.w

	local items, len = self.world:querySegment(hitbox_x, self.y, self.hitbox_w, self.hitbox_h, playerFilter)

	return len > 0
end

function Enemy:setTarget(target_x, target_y)
	target_x = target_x or self.target_x
	target_y = target_y or self.target_y
	self.target_x, self.target_y = target_x, target_y
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
			if other.id == ENTITY_TYPES.Player and self.hitbox.is_active then
				other:hit(self)
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
	self.curr_animation = self.animations.attack
	self.curr_animation:gotoFrame(1)
	self.curr_animation:resume()
	self:addHitboxToWorld()
end

function Enemy:jump()
	self.y_velocity = self.jump_strength
	self.jump_cooldown = self.jump_cooldown_time
end

-- Check if the target can be reached by one jump
-- Check if the target can be reached by one jump
function Enemy:canJumpToTarget(target_x, target_y)
	target_x = target_x or self.target_x
	target_y = target_y or self.target_y

	local dx = target_x - self.x

	-- Calculate the time to reach the target horizontally
	local t = math.abs(dx) / self.speed

	if t > math.abs(2 * self.jump_strength / self.gravity) then
		return false
	end

	-- Calculate the vertical distance to the target
	local dy = target_y - self.y

	local max_jump_height = (self.jump_strength * self.jump_strength) / (2 * self.gravity)

	return math.abs(dy) <= max_jump_height
end

--- Check if there is an obstacle in the path.
---@param dt number: Delta time.
---@param dx number: The x distance to check.
---@param dy number: The y distance to check.
---@param distance number: The total distance to check.
---@return table|nil: The obstacle coordinates and height if found, otherwise nil.
function Enemy:isObstacle(dt, dx, dy, distance)
	local goal_x = self.x + (dx / distance) * self.speed * dt
	-- TODO: check if self.h is required
	local goal_y = self.y + (dy / distance) * self.y_velocity * dt
	local jumpFilter = function(item)
		return item.id == "Collision"
	end
	local items, len = self.world:queryPoint(goal_x + dx > 0 and self.w or 0, goal_y, jumpFilter)

	if len == 0 then
		return nil
	end

	local _, _, _, item_h = self.world:getRect(items[1])

	return { x = goal_x, y = goal_y, item_h = item_h }
end

-- Check if the distance between self and target is smaller or equal to the GRID_SIZE
---@param target_x number: The target x coordinate.
---@param target_y number: The target y coordinate.
---@return boolean: True if the distance is smaller or equal to GRID_SIZE, otherwise false.
function Enemy:isAtTarget(target_x, target_y)
	local dx = target_x - self.x
	local dy = target_y - self.y
	local distance = math.sqrt(dx * dx + dy * dy)

	return distance <= GRID_SIZE
end

function Enemy:update(dt)
	self:applyGravity(dt)
	self.state_machine:update(dt)
	if self.curr_animation then
		self.curr_animation:update(dt)
	end
end

return Enemy
