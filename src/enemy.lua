local anim8 = require("lib.anim8")
local keymaps = require("config.keymaps")
local StateMachine = require("src.utils.state_machine")

---@class enemy
local enemy = {}

-- class table
local Enemy = {}

function enemy.new(x, y, world)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.x = x
	self.y = y
	self.width = 18
	self.height = 17
	self.speed = 150
	self.direction = 1
	self.y_velocity = 0
	self.jump_strength = -1300
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.gravity = 1000

	self.world = world
	self.world:add(self, self.x - self.width / 2, self.y - self.height, self.width, self.height)

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
	self.idle_image = love.graphics.newImage("/assets/sprites/03-pig/idle.png")
	self.run_image = love.graphics.newImage("/assets/sprites/03-pig/run.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/03-pig/jump.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/03-pig/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/03-pig/ground.png")
	self.attack_image = love.graphics.newImage("/assets/sprites/03-pig/attack.png")

	-- Create a grid for the animations
	local idle_grid =
		anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), self.idle_image:getHeight())
	local run_grid = anim8.newGrid(sprite_width, sprite_height, self.run_image:getWidth(), self.run_image:getHeight())
	local attack_grid =
		anim8.newGrid(sprite_width, sprite_height, self.attack_image:getWidth(), self.attack_image:getHeight())
	local jump_grid =
		anim8.newGrid(sprite_width, sprite_height, self.jump_image:getWidth(), self.jump_image:getHeight())
	local fall_grid =
		anim8.newGrid(sprite_width, sprite_height, self.fall_image:getWidth(), self.fall_image:getHeight())
	local ground_grid =
		anim8.newGrid(sprite_width, sprite_height, self.ground_image:getWidth(), self.ground_image:getHeight())

	-- Create the animations
	self.animations.idle = anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.run = anim8.newAnimation(run_grid("1-6", 1), 0.1)
	self.animations.jump = anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.fall = anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.attack = anim8.newAnimation(attack_grid("1-5", 1), 0.1, function(anim)
		anim:pauseAtEnd()
	end)

	-- Set the initial animation to idle
	self.current_animation = self.animations.idle
end

function Enemy:setupStates()
	self.stateMachine:addState("grounded", {
		enter = function()
			self.currentAnimation = self.animations.idle
		end,
		update = function(_, dt)
			-- self:handleMovement(dt)
			--
			-- if self.y_velocity ~= 0 then
			-- 	self.stateMachine:setState("airborne")
			-- end
		end,
		keypressed = function(_, key)
			-- if key == keymaps.jump and self.jump_cooldown <= 0 then
			-- 	self.y_velocity = self.jump_strength
			-- 	self.jump_cooldown = self.jump_cooldown_time
			-- 	self.stateMachine:setState("airborne")
			-- elseif key == keymaps.attack then
			-- 	self.stateMachine:setState("grounded.attacking")
			-- end
		end,
	})
	--
	-- self.stateMachine:addState("grounded.attacking", {
	-- 	enter = function()
	-- 		self.currentAnimation = self.animations.attack
	-- 		self.currentAnimation:gotoFrame(1)
	-- 		self.currentAnimation:resume()
	-- 	end,
	-- 	update = function(_)
	-- 		if self.currentAnimation.status == "paused" then
	-- 			self.stateMachine:setState("grounded")
	-- 		end
	-- 	end,
	-- })
	--
	-- self.stateMachine:addState("airborne", {
	-- 	enter = function()
	-- 		self.currentAnimation = self.animations.jump
	-- 	end,
	-- 	update = function(_, dt)
	-- 		-- Handle airborne movement
	-- 		self:handleMovement(dt)
	--
	-- 		if self.y_velocity < -self.gravity then
	-- 			self.currentAnimation = self.animations.jump
	-- 		else
	-- 			self.currentAnimation = self.animations.fall
	-- 		end
	--
	-- 		if self.y_velocity >= 0 then
	-- 			self.currentAnimation = self.animations.ground
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
	-- 		self.currentAnimation = self.animations.attack
	-- 		self.currentAnimation:gotoFrame(1)
	-- 		self.currentAnimation:resume()
	-- 	end,
	-- 	update = function(_, dt)
	-- 		self:handleMovement(dt) -- Update movement while attacking
	--
	-- 		if self.currentAnimation.status == "paused" then
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

function Enemy:getMovementDirection()
	local direction = 0
	if love.keyboard.isDown(keymaps.left) then
		direction = -1
	end
	if love.keyboard.isDown(keymaps.right) then
		direction = 1
	end
	return direction
end

function Enemy:handleMovement(dt)
	local dx = 0
	local direction = self:getMovementDirection()

	if direction ~= 0 then
		dx = self.speed * dt * direction
		self.direction = direction
		if self.stateMachine:getState("grounded") then
			self.currentAnimation = self.animations.run
		end
	elseif self.stateMachine:getState("grounded") then
		self.currentAnimation = self.animations.idle
	end

	local dy = self.y_velocity * dt + self.gravity * dt

	local goalX = self.x + dx
	local goalY = self.y + dy

	self:move(goalX, goalY)
end

function Enemy:move(goalX, goalY)
	local actualX, actualY, cols, len = self.world:move(self, goalX, goalY)

	self.x, self.y = actualX, actualY

	for i = 1, len do
		local col = cols[i]
		if col.normal.y < 0 then
			self.y_velocity = 0
		end
	end
end

function Enemy:update(dt)
	-- Update jump cooldown
	-- if self.jump_cooldown > 0 then
	-- 	self.jump_cooldown = self.jump_cooldown - dt
	-- end
	--
	-- if self.y_velocity <= 0 then
	-- 	self.y_velocity = self.y_velocity + self.gravity * dt
	-- end

	self.stateMachine:update(dt)
	self.currentAnimation:update(dt)
end

function Enemy:keypressed(key)
	self.stateMachine:handleEvent("keypressed", key)
end

function Enemy:draw()
	-- Flip the sprite based on direction
	local scaleX = (self.direction == -1) and -1 or 1
	local offsetX = (self.direction == -1) and self.width or 0 -- Shift the sprite to the correct position when flipped

	-- TODO: add offset
	-- Draw the current animation based on the last movement direction (flip horizontally when facing left)
	self.currentAnimation:draw(
		-- self.currentAnimation == self.animations.idle and self.idle_image
		-- 	or self.currentAnimation == self.animations.run and self.run_image
		-- 	or self.currentAnimation == self.animations.jump and self.jump_image
		-- 	or self.currentAnimation == self.animations.fall and self.fall_image
		-- 	or self.currentAnimation == self.animations.ground and self.ground_image
		-- 	or self.attack_image,
		self.idle_image,
		self.x + offsetX, -- Adjust the x position when flipping
		self.y,
		0,
		scaleX, -- Flip horizontally when direction is left (-1)
		1,
		self.width,
		28
	)

	-- Draw debugging box
	if IsDebug then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	end
end

return enemy
