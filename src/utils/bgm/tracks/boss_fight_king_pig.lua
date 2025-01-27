local notes = require("src.utils.bgm.notes")

local boss_fight_king_pig = {
	melody = {
		{ freq = notes.C5, duration = 0.125 },
		{ freq = notes.E5, duration = 0.125 },
		{ freq = notes.F5, duration = 0.25 },
		{ freq = notes.D5, duration = 0.125 },
		{ freq = notes.G5, duration = 0.375 },
		{ freq = notes.REST, duration = 0.125 },
		{ freq = notes.B4, duration = 0.125 },
		{ freq = notes.A4, duration = 0.125 },
		{ freq = notes.F5, duration = 0.25 },
		{ freq = notes.E5, duration = 0.125 },
		{ freq = notes.D5, duration = 0.125 },
		{ freq = notes.G4, duration = 0.25 },
		{ freq = notes.A4, duration = 0.125 },
		{ freq = notes.B4, duration = 0.25 },
		{ freq = notes.C5, duration = 0.125 },
		{ freq = notes.REST, duration = 0.25 },
		{ freq = notes.D5, duration = 0.125 },
		{ freq = notes.F5, duration = 0.125 },
		{ freq = notes.G5, duration = 0.375 },
		{ freq = notes.A5, duration = 0.25 },
		{ freq = notes.REST, duration = 0.125 },
		{ freq = notes.F5, duration = 0.25 },
		{ freq = notes.E5, duration = 0.125 },
		{ freq = notes.D5, duration = 0.25 },
		{ freq = notes.G4, duration = 0.5 },
		{ freq = notes.REST, duration = 0.25 },
	},

	bassline = {
		{ freq = notes.F2, duration = 0.25 },
		{ freq = notes.G2, duration = 0.25 },
		{ freq = notes.A2, duration = 0.125 },
		{ freq = notes.B2, duration = 0.125 },
		{ freq = notes.D3, duration = 0.25 },
		{ freq = notes.REST, duration = 0.125 },
		{ freq = notes.C3, duration = 0.25 },
		{ freq = notes.E3, duration = 0.25 },
		{ freq = notes.F3, duration = 0.375 },
		{ freq = notes.G3, duration = 0.125 },
		{ freq = notes.REST, duration = 0.125 },
		{ freq = notes.A2, duration = 0.25 },
		{ freq = notes.B2, duration = 0.25 },
		{ freq = notes.G2, duration = 0.125 },
		{ freq = notes.F2, duration = 0.125 },
		{ freq = notes.E2, duration = 0.5 },
		{ freq = notes.REST, duration = 0.25 },
	},
}

return boss_fight_king_pig
