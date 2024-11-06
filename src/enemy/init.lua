local Enemy = require("src.enemy.base_enemy") -- Base enemy class

-- Lazily load specific enemies as needed
local enemies = {
	Pig = function()
		return require("src.enemy.pig")
	end,
	KingPig = function()
		return require("src.enemy.king_pig")
	end,
}

Enemy.getClass = function(type)
	return enemies[type] and enemies[type]()
end

return Enemy
