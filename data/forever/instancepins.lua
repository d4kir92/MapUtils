local _, MapUtils = ...
MapUtils.INSTANCEPINS = MapUtils.INSTANCEPINS or {}
MapUtils.INSTANCEARTHEIGHTS = MapUtils.INSTANCEARTHEIGHTS or {}
local pins = MapUtils.INSTANCEPINS
local heights = MapUtils.INSTANCEARTHEIGHTS
pins["2959"] = {
	{"level", 0.616, 0.542, "2959_2"},
	{"level", 0.513, 0.684, "2959_2"},
	{"level", 0.531, 0.365, "2959_2"},
	{"boss", 0.524, 0.840, 245999, "Arcane Anomaly", 30, 129891, 1},
	{"boss", 0.565, 0.230, 246020, "Shade of the Archmage", 33, 130061, 1},
	{"boss", 0.517, 0.551, 246003, "Fel Ancient", 32, 129894, 1},
	{"boss", 0.613, 0.424, 246017, "Unstable Sentinel", 31, 129954, 1},
	{"boss", 0.668, 0.516, 246016, "Arcanic Enigma", 30, 129900, 1},
	{"boss", 0.418, 0.729, 246008, "Mana Devourer", 31, 129895, 1},
}
pins["2959_2"] = {
	{"entrance", 0.184, 0.840},
	{"level", 0.765, 0.570, "2959", true},
	{"boss", 0.545, 0.510, 247126, "Atrexis the Grave Knight", 29, 145787, 1},
	{"boss", 0.680, 0.180, 247032, "Lyn the Ignored", 31, 130235, 2},
}
pins["2998"] = {
	{"entrance", 0.889, 0.258},
	{"boss", 0.550, 0.360, 260322, "Saltspine", false, 144209, 1},
	{"boss", 0.325, 0.700, 260326, "Relic Guardian", false, 144224, 1},
	{"boss", 0.305, 0.480, 260325, "Shadetooth", false, 144210, 1},
	{"boss", 0.770, 0.220, 260808, "Highland Horror", 28, 9010, 1},
}
pins["2999"] = {
	{"entrance", 0.612, 0.216},
	{"boss", 0.704, 0.389, 250483, "Witherfang", 17, 144189, 1},
	{"boss", 0.606, 0.696, 250660, "The Baron", 17, 144188, 1},
	{"boss", 0.382, 0.670, 256035, "Viktor the Vile", 19, 139455, 1},
	{"boss", 0.406, 0.534, 250631, "The Abandoned", 18, 138667, 1},
	{"boss", 0.424, 0.385, 256097, "Bjork", 19, 144170, 1},
	{"boss", 0.463, 0.623, 250657, "Rath'mael", 20, 144175, 1},
	{"boss", 0.433, 0.269, 255699, "Lordaeron Captain", 19, 139050, 2},
	{"item", 0.347, 0.207, 275521},
	{"item", 0.376, 0.493, 275521},
	{"item", 0.433, 0.290, 275521},
	{"item", 0.566, 0.596, 275521},
	{"item", 0.591, 0.680, 280438},
	{"item", 0.671, 0.493, 275521},
}
pins["3065"] = {
	{"entrance", 0.511, 0.948},
	{"boss", 0.509, 0.666, 261306, "Faldrim Anvilmar", 16, 142826, 1},
	{"boss", 0.717, 0.465, 261316, "Magmatus", 16, 1070, 1},
	{"boss", 0.509, 0.516, 261311, "Plunder", 16, 142840, 1},
	{"boss", 0.510, 0.167, 261319, "Durgen Dirgehammer", 16, 142837, 1},
}
heights["2959"] = 684
heights["2959_2"] = 689
