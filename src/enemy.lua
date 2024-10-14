local Anim8 = require("lib.anim8.anim8")
local StateMachine = require("src.utils.state_machine")

---@class enemy
local enemy = {}

-- class table
local Enemy = {}

function enemy.new(x, y, props, world)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.x = x
	self.y = y
	self.world = world
	self.patrol = props.patrol
	self.health = 3
	self.is_enemy = true

	self.w = 18
	self.h = 17
	self.speed = 100
	self.direction = 0
	self.y_velocity = 0
	self.jump_strength = -1300
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.gravity = 1000

	self.current_animation = nil
	self.animations = {}
	self:loadAnimations()

	self.state_machine = StateMachine.new()
	self:setupStates()

	return self
end

function Enemy:loadAnimations()
	local sprite_width = 34
	local sprite_height = 28

	-- Load images
	self.attack_image = love.graphics.newImage("/assets/sprites/03-pig/attack.png")
	self.dead_image = love.graphics.newImage("/assets/sprites/03-pig/dead.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/03-pig/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/03-pig/ground.png")
	self.hit_image = love.graphics.newImage("/assets/sprites/03-pig/hit.png")
	self.idle_image = love.graphics.newImage("/assets/sprites/03-pig/idle.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/03-pig/jump.png")
	self.run_image = love.graphics.newImage("/assets/sprites/03-pig/run.png")

	-- Create a grid for the animations
	local attack_grid = Anim8.newGrid(sprite_width, sprite_height, self.attack_image:getWidth(), sprite_height)
	local dead_grid = Anim8.newGrid(sprite_width, sprite_height, self.dead_image:getWidth(), sprite_height)
	local fall_grid = Anim8.newGrid(sprite_width, sprite_height, self.fall_image:getWidth(), sprite_height)
	local ground_grid = Anim8.newGrid(sprite_width, sprite_height, self.ground_image:getWidth(), sprite_height)
	local hit_grid = Anim8.newGrid(sprite_width, sprite_height, self.hit_image:getWidth(), sprite_height)
	local idle_grid = Anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	local jump_grid = Anim8.newGrid(sprite_width, sprite_height, self.jump_image:getWidth(), sprite_height)
	local run_grid = Anim8.newGrid(sprite_width, sprite_height, self.run_image:getWidth(), sprite_height)

	-- Create the animations
	self.animations.attack = Anim8.newAnimation(attack_grid("1-5", 1), 0.1, "pauseAtEnd")
	self.animations.dead = Anim8.newAnimation(dead_grid("1-4", 1), 0.1, "pauseAtEnd")
	self.animations.fall = Anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = Anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.hit = Anim8.newAnimation(hit_grid("1-2", 1), 0.1)
	self.animations.idle = Anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.jump = Anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = Anim8.newAnimation(run_grid("1-6", 1), 0.1)

	-- Set the initial animation to idle
	self.current_animation = self.animations.idle
end

function Enemy:setupStates()
	local start_x, start_y = self.x, self.y

	self.state_machine:addState("grounded", {
		enter = function()
			self.current_animation = self.animations.idle
		end,
		update = function(_, dt)
			if self.y_velocity ~= 0 then
				self.state_machine:setState("airborne")
			end

			if self.patrol then
				self.state_machine:setState("grounded.to_target")
			end
		end,
	})

	if self.patrol then
		local wait_time = 2
		local wait_timer = wait_time
		local target_x, target_y =
			self.patrol.cx * GRID_SIZE / SCALE + GRID_SIZE / SCALE / SCALE,
			self.patrol.cy * GRID_SIZE / SCALE + GRID_SIZE / SCALE

		self.state_machine:addState("grounded.to_target", {
			enter = function()
				self.current_animation = self.animations.run
			end,
			update = function(_, dt)
				if self.y_velocity ~= 0 then
					self.state_machine:setState("airborne")
				end

				local dx = target_x - self.x
				local dy = target_y - self.y
				local distance = math.sqrt(dx * dx + dy * dy)

				if distance < GRID_SIZE then
					self.state_machine:setState("grounded.at_target")
				else
					local goal_x = self.x + (dx / distance) * self.speed * dt
					local goal_y = self.y + (dy / distance) * self.speed * dt
					self:move(goal_x, goal_y)
				end
			end,
		})

		self.state_machine:addState("grounded.at_target", {
			enter = function()
				self.current_animation = self.animations.idle
			end,
			update = function(_, dt)
				wait_timer = wait_timer - dt

				if wait_timer <= 0 then
					wait_timer = wait_time
					self.state_machine:setState("grounded.to_start")
				end
			end,
		})

		self.state_machine:addState("grounded.to_start", {
			enter = function()
				self.current_animation = self.animations.run
			end,
			update = function(_, dt)
				if self.y_velocity ~= 0 then
					self.state_machine:setState("airborne")
				end

				local dx = start_x - self.x
				local dy = start_y - self.y
				local distance = math.sqrt(dx * dx + dy * dy)

				if distance < GRID_SIZE then
					self.state_machine:setState("grounded.at_start")
				else
					local move_x = (dx / distance) * self.speed * dt
					local move_y = (dy / distance) * self.speed * dt
					self:move(self.x + move_x, self.y + move_y)
				end
			end,
		})

		self.state_machine:addState("grounded.at_start", {
			enter = function()
				self.current_animation = self.animations.idle
			end,
			update = function(_, dt)
				wait_timer = wait_timer - dt

				if wait_timer <= 0 then
					wait_timer = wait_time
					self.state_machine:setState("grounded.to_target")
				end
			end,
		})
	end

	self.state_machine:addState("airborne", {
		enter = function()
			self:setAirborneAnimation()
		end,
		update = function(_, dt)
			self:setAirborneAnimation()

			if self.y_velocity == 0 then
				self.current_animation = self.animations.ground
				self.state_machine:setState(self.state_machine.prevState.name)
			end
		end,
	})

	self.state_machine:addState("hit", {
		enter = function()
			self.current_animation = self.animations.hit
			-- TODO: add hit sfx
		end,
		update = function(_, dt)
			if self.health <= 0 then
				self.state_machine:setState("dead")
			else
				self.state_machine:setState("grounded")
			end
		end,
	})

	self.state_machine:addState("dead", {
		enter = function()
			self.current_animation = self.animations.dead
			-- TODO: add dead sfx
		end,
		update = function(_, dt)
			if self.current_animation and self.current_animation.status == "paused" then
				self.world:remove(self)
				self.current_animation = nil
			end
		end,
	})

	-- Set default state
	self.state_machine:setState("grounded")
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

-- TODO: improve patrol logic to check if target is reachable
function Enemy:isPathTo(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:check(self, goal_x, goal_y)
	if self.y == goal_y and len == 0 then
		return true
	end
	return false
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

function Enemy:draw()
	-- Flip the sprite based on direction
	local scale_x = (self.direction == -1) and 1 or -1
	local offset_x = (self.direction == -1) and 0 or self.w -- Shift the sprite to the correct position when flipped

	love.graphics.push()

	-- TODO: add animation offset across enemy
	if self.current_animation then
		self.current_animation:draw(
			self.current_animation == self.animations.idle and self.idle_image
				or self.current_animation == self.animations.run and self.run_image
				or self.current_animation == self.animations.jump and self.jump_image
				or self.current_animation == self.animations.fall and self.fall_image
				or self.current_animation == self.animations.ground and self.ground_image
				or self.current_animation == self.animations.hit and self.hit_image
				or self.current_animation == self.animations.dead and self.dead_image
				or self.idle_image,
			self.x + offset_x, -- Adjust the x position when flipping
			self.y,
			0,
			scale_x, -- Flip horizontally when direction is left (-1)
			1,
			self.w / SCALE,
			10
		)
	end

	love.graphics.pop()
end

return enemy
