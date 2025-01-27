local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local BaseEnemy = require("src.enemy.base_enemy")
local EntityFactory = require("src.entity.entity_factory")

local Pig = {}
Pig.__index = Pig
setmetatable(Pig, BaseEnemy)

function Pig.new(entity)
	local self = BaseEnemy.new(entity)
	setmetatable(self, Pig)

	if entity.props then
		self.props = entity.props
		if entity.props.patrol then
			self.target_x, self.target_y =
				entity.props.patrol.cx * GRID_SIZE / SCALE + GRID_SIZE / SCALE / SCALE,
				entity.props.patrol.cy * GRID_SIZE / SCALE + GRID_SIZE / SCALE
		end
	end

	-- Initialize Patrol Path
	self.start_x, self.start_y = self.x, self.y
	self.w = 15
	self.h = 17

	self.knock_back_offset = 15
	self.speed = 100
	self.velocity_y = 0
	self.gravity = 1000
	self.jump_strength = -320
	self.jump_attempt = 1
	self.max_jump_attempts = 1
	self.hitbox_w = 12
	self.hitbox_h = 10

	-- Timers
	self.pause_time = 2
	self.pause_timer = self.pause_time
	self.chase_attempt_time = 2
	self.chase_attempt_timer = self.chase_attempt_time
	self.jump_cooldown = 0
	self.jump_cooldown_time = 0.1
	self.attack_cooldown = 0
	self.attack_cooldown_time = 2
	self.hit_cooldown = 0
	self.hit_cooldown_time = 0.4
	self.drop_cooldown = 0
	self.drop_cooldown_time = 0.1
	self.chase_cooldown = 0
	self.chase_cooldown_time = 10
	self.dialogue_timer = 0
	self.dialogue_time = 0.5

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
		[self.animations.attack] = self.attack_image,
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
	self.state_machine:addState("grounded.idle", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			if self.target_x and self.target_y then
				if not self:isAtTarget(self.target_x, self.target_y) then
					self.state_machine:setState("grounded.to_target")
				end
			end
		end,
	})

	self.state_machine:addState("grounded.attacking", {
		enter = function()
			Sfx:play("pig.attack")
			self:attack()
			self.attack_cooldown = self.attack_cooldown_time
		end,
		update = function(_, dt)
			self.attack_cooldown = self.attack_cooldown - dt

			if self.hitbox.is_active then
				self.hitbox:update()
			end

			if self.curr_animation.status == "paused" then
				self.curr_animation = self.animations.idle
			end

			if self.attack_cooldown <= 0 then
				self.state_machine:setState("grounded.idle")
			end
		end,
	})

	self.state_machine:addState("grounded.to_target", {
		enter = function()
			self.curr_animation = self.animations.run
		end,
		update = function(_, dt)
			self:checkAirborne()

			if self:isAtTarget(self.target_x, self.target_y) then
				self.state_machine:setState("grounded.at_target")
			else
				if self:canJumpToTarget() and self.jump_attempt <= self.max_jump_attempts then
					self:jump()
					self.jump_attempt = self.jump_attempt + 1
					self.state_machine:setState("airborne.to_target")
				else
					-- Fallback to `grounded.at_target` after a certain time(can't reach the point)
					self.chase_attempt_timer = self.chase_attempt_timer - dt
					if self.chase_attempt_timer <= 0 then
						self.state_machine:setState("grounded.at_target")
					end
					local direction = self.target_x > self.x and 1 or -1
					local goal_x = self.x + self.speed * dt * direction
					self:move(goal_x, self.y)
				end
			end
		end,
	})

	self.state_machine:addState("grounded.at_target", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			self.pause_timer = self.pause_timer - dt

			if self:isPlayerInAttackRange() then
				self.state_machine:setState("grounded.attacking")
			end

			if self.pause_timer <= 0 then
				self.pause_timer = self.pause_time
				self.state_machine:setState("grounded.to_start")
			end
		end,
	})

	self.state_machine:addState("grounded.to_start", {
		enter = function()
			self.curr_animation = self.animations.run
		end,
		update = function(_, dt)
			self:checkAirborne()

			if self:isAtTarget(self.start_x, self.start_y) then
				self.state_machine:setState("grounded.at_start")
			else
				local direction = self.start_x > self.x and 1 or -1
				local goal_x = self.x + self.speed * dt * direction
				self:move(goal_x, self.y)
			end
		end,
	})

	self.state_machine:addState("grounded.at_start", {
		enter = function()
			self.curr_animation = self.animations.idle
			self.jump_attempt = 1
		end,
		update = function(_, dt)
			self.pause_timer = self.pause_timer - dt

			if self.pause_timer <= 0 then
				self.pause_timer = self.pause_time
				self.state_machine:setState("grounded.to_target")
			end
		end,
	})

	self.state_machine:addState("airborne", {
		enter = function()
			self:setAirborneAnimation()
		end,
		update = function(_, dt)
			self:setAirborneAnimation()

			if self.velocity_y == 0 then
				self.curr_animation = self.animations.ground
				self.state_machine:setState(self.state_machine.prevState.name)
			end
		end,
	})

	self.state_machine:addState("airborne.to_target", {
		enter = function()
			self:setAirborneAnimation()
			-- TODO: add condition to reset jump_attempt
		end,
		update = function(_, dt)
			self:setAirborneAnimation()

			local goal_x = self.x + self.speed * dt * self.direction
			local goal_y = self.y + self.h + self.velocity_y * dt
			local jumpFilter = function(item)
				return item.id == "Collision"
			end
			local items, len = self.world:queryPoint(goal_x, goal_y, jumpFilter)

			if self.velocity_y == 0 then
				self.curr_animation = self.animations.ground
				self.state_machine:setState(self.state_machine.prevState.name)
			else
				self:move(goal_x, self.y)
			end
		end,
	})

	-- TODO: draw shock dialogue
	self.state_machine:addState("hit", {
		enter = function()
			self.curr_animation = self.animations.hit
			self.hit_cooldown = self.hit_cooldown_time
			Sfx:play("pig.hit")
		end,
		update = function(_, dt)
			if self.hit_cooldown > 0 then
				self.hit_cooldown = self.hit_cooldown - dt
			else
				self.state_machine:setState("grounded.idle")
				self.hit_cooldown = self.hit_cooldown_time
			end
		end,
	})

	self.state_machine:addState("dead", {
		enter = function()
			self.curr_animation = self.animations.dead
			Sfx:play("pig.dead")
			self.dialogue:hide("shock")
			self.drop_timer = 0.2
			self.drop_interval = 0.2
			self.dead_timer = 0.2 -- make the body stay for while
			self.current_drop_index = 1 -- Track which loot we're currently dropping
			self.world:remove(self)
			if self.removeFromSummoned then
				self.removeFromSummoned(self.summoned_index)
			end
		end,
		update = function(_, dt)
			-- wait for death animation to complete
			self.curr_animation:update(dt)

			if self.props.Loot and self.current_drop_index <= #self.props.Loot then
				if self.drop_timer > 0 then
					self.drop_timer = self.drop_timer - dt
				else
					local loot = self.props.Loot[self.current_drop_index]
					local loot_entity = {
						id = loot,
						x = self.x + self.w / 2,
						y = self.y,
						world = self.world,
					}
					local new_loot = EntityFactory.create(loot_entity)
					self:dropItem(new_loot, self.speed)

					self.current_drop_index = self.current_drop_index + 1
					self.drop_timer = self.drop_interval -- Reset timer for next drop
				end
			-- remove the entity after all the loots are dropped
			elseif self.curr_animation.status == "paused" then
				if self.dead_timer > 0 then
					self.dead_timer = self.dead_timer - dt
				else
					self:removeFromWorld()
				end
			end
		end,
	})

	-- Set default state
	self.state_machine:setState("grounded.idle")
end

function Pig:update(dt)
	if not self.is_active then
		return
	end

	if not self.state_machine:getState("dead") then
		-- Update target if player is spotted
		if self.chase_cooldown > 0 then
			self.chase_cooldown = self.chase_cooldown - dt
			-- TODO: improve dialogue show/hide logic
			self.dialogue_timer = self.dialogue_timer - dt
			if self.dialogue_timer <= 0 then
				self.dialogue:hide("shock")
			end
		else
			local player_last_known_point = self:isPlayerInSight(8, self.w * 8)
			if player_last_known_point then
				if self:isPathTo(player_last_known_point.x, player_last_known_point.y, dt) then
					self:setTarget(player_last_known_point.x, player_last_known_point.y)
					self.dialogue:show("shock")
					Sfx:play("dialogue.shock")
					self.dialogue_timer = self.dialogue_time
					self.chase_cooldown = self.chase_cooldown_time
					self.state_machine:setState("grounded.to_target")
				end
			end
		end
		self:applyGravity(dt)
	end
	self.state_machine:update(dt)
	self.curr_animation:update(dt)
	self.dialogue:update(dt)
end

function Pig:draw()
	local scale_x = (self.direction == -1) and 1 or -1
	local offset_x = (self.direction == -1) and 12 or 28
	local offset_y = 10
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	love.graphics.push()

	-- TODO: add animation offset across enemy
	if self.is_active then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, scale_x, 1, offset_x, offset_y)
		-- TODO: improve dialogue drawing logic
		if self.chase_cooldown > 0 then
			self.dialogue:draw("shock", self.x - 8, self.y - self.h)
		end
	end

	love.graphics.pop()
end

return Pig
