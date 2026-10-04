local _, MapUtils = ...
local MEDIA_PATH = "Interface\\AddOns\\MapUtils\\media\\"
local PIN_TOGGLE_KEYS = {
	["boss"] = "BOSSPINS",
	["item"] = "QUESTPINS",
	["entrance"] = "ENTRANCEPINS",
	["level"] = "LEVELPINS",
}

local compendium = _G["AzerothCompendiumAPI"]
if type(compendium) == "table" and compendium.ShowInstanceMap ~= nil then
	function MapUtils:ShowInstanceMap(instances, level)
		return compendium.ShowInstanceMap(instances, level)
	end

	function MapUtils:IsInstanceMapShown()
		return compendium.IsInstanceMapShown()
	end

	function MapUtils:ToggleInstanceMap()
		if not compendium.ToggleInstanceMap() then MapUtils:INFO("No own map for this instance") end
	end

	return
end

local art = {}
local function AddArt(instanceMapID, instanceName, levels)
	art[instanceMapID] = {}
	for i, level in ipairs(levels) do
		art[instanceMapID][i] = {
			["file"] = MEDIA_PATH .. level[1],
			["key"] = tostring(level[1]),
			["instance"] = instanceName,
			["name"] = level[2],
			["width"] = 1024,
			["height"] = level[3] or 683,
			["fileWidth"] = 1024,
			["fileHeight"] = 1024,
			["zoom"] = 1,
		}
	end
end

AddArt(2959, "City of Dalaran", {{2959, "City of Dalaran (1)"}, {"2959_2", "City of Dalaran (2)"}})
AddArt(2998, "Excavation Site: Wetlands", {{2998}})
AddArt(2999, "Ruins of Lordaeron", {{2999}})
AddArt(3065, "Hall of the Thanes", {{3065}})
AddArt(389, "Ragefire Chasm", {{213}})
AddArt(36, "The Deadmines", {{291}, {292, "Ironclad Cove"}})
AddArt(43, "Wailing Caverns", {{279}})
AddArt(33, "Shadowfang Keep", {{310, "The Courtyard"}, {311, "Dining Hall"}, {312, "The Vacant Den"}, {313, "Lower Observatory"}, {314, "Upper Observatory"}, {316, "The Wall Walk"}, {315, "Lord Godfrey's Chamber"}})
AddArt(34, "The Stockade", {{225, nil, 670}})
AddArt(48, "Blackfathom Deeps", {{221, "The Pool of Ask'Ar"}, {222, "Moonshrine Sanctum"}, {223, "The Forgotten Pool"}})
AddArt(90, "Gnomeregan", {{226, "The Hall of Gears"}, {227, "The Dormitory"}, {228, "Launch Bay"}, {229, "Tinkers' Court"}})
AddArt(47, "Razorfen Kraul", {{301}})
AddArt(189, "Scarlet Monastery", {{302, "Graveyard"}, {303, "Library"}, {304, "Armory"}, {305, "Cathedral"}})
AddArt(129, "Razorfen Downs", {{300}})
AddArt(70, "Uldaman", {{230, "Hall of the Keepers"}, {231, "Khaz'Goroth's Seat"}})
AddArt(209, "Zul'Farrak", {{219}})
AddArt(349, "Maraudon", {{280, "Caverns of Maraudon"}, {281, "Zaetar's Grave"}})
AddArt(109, "Temple of Atal'Hakkar", {{220}})
AddArt(230, "Blackrock Depths", {{242, "Detention Block"}, {243, "Shadowforge City"}})
AddArt(229, "Blackrock Spire", {{250, "Tazz'Alor"}, {251, "Skitterweb Tunnels"}, {252, "Hordemar City"}, {253, "Hall of Blackhand"}, {254, "Halycon's Lair"}, {255, "Chamber of Battle"}})
AddArt(409, "Molten Core", {{232}})
AddArt(469, "Blackwing Lair", {{287, "Dragonmaw Garrison"}, {288, "Halls of Strife"}, {289, "Crimson Laboratories"}, {290, "Nefarian's Lair"}})
AddArt(429, "Dire Maul", {{234}, {235, "Gordok Commons"}, {236, "Capital Gardens"}, {237, "Court of the Highborne"}, {238, "Prison of Immol'Thar"}, {239, "Warpwood Quarter"}, {240, "The Shrine of Eldretharr"}})
AddArt(289, "Scholomance", {{306, "The Reliquary"}, {307, "Chamber of Summoning"}, {308, "The Upper Study"}, {309, "Headmaster's Study"}})
AddArt(329, "Stratholme", {{317, "Crusader's Square"}, {318, "The Gauntlet"}})
AddArt(309, "Zul'Gurub", {{233}})
AddArt(249, "Onyxia's Lair", {{248}})
AddArt(509, "Ruins of Ahn'Qiraj", {{247}})
AddArt(531, "Temple of Ahn'Qiraj", {{319, "The Hive Undergrounds"}, {320, "The Temple Gates"}, {321, "Vault of C'Thun"}})
AddArt(533, "Naxxramas", {{162, "The Construct Quarter"}, {163, "The Arachnid Quarter"}, {164, "The Military Quarter"}, {165, "The Plague Quarter"}, {166, "The Lower Necropolis"}, {167, "The Upper Necropolis"}})
local function GetLevelLabel(levels, level)
	local instanceName = MapUtils:TransName(level.instance)
	if level.name == nil then return instanceName end
	for _, other in ipairs(levels) do
		if other.instance ~= level.instance then return instanceName .. " - " .. MapUtils:TransName(level.name) end
	end

	return MapUtils:TransName(level.name)
end

local instanceMap = MapUtils:CreateInstanceMap(
	{
		["media"] = MEDIA_PATH,
		["isDisabled"] = function() return MapUtils.nativeInstanceMaps end,
		["getLevels"] = function(instanceMapID) return art[instanceMapID] end,
		["getLabel"] = GetLevelLabel,
		["getPins"] = function(info) return MapUtils.INSTANCEPINS ~= nil and info.key ~= nil and MapUtils.INSTANCEPINS[info.key] or nil end,
		["getBossName"] = function(row) return MapUtils:TransName(row[5]) end,
		["getLevelHint"] = function() return format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SHOWDESTMAP")) end,
		["getEntranceText"] = function(row) return MapUtils:Trans(row[4] == "raid" and "LID_RAIDENTRANCE" or "LID_DUNGEONENTRANCE") end,
		["isPinEnabled"] = function(kind) return MapUtils:GetConfig("INSTANCEPINS_" .. strupper(kind), true) ~= false end,
		["setPinEnabled"] = function(kind, enabled) MapUtils:SetSharedOption("INSTANCEPINS_" .. strupper(kind), enabled) end,
		["getToggleText"] = function(kind, enabled) return MapUtils:Trans("LID_" .. (enabled and "HIDE" or "SHOW") .. PIN_TOGGLE_KEYS[kind]) end,
	}
)

function MapUtils:ShowInstanceMap(instances, level)
	return instanceMap:Show(instances, level)
end

function MapUtils:IsInstanceMapShown()
	return instanceMap:IsShown()
end

function MapUtils:RefreshInstanceMap()
	instanceMap:Invalidate()
end

function MapUtils:ToggleInstanceMap()
	if not instanceMap:Toggle() then MapUtils:INFO("No own map for this instance") end
end
