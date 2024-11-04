local Anim8 = require("lib.anim8.anim8")

local Dialogue = {}
Dialogue.__index = Dialogue

-- Define image maps as a local constant
local IMAGE_MAPS = {
	{ name = "attack" },
	{ name = "boom" },
	{ name = "dead" },
	{ name = "hello" },
	{ name = "hi" },
	{ name = "interrogation" },
	{ name = "loser" },
	{ name = "no" },
	{ name = "shock" },
	{ name = "wtf" },
}

-- Constructor function
function Dialogue.new()
	local self = setmetatable({}, Dialogue)
	self.images = {}
	self.animations = {}
	self.states = {}
	self:init()
	return self
end

function Dialogue:loadAnimations()
	local sprite_h = 16
	for _, image in ipairs(IMAGE_MAPS) do
		-- Load images for each state
		local image_in = love.graphics.newImage("assets/sprites/13-dialogue-boxes/" .. image.name .. "-in.png")
		local image_out = love.graphics.newImage("assets/sprites/13-dialogue-boxes/" .. image.name .. "-out.png")
		local frames_in = 3
		local frames_out = 2

		self.images[image.name .. "_in"] = image_in
		self.images[image.name .. "_out"] = image_out

		-- Create grids for animations
		local grid_in = Anim8.newGrid(image_in:getWidth() / frames_in, sprite_h, image_in:getWidth(), sprite_h)
		local grid_out = Anim8.newGrid(image_out:getWidth() / frames_out, sprite_h, image_out:getWidth(), sprite_h)

		-- Create animations for each state
		self.animations[image.name .. "_in"] = Anim8.newAnimation(grid_in("1-" .. frames_in, 1), 0.4, "pauseAtEnd")
		self.animations[image.name .. "_out"] = Anim8.newAnimation(grid_out("1-" .. frames_out, 1), 0.2, "pauseAtEnd")

		-- Initialize state for this dialogue
		self.states[image.name] = {
			current = "hidden", -- hidden, showing, visible, hiding
			animation = nil,
		}
	end
end

function Dialogue:show(name)
	local state = self.states[name]
	if state.current == "hidden" then
		state.current = "showing"
		state.animation = self.animations[name .. "_in"]
		state.animation:gotoFrame(1)
		state.animation:resume()
	end
end

function Dialogue:hide(name)
	local state = self.states[name]
	if state.current == "visible" then
		state.current = "hiding"
		state.animation = self.animations[name .. "_out"]
		state.animation:gotoFrame(1)
		state.animation:resume()
	end
end

function Dialogue:update(dt)
	for name, state in pairs(self.states) do
		if state.animation then
			state.animation:update(dt)
			-- Handle state transitions
			if state.current == "showing" and state.animation.status == "paused" then
				state.current = "visible"
			elseif state.current == "hiding" and state.animation.status == "paused" then
				state.current = "hidden"
				state.animation = nil
			end
		end
	end
end

function Dialogue:getCurrState(name)
	return self.states[name].current
end

function Dialogue:draw(name, x, y)
	local state = self.states[name]
	if state.animation then
		local image_suffix = state.current == "hiding" and "_out" or "_in"
		state.animation:draw(self.images[name .. image_suffix], x, y)
	end
end

function Dialogue:init()
	self:loadAnimations()
end

return Dialogue
