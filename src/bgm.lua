local bgm = {}

-- Sound parameters
local sampleRate = 44100 -- Samples per second
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

local melody = {
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.B4, duration = 0.75 },
	{ freq = notes.A4, duration = 0.25 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.D4, duration = 1 },
	{ freq = notes.REST, duration = 0.5 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.A4, duration = 0.5 },
	{ freq = notes.C5, duration = 0.75 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.A4, duration = 0.5 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.E4, duration = 1 },
	{ freq = notes.REST, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.B4, duration = 0.5 },
	{ freq = notes.D5, duration = 0.75 },
	{ freq = notes.C5, duration = 0.25 },
	{ freq = notes.B4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.F4, duration = 1 },
	{ freq = notes.REST, duration = 0.5 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.C5, duration = 0.75 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.A4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.D4, duration = 1 },
	{ freq = notes.REST, duration = 0.75 },
	{ freq = notes.G3, duration = 0.25 },
	{ freq = notes.C4, duration = 0.5 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.75 },
	{ freq = notes.F4, duration = 0.25 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.C4, duration = 0.5 },
	{ freq = notes.B3, duration = 1 },
	{ freq = notes.REST, duration = 0.5 },
	{ freq = notes.D4, duration = 0.5 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.A4, duration = 0.75 },
	{ freq = notes.G4, duration = 0.25 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.D4, duration = 0.5 },
	{ freq = notes.C4, duration = 1.5 },
	{ freq = notes.REST, duration = 1 },
}

local bassline = {
	{ freq = notes.C3, duration = 0.5 },
	{ freq = notes.G3, duration = 0.5 },
	{ freq = notes.D3, duration = 0.5 },
	{ freq = notes.A3, duration = 0.5 },
	{ freq = notes.E3, duration = 0.5 },
	{ freq = notes.B3, duration = 0.5 },
	{ freq = notes.C3, duration = 0.5 },
	{ freq = notes.G3, duration = 0.5 },
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

function bgm:load()
	local sound_data = love.sound.newSoundData(sampleRate * duration, sampleRate, 16, 1)

	local time = 0
	local melody_index = 1
	local bass_index = 1
	local melody_time = 0
	local bass_time = 0

	for i = 0, sound_data:getSampleCount() - 1 do
		local current_note = melody[melody_index]
		local current_bass = bassline[bass_index]

		local melody_sample = generateSquare(time, current_note.freq) * 0.3
		local bass_sample = generateTriangle(time, current_bass.freq) * 0.2
		local noise_sample = generateNoise() * 0.05

		local sample = melody_sample + bass_sample + noise_sample

		-- Add a simple envelope
		local melody_envelope = 1
		local bass_envelope = 1
		if melody_time < 0.01 then
			melody_envelope = melody_time / 0.01 -- Attack
		elseif melody_time > current_note.duration - 0.01 then
			melody_envelope = (current_note.duration - melody_time) / 0.01 -- Release
		end
		if bass_time < 0.01 then
			bass_envelope = bass_time / 0.01 -- Attack
		elseif bass_time > current_bass.duration - 0.01 then
			bass_envelope = (current_bass.duration - bass_time) / 0.01 -- Release
		end

		sample = sample * melody_envelope * bass_envelope

		sound_data:setSample(i, sample)

		time = time + 1 / sampleRate
		melody_time = melody_time + 1 / sampleRate
		bass_time = bass_time + 1 / sampleRate

		if melody_time >= current_note.duration then
			melody_index = (melody_index % #melody) + 1
			melody_time = 0
		end
		if bass_time >= current_bass.duration then
			bass_index = (bass_index % #bassline) + 1
			bass_time = 0
		end
	end

	self.music = love.audio.newSource(sound_data)
	self.music:setLooping(true)
end

function bgm:play()
	love.audio.play(self.music)
end

function bgm:stop()
	love.audio.stop(self.music)
end

function bgm:pause()
	self.music:pause()
end

function bgm:resume()
	self.music:play()
end

function bgm:setVolume(volume)
	self.music:setVolume(volume)
end

return bgm
