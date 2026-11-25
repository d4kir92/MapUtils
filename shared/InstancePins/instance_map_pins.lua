local _, Addon = ...
Addon.INSTANCEMAPPINS = {
    [900003002] = {
        {"boss", 0.391, 0.716, 257016}, -- Katerina the Cleaner
        {"boss", 0.662, 0.715, 255702}, -- Blazeroar
        {"level", 0.248, 0.502, 900003, true},
    },
    [900003] = {
        {"boss", 0.245, 0.180, 256236}, -- The Questioner
        {"boss", 0.354, 0.711, 255997}, -- Tidemistress Ca'zass
        {"boss", 0.644, 0.337, 255391}, -- Overseer Wrex
        {"entrance", 0.354, 0.163},
        {"level", 0.250, 0.522, 900003002, true},
    },
    [900001002] = {
        {"level", 0.300, 0.770, 900001, true},
        {"level", 0.680, 0.130, 900001, true},
        {"boss", 0.669, 0.553, 263886}, -- Primeval Elemental
    },
    [220005] = {
        {"marker", 0.400, 0.500, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "3", tip = "Southwest"},
        {"marker", 0.430, 0.300, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "5", tip = "Northwest"},
        {"marker", 0.491, 0.634, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "1", tip = "South"},
        {"marker", 0.555, 0.245, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "2", tip = "North"},
        {"marker", 0.622, 0.579, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "4", tip = "Southeast"},
        {"marker", 0.650, 0.380, "Interface\\AddOns\\AzerothCompendium\\media\\serpentstatue", label = "6", tip = "Northeast"},
    },
    [220004] = {
        {"boss", 0.609, 0.722, 8580}, -- Atal'alarion <Guardian of the Idol>
        {"questend", 0.610, 0.660, 3447}, -- Secret of the Circle
        {"questend", 0.500, 0.460, 3447}, -- Secret of the Circle
    },
    [220003] = {
        {"boss", 0.361, 0.535, 5714}, -- Loro
        {"boss", 0.431, 0.355, 5713}, -- Gasher
        {"boss", 0.431, 0.715, 5716}, -- Zul'Lor
        {"boss", 0.571, 0.355, 5715}, -- Hukku
        {"boss", 0.571, 0.715, 5717}, -- Mijan
        {"boss", 0.641, 0.535, 5712}, -- Zolo
    },
    [900001] = {
        {"boss", 0.211, 0.535, 260243}, -- Min'loth the Serpent
        {"boss", 0.349, 0.538, 260202}, -- Deathless Marrow
        {"boss", 0.516, 0.700, 258924}, -- Var'Taka
        {"boss", 0.558, 0.340, 260042}, -- Captain Dreadrise
        {"boss", 0.700, 0.541, 258905}, -- Zul'Alai
        {"entrance", 0.845, 0.522},
        {"boss", 0.435, 0.530, 264177}, -- Gill
        {"boss", 0.544, 0.810, 264172}, -- Umbra
        {"level", 0.565, 0.580, 900001002},
        {"level", 0.580, 0.830, 900001002},
    },
    [900002] = {
        {"entrance", 0.205, 0.807},
        {"boss", 0.330, 0.700, 258966}, -- Slavecrusher Grox
        {"boss", 0.397, 0.734, 258972}, -- Twilight Commander Zarmok
        {"boss", 0.405, 0.576, 258964}, -- Nar'gurk <The Corruptor>
        {"boss", 0.611, 0.440, 264773}, -- Bossman Toof
        {"boss", 0.623, 0.526, 259281}, -- War Handler Ashka
        {"boss", 0.683, 0.243, 258968}, -- Overlord Mugg
    },
    [3065] = { -- The Hall of Thanes
        {"entrance", 0.511, 0.948},
        {"boss", 0.509, 0.666, 261306}, -- Faldrim Anvilmar
        {"boss", 0.717, 0.465, 261316}, -- Magmatus
        {"boss", 0.509, 0.516, 261311}, -- Plunder
        {"boss", 0.510, 0.167, 261319}, -- Durgen Dirgehammer
    },
    [2999] = { -- Ruins of Lordaeron
        {"entrance", 0.612, 0.216},
        {"boss", 0.704, 0.389, 250483}, -- Witherfang
        {"boss", 0.606, 0.696, 250660}, -- The Baron
        {"boss", 0.382, 0.670, 256035}, -- Viktor the Vile
        {"boss", 0.406, 0.534, 250631}, -- The Abandoned
        {"boss", 0.424, 0.385, 256097}, -- Bjork
        {"boss", 0.463, 0.623, 250657}, -- Rath'mael
        {"boss", 0.344, 0.429, 255699}, -- Lordaeron Captain
        {"item", 0.347, 0.207, 275521}, -- Crest of Lordaeron
        {"item", 0.370, 0.493, 275521}, -- Crest of Lordaeron
        {"item", 0.433, 0.290, 275521}, -- Crest of Lordaeron
        {"item", 0.566, 0.596, 275521}, -- Crest of Lordaeron
        {"item", 0.591, 0.680, 280438}, -- Abominable Head
        {"item", 0.664, 0.495, 275521}, -- Crest of Lordaeron
    },
    [2998] = { -- Excavation Site: Wetlands
        {"entrance", 0.889, 0.258},
        {"boss", 0.550, 0.360, 260322}, -- Saltspine
        {"boss", 0.325, 0.700, 260326}, -- Relic Guardian
        {"boss", 0.305, 0.480, 260325}, -- Shadetooth
    },
    [2959] = { -- City of Dalaran
        {"level", 0.616, 0.542, 2959002},
        {"level", 0.513, 0.684, 2959002},
        {"level", 0.531, 0.365, 2959002},
        {"boss", 0.524, 0.840, 245999}, -- Arcane Anomaly
        {"boss", 0.565, 0.230, 246020}, -- Shade of the Archmage
        {"boss", 0.517, 0.551, 246003}, -- Fel Ancient
        {"boss", 0.613, 0.424, 246017}, -- Unstable Sentinel
        {"boss", 0.668, 0.516, 246016}, -- Arcanic Enigma
        {"boss", 0.418, 0.729, 246008}, -- Mana Devourer
    },
    [2959002] = { -- City of Dalaran - Dalaran Sewers
        {"entrance", 0.184, 0.840},
        {"level", 0.765, 0.570, 2959, true},
        {"boss", 0.545, 0.510, 247126}, -- Atrexis the Grave Knight
        {"boss", 0.680, 0.180, 247032}, -- Lyn the Ignored
    },
    [213] = { -- Ragefire Chasm
        {"entrance", 0.611, 0.072},
        {"boss", 0.557, 0.380, 11517},
        {"boss", 0.406, 0.574, 11520},
        {"boss", 0.338, 0.840, 11518},
        {"boss", 0.422, 0.857, 11519},
        {"questend", 0.578, 0.378, 5722}, -- Searching for the Lost Satchel
        {"queststart", 0.578, 0.378, 5724}, -- Returning the Lost Satchel
    },
    [291] = { -- The Deadmines
        {"entrance", 0.297, 0.133},
        {"level", 0.655, 0.667, 292},
        {"boss", 0.374, 0.610, 644},
        {"boss", 0.523, 0.510, 3586},
        {"boss", 0.493, 0.862, 642},
        {"boss", 0.607, 0.572, 1763},
        {"boss", 0.365, 0.612, 47162}, -- Glubtok
        {"boss", 0.502, 0.868, 47296}, -- Helix Gearbreaker
    },
    [292] = { -- The Deadmines - Ironclad Cove
        {"level", 0.123, 0.883, 291, true},
        {"boss", 0.531, 0.175, 646},
        {"boss", 0.604, 0.375, 647},
        {"boss", 0.604, 0.448, 639},
        {"boss", 0.668, 0.398, 645},
        {"boss", 0.125, 0.759, 43778}, -- Foe Reaper 5000
        {"boss", 0.605, 0.388, 47626}, -- Admiral Ripsnarl
        {"boss", 0.605, 0.455, 47739}, -- "Captain" Cookie
        {"boss", 0.655, 0.403, 49429}, -- Vanessa VanCleef
    },
    [279] = { -- Wailing Caverns
        {"entrance", 0.463, 0.590},
        {"boss", 0.400, 0.271, 3671},
        {"boss", 0.300, 0.300, 3671}, -- Lady Anacondra
        {"boss", 0.310, 0.430, 3671}, -- Lady Anacondra
        {"boss", 0.460, 0.440, 3671}, -- Lady Anacondra
        {"boss", 0.156, 0.585, 3669},
        {"boss", 0.418, 0.356, 3653},
        {"boss", 0.856, 0.299, 3670},
        {"boss", 0.924, 0.782, 3674},
        {"boss", 0.613, 0.537, 3673},
        {"boss", 0.555, 0.475, 5775},
        {"boss", 0.642, 0.410, 5912},
        {"boss", 0.338, 0.133, 3654},
        {"boss", 0.300, 0.300, 3671},
        {"boss", 0.310, 0.430, 3671},
        {"boss", 0.460, 0.440, 3671},
    },
    [310] = { -- Shadowfang Keep 1
        {"entrance", 0.705, 0.606},
        {"level", 0.367, 0.392, 311},
        {"level", 0.148, 0.866, 311},
        {"level", 0.355, 0.666, 316, true},
        {"boss", 0.650, 0.715, 3914}, -- Rethilgore
        {"boss", 0.278, 0.601, 4278}, -- Commander Springvale
        {"questend", 0.576, 0.573, 1098}, -- Deathstalkers in Shadowfang
        {"boss", 0.665, 0.732, 46962}, -- Baron Ashbury
    },
    [311] = { -- Shadowfang Keep 2
        {"level", 0.593, 0.121, 310, true},
        {"level", 0.273, 0.881, 310, true},
        {"boss", 0.301, 0.762, 3887}, -- Baron Silverlaine
        {"boss", 0.472, 0.277, 3886}, -- Razorclaw the Butcher
    },
    [312] = { -- Shadowfang Keep 3
        {"level", 0.516, 0.904, 316, true},
        {"level", 0.533, 0.600, 313, true},
    },
    [313] = { -- Shadowfang Keep 4
        {"level", 0.442, 0.749, 314, true},
        {"level", 0.526, 0.872, 312},
        {"boss", 0.544, 0.537, 4274}, -- Fenrus the Devourer
        {"questend", 0.624, 0.436, 1013}, -- The Book of Ur
        {"boss", 0.500, 0.480, 4627}, -- Arugal's Voidwalker
        {"boss", 0.545, 0.537, 46963}, -- Lord Walden
    },
    [315] = { -- Shadowfang Keep 6
        {"level", 0.420, 0.842, 314},
        {"boss", 0.553, 0.627, 3927}, -- Wolf Master Nandos
        {"boss", 0.639, 0.200, 4275},
        {"boss", 0.685, 0.335, 46964}, -- Lord Godfrey
    },
    [316] = { -- Shadowfang Keep 7
        {"level", 0.239, 0.745, 310},
        {"level", 0.436, 0.331, 312, true},
        {"boss", 0.595, 0.820, 4279}, -- Odo the Blindwatcher
        {"boss", 0.690, 0.770, 3872}, -- Deathsworn Captain
    },
    [225] = { -- The Stockade
        {"entrance", 0.500, 0.815},
        {"boss", 0.440, 0.446, 1696},
        {"boss", 0.691, 0.300, 1666},
        {"boss", 0.780, 0.454, 1717},
        {"boss", 0.745, 0.562, 1716},
        {"boss", 0.213, 0.260, 1663},
        {"boss", 0.497, 0.222, 1720},
    },
    [221] = { -- Blackfathom Deeps 1
        {"entrance", 0.453, 0.108},
        {"level", 0.621, 0.741, 222},
        {"boss", 0.328, 0.602, 4887}, -- Ghamoo-ra
        {"boss", 0.111, 0.400, 4831}, -- Lady Sarevess
        {"boss", 0.542, 0.568, 6243}, -- Gelihast
        {"boss", 0.615, 0.630, 12902},
        {"boss", 0.670, 0.660, 12902},
        {"queststart", 0.210, 0.730, 6561}, -- Blackfathom Villainy
    },
    [222] = { -- Blackfathom Deeps 2
        {"level", 0.477, 0.707, 223},
        {"level", 0.350, 0.290, 221},
        {"boss", 0.519, 0.816, 4832},
        {"boss", 0.856, 0.866, 4829},
        {"boss", 0.334, 0.695, 12902},
        {"boss", 0.390, 0.220, 12902},
        {"boss", 0.440, 0.240, 12902},
        {"boss", 0.437, 0.740, 12876},
        {"questend", 0.414, 0.753, 6921, hint = "Is underwater"}, -- Amongst the Ruins
    },
    [223] = { -- Blackfathom Deeps 3
        {"level", 0.300, 0.612, 222, true},
        {"boss", 0.606, 0.312, 4830},
    },
    [226] = { -- Gnomeregan - The Hall of Gears
        {"entrance", 0.644, 0.275},
        {"level", 0.345, 0.640, 227},
        {"level", 0.470, 0.870, 227},
        {"level", 0.551, 0.440, 227},
        {"boss", 0.770, 0.670, 7361},
    },
    [302] = { -- Scarlet Monastery - Graveyard
        {"entrance", 0.840, 0.830},
        {"boss", 0.721, 0.593, 3983},
        {"boss", 0.250, 0.560, 4543},
        {"boss", 0.325, 0.660, 6490},
        {"boss", 0.400, 0.460, 6488},
        {"boss", 0.400, 0.660, 6489},
        {"queststart", 0.722, 0.570, 1051}, -- Vorrel's Revenge
    },
    [303] = { -- Scarlet Monastery - Library
        {"entrance", 0.130, 0.248},
        {"boss", 0.300, 0.850, 3974},
        {"boss", 0.835, 0.740, 6487},
        {"questend", 0.452, 0.317, 1160}, -- Test of Lore
        {"questend", 0.820, 0.150, 1049}, -- Compendium of the Fallen
    },
    [304] = { -- Scarlet Monastery - Armory
        {"entrance", 0.610, 0.955},
        {"boss", 0.785, 0.103, 3975},
    },
    [305] = { -- Scarlet Monastery - Cathedral
        {"entrance", 0.623, 0.920},
        {"boss", 0.487, 0.280, 3976},
        {"boss", 0.493, 0.160, 3977},
        {"boss", 0.559, 0.243, 4542},
    },
    [301] = { -- Razorfen Kraul
        {"entrance", 0.715, 0.837},
        {"boss", 0.810, 0.510, 6168},
        {"boss", 0.865, 0.410, 4424},
        {"boss", 0.570, 0.300, 4428},
        {"boss", 0.215, 0.300, 4420},
        {"boss", 0.112, 0.724, 4422},
        {"boss", 0.110, 0.303, 4425},
        {"boss", 0.080, 0.690, 4421},
        {"boss", 0.494, 0.471, 4842},
        {"queststart", 0.370, 0.308, 1142}, -- Mortality Wanes
        {"queststart", 0.370, 0.332, 1144}, -- Willix the Importer
    },
    [300] = { -- Razorfen Downs
        {"entrance", 0.237, 0.190},
        {"boss", 0.470, 0.200, 7356}, -- Plaguemaw the Rotting
        {"boss", 0.857, 0.465, 7357},
        {"boss", 0.350, 0.670, 8567},
        {"boss", 0.529, 0.672, 7354},
        {"boss", 0.443, 0.596, 7358},
        {"boss", 0.590, 0.339, 7355},
        {"questend", 0.490, 0.210, 3525}, -- Extinguishing the Idol
        {"questend", 0.780, 0.170, 3523}, -- Scourge of the Downs
        {"queststart", 0.780, 0.170, 3523}, -- Scourge of the Downs
        {"queststart", 0.780, 0.170, 3525}, -- Extinguishing the Idol
    },
    [280] = { -- Maraudon - Caverns of Maraudon
        {"entrance", 0.768, 0.657},
        {"level", 0.145, 0.570, 281},
        {"entrance", 0.622, 0.281},
        {"boss", 0.348, 0.107, 13282},
        {"boss", 0.162, 0.340, 12258},
        {"boss", 0.377, 0.694, 12236},
        {"boss", 0.246, 0.874, 12237},
    },
    [230] = { -- Uldaman - Hall of the Keepers
        {"entrance", 0.285, 0.692},
        {"level", 0.485, 0.210, 231},
        {"entrance", 0.680, 0.725},
        {"boss", 0.541, 0.722, 6910},
        {"boss", 0.585, 0.910, 6906},
        {"boss", 0.474, 0.407, 7206},
        {"boss", 0.258, 0.360, 7291},
        {"boss", 0.212, 0.248, 4854},
        {"boss", 0.360, 0.730, 7228},
        {"boss", 0.474, 0.407, 4857}, -- Stone Keeper
        {"questend", 0.237, 0.271, 2339}, -- Find the Gems and Power Source
        {"questend", 0.533, 0.640, 2284}, -- Necklace Recovery, Take 2
        {"questend", 0.604, 0.939, 2339}, -- Find the Gems and Power Source
        {"queststart", 0.533, 0.640, 2318}, -- Translating the Journal
        {"boss", 0.289, 0.597, 7023}, -- Obsidian Sentinel
    },
    [219] = { -- Zul'Farrak
        {"entrance", 0.566, 0.901},
        {"boss", 0.690, 0.256, 8127},
        {"boss", 0.554, 0.296, 7272},
        {"boss", 0.440, 0.160, 7271},
        {"boss", 0.255, 0.130, 7604},
        {"boss", 0.289, 0.403, 7795},
        {"boss", 0.420, 0.360, 7797},
        {"boss", 0.440, 0.330, 7267},
        {"boss", 0.538, 0.373, 10082},
        {"boss", 0.463, 0.578, 10080},
        {"boss", 0.317, 0.460, 10081},
        {"boss", 0.235, 0.183, 7796},
        {"boss", 0.334, 0.170, 7275},
        {"boss", 0.305, 0.400, 7273},
        {"boss", 0.440, 0.160, 220076}, -- Witch Doctor Zum'rah
    },
    [317] = { -- Stratholme - Crusader's Square
        {"entrance", 0.640, 0.880},
        {"boss", 0.392, 0.287, 10808},
        {"entrance", 0.686, 0.880},
        {"level", 0.900, 0.330, 318, true},
        {"boss", 0.815, 0.438, 10393},
        {"boss", 0.847, 0.454, 10558},
        {"boss", 0.729, 0.193, 10516},
        {"boss", 0.304, 0.400, 11032},
        {"boss", 0.036, 0.501, 10997},
        {"boss", 0.271, 0.751, 10811},
        {"boss", 0.188, 0.837, 10813},
        {"boss", 0.558, 0.684, 11143}, -- Postmaster Malown
    },
    [220] = { -- The Temple of Atal'Hakkar
        {"entrance", 0.499, 0.107},
        {"boss", 0.525, 0.550, 5721}, -- Dreamscythe
        {"boss", 0.470, 0.550, 5720}, -- Weaver
        {"boss", 0.740, 0.370, 5710}, -- Jammal'an the Prophet
        {"boss", 0.784, 0.370, 5711}, -- Ogom the Wretched
        {"boss", 0.491, 0.845, 5719},
        {"boss", 0.448, 0.851, 5722},
        {"boss", 0.666, 0.874, 5709}, -- Shade of Eranikus
        {"boss", 0.240, 0.457, 8443},
    },
    [242] = { -- Blackrock Depths - Detention Block
        {"entrance", 0.333, 0.791},
        {"level", 0.655, 0.294, 243, true},
        {"boss", 0.494, 0.567, 9025},
        {"boss", 0.475, 0.934, 9018},
        {"boss", 0.495, 0.617, 9319},
        {"boss", 0.240, 0.516, 9016},
        {"boss", 0.561, 0.312, 9017},
        {"boss", 0.613, 0.242, 9056},
        {"boss", 0.545, 0.700, 9024},
        {"boss", 0.356, 0.570, 9033},
        {"boss", 0.500, 0.635, 9031},
    },
    [250] = { -- Blackrock Spire - Tazz'Alor
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 251},
        {"boss", 0.275, 0.190, 9219}, -- Spirestone Butcher
        {"boss", 0.350, 0.190, 9218}, -- Spirestone Battle Lord
        {"boss", 0.425, 0.190, 9217}, -- Spirestone Lord Magus
        {"boss", 0.500, 0.190, 9596}, -- Bannok Grimaxe
        {"boss", 0.575, 0.190, 10376}, -- Crystal Fang
        {"boss", 0.050, 0.300, 9718}, -- Ghok Bashguud
        {"boss", 0.125, 0.300, 9816}, -- Pyroguard Emberseer
        {"boss", 0.200, 0.300, 10264}, -- Solakar Flamewreath
        {"boss", 0.275, 0.300, 10899}, -- Goraluk Anvilcrack
        {"boss", 0.350, 0.300, 10509}, -- Jed Runewatcher
        {"boss", 0.425, 0.300, 10429}, -- Warchief Rend Blackhand
        {"boss", 0.500, 0.300, 10339}, -- Gyth
        {"boss", 0.575, 0.300, 10430}, -- The Beast
        {"boss", 0.050, 0.410, 10363}, -- General Drakkisath
        {"boss", 0.525, 0.545, 9237}, -- War Master Voone
    },
    [306] = { -- Scholomance - The Reliquary
        {"entrance", 0.390, 0.652},
        {"level", 0.125, 0.080, 307},
        {"boss", 0.200, 0.080, 14861}, -- Blood Steward of Kirtonos
        {"boss", 0.350, 0.080, 10503}, -- Jandice Barov
        {"boss", 0.500, 0.080, 14516}, -- Death Knight Darkreaver
    },
    [232] = { -- Molten Core
        {"entrance", 0.264, 0.226},
        {"boss", 0.660, 0.370, 12118}, -- Lucifron
        {"boss", 0.695, 0.230, 11982}, -- Magmadar
        {"boss", 0.350, 0.490, 12259}, -- Gehennas
        {"boss", 0.315, 0.690, 12057}, -- Garr
        {"boss", 0.550, 0.850, 12264}, -- Shazzrah
        {"boss", 0.535, 0.750, 12056}, -- Baron Geddon
        {"boss", 0.810, 0.820, 12098}, -- Sulfuron Harbinger
        {"boss", 0.685, 0.570, 11988}, -- Golemagg the Incinerator
        {"boss", 0.840, 0.660, 12018}, -- Majordomo Executus
        {"boss", 0.548, 0.540, 11502}, -- Ragnaros
    },
    [248] = { -- Onyxia's Lair
        {"entrance", 0.341, 0.205},
        {"boss", 0.670, 0.310, 10184}, -- Onyxia
    },
    [287] = { -- Blackwing Lair - Dragonmaw Garrison
        {"entrance", 0.527, 0.836},
        {"level", 0.435, 0.300, 288, true},
        {"level", 0.360, 0.130, 288, true},
        {"boss", 0.419, 0.602, 12435}, -- Razorgore the Untamed
        {"boss", 0.333, 0.275, 13020}, -- Vaelastrasz the Corrupt
    },
    [233] = { -- Zul'Gurub
        {"entrance", 0.290, 0.490},
        {"boss", 0.390, 0.730, 14517}, -- High Priestess Jeklik
        {"boss", 0.515, 0.540, 14507}, -- High Priest Venoxis
        {"boss", 0.470, 0.770, 14510}, -- High Priestess Mar'li
        {"boss", 0.625, 0.680, 11382}, -- Bloodlord Mandokir
        {"boss", 0.600, 0.462, 15082}, -- Gri'lek / Hazza'rah / Renataki / Wushoolay
        {"boss", 0.535, 0.320, 15114}, -- Gahz'ranka
        {"boss", 0.620, 0.340, 14509}, -- High Priest Thekal
        {"boss", 0.475, 0.190, 14515}, -- High Priestess Arlokk
        {"boss", 0.310, 0.240, 11380}, -- Jin'do the Hexxer
        {"boss", 0.505, 0.390, 14834}, -- Hakkar
    },
    [247] = { -- Ruins of Ahn'Qiraj
        {"entrance", 0.050, 0.080},
        {"boss", 0.564, 0.357, 15348}, -- Kurinnaxx
        {"boss", 0.584, 0.491, 15341}, -- General Rajaxx
        {"boss", 0.329, 0.361, 15340}, -- Moam
        {"boss", 0.698, 0.621, 15370}, -- Buru the Gorger
        {"boss", 0.617, 0.905, 15369}, -- Ayamiss the Hunter
        {"boss", 0.429, 0.696, 15339}, -- Ossirian the Unscarred
    },
    [319] = { -- Temple of Ahn'Qiraj - The Hive Undergrounds
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 320},
        {"boss", 0.285, 0.497, 15544}, -- Vem / Lord Kri / Princess Yauj
        {"boss", 0.446, 0.336, 15516}, -- Battleguard Sartura
        {"boss", 0.623, 0.219, 15510}, -- Fankriss the Unyielding
        {"boss", 0.721, 0.179, 15299}, -- Viscidus
        {"boss", 0.435, 0.504, 15509}, -- Princess Huhuran
        {"boss", 0.607, 0.697, 15276}, -- Emperor Vek'lor / Emperor Vek'nilash
        {"boss", 0.302, 0.819, 15517}, -- Ouro
    },
    [162] = { -- Naxxramas - The Construct Quarter
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 163},
        {"boss", 0.541, 0.417, 16028}, -- Patchwerk
        {"boss", 0.616, 0.532, 15931}, -- Grobbulus
        {"boss", 0.463, 0.438, 15932}, -- Gluth
        {"boss", 0.266, 0.146, 15928}, -- Thaddius
    },
    [314] = { -- Shadowfang Keep - Upper Observatory
        {"level", 0.437, 0.743, 315, true},
        {"level", 0.490, 0.780, 313},
    },
    [227] = { -- Gnomeregan - The Dormitory
        {"level", 0.245, 0.580, 228},
        {"level", 0.430, 0.830, 226, true},
        {"level", 0.640, 0.580, 226, true},
        {"boss", 0.755, 0.450, 7079},
        {"boss", 0.242, 0.678, 6235},
        {"questend", 0.620, 0.630, 2945}, -- Grime-Encrusted Ring
        {"queststart", 0.660, 0.620, 2951}, -- The Sparklematic 5200!
        {"queststart", 0.670, 0.690, 2949}, -- Return of the Ring
        {"queststart", 0.840, 0.790, 2904}, -- A Fine Mess
    },
    [228] = { -- Gnomeregan - Launch Bay
        {"entrance", 0.870, 0.480},
        {"level", 0.488, 0.710, 229},
        {"level", 0.273, 0.308, 229},
        {"level", 0.445, 0.430, 227, true},
        {"boss", 0.438, 0.865, 6229},
    },
    [229] = { -- Gnomeregan - Tinkers' Court
        {"level", 0.481, 0.540, 228, true},
        {"level", 0.710, 0.773, 228, true},
        {"boss", 0.465, 0.640, 6228},
        {"boss", 0.313, 0.300, 7800},
        {"questend", 0.350, 0.180, 2841}, -- Rig Wars
    },
    [231] = { -- Uldaman - Khaz'Goroth's Seat
        {"level", 0.645, 0.410, 230, true},
        {"boss", 0.554, 0.506, 2748},
        {"questend", 0.500, 0.340, 2278}, -- The Platinum Discs
        {"queststart", 0.500, 0.340, 2278}, -- The Platinum Discs
    },
    [281] = { -- Maraudon - Zaetar's Grave
        {"level", 0.295, 0.040, 280, true},
        {"boss", 0.245, 0.144, 12225},
        {"boss", 0.406, 0.482, 12203},
        {"boss", 0.484, 0.686, 13601},
        {"boss", 0.413, 0.811, 13596}, -- Rotgrip
        {"boss", 0.242, 0.784, 12201},
    },
    [243] = { -- Blackrock Depths - Shadowforge City
        {"level", 0.595, 0.547, 242},
        {"boss", 0.607, 0.673, 9041},
        {"boss", 0.369, 0.650, 8983},
        {"boss", 0.532, 0.649, 9502},
        {"boss", 0.491, 0.619, 9543},
        {"boss", 0.498, 0.609, 9499},
        {"boss", 0.538, 0.488, 9156},
        {"boss", 0.815, 0.119, 9938},
        {"boss", 0.537, 0.248, 9039},
        {"boss", 0.932, 0.134, 9019},
        {"boss", 0.930, 0.096, 8929},
        {"boss", 0.480, 0.580, 9537},
        {"boss", 0.505, 0.354, 8923},
    },
    [251] = { -- Blackrock Spire - Skitterweb Tunnels
        {"level", 0.125, 0.080, 252},
        {"boss", 0.553, 0.693, 9236}, -- Shadow Hunter Vosh'gajin
        {"boss", 0.621, 0.741, 10596}, -- Mother Smolderweb
    },
    [252] = { -- Blackrock Spire - Hordemar City
        {"level", 0.125, 0.080, 253},
        {"boss", 0.387, 0.590, 9196}, -- Highlord Omokk
    },
    [253] = { -- Blackrock Spire - Hall of Blackhand
        {"level", 0.125, 0.080, 254},
        {"boss", 0.455, 0.557, 10584}, -- Urok Doomhowl
    },
    [254] = { -- Blackrock Spire - Halycon's Lair
        {"level", 0.125, 0.080, 255},
        {"boss", 0.540, 0.844, 9736}, -- Quartermaster Zigris
        {"boss", 0.380, 0.840, 10220}, -- Halycon
        {"boss", 0.395, 0.793, 10268}, -- Gizrul the Slavener
    },
    [255] = { -- Blackrock Spire - Chamber of Battle
        {"level", 0.125, 0.080, 254},
        {"boss", 0.575, 0.600, 9568}, -- Overlord Wyrmthalak
    },
    [288] = { -- Blackwing Lair - Halls of Strife
        {"level", 0.525, 0.320, 287},
        {"level", 0.463, 0.198, 287},
    },
    [289] = { -- Blackwing Lair - Crimson Laboratories
        {"level", 0.125, 0.080, 290},
        {"boss", 0.506, 0.617, 12017}, -- Broodlord Lashlayer
        {"boss", 0.464, 0.430, 11983}, -- Firemaw
        {"boss", 0.349, 0.210, 14601}, -- Ebonroc
    },
    [290] = { -- Blackwing Lair - Nefarian's Lair
        {"level", 0.125, 0.080, 289},
        {"boss", 0.355, 0.371, 11981}, -- Flamegor
        {"boss", 0.394, 0.726, 14020}, -- Chromaggus
        {"boss", 0.704, 0.725, 11583}, -- Nefarian
    },
    [235] = { -- Dire Maul - Gordok Commons
        {"entrance", 0.718, 0.926},
        {"boss", 0.694, 0.752, 14326},
        {"boss", 0.609, 0.681, 14322},
        {"boss", 0.495, 0.780, 14321},
        {"boss", 0.265, 0.567, 14323},
        {"boss", 0.318, 0.498, 14325},
        {"boss", 0.304, 0.254, 14324},
        {"boss", 0.319, 0.259, 11501},
    },
    [236] = { -- Dire Maul - Capital Gardens
        {"entrance", 0.935, 0.721},
        {"entrance", 0.936, 0.510},
        {"level", 0.270, 0.190, 237},
        {"level", 0.304, 0.430, 238},
        {"boss", 0.332, 0.530, 11489},
        {"boss", 0.212, 0.782, 11488},
    },
    [237] = { -- Dire Maul - Court of the Highborne
        {"level", 0.415, 0.120, 236},
        {"boss", 0.335, 0.436, 11487},
        {"boss", 0.322, 0.143, 11467},
    },
    [238] = { -- Dire Maul - Prison of Immol'Thar
        {"level", 0.745, 0.400, 236, true},
        {"boss", 0.350, 0.576, 11496},
        {"boss", 0.620, 0.230, 11486},
    },
    [239] = { -- Dire Maul - Warpwood Quarter
        {"entrance", 0.070, 0.392},
        {"entrance", 0.164, 0.853},
        {"entrance", 0.954, 0.508},
        {"level", 0.505, 0.630, 240},
        {"boss", 0.122, 0.310, 14354},
        {"boss", 0.437, 0.477, 11490},
    },
    [240] = { -- Dire Maul - The Shrine of Eldretharr
        {"entrance", 0.281, 0.555},
        {"level", 0.633, 0.844, 239, true},
        {"boss", 0.554, 0.269, 11492},
        {"boss", 0.533, 0.713, 13280},
        {"boss", 0.576, 0.732, 14327},
    },
    [307] = { -- Scholomance - Chamber of Summoning
        {"level", 0.125, 0.080, 308},
        {"boss", 0.445, 0.650, 10433}, -- Marduk Blackpool
        {"boss", 0.490, 0.650, 10432}, -- Vectus
        {"boss", 0.495, 0.100, 10506}, -- Kirtonos the Herald
    },
    [308] = { -- Scholomance - The Upper Study
        {"level", 0.125, 0.080, 309},
        {"boss", 0.315, 0.650, 11622}, -- Rattlegore
        {"boss", 0.722, 0.220, 10901}, -- Lorekeeper Polkelt
        {"boss", 0.727, 0.700, 10505}, -- Instructor Malicia
        {"boss", 0.885, 0.460, 11261}, -- Doctor Theolen Krastinov <The Butcher>
    },
    [309] = { -- Scholomance - Headmaster's Study
        {"level", 0.125, 0.080, 308},
        {"boss", 0.406, 0.884, 10508},
        {"boss", 0.670, 0.300, 1853}, -- Darkmaster Gandling
        {"boss", 0.675, 0.140, 10502}, -- Lady Illucia Barov
        {"boss", 0.675, 0.480, 10507}, -- The Ravenian
        {"boss", 0.800, 0.294, 10504}, -- Lord Alexei Barov
    },
    [318] = { -- Stratholme - The Gauntlet
        {"level", 0.355, 0.390, 317},
        {"level", 0.570, 0.770, 317},
        {"boss", 0.649, 0.489, 10809},
        {"boss", 0.750, 0.468, 10436},
        {"boss", 0.564, 0.469, 10437},
        {"boss", 0.682, 0.199, 10438},
        {"boss", 0.644, 0.752, 10435},
        {"boss", 0.372, 0.199, 10440},
        {"boss", 0.455, 0.200, 10439},
    },
    [320] = { -- Temple of Ahn'Qiraj - The Temple Gates
        {"level", 0.125, 0.080, 321},
        {"boss", 0.458, 0.522, 15263}, -- The Prophet Skeram
    },
    [321] = { -- Temple of Ahn'Qiraj - Vault of C'Thun
        {"level", 0.125, 0.080, 320},
        {"boss", 0.571, 0.625, 15727}, -- C'Thun
    },
    [163] = { -- Naxxramas - The Arachnid Quarter
        {"level", 0.125, 0.080, 164},
        {"boss", 0.307, 0.470, 15956}, -- Anub'Rekhan
        {"boss", 0.442, 0.361, 15953}, -- Grand Widow Faerlina
        {"boss", 0.686, 0.153, 15952}, -- Maexxna
    },
    [164] = { -- Naxxramas - The Military Quarter
        {"level", 0.125, 0.080, 165},
        {"boss", 0.427, 0.460, 16061}, -- Instructor Razuvious
        {"boss", 0.675, 0.596, 16060}, -- Gothik the Harvester
        {"boss", 0.301, 0.768, 16064}, -- Thane Korth'azz / Lady Blaumeux / Sir Zeliek / Highlord Mograine
    },
    [165] = { -- Naxxramas - The Plague Quarter
        {"level", 0.125, 0.080, 166},
        {"boss", 0.346, 0.565, 15954}, -- Noth the Plaguebringer
        {"boss", 0.498, 0.457, 15936}, -- Heigan the Unclean
        {"boss", 0.760, 0.284, 16011}, -- Loatheb
    },
    [166] = { -- Naxxramas - The Lower Necropolis
        {"level", 0.125, 0.080, 167},
    },
    [167] = { -- Naxxramas - The Upper Necropolis
        {"level", 0.125, 0.080, 166},
        {"boss", 0.565, 0.675, 15989}, -- Sapphiron
        {"boss", 0.365, 0.223, 15990}, -- Kel'Thuzad
    },
    [347] = { -- Hellfire Ramparts
        {"boss", 0.730, 0.314, 17306}, -- Watchkeeper Gargolmar
        {"boss", 0.391, 0.205, 17308}, -- Omor the Unscarred
        {"boss", 0.355, 0.828, 17537}, -- Nazan & Vazruden
    },
    [261] = { -- The Blood Furnace
        {"boss", 0.387, 0.418, 17381}, -- The Maker
        {"boss", 0.433, 0.219, 17380}, -- Broggok
        {"boss", 0.583, 0.412, 17377}, -- Keli'dan the Breaker
    },
    [246] = { -- The Shattered Halls
        {"boss", 0.333, 0.621, 16807}, -- Grand Warlock Nethekurse
        {"boss", 0.297, 0.147, 20923}, -- Blood Guard Porung
        {"boss", 0.542, 0.342, 16809}, -- Warbringer O'mrogg
        {"boss", 0.673, 0.545, 16808}, -- Warchief Kargath Bladefist
    },
    [272] = { -- Mana-Tombs
        {"boss", 0.480, 0.297, 18341}, -- Pandemonius
        {"boss", 0.609, 0.742, 18343}, -- Tavarok
        {"boss", 0.357, 0.609, 22930}, -- Yor
        {"boss", 0.324, 0.492, 18344}, -- Nexus-Prince Shaffar
    },
    [257] = { -- Auchenai Crypts - 257
        {"boss", 0.463, 0.680, 18371}, -- Shirrak the Dead Watcher
        {"boss", 0.739, 0.508, 18373}, -- Exarch Maladaar
    },
    [258] = { -- Sethekk Halls - 258
        {"boss", 0.488, 0.680, 18472}, -- Darkweaver Syth
    },
    [259] = { -- Sethekk Halls - 259
        {"boss", 0.327, 0.545, 23035}, -- Anzu
        {"boss", 0.327, 0.277, 18473}, -- Talon King Ikiss
    },
    [260] = { -- Shadow Labyrinth
        {"boss", 0.219, 0.395, 18731}, -- Ambassador Hellmaw
        {"boss", 0.268, 0.705, 18667}, -- Blackheart the Inciter
        {"boss", 0.531, 0.541, 18732}, -- Grandmaster Vorpil
        {"boss", 0.809, 0.391, 18708}, -- Murmur
    },
    [265] = { -- The Slave Pens
        {"boss", 0.490, 0.270, 17941}, -- Mennu the Betrayer
        {"boss", 0.581, 0.406, 17991}, -- Rokmar the Crackler
        {"boss", 0.821, 0.768, 17942}, -- Quagmirran
    },
    [262] = { -- The Underbog
        {"boss", 0.694, 0.900, 17770}, -- Hungarfen
        {"boss", 0.787, 0.289, 18105}, -- Ghaz'an
        {"boss", 0.415, 0.242, 17826}, -- Swamplord Musel'ek
        {"boss", 0.247, 0.457, 17882}, -- The Black Stalker
    },
    [263] = { -- The Steamvault - 263
        {"boss", 0.542, 0.137, 17797}, -- Hydromancer Thespia
        {"boss", 0.342, 0.820, 17796}, -- Mekgineer Steamrigger
        {"boss", 0.760, 0.436, 17798}, -- Warlord Kalithresh
    },
    [274] = { -- Old Hillsbrad Foothills
        {"boss", 0.754, 0.662, 17848}, -- Lieutenant Drake
        {"boss", 0.691, 0.697, 17862}, -- Captain Skarloc
        {"boss", 0.508, 0.320, 18096}, -- Epoch Hunter
    },
    [273] = { -- The Black Morass
        {"boss", 0.451, 0.621, 17879}, -- Chrono Lord Deja
        {"boss", 0.549, 0.619, 17880}, -- Temporus
        {"boss", 0.481, 0.746, 17881}, -- Aeonus
    },
    [269] = { -- The Arcatraz - 269
        {"boss", 0.593, 0.244, 20870}, -- Zereketh the Unbound
    },
    [270] = { -- The Arcatraz - 270
        {"boss", 0.363, 0.783, 20885}, -- Dalliah the Doomsayer
        {"boss", 0.199, 0.787, 20886}, -- Wrath-Scryer Soccothrates
    },
    [271] = { -- The Arcatraz - 271
        {"boss", 0.616, 0.307, 20912}, -- Harbinger Skyriss
    },
    [266] = { -- The Botanica
        {"boss", 0.443, 0.234, 17976}, -- Commander Sarannis
        {"boss", 0.242, 0.227, 17975}, -- High Botanist Freywinn
        {"boss", 0.074, 0.482, 17978}, -- Thorngrin the Tender
        {"boss", 0.340, 0.863, 17980}, -- Laj
        {"boss", 0.343, 0.369, 17977}, -- Warp Splinter
    },
    [267] = { -- The Mechanar - 267
        {"boss", 0.514, 0.316, 19219}, -- Mechano-Lord Capacitus
    },
    [268] = { -- The Mechanar - 268
        {"boss", 0.478, 0.203, 19221}, -- Nethermancer Sepethrea
        {"boss", 0.272, 0.611, 19220}, -- Pathaleon the Calculator
    },
    [348] = { -- Magisters' Terrace - 348
        {"boss", 0.398, 0.557, 24560}, -- Priestess Delrissa
        {"boss", 0.086, 0.502, 24664}, -- Kael'thas Sunstrider
    },
    [349] = { -- Magisters' Terrace - 349
        {"boss", 0.425, 0.223, 24723}, -- Selin Fireheart
        {"boss", 0.835, 0.264, 24744}, -- Vexallus
    },
    [350] = { -- Karazhan - 350
        {"boss", 0.453, 0.826, 16152}, -- Attumen the Huntsman
        {"boss", 0.551, 0.288, 16181}, -- Rokad the Ravager
        {"boss", 0.596, 0.238, 16180}, -- Shadikith the Glider
        {"boss", 0.641, 0.288, 16179}, -- Hyakiss the Lurker
    },
    [352] = { -- Karazhan - 352
        {"boss", 0.271, 0.635, 15687}, -- Moroes
    },
    [353] = { -- Karazhan - 353
        {"boss", 0.834, 0.500, 16457}, -- Maiden of Virtue
        {"boss", 0.181, 0.351, 17521}, -- The Big Bad Wolf
        {"boss", 0.231, 0.351, 18168}, -- The Wizard of Oz
        {"boss", 0.131, 0.351, 17533}, -- Romulo and Julianne
    },
    [358] = { -- Karazhan - 358
        {"boss", 0.495, 0.366, 15691}, -- The Curator
    },
    [359] = { -- Karazhan - 359
        {"boss", 0.716, 0.260, 16524}, -- Shade of Aran
    },
    [360] = { -- Karazhan - 360
        {"boss", 0.526, 0.697, 15688}, -- Terestian Illhoof
    },
    [362] = { -- Karazhan - 362
        {"boss", 0.359, 0.418, 15689}, -- Netherspite
    },
    [366] = { -- Karazhan - 366
        {"boss", 0.514, 0.309, 15690}, -- Prince Malchezaar
    },
    [333] = { -- Zul'Aman
        {"boss", 0.355, 0.231, 23574}, -- Akil'zon
        {"boss", 0.405, 0.774, 23576}, -- Nalorakk
        {"boss", 0.555, 0.710, 23578}, -- Jan'alai
        {"boss", 0.585, 0.238, 23577}, -- Halazzi
        {"boss", 0.715, 0.530, 24239}, -- Hex Lord Malacrass
        {"boss", 0.904, 0.530, 23863}, -- Zul'jin
    },
    [331] = { -- Magtheridon's Lair
        {"boss", 0.692, 0.743, 17257}, -- Magtheridon
    },
    [330] = { -- Gruul's Lair
        {"boss", 0.550, 0.571, 18831}, -- High King Maulgar
        {"boss", 0.199, 0.283, 19044}, -- Gruul the Dragonkiller
    },
    [332] = { -- Serpentshrine Cavern
        {"boss", 0.364, 0.848, 21216}, -- Hydross the Unstable
        {"boss", 0.403, 0.582, 21217}, -- The Lurker Below
        {"boss", 0.418, 0.255, 21215}, -- Leotheras the Blind
        {"boss", 0.504, 0.177, 21214}, -- Fathom-Lord Karathress
        {"boss", 0.596, 0.260, 21213}, -- Morogrim Tidewalker
        {"boss", 0.723, 0.589, 21212}, -- Lady Vashj
    },
    [334] = { -- Tempest Keep
        {"boss", 0.501, 0.588, 19514}, -- Al'ar
        {"boss", 0.264, 0.491, 19516}, -- Void Reaver
        {"boss", 0.740, 0.489, 18805}, -- High Astromancer Solarian
        {"boss", 0.501, 0.138, 19622}, -- Kael'thas Sunstrider
    },
    [329] = { -- Hyjal Summit
        {"boss", 0.128, 0.634, 17767}, -- Rage Winterchill
        {"boss", 0.086, 0.682, 17808}, -- Anetheron
        {"boss", 0.424, 0.358, 17888}, -- Kaz'rogal
        {"boss", 0.357, 0.378, 17842}, -- Azgalor
        {"boss", 0.773, 0.283, 17968}, -- Archimonde
    },
    [339] = { -- Black Temple - 339
        {"boss", 0.663, 0.474, 22898}, -- Supremus
    },
    [340] = { -- Black Temple - 340
        {"boss", 0.439, 0.188, 22887}, -- High Warlord Naj'entus
    },
    [341] = { -- Black Temple - 341
        {"boss", 0.410, 0.889, 22841}, -- Shade of Akama
    },
    [342] = { -- Black Temple - 342
        {"boss", 0.540, 0.477, 22948}, -- Gurtogg Bloodboil
        {"boss", 0.614, 0.851, 22856}, -- Reliquary of the Lost
    },
    [343] = { -- Black Temple - 343
        {"boss", 0.394, 0.118, 22871}, -- Teron Gorefiend
    },
    [344] = { -- Black Temple - 344
        {"boss", 0.675, 0.368, 22947}, -- Mother Shahraz
    },
    [345] = { -- Black Temple - 345
        {"boss", 0.473, 0.438, 23426}, -- The Illidari Council
    },
    [346] = { -- Black Temple - 346
        {"boss", 0.528, 0.705, 22917}, -- Illidan Stormrage
    },
    [335] = { -- Sunwell Plateau - 335
        {"boss", 0.306, 0.511, 24850}, -- Kalecgos
        {"boss", 0.659, 0.865, 24882}, -- Brutallus
        {"boss", 0.728, 0.826, 25038}, -- Felmyst
        {"boss", 0.642, 0.321, 25166}, -- Eredar Twins
    },
    [336] = { -- Sunwell Plateau - 336
        {"boss", 0.467, 0.238, 25741}, -- M'uru
        {"boss", 0.460, 0.617, 25315}, -- Kil'jaeden
    },
}
