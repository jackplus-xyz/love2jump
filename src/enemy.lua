local anim8 = require("lib.anim8.anim8")
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

	self.width = 18
	self.height = 17
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

	self.stateMachine = StateMachine.new()
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
	local attack_grid = anim8.newGrid(sprite_width, sprite_height, self.attack_image:getWidth(), sprite_height)
	local dead_grid = anim8.newGrid(sprite_width, sprite_height, self.dead_image:getWidth(), sprite_height)
	local fall_grid = anim8.newGrid(sprite_width, sprite_height, self.fall_image:getWidth(), sprite_height)
	local ground_grid = anim8.newGrid(sprite_width, sprite_height, self.ground_image:getWidth(), sprite_height)
	local hit_grid = anim8.newGrid(sprite_width, sprite_height, self.hit_image:getWidth(), sprite_height)
	local idle_grid = anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	local jump_grid = anim8.newGrid(sprite_width, sprite_height, self.jump_image:getWidth(), sprite_height)
	local run_grid = anim8.newGrid(sprite_width, sprite_height, self.run_image:getWidth(), sprite_height)

	-- Create the animations
	self.animations.attack = anim8.newAnimation(attack_grid("1-5", 1), 0.1, function(anim)
		anim:pauseAtEnd()
	end)
	self.animations.dead = anim8.newAnimation(dead_grid("1-4", 1), 0.1)
	self.animations.fall = anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.hit = anim8.newAnimation(hit_grid("1-2", 1), 0.1)
	self.animations.idle = anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.jump = anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = anim8.newAnimation(run_grid("1-6", 1), 0.1)

	-- Set the initial animation to idle
	self.current_animation = self.animations.idle
end

function Enemy:setupStates()
	local start_x, start_y = self.x, self.y

	self.stateMachine:addState("grounded", {
		enter = function()
			self.current_animation = self.animations.idle
		end,
		update = function(_, dt)
			if self.y_velocity ~= 0 then
				self.stateMachine:setState("airborne")
			end

			if self.patrol then
				self.stateMachine:setState("grounded.to_target")
			end
		end,
	})

	if self.patrol then
		local wait_time = 2
		local wait_timer = wait_time
		local target_x, target_y =
			self.patrol.cx * GRID_SIZE / SCALE + GRID_SIZE / SCALE / SCALE,
			self.patrol.cy * GRID_SIZE / SCALE + GRID_SIZE / SCALE

		self.stateMachine:addState("grounded.to_target", {
			enter = function()
				self.current_animation = self.animations.run
			end,
			update = function(_, dt)
				if self.y_velocity ~= 0 then
					self.stateMachine:setState("airborne")
				end

				local dx = target_x - self.x
				local dy = target_y - self.y
				local distance = math.sqrt(dx * dx + dy * dy)

				if distance < GRID_SIZE then
					self.stateMachine:setState("grounded.at_target")
				else
					local goal_x = self.x + (dx / distance) * self.speed * dt
					local goal_y = self.y + (dy / distance) * self.speed * dt
					self:move(goal_x, goal_y)
				end
			end,
		})

		self.stateMachine:addState("grounded.at_target", {
			enter = function()
				self.current_animation = self.animations.idle
			end,
			update = function(_, dt)
				wait_timer = wait_timer - dt

				if wait_timer <= 0 then
					wait_timer = wait_time
					self.stateMachine:setState("grounded.to_start")
				end
			end,
		})

		self.stateMachine:addState("grounded.to_start", {
			enter = function()
				self.current_animation = self.animations.run
			end,
			update = function(_, dt)
				if self.y_velocity ~= 0 then
					self.stateMachine:setState("airborne")
				end

				local dx = start_x - self.x
				local dy = start_y - self.y
				local distance = math.sqrt(dx * dx + dy * dy)

				if distance < GRID_SIZE then
					self.stateMachine:setState("grounded.at_start")
				else
					local move_x = (dx / distance) * self.speed * dt
					local move_y = (dy / distance) * self.speed * dt
					self:move(self.x + move_x, self.y + move_y)
				end
			end,
		})

		self.stateMachine:addState("grounded.at_start", {
			enter = function()
				self.current_animation = self.animations.idle
			end,
			update = function(_, dt)
				wait_timer = wait_timer - dt

				if wait_timer <= 0 then
					wait_timer = wait_time
					self.stateMachine:setState("grounded.to_target")
				end
			end,
		})
	end

	self.stateMachine:addState("airborne", {
		enter = function()
			self:setAirborneAnimation()
		end,
		update = function(_, dt)
			self:setAirborneAnimation()

			if self.y_velocity == 0 then
				self.current_animation = self.animations.ground
				self.stateMachine:setState(self.stateMachine.prevState.name)
			end
		end,
	})

	-- Set default state
	self.stateMachine:setState("grounded")
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
	self:applyGravity(dt)
	self.stateMachine:update(dt)
	self.current_animation:update(dt)
end

function Enemy:draw()
	-- Flip the sprite based on direction
	local scale_x = (self.direction == -1) and 1 or -1
	local offset_x = (self.direction == -1) and 0 or self.width -- Shift the sprite to the correct position when flipped

	love.graphics.push()

	-- TODO: add animation offset across enemy
	self.current_animation:draw(
		self.current_animation == self.animations.idle and self.idle_image
			or self.current_animation == self.animations.run and self.run_image
			or self.current_animation == self.animations.jump and self.jump_image
			or self.current_animation == self.animations.fall and self.fall_image
			or self.current_animation == self.animations.ground and self.ground_image
			or self.attack_image,
		self.x + offset_x, -- Adjust the x position when flipping
		self.y,
		0,
		scale_x, -- Flip horizontally when direction is left (-1)
		1,
		self.width / SCALE,
		10
	)

	-- Draw debugging box
	if IsDebug then
		local world_x, world_y, world_width, world_height = self.world:getRect(self)

		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", world_x, world_y, world_width, world_height)
	end

	love.graphics.pop()
end

return enemy
