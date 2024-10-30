local Anim8 = require("lib.anim8.anim8")
local Keymaps = require("config.keymaps")
local StateMachine = require("src.utils.state_machine")
local Sfx = require("src.sfx")

local Player = {}
Player.__index = Player

-- Define collision behaviors for different entity types:
-- types: "touch" | "cross" | "slide" | "bounce" | nil
local collision_types = {
	Coin = "cross",
	Door = "cross",
	Enemy = "slide",
	Collision = "slide",
}

local playerFilter = function(item, other)
	return collision_types[other.id] or nil -- Return nil for undefined collision_types
end

local hitboxFilter = function(item, other)
	return "cross"
end

function Player.new(entity)
	local self = setmetatable({}, Player)

	self.id = "Player"
	self.x = entity.x
	self.y = entity.y
	self.max_health = 3
	if entity.props then
		self.direction = entity.props.direction or 1
		self.coins = entity.props.coins or 0
		self.health = entity.props.health or 3
		self.atk = entity.props.atk or 1
	else
		self.direction = 1
		self.coins = 0
		self.health = self.max_health
		self.atk = 1
	end

	self.is_player = true
	self.is_next_level = nil
	self.hitbox = {}

	self.w = 18
	self.h = 26
	self.speed = 150
	self.y_velocity = 0
	self.jump_strength = -320
	self.gravity = 1200
	self.knock_back_offset = 5

	-- Timers
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.hit_cooldown = 0
	self.hit_cooldown_time = 0.4

	self.image_map = {}
	self.animations = {}
	self.curr_animation = nil
	self.state_machine = StateMachine.new()

	self:init()

	return self
end

function Player:addToWorld(world)
	self.world = world or self.world
	self.world:add(self, self.x, self.y, self.w, self.h, playerFilter)
	local x, y = self.world:getRect(self)
	self.x, self.y = x, y
end

function Player:loadAnimations()
	local sprite_w = 78
	local sprite_h = 58

	-- Load images
	self.attack_image = love.graphics.newImage("/assets/sprites/01-king-human/attack.png")
	self.dead_image = love.graphics.newImage("/assets/sprites/01-king-human/dead.png")
	self.door_open_image = love.graphics.newImage("/assets/sprites/01-king-human/door.png")
	self.door_close_image = love.graphics.newImage("/assets/sprites/01-king-human/door-out.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/01-king-human/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/01-king-human/ground.png")
	self.hit_image = love.graphics.newImage("/assets/sprites/01-king-human/hit.png")
	self.idle_image = love.graphics.newImage("/assets/sprites/01-king-human/idle.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/01-king-human/jump.png")
	self.run_image = love.graphics.newImage("/assets/sprites/01-king-human/run.png")

	-- Create a grid for the animations
	local attack_grid = Anim8.newGrid(sprite_w, sprite_h, self.attack_image:getWidth(), sprite_h)
	local dead_grid = Anim8.newGrid(sprite_w, sprite_h, self.dead_image:getWidth(), sprite_h)
	local door_open_grid = Anim8.newGrid(sprite_w, sprite_h, self.door_open_image:getWidth(), sprite_h)
	local door_close_grid = Anim8.newGrid(sprite_w, sprite_h, self.door_close_image:getWidth(), sprite_h)
	local fall_grid = Anim8.newGrid(sprite_w, sprite_h, self.fall_image:getWidth(), sprite_h)
	local ground_grid = Anim8.newGrid(sprite_w, sprite_h, self.ground_image:getWidth(), sprite_h)
	local hit_grid = Anim8.newGrid(sprite_w, sprite_h, self.hit_image:getWidth(), sprite_h)
	local idle_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_image:getWidth(), sprite_h)
	local jump_grid = Anim8.newGrid(sprite_w, sprite_h, self.jump_image:getWidth(), sprite_h)
	local run_grid = Anim8.newGrid(sprite_w, sprite_h, self.run_image:getWidth(), sprite_h)

	-- Create the animations
	self.animations.attack = Anim8.newAnimation(attack_grid("1-3", 1), 0.05, "pauseAtEnd")
	self.animations.dead = Anim8.newAnimation(dead_grid("1-4", 1), 0.1, "pauseAtEnd")
	self.animations.door_open = Anim8.newAnimation(door_open_grid("1-8", 1), 0.1, "pauseAtEnd")
	self.animations.door_close = Anim8.newAnimation(door_close_grid("1-8", 1), 0.1, "pauseAtEnd")
	self.animations.hit = Anim8.newAnimation(hit_grid("1-2", 1), 0.1)
	self.animations.fall = Anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = Anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.idle = Anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.jump = Anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = Anim8.newAnimation(run_grid("1-8", 1), 0.1)

	self.image_map = {
		[self.animations.attack] = self.attack_image,
		[self.animations.dead] = self.dead_image,
		[self.animations.door_open] = self.door_open_image,
		[self.animations.door_close] = self.door_close_image,
		[self.animations.hit] = self.hit_image,
		[self.animations.fall] = self.fall_image,
		[self.animations.ground] = self.ground_image,
		[self.animations.idle] = self.idle_image,
		[self.animations.jump] = self.jump_image,
		[self.animations.run] = self.run_image,
	}

	-- Set the initial animation to idle
	self.curr_animation = self.animations.idle
end

function Player:setupStates()
	self.state_machine:addState("grounded", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			self:handleMovement(dt)

			if self.jump_cooldown > 0 then
				self.jump_cooldown = self.jump_cooldown - dt
			end

			if self.y_velocity ~= 0 then
				self.state_machine:setState("airborne")
			end
		end,
		keypressed = function(_, key)
			if key == Keymaps.jump and self.jump_cooldown <= 0 then
				self.y_velocity = self.jump_strength
				self.jump_cooldown = self.jump_cooldown_time
				self.state_machine:setState("airborne")
			elseif key == Keymaps.attack then
				self.state_machine:setState("grounded.attacking")
			elseif key == Keymaps.up then
				local _, _, cols, len = self.world:check(self, self.x, self.y, playerFilter)
				for i = 1, len do
					local other = cols[i].other
					if other.id == "Door" then
						self.state_machine:setState("door.open")
						self.is_next_level = other:open()
					end
				end
			end
		end,
	})

	self.state_machine:addState("grounded.attacking", {
		enter = function()
			self:attack()
		end,
		update = function(_, dt)
			if self.hitbox.is_active then
				self.hitbox:update()
			end

			if self.curr_animation.status == "paused" then
				self:removeHitbox()
				self.state_machine:setState("grounded")
			end
		end,
	})

	self.state_machine:addState("airborne", {
		enter = function()
			self:setAirborneAnimation()
		end,
		update = function(_, dt)
			self:setAirborneAnimation()
			self:handleMovement(dt)

			if self.y_velocity == 0 then
				self.curr_animation = self.animations.ground
				self.state_machine:setState("grounded")
			end
		end,
		keypressed = function(_, key)
			-- Handle airborne attack
			if key == Keymaps.attack then
				self.state_machine:setState("airborne.attacking")
			end
		end,
	})

	self.state_machine:addState("airborne.attacking", {
		enter = function()
			self.curr_animation = self.animations.attack
			self.curr_animation:gotoFrame(1)
			self.curr_animation:resume()
			self:attack()
			Sfx:play("player.attack")
		end,
		update = function(_, dt)
			self:handleMovement(dt)

			if self.hitbox.is_active then
				self.hitbox:update()
			end

			if self.curr_animation.status == "paused" then
				self:removeHitbox()
				self:setAirborneAnimation()
				if self.y_velocity == 0 then
					self.state_machine:setState("grounded")
				else
					self.state_machine:setState("airborne")
				end
			end
		end,
	})

	self.state_machine:addState("door.open", {
		enter = function()
			self.curr_animation = self.animations.door_open
			self.curr_animation:gotoFrame(1)
			self.curr_animation:resume()
		end,
		update = function(_, dt) end,
	})

	self.state_machine:addState("door.close", {
		enter = function()
			self.curr_animation = self.animations.door_close
			self.curr_animation:gotoFrame(1)
			self.curr_animation:resume()
		end,
		update = function(_, dt)
			self.world:update(self, self.x, self.y)

			if self.curr_animation.status == "paused" then
				self.curr_animation = self.animations.idle
			end
		end,
	})

	self.state_machine:addState("hit", {
		enter = function()
			self.curr_animation = self.animations.hit
			self.hit_cooldown = self.hit_cooldown_time
			Sfx:play("player.hit")
			self:applyKnockback(self.knock_back_offset)
		end,
		update = function(_, dt)
			if self.hit_cooldown > 0 then
				self.hit_cooldown = self.hit_cooldown - dt
			end

			if self.hit_cooldown <= 0 then
				self.state_machine:setState("grounded")
				self.hit_cooldown = self.hit_cooldown_time
			end
		end,
	})

	-- Set default state
	self.state_machine:setState("grounded")
end

function Player:init()
	self:loadAnimations()
	self:setupStates()
end

function Player:setAirborneAnimation()
	self.curr_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
end

function Player:handleMovement(dt)
	local direction = 0

	if love.keyboard.isDown(Keymaps.right) then
		direction = 1
	elseif love.keyboard.isDown(Keymaps.left) then
		direction = -1
	end

	local dx = 0
	if direction ~= 0 then
		dx = self.speed * dt * direction
		self.direction = direction
		if self.state_machine:getState("grounded") then
			self.curr_animation = self.animations.run
		end
	elseif self.state_machine:getState("grounded") then
		self.curr_animation = self.animations.idle
	end

	local goal_x = self.x + dx

	self:move(goal_x, self.y)
end

function Player:addHitboxToWorld()
	local hitbox_w = 30
	local hitbox_h = 20

	local function update()
		self.world:update(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
		local _, _, cols, len = self.world:check(self.hitbox, self.hitbox.x, self.hitbox.y, hitboxFilter)
		for i = 1, len do
			local other = cols[i].other
			if other.id == "Enemy" and self.hitbox.is_active then
				other:hit(self.atk)
			end
		end
		self.hitbox.is_active = false
	end

	local hixbox_x = (self.direction == -1) and self.x - hitbox_w or self.x + self.w
	self.hitbox = {
		id = "Hitbox",
		x = hixbox_x,
		y = self.y - hitbox_h,
		w = hitbox_w,
		h = self.h + hitbox_h,
		is_active = true,
		update = update,
		player = self,
	}
	self.world:add(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
end

function Player:removeHitbox()
	self.world:remove(self.hitbox)
	self.hitbox = {}
end

function Player:attack()
	self.curr_animation = self.animations.attack
	self.curr_animation:gotoFrame(1)
	self.curr_animation:resume()
	Sfx:play("player.attack")
	self:addHitboxToWorld()
end

function Player:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, playerFilter)

	for i = 1, len do
		local other = cols[i].other
		if other.id == "Coin" then
			other:collect()
			self.coins = self.coins + 1
		end
	end

	self.x, self.y = actual_x, actual_y
end

function Player:applyGravity(dt)
	-- Update jump cooldown
	if self.jump_cooldown > 0 then
		self.jump_cooldown = self.jump_cooldown - dt
	end

	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_y = self.y + self.y_velocity * dt
	local _, actual_y, cols, len = self.world:check(self, self.x, goal_y, playerFilter)

	if len > 0 then
		for i = 1, len do
			local other = cols[i].other
			if other.id == "Collision" then
				self.y_velocity = 0
				return
			end
		end
	end

	self:move(self.x, actual_y)
end

function Player:applyKnockback(x_offset)
	local _, _, cols, len = self.world:check(self, self.x, self.y, self.enemy_filter)

	x_offset = x_offset or 0
	local hitbox_direction = 0
	for i = 1, len do
		local other = cols[i].other
		if other.id == "Hitbox" and other.enemy then
			if other.enemy.x > self.x then
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
		self.world:move(self, self.x + x_offset * hitbox_direction, self.y, self.enemy_filter)
	self.x, self.y = actual_x, actual_y
	self.direction = hitbox_direction
end

function Player:hit(atk)
	self.health = self.health - atk
	if self.health <= 0 then
		self.state_machine:setState("dead")
		self:applyKnockback(self.knock_back_offset)
	else
		self.state_machine:setState("hit")
	end
end

function Player:update(dt)
	self:applyGravity(dt)
	self.state_machine:update(dt)
	self.curr_animation:update(dt)
end

function Player:keypressed(key)
	self.state_machine:handleEvent("keypressed", key)
end

function Player:getState()
	return {
		x = self.x,
		y = self.y,
		max_health = self.max_health,
		health = self.health,
		coins = self.coins,
		atk = self.atk,
	}
end

function Player:setState(player_state)
	for key, value in pairs(player_state) do
		if self[key] ~= nil then
			self[key] = value
		end
	end
end

function Player:draw()
	local scale_x = (self.direction == -1) and -1 or 1 -- Flip the sprite based on direction
	local offset_x = (self.direction == -1) and 41 or 22 -- Shift the sprite to the correct position when flipped
	local offset_y = 18
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	love.graphics.push()

	self.curr_animation:draw(
		curr_image,
		self.x,
		self.y,
		0,
		scale_x, -- Flip horizontally when direction is left (-1)
		1,
		offset_x,
		offset_y
	)

	love.graphics.pop()
end

return Player
