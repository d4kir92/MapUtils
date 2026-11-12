local _, MapUtils = ...
MapUtils.INSTANCEDATA = MapUtils.INSTANCEDATA or {["dungeonMaps"] = {}, ["raidMaps"] = {}, ["instanceToMap"] = {}, ["art"] = {}}
local data = MapUtils.INSTANCEDATA
local ATLAS_FOREVER = "Santiago Reyes - Atlas de Azeroth: Forever"
data.art[2959] = {"City of Dalaran", {{2959, "City of Dalaran (1)", ATLAS_FOREVER}, {"2959_2", "City of Dalaran (2)", ATLAS_FOREVER}}}
data.art[2998] = {"Excavation Site: Wetlands", {{2998, nil, ATLAS_FOREVER}}}
data.art[2999] = {"Ruins of Lordaeron", {{2999, nil, ATLAS_FOREVER}}}
data.art[3065] = {"Hall of the Thanes", {{3065, nil, ATLAS_FOREVER}}}
data.art[900001] = {"The Drowned City", {{900001, nil, ATLAS_FOREVER}}}
data.art[900002] = {"Krol'dok Stronghold", {{900002, nil, ATLAS_FOREVER}}}
data.art[900003] = {"Alcaz Prison", {{900003, nil, ATLAS_FOREVER}}}
data.art[900005] = {"Shaper's Terrace", {{900005, nil, ATLAS_FOREVER}}}
