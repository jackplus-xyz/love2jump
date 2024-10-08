local anim8 = require("lib.anim8")
-- local ldtk = require("lib.ldtk-love.ldtk")

local Door = {}
Door.__index = Door

local sprite_width = 46
local sprite_height = 56

function Door.new(x, y, props)
	local self = setmetatable({}, Door)

	self.is_door = true
	self.is_next = props.isNext
	self.x = x
	self.y = y
	self.ldtk = ldtk
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

	if self.is_next then
		ldtk:next()
	else
		ldtk:previous()
	end
end

function Door:draw()
	local x_offset = self.width / SCALE
	local y_offset = self.height

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

	-- Draw debugging box
	if IsDebug then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", self.x - self.x_offset, self.y - y_offset, self.width, self.height)
	end
end

return Door
