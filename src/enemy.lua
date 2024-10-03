local anim8 = require("lib.anim8")
local StateMachine = require("src.utils.state_machine")

---@class enemy
local enemy = {}

-- class table
local Enemy = {}

function enemy.new(x, y, patrol)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.x = x
	self.y = y
	self.width = 18
	self.height = 17
	self.speed = 50
	self.direction = 1
	self.y_velocity = 0
	self.jump_strength = -1300
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.gravity = 1000

	self.patrol = patrol
	self.currentPatrolIndex = 1
	self.patrolDirection = 1

	World:add(self, self.x - self.width / 2, self.y - self.height, self.width, self.height)

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
	self.stateMachine:addState("grounded", {
		enter = function()
			self.current_animation = self.animations.idle
		end,
		update = function(_, dt)
			self:handleMovement(dt)

			if self.y_velocity ~= 0 then
				self.stateMachine:setState("airborne")
			end
		end,
	})
	--
	-- self.stateMachine:addState("grounded.attacking", {
	-- 	enter = function()
	-- 		self.current_animation = self.animations.attack
	-- 		self.current_animation:gotoFrame(1)
	-- 		self.current_animation:resume()
	-- 	end,
	-- 	update = function(_)
	-- 		if self.current_animation.status == "paused" then
	-- 			self.stateMachine:setState("grounded")
	-- 		end
	-- 	end,
	-- })
	--
	-- self.stateMachine:addState("airborne", {
	-- 	enter = function()
	-- 		self.current_animation = self.animations.jump
	-- 	end,
	-- 	update = function(_, dt)
	-- 		-- Handle airborne movement
	-- 		self:handleMovement(dt)
	--
	-- 		if self.y_velocity < -self.gravity then
	-- 			self.current_animation = self.animations.jump
	-- 		else
	-- 			self.current_animation = self.animations.fall
	-- 		end
	--
	-- 		if self.y_velocity >= 0 then
	-- 			self.current_animation = self.animations.ground
	-- 			self.stateMachine:setState("grounded")
	-- 		end
	-- 	end,
	-- 	keypressed = function(_, key)
	-- 		-- Handle potential airborne attack
	-- 		if key == keymaps.attack then
	-- 			self.stateMachine:setState("airborne.attacking")
	-- 		end
	-- 	end,
	-- })
	--
	-- self.stateMachine:addState("airborne.attacking", {
	-- 	enter = function()
	-- 		self.current_animation = self.animations.attack
	-- 		self.current_animation:gotoFrame(1)
	-- 		self.current_animation:resume()
	-- 	end,
	-- 	update = function(_, dt)
	-- 		self:handleMovement(dt) -- Update movement while attacking
	--
	-- 		if self.current_animation.status == "paused" then
	-- 			if self.y_velocity == 0 then
	-- 				self.stateMachine:setState("grounded")
	-- 			else
	-- 				self.stateMachine:setState("airborne")
	-- 			end
	-- 		end
	-- 	end,
	-- })

	-- Set default state
	self.stateMachine:setState("grounded")
end

function Enemy:handleMovement(dt)
	local dx = 0
	-- local direction = self:getMovementDirection()
	--
	-- if direction ~= 0 then
	-- 	dx = self.speed * dt * direction
	-- 	self.direction = direction
	-- 	if self.stateMachine:getState("grounded") then
	-- 		self.current_animation = self.animations.run
	-- 	end
	-- elseif self.stateMachine:getState("grounded") then
	-- 	self.current_animation = self.animations.idle
	-- end

	local dy = self.y_velocity * dt + self.gravity * dt

	local goalX = self.x + dx
	local goalY = self.y + dy

	self:move(goalX, goalY)
end

function Enemy:move(goalX, goalY)
	local actualX, actualY, cols, len = World:move(self, goalX, goalY)

	self.x, self.y = actualX, actualY

	for i = 1, len do
		local col = cols[i]
		if col.normal.y < 0 then
			self.y_velocity = 0
		end
	end
end

-- TODO: improve patrol logic
function Enemy:update(dt)
	if self.patrol[self.currentPatrolIndex] then
		-- Handle patrolling behavior
		local current_patrol_point = self.patrol[self.currentPatrolIndex]
		local goal_x, goal_y = current_patrol_point.cx, current_patrol_point.cy

		local dx = goal_x - self.x
		local dy = goal_y - self.y
		local distance = math.sqrt(dx * dx + dy * dy)

		if distance < 1 then -- If close enough to the current patrol point
			-- Move to the next patrol point
			self.currentPatrolIndex = self.currentPatrolIndex + self.patrolDirection

			-- If we've reached the end of the patrol route, reverse direction
			if self.currentPatrolIndex > #self.patrol or self.currentPatrolIndex < 1 then
				self.patrolDirection = -self.patrolDirection
				self.currentPatrolIndex = self.currentPatrolIndex + self.patrolDirection
			end
		else
			-- Move towards the current patrol point
			local moveX = (dx / distance) * self.speed * dt
			local moveY = (dy / distance) * self.speed * dt
			self:move(self.x + moveX, self.y + moveY)
		end
	end

	self.stateMachine:update(dt)
	self.current_animation:update(dt)
end

function Enemy:draw()
	-- Flip the sprite based on direction
	local scaleX = (self.direction == -1) and -1 or 1
	local offsetX = (self.direction == -1) and self.width or 0 -- Shift the sprite to the correct position when flipped

	-- TODO: add offset
	-- Draw the current animation based on the last movement direction (flip horizontally when facing left)
	self.current_animation:draw(
		self.current_animation == self.animations.idle and self.idle_image
			or self.current_animation == self.animations.run and self.run_image
			or self.current_animation == self.animations.jump and self.jump_image
			or self.current_animation == self.animations.fall and self.fall_image
			or self.current_animation == self.animations.ground and self.ground_image
			or self.attack_image,
		self.x + offsetX, -- Adjust the x position when flipping
		self.y,
		0,
		scaleX, -- Flip horizontally when direction is left (-1)
		1,
		self.width,
		10
	)

	-- Draw debugging box
	if IsDebug then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	end
end

return enemy
