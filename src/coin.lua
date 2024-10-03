local anim8 = require("lib.anim8")
local ldtk = require("lib.ldtk-love.ldtk")

local Coin = {}
Coin.__index = Coin

local sprite_width = 18
local sprite_height = 14

function Coin.new(x, y)
	local self = setmetatable({}, Coin)

	self.x = x
	self.y = y
	self.is_coin = true
	self.animations = {}

	self:init()

	return self
end

function Coin:init()
	self.idle_image = love.graphics.newImage("assets/sprites/12-live-and-coins/big-diamond-idle.png")

	self.idle_grid = anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)

	self.animations.idle = anim8.newAnimation(self.idle_grid("1-10", 1), 0.1)
end

function Coin:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Coin:draw()
	self.animations.idle:draw(self.idle_image, self.x, self.y, 0, 1, 1, sprite_width, sprite_height)
end

return Coin
