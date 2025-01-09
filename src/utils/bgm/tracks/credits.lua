local notes = require("src.utils.bgm.notes")

local credit = {
	melody = {
		-- Gentle ascending phrase
		{ freq = notes.C4, duration = 1.0 },
		{ freq = notes.E4, duration = 1.0 },
		{ freq = notes.G4, duration = 1.0 },
		{ freq = notes.REST, duration = 0.5 },

		-- Descending response
		{ freq = notes.A4, duration = 0.75 },
		{ freq = notes.G4, duration = 0.75 },
		{ freq = notes.E4, duration = 1.0 },
		{ freq = notes.REST, duration = 0.5 },

		-- Second phrase
		{ freq = notes.F4, duration = 1.0 },
		{ freq = notes.A4, duration = 1.0 },
		{ freq = notes.C5, duration = 1.0 },
		{ freq = notes.REST, duration = 0.5 },

		-- Gentle conclusion
		{ freq = notes.B4, duration = 0.75 },
		{ freq = notes.G4, duration = 0.75 },
		{ freq = notes.E4, duration = 1.5 },
		{ freq = notes.REST, duration = 1.0 },
	},

	bassline = {
		-- Simple, supporting bass pattern
		{ freq = notes.C3, duration = 2.0 },
		{ freq = notes.G3, duration = 2.0 },
		{ freq = notes.F3, duration = 2.0 },
		{ freq = notes.C3, duration = 2.0 },
	},
}

return credit
