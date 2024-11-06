local Enemy = require("src.enemy") -- Uses `init.lua` which has `getClass`

local enemy_factory = {}

local nop = function() end

function enemy_factory.create(entity)
	local enemy_type = entity.props.Enemy
	local EnemyClass = Enemy.getClass(enemy_type)
	if EnemyClass then
		return EnemyClass.new(entity)
	else
		return nil
	end
end

return enemy_factory
