local Bgm = {}
local Sounds = require("src.utils.bgm.sounds")

local function loadTrack(name)
	local track = require("src.utils.bgm.tracks." .. name)
	return track.melody, track.bassline
end

function Bgm:play(track_name)
	if self.music then
		self:fadeOut(0.5) -- Fade out the current track over 0.5 seconds
	end

	local melody, bassline = loadTrack(track_name)
	local sound_data = Sounds.generateSoundData(melody, bassline)
	self.music = love.audio.newSource(sound_data)
	self.music:setLooping(true)
	self.music:setVolume(0) -- Start with volume at 0 for fade-in
	love.audio.play(self.music)
	self:fadeIn(0.2) -- Fade in the new track over 0.5 seconds
end

function Bgm:fadeIn(duration)
	local startTime = love.timer.getTime()
	local function updateVolume()
		local elapsed = love.timer.getTime() - startTime
		if elapsed < duration then
			local volume = elapsed / duration
			self.music:setVolume(volume)
			love.timer.sleep(0.01)
			updateVolume()
		else
			self.music:setVolume(1)
		end
	end
	updateVolume()
end

function Bgm:fadeOut(duration)
	local startTime = love.timer.getTime()
	local initialVolume = self.music:getVolume()
	local function updateVolume()
		local elapsed = love.timer.getTime() - startTime
		if elapsed < duration then
			local volume = initialVolume * (1 - elapsed / duration)
			self.music:setVolume(volume)
			love.timer.sleep(0.01)
			updateVolume()
		else
			self.music:stop()
		end
	end
	updateVolume()
end

function Bgm:stop()
	if self.music then
		love.audio.stop(self.music)
	end
end

function Bgm:setVolume(volume)
	if self.music then
		self.music:setVolume(volume)
	end
end

return Bgm
