local Ui = require("src.ui")
local Keymaps = require("config.keymaps")
local Sfx = require("src.sfx")
local Fonts = require("src.assets.fonts")

local ui = {}
local screen = {}
Bgm = require("src.utils.bgm.init")

function screen:Load(ScreenManager) -- pass a reference to the ScreenManager. Avoids circlular require()
	self.screenManager = ScreenManager
	self.screenManager.shared = { is_load_save = true }
	self.is_bye_pressed = false
	self.bye_time = 1
	self.bye_timer = self.bye_time

	Ui.credits:init()
	ui = Ui.credits
	Bgm:play("credits")
end

function screen:Draw()
	ui:draw()
	if self.is_bye_pressed then
		love.graphics.push("all")
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

		local bye = "Bye!"
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(Fonts.heading_3)
		love.graphics.printf(
			bye,
			0,
			love.graphics.getHeight() / 2 - Fonts.heading_3:getHeight(),
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.pop()
	end
end

function screen:Update(dt)
	ui:update(dt)
	if self.is_bye_pressed then
		self.bye_timer = self.bye_timer - dt
		if self.bye_timer < 0 then
			love.event.quit()
		end
	end
end

function screen:MousePressed(x, y, button) end

function screen:MouseReleased(x, y, button) end

function screen:KeyPressed(key)
	if ui.is_last_line and not self.is_bye_pressed then
		self.is_bye_pressed = true
		Sfx:play("ui.confirm")
	end
end

function screen:KeyReleased(key) end

return screen
