local base_frequency = 261.63 -- C4 note

local notes = {
	C2 = base_frequency / 4,
	D2 = (base_frequency * 9 / 8) / 4,
	E2 = (base_frequency * 5 / 4) / 4,
	F2 = (base_frequency * 4 / 3) / 4,
	G2 = (base_frequency * 3 / 2) / 4,
	A2 = (base_frequency * 5 / 3) / 4,
	B2 = (base_frequency * 15 / 8) / 4,
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

return notes
