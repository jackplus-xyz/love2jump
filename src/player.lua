local Anim8 = require("lib.anim8.anim8")
local Keymaps = require("config.keymaps")
local StateMachine = require("src.utils.state_machine")
local Sfx = require("src.sfx")

---@class player
local player = {}

-- class table
local Player = {}

local playerFilter = function(item, other)
	if other.is_coin then
		return "cross"
	elseif other.is_door then
		return "cross"
	elseif other.is_enemy then
		return "slide"
	elseif other.is_block then
		return "slide"
	elseif other.is_hitbox then
		return "cross"
	end
	-- else return nil
end

local hitboxFilter = function(item, other)
	return "cross"
end

function player.new(x, y, world)
	local self = {}
	setmetatable(self, { __index = Player })

	self.x = x
	self.y = y
	self.world = world
	self.is_player = true
	self.is_next_level = nil
	self.hitbox = {}

	self.width = 18
	self.height = 26
	self.speed = 150
	self.direction = 1
	self.y_velocity = 0
	self.jump_strength = -320
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.gravity = 1200
	self.coins = 0

	self.health = 3
	self.max_health = 3
	self.atk = 3

	self.current_animation = nil
	self.animations = {}
	self:loadAnimations()

	self.state_machine = StateMachine.new()
	self:setupStates()

	return self
end

function Player:loadAnimations()
	local sprite_width = 78
	local sprite_height = 58

	-- Load images
	self.attack_image = love.graphics.newImage("/assets/sprites/01-king-human/attack.png")
	self.dead_image = love.graphics.newImage("/assets/sprites/01-king-human/dead.png")
	self.door_enter_image = love.graphics.newImage("/assets/sprites/01-king-human/door.png")
	self.door_out_image = love.graphics.newImage("/assets/sprites/01-king-human/door-out.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/01-king-human/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/01-king-human/ground.png")
	self.hit_image = love.graphics.newImage("/assets/sprites/01-king-human/hit.png")
	self.idle_image = love.graphics.newImage("/assets/sprites/01-king-human/idle.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/01-king-human/jump.png")
	self.run_image = love.graphics.newImage("/assets/sprites/01-king-human/run.png")

	-- Create a grid for the animations
	local attack_grid = Anim8.newGrid(sprite_width, sprite_height, self.attack_image:getWidth(), sprite_height)
	local dead_grid = Anim8.newGrid(sprite_width, sprite_height, self.dead_image:getWidth(), sprite_height)
	local door_enter_grid = Anim8.newGrid(sprite_width, sprite_height, self.door_enter_image:getWidth(), sprite_height)
	local door_out_grid = Anim8.newGrid(sprite_width, sprite_height, self.door_out_image:getWidth(), sprite_height)
	local fall_grid = Anim8.newGrid(sprite_width, sprite_height, self.fall_image:getWidth(), sprite_height)
	local ground_grid = Anim8.newGrid(sprite_width, sprite_height, self.ground_image:getWidth(), sprite_height)
	local hit_grid = Anim8.newGrid(sprite_width, sprite_height, self.hit_image:getWidth(), sprite_height)
	local idle_grid = Anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	local jump_grid = Anim8.newGrid(sprite_width, sprite_height, self.jump_image:getWidth(), sprite_height)
	local run_grid = Anim8.newGrid(sprite_width, sprite_height, self.run_image:getWidth(), sprite_height)

	-- Create the animations
	self.animations.attack = Anim8.newAnimation(attack_grid("1-3", 1), 0.05, "pauseAtEnd")
	self.animations.dead = Anim8.newAnimation(dead_grid("1-4", 1), 0.1, "pauseAtEnd")
	self.animations.door_enter = Anim8.newAnimation(door_enter_grid("1-8", 1), 0.1, "pauseAtEnd")
	self.animations.door_out = Anim8.newAnimation(door_out_grid("1-8", 1), 0.1, "pauseAtEnd")
	self.animations.hit = Anim8.newAnimation(hit_grid("1-2", 1), 0.1)
	self.animations.fall = Anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = Anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.idle = Anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.jump = Anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = Anim8.newAnimation(run_grid("1-8", 1), 0.1)

	-- Set the initial animation to idle
	self.current_animation = self.animations.idle
end

function Player:setupStates()
	self.state_machine:addState("grounded", {
		enter = function()
			self.current_animation = self.animations.idle
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
					if other.is_door then
						self.state_machine:setState("door.enter")
						self.is_next_level = other:enter()
					end
				end
			end
		end,
	})

	self.state_machine:addState("grounded.attacking", {
		enter = function()
			self:attack()
		end,
		update = function(_)
			self:updateHitbox()

			if self.current_animation.status == "paused" then
				self.world:remove(self.hitbox)
				self.hitbox = {}
				self.state_machine:setState("grounded")
			end
		end,
	})

	self.state_machine:addState("airborne", {
		enter = function()
			self:setAirborneAnimation()
		end,
		update = function(_, dt)
			-- Update jump cooldown
			if self.jump_cooldown > 0 then
				self.jump_cooldown = self.jump_cooldown - dt
			end

			self:setAirborneAnimation()
			self:handleMovement(dt)

			if self.y_velocity == 0 then
				self.current_animation = self.animations.ground
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
			self.current_animation = self.animations.attack
			self.current_animation:gotoFrame(1)
			self.current_animation:resume()
			self:attack()
			Sfx:play("player.attack")
		end,
		update = function(_, dt)
			-- Update jump cooldown
			if self.jump_cooldown > 0 then
				self.jump_cooldown = self.jump_cooldown - dt
			end

			self:handleMovement(dt)
			self:updateHitbox()

			if self.current_animation.status == "paused" then
				self.world:remove(self.hitbox)
				self.hitbox = {}
				self:setAirborneAnimation()
				if self.y_velocity == 0 then
					self.state_machine:setState("grounded")
				else
					self.state_machine:setState("airborne")
				end
			end
		end,
	})

	self.state_machine:addState("door.enter", {
		enter = function()
			self.current_animation = self.animations.door_enter
			self.current_animation:gotoFrame(1)
			self.current_animation:resume()
		end,
		update = function(_, dt)
			if self.current_animation.status == "paused" then
				self.state_machine:setState("door.out")
			end
		end,
	})

	self.state_machine:addState("door.out", {
		enter = function()
			self.current_animation = self.animations.door_out
			self.current_animation:gotoFrame(1)
			self.current_animation:resume()
		end,
		update = function(_, dt)
			self.world:update(self, self.x, self.y)
			local _, _, cols, len = self.world:check(self, self.x, self.y, playerFilter)
			for i = 1, len do
				local other = cols[i].other
				if other.is_door and not other.is_next then
					other:out()
				end
			end
			if self.current_animation.status == "paused" then
				self.state_machine:setState("grounded")
			end
		end,
	})

	-- Set default state
	self.state_machine:setState("grounded")
end

function Player:setAirborneAnimation()
	self.current_animation = (self.y_velocity < 0) and self.animations.jump or self.animations.fall
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
			self.current_animation = self.animations.run
		end
	elseif self.state_machine:getState("grounded") then
		self.current_animation = self.animations.idle
	end

	local goal_x = self.x + dx

	self:move(goal_x, self.y)
end

function Player:attack()
	self.current_animation = self.animations.attack
	self.current_animation:gotoFrame(1)
	self.current_animation:resume()
	Sfx:play("player.attack")

	-- Hitbox
	local hitbox_width = 30
	local hitbox_height = 20

	local hixbox_x = (self.direction == -1) and self.x - hitbox_width or self.x + self.width
	self.hitbox = {
		is_hitbox = true,
		x = hixbox_x,
		y = self.y - hitbox_height,
		w = hitbox_width,
		h = self.height + hitbox_height,
	}
	self.world:add(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
end

function Player:updateHitbox()
	self.world:update(self.hitbox, self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h, hitboxFilter)
	local _, _, cols, len = self.world:check(self.hitbox, self.hitbox.x, self.hitbox.y, hitboxFilter)
	for i = 1, len do
		local other = cols[i].other
		if other.is_enemy then
			other:hit(self.atk)
		end
	end
end

function Player:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, playerFilter)

	for i = 1, len do
		local other = cols[i].other
		if other.is_coin then
			other:collect()
			self.coins = self.coins + 1
		end
	end

	self.x, self.y = actual_x, actual_y
end

function Player:applyGravity(dt)
	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_y = self.y + self.y_velocity * dt
	local _, actual_y, cols, len = self.world:check(self, self.x, goal_y, playerFilter)

	if len > 0 then
		self.y_velocity = 0
	else
		self:move(self.x, actual_y)
	end
end

function Player:update(dt)
	self:applyGravity(dt)
	self.state_machine:update(dt)
	self.current_animation:update(dt)
end

function Player:keypressed(key)
	self.state_machine:handleEvent("keypressed", key)
end

function Player:draw()
	-- Flip the sprite based on direction
	local scaleX = (self.direction == -1) and -1 or 1
	local offsetX = (self.direction == -1) and self.width or 0 -- Shift the sprite to the correct position when flipped

	love.graphics.push()

	-- Draw the current animation based on the last movement direction (flip horizontally when facing left)
	self.current_animation:draw(
		self.current_animation == self.animations.attack and self.attack_image
			or self.current_animation == self.animations.dead and self.dead_image
			or self.current_animation == self.animations.door_enter and self.door_enter_image
			or self.current_animation == self.animations.door_out and self.door_out_image
			or self.current_animation == self.animations.fall and self.fall_image
			or self.current_animation == self.animations.ground and self.ground_image
			or self.current_animation == self.animations.hit and self.hit_image
			or self.current_animation == self.animations.idle and self.idle_image
			or self.current_animation == self.animations.jump and self.jump_image
			or self.current_animation == self.animations.run and self.run_image
			or self.idle_image,
		self.x + offsetX, -- Adjust the x position when flipping
		self.y,
		0,
		scaleX, -- Flip horizontally when direction is left (-1)
		1,
		21,
		18
	)

	love.graphics.pop()
end

return player
