local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")
local Ldtk = require("lib.ldtk-love.ldtk")

local Coin = {}
Coin.__index = Coin

local sprite_width = 18
local sprite_height = 14

-- FIXME: don't respawn coin whenever the level refresh
function Coin.new(x, y, world)
	local self = setmetatable({}, Coin)

	self.x = x
	self.y = y
	self.world = world

	self.is_coin = true
	self.is_collected = false
	self.timer = 1

	self.width = 18
	self.height = 14
	self.x_offset = self.width / SCALE
	self.y_offset = self.height

	self.current_animation = nil
	self.animations = {}

	self:init()

	return self
end

function Coin:init()
	self.idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-idle.png")
	self.hit_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-hit.png")

	self.idle_grid = Anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	self.hit_grid = Anim8.newGrid(sprite_width, sprite_height, self.hit_image:getWidth(), sprite_height)

	self.animations.idle = Anim8.newAnimation(self.idle_grid("1-10", 1), 0.1)
	self.animations.hit = Anim8.newAnimation(self.hit_grid("1-2", 1), 0.1)

	self.current_animation = self.animations.idle
end

function Coin:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end

	if self.is_collected and self.timer >= 0 then
		self.timer = self.timer - dt
	end
end

function Coin:collect()
	Sfx:play("coin.collect")
	self.current_animation = self.animations.hit
	self.is_collected = true

	self.world:remove(self)
end

function Coin:draw()
	-- TODO: add animation offset across coins
	if not self.is_collected or self.timer >= 0 then
		self.current_animation:draw(
			self.current_animation == self.animations.hit and self.hit_image or self.idle_image,
			self.x,
			self.y,
			0,
			1,
			1,
			self.x_offset,
			self.y_offset
		)
	end
end

return Coin
