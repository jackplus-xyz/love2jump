local Anim8 = require("lib.anim8.anim8")
local Entity = require("src.entity.entity")
local Sfx = require("src.sfx")

local Door = {}
Door.__index = Door
setmetatable(Door, Entity)

local sprite_w = 46
local sprite_h = 56

function Door.new(entity)
	local self = Entity.new(entity)
	setmetatable(self, Door)

	self.w = sprite_w
	self.h = sprite_h
	self.offset_x = self.w / SCALE
	self.offset_y = self.h
	self.timer = 3

	self.is_visible = entity.props.is_visible
	self.next_door = entity.props.next_door

	self:init()

	return self
end

function Door:init()
	self:loadAnimations()
end

function Door:loadAnimations()
	self.idle_image = love.graphics.newImage("/assets/sprites/11-door/idle.png")
	self.opening_image = love.graphics.newImage("/assets/sprites/11-door/opening.png")
	self.closing_image = love.graphics.newImage("/assets/sprites/11-door/closing.png")

	self.idle_grid = Anim8.newGrid(sprite_w, sprite_h, self.idle_image:getWidth(), sprite_h)
	self.opening_grid = Anim8.newGrid(sprite_w, sprite_h, self.opening_image:getWidth(), sprite_h)
	self.closing_grid = Anim8.newGrid(sprite_w, sprite_h, self.closing_image:getWidth(), sprite_h)

	self.animations.idle = Anim8.newAnimation(self.idle_grid("1-1", 1), 0.1)
	self.animations.opening = Anim8.newAnimation(self.opening_grid("1-5", 1), 0.1, "pauseAtEnd")
	self.animations.closing = Anim8.newAnimation(self.closing_grid("1-3", 1), 0.1, "pauseAtEnd")

	self.image_map = {
		[self.animations.idle] = self.idle_image,
		[self.animations.opening] = self.opening_image,
		[self.animations.closing] = self.closing_image,
	}

	self.curr_animation = self.animations.idle
end

function Door:open()
	self.curr_animation = self.animations.opening
	Sfx:play("door.open")
	return self.next_door
end

function Door:close()
	self.curr_animation = self.animations.closing
	Sfx:play("door.close")
end

function Door:update(dt)
	for _, animation in pairs(self.animations) do
		animation:update(dt)
	end
end

function Door:draw()
	local offset_x = 0
	local offset_y = 0
	local curr_image = self.image_map[self.curr_animation] or self.idle_image
	love.graphics.push()

	self.curr_animation:draw(curr_image, self.x, self.y, 0, 1, 1, offset_x, offset_y)

	love.graphics.pop()
end

return Door
