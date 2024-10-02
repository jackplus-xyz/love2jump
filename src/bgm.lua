local bgm = {}

-- Sound parameters
local sampleRate = 44100 -- Samples per second
local duration = 5 -- Duration in seconds
local baseFrequency = 261.63 -- C4 note

-- Define notes
local notes = {
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

-- Create a more complex melody
local melody = {
	{ freq = notes.E4, duration = 0.25 },
	{ freq = notes.G4, duration = 0.25 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.C5, duration = 0.25 },
	{ freq = notes.D5, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.A4, duration = 0.25 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.C5, duration = 0.5 },
	{ freq = notes.F4, duration = 0.25 },
	{ freq = notes.A4, duration = 0.25 },
	{ freq = notes.C5, duration = 0.25 },
	{ freq = notes.D5, duration = 0.25 },
	{ freq = notes.E5, duration = 0.5 },
	{ freq = notes.A4, duration = 0.5 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.C5, duration = 0.25 },
	{ freq = notes.D5, duration = 0.5 },
	{ freq = notes.G4, duration = 0.25 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.D5, duration = 0.25 },
	{ freq = notes.E5, duration = 0.25 },
	{ freq = notes.F5, duration = 0.5 },
	{ freq = notes.D5, duration = 0.25 },
	{ freq = notes.B4, duration = 0.25 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.E4, duration = 0.5 },
	{ freq = notes.C5, duration = 0.5 },
	{ freq = notes.A4, duration = 0.5 },
	{ freq = notes.F4, duration = 0.5 },
	{ freq = notes.D5, duration = 0.5 },
	{ freq = notes.B4, duration = 0.5 },
	{ freq = notes.G4, duration = 0.5 },
	{ freq = notes.E5, duration = 1 },
	{ freq = notes.REST, duration = 0.5 },
}

function bgm:load()
	-- Create SoundData
	local soundData = love.sound.newSoundData(sampleRate * duration, sampleRate, 16, 1)

	local time = 0
	local melodyIndex = 1
	local noteTime = 0
	-- Square wave function
	local function squareWave(t, freq)
		return (t * freq) % 1 < 0.5 and 1 or -1
	end

	-- Fill SoundData with the melody
	for i = 0, soundData:getSampleCount() - 1 do
		local currentNote = melody[melodyIndex]
		local amplitude = math.sin(2 * math.pi * currentNote.freq * time) * 0.5 -- Reduced amplitude

		-- Add a simple envelope
		local envelopeFactor = 1
		if noteTime < 0.01 then
			envelopeFactor = noteTime / 0.01 -- Attack
		elseif noteTime > currentNote.duration - 0.01 then
			envelopeFactor = (currentNote.duration - noteTime) / 0.01 -- Release
		end

		soundData:setSample(i, amplitude * envelopeFactor)

		time = time + 1 / sampleRate
		noteTime = noteTime + 1 / sampleRate

		if noteTime >= currentNote.duration then
			melodyIndex = (melodyIndex % #melody) + 1
			noteTime = 0
		end
	end

	-- Create audio source from SoundData
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
