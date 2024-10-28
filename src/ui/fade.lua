local Fade = {}
Fade.__index = Fade

function Fade:new(direction, duration)
	local instance = setmetatable({}, Fade)
	instance:init(direction, duration)
	return instance
end

function Fade:init(direction, duration)
	self.alpha = direction == "in" and 0 or 1 -- Start alpha based on fade direction
	self.direction = direction or "in" -- Direction of fade ("in" or "out")
	self.duration = duration or 0.5 -- Total duration of the fade
	self.timer = self.duration -- Timer to track fading progress
	self.is_active = true -- Whether a fade is active
end

function Fade:reset()
	self.alpha = self.direction == "in" and 0 or 1
	self.direction = self.direction or "in"
	self.duration = self.duration or 0.5
	self.timer = self.duration
	self.is_active = true
end

function Fade:update(dt)
	if self.is_active then
		self.timer = self.timer - dt
		local progress = math.max(0, math.min(1, self.timer / self.duration))

		if self.direction == "in" then
			self.alpha = 1 - progress -- Fade In(alpha goes from 0 to 1)
		elseif self.direction == "out" then
			self.alpha = progress -- Fade Out (alpha goes from 1 to 0)
		end

		if self.timer <= 0 then
			self.is_active = false
		end
	end
end

function Fade:draw()
	if self.is_active then
		love.graphics.push("all")

		-- Draw a black rectangle over the screen with varying alpha
		love.graphics.setColor(0, 0, 0, self.alpha)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

		love.graphics.pop()
	end
end

return Fade
