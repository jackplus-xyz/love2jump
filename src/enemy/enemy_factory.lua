local enemy_classes = {
	Pig = require("src.enemy.pig"),
	KingPig = require("src.enemy.king_pig"),
}

local enemy_factory = {}

function enemy_factory.create(entity)
	local enemy_type = entity.props.Enemy
	if enemy_classes[enemy_type] then
		return enemy_classes[enemy_type].new(entity)
	else
		return nil
	end
end

return enemy_factory
