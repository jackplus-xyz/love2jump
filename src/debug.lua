-- Used to print debugging information
local debug = {}
local fonts = require("src.assets.fonts")
local ldtk = require("lib.ldtk-love.ldtk")

function debug:init(world, camera_manager, player)
	self.world = world
	self.camera_manager = camera_manager
	self.player = player

	self.info_table = {}
	self:updateInfoTable()
end

function debug:updateInfoTable()
	local cam_x, cam_y = self.camera_manager.getCoords()
	local cam_bound_x, cam_bound_y, cam_bound_w, cam_bound_h = self.camera_manager.getBounds()

	self.info_table = {
		{ "Player State", self.player.state_machine.currState.name },
		{ "y_velocity", string.format("%.2f", self.player.y_velocity) },
		{
			"Position",
			"(" .. string.format("%.2f", self.player.x) .. ", " .. string.format("%.2f", self.player.y) .. ")",
		},
		{ "Current Animation Status", self.player.current_animation.status },
		{ "Camera Coords", "(" .. string.format("%.2f", cam_x) .. ", " .. string.format("%.2f", cam_y) .. ")" },
		{
			"Camera Bounds",
			"("
				.. string.format("%.0f", cam_bound_x)
				.. ", "
				.. string.format("%.0f", cam_bound_y)
				.. ", "
				.. string.format("%.0f", cam_bound_w)
				.. ", "
				.. string.format("%.0f", cam_bound_h)
				.. ")",
		},
		{
			"Current Level",
			ldtk:getCurrent(),
		},
	}
end

function debug:update()
	self:updateInfoTable()
end

function debug:draw(y_start)
	y_start = y_start or 0
	local y_offset = 16
	local x_start = 16
	local x_offset = 4

	-- Calculate the maximum width of the text entries
	local max_width = 0
	for _, info in ipairs(self.info_table) do
		local text = info[1] .. ": " .. tostring(info[2])
		local text_width = fonts.debug:getWidth(text)
		if text_width > max_width then
			max_width = text_width
		end
	end
	max_width = max_width + x_start + x_offset * 2

	love.graphics.push()
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle(
		"fill",
		GRID_SIZE / 2,
		GRID_SIZE / 2 + y_start,
		max_width,
		y_offset * (#self.info_table + 1)
	)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(fonts.debug)
	for i, info in ipairs(self.info_table) do
		love.graphics.print(info[1] .. ": " .. tostring(info[2]), x_start + x_offset, y_start + y_offset * i)
	end

	love.graphics.pop()
end

return debug
