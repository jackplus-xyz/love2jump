local Door = {}
Door.__index = Door

function Door.new()
	local self = setmetatable({}, Door)

	return self
end

function Door:init()
	local sprite_width = 46
	local sprite_height = 56

	-- Load images
	self.idle_image = love.graphics.newImage("/assets/sprites/11-door/idle.png")
	self.closing_image = love.graphics.newImage("/assets/sprites/11-door/closing.png")
	self.opening_image = love.graphics.newImage("/assets/sprites/11-door/opening.png")
end

return Door
