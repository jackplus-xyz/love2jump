local UI = {}

UI.modules = {
	"hud",
	"title",
	"landing",
	"playing",
}

function UI:new()
	local instance = setmetatable({}, { __index = self })
	instance:init()
	return instance
end

function UI:init()
	-- Load each module
	for _, module_name in ipairs(self.modules) do
		self[module_name] = require("src.ui." .. module_name):new()
	end
end

function UI:update(dt)
	-- Update each loaded module
	for _, module_name in ipairs(self.modules) do
		if self[module_name].update then
			self[module_name]:update(dt)
		end
	end
end

function UI:draw()
	-- Draw each loaded module (if necessary)
	for _, module_name in ipairs(self.modules) do
		if self[module_name].draw then
			self[module_name]:draw()
		end
	end
end

return UI
