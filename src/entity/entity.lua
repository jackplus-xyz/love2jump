local Entity = {}
Entity.__index = Entity

function Entity.new(entity)
	local self = setmetatable({}, Entity)

	self.iid = entity.iid or false
	self.id = entity.id
	self.x = entity.x
	self.y = entity.y

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

return Entity
