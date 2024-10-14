local Anim8 = require("lib.anim8.anim8")
local Sfx = require("src.sfx")

local Door = {}
Door.__index = Door

local sprite_width = 46
local sprite_height = 56

function Door.new(x, y, props, world)
	local self = setmetatable({}, Door)

	self.is_door = true
	self.is_next = props.isNext
	self.timer = 3
	self.world = world

	self.x = x
	self.y = y
	self.width = sprite_width
	self.height = sprite_height
	self.x_offset = self.width / SCALE
	self.y_offset = self.height

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

	self.idle_grid = Anim8.newGrid(sprite_width, sprite_height, self.idle_image:getWidth(), sprite_height)
	self.opening_grid = Anim8.newGrid(sprite_width, sprite_height, self.opening_image:getWidth(), sprite_height)
	self.closing_grid = Anim8.newGrid(sprite_width, sprite_height, self.closing_image:getWidth(), sprite_height)

	self.animations.idle = Anim8.newAnimation(self.idle_grid("1-1", 1), 0.1)
	self.animations.opening = Anim8.newAnimation(self.opening_grid("1-5", 1), 0.1, "pauseAtEnd")
	self.animations.closing = Anim8.newAnimation(self.closing_grid("1-3", 1), 0.1, "pauseAtEnd")

	self.current_animation = self.animations.idle
end

function Door:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Door:enter()
	self.current_animation = self.animations.opening
	-- Sfx:play("door.enter")

	-- Perform level transition after fade-out is complete
	return self.is_next
end

function Door:out()
	self.current_animation = self.animations.closing
	-- Sfx:play("door.enter")
	-- TODO: add close door sfx
end

-- FIXME: collision when jumping over a door
function Door:draw()
	love.graphics.push()
	self.current_animation:draw(
		self.current_animation == self.animations.opening and self.opening_image
			or self.current_animation == self.animations.closing and self.closing_image
			or self.idle_image,
		self.x,
		self.y,
		0,
		1,
		1,
		self.x_offset,
		self.y_offset
	)

	love.graphics.pop()
end

return Door
