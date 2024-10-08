local sfx = {}

-- Sound parameters
local sample_rate = 44100 -- Samples per second
local duration = 10 -- Extended duration in seconds
local base_frequency = 261.63 -- C4 note

local notes = {
	C3 = base_frequency / 2,
	D3 = (base_frequency * 9 / 8) / 2,
	E3 = (base_frequency * 5 / 4) / 2,
	F3 = (base_frequency * 4 / 3) / 2,
	G3 = (base_frequency * 3 / 2) / 2,
	A3 = (base_frequency * 5 / 3) / 2,
	B3 = (base_frequency * 15 / 8) / 2,
	C4 = base_frequency,
	D4 = base_frequency * 9 / 8,
	E4 = base_frequency * 5 / 4,
	F4 = base_frequency * 4 / 3,
	G4 = base_frequency * 3 / 2,
	A4 = base_frequency * 5 / 3,
	B4 = base_frequency * 15 / 8,
	C5 = base_frequency * 2,
	D5 = base_frequency * 9 / 4,
	E5 = base_frequency * 5 / 2,
	F5 = base_frequency * 8 / 3,
	G5 = base_frequency * 3,
	A5 = base_frequency * 10 / 3,
	REST = 0,
}

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
	["player.attack"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 100 + 400 * (1 - t / duration)
			return generateSquare(t, freq) * (1 - t / duration)
		end,
	},
	["coin.collected"] = {
		duration = 0.3, -- Short and sweet
		generate = function(t, duration)
			local freq = 800 + 1000 * (t / duration) -- Frequency rises quickly
			return generateSquare(t, freq) * (1 - t / duration) -- Square wave, decreasing in volume
		end,
	},
	["door.enter"] = {
		duration = 0.5,
		generate = function(t, duration)
			local freq = 200 + 100 * math.sin(t * 20)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.5
		end,
	},
	["enemy.hit"] = {
		duration = 0.15,
		generate = function(t, duration)
			local freq = 300 + 200 * (t / duration)
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration)
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
