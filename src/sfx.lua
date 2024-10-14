local sfx = {}

-- Sound parameters
local sample_rate = 44100 -- Samples per second

-- Sound generation functions
local function generateNoise()
	return math.random() * 2 - 1
end

local function generateTriangle(t, freq)
	local period = 1 / freq
	local phase = (t % period) / period
	return math.abs(4 * phase - 2) - 1
end

local function generateSquare(t, freq)
	return (t * freq) % 1 < 0.5 and 0.5 or -0.5
end

-- Sound effect definitions
local soundEffects = {
	-- Player
	["player.attack"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 100 + 400 * (1 - t / duration)
			return generateSquare(t, freq) * (1 - t / duration)
		end,
	},
	["player.hit"] = {
		duration = 0.25,
		generate = function(t, duration)
			local freq = 250 + 150 * (1 - t / duration)
			return generateSquare(t, freq) * (1 - t / duration) * 0.8
		end,
	},

	-- Entities
	["door.open"] = {
		duration = 0.5,
		generate = function(t, duration)
			local freq = 200 + 100 * math.sin(t * 20)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.5
		end,
	},
	["door.close"] = {
		duration = 0.3,
		generate = function(t, duration)
			local freq = 150 + 50 * math.sin(t * 10)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.7
		end,
	},

	-- Coin
	["coin.collect"] = {
		duration = 0.3, -- Short and sweet
		generate = function(t, duration)
			local freq = 800 + 1000 * (t / duration)
			return generateSquare(t, freq) * (1 - t / duration)
		end,
	},

	-- Enemy
	["enemy.hit"] = {
		duration = 0.15,
		generate = function(t, duration)
			local freq = 300 + 200 * (t / duration)
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration)
		end,
	},
	["enemy.dead"] = {
		duration = 0.4,
		generate = function(t, duration)
			local freq = 400 + 100 * math.sin(t * 15)
			return generateNoise() * generateTriangle(t, freq) * (1 - t / duration) * 0.6
		end,
	},
}

-- Generate sound data for all effects
function sfx:load()
	self.sources = {}
	for name, effect in pairs(soundEffects) do
		local soundData = love.sound.newSoundData(math.floor(sample_rate * effect.duration), sample_rate, 16, 1)
		for i = 0, soundData:getSampleCount() - 1 do
			local t = i / sample_rate
			local sample = effect.generate(t, effect.duration)
			soundData:setSample(i, sample)
		end
		self.sources[name] = love.audio.newSource(soundData, "static")
	end
end

-- Play a specific sound effect
function sfx:play(name)
	if self.sources[name] then
		self.sources[name]:stop()
		self.sources[name]:play()
	else
		print("Sound effect not found: " .. name)
	end
end

-- Stop a specific sound effect
function sfx:stop(name)
	if self.sources[name] then
		self.sources[name]:stop()
	end
end

-- Pause a specific sound effect
function sfx:pause(name)
	if self.sources[name] then
		self.sources[name]:pause()
	end
end

-- Resume a specific sound effect
function sfx:resume(name)
	if self.sources[name] then
		self.sources[name]:play()
	end
end

-- Set volume for a specific sound effect
function sfx:setVolume(name, volume)
	if self.sources[name] then
		self.sources[name]:setVolume(volume)
	end
end

return sfx
