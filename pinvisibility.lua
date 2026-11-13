local _, MapUtils = ...
local PinVisibility = {
	sizeMin = 50,
	sizeMax = 200,
	sizeStep = 5,
	azerothCache = {},
	kindKeys = {
		["dungeon"] = "DUNGEONWORLDMAPPINS",
		["meetingstone"] = "MEETINGSTONEWORLDMAPPINS",
		["flight"] = "FLIGHTWORLDMAPPINS",
		["crossing"] = "CROSSINGWORLDMAPPINS",
		["spirithealer"] = "SPIRITHEALERWORLDMAPPINS",
		["convergence"] = "CONVERGENCEWORLDMAPPINS",
		["librarybook"] = "LIBRARYBOOKWORLDMAPPINS",
	},
	pierKey = "WORLDMAPPINS",
	sizeDefaults = {
		["LIBRARYBOOKWORLDMAPPINS"] = 65,
	},
	azerothDefaults = {
		["WORLDMAPPINS"] = true,
		["VESSELWORLDMAPPINS"] = true,
		["FLIGHTWORLDMAPPINS"] = true,
		["QUESTGIVERWORLDMAPPINS"] = true,
		["QUESTTURNINWORLDMAPPINS"] = true,
		["GUILDMEMBERPINS"] = true,
		["DUNGEONWORLDMAPPINS"] = false,
		["SPIRITHEALERWORLDMAPPINS"] = false,
		["TOWNPOIS"] = false,
		["CAPITALPOIS"] = false,
		["CROSSINGWORLDMAPPINS"] = false,
		["CONVERGENCEWORLDMAPPINS"] = false,
		["LIBRARYBOOKWORLDMAPPINS"] = false,
		["MEETINGSTONEWORLDMAPPINS"] = false,
	},
}

MapUtils.PinVisibility = PinVisibility
function PinVisibility.GetDB()
	MAUTTAB = MAUTTAB or {}

	return MAUTTAB
end

function MapUtils:IsAzerothMap(mapID)
	if mapID == nil and WorldMapFrame ~= nil and WorldMapFrame.GetMapID ~= nil then mapID = WorldMapFrame:GetMapID() end
	if mapID == nil then return false end
	local cached = PinVisibility.azerothCache[mapID]
	if cached ~= nil then return cached end
	if C_Map == nil or C_Map.GetMapInfo == nil or Enum == nil or Enum.UIMapType == nil then return false end
	local info = C_Map.GetMapInfo(mapID)
	local mapType = info and info.mapType
	local azeroth = mapType == Enum.UIMapType.Cosmic or mapType == Enum.UIMapType.World or mapType == Enum.UIMapType.Continent
	PinVisibility.azerothCache[mapID] = azeroth

	return azeroth
end

function MapUtils:IsPinCategoryEnabled(key)
	return PinVisibility.GetDB()[key .. "_ENABLED"] ~= false
end

function MapUtils:GetPinScopeShown(key, default, azeroth)
	local zone = MapUtils:GetConfig(key, default) == true
	if not azeroth then return zone end
	local value = PinVisibility.GetDB()[key .. "_AZEROTH"]
	if value == nil then return MapUtils:GetPinAzerothDefault(key, zone) end

	return value == true
end

function MapUtils:GetPinAzerothDefault(key, fallback)
	local value = PinVisibility.azerothDefaults[key]
	if value == nil then return fallback end

	return value
end

function MapUtils:KeepPinAzerothState(key, default)
	local db = PinVisibility.GetDB()
	if db[key .. "_AZEROTH"] == nil then db[key .. "_AZEROTH"] = MapUtils:GetPinScopeShown(key, default, true) end
end

function MapUtils:SetPinAzerothShown(key, default, value)
	MapUtils:KeepPinAzerothState(key, default)
	MapUtils:SV(PinVisibility.GetDB(), key .. "_AZEROTH", value == true)
end

function MapUtils:IsPinShownOnMap(key, default, mapID)
	if not MapUtils:IsPinCategoryEnabled(key) then return false end

	return MapUtils:GetPinScopeShown(key, default, MapUtils:IsAzerothMap(mapID))
end

function MapUtils:GetPinSizeDefault(key)
	return PinVisibility.sizeDefaults[key] or 100
end

function MapUtils:GetPinSizeFactor(key)
	local value = tonumber(PinVisibility.GetDB()[key .. "_SIZE"]) or MapUtils:GetPinSizeDefault(key)
	value = math.min(math.max(value, PinVisibility.sizeMin), PinVisibility.sizeMax)

	return value / 100
end

function MapUtils:GetPinKindSizeFactor(kind)
	return MapUtils:GetPinSizeFactor(PinVisibility.kindKeys[kind] or PinVisibility.pierKey)
end
