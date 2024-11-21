local entity_classes = {
	Coin = require("src.entity.coin"),
	Bomb = require("src.entity.bomb"),
}

local entity_factory = {}

function entity_factory.create(entity)
	local entity_type = entity.id
	if entity_classes[entity_type] then
		return entity_classes[entity_type].new(entity)
	else
		return nil
	end
end

return entity_factory
