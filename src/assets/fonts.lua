-- Re-initialize the fonts when the scale changes, since fonts are influenced by scale.
local fonts = {}
function initFonts()
	fonts.debug = love.graphics.newFont("assets/fonts/JetBrainsMono[wght].ttf")
end

initFonts()
return fonts
