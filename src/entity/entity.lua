local Entity = {}
Entity.__index = Entity

function Entity.new(entity, world)
	local self = setmetatable({}, Entity)

	self.iid = entity.iid or false
	self.id = entity.id
	self.x = entity.x
	self.y = entity.y
	self.world = world

	self.image_map = {}
	self.is_active = true
	self.is_gravity = entity.is_gravity or false
	self.curr_animation = nil
	self.animations = {}

	return self
end

function Entity:move(goal_x, goal_y, filter)
	local actual_x, actual_y, cols, len = self.world:move(self, goal_x, goal_y, filter or nil)
	self.x, self.y = actual_x, actual_y
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
