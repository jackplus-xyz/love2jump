-- Used to print debugging information
local debug = {}
local fonts = require("src.assets.fonts")
local ldtk = require("lib.ldtk-love.ldtk")

function debug:init(world)
	self.world = world
	-- self.ldtk = ldtk

	self.infoTable = {}
	self:updateInfoTable()
end

function debug:updateInfoTable()
	local cam_x, cam_y = CameraManager.getCoords()
	local cam_bound_x, cam_bound_y, cam_bound_w, cam_bound_h = CameraManager.getBounds()

	self.infoTable = {
		{ "Player State", Player.stateMachine.currState.name },
		{ "y_velocity", string.format("%.2f", Player.y_velocity) },
		{ "Position", "(" .. string.format("%.2f", Player.x) .. ", " .. string.format("%.2f", Player.y) .. ")" },
		{ "Current Animation Status", Player.current_animation.status },
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

function debug:draw(y_offset)
	y_offset = y_offset or 0
	love.graphics.setFont(fonts.debug)

	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 16, 16 + y_offset, 360, 20 * #self.infoTable + 10)
	love.graphics.setColor(1, 1, 1, 1)

	y_offset = y_offset + 20
	for _, info in ipairs(self.infoTable) do
		love.graphics.print(info[1] .. ": " .. tostring(info[2]), 20, y_offset)
		y_offset = y_offset + 20
	end
end

return debug
