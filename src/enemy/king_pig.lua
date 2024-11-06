local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local BaseEnemy = require("src.enemy.base_enemy")
local EnemyFactory = require("src.enemy.enemy_factory")
local EntityFactory = require("src.entity.entity_factory")
local WorldHelpers = require("src.utils.world_helpers")

local KingPig = {}
KingPig.__index = KingPig
setmetatable(KingPig, BaseEnemy)

function KingPig.new(entity)
	local self = BaseEnemy.new(entity)
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
			self:checkAirborne()
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
				self.target = items[1]
				self.state_machine:setState("shocked")
			end
		end,
	})

	self.state_machine:addState("shocked", {
		enter = function()
			Sfx:play("king_pig.shock")
			self.dialogue:show("shock")
			self.shock_timer = 1
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

	self.state_machine:addState("stage_1.at_start", {
		enter = function()
			self.move_timer = 2
		end,
		update = function(_, dt)
			if self.health <= self.max_health * 0.75 then
				self.state_machine:setState("stage_2.at_start")
			end

			if self.move_timer >= 0 then
				self.move_timer = self.move_timer - dt
				return
			end

			self.state_machine:setState("stage_1.summon")
		end,
	})

	self.state_machine:addState("stage_1.summon", {
		enter = function()
			Sfx:play("king_pig.summoning")
			self.summon_count = 0
			self.max_summon_count = 3
			self.summoned = {}
			self.summon_cooldown_time = 1
			self.summon_cooldown = 0
		end,
		update = function(_, dt)
			if self.summon_cooldown >= 0 then
				self.summon_cooldown = self.summon_cooldown - dt
				return
			end

			self.summon_cooldown = self.summon_cooldown_time

			if self.summon_count < self.max_summon_count then
				local entity = {
					iid = nil,
					id = "Enemy",
					x = self.x + self.direction * GRID_SIZE * 2 * (self.max_summon_count - self.summon_count + 1),
					y = self.y,
					props = {
						Enemy = "Pig",
						max_health = 3,
						atk = 1,
					},
				}

				local new_enemy = self:summon(entity)
				if new_enemy then
					local summoned_index = self.summon_count + 1
					new_enemy.summoned_index = summoned_index
					self.summoned[summoned_index] = new_enemy
					new_enemy.removeFromSummoned = function()
						self.summoned[summoned_index] = nil
					end
					Sfx:play("pig.summoned")
					self.summon_count = self.summon_count + 1
				end
			else
				if #self.summoned == 0 then
					self.state_machine:setState("stage_1.to_target")
				end
			end
		end,
	})

	self.state_machine:addState("stage_1.to_target", {
		enter = function()
			self.curr_animation = self.animations.run
		end,
		update = function(_, dt)
			local dx = self.target_x - self.x
			local dy = self.target_y - self.y
			local distance = math.sqrt(dx * dx + dy * dy)

			if distance < GRID_SIZE then
				self.state_machine:setState("grounded.at_target")
			else
				-- Check if there's obstacle to target
				local goal_x = self.x + (dx / distance) * self.speed * dt
				-- TODO: check if self.h is required
				local goal_y = self.y + (dy / distance) * self.y_velocity * dt
				local jumpFilter = function(item)
					return item.id == "Collision"
				end
				local items, len = self.world:queryPoint(goal_x, goal_y, jumpFilter)

				-- Encounter an obstacle, check if can jump over it
				if len > 0 then
					local max_jump_height = self.jump_strength * self.jump_strength / self.gravity / 2
					local _, _, _, item_h = self.world:getRect(items[1])
					if max_jump_height > item_h and self.jump_attempt <= self.max_jump_attempts then
						self:jump()
						self.state_machine:setState("airborne.to_target")
					else
						self.state_machine:setState("grounded.at_target")
					end
				end

				self:move(goal_x, goal_y)
			end
		end,
	})

	self.state_machine:addState("stage_1.at_target", {
		enter = function()
			self.curr_animation = self.animations.idle
		end,
		update = function(_, dt)
			if self:isPlayerInAttackRange() then
				self.state_machine:setState("stage_1.attacking")
			end
		end,
	})

	self.state_machine:addState("grounded.attacking", {
		enter = function()
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
				self.state_machine:setState("stage_1.to_start")
			end
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
			Sfx:play("pig.hit")
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
			Sfx:play("pig.dead")
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

function KingPig:summon(entity)
	local new_enemy = EnemyFactory.create(entity)
	if not new_enemy then
		return
	end

	new_enemy.addToWorld = WorldHelpers.addToWorld
	new_enemy.removeFromWorld = WorldHelpers.removeFromWorld
	new_enemy:addToWorld(self.world)
	new_enemy:setTarget(self.target.x, self.target.y)
	new_enemy.state_machine:setState("grounded.to_target")
	self.addEntityToGame(new_enemy)

	return new_enemy
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
