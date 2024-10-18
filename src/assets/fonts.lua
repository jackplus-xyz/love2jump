local fonts = {}

local function createFont(path, size)
	local font = love.graphics.newFont(path, size)
	font:setFilter("nearest", "nearest")
	return font
end

function fonts:init()
	self.debug = createFont("assets/fonts/JetBrainsMono[wght].ttf", 16)

	self.heading_1 = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 64)
	self.heading_2 = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 48)
	self.heading_3 = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 32)
	self.heading_4 = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 24)

	self.text_xl = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 20)
	self.text = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 16)
	self.text_sm = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 14)
	self.text_xs = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 12)

	self.caption = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 10)
	self.small = createFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 8)
end

fonts:init()
return fonts
