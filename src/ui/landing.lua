local Fonts = require("src.assets.fonts")
local keymaps = require("config.keymaps")

local Landing = {}
Landing.__index = Landing

function Landing:new()
	local instance = setmetatable({}, Landing)
	instance:init()
	return instance
end

function Landing:init()
	self.landing_instruction_duration = 0
	self.landing_instruction_timer = self.landing_instruction_duration
	self.flash_interval = 0.8
	self.flash_timer = 0
	self.is_flash_visible = true
end

function Landing:update(dt)
	if self.landing_instruction_timer > 0 then
		self.landing_instruction_timer = self.landing_instruction_timer - dt
	else
		self.flash_timer = self.flash_timer + dt
		if self.flash_timer >= self.flash_interval then
			self.flash_timer = self.flash_timer - self.flash_interval
			self.is_flash_visible = not self.is_flash_visible
		end
	end
end

function Landing:draw()
	local instruction = "Press Any Key to Begin"
	local center_x = love.graphics.getWidth() / 2 - Fonts.heading_1:getWidth(instruction) / 4
	local start_y = Fonts.heading_1:getHeight()
	local offset_y = start_y / 2

	local keymaps_info = {
		{ "Move left:", keymaps.left },
		{ "Move right:", keymaps.right },
		{ "Jump:", keymaps.jump },
		{ "Enter a door:", keymaps.up },
		{ "Attack:", keymaps.attack },
	}

	love.graphics.push()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(Fonts.heading_2)
	love.graphics.print("Keymaps", center_x, start_y)

	for i, key in pairs(keymaps_info) do
		local keymap = tostring(key[1]) .. " " .. tostring(key[2])
		love.graphics.setFont(Fonts.heading_3)
		love.graphics.print(keymap, center_x, start_y + offset_y * (i + 1))
	end

	if self.is_flash_visible and self.landing_instruction_timer <= 0 then
		love.graphics.print(
			instruction,
			love.graphics.getWidth() / 2 - Fonts.heading_1:getWidth(instruction) / 4,
			start_y + offset_y * (#keymaps_info + 2)
		)
	end

	love.graphics.pop()
end

return Landing
