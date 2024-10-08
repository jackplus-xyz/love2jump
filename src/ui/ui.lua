local UI = require("src.ui.init")

local ui = {}

function ui:init()
	self.ui = UI:new()
end

function ui:update(dt)
	self.ui:update(dt)
end

function ui:draw()
	self.ui:draw()
end

return ui
