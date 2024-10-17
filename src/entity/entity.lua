local Entity = {}
Entity.__index = Entity

function Entity.new()
	local self = setmetatable({}, Entity)
	return self
end

function Entity:addToWorld()
	self.world:add(self, self.x - self.x_offset, self.y - self.y_offset, self.width, self.height)
end

return Entity
