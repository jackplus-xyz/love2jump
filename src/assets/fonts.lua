-- Re-initialize the fonts when the scale changes, since fonts are influenced by scale.
local fonts = {}
function fonts:init()
	fonts.debug = love.graphics.newFont("assets/fonts/JetBrainsMono[wght].ttf", 64)
	fonts.title = love.graphics.newFont("assets/fonts/PixelifySans-VariableFont_wght.ttf", 64)
	fonts.debug:setFilter("nearest", "nearest")
	fonts.title:setFilter("nearest", "nearest")
end

fonts:init()

return fonts
