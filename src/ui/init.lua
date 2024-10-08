local UI = {}

UI.HUD = require("src.ui.hud")
-- Add other UI components here as they are created
-- UI.Menu = require("src.ui.menu")
-- UI.Transitions = require("src.ui.transitions")

function UI:new()
	local instance = setmetatable({}, { __index = self })
	instance:init()
	return instance
end

function UI:init()
	self.hud = self.HUD:new()
	-- Initialize other UI components here in the future
	-- self.menu = self.Menu:new()
	-- self.transitions = self.Transitions:new()
end

function UI:update(dt)
	self.hud:update(dt)
	-- Update other UI components here in the future
	-- self.menu:update(dt)
	-- self.transitions:update(dt)
end

function UI:draw()
	self.hud:draw()
	-- Draw other UI components here in the future
	-- self.menu:draw()
	-- self.transitions:draw()
end

return UI
