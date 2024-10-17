local Anim8 = require("lib.anim8.anim8")
local Entity = require("src.entity.entity")
local Sfx = require("src.sfx")

local Door = {}
Door.__index = Door
setmetatable(Door, Entity)

local sprite_width = 46
local sprite_height = 56

function Door.new(x, y, props, world)
	local instance = Entity.new()
	setmetatable(instance, Door)

	instance.is_door = true
	instance.is_next = props.isNext
	instance.timer = 3
	instance.world = world

	instance.x = x
	instance.y = y
	instance.width = sprite_width
	instance.height = sprite_height
	instance.x_offset = instance.width / SCALE
	instance.y_offset = instance.height

	instance.current_animation = nil
	instance.animations = {}
	instance:init()

	return instance
end

function Door:init()
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

function Door:open()
	self.current_animation = self.animations.opening
	Sfx:play("door.open")

	return self.is_next
end

function Door:close()
	self.current_animation = self.animations.closing
	Sfx:play("door.close")
end

function Door:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
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
