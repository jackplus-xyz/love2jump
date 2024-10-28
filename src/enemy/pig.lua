local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local Enemy = require("src.enemy.enemy")

local Pig = {}
Pig.__index = Pig
setmetatable(Pig, Enemy)

function Pig.new(entity, world)
	local self = Enemy.new(entity, world)
	setmetatable(self, Pig)

	self.patrol = entity.props.patrol

	self.w = 18
	self.h = 17
	self.speed = 100
	self.knock_back_offset = 15
	self.direction = 0
	self.y_velocity = 0
	self.jump_strength = -1300
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.hit_cooldown = 0
	self.hit_cooldown_time = 0.2
	self.gravity = 1000

	self:init()
	return self
end

function Pig:init()
	self:loadAnimations()
	self:setupStates()
end

function Pig:loadAnimations()
	local sprite_w = 34
	local sprite_h = 28

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
	local attack_grid = Anim8.newGrid(sprite_w, sprite_h, self.attack_image:getWidth(), sprite_h)
	local dead_grid = Anim8.newGrid(sprite_w, sprite_h, self.dead_image:getWidth(), sprite_h)
	local fall_grid = Anim8.newGrid(sprite_w, sprite_h, self.fall_image:getWidth(), sprite_h)
	local ground_grid = Anim8.newGrid(sprite_w, sprite_h, self.ground_image:getWidth(), sprite_h)
	local hit_grid = Anim8.newGrid(sprite_w, sprite_h, self.hit_image:getWidth(), sprite_h)
	local idle_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_image:getWidth(), sprite_h)
	local jump_grid = Anim8.newGrid(sprite_w, sprite_h, self.jump_image:getWidth(), sprite_h)
	local run_grid = Anim8.newGrid(sprite_w, sprite_h, self.run_image:getWidth(), sprite_h)

	-- Create the animations
	self.animations.attack = Anim8.newAnimation(attack_grid("1-5", 1), 0.1, "pauseAtEnd")
	self.animations.dead = Anim8.newAnimation(dead_grid("1-4", 1), 0.1, "pauseAtEnd")
	self.animations.fall = Anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = Anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.hit = Anim8.newAnimation(hit_grid("1-2", 1), 0.1)
	self.animations.idle = Anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.jump = Anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = Anim8.newAnimation(run_grid("1-6", 1), 0.1)

	self.image_map = {
		[self.animations.idle] = self.idle_image,
		[self.animations.run] = self.run_image,
		[self.animations.jump] = self.jump_image,
		[self.animations.fall] = self.fall_image,
		[self.animations.ground] = self.ground_image,
		[self.animations.hit] = self.hit_image,
		[self.animations.dead] = self.dead_image,
	}

	-- Set the initial animation to idle
	self.curr_animation = self.animations.idle
end

function Pig:setupStates()
	local start_x, start_y = self.x, self.y

	self.state_machine:addState("grounded", {
		enter = function()
			self.curr_animation = self.animations.idle
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
				self.curr_animation = self.animations.run
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
				self.curr_animation = self.animations.idle
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
				self.curr_animation = self.animations.run
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
				self.curr_animation = self.animations.idle
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
				self.curr_animation = self.animations.ground
				self.state_machine:setState(self.state_machine.prevState.name)
			end
		end,
	})

	self.state_machine:addState("hit", {
		enter = function()
			self.curr_animation = self.animations.hit
			Sfx:play("enemy.hit")
			self:applyKnockback(self.knock_back_offset)
		end,
		update = function(_, dt)
			if self.hit_cooldown > 0 then
				self.hit_cooldown = self.hit_cooldown - dt
			end

			if self.hit_cooldown <= 0 then
				if self.health <= 0 then
					self.state_machine:setState("dead")
				else
					self.state_machine:setState("grounded")
				end
				self.hit_cooldown = self.hit_cooldown_time
			end
		end,
	})

	self.state_machine:addState("dead", {
		enter = function()
			self.curr_animation = self.animations.dead
			Sfx:play("enemy.dead")
		end,
		update = function(_, dt)
			if self.curr_animation and self.curr_animation.status == "paused" then
				self.world:remove(self)
				self.is_active = false
				self.curr_animation = nil
			end
		end,
	})

	-- Set default state
	self.state_machine:setState("grounded")
end

-- TODO: improve patrol logic to check if target is reachable
function Pig:isPathTo(goal_x, goal_y)
	local actual_x, actual_y, cols, len = self.world:check(self, goal_x, goal_y, self.enemy_filter)
	if self.y == goal_y and len == 0 then
		return true
	end
	return false
end

function Pig:draw()
	-- Flip the sprite based on direction (enemy sprites face opposite direction from the player)
	local scale_x = (self.direction == -1) and 1 or -1
	local offset_x = (self.direction == -1) and 0 or self.w
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	love.graphics.push()

	-- TODO: add animation offset across enemy
	if self.curr_animation then
		self.curr_animation:draw(curr_image, self.x + offset_x, self.y, 0, scale_x, 1, self.w / SCALE, 10)
	end

	love.graphics.pop()
end

return Pig
