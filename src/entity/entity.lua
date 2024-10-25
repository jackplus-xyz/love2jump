local Entity = {}
Entity.__index = Entity

function Entity.new(entity, world)
	local self = setmetatable({}, Entity)

	self.iid = entity.iid
	self.id = entity.id
	self.x = entity.x
	self.y = entity.y
	self.world = world

	self.image_map = {}
	self.is_active = true
	self.curr_animation = nil
	self.animations = {}

	return self
end

function Entity:addToWorld()
	self.is_active = true
	self.world:add(self, self.x - self.x_offset, self.y - self.y_offset, self.w, self.h)
end

function Entity:removeFromWorld()
	self.is_active = false
	self.world:remove(self)
end

return Entity
