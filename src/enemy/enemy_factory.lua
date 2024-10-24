local enemy_classes = {
	Pig = require("src.enemy.pig"),
}

local enemy_factory = {}

function enemy_factory.create(entity, world)
	local enemy_type = entity.props.Enemy
	if enemy_classes[enemy_type] then
		return enemy_classes[enemy_type].new(entity, world)
	else
		return nil
	end
end

return enemy_factory
