local _, MapUtils = ...
local ICON_SIZE = 20
local DUNGEON_ICON_SIZE = 32
local POI_START_SCALE = 1
local POI_END_SCALE = 1.2
local WAYPOINT_TOLERANCE = 0.001
local SUPERTRACKED_ALPHA = 0.5
local SUPERTRACKED_MIN_DISTANCE = 1000
local TRACKED_ICON_SCALE = 0.72
local MEETING_STONE_ICON_SCALE = 0.8
local PUSHED_OFFSET = 1
local CIRCLE_TRACKED = "UI-QuestPoi-QuestNumber-SuperTracked"
local CIRCLE_TRACKED_PUSHED = "UI-QuestPoi-QuestNumber-Pressed-SuperTracked"
local CIRCLE_PUSHED = "UI-QuestPoi-QuestNumber-Pressed"
local UPDATE_INTERVAL = 0.05
local WORLD_PIN_LEVEL = 2000
local MINIMAP_PIN_LEVEL = 10
local DEFAULT_ICON = "Interface\\Icons\\Spell_Arcane_PortalStormwind"
local DEFAULT_FACTION = "Alliance"
local FACTION_ICONS = {}
FACTION_ICONS["Alliance"] = "TaxiNode_Continent_Alliance"
FACTION_ICONS["Horde"] = "TaxiNode_Continent_Horde"
FACTION_ICONS["Neutral"] = "TaxiNode_Continent_Neutral"
local FACTION_ORDER = {"Alliance", "Horde", "Neutral"}
local ICON_CANDIDATES = {"TaxiNode_Continent", "MagePortalAlliance", "MagePortalHorde", "Portal", "Ferry", "TransportShip", "Vehicle-Temporary-Zone-Boat", "FlightMaster_Neutral"}
local LFG_SCAN_MAX = 4000
local MAP_SCAN_MAX = 5000
local MAP_PRINT_LIMIT = 80
local DEFAULT_DUNGEON_ICON = "Interface\\Icons\\INV_Misc_Bone_Skull_02"
local DUNGEON_ICON_CANDIDATES = {"Dungeon", "DungeonSkull", "Dungeon-Normal"}
local PATH_ICON_CANDIDATES = {"CaveUnderground-Down", "CaveUnderground-Up"}
local RAID_ICON_CANDIDATES = {"Raid"}
local CROSSING_ICON_CANDIDATES = {}
CROSSING_ICON_CANDIDATES["down"] = {"CaveUnderground-Down", "Garr_LevelUpgradeArrow"}
CROSSING_ICON_CANDIDATES["up"] = {"CaveUnderground-Up", "Garr_LevelUpgradeArrow"}
local DEFAULT_CROSSING_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local MEETING_STONE_ICON = "Interface\\AddOns\\MapUtils\\media\\meetingstone"
local DEFAULT_FLIGHT_ICON = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green"
local FLIGHT_ICONS = {}
FLIGHT_ICONS["Alliance"] = "TaxiNode_Alliance"
FLIGHT_ICONS["Horde"] = "TaxiNode_Horde"
FLIGHT_ICONS["Neutral"] = "TaxiNode_Neutral"
local TAXI_FACTIONS = {}
TAXI_FACTIONS[0] = "Neutral"
TAXI_FACTIONS[1] = "Horde"
TAXI_FACTIONS[2] = "Alliance"
local ZONE_MAP_TYPE = 3
local COVERED_PIN_LEVELS = {"PIN_FRAME_LEVEL_DUNGEON_ENTRANCE", "PIN_FRAME_LEVEL_FLIGHT_POINT"}
local MINIMAP_YARDS = {}
MINIMAP_YARDS["outdoor"] = {[0] = 466.66666, 400, 333.33333, 266.66666, 200, 133.33333}
MINIMAP_YARDS["indoor"] = {[0] = 300, 240, 180, 120, 80, 50}
local piers = {}
piers[1411] = {
	{
		["name"] = "Orgrimmar",
		["x"] = 0.509,
		["y"] = 0.139,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Undercity",
				["mapID"] = 1420,
			},
		},
	},
	{
		["name"] = "Orgrimmar",
		["x"] = 0.506,
		["y"] = 0.126,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Grom'gol Base Camp",
				["mapID"] = 1434,
			},
		},
	},
}

piers[1413] = {
	{
		["name"] = "Ratchet",
		["x"] = 0.6367,
		["y"] = 0.3843,
		["faction"] = "Neutral",
		["routes"] = {
			{
				["dest"] = "Booty Bay",
				["mapID"] = 1434,
			},
		},
	},
}

piers[1420] = {
	{
		["name"] = "Undercity",
		["x"] = 0.607,
		["y"] = 0.588,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Orgrimmar",
				["mapID"] = 1411,
			},
		},
	},
	{
		["name"] = "Undercity",
		["x"] = 0.619,
		["y"] = 0.591,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Grom'gol Base Camp",
				["mapID"] = 1434,
			},
		},
	},
}

piers[1424] = {
	{
		["name"] = "Southshore",
		["x"] = 0.5057,
		["y"] = 0.6967,
		["routes"] = {
			{
				["dest"] = "Auberdine",
				["mapID"] = 1439,
			},
		},
	},
}

piers[1434] = {
	{
		["name"] = "Grom'gol Base Camp",
		["x"] = 0.314,
		["y"] = 0.302,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Orgrimmar",
				["mapID"] = 1411,
			},
		},
	},
	{
		["name"] = "Grom'gol Base Camp",
		["x"] = 0.316,
		["y"] = 0.291,
		["faction"] = "Horde",
		["transport"] = "zeppelin",
		["routes"] = {
			{
				["dest"] = "Undercity",
				["mapID"] = 1420,
			},
		},
	},
	{
		["name"] = "Booty Bay",
		["x"] = 0.2586,
		["y"] = 0.7299,
		["faction"] = "Neutral",
		["routes"] = {
			{
				["dest"] = "Ratchet",
				["mapID"] = 1413,
			},
		},
	},
}

piers[1437] = {
	{
		["name"] = "Menethil Harbor",
		["x"] = 0.0464,
		["y"] = 0.5717,
		["routes"] = {
			{
				["dest"] = "Southshore",
				["mapID"] = 1424,
			},
			{
				["dest"] = "Auberdine",
				["mapID"] = 1439,
			},
		},
	},
	{
		["name"] = "Menethil Harbor",
		["x"] = 0.0508,
		["y"] = 0.6341,
		["routes"] = {
			{
				["dest"] = "Theramore Isle",
				["mapID"] = 1445,
			},
		},
	},
}

piers[1438] = {
	{
		["name"] = "Rut'theran Village",
		["x"] = 0.5486,
		["y"] = 0.9677,
		["routes"] = {
			{
				["dest"] = "Auberdine",
				["mapID"] = 1439,
			},
		},
	},
}

piers[1439] = {
	{
		["name"] = "Auberdine",
		["x"] = 0.3242,
		["y"] = 0.4377,
		["routes"] = {
			{
				["dest"] = "Menethil Harbor",
				["mapID"] = 1437,
			},
			{
				["dest"] = "Southshore",
				["mapID"] = 1424,
			},
		},
	},
	{
		["name"] = "Auberdine",
		["x"] = 0.3074,
		["y"] = 0.4103,
		["routes"] = {
			{
				["dest"] = "Stormwind Harbor",
				["mapID"] = 1453,
			},
		},
	},
	{
		["name"] = "Auberdine",
		["x"] = 0.3319,
		["y"] = 0.4013,
		["routes"] = {
			{
				["dest"] = "Rut'theran Village",
				["mapID"] = 1438,
			},
		},
	},
}

piers[1444] = {
	{
		["name"] = "The Forgotten Coast",
		["x"] = 0.433,
		["y"] = 0.428,
		["routes"] = {
			{
				["dest"] = "Feathermoon Stronghold",
				["mapID"] = 1444,
			},
		},
	},
	{
		["name"] = "Feathermoon Stronghold",
		["x"] = 0.31,
		["y"] = 0.398,
		["routes"] = {
			{
				["dest"] = "The Forgotten Coast",
				["mapID"] = 1444,
			},
		},
	},
}

piers[1445] = {
	{
		["name"] = "Theramore Isle",
		["x"] = 0.7151,
		["y"] = 0.5634,
		["routes"] = {
			{
				["dest"] = "Menethil Harbor",
				["mapID"] = 1437,
			},
		},
	},
}

piers[1446] = {
	{
		["name"] = "Tanaris",
		["nameMapID"] = 1446,
		["x"] = 0.6813,
		["y"] = 0.2254,
		["faction"] = "Neutral",
		["routes"] = {
			{
				["mapID"] = 2548,
			},
		},
	},
}

piers[2548] = {
	{
		["name"] = "Riverglades",
		["nameMapID"] = 2548,
		["x"] = 0.8024,
		["y"] = 0.5408,
		["faction"] = "Neutral",
		["routes"] = {
			{
				["mapID"] = 1446,
			},
		},
	},
}

piers[1453] = {
	{
		["name"] = "Stormwind Harbor",
		["x"] = 0.2253,
		["y"] = 0.562,
		["routes"] = {
			{
				["dest"] = "Auberdine",
				["mapID"] = 1439,
			},
		},
	},
	{
		["name"] = "Dwarven District",
		["x"] = 0.666,
		["y"] = 0.347,
		["forever"] = {0.6901, 0.3071},
		["transport"] = "tram",
		["routes"] = {
			{
				["dest"] = "Tinker Town",
				["mapID"] = 1455,
			},
		},
	},
}

piers[1455] = {
	{
		["name"] = "Tinker Town",
		["x"] = 0.76676,
		["y"] = 0.51133,
		["transport"] = "tram",
		["routes"] = {
			{
				["dest"] = "Dwarven District",
				["mapID"] = 1453,
			},
		},
	},
}

for _, list in pairs(piers) do
	for _, pier in ipairs(list) do
		if pier.forever ~= nil and MapUtils:IsForever() then pier.x, pier.y = pier.forever[1], pier.forever[2] end
		pier.name = MapUtils:TransName(pier.name)
		local info = pier.nameMapID and C_Map.GetMapInfo(pier.nameMapID)
		if info and info.name and info.name ~= "" then pier.name = info.name end
		for _, route in ipairs(pier.routes or {}) do
			route.dest = MapUtils:TransName(route.dest)
		end
	end
end

local dungeons = {}
local function AddDungeon(info, positions)
	for mapID, pos in pairs(positions) do
		local entry = {}
		for key, value in pairs(info) do
			entry[key] = value
		end

		entry.kind = "dungeon"
		entry.name = MapUtils:TransName(entry.name)
		if entry.contains ~= nil then
			entry.contains = {}
			for i, instance in ipairs(info.contains) do
				entry.contains[i] = MapUtils:TransName(instance)
			end
		end

		entry.x = pos[1]
		entry.y = pos[2]
		dungeons[mapID] = dungeons[mapID] or {}
		tinsert(dungeons[mapID], entry)
	end
end

AddDungeon(
	{
		["name"] = "Ruins of Lordaeron",
		["lfg"] = 3272,
		["instance"] = 2999,
		["minLevel"] = 11,
		["maxLevel"] = 24,
	},
	{
		[1420] = {0.6336, 0.6738},
		[1458] = {0.7220, 0.1147},
	}
)

AddDungeon(
	{
		["name"] = "Hall of the Thanes",
		["instance"] = 3065,
		["minLevel"] = 10,
	},
	{
		[1455] = {0.27864, 0.47695},
	}
)

AddDungeon(
	{
		["name"] = "Hall of the Thanes",
		["entrance"] = "path",
		["instance"] = 3065,
		["minLevel"] = 10,
	},
	{
		[1455] = {0.43965, 0.51762},
	}
)

AddDungeon(
	{
		["name"] = "Ragefire Chasm",
		["instanceMap"] = 389,
		["lfg"] = 3,
		["minLevel"] = 13,
		["maxLevel"] = 18,
	},
	{
		[1454] = {0.526, 0.49},
	}
)

AddDungeon(
	{
		["name"] = "The Deadmines",
		["instanceMap"] = 36,
		["lfg"] = 5,
		["minLevel"] = 17,
		["maxLevel"] = 26,
	},
	{
		[1436] = {0.425, 0.717},
	}
)

AddDungeon(
	{
		["name"] = "Wailing Caverns",
		["instanceMap"] = 43,
		["minLevel"] = 17,
		["maxLevel"] = 24,
	},
	{
		[1413] = {0.46, 0.364},
	}
)

AddDungeon(
	{
		["name"] = "Shadowfang Keep",
		["instanceMap"] = 33,
		["minLevel"] = 22,
		["maxLevel"] = 30,
	},
	{
		[1421] = {0.448, 0.678},
	}
)

AddDungeon(
	{
		["name"] = "City of Dalaran",
		["lfg"] = 3271,
		["instance"] = 2959,
		["minLevel"] = 28,
		["maxLevel"] = 33,
	},
	{
		[1416] = {0.08509, 0.59261},
		[1421] = {0.69176, 0.45531},
	}
)

AddDungeon(
	{
		["name"] = "Excavation Site: Wetlands",
		["lfg"] = 3274,
		["instance"] = 2998,
	},
	{
		[1437] = {0.47705, 0.56244},
	}
)

AddDungeon(
	{
		["name"] = "The Stockade",
		["instanceMap"] = 34,
		["lfg"] = 11,
		["minLevel"] = 22,
		["maxLevel"] = 30,
	},
	{
		[1453] = {0.524, 0.7},
	}
)

AddDungeon(
	{
		["name"] = "Blackfathom Deeps",
		["instanceMap"] = 48,
		["lfg"] = 9,
		["minLevel"] = 24,
		["maxLevel"] = 32,
	},
	{
		[1440] = {0.145, 0.142},
	}
)

AddDungeon(
	{
		["name"] = "Gnomeregan",
		["instanceMap"] = 90,
		["minLevel"] = 29,
		["maxLevel"] = 38,
	},
	{
		[1426] = {0.243, 0.398},
	}
)

AddDungeon(
	{
		["name"] = "Razorfen Kraul",
		["instanceMap"] = 47,
		["minLevel"] = 29,
		["maxLevel"] = 38,
	},
	{
		[1413] = {0.429, 0.902},
	}
)

AddDungeon(
	{
		["name"] = "Scarlet Monastery",
		["instanceMap"] = 189,
		["minLevel"] = 34,
		["maxLevel"] = 45,
	},
	{
		[1420] = {0.826, 0.338},
	}
)

AddDungeon(
	{
		["name"] = "Razorfen Downs",
		["instanceMap"] = 129,
		["minLevel"] = 37,
		["maxLevel"] = 46,
	},
	{
		[1413] = {0.49, 0.939},
	}
)

AddDungeon(
	{
		["name"] = "Uldaman",
		["instanceMap"] = 70,
		["minLevel"] = 41,
		["maxLevel"] = 51,
	},
	{
		[1418] = {0.446, 0.121},
	}
)

AddDungeon(
	{
		["name"] = "The Drowned City",
		["minLevel"] = 35,
		["maxLevel"] = 40,
	},
	{
		[1434] = {0.21317, 0.27817},
	}
)

AddDungeon(
	{
		["name"] = "Zul'Farrak",
		["instanceMap"] = 209,
		["minLevel"] = 44,
		["maxLevel"] = 54,
	},
	{
		[1446] = {0.387, 0.2},
	}
)

AddDungeon(
	{
		["name"] = "Maraudon",
		["instanceMap"] = 349,
		["minLevel"] = 46,
		["maxLevel"] = 55,
	},
	{
		[1443] = {0.291, 0.625},
	}
)

AddDungeon(
	{
		["name"] = "Temple of Atal'Hakkar",
		["instanceMap"] = 109,
		["minLevel"] = 50,
		["maxLevel"] = 60,
	},
	{
		[1435] = {0.699, 0.536},
	}
)

AddDungeon(
	{
		["name"] = "Blackrock Mountain",
		["instanceMap"] = {230, 229, 409, 469},
		["entrance"] = "both",
		["contains"] = {"Blackrock Depths", "Lower Blackrock Spire", "Upper Blackrock Spire", "Molten Core", "Blackwing Lair"},
		["minLevel"] = 52,
		["maxLevel"] = 60,
	},
	{
		[1427] = {0.348, 0.853},
		[1428] = {0.294, 0.383},
	}
)

AddDungeon(
	{
		["name"] = "Dire Maul (North)",
		["instanceMap"] = 429,
		["instanceMapLevel"] = 2,
		["minLevel"] = 56,
		["maxLevel"] = 60,
	},
	{
		[1444] = {0.625, 0.249},
	}
)

AddDungeon(
	{
		["name"] = "Dire Maul (West)",
		["instanceMap"] = 429,
		["instanceMapLevel"] = 3,
		["minLevel"] = 56,
		["maxLevel"] = 60,
	},
	{
		[1444] = {0.603, 0.302},
	}
)

AddDungeon(
	{
		["name"] = "Dire Maul (East)",
		["instanceMap"] = 429,
		["instanceMapLevel"] = 6,
		["minLevel"] = 56,
		["maxLevel"] = 60,
	},
	{
		[1444] = {0.648, 0.302},
	}
)

AddDungeon(
	{
		["name"] = "Scholomance",
		["instanceMap"] = 289,
		["minLevel"] = 58,
		["maxLevel"] = 60,
	},
	{
		[1422] = {0.697, 0.732},
	}
)

AddDungeon(
	{
		["name"] = "Stratholme",
		["instanceMap"] = 329,
		["minLevel"] = 58,
		["maxLevel"] = 60,
	},
	{
		[1423] = {0.313, 0.157},
	}
)

AddDungeon(
	{
		["name"] = "Stratholme",
		["instanceMap"] = 329,
		["instanceMapLevel"] = 2,
		["minLevel"] = 58,
		["maxLevel"] = 60,
	},
	{
		[1423] = {0.479, 0.239},
	}
)

AddDungeon(
	{
		["name"] = "Zul'Gurub",
		["instanceMap"] = 309,
		["entrance"] = "raid",
		["minLevel"] = 60,
		["maxLevel"] = 60,
	},
	{
		[1434] = {0.539, 0.176},
	}
)

AddDungeon(
	{
		["name"] = "Onyxia's Lair",
		["instanceMap"] = 249,
		["entrance"] = "raid",
		["minLevel"] = 60,
		["maxLevel"] = 60,
	},
	{
		[1445] = {0.526, 0.768},
	}
)

AddDungeon(
	{
		["name"] = "Ahn'Qiraj",
		["instanceMap"] = {509, 531},
		["entrance"] = "raid",
		["contains"] = {"Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj"},
		["minLevel"] = 60,
		["maxLevel"] = 60,
	},
	{
		[1451] = {0.286, 0.924},
	}
)

AddDungeon(
	{
		["name"] = "Naxxramas",
		["entrance"] = "raid",
		["instanceMap"] = 533,
		["minLevel"] = 60,
		["maxLevel"] = 60,
	},
	{
		[1423] = {0.399, 0.259},
	}
)

local meetingStones = {}
meetingStones[1434] = {
	{
		["kind"] = "meetingstone",
		["name"] = "The Drowned City",
		["x"] = 0.21756,
		["y"] = 0.27748,
	},
}
meetingStones[1437] = {
	{
		["kind"] = "meetingstone",
		["name"] = "Excavation Site: Wetlands",
		["lfg"] = 3274,
		["instance"] = 2998,
		["x"] = 0.53788,
		["y"] = 0.65724,
	},
}

local mapRects = {}
local function GetMapRect(mapID)
	if mapID == nil then return nil end
	if mapRects[mapID] ~= nil then return mapRects[mapID] end
	if C_Map == nil or C_Map.GetWorldPosFromMapPos == nil then return nil end
	if C_Map.GetMapInfo(mapID) == nil then return nil end
	local _, topLeft = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
	local _, bottomRight = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
	if topLeft == nil or bottomRight == nil then return nil end
	if bottomRight.x == topLeft.x or bottomRight.y == topLeft.y then return nil end
	local rect = {}
	rect[1] = topLeft
	rect[2] = CreateVector2D(bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
	mapRects[mapID] = rect

	return rect
end

local function GetPlayerMapPos(mapID)
	local rect = GetMapRect(mapID)
	if rect == nil then return nil end
	local wx, wy = UnitPosition("player")
	if wx == nil or wy == nil then return nil end

	return (wy - rect[1].y) / rect[2].y, (wx - rect[1].x) / rect[2].x
end

local function GetEntryWorldPos(mapID, entry)
	if entry.worldPos ~= nil then return entry.worldPos end
	local rect = GetMapRect(mapID)
	if rect == nil then return nil end
	entry.worldPos = CreateVector2D(rect[1].x + rect[2].x * entry.y, rect[1].y + rect[2].y * entry.x)

	return entry.worldPos
end

local function GetMapName(mapID)
	if mapID == nil then return "no uiMapID" end
	if C_Map == nil or C_Map.GetMapInfo == nil then return "no C_Map" end
	local info = C_Map.GetMapInfo(mapID)
	if info == nil then return "uiMapID unknown to client" end

	return info.name or "?"
end

local function IsAtlas(icon)
	if icon == nil or icon == "" then return false end
	if MapUtils.AtlasExists == nil then return false end

	return MapUtils:AtlasExists(icon) == true
end

local resolvedIcons = {}
local function GetIcon(faction)
	if faction == nil or FACTION_ICONS[faction] == nil then faction = DEFAULT_FACTION end
	if resolvedIcons[faction] ~= nil then return resolvedIcons[faction] end
	if MAUTTAB ~= nil and MAUTTAB["icon"] ~= nil and MAUTTAB["icon"] ~= "" then
		resolvedIcons[faction] = MAUTTAB["icon"]

		return resolvedIcons[faction]
	end

	if IsAtlas(FACTION_ICONS[faction]) then
		resolvedIcons[faction] = FACTION_ICONS[faction]

		return resolvedIcons[faction]
	end

	resolvedIcons[faction] = MapUtils:FindAtlas(ICON_CANDIDATES) or DEFAULT_ICON

	return resolvedIcons[faction]
end

local resolvedDungeonIcon = nil
local function GetDungeonIcon()
	if resolvedDungeonIcon == nil then resolvedDungeonIcon = MapUtils:FindAtlas(DUNGEON_ICON_CANDIDATES) or DEFAULT_DUNGEON_ICON end

	return resolvedDungeonIcon
end

local resolvedRaidIcon = nil
local function GetRaidIcon()
	if resolvedRaidIcon == nil then resolvedRaidIcon = MapUtils:FindAtlas(RAID_ICON_CANDIDATES) or GetDungeonIcon() end

	return resolvedRaidIcon
end

local resolvedPathIcon = nil
local function GetPathIcon()
	if resolvedPathIcon == nil then resolvedPathIcon = MapUtils:FindAtlas(PATH_ICON_CANDIDATES) or false end

	return resolvedPathIcon or nil
end

local resolvedCrossingIcons = {}
local function GetCrossingIcon(up)
	local direction = up == true and "up" or "down"
	if resolvedCrossingIcons[direction] == nil then resolvedCrossingIcons[direction] = MapUtils:FindAtlas(CROSSING_ICON_CANDIDATES[direction]) or DEFAULT_CROSSING_ICON end

	return resolvedCrossingIcons[direction]
end

local function IsDesaturatedEntry(entry)
	if entry.kind == "flight" then return entry.undiscovered == true or not entry.discoveryKnown end

	return entry.kind == "dungeon" and entry.entrance == "path" and entry.icon == nil and GetPathIcon() == nil
end

local SPLIT_ICON = {"dungeon", "raid"}
local function GetEntryIcon(entry)
	if entry.icon ~= nil then return entry.icon end
	if entry.kind == "dungeon" and entry.entrance == "path" and GetPathIcon() ~= nil then return GetPathIcon() end
	if entry.kind == "dungeon" and entry.entrance == "raid" then return GetRaidIcon() end
	if entry.kind == "dungeon" and entry.entrance == "both" then return SPLIT_ICON end
	if entry.kind == "dungeon" then return GetDungeonIcon() end
	if entry.kind == "meetingstone" then return MEETING_STONE_ICON end
	if entry.kind == "crossing" then return GetCrossingIcon(entry.up) end

	return GetIcon(entry.faction)
end

local function SetTextureIcon(texture, icon, half)
	if IsAtlas(icon) and texture.SetAtlas ~= nil then
		texture:SetAtlas(icon)
	else
		texture:SetTexture(icon)
		texture:SetTexCoord(0, 1, 0, 1)
	end

	if half == nil then return end
	local left, top, _, bottom, right = texture:GetTexCoord()
	local middle = (left + right) / 2
	if half == "right" then
		texture:SetTexCoord(middle, right, top, bottom)
	else
		texture:SetTexCoord(left, middle, top, bottom)
	end
end

local function ApplyIcon(pin, icon)
	if pin.icon == icon then return end
	pin.icon = icon
	pin.splitIcon = icon == SPLIT_ICON
	if pin.splitIcon then
		if pin.textureRight == nil then pin.textureRight = pin:CreateTexture(nil, "OVERLAY") end
		SetTextureIcon(pin.texture, GetDungeonIcon(), "left")
		SetTextureIcon(pin.textureRight, GetRaidIcon(), "right")

		return
	end

	if pin.textureRight ~= nil then pin.textureRight:Hide() end
	SetTextureIcon(pin.texture, icon)
end

local function LayoutPinIcon(pin, size, x, y)
	pin.texture:ClearAllPoints()
	if not pin.splitIcon then
		pin.texture:SetPoint("CENTER", pin, "CENTER", x, y)
		pin.texture:SetSize(size, size)

		return
	end

	pin.texture:SetPoint("RIGHT", pin, "CENTER", x, y)
	pin.texture:SetSize(size / 2, size)
	pin.textureRight:ClearAllPoints()
	pin.textureRight:SetPoint("LEFT", pin, "CENTER", x, y)
	pin.textureRight:SetSize(size / 2, size)
	pin.textureRight:Show()
end

local function ApplyEntryTint(pin, entry)
	pin.texture:SetDesaturated(IsDesaturatedEntry(entry))
	if entry.kind == "flight" and entry.undiscovered then
		pin.texture:SetVertexColor(0.55, 0.55, 0.55)
	elseif entry.kind == "flight" and entry.discoveryKnown and (entry.faction == "Neutral" or type(entry.icon) == "string" and entry.icon:lower():find("neutral", 1, true)) then
		pin.texture:SetVertexColor(1, 0.82, 0)
	else
		pin.texture:SetVertexColor(1, 1, 1)
	end

	if pin.textureRight ~= nil then
		pin.textureRight:SetDesaturated(pin.texture:IsDesaturated())
		pin.textureRight:SetVertexColor(pin.texture:GetVertexColor())
	end
end

local function GetAtlasWidth(icon)
	if not IsAtlas(icon) or C_Texture == nil or C_Texture.GetAtlasInfo == nil then return nil end
	local info = C_Texture.GetAtlasInfo(icon)
	if info == nil or info.width == nil or info.width <= 0 then return nil end

	return info.width
end

local function GetFlightIcon(node, faction)
	local atlas = node.atlasName
	if atlas ~= nil and atlas ~= "" and node.textureKit ~= nil and node.textureKit ~= "" then atlas = format("%s-%s", node.textureKit, atlas) end
	if IsAtlas(atlas) then return atlas end
	if IsAtlas(FLIGHT_ICONS[faction]) then return FLIGHT_ICONS[faction] end

	return DEFAULT_FLIGHT_ICON
end

function MapUtils:GetFlightKnowledge()
	local guid = UnitGUID("player")
	if guid == nil or MAUTTAB == nil then return {} end
	if MAUTTAB.flightKnowledgeVersion ~= 4 then
		MAUTTAB.flightKnowledge = {}
		MAUTTAB.flightKnowledgeVersion = 4
	end

	MAUTTAB.flightKnowledge = MAUTTAB.flightKnowledge or {}
	MAUTTAB.flightKnowledge[guid] = MAUTTAB.flightKnowledge[guid] or {}

	return MAUTTAB.flightKnowledge[guid]
end

function MapUtils:CaptureFlightKnowledge()
	if C_TaxiMap.GetAllTaxiNodes == nil then return end
	local known = self:GetFlightKnowledge()
	local forever = self:IsForever()
	local nativeTypes = {}
	if forever and NumTaxiNodes ~= nil and TaxiNodeName ~= nil and TaxiNodeGetType ~= nil then
		for slot = 1, NumTaxiNodes() do
			local name = TaxiNodeName(slot)
			if name ~= nil and name ~= "" then nativeTypes[name] = TaxiNodeGetType(slot) end
		end
	end
	local routeNames = {}
	if NumTaxiNodes ~= nil and TaxiNodeName ~= nil and TaxiNodeGetType ~= nil and GetNumRoutes ~= nil and TaxiGetNodeSlot ~= nil then
		for slot = 1, NumTaxiNodes() do
			if TaxiNodeGetType(slot) == "REACHABLE" then
				for hop = 1, GetNumRoutes(slot) do
					for _, isSource in ipairs({true, false}) do
						local routeSlot = TaxiGetNodeSlot(slot, hop, isSource)
						if type(routeSlot) == "number" and routeSlot >= 1 and routeSlot <= NumTaxiNodes() then
							local name = TaxiNodeName(routeSlot)
							if name ~= nil and name ~= "" then routeNames[name] = true end
						end
					end
				end
			end
		end
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	local visited = {}
	while mapID ~= nil and mapID ~= 0 and not visited[mapID] do
		visited[mapID] = true
		local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, mapID)
		if ok and type(nodes) == "table" then
			for _, node in ipairs(nodes) do
				if node.nodeID ~= nil and not node.isMapLayerTransition then
					local nodeType
					if forever then
						nodeType = nativeTypes[node.name]
					else
						nodeType = node.slotIndex ~= nil and TaxiNodeGetType ~= nil and TaxiNodeGetType(node.slotIndex) or nil
					end
					if nodeType == "CURRENT" or nodeType == "REACHABLE" or routeNames[node.name] then
						known[node.nodeID] = true
					elseif not forever and nodeType == nil and (node.state == 0 or node.state == 1) then
						known[node.nodeID] = true
					end
				end
			end
		end

		local info = C_Map.GetMapInfo(mapID)
		mapID = info ~= nil and info.parentMapID or nil
	end
end

local flights = {}
local function GetFlights(mapID)
	if mapID == nil then return nil end
	if flights[mapID] ~= nil then return flights[mapID] end
	if C_TaxiMap == nil or C_TaxiMap.GetTaxiNodesForMap == nil then return nil end
	local info = C_Map.GetMapInfo(mapID)
	local playerFaction = UnitFactionGroup("player")
	if info == nil or playerFaction == nil then return nil end
	local list = {}
	if info.mapType ~= nil and info.mapType >= ZONE_MAP_TYPE then
		local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
		if ok and type(nodes) == "table" then
			for _, node in ipairs(nodes) do
				local faction = TAXI_FACTIONS[node.faction] or "Neutral"
				if node.position ~= nil and (type(node.name) ~= "string" or strfind(strlower(node.name), "^zzold") == nil) and (faction == "Neutral" or faction == playerFaction) then
					local entry = {}
					entry.kind = "flight"
					entry.nodeID = node.nodeID
					entry.name = MapUtils:TransName(node.name)
					entry.faction = faction
					entry.undiscovered = node.isUndiscovered == true
					local known = MapUtils:GetFlightKnowledge()[node.nodeID]
					entry.discoveryKnown = entry.undiscovered or known ~= nil or MapUtils:GetWoWBuild() == "RETAIL" and not MapUtils:IsForever() and type(node.isUndiscovered) == "boolean"
					if not entry.undiscovered and known ~= nil then entry.undiscovered = not known end
					entry.icon = GetFlightIcon(node, faction)
					entry.x, entry.y = node.position:GetXY()
					tinsert(list, entry)
				end
			end
		end
	end

	flights[mapID] = list

	return list
end

local crossings = {}
local function GetCrossings(mapID)
	if crossings[mapID] ~= nil then return crossings[mapID] end
	local list = {}
	local rows = MapUtils.GetZoneCrossings ~= nil and MapUtils:GetZoneCrossings(mapID) or nil
	for _, row in ipairs(rows or {}) do
		local dests = type(row[3]) == "table" and row[3] or {row[3]}
		local names = {}
		for _, destMapID in ipairs(dests) do
			local info = C_Map.GetMapInfo(destMapID)
			if info ~= nil and info.name ~= nil and info.name ~= "" then tinsert(names, info.name) end
		end

		local tips = {}
		for i = 4, #row do
			tinsert(tips, MapUtils:TransName(row[i]))
		end

		if #names > 0 then
			tinsert(
				list,
				{
					["kind"] = "crossing",
					["x"] = row[1],
					["y"] = row[2],
					["destMapID"] = dests[1],
					["name"] = table.concat(names, ", "),
					["tips"] = tips,
					["up"] = row.up == true
				}
			)
		end
	end

	crossings[mapID] = list

	return list
end

local function GetCrossingLabel(entry)
	local lines = {MapUtils:Trans("LID_ZONECROSSING")}
	for _, tip in ipairs(entry.tips) do
		tinsert(lines, format("|cffffd100%s|r", tip))
	end

	return entry.name, table.concat(lines, "\n")
end

local function GetFlightDescription()
	return MapUtils:Trans("LID_FLIGHTPOINT")
end

local function GetFlightStatus(entry)
	if not entry.discoveryKnown then return UNKNOWN or "Unknown", 1, 0.82, 0 end
	if entry.undiscovered then return MapUtils:Trans("LID_FLIGHTUNDISCOVERED"), 1, 0.25, 0.25 end

	return MapUtils:Trans("LID_FLIGHTDISCOVERED"), 0.25, 1, 0.25
end

local function GetRouteText(route, index)
	local text = route.dest or ""
	if route.mapID ~= nil then
		local info = C_Map.GetMapInfo(route.mapID)
		if info ~= nil and info.name ~= nil and info.name ~= "" and info.name ~= text then
			if text == "" then
				text = info.name
			else
				text = text .. ", " .. info.name
			end
		end
	end

	if index > 1 then text = MapUtils:Trans("LID_THEN") .. " " .. text end

	return text
end

local lfgByInstance = nil
local function GetLFGIndex()
	if lfgByInstance ~= nil then return lfgByInstance end
	local index = {}
	if GetLFGDungeonInfo == nil then
		lfgByInstance = index

		return index
	end

	local found = false
	for id = 1, LFG_SCAN_MAX do
		local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, lfgMapID = GetLFGDungeonInfo(id)
		if name ~= nil and name ~= "" then
			found = true
			if lfgMapID ~= nil and lfgMapID > 0 and index[lfgMapID] == nil then index[lfgMapID] = id end
		end
	end

	if not found then return index end
	lfgByInstance = index

	return index
end

local function IsRange(min, max)
	return min ~= nil and max ~= nil and min > 0 and max > min
end

local function HasActivityAPI()
	if C_LFGList == nil then return false end
	if C_LFGList.GetActivityInfoTable == nil then return false end
	if C_LFGList.GetAvailableActivities == nil then return false end
	if C_LFGList.GetAvailableCategories == nil then return false end

	return true
end

local function ForEachActivity(callback)
	if not HasActivityAPI() then return end
	for _, categoryID in ipairs(C_LFGList.GetAvailableCategories() or {}) do
		local groups = {0}
		if C_LFGList.GetAvailableActivityGroups ~= nil then
			for _, groupID in ipairs(C_LFGList.GetAvailableActivityGroups(categoryID) or {}) do
				tinsert(groups, groupID)
			end
		end

		for _, groupID in ipairs(groups) do
			for _, activityID in ipairs(C_LFGList.GetAvailableActivities(categoryID, groupID) or {}) do
				local info = C_LFGList.GetActivityInfoTable(activityID)
				if info ~= nil then callback(activityID, info) end
			end
		end
	end
end

local activityLevels = nil
local function GetActivityLevels()
	if activityLevels ~= nil then return activityLevels end
	local map = {}
	if not HasActivityAPI() then
		activityLevels = map

		return map
	end

	local count = 0
	ForEachActivity(
		function(_, info)
			local min = info.minLevelSuggestion or 0
			local max = info.maxLevelSuggestion or 0
			if IsRange(min, max) then
				local levels = {min, max}
				if info.shortName ~= nil and info.shortName ~= "" and map[info.shortName] == nil then map[info.shortName] = levels end
				if info.fullName ~= nil and info.fullName ~= "" and map[info.fullName] == nil then map[info.fullName] = levels end
				count = count + 1
			end
		end
	)

	if count == 0 then return map end
	activityLevels = map

	return map
end

local function GetDungeonInfo(entry)
	local id = entry.lfg
	if id == nil and entry.instance ~= nil then id = GetLFGIndex()[entry.instance] end
	local lfgName, apiMin, apiMax, apiRecMin, apiRecMax = nil, nil, nil, nil, nil
	if id ~= nil and GetLFGDungeonInfo ~= nil then
		local name, _, _, min, max, _, recMin, recMax = GetLFGDungeonInfo(id)
		if name ~= nil and name ~= "" then lfgName = name end
		apiMin = min
		apiMax = max
		apiRecMin = recMin
		apiRecMax = recMax
	end

	local minLevel, maxLevel = nil, nil
	if lfgName ~= nil then
		local levels = GetActivityLevels()[lfgName]
		if levels ~= nil then
			minLevel = levels[1]
			maxLevel = levels[2]
		end
	end

	if minLevel == nil then
		if IsRange(apiRecMin, apiRecMax) then
			minLevel = apiRecMin
			maxLevel = apiRecMax
		elseif IsRange(apiMin, apiMax) then
			minLevel = apiMin
			maxLevel = apiMax
		else
			minLevel = entry.minLevel
			maxLevel = entry.maxLevel
		end
	end

	local recLevel = nil
	if apiMin ~= nil and apiMin > 0 and apiMin ~= minLevel then recLevel = apiMin end

	return lfgName, minLevel, maxLevel, recLevel
end

local function GetEntranceText(entry)
	if entry.entrance == "raid" then return MapUtils:Trans("LID_RAIDENTRANCE") end
	if entry.entrance == "both" then return MapUtils:Trans("LID_DUNGEONRAIDENTRANCE") end
	if entry.entrance == "path" then return MapUtils:Trans("LID_DUNGEONPATH") end

	return MapUtils:Trans("LID_DUNGEONENTRANCE")
end

function MapUtils:GetLevelColorCode(minLevel, maxLevel)
	local playerLevel = UnitLevel("player")
	if playerLevel < minLevel then return MapUtils:GetColorCode(MapUtils:GetLevelDifficultyColor(minLevel)) end
	if playerLevel > maxLevel then return MapUtils:GetColorCode(MapUtils:GetLevelDifficultyColor(maxLevel - 2)) end
	local color = QuestDifficultyColors["difficult"]

	return MapUtils:GetColorCode(color.r, color.g, color.b)
end

local function GetDungeonLabel(entry)
	local name, minLevel, maxLevel, recLevel = GetDungeonInfo(entry)
	name = name or entry.name
	if minLevel ~= nil and minLevel > 0 then
		if maxLevel == nil or maxLevel < minLevel then maxLevel = minLevel end
		local range = tostring(minLevel)
		if maxLevel > minLevel then range = format("%d-%d", minLevel, maxLevel) end
		name = format("%s%s (%s)|r", name, MapUtils:GetLevelColorCode(minLevel, maxLevel), range)
	end

	local lines = {GetEntranceText(entry)}
	for _, instance in ipairs(entry.contains or {}) do
		tinsert(lines, format("|cffffd100%s|r", instance))
	end

	if recLevel ~= nil then tinsert(lines, MapUtils:Trans("LID_RECOMMENDEDLEVEL", nil, recLevel)) end

	return name, table.concat(lines, "\n")
end

local function IsPinMouseOver(pin)
	local extend = pin.hitExtend or 0

	return pin:IsMouseOver(extend, -extend, -extend, extend)
end

local areaLabel = nil
local function GetAreaLabel()
	if areaLabel ~= nil then return areaLabel end
	if WorldMapFrame.dataProviders == nil then return nil end
	local parent = nil
	for provider in pairs(WorldMapFrame.dataProviders) do
		if provider.Label ~= nil then
			parent = provider.Label
			break
		end
	end

	if parent == nil then return nil end
	areaLabel = CreateFrame("FRAME", nil, parent)
	areaLabel:SetAllPoints(parent)
	areaLabel.name = areaLabel:CreateFontString(nil, "OVERLAY", "WorldMapTextFont")
	areaLabel.name:SetPoint("TOP", areaLabel, "TOP", 0, -20)
	areaLabel.description = areaLabel:CreateFontString(nil, "OVERLAY", "SubZoneTextFont")
	areaLabel.description:SetPoint("TOP", areaLabel.name, "BOTTOM", 0, -10)
	areaLabel.hint = areaLabel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	areaLabel.hint:SetPoint("TOP", areaLabel.description, "BOTTOM", 0, -8)
	if AREA_NAME_FONT_COLOR ~= nil then areaLabel.name:SetVertexColor(AREA_NAME_FONT_COLOR:GetRGB()) end
	if AREA_DESCRIPTION_FONT_COLOR ~= nil then areaLabel.description:SetVertexColor(AREA_DESCRIPTION_FONT_COLOR:GetRGB()) end
	areaLabel:SetScript(
		"OnUpdate",
		function(self)
			local owner = self.owner
			if owner == nil or not owner:IsVisible() or not IsPinMouseOver(owner) then self:Hide() end
		end
	)

	areaLabel:Hide()

	return areaLabel
end

local function GetRouteHeader(entry)
	if entry.transport == "zeppelin" then return MapUtils:Trans("LID_ZEPPELINTO") end
	if entry.transport == "tram" then return MapUtils:Trans("LID_TRAMTO") end

	return MapUtils:Trans("LID_SHIPTO")
end

local function GetPierLabel(entry)
	local lines = {GetRouteHeader(entry)}
	for i, route in ipairs(entry.routes) do
		tinsert(lines, format("|cffffd100%s|r", GetRouteText(route, i)))
	end

	return entry.name, table.concat(lines, "\n")
end

local function GetDestinationMapID(entry)
	if entry.destMapID ~= nil then return entry.destMapID end
	if type(entry.routes) ~= "table" then return nil end
	local route = entry.routes[1]
	if type(route) ~= "table" then return nil end

	return route.mapID
end

local function GetClickHints(pin)
	local hints = {}
	if not pin.clickable then return hints end
	local entry = pin.entry
	if entry.kind == "dungeon" then return hints end
	tinsert(
		hints,
		{
			MapUtils:Trans("LID_LEFTCLICK"),
			MapUtils:Trans("LID_SETWAYPOINT")
		}
	)

	if entry.kind ~= "flight" and GetDestinationMapID(entry) ~= nil then
		tinsert(
			hints,
			{
				MapUtils:Trans("LID_RIGHTCLICK"),
				MapUtils:Trans("LID_SHOWDESTMAP")
			}
		)
	end

	return hints
end

local function ShowAreaLabel(pin)
	local label = GetAreaLabel()
	if label == nil then return false end
	local name, description = nil, nil
	if pin.entry.kind == "dungeon" then
		name, description = GetDungeonLabel(pin.entry)
	elseif pin.entry.kind == "meetingstone" then
		name = GetDungeonInfo(pin.entry) or pin.entry.name
		description = MapUtils:Trans("LID_MEETINGSTONE")
	elseif pin.entry.kind == "crossing" then
		name, description = GetCrossingLabel(pin.entry)
	elseif pin.entry.kind == "flight" then
		local status, r, g, b = GetFlightStatus(pin.entry)
		name = pin.entry.name
		description = format("%s\n|cff%02x%02x%02x%s|r", GetFlightDescription(), math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), status)
	else
		name, description = GetPierLabel(pin.entry)
	end

	label.name:SetText(name)
	label.description:SetText(description)
	local hintLines = {}
	for _, hint in ipairs(GetClickHints(pin)) do
		tinsert(hintLines, format("|cffffd100%s|r  %s", hint[1], hint[2]))
	end

	label.hint:SetText(table.concat(hintLines, "\n"))
	label.owner = pin
	label:Show()

	return true
end

local function OnPinEnter(pin)
	local entry = pin.entry
	if entry == nil then return end
	if pin.worldMap and ShowAreaLabel(pin) then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	if entry.kind == "dungeon" then
		local name, minLevel, maxLevel, recLevel = GetDungeonInfo(entry)
		GameTooltip:AddLine(name or entry.name, 1, 1, 1)
		GameTooltip:AddLine(GetEntranceText(entry), 0.6, 0.6, 0.6)
		for _, instance in ipairs(entry.contains or {}) do
			GameTooltip:AddLine(instance, 1, 0.82, 0)
		end
		if minLevel ~= nil and minLevel > 0 then
			if maxLevel ~= nil and maxLevel > minLevel then
				GameTooltip:AddLine(format("%s %d - %d", LEVEL or "Level", minLevel, maxLevel), 1, 0.82, 0)
			else
				GameTooltip:AddLine(format("%s %d", LEVEL or "Level", minLevel), 1, 0.82, 0)
			end
		end

		if recLevel ~= nil then GameTooltip:AddLine(MapUtils:Trans("LID_RECOMMENDEDLEVEL", nil, recLevel), 0.6, 0.6, 0.6) end
	elseif entry.kind == "meetingstone" then
		local name = GetDungeonInfo(entry)
		GameTooltip:AddLine(name or entry.name, 1, 1, 1)
		GameTooltip:AddLine(MapUtils:Trans("LID_MEETINGSTONE"), 0.6, 0.6, 0.6)
	elseif entry.kind == "crossing" then
		GameTooltip:AddLine(entry.name, 1, 1, 1)
		GameTooltip:AddLine(MapUtils:Trans("LID_ZONECROSSING"), 0.6, 0.6, 0.6)
		for _, tip in ipairs(entry.tips) do
			GameTooltip:AddLine(tip, 1, 0.82, 0)
		end
	elseif entry.kind == "flight" then
		GameTooltip:AddLine(entry.name, 1, 1, 1)
		GameTooltip:AddLine(GetFlightDescription(), 0.6, 0.6, 0.6)
		GameTooltip:AddLine(GetFlightStatus(entry))
	else
		GameTooltip:AddLine(entry.name, 1, 1, 1)
		GameTooltip:AddLine(GetRouteHeader(entry), 0.6, 0.6, 0.6)
		for i, route in ipairs(entry.routes) do
			GameTooltip:AddLine(GetRouteText(route, i), 1, 0.82, 0)
		end
	end

	local hints = GetClickHints(pin)
	if #hints > 0 then GameTooltip:AddLine(" ") end
	for _, hint in ipairs(hints) do
		GameTooltip:AddDoubleLine(hint[1], hint[2], 1, 0.82, 0, 1, 1, 1)
	end

	GameTooltip:Show()
end

local function PlayWaypointSound(key)
	if SOUNDKIT ~= nil and SOUNDKIT[key] ~= nil then PlaySound(SOUNDKIT[key]) end
end

local waypointEntry = nil
local waypointKey = nil
local function GetWaypointKey()
	if C_Map.HasUserWaypoint == nil or C_Map.GetUserWaypoint == nil or not C_Map.HasUserWaypoint() then return nil end
	local point = C_Map.GetUserWaypoint()
	if point == nil or point.position == nil then return nil end

	return format("%s|%s|%s", tostring(point.uiMapID), tostring(point.position.x), tostring(point.position.y))
end

local function IsSameEntry(a, b)
	if a == b then return true end
	if a.kind ~= b.kind then return false end
	if a.kind == "flight" then return a.nodeID ~= nil and a.nodeID == b.nodeID end
	if a.kind == "dungeon" or a.kind == "meetingstone" then return a.instance ~= nil and a.instance == b.instance end

	return false
end

local function IsEntryWaypoint(mapID, entry)
	local key = GetWaypointKey()
	if key == nil then return false end
	if waypointEntry ~= nil and key == waypointKey then return IsSameEntry(entry, waypointEntry) end
	if C_Map.GetUserWaypointPositionForMap == nil then return false end
	local pos = C_Map.GetUserWaypointPositionForMap(mapID)
	if pos == nil then return false end
	local x, y = pos:GetXY()

	return math.abs(x - entry.x) < WAYPOINT_TOLERANCE and math.abs(y - entry.y) < WAYPOINT_TOLERANCE
end

local function ToggleWaypoint(mapID, entry)
	if mapID == nil or C_Map.SetUserWaypoint == nil or UiMapPoint == nil then return end
	if IsEntryWaypoint(mapID, entry) then
		if MapUtils:IsWaypointTracked() then
			C_Map.ClearUserWaypoint()
			waypointEntry = nil
			waypointKey = nil
			MapUtils:SetWaypointTracked(false)
			PlayWaypointSound("UI_MAP_WAYPOINT_REMOVE")
		else
			MapUtils:SetWaypointTracked(true)
			PlayWaypointSound("UI_MAP_WAYPOINT_SUPER_TRACK_ON")
		end

		return
	end

	local waypointSet, reason = MapUtils:SetTrackedWaypoint(mapID, entry.x, entry.y)
	if not waypointSet then
		if reason == "invalid" and UIErrorsFrame ~= nil and MAP_PIN_INVALID_MAP ~= nil then UIErrorsFrame:AddMessage(MAP_PIN_INVALID_MAP, 1, 0.1, 0.1) end

		return
	end

	waypointEntry = entry
	waypointKey = GetWaypointKey()
	PlayWaypointSound("UI_MAP_WAYPOINT_SUPER_TRACK_ON")
end

local function GetCircleAtlas(tracked, pushed)
	local atlas = nil
	if tracked and pushed then
		atlas = CIRCLE_TRACKED_PUSHED
	elseif tracked then
		atlas = CIRCLE_TRACKED
	elseif pushed then
		atlas = CIRCLE_PUSHED
	end

	if atlas ~= nil and IsAtlas(atlas) then return atlas end

	return nil
end

local function GetPinLevelsManager()
	if WorldMapFrame.GetPinFrameLevelsManager == nil then return nil end
	local manager = WorldMapFrame:GetPinFrameLevelsManager()
	if manager == nil or manager.GetValidFrameLevel == nil then return nil end

	return manager
end

local function GetWaypointPinLevel()
	local manager = GetPinLevelsManager()
	if manager == nil then return nil end

	return manager:GetValidFrameLevel("PIN_FRAME_LEVEL_WAYPOINT_LOCATION")
end

local function GetWorldPinLevel(child)
	local level = child:GetFrameLevel() + WORLD_PIN_LEVEL
	local manager = GetPinLevelsManager()
	if manager ~= nil then
		for _, levelType in ipairs(COVERED_PIN_LEVELS) do
			level = math.max(level, manager:GetValidFrameLevel(levelType) + 1)
		end
	end

	if WorldMapFrame.EnumeratePinsByTemplate ~= nil then
		for _, template in ipairs({"LeaMapsGlobalPinTemplate", "FlightPointPinTemplate"}) do
			for otherPin in WorldMapFrame:EnumeratePinsByTemplate(template) do
				if otherPin:IsShown() and otherPin:GetFrameStrata() == child:GetFrameStrata() then level = math.max(level, otherPin:GetFrameLevel() + 1) end
			end
		end
	end

	return level
end

local function UpdatePinLevel(pin, isWaypoint)
	local level = pin.baseLevel
	if pin.entry ~= nil and pin.entry.kind == "flight" then level = level + 1 end
	if isWaypoint then
		local waypointLevel = GetWaypointPinLevel()
		if waypointLevel ~= nil and waypointLevel >= level then level = waypointLevel + 1 end
	end

	if pin:GetFrameLevel() ~= level then pin:SetFrameLevel(level) end
end

local function GetEntryIconScale(entry)
	if entry ~= nil and entry.kind == "meetingstone" then return MEETING_STONE_ICON_SCALE end

	return 1
end

local function UpdatePinStyle(pin)
	if pin.circle == nil then return end
	local isWaypoint = pin.entry ~= nil and IsEntryWaypoint(pin.mapID, pin.entry)
	UpdatePinLevel(pin, isWaypoint)
	local tracked = isWaypoint and MapUtils:IsWaypointTracked()
	local atlas = GetCircleAtlas(tracked, pin.pushed)
	local pinSize = pin:GetWidth()
	local size = pinSize
	local extend = 0
	if atlas ~= nil then
		local circleSize = math.max(pinSize, pin.minCircleSize or pinSize)
		pin.circle:SetAtlas(atlas)
		pin.circle:SetSize(circleSize, circleSize)
		pin.circle:Show()
		size = math.min(pinSize, circleSize * TRACKED_ICON_SCALE)
		extend = (circleSize - pinSize) / 2
	else
		pin.circle:Hide()
	end
	size = size * GetEntryIconScale(pin.entry)

	if pin.hitExtend ~= extend then
		pin.hitExtend = extend
		pin:SetHitRectInsets(-extend, -extend, -extend, -extend)
	end

	local offset = 0
	if pin.pushed then offset = PUSHED_OFFSET * (pin.pixel or 1) end
	LayoutPinIcon(pin, size, offset, -offset)
end

local function IsCovered()
	return MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
end

local function OnPinLeave(pin)
	if pin.pushed then
		pin.pushed = false
		UpdatePinStyle(pin)
	end

	if areaLabel ~= nil and areaLabel.owner == pin then areaLabel:Hide() end
	if GameTooltip:GetOwner() == pin then GameTooltip:Hide() end
end

local function OnPinMouseDown(pin, button)
	if button ~= "LeftButton" or IsCovered() then return end
	pin.pushed = true
	UpdatePinStyle(pin)
end

local function OnPinMouseUp(pin, button)
	pin.pushed = false
	UpdatePinStyle(pin)
end

local function OnPinClick(pin, button)
	local entry = pin.entry
	if entry ~= nil and button == "LeftButton" and pin.worldMap and MapUtils:IsDebug() and MapUtils:IsPinEditable(entry) then
		MapUtils:SelectDebugPin(pin.mapID, entry)
	elseif entry ~= nil and IsPinMouseOver(pin) then
		if IsCovered() then
			if button == "RightButton" then MapUtils:ToggleInstanceMap() end
		elseif button == "LeftButton" then
			ToggleWaypoint(pin.mapID, entry)
		elseif button == "RightButton" and entry.kind ~= "dungeon" and entry.kind ~= "flight" and GetDestinationMapID(entry) ~= nil then
			OnPinLeave(pin)
			WorldMapFrame:SetMapID(GetDestinationMapID(entry))
		elseif button == "RightButton" and entry.kind == "dungeon" and (entry.instanceMap or entry.instance) ~= nil and MapUtils.ShowInstanceMap ~= nil then
			MapUtils:ShowInstanceMap(entry.instanceMap or entry.instance, entry.instanceMapLevel)
		end
	end

	UpdatePinStyle(pin)
end

local function SetupPin(pin, parent, levelOffset, clickable)
	pin:SetSize(ICON_SIZE, ICON_SIZE)
	pin.clickable = clickable
	pin.baseLevel = parent:GetFrameLevel() + levelOffset
	pin:SetFrameLevel(pin.baseLevel)
	pin:EnableMouse(true)
	pin:SetScript("OnEnter", OnPinEnter)
	pin:SetScript("OnLeave", OnPinLeave)
	if pin.texture == nil then
		pin.texture = pin:CreateTexture(nil, "OVERLAY")
		pin.texture:SetAllPoints(pin)
	end

	if clickable then
		if pin.circle == nil then
			pin.circle = pin:CreateTexture(nil, "ARTWORK")
			pin.circle:SetPoint("CENTER", pin, "CENTER", 0, 0)
		end

		pin.circle:Hide()
		pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		pin:SetScript("OnMouseDown", OnPinMouseDown)
		pin:SetScript("OnMouseUp", OnPinMouseUp)
		pin:SetScript("OnClick", OnPinClick)
	end

	return pin
end

local function CreatePin(parent, levelOffset, clickable)
	local frameType = clickable and "BUTTON" or "FRAME"
	local pin = CreateFrame(frameType, nil, parent)

	return SetupPin(pin, parent, levelOffset, clickable)
end

local function HideAll(pins)
	for _, pin in pairs(pins) do
		pin:Hide()
	end
end

local function PiersEnabled(worldMap)
	if worldMap then return MapUtils:GetConfig("WORLDMAPPINS", true) == true end

	return MapUtils:GetConfig("MINIMAPPINS", true) == true
end

local function DungeonsEnabled(worldMap)
	if worldMap then return MapUtils:GetConfig("DUNGEONWORLDMAPPINS", true) == true end

	return MapUtils:GetConfig("DUNGEONMINIMAPPINS", true) == true
end

local function FlightsEnabled(worldMap)
	if worldMap then return MapUtils:GetConfig("FLIGHTWORLDMAPPINS", true) == true end

	return MapUtils:GetConfig("FLIGHTMINIMAPPINS", true) == true
end

local function MeetingStonesEnabled(worldMap)
	if worldMap then return MapUtils:GetConfig("MEETINGSTONEWORLDMAPPINS", true) == true end

	return MapUtils:GetConfig("MEETINGSTONEMINIMAPPINS", true) == true
end

local function CrossingsEnabled()
	return MapUtils:GetConfig("CROSSINGWORLDMAPPINS", true) == true
end

local function BuildList(mapID, piersOn, dungeonsOn, flightsOn, meetingStonesOn, crossingsOn)
	if mapID == nil then return nil end
	local list = nil
	local crossingList = nil
	if crossingsOn then crossingList = GetCrossings(mapID) end
	if crossingList ~= nil and #crossingList > 0 then
		list = {}
		for _, entry in ipairs(crossingList) do
			tinsert(list, entry)
		end
	end

	if piersOn and piers[mapID] ~= nil then
		list = list or {}
		for _, entry in ipairs(piers[mapID]) do
			tinsert(list, entry)
		end
	end

	if dungeonsOn and dungeons[mapID] ~= nil then
		list = list or {}
		for _, entry in ipairs(dungeons[mapID]) do
			tinsert(list, entry)
		end
	end

	if meetingStonesOn and meetingStones[mapID] ~= nil then
		list = list or {}
		for _, entry in ipairs(meetingStones[mapID]) do
			tinsert(list, entry)
		end
	end

	local flightList = nil
	if flightsOn then flightList = GetFlights(mapID) end
	if flightList ~= nil and #flightList > 0 then
		list = list or {}
		for _, entry in ipairs(flightList) do
			tinsert(list, entry)
		end
	end

	if MapUtils.ApplyPinEdits ~= nil then list = MapUtils:ApplyPinEdits(mapID, list, crossingsOn) end

	return list
end

local function GetPoiScale()
	local zoom = 0
	if WorldMapFrame.GetCanvasZoomPercent ~= nil then zoom = WorldMapFrame:GetCanvasZoomPercent() or 0 end
	zoom = math.min(math.max(zoom, 0), 1)
	local scale = POI_START_SCALE + (POI_END_SCALE - POI_START_SCALE) * zoom
	if WorldMapFrame.GetGlobalPinScale ~= nil then scale = scale * (WorldMapFrame:GetGlobalPinScale() or 1) end

	return scale
end

local function GetWorldCanvas()
	if WorldMapFrame == nil then return nil end
	if WorldMapFrame.GetCanvas ~= nil then return WorldMapFrame:GetCanvas() end
	if WorldMapFrame.ScrollContainer == nil then return nil end

	return WorldMapFrame.ScrollContainer.Child
end

local worldPins = {}
local worldPinPool = nil
local worldMapID = nil
local worldScale = nil
local worldPiers = nil
local worldDungeons = nil
local worldFlights = nil
local worldMeetingStones = nil
local worldCrossings = nil
local function UpdateWorldPins()
	local child = GetWorldCanvas()
	if child == nil or worldPinPool == nil then return end
	local mapID = WorldMapFrame:GetMapID()
	local scale = child:GetScale()
	local piersOn = PiersEnabled(true)
	local dungeonsOn = DungeonsEnabled(true)
	local flightsOn = FlightsEnabled(true)
	local meetingStonesOn = MeetingStonesEnabled(true)
	local crossingsOn = CrossingsEnabled()
	local baseLevel = GetWorldPinLevel(child)
	if mapID == worldMapID and scale == worldScale and piersOn == worldPiers and dungeonsOn == worldDungeons and flightsOn == worldFlights and meetingStonesOn == worldMeetingStones and crossingsOn == worldCrossings then
		for _, pin in ipairs(worldPins) do
			pin.baseLevel = baseLevel
			UpdatePinLevel(pin, pin.entry ~= nil and IsEntryWaypoint(pin.mapID, pin.entry))
		end

		return
	end
	worldMapID = mapID
	worldScale = scale
	worldPiers = piersOn
	worldDungeons = dungeonsOn
	worldFlights = flightsOn
	worldMeetingStones = meetingStonesOn
	worldCrossings = crossingsOn
	worldPinPool:ReleaseAll()
	wipe(worldPins)
	local list = BuildList(mapID, piersOn, dungeonsOn, flightsOn, meetingStonesOn, crossingsOn)
	if list == nil then return end
	if scale == nil or scale <= 0 then return end
	local w = child:GetWidth()
	local h = child:GetHeight()
	local size = ICON_SIZE / scale
	local poiScale = GetPoiScale()
	local dungeonSize = DUNGEON_ICON_SIZE * poiScale / scale
	for i, entry in ipairs(list) do
		local pin = worldPinPool:Acquire()
		SetupPin(pin, child, WORLD_PIN_LEVEL, true)
		pin.worldMap = true
		worldPins[i] = pin

		pin.entry = entry
		pin.mapID = mapID
		pin.pixel = 1 / scale
		pin.minCircleSize = dungeonSize
		pin.baseLevel = baseLevel
		ApplyIcon(pin, GetEntryIcon(entry))
		ApplyEntryTint(pin, entry)
		if entry.kind == "crossing" or entry.kind == "dungeon" and entry.entrance == "path" then
			pin:SetSize(dungeonSize * 0.7, dungeonSize * 0.7)
		elseif entry.kind == "dungeon" then
			pin:SetSize(dungeonSize, dungeonSize)
		elseif entry.kind == "flight" then
			local flightSize = (GetAtlasWidth(entry.icon) or ICON_SIZE) * poiScale / scale
			pin:SetSize(flightSize, flightSize)
		else
			pin:SetSize(size, size)
		end

		UpdatePinStyle(pin)
		pin:ClearAllPoints()
		pin:SetPoint("CENTER", child, "TOPLEFT", w * entry.x, -h * entry.y)
		pin:SetAlpha(MapUtils:GetDebugPinAlpha(entry))
		pin:Show()
	end
end

local function GetMinimapYards()
	if Minimap == nil or Minimap.GetZoom == nil then return nil end
	local zoom = Minimap:GetZoom()
	if zoom == nil then return nil end
	local list = MINIMAP_YARDS["outdoor"]
	local inside = tonumber(MapUtils:GetCVar("minimapInsideZoom") or "")
	local outside = tonumber(MapUtils:GetCVar("minimapZoom") or "")
	if inside == zoom and outside ~= zoom then list = MINIMAP_YARDS["indoor"] end

	return list[zoom] or list[0]
end

local minimapPins = {}
local minimapMapID = nil
local minimapPiers = nil
local minimapDungeons = nil
local minimapFlights = nil
local minimapMeetingStones = nil
local minimapList = nil
local function GetMinimapList(mapID, piersOn, dungeonsOn, flightsOn, meetingStonesOn)
	if mapID == minimapMapID and piersOn == minimapPiers and dungeonsOn == minimapDungeons and flightsOn == minimapFlights and meetingStonesOn == minimapMeetingStones then return minimapList end
	minimapMapID = mapID
	minimapPiers = piersOn
	minimapDungeons = dungeonsOn
	minimapFlights = flightsOn
	minimapMeetingStones = meetingStonesOn
	minimapList = BuildList(mapID, piersOn, dungeonsOn, flightsOn, meetingStonesOn)

	return minimapList
end

local function UpdateMinimapPins()
	local mapID = C_Map.GetBestMapForUnit("player")
	local list = GetMinimapList(mapID, PiersEnabled(false), DungeonsEnabled(false), FlightsEnabled(false), MeetingStonesEnabled(false))
	if list == nil then
		HideAll(minimapPins)

		return
	end

	local wx, wy = UnitPosition("player")
	local yards = GetMinimapYards()
	if wx == nil or wy == nil or yards == nil or yards <= 0 then
		HideAll(minimapPins)

		return
	end

	local width = Minimap:GetWidth()
	local scale = width / yards
	local radius = width / 2
	local facing = 0
	if MapUtils:GetCVar("rotateMinimap") == "1" then facing = GetPlayerFacing() or 0 end
	local cosF = math.cos(facing)
	local sinF = math.sin(facing)
	for i, entry in ipairs(list) do
		local pin = minimapPins[i]
		if pin == nil then
			pin = CreatePin(Minimap, MINIMAP_PIN_LEVEL)
			minimapPins[i] = pin
		end

		pin.entry = entry
		ApplyIcon(pin, GetEntryIcon(entry))
		ApplyEntryTint(pin, entry)
		LayoutPinIcon(pin, ICON_SIZE * GetEntryIconScale(entry), 0, 0)
		local pos = GetEntryWorldPos(mapID, entry)
		if pos == nil then
			pin:Hide()
		else
			local dx = pos.x - wx
			local dy = pos.y - wy
			local sx = -(dy * cosF - dx * sinF) * scale
			local sy = (dx * cosF + dy * sinF) * scale
			if math.sqrt(sx * sx + sy * sy) > radius then
				pin:Hide()
			else
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
				pin:Show()
			end
		end
	end

	for i = #list + 1, #minimapPins do
		minimapPins[i]:Hide()
	end
end

local function CreateUpdater(parent, callback)
	local updater = CreateFrame("FRAME", nil, parent)
	updater.elapsed = 0
	updater:SetScript(
		"OnUpdate",
		function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < UPDATE_INTERVAL then return end
			self.elapsed = 0
			callback()
		end
	)

	return updater
end

local worldUpdater = nil
local minimapUpdater = nil
local worldCanvas = GetWorldCanvas()
if worldCanvas ~= nil and CreateFramePool ~= nil then
	worldPinPool = CreateFramePool(
		"BUTTON",
		worldCanvas,
		nil,
		function(_, pin)
			OnPinLeave(pin)
			pin:Hide()
			pin:ClearAllPoints()
			pin.entry = nil
			pin.mapID = nil
			pin.pushed = false
			pin.hitExtend = nil
			pin.icon = nil
		end
	)
	worldUpdater = CreateUpdater(WorldMapFrame, UpdateWorldPins)
	WorldMapFrame:HookScript(
		"OnHide",
		function()
			worldPinPool:ReleaseAll()
			wipe(worldPins)
			worldMapID = nil
		end
	)
end

if Minimap ~= nil then minimapUpdater = CreateUpdater(Minimap, UpdateMinimapPins) end
local function UpdatePinStyles()
	for _, pin in ipairs(worldPins) do
		if pin:IsShown() then UpdatePinStyle(pin) end
	end
end

if C_Map.SetUserWaypoint ~= nil then
	local styleFrame = CreateFrame("FRAME")
	styleFrame:RegisterEvent("USER_WAYPOINT_UPDATED")
	if C_SuperTrack ~= nil then styleFrame:RegisterEvent("SUPER_TRACKING_CHANGED") end
	styleFrame:SetScript("OnEvent", UpdatePinStyles)
end

if C_TaxiMap ~= nil and C_TaxiMap.GetTaxiNodesForMap ~= nil then
	local taxiFrame = CreateFrame("FRAME")
	MapUtils:RegisterEvent(taxiFrame, "TAXI_NODE_STATUS_CHANGED")
	MapUtils:RegisterEvent(taxiFrame, "TAXIMAP_OPENED")
	MapUtils:RegisterEvent(taxiFrame, "UI_INFO_MESSAGE")
	taxiFrame.Refresh = function()
		wipe(flights)
		MapUtils:RefreshPins()
	end

	taxiFrame:SetScript(
		"OnEvent",
		function(self, event, _, message)
			if event == "TAXIMAP_OPENED" then MapUtils:CaptureFlightKnowledge() end
			if event == "UI_INFO_MESSAGE" then
				if ERR_NEWTAXIPATH == nil or message ~= ERR_NEWTAXIPATH then return end
				if C_Timer ~= nil then C_Timer.After(0.5, self.Refresh) end
			end

			self.Refresh()
		end
	)
end

local function CountPins(mapID)
	if mapID == nil then return 0, 0, 0, 0 end
	local pierCount = 0
	local dungeonCount = 0
	local flightCount = 0
	local meetingStoneCount = 0
	if piers[mapID] ~= nil then pierCount = #piers[mapID] end
	if dungeons[mapID] ~= nil then dungeonCount = #dungeons[mapID] end
	local flightList = GetFlights(mapID)
	if flightList ~= nil then flightCount = #flightList end
	if meetingStones[mapID] ~= nil then meetingStoneCount = #meetingStones[mapID] end

	return pierCount, dungeonCount, flightCount, meetingStoneCount
end

local function GetCaptures()
	MAUTTAB = MAUTTAB or {}
	MAUTTAB["captures"] = MAUTTAB["captures"] or {}

	return MAUTTAB["captures"]
end

local function AddCapture(label)
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID == nil then
		MapUtils:INFO("No uiMapID for player")

		return
	end

	local x, y = GetPlayerMapPos(mapID)
	if x == nil then
		MapUtils:INFO("No position for player, uiMapID:", mapID, GetMapName(mapID))

		return
	end

	local zone = GetSubZoneText()
	if zone == nil or zone == "" then zone = GetZoneText() or "" end
	local text = format("piers[%d] x = %.4f y = %.4f | %s | %s", mapID, x, y, GetMapName(mapID), zone)
	if label ~= nil and label ~= "" then text = text .. " | " .. label end
	local list = GetCaptures()
	tinsert(list, text)
	MapUtils:INFO(format("[%d]", #list), text)
	if #list == 1 then MapUtils:INFO("Saved. Do a /reload or logout when done, then the list is in SavedVariables\\MapUtils.lua") end
end

local function ListCaptures()
	local list = GetCaptures()
	if #list == 0 then
		MapUtils:INFO("No captures yet")

		return
	end

	for i, text in ipairs(list) do
		MapUtils:INFO(format("[%d]", i), text)
	end
end

local function ClearCaptures()
	MAUTTAB = MAUTTAB or {}
	MAUTTAB["captures"] = {}
	MapUtils:INFO("Captures cleared")
end

local function RefreshIcons()
	for _, pin in pairs(worldPins) do
		pin.icon = nil
	end

	for _, pin in pairs(minimapPins) do
		pin.icon = nil
	end

	worldMapID = nil
	worldScale = nil
	worldPiers = nil
	worldDungeons = nil
	worldFlights = nil
	worldMeetingStones = nil
	worldCrossings = nil
	resolvedDungeonIcon = nil
	resolvedRaidIcon = nil
	wipe(resolvedCrossingIcons)
end

function MapUtils:RefreshPins()
	worldMapID = nil
	worldScale = nil
	worldPiers = nil
	worldDungeons = nil
	worldFlights = nil
	worldMeetingStones = nil
	worldCrossings = nil
	minimapMapID = nil
	minimapPiers = nil
	minimapDungeons = nil
	minimapFlights = nil
	minimapMeetingStones = nil
	minimapList = nil
	if worldPinPool ~= nil then worldPinPool:ReleaseAll() end
	wipe(worldPins)
	HideAll(minimapPins)
end

local function SetIcon(value)
	MAUTTAB = MAUTTAB or {}
	if value == "reset" then
		MAUTTAB["icon"] = nil
		wipe(resolvedIcons)
		RefreshIcons()
		for _, faction in ipairs(FACTION_ORDER) do
			MapUtils:INFO("Icon reset to:", GetIcon(faction), "-", faction)
		end

		return
	end

	MAUTTAB["icon"] = value
	wipe(resolvedIcons)
	RefreshIcons()
	if IsAtlas(value) then
		MapUtils:INFO("Icon set as atlas:", value)
	else
		MapUtils:INFO("Icon set as texture path:", value, "- no atlas of that name exists, so a blank pin means the path is wrong")
	end
end

local function ReportIcons()
	for _, faction in ipairs(FACTION_ORDER) do
		MapUtils:INFO("current icon", faction, "-", GetIcon(faction), "- is atlas:", IsAtlas(GetIcon(faction)))
		MapUtils:INFO("atlas", FACTION_ICONS[faction], "exists:", IsAtlas(FACTION_ICONS[faction]))
	end

	for _, atlas in ipairs(ICON_CANDIDATES) do
		MapUtils:INFO("atlas", atlas, "exists:", IsAtlas(atlas))
	end

	MapUtils:INFO("current dungeon icon:", GetDungeonIcon(), "- is atlas:", IsAtlas(GetDungeonIcon()))
	for _, atlas in ipairs(DUNGEON_ICON_CANDIDATES) do
		MapUtils:INFO("atlas", atlas, "exists:", IsAtlas(atlas))
	end

	MapUtils:INFO("current raid icon:", GetRaidIcon(), "- is atlas:", IsAtlas(GetRaidIcon()))
	MapUtils:INFO("current meeting stone icon:", MEETING_STONE_ICON)

	MapUtils:INFO("Use /mappins icon <atlas or texture path> to try one, /mappins icon reset to go back")
end

function MapUtils:ReportOverlappingTextures(pin)
	if EnumerateFrames == nil or not pin:IsShown() then return end
	local px, py = pin.texture:GetCenter()
	if px == nil or py == nil then return end
	local scale = pin:GetEffectiveScale()
	px, py = px * scale, py * scale
	local function ReportFrame(frame)
		if not frame:IsShown() then return end
		local frameScale = frame:GetEffectiveScale()
		for _, texture in ipairs({frame:GetRegions()}) do
			if texture:IsObjectType("Texture") and texture:IsShown() and texture:GetWidth() <= 64 and texture:GetHeight() <= 64 then
				local x, y = texture:GetCenter()
				if x ~= nil and y ~= nil and math.abs(x * frameScale - px) <= 16 * scale and math.abs(y * frameScale - py) <= 16 * scale then
					local r, g, b = texture:GetVertexColor()
					local layer, sublevel = texture:GetDrawLayer()
					local text = format("nearby texture | own %s | frame %s | parent %s | level %d | strata %s | atlas %s | texture %s | layer %s/%s | alpha %.2f | blend %s | tint %.2f / %.2f / %.2f", tostring(texture == pin.texture), tostring(frame:GetName() or frame), tostring(frame:GetParent() and (frame:GetParent():GetName() or frame:GetParent())), frame:GetFrameLevel(), frame:GetFrameStrata(), tostring(texture:GetAtlas()), tostring(texture:GetTexture()), tostring(layer), tostring(sublevel), texture:GetAlpha(), tostring(texture:GetBlendMode()), r, g, b)
					self:INFO(text)
					tinsert(GetCaptures(), text)
				end
			end
		end
	end

	local frame = EnumerateFrames()
	while frame do
		pcall(ReportFrame, frame)
		frame = EnumerateFrames(frame)
	end
end

local function ReportState(filter)
	if filter ~= nil and filter ~= "" then
		local needle = strlower(filter)
		local hits = 0
		local function ReportPin(pin, surface, index)
			local entry = pin.entry
			if entry == nil or strfind(strlower(entry.name or ""), needle, 1, true) == nil then return end
			hits = hits + 1
			local r, g, b = pin.texture:GetVertexColor()
			local text = format("%s pin %d | %s | %s | map %s | %.4f / %.4f | shown %s | waypoint %s | level %d | strata %s | faction %s | icon %s | known %s | undiscovered %s | desaturated %s | tint %.2f / %.2f / %.2f", surface, index, tostring(entry.kind or "pier"), tostring(entry.name), tostring(pin.mapID), entry.x, entry.y, tostring(pin:IsShown()), tostring(IsEntryWaypoint(pin.mapID, entry)), pin:GetFrameLevel(), tostring(pin:GetFrameStrata()), tostring(entry.faction), tostring(pin.icon), tostring(entry.discoveryKnown), tostring(entry.undiscovered), tostring(pin.texture:IsDesaturated()), r, g, b)
			MapUtils:INFO(text)
			tinsert(GetCaptures(), text)
			if surface == "world" and entry.kind == "flight" then MapUtils:ReportOverlappingTextures(pin) end
			if surface == "world" and WorldMapFrame.pinPools ~= nil then
				for template, pool in pairs(WorldMapFrame.pinPools) do
					for otherPin in pool:EnumerateActive() do
						if otherPin:IsShown() and otherPin.GetPosition ~= nil then
							local x, y = otherPin:GetPosition()
							if x ~= nil and y ~= nil and math.abs(x - entry.x) <= 0.005 and math.abs(y - entry.y) <= 0.005 then
								local texture = otherPin.Texture or otherPin.texture
								local atlas = texture and texture.GetAtlas and texture:GetAtlas()
								local cr, cg, cb = 0, 0, 0
								if texture and texture.GetVertexColor then cr, cg, cb = texture:GetVertexColor() end
								local otherText = format("overlapping pin | template %s | %.4f / %.4f | level %d | strata %s | atlas %s | tint %.2f / %.2f / %.2f", tostring(template), x, y, otherPin:GetFrameLevel(), tostring(otherPin:GetFrameStrata()), tostring(atlas), cr, cg, cb)
								MapUtils:INFO(otherText)
								tinsert(GetCaptures(), otherText)
							end
						end
					end
				end
			end
		end

		for i, pin in ipairs(worldPins) do
			ReportPin(pin, "world", i)
		end

		for i, pin in ipairs(minimapPins) do
			ReportPin(pin, "minimap", i)
		end

		MapUtils:INFO(format("%d pins matching '%s'; open the relevant map to inspect its pins. Results also saved to SavedVariables.", hits, filter))

		return
	end
	local playerMapID = C_Map.GetBestMapForUnit("player")
	local canvasMapID = nil
	local mapOpen = false
	if WorldMapFrame ~= nil then
		if WorldMapFrame.GetMapID ~= nil then canvasMapID = WorldMapFrame:GetMapID() end
		mapOpen = WorldMapFrame:IsShown() == true
	end

	local playerPiers, playerDungeons, playerFlights, playerMeetingStones = CountPins(playerMapID)
	local canvasPiers, canvasDungeons, canvasFlights, canvasMeetingStones = CountPins(canvasMapID)
	local zone, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	MapUtils:INFO("world updater:", worldUpdater ~= nil, "minimap updater:", minimapUpdater ~= nil, "map open:", mapOpen)
	MapUtils:INFO("instance:", tostring(zone), "- instanceMapID:", tostring(instanceMapID))
	MapUtils:INFO("player uiMapID:", tostring(playerMapID), "-", GetMapName(playerMapID), "- piers:", playerPiers, "- dungeons:", playerDungeons, "- flights:", playerFlights, "- meeting stones:", playerMeetingStones)
	MapUtils:INFO("canvas uiMapID:", tostring(canvasMapID), "-", GetMapName(canvasMapID), "- piers:", canvasPiers, "- dungeons:", canvasDungeons, "- flights:", canvasFlights, "- meeting stones:", canvasMeetingStones)
	MapUtils:INFO("C_TaxiMap.GetTaxiNodesForMap:", C_TaxiMap ~= nil and C_TaxiMap.GetTaxiNodesForMap ~= nil, "- world pin base level:", worldUpdater ~= nil and GetWorldPinLevel(GetWorldCanvas()) or "?")
	MapUtils:INFO("world pins:", #worldPins, "minimap pins:", #minimapPins, "icon:", GetIcon(DEFAULT_FACTION), "is atlas:", IsAtlas(GetIcon(DEFAULT_FACTION)))
	MapUtils:INFO("user waypoint:", tostring(GetWaypointKey()), "- set by pin:", tostring(waypointKey), "- tracked:", tostring(MapUtils:IsWaypointTracked()))
	if canvasMapID ~= nil and C_Map.GetUserWaypointPositionForMap ~= nil then
		local pos = C_Map.GetUserWaypointPositionForMap(canvasMapID)
		if pos ~= nil then MapUtils:INFO(format("user waypoint on canvas map: %.5f / %.5f", pos:GetXY())) end
	end

	for i, pin in ipairs(worldPins) do
		local ox, oy = 0, 0
		if pin:GetNumPoints() > 0 then
			local _, _, _, px, py = pin:GetPoint(1)
			ox = px or 0
			oy = py or 0
		end

		MapUtils:INFO(format("world pin %d shown = %s offset = %.1f / %.1f size = %.1f level = %d strata = %s", i, tostring(pin:IsShown()), ox, oy, pin:GetWidth(), pin:GetFrameLevel(), tostring(pin:GetFrameStrata())))
		if pin.entry ~= nil then MapUtils:INFO(format("  %s %s %.4f / %.4f waypoint = %s", tostring(pin.entry.kind or "pier"), tostring(pin.entry.name), pin.entry.x, pin.entry.y, tostring(IsEntryWaypoint(pin.mapID, pin.entry)))) end
		if pin.entry ~= nil and pin.entry.kind == "flight" then
			local r, g, b = pin.texture:GetVertexColor()
			MapUtils:INFO(format("  faction = %s icon = %s known = %s undiscovered = %s tint = %.2f / %.2f / %.2f", tostring(pin.entry.faction), tostring(pin.icon), tostring(pin.entry.discoveryKnown), tostring(pin.entry.undiscovered), r, g, b))
		end
	end

	for i, pin in ipairs(minimapPins) do
		MapUtils:INFO(format("minimap pin %d shown = %s level = %d", i, tostring(pin:IsShown()), pin:GetFrameLevel()))
	end
end

local function ReportLFG(filter)
	if GetLFGDungeonInfo == nil then
		MapUtils:INFO("GetLFGDungeonInfo does not exist on this client")

		return
	end

	local needle = nil
	if filter ~= nil and filter ~= "" then needle = strlower(filter) end
	local list = GetCaptures()
	local hits = 0
	for id = 1, LFG_SCAN_MAX do
		local name, _, _, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, _, _, _, _, _, _, _, _, _, _, _, _, _, lfgMapID = GetLFGDungeonInfo(id)
		if name ~= nil and name ~= "" and (needle == nil or strfind(strlower(name), needle, 1, true) ~= nil) then
			hits = hits + 1
			local text = format("lfg %d | %s | lvl %s - %s | rec %s (%s - %s) | instance %s", id, name, tostring(minLevel), tostring(maxLevel), tostring(recLevel), tostring(minRecLevel), tostring(maxRecLevel), tostring(lfgMapID))
			tinsert(list, text)
			MapUtils:INFO(text)
		end
	end

	MapUtils:INFO(format("%d LFG entries found, also saved to SavedVariables - /mappins clear empties the list again", hits))
end

local function ReportActivities(filter)
	if not HasActivityAPI() then
		MapUtils:INFO("C_LFGList activities do not exist on this client")

		return
	end

	local needle = nil
	if filter ~= nil and filter ~= "" then needle = strlower(filter) end
	local list = GetCaptures()
	local hits = 0
	ForEachActivity(
		function(activityID, info)
			local short = info.shortName or ""
			local full = info.fullName or ""
			if needle ~= nil and strfind(strlower(short), needle, 1, true) == nil and strfind(strlower(full), needle, 1, true) == nil then return end
			hits = hits + 1
			local text = format("activity %d | %s | %s | %s - %s", activityID, short, full, tostring(info.minLevelSuggestion), tostring(info.maxLevelSuggestion))
			tinsert(list, text)
			MapUtils:INFO(text)
		end
	)

	MapUtils:INFO(format("%d activities found, also saved to SavedVariables", hits))
end

local function ReportMaps(filter)
	if C_Map == nil or C_Map.GetMapInfo == nil then
		MapUtils:INFO("C_Map.GetMapInfo does not exist on this client")

		return
	end

	local needle = nil
	if filter ~= nil and filter ~= "" then needle = strlower(filter) end
	local texts = {}
	for id = 1, MAP_SCAN_MAX do
		local info = C_Map.GetMapInfo(id)
		if info ~= nil then
			local name = info.name or ""
			if needle == nil or strfind(strlower(name), needle, 1, true) ~= nil then tinsert(texts, format("uiMap %d | %s | type %s | parent %s", id, name, tostring(info.mapType), tostring(info.parentMapID))) end
		end
	end

	local list = GetCaptures()
	for _, text in ipairs(texts) do
		tinsert(list, text)
		if #texts <= MAP_PRINT_LIMIT then MapUtils:INFO(text) end
	end

	if #texts > MAP_PRINT_LIMIT then
		MapUtils:INFO(format("%d maps saved to SavedVariables, too many to print - use /mappins maps <text> to filter by name", #texts))
	else
		MapUtils:INFO(format("%d maps found, also saved to SavedVariables", #texts))
	end
end

local function GetEntranceXY(entrance)
	local pos = entrance.position
	if pos == nil then return nil end
	if pos.GetXY ~= nil then return pos:GetXY() end

	return pos.x, pos.y
end

local function ReportEntrances()
	if C_EncounterJournal == nil or C_EncounterJournal.GetDungeonEntrancesForMap == nil then
		MapUtils:INFO("C_EncounterJournal.GetDungeonEntrancesForMap does not exist on this client")

		return
	end

	local list = GetCaptures()
	local hits = 0
	for id = 1, MAP_SCAN_MAX do
		local info = C_Map.GetMapInfo(id)
		if info ~= nil then
			local ok, entrances = pcall(C_EncounterJournal.GetDungeonEntrancesForMap, id)
			if ok and type(entrances) == "table" then
				for _, entrance in ipairs(entrances) do
					local x, y = GetEntranceXY(entrance)
					hits = hits + 1
					local text = format("entrance | uiMap %d %s | %s | %.4f %.4f | journal %s | atlas %s", id, info.name or "", entrance.name or "", x or 0, y or 0, tostring(entrance.journalInstanceID), tostring(entrance.atlasName))
					tinsert(list, text)
					MapUtils:INFO(text)
				end
			end
		end
	end

	MapUtils:INFO(format("%d dungeon entrances found, also saved to SavedVariables", hits))
end

local function HandleSlash(args)
	local label = strtrim(args or "")
	local sub, rest = strsplit(" ", label, 2)
	sub = strlower(strtrim(sub or ""))
	rest = strtrim(rest or "")
	if sub == "debug" then
		ReportState(rest)
	elseif sub == "list" then
		ListCaptures()
	elseif sub == "clear" then
		ClearCaptures()
	elseif sub == "lfg" then
		ReportLFG(rest)
	elseif sub == "activities" then
		ReportActivities(rest)
	elseif sub == "maps" then
		ReportMaps(rest)
	elseif sub == "entrances" then
		ReportEntrances()
	elseif sub == "icon" then
		if rest == "" then
			ReportIcons()
		else
			SetIcon(rest)
		end
	else
		AddCapture(label)
	end
end

MapUtils:AddSlash("mappins", HandleSlash)
MapUtils:AddSlash("mapdocks", HandleSlash)
local superTrackedFixed = false
local function FixSuperTrackedFrame()
	local frame = SuperTrackedFrame
	if superTrackedFixed or frame == nil then return superTrackedFixed end
	superTrackedFixed = true
	local function ShouldForceAlpha()
		if not MapUtils:IsWaypointTracked() and not MapUtils:GetConfig("ALWAYSSHOWWAYPOINT", false) then return false end
		if C_Navigation == nil or C_Navigation.GetDistance == nil then return false end
		local distance = C_Navigation.GetDistance() or 0
		if MapUtils:IsForever() then return frame.navFrame ~= nil and distance > 0 end

		return distance >= SUPERTRACKED_MIN_DISTANCE
	end

	for _, key in ipairs({"GetTargetAlphaBaseValue", "GetTargetAlpha"}) do
		local original = frame[key]
		if original ~= nil then
			frame[key] = function(self, ...)
				local alpha = original(self, ...)
				if alpha == 0 and ShouldForceAlpha() then return SUPERTRACKED_ALPHA end

				return alpha
			end
		end
	end

	return true
end

local superTrackedLoader = CreateFrame("FRAME")
MapUtils:RegisterEvent(superTrackedLoader, "PLAYER_LOGIN")
MapUtils:RegisterEvent(superTrackedLoader, "ADDON_LOADED")
superTrackedLoader:SetScript(
	"OnEvent",
	function(self)
		if FixSuperTrackedFrame() then self:UnregisterAllEvents() end
	end
)
