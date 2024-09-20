---@class StateMachine
---@field states table<string, table>
---@field currState table|nil
---@field prevState table|nil
local StateMachine = {}
StateMachine.__index = StateMachine

---Creates a new StateMachine instance.
---@return StateMachine A new state machine object
function StateMachine.new()
	local self = setmetatable({}, StateMachine)
	self.states = {}
	self.currState = nil
	self.prevState = nil
	return self
end

---Adds a new state to the state machine.
---@param name string The name of the state
---@param state table The state object containing enter, exit, and update functions
---@param parentState string|nil The name of the parent state, if any
function StateMachine:addState(name, state, parentState)
	state.name = name
	state.children = {}
	state.parent = self.states[parentState]
	self.states[name] = state
	if parentState then
		table.insert(self.states[parentState].children, state)
	end
end

---Set the current state of the state machine.
---@param stateName string The name of the state to change to
---@param ... any Additional arguments to pass to the enter function of the new state
function StateMachine:setState(stateName, ...)
	assert(self.states[stateName], "State " .. stateName .. " does not exist!")

	local newState = self.states[stateName]
	local oldState = self.currState

	-- Exit all current states up to the common ancestor
	while oldState and oldState ~= newState.parent do
		if oldState.exit then
			oldState:exit()
		end
		oldState = oldState.parent
	end

	-- Enter all new states from the common ancestor
	local statesToEnter = {}
	local state = newState
	while state and state ~= oldState do
		table.insert(statesToEnter, 1, state)
		state = state.parent
	end

	for _, s in ipairs(statesToEnter) do
		if s.enter then
			s:enter(...)
		end
	end

	self.prevState = self.currState
	self.currState = newState
end

---Updates the current state and all its parent states.
---@param dt number Delta time since the last update
function StateMachine:update(dt)
	local state = self.currState
	while state do
		if state.update then
			state:update(dt)
		end
		state = state.parent
	end
end

---Handles an event by propagating it up the state hierarchy.
---@param eventName string The name of the event to handle
---@param ... any Additional arguments to pass to the event handler
---@return boolean True if the event was handled, false otherwise
function StateMachine:handleEvent(eventName, ...)
	local state = self.currState
	while state do
		if state[eventName] then
			local handled = state[eventName](state, ...)
			if handled then
				return true
			end
		end
		state = state.parent
	end
	return false
end

---Gets the current state or checks if the current state matches a given state name.
---@param stateName string|nil The name of the state to check (optional)
---@return string|boolean If stateName is nil, returns the name of the current state. If stateName is provided, returns true if it matches the current state (or any parent state), false otherwise.
function StateMachine:getState(stateName)
	if not stateName then
		return self.currState.name
	end

	local state = self.currState
	while state do
		if state.name == stateName then
			return true
		end
		state = state.parent
	end
	return false
end

return StateMachine
