local anim8 = require("lib.anim8")
-- local ldtk = require("lib.ldtk-love.ldtk")

local Door = {}
Door.__index = Door

local sprite_width = 46
local sprite_height = 56

function Door.new(x, y, ldtk, next_level_id)
	local self = setmetatable({}, Door)

	self.x = x
	self.y = y
	self.ldtk = ldtk
	self.width = sprite_width
	self.height = sprite_height
	self.is_door = true
	self.next_level_id = next_level_id

	self.current_animation = nil
	self.animations = {}
	self:init()

	return self
end

function Door:init()
	-- Load images
	self.idle_image = love.graphics.newImage("/assets/sprites/11-door/idle.png")
	self.opening_image = love.graphics.newImage("/assets/sprites/11-door/opening.png")
	self.closing_image = love.graphics.newImage("/assets/sprites/11-door/closing.png")

	self.idle_grid = anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	self.opening_grid = anim8.newGrid(sprite_width, sprite_height, self.opening_image:getWidth(), sprite_height)
	self.closing_grid = anim8.newGrid(sprite_width, sprite_height, self.closing_image:getWidth(), sprite_height)

	self.animations.idle = anim8.newAnimation(self.idle_grid("1-1", 1), 0.1)
	self.animations.opening = anim8.newAnimation(self.opening_grid("1-5", 1), 0.1)
	self.animations.closing = anim8.newAnimation(self.opening_grid("1-3", 1), 0.1)

	self.current_animation = self.animations.idle
	World:add(self, self.x - self.width / 2, self.y - self.height, self.width, self.height)
end

function Door:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Door:enter()
	self.current_animation = self.animations.opening
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setColor(1, 1, 1, 1)
	self.ldtk:goTo(2)
end

function Door:draw()
	self.current_animation:draw(
		self.current_animation == self.animations.opening and self.opening_image
			or self.current_animation == self.animations.closing and self.closing_image
			or self.idle_image,
		self.x,
		self.y,
		0,
		1,
		1,
		sprite_width,
		sprite_height
	)
end

return Door
