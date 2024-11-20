local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local Pig = require("src.enemy.pig")
local EntityFactory = require("src.entity.entity_factory")
local WorldHelpers = require("src.utils.world_helpers")

local BombPig = {}
BombPig.__index = BombPig
setmetatable(BombPig, Pig)

function BombPig.new(entity)
	local self = Pig.new(entity)
	setmetatable(self, BombPig)

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
	self.is_with_bomb = true

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
	self.pause_timer = 0
	self.pause_time = 1
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

function BombPig:init()
	self:loadAnimations()
	self:loadBombAnimations()
	self:setupStates()
end

function BombPig:loadBombAnimations()
	local sprite_w = 26
	local sprite_h = 26

	-- Load images
	self.idle_bomb_image = love.graphics.newImage("/assets/sprites/05-bomb-pig/idle.png")
	self.run_bomb_image = love.graphics.newImage("/assets/sprites/05-bomb-pig/run.png")
	self.picking_bomb_image = love.graphics.newImage("/assets/sprites/05-bomb-pig/picking-bomb.png")
	self.throwing_bomb_image = love.graphics.newImage("/assets/sprites/05-bomb-pig/throwing-bomb.png")

	-- Create a grid for the animations
	local idle_bomb_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_bomb_image:getWidth(), sprite_h)
	local run_bomb_grid = Anim8.newGrid(sprite_w, sprite_h, self.run_bomb_image:getWidth(), sprite_h)
	local picking_bomb_grid = Anim8.newGrid(sprite_w, sprite_h, self.picking_bomb_image:getWidth(), sprite_h)
	local throwing_bomb_grid = Anim8.newGrid(sprite_w, sprite_h, self.throwing_bomb_image:getWidth(), sprite_h)

	-- Create the animations
	self.animations.idle_bomb = Anim8.newAnimation(idle_bomb_grid("1-10", 1), 0.1)
	self.animations.run_bomb = Anim8.newAnimation(run_bomb_grid("1-6", 1), 0.1)
	self.animations.picking_bomb = Anim8.newAnimation(picking_bomb_grid("1-4", 1), 0.1, "pauseAtEnd")
	self.animations.throwing_bomb = Anim8.newAnimation(throwing_bomb_grid("1-5", 1), 0.1, "pauseAtEnd")

	self.image_map[self.animations.idle_bomb] = self.idle_bomb_image
	self.image_map[self.animations.run_bomb] = self.run_bomb_image
	self.image_map[self.animations.picking_bomb] = self.picking_bomb_image
	self.image_map[self.animations.throwing_bomb] = self.throwing_bomb_image
end

-- TODO: add picking bomb?
function BombPig:setupStates()
	self.state_machine:addState("grounded.idle.bomb", {
		enter = function()
			self.curr_animation = self.animations.idle_bomb
		end,
		update = function(_, dt)
			-- Update target if player is spotted
			local player_last_known_point = self:isPlayerInSight(8, self.w * 8)
			if player_last_known_point then
				if self:isPathTo(player_last_known_point.x, player_last_known_point.y, dt) then
					self:setTarget(player_last_known_point.x, player_last_known_point.y)
					self.state_machine:setState("grounded.shocked.bomb")
				end
			end
		end,
	})

	self.state_machine:addState("grounded.shocked.bomb", {
		enter = function()
			-- TODO: add shock Dialogue
			self.curr_animation = self.animations.idle_bomb
			self.shock_timer = 1
			self.dialogue:show("shock")
			Sfx:play("dialogue.shock")
			self.dialogue_timer = self.dialogue_time
		end,
		update = function(_, dt)
			self.shock_timer = self.shock_timer - dt
			if self.shock_timer <= 0 then
				self.state_machine:setState("grounded.throwing.bomb")
			end
		end,
	})

	self.state_machine:addState("grounded.throwing.bomb", {
		enter = function()
			self.curr_animation = self.animations.throwing_bomb
			self.pause_timer = self.pause_time
			-- TODO: call `throwBomb()` at the correct frame
			self:throwBomb()
		end,
		update = function(_, dt)
			print(self.curr_animation.position)
			if self.curr_animation.status == "paused" then
				self.pause_timer = self.pause_timer - dt
				if self.pause_timer <= 0 then
					self.state_machine:setState("grounded.idle")
				end
			end
		end,
	})

	self.state_machine:addState("hit.bomb", {
		enter = function()
			self.curr_animation = self.animations.hit
			self.hit_cooldown = self.hit_cooldown_time
			Sfx:play("pig.hit")
		end,
		update = function(_, dt)
			if self.hit_cooldown > 0 then
				self.hit_cooldown = self.hit_cooldown - dt
			else
				self.state_machine:setState("grounded.idle.bomb")
				self.hit_cooldown = self.hit_cooldown_time
			end
		end,
	})

	self.state_machine:setState("grounded.idle.bomb")
end

function BombPig:hit(other)
	self.health = self.health - other.atk
	local hitbox_direction = other.x > self.x and 1 or -1
	self:applyKnockback(self.knock_back_offset, hitbox_direction)
	if self.health <= 0 then
		self.state_machine:setState("dead")
	else
		local is_with_bomb = self.state_machine:getState():find("bomb") ~= nil
		self.state_machine:setState(is_with_bomb and "hit.bomb" or "hit")
	end
end

function BombPig:throwBomb()
	-- TODO: match the bomb at correct cord_y
	local bomb_entity = {
		id = "Bomb",
		x = self.x + self.w / 2,
		y = self.y,
		velocity_x = 200 * self.direction,
		velocity_y = -200,
		world = self.world,
		props = {
			atk = 3,
		},
	}
	local new_bomb = EntityFactory.create(bomb_entity)
	if not new_bomb then
		return
	end

	Sfx:play("bomb_pig:throw")
	new_bomb.addToWorld = WorldHelpers.addToWorld
	new_bomb.removeFromWorld = WorldHelpers.removeFromWorld
	new_bomb:addToWorld(self.world)
	self.addEntityToGame(new_bomb)

	return new_bomb
end

function BombPig:update(dt)
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

function BombPig:draw()
	local scale_x = (self.direction == -1) and 1 or -1
	local is_with_bomb = self.state_machine:getState():find("bomb") ~= nil
	local offset_x = (self.direction == -1) and (is_with_bomb and 4 or 12) or (is_with_bomb and 20 or 28)
	local offset_y = is_with_bomb and 8 or 10
	local curr_image = self.image_map[self.curr_animation] or self.idle_image

	love.graphics.push()

	-- TODO: add animation offset across enemy
	if self.is_active then
		self.curr_animation:draw(curr_image, self.x, self.y, 0, scale_x, 1, offset_x, offset_y)
		-- TODO: improve dialogue drawing logic
		self.dialogue:draw("shock", self.x - 8, self.y - self.h)
	end

	love.graphics.pop()
end

return BombPig
