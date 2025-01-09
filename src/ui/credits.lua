local Fonts = require("src.assets.fonts")

local Credits = {}
Credits.__index = Credits

function Credits:new()
	local instance = setmetatable({}, Credits)
	instance:init()
	return instance
end

function Credits:init()
	self.fade_time = 2.5
	self.fade_timer = self.fade_time
	self.is_done_scrolling = false
	self.is_last_line = false
	self.pause_timer = 2
	self.credits = {
		{
			heading = "Love Arcade",
			content = {
				"A Personal Game Development Project",
				"Created with LÖVE (Love2D)",
			},
		},
		{
			heading = "Technologies",
			content = {
				"Programming Language: Lua",
				"Game Engine: LÖVE (Love2D)",
				"Level Editor: LDTK",
			},
		},
		{
			heading = "Libraries",
			content = {
				"ldtk-love by HamdyElzanqali",
				"anim8 by kikito",
				"bump.lua by kikito",
				"CameraMgr by V3X3D",
				"Yonder by thenerdie",
			},
		},
		{
			heading = "Special Thanks",
			content = {
				"LÖVE Framework Team",
				"Lua Development Team",
				"LDTK Development Team",
				"Neovim Community",
			},
		},
		{
			heading = "",
			content = { "", "", "", "", "" },
		},
		{
			heading = "Thank you for playing!",
			content = {},
		},
	}
	self.selected_option = self.credits[self.curr_index]
end

function Credits:update(dt)
	if self.fade_timer > 0 then
		self.fade_timer = self.fade_timer - dt
	end

	local scroll_speed = -50
	if not self.scroll_position then
		self.scroll_position = love.graphics.getHeight() / 2 -- initial print position
	end
	self.scroll_position = self.scroll_position - (scroll_speed * dt)

	if self.is_done_scrolling then
		self.pause_timer = self.pause_timer - dt
	end

	if self.pause_timer < 0 then
		self.is_last_line = true
	end
end

function Credits:draw()
	local opacity = (self.fade_time - self.fade_timer) / self.fade_time
	local title = "Credits"
	-- Calculate the maximum scroll position
	local max_scroll = self:getTotalContentHeight() + love.graphics.getHeight() / 2 - Fonts.heading_2:getHeight()

	-- Clamp the scroll offset to stop at the end
	local scroll_offset = math.min(max_scroll, self.scroll_position)
	local center_y = love.graphics.getHeight() - scroll_offset

	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	if center_y > -self:getTotalContentHeight() then
		love.graphics.setColor(1, 1, 1, opacity)
		love.graphics.setFont(Fonts.heading_1)
		love.graphics.printf(title, 0, center_y, love.graphics.getWidth(), "center")

		local y_offset = center_y + 80

		for _, section in ipairs(self.credits) do
			love.graphics.setFont(Fonts.heading_2)
			love.graphics.setColor(1, 0.8, 0.2, opacity)
			love.graphics.printf(section.heading, 0, y_offset, love.graphics.getWidth(), "center")
			y_offset = y_offset + Fonts.heading_2:getHeight() + 10

			love.graphics.setFont(Fonts.heading_3)
			love.graphics.setColor(1, 1, 1, opacity)
			for _, line in ipairs(section.content) do
				love.graphics.printf(line, 0, y_offset, love.graphics.getWidth(), "center")
				y_offset = y_offset + Fonts.heading_3:getHeight() + 5
			end
			y_offset = y_offset + 30
		end
	end

	if max_scroll < self.scroll_position then
		self.is_done_scrolling = true
	end

	if self.is_last_line then
		love.graphics.setFont(Fonts.heading_3)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(
			"Press any key to quit",
			0,
			love.graphics.getHeight() / 2 + Fonts.heading_2:getHeight(),
			love.graphics.getWidth(),
			"center"
		)
	end

	love.graphics.pop()
end

function Credits:getTotalContentHeight()
	local total_height = 80 -- Initial spacing

	for _, section in ipairs(self.credits) do
		total_height = total_height + Fonts.heading_2:getHeight() + 10 -- Section heading
		total_height = total_height + (#section.content * (Fonts.heading_3:getHeight() + 5)) -- Content lines
		total_height = total_height + 30 -- Section spacing
	end

	return total_height
end

return Credits
