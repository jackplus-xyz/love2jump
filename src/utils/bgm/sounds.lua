local sounds = {}

local sampleRate = 44100

local function generateTriangle(t, freq)
	local period = 1 / freq
	local phase = (t % period) / period
	return math.abs(4 * phase - 2) - 1
end

local function generateSquare(t, freq)
	return (t * freq) % 1 < 0.5 and 0.5 or -0.5
end

local function generateNoise()
	return math.random() * 2 - 1
end

function sounds.generateSoundData(melody, bassline)
	local duration = 10
	local sound_data = love.sound.newSoundData(sampleRate * duration, sampleRate, 16, 1)

	local time = 0
	local melody_index = 1
	local bass_index = 1
	local melody_time = 0
	local bass_time = 0

	for i = 0, sound_data:getSampleCount() - 1 do
		local curr_note = melody[melody_index]
		local curr_bass = bassline[bass_index]

		local melody_sample = generateSquare(time, curr_note.freq) * 0.3
		local bass_sample = generateTriangle(time, curr_bass.freq) * 0.2
		local noise_sample = generateNoise() * 0.05

		local sample = melody_sample + bass_sample + noise_sample

		-- Add a simple envelope
		local melody_envelope = 1
		local bass_envelope = 1
		if melody_time < 0.01 then
			melody_envelope = melody_time / 0.01 -- Attack
		elseif melody_time > curr_note.duration - 0.01 then
			melody_envelope = (curr_note.duration - melody_time) / 0.01 -- Release
		end
		if bass_time < 0.01 then
			bass_envelope = bass_time / 0.01 -- Attack
		elseif bass_time > curr_bass.duration - 0.01 then
			bass_envelope = (curr_bass.duration - bass_time) / 0.01 -- Release
		end

		sample = sample * melody_envelope * bass_envelope

		sound_data:setSample(i, sample)

		time = time + 1 / sampleRate
		melody_time = melody_time + 1 / sampleRate
		bass_time = bass_time + 1 / sampleRate

		if melody_time >= curr_note.duration then
			melody_index = (melody_index % #melody) + 1
			melody_time = 0
		end
		if bass_time >= curr_bass.duration then
			bass_index = (bass_index % #bassline) + 1
			bass_time = 0
		end
	end

	return sound_data
end

return sounds
