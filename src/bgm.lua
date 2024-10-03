local bgm = {}

-- Sound parameters
local sampleRate = 44100 -- Samples per second
local duration = 10 -- Extended duration in seconds
local baseFrequency = 261.63 -- C4 note

local notes = {
	C3 = baseFrequency / 2,
	D3 = (baseFrequency * 9 / 8) / 2,
	E3 = (baseFrequency * 5 / 4) / 2,
	F3 = (baseFrequency * 4 / 3) / 2,
	G3 = (baseFrequency * 3 / 2) / 2,
	A3 = (baseFrequency * 5 / 3) / 2,
	B3 = (baseFrequency * 15 / 8) / 2,
	C4 = baseFrequency,
	D4 = baseFrequency * 9 / 8,
	E4 = baseFrequency * 5 / 4,
	F4 = baseFrequency * 4 / 3,
	G4 = baseFrequency * 3 / 2,
	A4 = baseFrequency * 5 / 3,
	B4 = baseFrequency * 15 / 8,
	C5 = baseFrequency * 2,
	D5 = baseFrequency * 9 / 4,
	E5 = baseFrequency * 5 / 2,
	F5 = baseFrequency * 8 / 3,
	G5 = baseFrequency * 3,
	A5 = baseFrequency * 10 / 3,
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
	local soundData = love.sound.newSoundData(sampleRate * duration, sampleRate, 16, 1)

	local time = 0
	local melodyIndex = 1
	local bassIndex = 1
	local melodyTime = 0
	local bassTime = 0

	for i = 0, soundData:getSampleCount() - 1 do
		local currentNote = melody[melodyIndex]
		local currentBass = bassline[bassIndex]

		local melodySample = generateSquare(time, currentNote.freq) * 0.3
		local bassSample = generateTriangle(time, currentBass.freq) * 0.2
		local noiseSample = generateNoise() * 0.05

		local sample = melodySample + bassSample + noiseSample

		-- Add a simple envelope
		local melodyEnvelope = 1
		local bassEnvelope = 1
		if melodyTime < 0.01 then
			melodyEnvelope = melodyTime / 0.01 -- Attack
		elseif melodyTime > currentNote.duration - 0.01 then
			melodyEnvelope = (currentNote.duration - melodyTime) / 0.01 -- Release
		end
		if bassTime < 0.01 then
			bassEnvelope = bassTime / 0.01 -- Attack
		elseif bassTime > currentBass.duration - 0.01 then
			bassEnvelope = (currentBass.duration - bassTime) / 0.01 -- Release
		end

		sample = sample * melodyEnvelope * bassEnvelope

		soundData:setSample(i, sample)

		time = time + 1 / sampleRate
		melodyTime = melodyTime + 1 / sampleRate
		bassTime = bassTime + 1 / sampleRate

		if melodyTime >= currentNote.duration then
			melodyIndex = (melodyIndex % #melody) + 1
			melodyTime = 0
		end
		if bassTime >= currentBass.duration then
			bassIndex = (bassIndex % #bassline) + 1
			bassTime = 0
		end
	end

	self.music = love.audio.newSource(soundData)
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
