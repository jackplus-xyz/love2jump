local world_helpers = {}

function world_helpers.addToWorld(self, world)
	self.world = world or self.world
	self.is_active = true
	self.world:add(self, self.x - self.w / 2, self.y - self.h, self.w, self.h)
	local x, y = self.world:getRect(self)
	self.x, self.y = x, y
end

function world_helpers.removeFromWorld(self)
	self.is_active = false
	if self.world:hasItem(self) then
		self.world:remove(self)
	end
end

return world_helpers
