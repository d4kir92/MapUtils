local _, MapUtils = ...
MapUtils.INSTANCEPINS = {
	["2959"] = {
		{"level", 0.616, 0.542, "2959_2"},
		{"level", 0.513, 0.684, "2959_2"},
		{"level", 0.531, 0.365, "2959_2"},
		{"boss", 0.524, 0.840, 245999, "Arcane Anomaly", 30, 129891, 1},
		{"boss", 0.565, 0.230, 246020, "Shade of the Archmage", 33, 130061, 1},
		{"boss", 0.517, 0.551, 246003, "Fel Ancient", 32, 129894, 1},
		{"boss", 0.613, 0.424, 246017, "Unstable Sentinel", 31, 129954, 1},
		{"boss", 0.668, 0.516, 246016, "Arcanic Enigma", 30, 129900, 1},
		{"boss", 0.418, 0.729, 246008, "Mana Devourer", 31, 129895, 1},
	},
	["2959_2"] = {
		{"entrance", 0.184, 0.840},
		{"level", 0.765, 0.570, "2959", true},
		{"boss", 0.545, 0.510, 247126, "Atrexis the Grave Knight", 29, 145787, 1},
		{"boss", 0.680, 0.180, 247032, "Lyn the Ignored", 31, 130235, 2},
	},
	["2998"] = {
		{"entrance", 0.889, 0.258},
		{"boss", 0.550, 0.360, 260322, "Saltspine", false, 144209, 1},
		{"boss", 0.325, 0.700, 260326, "Relic Guardian", false, 144224, 1},
		{"boss", 0.305, 0.480, 260325, "Shadetooth", false, 144210, 1},
		{"boss", 0.770, 0.220, 260808, "Highland Horror", 28, 9010, 1},
	},
	["2999"] = {
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
		{"boss", 0.564, 0.372, 11517, "Oggleflint <Ragefire Chieftain>", 16, 11611, 1},
		{"boss", 0.406, 0.574, 11520, "Taragaman the Hungerer", 16, 7970, 1},
		{"boss", 0.338, 0.840, 11518, "Jergosh the Invoker", 16, 11429, 1},
		{"boss", 0.422, 0.857, 11519, "Bazzalan", 16, 2007, 1},
	},
	["291"] = {
		{"entrance", 0.297, 0.133},
		{"level", 0.655, 0.667, "292"},
		{"boss", 0.374, 0.610, 644, "Rhahk'Zor <The Foreman>", 19, 14403, 1},
		{"boss", 0.523, 0.510, 3586, "Miner Johnson", 19, 556, 2},
		{"boss", 0.493, 0.862, 642, "Sneed's Shredder / Sneed", 20, 1269, 1},
		{"boss", 0.607, 0.572, 1763, "Gilnid <The Smelter>", 20, 7124, 1},
	},
	["292"] = {
		{"level", 0.123, 0.883, "291", true},
		{"boss", 0.561, 0.265, 646, "Mr. Smite <The Ship's First Mate>", 20, 2026, 1},
		{"boss", 0.632, 0.389, 647, "Captain Greenskin", 20, 7113, 1},
		{"boss", 0.603, 0.455, 639, "Edwin VanCleef <Defias Kingpin>", 21, 2029, 1},
		{"boss", 0.668, 0.398, 645, "Cookie <The Ship's Cook>", 20, 1305, 1},
	},
	["279"] = {
		{"entrance", 0.463, 0.590},
		{"boss", 0.400, 0.271, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.300, 0.300, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.310, 0.430, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.460, 0.440, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.156, 0.585, 3669, "Lord Cobrahn <Fanglord>", 20, 4213, 1},
		{"boss", 0.418, 0.356, 3653, "Kresh", 20, 5126, 1},
		{"boss", 0.856, 0.299, 3670, "Lord Pythas <Fanglord>", 21, 4214, 1},
		{"boss", 0.924, 0.782, 3674, "Skum", 21, 4203, 1},
		{"boss", 0.613, 0.537, 3673, "Lord Serpentis <Fanglord>", 21, 4215, 1},
		{"boss", 0.555, 0.475, 5775, "Verdan the Everliving", 21, 4256, 1},
		{"boss", 0.642, 0.410, 5912, "Deviate Faerie Dragon", 20, 1267, 2},
		{"boss", 0.338, 0.133, 3654, "Mutanus the Devourer", 22, 4088, 1},
		{"boss", 0.300, 0.300, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.310, 0.430, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
		{"boss", 0.460, 0.440, 3671, "Lady Anacondra <Fanglord>", 20, 4313, 1},
	},
	["310"] = {
		{"entrance", 0.705, 0.606},
		{"level", 0.367, 0.392, "311"},
		{"level", 0.148, 0.866, "311"},
		{"level", 0.355, 0.666, "316", true},
		{"boss", 0.650, 0.715, 3914, "Rethilgore <The Cell Keeper>", 20, 524, 1},
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
		{"boss", 0.553, 0.627, 3927, "Wolf Master Nandos", 25, 11179, 1},
		{"boss", 0.639, 0.200, 4275, "Archmage Arugal", 26, 2353, 1},
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
		{"boss", 0.329, 0.602, 4887, "Ghamoo-ra", 25, 5027, 1},
		{"boss", 0.101, 0.360, 4831, "Lady Sarevess", 25, 4979, 1},
		{"boss", 0.536, 0.568, 6243, "Gelihast", 26, 1773, 1},
		{"boss", 0.614, 0.625, 12902, "Lorgus Jett", 26, 12822, 1},
	},
	["222"] = {
		{"level", 0.477, 0.707, "223"},
		{"level", 0.350, 0.290, "221"},
		{"boss", 0.519, 0.816, 4832, "Twilight Lord Kelris", 27, 4939, 1},
		{"boss", 0.856, 0.866, 4829, "Aku'mai", 28, 2837, 1},
	},
	["223"] = {
		{"level", 0.300, 0.612, "222", true},
		{"boss", 0.606, 0.312, 4830, "Old Serra'kis", 26, 1816, 1},
		{"boss", 0.234, 0.498, 12876, "Baron Aquanis", 28, 110, 1},
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
	},
	["228"] = {
		{"entrance", 0.870, 0.480},
		{"level", 0.488, 0.710, "229"},
		{"level", 0.273, 0.308, "229"},
		{"level", 0.445, 0.430, "227", true},
		{"boss", 0.438, 0.865, 6229, "Crowd Pummeler 9-60", 32, 6774, 1},
	},
	["229"] = {
		{"level", 0.481, 0.540, "228", true},
		{"level", 0.710, 0.773, "228", true},
		{"boss", 0.508, 0.331, 6235, "Electrocutioner 6000", 32, 6915, 1},
		{"boss", 0.295, 0.540, 6228, "Dark Iron Ambassador", 41, 6669, 2},
		{"boss", 0.313, 0.300, 7800, "Mekgineer Thermaplugg", 34, 6980, 1},
	},
	["301"] = {
		{"entrance", 0.715, 0.837},
		{"boss", 0.810, 0.510, 6168, "Roogug", 28, 6110, 1},
		{"boss", 0.865, 0.410, 4424, "Aggem Thorncurse <Death's Head Prophet>", 30, 6097, 1},
		{"boss", 0.570, 0.300, 4428, "Death Speaker Jargba <Death's Head Captain>", 30, 4644, 1},
		{"boss", 0.215, 0.300, 4420, "Overlord Ramtusk", 32, 4652, 1},
		{"boss", 0.112, 0.724, 4422, "Agathelos the Raging", 33, 2450, 1},
		{"boss", 0.110, 0.303, 4425, "Blind Hunter", 32, 4735, 2},
		{"boss", 0.080, 0.690, 4421, "Charlga Razorflank <The Crone>", 33, 4642, 1},
		{"boss", 0.494, 0.471, 4842, "Earthcaller Halmgar", 32, 6102, 2},
	},
	["302"] = {
		{"entrance", 0.840, 0.830},
		{"boss", 0.721, 0.593, 3983, "Interrogator Vishas", 32, 2044, 1},
		{"boss", 0.250, 0.560, 4543, "Bloodmage Thalnos", 34, 11396, 1},
		{"boss", 0.325, 0.660, 6490, "Azshir the Sleepless", 33, 5534, 2},
		{"boss", 0.400, 0.460, 6488, "Fallen Champion", 33, 5230, 2},
		{"boss", 0.400, 0.660, 6489, "Ironspine", 33, 5231, 2},
	},
	["303"] = {
		{"entrance", 0.130, 0.248},
		{"boss", 0.300, 0.850, 3974, "Houndmaster Loksey", 34, 2040, 1},
		{"boss", 0.835, 0.740, 6487, "Arcanist Doan", 37, 5266, 1},
	},
	["304"] = {
		{"entrance", 0.610, 0.955},
		{"boss", 0.785, 0.103, 3975, "Herod <The Scarlet Champion>", 40, 2041, 1},
	},
	["305"] = {
		{"entrance", 0.623, 0.920},
		{"boss", 0.487, 0.280, 3976, "Scarlet Commander Mograine", 42, 2042, 1},
		{"boss", 0.493, 0.160, 3977, "High Inquisitor Whitemane", 42, 2043, 1},
		{"boss", 0.559, 0.243, 4542, "High Inquisitor Fairbanks", 40, 2605, 1},
	},
	["300"] = {
		{"entrance", 0.237, 0.190},
		{"boss", 0.470, 0.200, 7356, "Plaguemaw the Rotting", 40, 6124, 1},
		{"boss", 0.857, 0.465, 7357, "Mordresh Fire Eye", 39, 8055, 1},
		{"boss", 0.350, 0.670, 8567, "Glutton", 40, 7864, 1},
		{"boss", 0.529, 0.672, 7354, "Ragglesnout", 40, 11382, 1},
		{"boss", 0.443, 0.596, 7358, "Amnennar the Coldbringer", 41, 7971, 1},
		{"boss", 0.590, 0.339, 7355, "Tuten'kash", 40, 7845, 1},
	},
	["230"] = {
		{"entrance", 0.285, 0.692},
		{"level", 0.485, 0.210, "231"},
		{"entrance", 0.680, 0.725},
		{"boss", 0.541, 0.722, 6910, "Revelosh", 40, 5945, 1},
		{"boss", 0.585, 0.910, 6906, "Baelog / Eric \"The Swift\" / Olaf", 41, 5710, 1},
		{"boss", 0.474, 0.407, 7206, "Ancient Stone Keeper", 44, 10798, 1},
		{"boss", 0.258, 0.360, 7291, "Galgann Firehammer", 45, 6059, 1},
		{"boss", 0.212, 0.248, 4854, "Grimlok <Stonevault Chieftain>", 45, 11165, 1},
		{"boss", 0.360, 0.730, 7228, "Ironaya", 40, 6089, 1},
	},
	["231"] = {
		{"level", 0.645, 0.410, "230", true},
		{"boss", 0.554, 0.506, 2748, "Archaedas <Ancient Stone Watcher>", 47, 5988, 1},
	},
	["219"] = {
		{"entrance", 0.566, 0.901},
		{"boss", 0.690, 0.256, 8127, "Antu'sul <Overseer of Sul>", 48, 7353, 1},
		{"boss", 0.554, 0.296, 7272, "Theka the Martyr", 46, 6696, 1},
		{"boss", 0.440, 0.160, 7271, "Witch Doctor Zum'rah", 46, 6434, 1},
		{"boss", 0.255, 0.130, 7604, "Sergeant Bly", 45, 6433, 1},
		{"boss", 0.289, 0.403, 7795, "Hydromancer Velratha", 46, 6685, 1},
		{"boss", 0.420, 0.360, 7797, "Ruuzlu", 46, 6687, 1},
		{"boss", 0.440, 0.330, 7267, "Chief Ukorz Sandscalp", 48, 6439, 1},
		{"boss", 0.538, 0.373, 10082, "Zerillis", 45, 9293, 2},
		{"boss", 0.463, 0.578, 10080, "Sandarr Dunereaver", 45, 9291, 2},
		{"boss", 0.317, 0.460, 10081, "Dustwraith", 45, 9292, 2},
		{"boss", 0.235, 0.183, 7796, "Nekrum Gutchewer", 46, 6690, 1},
		{"boss", 0.334, 0.170, 7275, "Shadowpriest Sezz'ziz", 47, 6441, 1},
		{"boss", 0.305, 0.400, 7273, "Gahz'rilla", 46, 7271, 1},
	},
	["280"] = {
		{"entrance", 0.768, 0.657},
		{"level", 0.145, 0.570, "281"},
		{"entrance", 0.622, 0.281},
		{"boss", 0.348, 0.107, 13282, "Noxxion", 48, 11172, 1},
		{"boss", 0.162, 0.340, 12258, "Razorlash", 48, 12389, 1},
		{"boss", 0.377, 0.694, 12236, "Lord Vyletongue", 47, 12334, 1},
		{"boss", 0.246, 0.874, 12237, "Meshlok the Harvester", 48, 9014, 2},
	},
	["281"] = {
		{"level", 0.295, 0.040, "280", true},
		{"boss", 0.245, 0.144, 12225, "Celebras the Cursed", 49, 12350, 1},
		{"boss", 0.406, 0.482, 12203, "Landslide", 50, 12293, 1},
		{"boss", 0.484, 0.686, 13601, "Tinkerer Gizlock", 50, 7125, 1},
		{"boss", 0.333, 0.771, 13596, "Rotgrip", 50, 13589, 1},
		{"boss", 0.242, 0.784, 12201, "Princess Theradras", 51, 12292, 1},
	},
	["220"] = {
		{"entrance", 0.500, 0.110},
		{"boss", 0.525, 0.450, 5721, "Dreamscythe", 53, 7553, 1},
		{"boss", 0.470, 0.450, 5720, "Weaver", 51, 6375, 1},
		{"boss", 0.451, 0.585, 5713, "Gasher", 51, 6698, 1},
		{"boss", 0.451, 0.585, 5714, "Loro", 51, 6700, 1},
		{"boss", 0.451, 0.585, 5715, "Hukku", 52, 6702, 1},
		{"boss", 0.451, 0.585, 5712, "Zolo", 51, 6699, 1},
		{"boss", 0.451, 0.585, 5717, "Mijan", 52, 6707, 1},
		{"boss", 0.451, 0.585, 5716, "Zul'Lor", 52, 6701, 1},
		{"boss", 0.760, 0.370, 5710, "Jammal'an the Prophet", 54, 6708, 1},
		{"boss", 0.767, 0.361, 5711, "Ogom the Wretched", 53, 6709, 1},
		{"boss", 0.491, 0.845, 5719, "Morphaz", 52, 7975, 1},
		{"boss", 0.448, 0.851, 5722, "Hazzas", 53, 9584, 1},
		{"boss", 0.686, 0.874, 5709, "Shade of Eranikus", 55, 7806, 1},
		{"boss", 0.501, 0.358, 8580, "Atal'alarion <Guardian of the Idol>", 50, 7873, 1},
		{"boss", 0.240, 0.457, 8443, "Avatar of Hakkar", 49, 8053, 1},
	},
	["242"] = {
		{"entrance", 0.333, 0.791},
		{"level", 0.655, 0.294, "243", true},
		{"boss", 0.494, 0.567, 9025, "Lord Roccor", 51, 5781, 1},
		{"boss", 0.475, 0.934, 9018, "High Interrogator Gerstahn <Twilight's Hammer Interrogator>", 52, 8761, 1},
		{"boss", 0.495, 0.617, 9319, "Houndmaster Grebmar", 52, 9212, 1},
		{"boss", 0.240, 0.516, 9016, "Bael'Gar", 54, 12162, 1},
		{"boss", 0.561, 0.312, 9017, "Lord Incendius", 55, 1204, 1},
		{"boss", 0.613, 0.242, 9056, "Fineous Darkvire <Chief Architect>", 54, 8704, 1},
		{"boss", 0.545, 0.700, 9024, "Pyromancer Loregrain", 52, 8762, 1},
		{"boss", 0.356, 0.570, 9033, "General Angerforge", 57, 8756, 1},
		{"boss", 0.500, 0.635, 9031, "Anub'shiah / Eviscerator / Gorosh the Dervish / Grizzle / Hedrum the Creeper / Ok'thor the Breaker", 56, 3004, 1},
	},
	["243"] = {
		{"level", 0.595, 0.547, "242"},
		{"boss", 0.607, 0.673, 9041, "Warder Stilgiss / Verek", 56, 9089, 1},
		{"boss", 0.369, 0.650, 8983, "Golem Lord Argelmach", 57, 8759, 1},
		{"boss", 0.532, 0.649, 9502, "Phalanx", 55, 8177, 1},
		{"boss", 0.491, 0.619, 9543, "Ribbly Screwspigot", 53, 8667, 1},
		{"boss", 0.498, 0.609, 9499, "Plugger Spazzring", 55, 8652, 1},
		{"boss", 0.538, 0.488, 9156, "Ambassador Flamelash", 57, 8329, 1},
		{"boss", 0.815, 0.119, 9938, "Magmus", 57, 12162, 1},
		{"boss", 0.537, 0.248, 9039, "Doom'rel / Dope'rel / Hate'rel / Seeth'rel / Vile'rel / Gloom'rel / Anger'rel", 57, 8687, 1},
		{"boss", 0.932, 0.134, 9019, "Emperor Dagran Thaurissan", 59, 8807, 1},
		{"boss", 0.930, 0.096, 8929, "Princess Moira Bronzebeard <Princess of Ironforge>", 58, 8705, 1},
		{"boss", 0.480, 0.580, 9537, "Hurley Blackbreath", 55, 8658, 1},
		{"boss", 0.505, 0.354, 8923, "Panzor the Invincible", 57, 8270, 2},
	},
	["232"] = {
		{"entrance", 0.264, 0.226, "raid"},
		{"boss", 0.660, 0.370, 12118, "Lucifron", 9999, 13031, 3},
		{"boss", 0.695, 0.230, 11982, "Magmadar", 9999, 10193, 3},
		{"boss", 0.350, 0.490, 12259, "Gehennas", 9999, 13030, 3},
		{"boss", 0.315, 0.690, 12057, "Garr", 9999, 12110, 3},
		{"boss", 0.550, 0.850, 12264, "Shazzrah", 9999, 13032, 3},
		{"boss", 0.535, 0.750, 12056, "Baron Geddon", 9999, 12129, 3},
		{"boss", 0.810, 0.820, 12098, "Sulfuron Harbinger", 9999, 13030, 3},
		{"boss", 0.685, 0.570, 11988, "Golemagg the Incinerator", 9999, 11986, 3},
		{"boss", 0.840, 0.660, 12018, "Majordomo Executus", 9999, 12029, 3},
		{"boss", 0.548, 0.540, 11502, "Ragnaros", 9999, 11121, 3},
	},
	["287"] = {
		{"entrance", 0.527, 0.836, "raid"},
		{"level", 0.435, 0.300, "288", true},
		{"level", 0.360, 0.130, "288", true},
	},
	["288"] = {
		{"level", 0.525, 0.320, "287"},
		{"level", 0.463, 0.198, "287"},
	},
	["239"] = {
		{"entrance", 0.070, 0.392},
		{"entrance", 0.164, 0.853},
		{"entrance", 0.954, 0.508},
		{"level", 0.505, 0.630, "240"},
		{"boss", 0.122, 0.310, 14354, "Pusillin", 57, 7552, 1},
		{"boss", 0.437, 0.477, 11490, "Zevrim Thornhoof", 57, 11335, 1},
	},
	["240"] = {
		{"entrance", 0.281, 0.555},
		{"level", 0.633, 0.844, "239", true},
		{"boss", 0.554, 0.269, 11492, "Alzzin the Wildshaper", 58, 14416, 1},
		{"boss", 0.533, 0.713, 13280, "Hydrospawn", 57, 5489, 1},
		{"boss", 0.576, 0.732, 14327, "Lethtendris", 57, 14378, 1},
	},
	["236"] = {
		{"entrance", 0.935, 0.721},
		{"entrance", 0.936, 0.510},
		{"level", 0.270, 0.190, "237"},
		{"level", 0.304, 0.430, "238"},
		{"boss", 0.332, 0.530, 11489, "Tendris Warpwood", 60, 14383, 1},
		{"boss", 0.212, 0.782, 11488, "Illyanna Ravenoak", 60, 11270, 1},
	},
	["237"] = {
		{"level", 0.415, 0.120, "236"},
		{"boss", 0.335, 0.436, 11487, "Magister Kalendris", 60, 14384, 1},
		{"boss", 0.322, 0.143, 11467, "Tsu'zee", 59, 11250, 1},
	},
	["238"] = {
		{"level", 0.745, 0.400, "236", true},
		{"boss", 0.350, 0.576, 11496, "Immol'thar", 61, 14173, 1},
		{"boss", 0.620, 0.230, 11486, "Prince Tortheldrin", 61, 11256, 1},
	},
	["235"] = {
		{"entrance", 0.718, 0.926},
		{"boss", 0.694, 0.752, 14326, "Guard Mol'dar", 59, 11561, 1},
		{"boss", 0.609, 0.681, 14322, "Stomper Kreeg <The Drunk>", 59, 11545, 1},
		{"boss", 0.495, 0.780, 14321, "Guard Fengus", 59, 11561, 1},
		{"boss", 0.265, 0.567, 14323, "Guard Slip'kik", 59, 11561, 1},
		{"boss", 0.318, 0.498, 14325, "Captain Kromcrush", 61, 11564, 1},
		{"boss", 0.304, 0.254, 14324, "Cho'Rush the Observer", 60, 11537, 1},
		{"boss", 0.319, 0.259, 11501, "King Gordok", 62, 11583, 1},
	},
	["306"] = {
		{"entrance", 0.390, 0.652},
	},
	["309"] = {
		{"boss", 0.406, 0.884, 10508, "Ras Frostwhisper", 62, 7919, 1},
	},
	["317"] = {
		{"entrance", 0.640, 0.880},
		{"boss", 0.392, 0.287, 10808, "Timmy the Cruel", 58, 571, 2},
		{"entrance", 0.686, 0.880},
		{"level", 0.900, 0.330, "318", true},
		{"boss", 0.815, 0.438, 10393, "Skul", 58, 2606, 2},
		{"boss", 0.847, 0.454, 10558, "Hearthsinger Forresten", 57, 10482, 2},
		{"boss", 0.729, 0.193, 10516, "The Unforgiven", 57, 10771, 1},
		{"boss", 0.304, 0.400, 11032, "Malor the Zealous", 60, 10458, 1},
		{"boss", 0.036, 0.501, 10997, "Cannon Master Willey", 60, 10674, 1},
		{"boss", 0.271, 0.751, 10811, "Archivist Galford", 60, 10544, 1},
		{"boss", 0.188, 0.837, 10813, "Balnazzar", 62, 10691, 1},
	},
	["318"] = {
		{"level", 0.355, 0.390, "317"},
		{"level", 0.570, 0.770, "317"},
		{"boss", 0.649, 0.489, 10809, "Stonespine", 60, 7856, 2},
		{"boss", 0.750, 0.468, 10436, "Baroness Anastari", 59, 10698, 1},
		{"boss", 0.564, 0.469, 10437, "Nerub'enkan", 60, 9793, 1},
		{"boss", 0.682, 0.199, 10438, "Maleki the Pallid", 61, 10546, 1},
		{"boss", 0.644, 0.752, 10435, "Magistrate Barthilas", 58, 10433, 1},
		{"boss", 0.372, 0.199, 10440, "Baron Rivendare", 62, 10729, 1},
		{"boss", 0.455, 0.200, 10439, "Ramstein the Gorger", 61, 12818, 1},
	},
	["233"] = {
		{"entrance", 0.290, 0.490, "raid"},
		{"boss", 0.390, 0.730, 14517, "High Priestess Jeklik", 9999, 15219, 3},
		{"boss", 0.515, 0.540, 14507, "High Priest Venoxis", 9999, 15217, 3},
		{"boss", 0.470, 0.770, 14510, "High Priestess Mar'li", 9999, 15220, 3},
		{"boss", 0.625, 0.680, 11382, "Bloodlord Mandokir", 9999, 11288, 3},
		{"boss", 0.600, 0.462, 15082, "Gri'lek / Hazza'rah / Renataki / Wushoolay", 9999, 8390, 3},
		{"boss", 0.535, 0.320, 15114, "Gahz'ranka", 9999, 15288, 3},
		{"boss", 0.620, 0.340, 14509, "High Priest Thekal", 9999, 15216, 3},
		{"boss", 0.475, 0.190, 14515, "High Priestess Arlokk", 9999, 15218, 3},
		{"boss", 0.310, 0.240, 11380, "Jin'do the Hexxer", 9999, 11311, 3},
		{"boss", 0.505, 0.390, 14834, "Hakkar", 9999, 15295, 3},
	},
	["248"] = {
		{"entrance", 0.341, 0.205, "raid"},
		{"boss", 0.670, 0.310, 10184, "Onyxia", 9999, 8570, 3},
	},
}

MapUtils:AddName("deDE", "Agathelos the Raging", "Agathelos der Tobende")
MapUtils:AddName("deDE", "Aggem Thorncurse <Death's Head Prophet>", "Aggem Dornfluch")
MapUtils:AddName("deDE", "Alzzin the Wildshaper", "Alzzin der Wildformer")
MapUtils:AddName("deDE", "Ambassador Flamelash", "Botschafter Flammenschlag")
MapUtils:AddName("deDE", "Amnennar the Coldbringer", "Amnennar der Kältebringer")
MapUtils:AddName("deDE", "Ancient Stone Keeper", "Uralter Steinbewahrer")
MapUtils:AddName("deDE", "Anub'shiah / Eviscerator / Gorosh the Dervish / Grizzle / Hedrum the Creeper / Ok'thor the Breaker", "Anub'shiah / Ausweider / Gorosh der Derwisch / Grizzler / Hedrum der Krabbler / Ok'thor der Zerstörer")
MapUtils:AddName("deDE", "Arcanist Doan", "Arkanist Doan")
MapUtils:AddName("deDE", "Archivist Galford", "Archivar Galford")
MapUtils:AddName("deDE", "Archmage Arugal", "Erzmagier Arugal")
MapUtils:AddName("deDE", "Avatar of Hakkar", "Avatar von Hakkar")
MapUtils:AddName("deDE", "Azshir the Sleepless", "Azshir der Schlaflose")
MapUtils:AddName("deDE", "Baelog / Eric \"The Swift\" / Olaf", "Baelog / Eric \"Der Flinke\" / Olaf")
MapUtils:AddName("deDE", "Blind Hunter", "Blinder Jäger")
MapUtils:AddName("deDE", "Bloodlord Mandokir", "Blutfürst Mandokir")
MapUtils:AddName("deDE", "Bloodmage Thalnos", "Blutmagier Thalnos")
MapUtils:AddName("deDE", "Bruegal Ironknuckle", "Bruegal Eisenfaust")
MapUtils:AddName("deDE", "Cannon Master Willey", "Kanonenmeister Willey")
MapUtils:AddName("deDE", "Celebras the Cursed", "Celebras der Verfluchte")
MapUtils:AddName("deDE", "Chief Ukorz Sandscalp", "Häuptling Ukorz Sandscalp")
MapUtils:AddName("deDE", "Cho'Rush the Observer", "Cho'Rush der Beobachter")
MapUtils:AddName("deDE", "Commander Springvale", "Kommandant Springvale")
MapUtils:AddName("deDE", "Crowd Pummeler 9-60", "Meute-Verprügler 9-60")
MapUtils:AddName("deDE", "Dark Iron Ambassador", "Botschafter der Dunkeleisenzwerge")
MapUtils:AddName("deDE", "Death Speaker Jargba <Death's Head Captain>", "Todessprecher Jargba")
MapUtils:AddName("deDE", "Deathsworn Captain", "Todeshöriger Captain")
MapUtils:AddName("deDE", "Deviate Faerie Dragon", "Deviatfeendrache")
MapUtils:AddName("deDE", "Doom'rel / Dope'rel / Hate'rel / Seeth'rel / Vile'rel / Gloom'rel / Anger'rel", "Un'rel / Trott'rel / Hass'rel / Wut'rel / Bös'rel / Dunk'rel / Zorn'rel")
MapUtils:AddName("deDE", "Dreamscythe", "Traumsense")
MapUtils:AddName("deDE", "Dustwraith", "Karaburan")
MapUtils:AddName("deDE", "Earthcaller Halmgar", "Erdenrufer Halmgar")
MapUtils:AddName("deDE", "Edwin VanCleef <Defias Kingpin>", "Edwin van Cleef")
MapUtils:AddName("deDE", "Electrocutioner 6000", "Elektrokutionator 6000")
MapUtils:AddName("deDE", "Emperor Dagran Thaurissan", "Imperator Dagran Thaurissan")
MapUtils:AddName("deDE", "Fallen Champion", "Gestürzter Held")
MapUtils:AddName("deDE", "Fenrus the Devourer", "Fenrus der Verschlinger")
MapUtils:AddName("deDE", "Galgann Firehammer", "Galgann Feuerhammer")
MapUtils:AddName("deDE", "Gasher", "Schlitzer")
MapUtils:AddName("deDE", "General Angerforge", "General Zornesschmied")
MapUtils:AddName("deDE", "Glutton", "Nimmersatt")
MapUtils:AddName("deDE", "Golem Lord Argelmach", "Golemlord Argelmach")
MapUtils:AddName("deDE", "Golemagg the Incinerator", "Golemagg der Verbrenner")
MapUtils:AddName("deDE", "Guard Fengus", "Wache Fengus")
MapUtils:AddName("deDE", "Guard Mol'dar", "Wache Mol'dar")
MapUtils:AddName("deDE", "Guard Slip'kik", "Wache Slip'kik")
MapUtils:AddName("deDE", "Hearthsinger Forresten", "Herdsinger Forresten")
MapUtils:AddName("deDE", "High Inquisitor Fairbanks", "Hochinquisitor Fairbanks")
MapUtils:AddName("deDE", "High Inquisitor Whitemane", "Hochinquisitor Whitemane")
MapUtils:AddName("deDE", "High Interrogator Gerstahn <Twilight's Hammer Interrogator>", "Verhörmeisterin Gerstahn")
MapUtils:AddName("deDE", "High Priest Thekal", "Hohepriester Thekal")
MapUtils:AddName("deDE", "High Priest Venoxis", "Hohepriester Venoxis")
MapUtils:AddName("deDE", "High Priestess Arlokk", "Hohepriesterin Arlokk")
MapUtils:AddName("deDE", "High Priestess Jeklik", "Hohepriesterin Jeklik")
MapUtils:AddName("deDE", "High Priestess Mar'li", "Hohepriesterin Mar'li")
MapUtils:AddName("deDE", "Houndmaster Grebmar", "Hundemeister Grebmar")
MapUtils:AddName("deDE", "Houndmaster Loksey", "Hundemeister Loksey")
MapUtils:AddName("deDE", "Hurley Blackbreath", "Hurley Pestatem")
MapUtils:AddName("deDE", "Hydromancer Velratha", "Wasserbeschwörerin Velratha")
MapUtils:AddName("deDE", "Hydrospawn", "Hydrobrut")
MapUtils:AddName("deDE", "Illyanna Ravenoak", "Illyanna Rabeneiche")
MapUtils:AddName("deDE", "Interrogator Vishas", "Befrager Vishas")
MapUtils:AddName("deDE", "Ironspine", "Eisenrücken")
MapUtils:AddName("deDE", "Jammal'an the Prophet", "Jammal'an der Prophet")
MapUtils:AddName("deDE", "Jergosh the Invoker", "Jergosh der Herbeirufer")
MapUtils:AddName("deDE", "Jin'do the Hexxer", "Jin'do der Verhexer")
MapUtils:AddName("deDE", "King Gordok", "König Gordok")
MapUtils:AddName("deDE", "Landslide", "Erdrutsch")
MapUtils:AddName("deDE", "Lord Cobrahn <Fanglord>", "Lord Kobrahn")
MapUtils:AddName("deDE", "Lord Vyletongue", "Lord Schlangenzunge")
MapUtils:AddName("deDE", "Magistrate Barthilas", "Magistrat Barthilas")
MapUtils:AddName("deDE", "Majordomo Executus", "Majordomus Exekutus")
MapUtils:AddName("deDE", "Maleki the Pallid", "Maleki der Leichenblasse")
MapUtils:AddName("deDE", "Malor the Zealous", "Malor der Eifrige")
MapUtils:AddName("deDE", "Mekgineer Thermaplugg", "Robogenieur Thermaplugg")
MapUtils:AddName("deDE", "Meshlok the Harvester", "Meshlok der Ernter")
MapUtils:AddName("deDE", "Miner Johnson", "Minenarbeiter Johnson")
MapUtils:AddName("deDE", "Mordresh Fire Eye", "Mordresh Feuerauge")
MapUtils:AddName("deDE", "Mutanus the Devourer", "Mutanus der Verschlinger")
MapUtils:AddName("deDE", "Nekrum Gutchewer", "Nekrum der Ausweider")
MapUtils:AddName("deDE", "Odo the Blindwatcher", "Odo der Blindseher")
MapUtils:AddName("deDE", "Oggleflint <Ragefire Chieftain>", "Flintauge")
MapUtils:AddName("deDE", "Ogom the Wretched", "Ogom der Elende")
MapUtils:AddName("deDE", "Overlord Ramtusk", "Oberanführer Rammhauer")
MapUtils:AddName("deDE", "Panzor the Invincible", "Panzor der Unbesiegbare")
MapUtils:AddName("deDE", "Plaguemaw the Rotting", "Seuchenschlund der Faulende")
MapUtils:AddName("deDE", "Prince Tortheldrin", "Prinz Tortheldrin")
MapUtils:AddName("deDE", "Princess Moira Bronzebeard <Princess of Ironforge>", "Prinzessin Moira Bronzebeard")
MapUtils:AddName("deDE", "Princess Theradras", "Prinzessin Theradras")
MapUtils:AddName("deDE", "Pyromancer Loregrain", "Pyromant Weiskorn")
MapUtils:AddName("deDE", "Ragglesnout", "Struppmähne")
MapUtils:AddName("deDE", "Ragnaros", "Lavaexplosion")
MapUtils:AddName("deDE", "Ramstein the Gorger", "Ramstein der Verschlinger")
MapUtils:AddName("deDE", "Ras Frostwhisper", "Ras Frostraunen")
MapUtils:AddName("deDE", "Razorclaw the Butcher", "Klingenklaue der Metzger")
MapUtils:AddName("deDE", "Razorlash", "Schlingwurzler")
MapUtils:AddName("deDE", "Rotgrip", "Faulschnapper")
MapUtils:AddName("deDE", "Sandarr Dunereaver", "Sandarr der Wüstenräuber")
MapUtils:AddName("deDE", "Scarlet Commander Mograine", "Scharlachroter Kommandant Mograine")
MapUtils:AddName("deDE", "Shade of Eranikus", "Eranikus' Schemen")
MapUtils:AddName("deDE", "Shadowpriest Sezz'ziz", "Schattenpriester Sezz'ziz")
MapUtils:AddName("deDE", "Sneed's Shredder / Sneed", "Sneeds Schredder / Sneed")
MapUtils:AddName("deDE", "Stomper Kreeg <The Drunk>", "Stampfer Kreeg")
MapUtils:AddName("deDE", "Stonespine", "Steinbuckel")
MapUtils:AddName("deDE", "Sulfuron Harbinger", "Sulfuronherold")
MapUtils:AddName("deDE", "Taragaman the Hungerer", "Taragaman der Hungerleider")
MapUtils:AddName("deDE", "Targorr the Dread", "Targorr der Schreckliche")
MapUtils:AddName("deDE", "Tendris Warpwood", "Tendris Wucherborke")
MapUtils:AddName("deDE", "The Unforgiven", "Der Unverziehene")
MapUtils:AddName("deDE", "Theka the Martyr", "Theka der Märtyrer")
MapUtils:AddName("deDE", "Timmy the Cruel", "Timmy der Grausame")
MapUtils:AddName("deDE", "Tinkerer Gizlock", "Tüftler Gizlock")
MapUtils:AddName("deDE", "Twilight Lord Kelris", "Twilight-Lord Kelris")
MapUtils:AddName("deDE", "Verdan the Everliving", "Verdan der Ewiglebende")
MapUtils:AddName("deDE", "Viscous Fallout", "Verflüssigte Ablagerung")
MapUtils:AddName("deDE", "Warder Stilgiss / Verek", "Wärter Stilgiss / Verek")
MapUtils:AddName("deDE", "Weaver", "Wirker")
MapUtils:AddName("deDE", "Witch Doctor Zum'rah", "Hexendoktor Zum'rah")
MapUtils:AddName("deDE", "Wolf Master Nandos", "Wolfmeister Nandos")
MapUtils:AddName("deDE", "Zevrim Thornhoof", "Zevrim Dornhuf")
