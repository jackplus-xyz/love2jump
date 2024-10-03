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

-- New function for attack sound
local function generateAttackSound(t, duration)
	local freq = 100 + 400 * (1 - t / duration)
	return generateSquare(t, freq) * (1 - t / duration)
end

-- New function for door opening sound
local function generateDoorSound(t, duration)
	local freq = 200 + 100 * math.sin(t * 20)
	return generateTriangle(t, freq) * (1 - t / duration) * 0.5
end

function sfx:load()
	local soundData = love.sound.newSoundData(sample_rate * duration, sample_rate, 16, 1)

	-- Generate attack sound
	local attack_duration = 0.2
	for i = 0, math.floor(sample_rate * attack_duration) do
		local t = i / sample_rate
		local sample = generateAttackSound(t, attack_duration)
		soundData:setSample(i, sample)
	end

	-- Generate door opening sound
	local doorDuration = 0.5
	local doorStart = math.floor(sample_rate * attack_duration)
	for i = 0, math.floor(sample_rate * doorDuration) do
		local t = i / sample_rate
		local sample = generateDoorSound(t, doorDuration)
		soundData:setSample(doorStart + i, sample)
	end

	self.sfxSource = love.audio.newSource(soundData, "static")
end

function sfx:playAttack()
	self.sfxSource:setLooping(false)
	self.sfxSource:seek(0)
	self.sfxSource:play()
end

function sfx:playDoorOpen()
	self.sfxSource:setLooping(false)
	self.sfxSource:seek(0.2) -- Start after the attack sound
	self.sfxSource:play()
end

function sfx:stop()
	self.sfxSource:stop()
end

function sfx:pause()
	self.sfxSource:pause()
end

function sfx:resume()
	self.sfxSource:play()
end

function sfx:setVolume(volume)
	self.sfxSource:setVolume(volume)
end

return sfx
