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

local function generateSine(t, freq)
	return math.sin(t * freq * math.pi * 2) * 0.5
end

-- Sound effect definitions
local soundEffects = {
	-- UI/Interface sounds
	["ui.select"] = {
		duration = 0.1,
		generate = function(t, duration)
			local freq = 400 + 200 * (t / duration)
			return generateSine(t, freq) * (1 - t / duration) * 0.3
		end,
	},
	["ui.confirm"] = {
		duration = 0.2,
		generate = function(t, duration)
			-- Three-tone happy confirmation
			local freq1 = 400
			local freq2 = 600
			local freq3 = 800
			-- Play frequencies in sequence
			local segment = duration / 3
			if t < segment then
				return generateSine(t, freq1) * (1 - t / duration) * 0.3
			elseif t < segment * 2 then
				return generateSine(t, freq2) * (1 - t / duration) * 0.3
			else
				return generateSine(t, freq3) * (1 - t / duration) * 0.3
			end
		end,
	},
	["ui.cancel"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 300 - 100 * (t / duration)
			return generateSine(t, freq) * (1 - t / duration) * 0.3
		end,
	},
	["ui.warning"] = {
		duration = 0.4,
		generate = function(t, duration)
			-- Two repeating tones
			local freq = 400
			local pulseRate = 8 -- Controls how fast the warning beeps
			local pulse = math.sin(t * pulseRate * math.pi * 2)
			-- Only play sound when pulse is positive (creates beeping effect)
			return generateTriangle(t, freq) * math.max(0, pulse) * (1 - t / duration) * 0.3
		end,
	},
	["ui.error"] = {
		duration = 0.3,
		generate = function(t, duration)
			local freq = 200 + 50 * math.sin(t * 30)
			return generateSquare(t, freq) * (1 - t / duration) * 0.25
		end,
	},
	["ui.hover"] = {
		duration = 0.05,
		generate = function(t, duration)
			local freq = 300
			return generateSine(t, freq) * (1 - t / duration) * 0.15
		end,
	},

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
	["player.dead"] = {
		duration = 0.8,
		generate = function(t, duration)
			-- Downward pitch slide with vibrato
			local freq = 400 * (1 - t / duration) + 50 * math.sin(t * 30)
			-- Mix square and triangle waves for a dramatic effect
			local sound = (generateSquare(t, freq) * 0.6 + generateTriangle(t, freq) * 0.4)
			return sound * (1 - t / duration) * 0.8
		end,
	},
	["player.jump"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 200 + 400 * (t / duration)
			return generateSine(t, freq) * (1 - t / duration) * 0.4
		end,
	},
	["player.land"] = {
		duration = 0.15,
		generate = function(t, duration)
			local freq = 300 - 200 * (t / duration)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.5
		end,
	},
	["player.victory"] = {
		duration = 0.6,
		generate = function(t, duration)
			-- Create an ascending arpeggio-like effect
			local baseFreq = 300
			local step = math.floor(t * 8) -- Creates 4-5 distinct steps
			local freq = baseFreq * (1 + step * 0.2) -- Ascending frequency steps
			-- Mix sine and triangle waves for a pleasant, musical tone
			local sound = generateSine(t, freq) * 0.5 + generateTriangle(t, freq * 1.5) * 0.5
			-- Add a slight decay at the end
			return sound * (1 - (t / duration) ^ 0.5) * 0.6
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
		duration = 0.3,
		generate = function(t, duration)
			local freq = 800 + 1000 * (t / duration)
			return generateSquare(t, freq) * (1 - t / duration)
		end,
	},
	["coin.spawn"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 1200 - 800 * (t / duration)
			return generateSine(t, freq) * (1 - t / duration) * 0.4
		end,
	},

	-- Bomb
	["bomb.on"] = {
		duration = 0.6,
		generate = function(t, duration)
			local freq = 300 + 200 * math.sin(t * 8)
			local pulse = 0.5 + 0.5 * math.sin(t * 15) -- Creates a pulsing sound as the bomb is armed
			return (generateTriangle(t, freq) + generateNoise() * 0.2) * pulse * (1 - t / duration) * 0.7
		end,
	},
	["bomb.explode"] = {
		duration = 0.8,
		generate = function(t, duration)
			local baseFreq = 100 + 500 * (1 - t / duration)
			local rumble = generateNoise() * (1 - t / duration) * 0.6
			local blast = generateSquare(t, baseFreq) * math.max(0, 1 - t / 0.3) -- Sharp initial blast
			return (blast + rumble) * 0.8
		end,
	},

	-- Enemy
	-- Pig
	["pig.summoned"] = {
		duration = 0.5,
		generate = function(t, duration)
			local freq = 500 - 300 * (t / duration)
			local impact = t < 0.1 and 1 or (1 - (t - 0.1) / (duration - 0.1))
			return (generateNoise() * 0.3 + generateSquare(t, freq) * 0.7) * impact * 0.8
		end,
	},
	["pig.attack"] = {
		duration = 0.3,
		generate = function(t, duration)
			local freq = 200 + 300 * (1 - t / duration)
			-- Combine noise and square wave for an aggressive sound
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration) * 0.6
		end,
	},
	["pig.hit"] = {
		duration = 0.15,
		generate = function(t, duration)
			local freq = 300 + 200 * (t / duration)
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration)
		end,
	},
	["pig.dead"] = {
		duration = 0.6,
		generate = function(t, duration)
			local freq = 500 * (1 - t / duration) + 150 * math.sin(t * 20)
			return generateNoise() * generateTriangle(t, freq) * (1 - t / duration) * 0.8
		end,
	},

	-- Bomb Pig
	["bomb_pig.throw"] = {
		duration = 0.4,
		generate = function(t, duration)
			-- Whistling effect with a descending pitch
			local freq = 800 - 400 * (t / duration)
			local whistle = generateSine(t, freq) * 0.6 + generateTriangle(t, freq * 0.8) * 0.4
			return whistle * (1 - t / duration) * 0.7
		end,
	},

	-- King Pig
	["king_pig.attack"] = {
		duration = 0.4, -- Slightly longer than regular pig
		generate = function(t, duration)
			local freq = 150 + 400 * (1 - t / duration) -- Lower base frequency for more menacing sound
			-- Combine noise, square and sine for a more complex attack sound
			return (generateNoise() * generateSquare(t, freq) + generateSine(t, freq * 0.5)) * (1 - t / duration) * 0.7
		end,
	},
	["king_pig.hit"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 250 + 300 * (t / duration) -- Deeper hit sound
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration) * 1.2 -- Slightly louder
		end,
	},
	["king_pig.dead"] = {
		duration = 0.8, -- Longer death sound
		generate = function(t, duration)
			local freq = 400 * (1 - t / duration) + 200 * math.sin(t * 15)
			-- More complex death sound with multiple waveforms
			return (generateNoise() * generateTriangle(t, freq) + generateSine(t, freq * 0.3))
				* (1 - t / duration)
				* 0.9
		end,
	},
	["king_pig.summoning"] = {
		duration = 0.6,
		generate = function(t, duration)
			-- Rising pitch effect for summoning
			local freq = 200 + 600 * (t / duration)
			-- Pulsing effect using sine wave
			local pulse = 0.5 + 0.5 * math.sin(t * 30)
			return (generateSine(t, freq) + generateTriangle(t, freq * 0.5) * pulse) * (1 - 0.7 * t / duration) * 0.6
		end,
	},
	["king_pig.shock"] = {
		duration = 0.45,
		generate = function(t, duration)
			-- Electric zap effect
			local baseFreq = 800 + 400 * math.sin(t * 50)
			local crackle = generateNoise() * (0.7 + 0.3 * math.sin(t * 120))
			local buzz = generateSquare(t, baseFreq) * (0.5 + 0.5 * math.sin(t * 60))
			return (crackle + buzz) * (1 - t / duration) * 0.5
		end,
	},
	["king_pig.stage_change"] = {
		duration = 0.7,
		generate = function(t, duration)
			-- Dramatic rising sound with a hint of chaos
			local freq = 300 + 500 * (t / duration)
			local noiseMix = generateNoise() * (1 - t / duration) * 0.3
			local waveMix = generateSine(t, freq) * 0.7 + generateTriangle(t, freq * 0.5) * 0.3
			return (noiseMix + waveMix) * (1 - t / duration) * 0.8
		end,
	},

	-- Dialogue
	["dialogue.attack"] = {
		duration = 0.3,
		generate = function(t, duration)
			local freq = 600 + 400 * math.sin(t * 10)
			return generateSquare(t, freq) * (1 - t / duration) * 0.5
		end,
	},
	["dialogue.boom"] = {
		duration = 0.5,
		generate = function(t, duration)
			local freq = 100 + 150 * math.sin(t * 40)
			return generateNoise() * generateTriangle(t, freq) * (1 - t / duration) * 0.7
		end,
	},
	["dialogue.dead"] = {
		duration = 0.4,
		generate = function(t, duration)
			local freq = 150 + 100 * (1 - t / duration)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.4
		end,
	},
	["dialogue.hello"] = {
		duration = 0.3,
		generate = function(t, duration)
			local freq = 400 + 100 * (t / duration)
			return generateSine(t, freq) * (1 - t / duration) * 0.3
		end,
	},
	["dialogue.hi"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 500
			return generateSine(t, freq) * (1 - t / duration) * 0.2
		end,
	},
	["dialogue.interrogation"] = {
		duration = 0.4,
		generate = function(t, duration)
			local freq = 300 + 100 * math.sin(t * 10)
			return generateSquare(t, freq) * (1 - t / duration) * 0.4
		end,
	},
	["dialogue.loser"] = {
		duration = 0.35,
		generate = function(t, duration)
			local freq = 250 + 150 * (1 - t / duration)
			return generateSquare(t, freq) * (1 - t / duration) * 0.5
		end,
	},
	["dialogue.no"] = {
		duration = 0.2,
		generate = function(t, duration)
			local freq = 400 - 100 * (t / duration)
			return generateTriangle(t, freq) * (1 - t / duration) * 0.3
		end,
	},
	["dialogue.shock"] = {
		duration = 0.5,
		generate = function(t, duration)
			local freq = 600 + 200 * math.sin(t * 20)
			return generateNoise() * generateSquare(t, freq) * (1 - t / duration) * 0.6
		end,
	},
	["dialogue.wtf"] = {
		duration = 0.4,
		generate = function(t, duration)
			local freq = 700 + 300 * math.sin(t * 15)
			return generateNoise() * generateSine(t, freq) * (1 - t / duration) * 0.7
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
