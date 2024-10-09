local UI = {}
UI.hud = require("src.ui.hud")
UI.title = require("src.ui.title")

function UI:new()
	local instance = setmetatable({}, { __index = self })
	instance:init()
	return instance
end

function UI:init()
	self.hud = self.hud:new()
	self.title = self.title:new()
end

function UI:update(dt)
	self.hud:update(dt)
	self.title:update(dt)
end

function UI:draw()
	self.hud:draw()
	self.title:draw()
end

return UI
