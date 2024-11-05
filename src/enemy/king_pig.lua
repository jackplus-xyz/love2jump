local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local Enemy = require("src.enemy.enemy")
local EntityFactory = require("src.entity.entity_factory")

local KingPig = {}
KingPig.__index = KingPig
setmetatable(KingPig, Enemy)

function KingPig.new(entity)
	local self = Enemy.new(entity)
	setmetatable(self, KingPig)

	self.w = 15
	self.h = 20
	self.start_x, self.start_y = self.x, self.y

	if entity.props then
		self.props = entity.props
	end

	self.direction = -1
	self.knock_back_offset = 2
	self.speed = 100
	self.y_velocity = 0
	self.gravity = 1000
	self.jump_strength = -320
	self.jump_attempt = 1
	self.max_jump_attempts = 1
	self.hitbox_w = 12
	self.hitbox_h = 10

	-- Timers
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

function KingPig:init()
	self:loadAnimations()
	self:setupStates()
end

function KingPig:loadAnimations()
	local sprite_w = 38
	local sprite_h = 28

	-- Load images
	self.attack_image = love.graphics.newImage("/assets/sprites/02-king-pig/attack.png")
	self.dead_image = love.graphics.newImage("/assets/sprites/02-king-pig/dead.png")
	self.fall_image = love.graphics.newImage("/assets/sprites/02-king-pig/fall.png")
	self.ground_image = love.graphics.newImage("/assets/sprites/02-king-pig/ground.png")
	self.hit_image = love.graphics.newImage("/assets/sprites/02-king-pig/hit.png")
	self.idle_image = love.graphics.newImage("/assets/sprites/02-king-pig/idle.png")
	self.jump_image = love.graphics.newImage("/assets/sprites/02-king-pig/jump.png")
	self.run_image = love.graphics.newImage("/assets/sprites/02-king-pig/run.png")

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
	self.animations.idle = Anim8.newAnimation(idle_grid("1-12", 1), 0.1)
	self.animations.jump = Anim8.newAnimation(jump_grid("1-1", 1), 0.1)
	self.animations.run = Anim8.newAnimation(run_grid("1-6", 1), 0.1)

	self.image_map = {
		[self.animations.attack] = self.attack_image,
		[self.animations.dead] = self.dead_image,
		[self.animations.fall] = self.fall_image,
		[self.animations.ground] = self.ground_image,
		[self.animations.hit] = self.hit_image,
		[self.animations.idle] = self.idle_image,
		[self.animations.jump] = self.jump_image,
		[self.animations.run] = self.run_image,
	}

	-- Set the initial animation to idle
	self.curr_animation = self.animations.idle
end

-- TODO: add stages and moves
function KingPig:setupStates()
	self.state_machine:addState("grounded", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			if self.y_velocity ~= 0 then
				self.state_machine:setState("airborne")
			end
		end,
	})

	self.state_machine:addState("grounded.idle", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			local function playerFilter(item)
				return item.id == "Player"
			end
			local range = 20
			local items, len = self.world:queryRect(
				self.x + self.direction * self.w * range,
				self.y,
				self.w * range,
				self.h * range,
				playerFilter
			)

			if len > 0 then
				self.state_machine:setState("shocked")
			end
		end,
	})

	self.state_machine:addState("shocked", {
		enter = function()
			Sfx:play("dialogue.shock")
			self.dialogue:show("shock")
			self.shock_timer = 2
		end,
		update = function(_, dt)
			if self.shock_timer >= 0 then
				self.shock_timer = self.shock_timer - dt
				return
			end

			self.dialogue:hide("shock")
			self.state_machine:setState("stage_1.at_start")
		end,
	})

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
			self.hit_cooldown = self.hit_cooldown_time
			Sfx:play("enemy.hit")
		end,
		update = function(_, dt)
			if self.hit_cooldown > 0 then
				self.hit_cooldown = self.hit_cooldown - dt
			else
				self.state_machine:setState("grounded")
				self.hit_cooldown = self.hit_cooldown_time
			end
		end,
	})

	self.state_machine:addState("dead", {
		enter = function()
			self.curr_animation = self.animations.dead
			Sfx:play("enemy.dead")
			self.dialogue:hide("shock")
			self.drop_timer = 0.2
			self.drop_interval = 0.2
			self.dead_timer = 0.2 -- make the body stay for while
			self.current_drop_index = 1 -- Track which loot we're currently dropping
			self.world:remove(self)
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
					self:dropItem(new_loot, 100)

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

function KingPig:update(dt)
	if not self.is_active then
		return
	end

	if not self.state_machine:getState("dead") then
		self:applyGravity(dt)
	end

	self.state_machine:update(dt)
	self.curr_animation:update(dt)
	self.dialogue:update(dt)
end

function KingPig:draw()
	local scale_x = (self.direction == -1) and 1 or -1
	local offset_x = (self.direction == -1) and 12 or 28
	local offset_y = 8
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	love.graphics.push()

	if self.is_active then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, scale_x, 1, offset_x, offset_y)
		self.dialogue:draw("shock", self.x - 8, self.y - self.h)
	end

	love.graphics.pop()
end

return KingPig
