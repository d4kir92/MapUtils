local _, MapUtils = ...
MapUtils.INSTANCEPINS = {
	["2959"] = {
		{"level", 0.605, 0.530, "2959_2"},
		{"boss", 0.536, 0.712, 245999, "Arcane Anomaly", false, 129891, 1},
		{"boss", 0.515, 0.270, 246020, "Shade of the Archmage", false, 130061, 1},
	},
	["2959_2"] = {
		{"entrance", 0.184, 0.840},
		{"level", 0.645, 0.640, "2959", true},
		{"boss", 0.545, 0.510, 247126, "Atrexis the Grave Knight", false, 145787, 1},
	},
	["2998"] = {
		{"entrance", 0.080, 0.610},
		{"boss", 0.340, 0.570, 260322, "Saltspine", false, 144209, 1},
		{"boss", 0.635, 0.250, 260326, "Relic Guardian", false, 144224, 1},
		{"boss", 0.775, 0.690, 260325, "Shadetooth", false, 144210, 1},
		{"boss", 0.790, 0.280, 260808, "Highland Horror", false, 9010, 1},
	},
	["2999"] = {
		{"entrance", 0.612, 0.216},
		{"boss", 0.704, 0.389, 250483, "Witherfang", 17, 144189, 1},
		{"boss", 0.606, 0.696, 250660, "The Baron", 17, 144188, 1},
		{"boss", 0.382, 0.670, 256035, "Viktor the Vile", 19, 139455, 1},
		{"boss", 0.406, 0.534, 250631, "The Abandoned", 18, 138667, 1},
		{"boss", 0.424, 0.385, 256097, "Bjork", 19, 144170, 1},
		{"boss", 0.463, 0.623, 250657, "Rath'mael", 20, 144175, 1},
		{"boss", 0.486, 0.719, 255699, "Lordaeron Captain", 19, 139050, 2},
		{"item", 0.347, 0.207, 275521},
		{"item", 0.376, 0.493, 275521},
		{"item", 0.433, 0.290, 275521},
		{"item", 0.566, 0.596, 275521},
		{"item", 0.591, 0.680, 280438},
		{"item", 0.671, 0.493, 275521},
	},
	["3065"] = {
		{"entrance", 0.511, 0.948},
		{"boss", 0.509, 0.666, 261306, "Faldrim Anvilmar", 16, 142826, 1},
		{"boss", 0.717, 0.465, 261316, "Magmatus", 16, 1070, 1},
		{"boss", 0.509, 0.516, 261311, "Plunder", 16, 142840, 1},
		{"boss", 0.510, 0.167, 261319, "Durgen Dirgehammer", 16, 142837, 1},
	},
	["213"] = {
		{"entrance", 0.611, 0.072},
		{"boss", 0.564, 0.372, 11517, "Oggleflint", 16, 11611, 1},
		{"boss", 0.406, 0.574, 11520, "Taragaman the Hungerer", 16, 7970, 1},
		{"boss", 0.338, 0.840, 11518, "Jergosh the Invoker", 16, 11429, 1},
		{"boss", 0.422, 0.857, 11519, "Bazzalan", 16, 2007, 1},
	},
	["291"] = {
		{"entrance", 0.297, 0.133},
		{"level", 0.655, 0.667, "292"},
		{"boss", 0.374, 0.610, 644, "Rhahk'Zor", 19, 14403, 1},
		{"boss", 0.523, 0.510, 3586, "Miner Johnson", 19, 556, 2},
		{"boss", 0.493, 0.862, 642, "Sneed's Shredder / Sneed", 20, 1269, 1},
	},
	["292"] = {
		{"level", 0.123, 0.883, "291", true},
		{"boss", 0.121, 0.741, 1763, "Gilnid", 20, 7124, 1},
		{"boss", 0.525, 0.170, 646, "Mr. Smite", 20, 2026, 1},
		{"boss", 0.582, 0.357, 647, "Captain Greenskin", 20, 7113, 1},
		{"boss", 0.603, 0.455, 639, "Edwin VanCleef", 21, 2029, 2},
		{"boss", 0.668, 0.398, 645, "Cookie", 20, 1305, 1},
	},
	["279"] = {
		{"entrance", 0.463, 0.590},
		{"boss", 0.303, 0.423, 3671, "Lady Anacondra", 20, 4313, 1},
		{"boss", 0.385, 0.340, 3653, "Kresh", 20, 5126, 1},
		{"boss", 0.162, 0.563, 3669, "Lord Cobrahn", 20, 4213, 1},
		{"boss", 0.547, 0.899, 3670, "Lord Pythas", 21, 4214, 1},
		{"boss", 0.604, 0.742, 3674, "Skum", 21, 4203, 1},
		{"boss", 0.480, 0.410, 5912, "Deviate Faerie Dragon", 20, 1267, 2},
		{"boss", 0.613, 0.537, 3673, "Lord Serpentis", 21, 4215, 1},
		{"boss", 0.555, 0.475, 5775, "Verdan the Everliving", 21, 4256, 1},
		{"boss", 0.338, 0.133, 3654, "Mutanus the Devourer", 22, 4088, 1},
	},
	["310"] = {
		{"entrance", 0.705, 0.606},
		{"level", 0.367, 0.392, "311"},
		{"level", 0.148, 0.866, "311"},
		{"level", 0.355, 0.666, "316", true},
		{"boss", 0.650, 0.715, 3914, "Rethilgore", 20, 524, 1},
		{"boss", 0.278, 0.601, 4278, "Commander Springvale", 24, 3223, 1},
	},
	["311"] = {
		{"level", 0.593, 0.121, "310", true},
		{"level", 0.273, 0.881, "310", true},
		{"boss", 0.301, 0.762, 3887, "Baron Silverlaine", 24, 3222, 1},
		{"boss", 0.472, 0.277, 3886, "Razorclaw the Butcher", 22, 524, 1},
	},
	["316"] = {
		{"level", 0.239, 0.745, "310"},
		{"level", 0.436, 0.331, "312", true},
		{"boss", 0.595, 0.820, 4279, "Odo the Blindwatcher", 24, 522, 1},
		{"boss", 0.690, 0.770, 3872, "Deathsworn Captain", 25, 3224, 2},
	},
	["312"] = {
		{"level", 0.516, 0.904, "316", true},
		{"level", 0.533, 0.600, "313", true},
	},
	["313"] = {
		{"level", 0.442, 0.749, "314", true},
		{"level", 0.526, 0.872, "312"},
		{"boss", 0.544, 0.537, 4274, "Fenrus the Devourer", 25, 2352, 1},
	},
	["314"] = {
		{"level", 0.437, 0.743, "315", true},
		{"level", 0.490, 0.780, "313"},
	},
	["315"] = {
		{"level", 0.420, 0.842, "314"},
		{"boss", 0.630, 0.185, 4275, "Archmage Arugal", 26, 2353, 1},
		{"boss", 0.553, 0.627, 3927, "Wolf Master Nandos", 25, 11179, 1},
	},
	["225"] = {
		{"entrance", 0.500, 0.815},
		{"boss", 0.440, 0.446, 1696, "Targorr the Dread", 24, 517, 1},
		{"boss", 0.691, 0.300, 1666, "Kam Deepfury", 27, 825, 1},
		{"boss", 0.780, 0.454, 1717, "Hamhock", 28, 3250, 1},
		{"boss", 0.745, 0.562, 1716, "Bazil Thredd", 29, 1621, 1},
		{"boss", 0.213, 0.260, 1663, "Dextren Ward", 26, 2149, 1},
		{"boss", 0.497, 0.222, 1720, "Bruegal Ironknuckle", 26, 2142, 2},
	},
	["221"] = {
		{"entrance", 0.453, 0.108},
		{"level", 0.621, 0.741, "222"},
		{"boss", 0.325, 0.595, 4887, "Ghamoo-ra", 25, 5027, 1},
		{"boss", 0.117, 0.378, 4831, "Lady Sarevess", 25, 4979, 1},
		{"boss", 0.536, 0.568, 6243, "Gelihast", 26, 1773, 1},
	},
	["222"] = {
		{"level", 0.477, 0.707, "223"},
		{"boss", 0.325, 0.710, 12902, "Lorgus Jett", 26, 12822, 1},
		{"boss", 0.413, 0.727, 12876, "Baron Aquanis", 28, 110, 1},
		{"boss", 0.515, 0.810, 4832, "Twilight Lord Kelris", 27, 4939, 1},
		{"boss", 0.848, 0.853, 4829, "Aku'mai", 28, 2837, 1},
		{"level", 0.350, 0.290, "221"},
	},
	["223"] = {
		{"boss", 0.585, 0.280, 4830, "Old Serra'kis", 26, 1816, 1},
		{"level", 0.300, 0.612, "222", true},
	},
	["226"] = {
		{"entrance", 0.644, 0.275},
		{"level", 0.345, 0.640, "227"},
		{"level", 0.470, 0.870, "227"},
		{"level", 0.551, 0.440, "227"},
		{"boss", 0.770, 0.670, 7361, "Grubbis", 32, 6533, 1},
	},
	["227"] = {
		{"level", 0.245, 0.580, "228"},
		{"level", 0.430, 0.830, "226", true},
		{"level", 0.640, 0.580, "226", true},
		{"boss", 0.755, 0.450, 7079, "Viscous Fallout", 30, 5497, 1},
		{"boss", 0.240, 0.680, 6235, "Electrocutioner 6000", 32, 6915, 1},
	},
	["228"] = {
		{"entrance", 0.870, 0.480},
		{"level", 0.488, 0.710, "229"},
		{"level", 0.273, 0.308, "229"},
		{"level", 0.445, 0.430, "227", true},
		{"boss", 0.427, 0.878, 6229, "Crowd Pummeler 9-60", 32, 6774, 1},
	},
	["229"] = {
		{"level", 0.481, 0.540, "228", true},
		{"level", 0.710, 0.773, "228", true},
		{"boss", 0.450, 0.680, 6228, "Dark Iron Ambassador", 33, 6669, 2},
		{"boss", 0.310, 0.294, 7800, "Mekgineer Thermaplugg", 34, 6980, 1},
	},
	["301"] = {
		{"entrance", 0.715, 0.837},
		{"boss", 0.810, 0.510, 6168, "Roogug", 28, 6110, 1},
		{"boss", 0.865, 0.410, 4424, "Aggem Thorncurse", 30, 6097, 1},
		{"boss", 0.570, 0.300, 4428, "Death Speaker Jargba", 30, 4644, 1},
		{"boss", 0.215, 0.300, 4420, "Overlord Ramtusk", 32, 4652, 1},
		{"boss", 0.080, 0.690, 4421, "Charlga Razorflank", 33, 4642, 1},
	},
	["302"] = {
		{"entrance", 0.840, 0.830},
		{"boss", 0.721, 0.593, 3983, "Interrogator Vishas", 32, 2044, 1},
		{"boss", 0.250, 0.560, 4543, "Bloodmage Thalnos", 34, 11396, 1},
		{"boss", 0.400, 0.660, 6489, "Ironspine", 33, 5231, 2},
		{"boss", 0.325, 0.660, 6490, "Azshir the Sleepless", 33, 5534, 2},
		{"boss", 0.400, 0.460, 6488, "Fallen Champion", 33, 5230, 2},
	},
	["303"] = {
		{"entrance", 0.130, 0.248},
		{"boss", 0.300, 0.850, 3974, "Houndmaster Loksey", 34, 2040, 1},
		{"boss", 0.835, 0.740, 6487, "Arcanist Doan", 37, 5266, 1},
	},
	["304"] = {
		{"entrance", 0.610, 0.955},
		{"boss", 0.785, 0.103, 3975, "Herod", 40, 2041, 1},
	},
	["305"] = {
		{"entrance", 0.623, 0.920},
		{"boss", 0.559, 0.243, 4542, "High Inquisitor Fairbanks", 40, 2605, 1},
		{"boss", 0.487, 0.280, 3976, "Scarlet Commander Mograine", 42, 2042, 1},
		{"boss", 0.493, 0.160, 3977, "High Inquisitor Whitemane", 42, 2043, 1},
	},
	["300"] = {
		{"entrance", 0.237, 0.190},
		{"boss", 0.855, 0.450, 7357, "Mordresh Fire Eye", 39, 8055, 1},
		{"boss", 0.350, 0.670, 8567, "Glutton", 40, 7864, 1},
		{"boss", 0.443, 0.596, 7358, "Amnennar the Coldbringer", 41, 7971, 1},
	},
	["230"] = {
		{"entrance", 0.285, 0.692},
		{"level", 0.485, 0.210, "231"},
		{"boss", 0.585, 0.910, 6906, "Baelog / Eric \"The Swift\" / Olaf", 41, 5710, 1},
		{"boss", 0.360, 0.730, 7228, "Ironaya", 40, 6089, 1},
		{"entrance", 0.680, 0.725},
	},
	["231"] = {
		{"level", 0.645, 0.410, "230", true},
		{"boss", 0.551, 0.506, 2748, "Archaedas", 47, 5988, 1},
	},
	["219"] = {
		{"entrance", 0.566, 0.901},
		{"boss", 0.440, 0.160, 7271, "Witch Doctor Zum'rah", 46, 6434, 1},
		{"boss", 0.255, 0.130, 7604, "Sergeant Bly", 45, 6433, 1},
		{"boss", 0.305, 0.400, 7273, "Gahz'rilla", 46, 7271, 1},
		{"boss", 0.334, 0.170, 7275, "Shadowpriest Sezz'ziz", 47, 6441, 1},
		{"boss", 0.440, 0.330, 7267, "Chief Ukorz Sandscalp", 48, 6439, 1},
		{"boss", 0.420, 0.360, 7797, "Ruuzlu", 46, 6687, 1},
	},
	["280"] = {
		{"entrance", 0.768, 0.657},
		{"level", 0.145, 0.570, "281"},
		{"entrance", 0.622, 0.281},
	},
	["281"] = {
		{"level", 0.295, 0.040, "280", true},
		{"boss", 0.255, 0.780, 12201, "Princess Theradras", 51, 12292, 1},
		{"boss", 0.405, 0.810, 13596, "Rotgrip", 50, 13589, 1},
	},
	["220"] = {
		{"entrance", 0.500, 0.110},
	},
	["242"] = {
		{"entrance", 0.333, 0.791},
	},
	["232"] = {
		{"entrance", 0.264, 0.226},
		{"boss", 0.840, 0.660, 12259, "Gehennas", 63, 13030, 3},
		{"boss", 0.548, 0.540, 11502, "Ragnaros", 63, 11121, 3},
	},
	["234"] = {
		{"entrance", 0.718, 0.926},
	},
	["306"] = {
		{"entrance", 0.390, 0.652},
	},
	["317"] = {
		{"entrance", 0.640, 0.880},
		{"entrance", 0.686, 0.880},
		{"level", 0.900, 0.330, "318", true},
	},
	["318"] = {
		{"level", 0.355, 0.390, "317"},
		{"level", 0.570, 0.770, "317"},
	},
}

MapUtils:AddName("deDE", "Aggem Thorncurse", "Aggem Dornfluch")
MapUtils:AddName("deDE", "Amnennar the Coldbringer", "Amnennar der Kältebringer")
MapUtils:AddName("deDE", "Arcanist Doan", "Arkanist Doan")
MapUtils:AddName("deDE", "Archmage Arugal", "Erzmagier Arugal")
MapUtils:AddName("deDE", "Azshir the Sleepless", "Azshir der Schlaflose")
MapUtils:AddName("deDE", "Baelog / Eric \"The Swift\" / Olaf", "Baelog / Eric \"Der Flinke\" / Olaf")
MapUtils:AddName("deDE", "Bloodmage Thalnos", "Blutmagier Thalnos")
MapUtils:AddName("deDE", "Bruegal Ironknuckle", "Bruegal Eisenfaust")
MapUtils:AddName("deDE", "Chief Ukorz Sandscalp", "Häuptling Ukorz Sandscalp")
MapUtils:AddName("deDE", "Commander Springvale", "Kommandant Springvale")
MapUtils:AddName("deDE", "Crowd Pummeler 9-60", "Meute-Verprügler 9-60")
MapUtils:AddName("deDE", "Dark Iron Ambassador", "Botschafter der Dunkeleisenzwerge")
MapUtils:AddName("deDE", "Death Speaker Jargba", "Todessprecher Jargba")
MapUtils:AddName("deDE", "Deathsworn Captain", "Todeshöriger Captain")
MapUtils:AddName("deDE", "Deviate Faerie Dragon", "Deviatfeendrache")
MapUtils:AddName("deDE", "Edwin VanCleef", "Edwin van Cleef")
MapUtils:AddName("deDE", "Electrocutioner 6000", "Elektrokutionator 6000")
MapUtils:AddName("deDE", "Fallen Champion", "Gestürzter Held")
MapUtils:AddName("deDE", "Fenrus the Devourer", "Fenrus der Verschlinger")
MapUtils:AddName("deDE", "Glutton", "Nimmersatt")
MapUtils:AddName("deDE", "High Inquisitor Fairbanks", "Hochinquisitor Fairbanks")
MapUtils:AddName("deDE", "High Inquisitor Whitemane", "Hochinquisitor Whitemane")
MapUtils:AddName("deDE", "Houndmaster Loksey", "Hundemeister Loksey")
MapUtils:AddName("deDE", "Interrogator Vishas", "Befrager Vishas")
MapUtils:AddName("deDE", "Ironspine", "Eisenrücken")
MapUtils:AddName("deDE", "Jergosh the Invoker", "Jergosh der Herbeirufer")
MapUtils:AddName("deDE", "Lord Cobrahn", "Lord Kobrahn")
MapUtils:AddName("deDE", "Mekgineer Thermaplugg", "Robogenieur Thermaplugg")
MapUtils:AddName("deDE", "Miner Johnson", "Minenarbeiter Johnson")
MapUtils:AddName("deDE", "Mordresh Fire Eye", "Mordresh Feuerauge")
MapUtils:AddName("deDE", "Mutanus the Devourer", "Mutanus der Verschlinger")
MapUtils:AddName("deDE", "Odo the Blindwatcher", "Odo der Blindseher")
MapUtils:AddName("deDE", "Oggleflint", "Flintauge")
MapUtils:AddName("deDE", "Overlord Ramtusk", "Oberanführer Rammhauer")
MapUtils:AddName("deDE", "Princess Theradras", "Prinzessin Theradras")
MapUtils:AddName("deDE", "Ragnaros", "Lavaexplosion")
MapUtils:AddName("deDE", "Razorclaw the Butcher", "Klingenklaue der Metzger")
MapUtils:AddName("deDE", "Rotgrip", "Faulschnapper")
MapUtils:AddName("deDE", "Scarlet Commander Mograine", "Scharlachroter Kommandant Mograine")
MapUtils:AddName("deDE", "Shadowpriest Sezz'ziz", "Schattenpriester Sezz'ziz")
MapUtils:AddName("deDE", "Sneed's Shredder / Sneed", "Sneeds Schredder / Sneed")
MapUtils:AddName("deDE", "Taragaman the Hungerer", "Taragaman der Hungerleider")
MapUtils:AddName("deDE", "Targorr the Dread", "Targorr der Schreckliche")
MapUtils:AddName("deDE", "Twilight Lord Kelris", "Twilight-Lord Kelris")
MapUtils:AddName("deDE", "Verdan the Everliving", "Verdan der Ewiglebende")
MapUtils:AddName("deDE", "Viscous Fallout", "Verflüssigte Ablagerung")
MapUtils:AddName("deDE", "Witch Doctor Zum'rah", "Hexendoktor Zum'rah")
MapUtils:AddName("deDE", "Wolf Master Nandos", "Wolfmeister Nandos")
