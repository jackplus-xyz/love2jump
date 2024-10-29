local enemy = require("src.enemy.enemy")
local pig = require("src.enemy.pig")

local enemy_types = {
	Pig = pig,
}

local function create_enemy(entity)
	local enemy_class = enemy_types[entity.props.Enemy]
	if enemy_class and enemy_class.new then
		return enemy_class.new(entity)
	else
		return nil
	end
end

return {
	create_enemy = create_enemy,
}
