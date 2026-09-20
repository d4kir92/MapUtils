local _, MapUtils = ...
local ICON_SIZE = 20
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
local DEFAULT_DUNGEON_ICON = "Interface\\Icons\\INV_Misc_Bone_Skull_02"
local DUNGEON_ICON_CANDIDATES = {"Dungeon", "DungeonSkull", "Dungeon-Normal"}
local MINIMAP_YARDS = {}
MINIMAP_YARDS["outdoor"] = {[0] = 466.66666, 400, 333.33333, 266.66666, 200, 133.33333}
MINIMAP_YARDS["indoor"] = {[0] = 300, 240, 180, 120, 80, 50}
local piers = {}
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
}

local dungeons = {}
dungeons[1458] = {
	{
		["name"] = "Ruins of Lordaeron",
		["x"] = 0.7220,
		["y"] = 0.1147,
		["lfg"] = 3272,
		["minLevel"] = 11,
		["maxLevel"] = 24,
	},
}

for _, list in pairs(dungeons) do
	for _, entry in ipairs(list) do
		entry.kind = "dungeon"
	end
end

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

	for _, atlas in ipairs(ICON_CANDIDATES) do
		if IsAtlas(atlas) then
			resolvedIcons[faction] = atlas

			return resolvedIcons[faction]
		end
	end

	resolvedIcons[faction] = DEFAULT_ICON

	return resolvedIcons[faction]
end

local resolvedDungeonIcon = nil
local function GetDungeonIcon()
	if resolvedDungeonIcon ~= nil then return resolvedDungeonIcon end
	for _, atlas in ipairs(DUNGEON_ICON_CANDIDATES) do
		if IsAtlas(atlas) then
			resolvedDungeonIcon = atlas

			return resolvedDungeonIcon
		end
	end

	resolvedDungeonIcon = DEFAULT_DUNGEON_ICON

	return resolvedDungeonIcon
end

local function GetEntryIcon(entry)
	if entry.icon ~= nil then return entry.icon end
	if entry.kind == "dungeon" then return GetDungeonIcon() end

	return GetIcon(entry.faction)
end

local function ApplyIcon(pin, icon)
	if pin.icon == icon then return end
	pin.icon = icon
	if IsAtlas(icon) and pin.texture.SetAtlas ~= nil then
		pin.texture:SetAtlas(icon)
	else
		pin.texture:SetTexture(icon)
	end
end

local function GetRouteText(route, index)
	local text = route.dest or ""
	if route.mapID ~= nil then
		local info = C_Map.GetMapInfo(route.mapID)
		if info ~= nil and info.name ~= nil and info.name ~= "" and info.name ~= text then text = text .. ", " .. info.name end
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

local function OnPinEnter(pin)
	local entry = pin.entry
	if entry == nil then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	if entry.kind == "dungeon" then
		local name, minLevel, maxLevel, recLevel = GetDungeonInfo(entry)
		GameTooltip:AddLine(name or entry.name, 1, 1, 1)
		GameTooltip:AddLine(MapUtils:Trans("LID_DUNGEONENTRANCE"), 0.6, 0.6, 0.6)
		if minLevel ~= nil and minLevel > 0 then
			if maxLevel ~= nil and maxLevel > minLevel then
				GameTooltip:AddLine(format("%s %d - %d", LEVEL or "Level", minLevel, maxLevel), 1, 0.82, 0)
			else
				GameTooltip:AddLine(format("%s %d", LEVEL or "Level", minLevel), 1, 0.82, 0)
			end
		end

		if recLevel ~= nil then GameTooltip:AddLine(MapUtils:Trans("LID_RECOMMENDEDLEVEL", nil, recLevel), 0.6, 0.6, 0.6) end
	else
		GameTooltip:AddLine(entry.name, 1, 1, 1)
		GameTooltip:AddLine(MapUtils:Trans("LID_SHIPTO"), 0.6, 0.6, 0.6)
		for i, route in ipairs(entry.routes) do
			GameTooltip:AddLine(GetRouteText(route, i), 1, 0.82, 0)
		end
	end

	GameTooltip:Show()
end

local function OnPinLeave()
	GameTooltip:Hide()
end

local function CreatePin(parent, levelOffset)
	local pin = CreateFrame("FRAME", nil, parent)
	pin:SetSize(ICON_SIZE, ICON_SIZE)
	pin:SetFrameLevel(parent:GetFrameLevel() + levelOffset)
	pin:EnableMouse(true)
	pin:SetScript("OnEnter", OnPinEnter)
	pin:SetScript("OnLeave", OnPinLeave)
	pin.texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture:SetAllPoints(pin)

	return pin
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

local function BuildList(mapID, piersOn, dungeonsOn)
	if mapID == nil then return nil end
	local list = nil
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

	return list
end

local worldPins = {}
local worldMapID = nil
local worldScale = nil
local worldPiers = nil
local worldDungeons = nil
local function UpdateWorldPins()
	local child = WorldMapFrame.ScrollContainer.Child
	local mapID = WorldMapFrame:GetMapID()
	local scale = child:GetScale()
	local piersOn = PiersEnabled(true)
	local dungeonsOn = DungeonsEnabled(true)
	if mapID == worldMapID and scale == worldScale and piersOn == worldPiers and dungeonsOn == worldDungeons then return end
	worldMapID = mapID
	worldScale = scale
	worldPiers = piersOn
	worldDungeons = dungeonsOn
	HideAll(worldPins)
	local list = BuildList(mapID, piersOn, dungeonsOn)
	if list == nil then return end
	if scale == nil or scale <= 0 then return end
	local w = child:GetWidth()
	local h = child:GetHeight()
	local size = ICON_SIZE / scale
	for i, entry in ipairs(list) do
		local pin = worldPins[i]
		if pin == nil then
			pin = CreatePin(child, WORLD_PIN_LEVEL)
			worldPins[i] = pin
		end

		pin.entry = entry
		ApplyIcon(pin, GetEntryIcon(entry))
		pin:SetSize(size, size)
		pin:ClearAllPoints()
		pin:SetPoint("CENTER", child, "TOPLEFT", w * entry.x, -h * entry.y)
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
local minimapList = nil
local function GetMinimapList(mapID, piersOn, dungeonsOn)
	if mapID == minimapMapID and piersOn == minimapPiers and dungeonsOn == minimapDungeons then return minimapList end
	minimapMapID = mapID
	minimapPiers = piersOn
	minimapDungeons = dungeonsOn
	minimapList = BuildList(mapID, piersOn, dungeonsOn)

	return minimapList
end

local function UpdateMinimapPins()
	local mapID = C_Map.GetBestMapForUnit("player")
	local list = GetMinimapList(mapID, PiersEnabled(false), DungeonsEnabled(false))
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
if WorldMapFrame ~= nil and WorldMapFrame.ScrollContainer ~= nil and WorldMapFrame.ScrollContainer.Child ~= nil then
	worldUpdater = CreateUpdater(WorldMapFrame, UpdateWorldPins)
end

if Minimap ~= nil then minimapUpdater = CreateUpdater(Minimap, UpdateMinimapPins) end
local function CountPins(mapID)
	if mapID == nil then return 0, 0 end
	local pierCount = 0
	local dungeonCount = 0
	if piers[mapID] ~= nil then pierCount = #piers[mapID] end
	if dungeons[mapID] ~= nil then dungeonCount = #dungeons[mapID] end

	return pierCount, dungeonCount
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
	resolvedDungeonIcon = nil
end

function MapUtils:RefreshPins()
	worldMapID = nil
	worldScale = nil
	worldPiers = nil
	worldDungeons = nil
	minimapMapID = nil
	minimapPiers = nil
	minimapDungeons = nil
	minimapList = nil
	HideAll(worldPins)
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

	MapUtils:INFO("Use /mapdocks icon <atlas or texture path> to try one, /mapdocks icon reset to go back")
end

local function ReportState()
	local playerMapID = C_Map.GetBestMapForUnit("player")
	local canvasMapID = nil
	local mapOpen = false
	if WorldMapFrame ~= nil then
		if WorldMapFrame.GetMapID ~= nil then canvasMapID = WorldMapFrame:GetMapID() end
		mapOpen = WorldMapFrame:IsShown() == true
	end

	local playerPiers, playerDungeons = CountPins(playerMapID)
	local canvasPiers, canvasDungeons = CountPins(canvasMapID)
	MapUtils:INFO("world updater:", worldUpdater ~= nil, "minimap updater:", minimapUpdater ~= nil, "map open:", mapOpen)
	MapUtils:INFO("player uiMapID:", tostring(playerMapID), "-", GetMapName(playerMapID), "- piers:", playerPiers, "- dungeons:", playerDungeons)
	MapUtils:INFO("canvas uiMapID:", tostring(canvasMapID), "-", GetMapName(canvasMapID), "- piers:", canvasPiers, "- dungeons:", canvasDungeons)
	MapUtils:INFO("world pins:", #worldPins, "minimap pins:", #minimapPins, "icon:", GetIcon(DEFAULT_FACTION), "is atlas:", IsAtlas(GetIcon(DEFAULT_FACTION)))
	for i, pin in ipairs(worldPins) do
		local ox, oy = 0, 0
		if pin:GetNumPoints() > 0 then
			local _, _, _, px, py = pin:GetPoint(1)
			ox = px or 0
			oy = py or 0
		end

		MapUtils:INFO(format("world pin %d shown = %s offset = %.1f / %.1f size = %.1f level = %d strata = %s", i, tostring(pin:IsShown()), ox, oy, pin:GetWidth(), pin:GetFrameLevel(), tostring(pin:GetFrameStrata())))
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

	MapUtils:INFO(format("%d LFG entries found, also saved to SavedVariables - /mapdocks clear empties the list again", hits))
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

MapUtils:AddSlash(
	"mapdocks",
	function(args)
		local label = strtrim(args or "")
		local sub, rest = strsplit(" ", label, 2)
		sub = strlower(strtrim(sub or ""))
		rest = strtrim(rest or "")
		if sub == "debug" then
			ReportState()
		elseif sub == "list" then
			ListCaptures()
		elseif sub == "clear" then
			ClearCaptures()
		elseif sub == "lfg" then
			ReportLFG(rest)
		elseif sub == "activities" then
			ReportActivities(rest)
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
)
