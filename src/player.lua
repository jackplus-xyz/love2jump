local anim8 = require("lib.anim8")
local keymaps = require("config.keymaps")
local stateMachine = require("src.utils.state_machine")
local sfx = require("src.sfx")

---@class player
local player = {}

-- class table
local Player = {}

local playerFilter = function(item, other)
	if other.is_coin then
		return "cross"
	elseif other.is_door then
		return "cross"
	elseif other.is_wall then
		return "slide"
	elseif other.is_exit then
		return "touch"
	elseif other.is_spring then
		return "bounce"
	else
		return "slide"
	end
	-- else return nil
end

function player.new(x, y)
	local self = {}
	setmetatable(self, { __index = Player })

	self.x = x
	self.y = y
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

	World:add(self, self.x - self.width / 2, self.y - self.height, self.width, self.height)

	self.current_animation = nil
	self.animations = {}
	self:loadAnimations()

	self.stateMachine = stateMachine.new()
	self:setupStates()

	return self
end

function Player:loadAnimations()
	local sprite_width = 78
	local sprite_height = 58

	-- Load images
	self.idle_image = love.graphics.newImage("/assets/sprites/01-king-human/idle.png")
	self.run_image = love.graphics.newImage("/assets/sprites/01-king-human/run.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/01-king-human/jump.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/01-king-human/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/01-king-human/ground.png")
	self.attack_image = love.graphics.newImage("/assets/sprites/01-king-human/attack.png")

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
		anim8.newGrid(sprite_width, sprite_height, self.ground_image:getWidth(), self.ground_image:getHeight(), 100)

	-- Create the animations
	self.animations.idle = anim8.newAnimation(idle_grid("1-11", 1), 0.1)
	self.animations.run = anim8.newAnimation(run_grid("1-8", 1), 0.1)
	self.animations.jump = anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.fall = anim8.newAnimation(fall_grid("1-1", 1), 0.1)
	self.animations.ground = anim8.newAnimation(ground_grid("1-1", 1), 0.1)
	self.animations.attack = anim8.newAnimation(attack_grid("1-3", 1), 0.1, function(anim)
		anim:pauseAtEnd()
	end)

	-- Set the initial animation to idle
	self.current_animation = self.animations.idle
end

function Player:setupStates()
	self.stateMachine:addState("grounded", {
		enter = function()
			self.currentAnimation = self.animations.idle
		end,
		update = function(_, dt)
			self:handleMovement(dt)

			if self.y_velocity ~= 0 then
				self.stateMachine:setState("airborne")
			end
		end,
		keypressed = function(_, key)
			if key == keymaps.jump and self.jump_cooldown <= 0 then
				self.y_velocity = self.jump_strength
				self.jump_cooldown = self.jump_cooldown_time
				self.stateMachine:setState("airborne")
			elseif key == keymaps.attack then
				self.stateMachine:setState("grounded.attacking")
			end
		end,
	})

	self.stateMachine:addState("grounded.attacking", {
		enter = function()
			self.currentAnimation = self.animations.attack
			self.currentAnimation:gotoFrame(1)
			self.currentAnimation:resume()
			sfx:play("player.attack")
		end,
		update = function(_)
			if self.currentAnimation.status == "paused" then
				self.stateMachine:setState("grounded")
			end
		end,
	})

	self.stateMachine:addState("airborne", {
		enter = function()
			self.currentAnimation = self.animations.jump
		end,
		update = function(_, dt)
			-- Handle airborne movement
			self:handleMovement(dt)

			-- FIXME:check is falling
			if self.y_velocity < -self.gravity then
				self.currentAnimation = self.animations.jump
			else
				self.currentAnimation = self.animations.fall
			end

			if self.y_velocity == 0 then
				self.currentAnimation = self.animations.ground
				self.stateMachine:setState("grounded")
			end
		end,
		keypressed = function(_, key)
			-- Handle potential airborne attack
			if key == keymaps.attack then
				self.stateMachine:setState("airborne.attacking")
			end
		end,
	})

	self.stateMachine:addState("airborne.attacking", {
		enter = function()
			self.currentAnimation = self.animations.attack
			self.currentAnimation:gotoFrame(1)
			self.currentAnimation:resume()
			sfx:play("player.attack")
		end,
		update = function(_, dt)
			self:handleMovement(dt) -- Update movement while attacking

			if self.currentAnimation.status == "paused" then
				if self.y_velocity == 0 then
					self.stateMachine:setState("grounded")
				else
					self.stateMachine:setState("airborne")
				end
			end
		end,
	})

	self.stateMachine:addState("entering", {
		enter = function()
			self.currentAnimation = self.animations.idle
			sfx:play("door")
		end,
	})

	-- Set default state
	self.stateMachine:setState("grounded")
end

function Player:handleMovement(dt)
	local direction = 0
	if love.keyboard.isDown(keymaps.left) then
		direction = -1
	end
	if love.keyboard.isDown(keymaps.right) then
		direction = 1
	end

	local dx = 0
	if direction ~= 0 then
		dx = self.speed * dt * direction
		self.direction = direction
		if self.stateMachine:getState("grounded") then
			self.currentAnimation = self.animations.run
		end
	elseif self.stateMachine:getState("grounded") then
		self.currentAnimation = self.animations.idle
	end

	local goal_x = self.x + dx

	self:move(goal_x, self.y)
end

function Player:move(goal_x, goal_y)
	local actual_x, actual_y, cols, len = World:move(self, goal_x, goal_y, playerFilter)

	self.x, self.y = actual_x, actual_y

	for i = 1, len do
		local col = cols[i]

		if col.normal.y < 0 then
			self.y_velocity = 0
		end
	end
end

function Player:update(dt)
	-- Update jump cooldown
	if self.jump_cooldown > 0 then
		self.jump_cooldown = self.jump_cooldown - dt
	end

	self.y_velocity = self.y_velocity + self.gravity * dt

	local goal_y = self.y + self.y_velocity * dt
	self:move(self.x, goal_y)

	self.stateMachine:update(dt)
	self.currentAnimation:update(dt)
end

function Player:keypressed(key)
	if key == keymaps.up then
		local actual_x, actual_y, cols, len = World:check(self, self.x, self.y, playerFilter)
		for i = 1, len do
			local other = cols[i].other
			if other.is_door then
				self.stateMachine:setState("entering")
				other:enter()
			end
		end
	else
		self.stateMachine:handleEvent("keypressed", key)
	end
end

function Player:draw()
	-- Flip the sprite based on direction
	local scaleX = (self.direction == -1) and -1 or 1
	local offsetX = (self.direction == -1) and self.width or 0 -- Shift the sprite to the correct position when flipped

	-- Draw the current animation based on the last movement direction (flip horizontally when facing left)
	self.currentAnimation:draw(
		self.currentAnimation == self.animations.idle and self.idle_image
			or self.currentAnimation == self.animations.run and self.run_image
			or self.currentAnimation == self.animations.jump and self.jump_image
			or self.currentAnimation == self.animations.fall and self.fall_image
			or self.currentAnimation == self.animations.ground and self.ground_image
			or self.attack_image,
		self.x + offsetX, -- Adjust the x position when flipping
		self.y,
		0,
		scaleX, -- Flip horizontally when direction is left (-1)
		1,
		21,
		18
	)

	-- Draw debugging box
	if IsDebug then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	end
end

return player
