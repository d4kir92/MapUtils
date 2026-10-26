local _, MapUtils = ...
MapUtils:SetAddonOutput()
local instanceData = MapUtils.INSTANCEDATA or {["dungeonMaps"] = {}, ["raidMaps"] = {}, ["instanceToMap"] = {}, ["art"] = {}}
local dungeonMaps = instanceData.dungeonMaps
local raidMaps = instanceData.raidMaps
local instanceToMap = instanceData.instanceToMap
local MAX_WORLD_MAP_TYPE = 2
local artTypes = {}
local function HasOwnArt(mapID)
	if mapID == nil then return false end
	if dungeonMaps[mapID] == nil and raidMaps[mapID] == nil then return false end
	if artTypes[mapID] == nil then
		local info = C_Map.GetMapInfo(mapID)
		if info == nil then return false end
		if info.mapType ~= nil and info.mapType <= MAX_WORLD_MAP_TYPE then
			artTypes[mapID] = false
		else
			artTypes[mapID] = true
		end
	end
	return artTypes[mapID]
end

local function IsOptionEnabled(key)
	if type(MAUTTAB) ~= "table" then return true end

	return MAUTTAB[key] ~= false
end

local function IsArtEnabled(mapID)
	if not HasOwnArt(mapID) then return false end
	if dungeonMaps[mapID] then return IsOptionEnabled("DUNGEONMAPS") end
	if raidMaps[mapID] then return IsOptionEnabled("RAIDMAPS") end

	return false
end

local missingMaps = {}
hooksecurefunc(WorldMapFrame, "Show", function()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
		if instanceMapID and instanceToMap[instanceMapID] then mapID = instanceToMap[instanceMapID] end
	end

	if mapID == nil then return end
	if dungeonMaps[mapID] == nil and raidMaps[mapID] == nil then
		local inInstance, instanceType = IsInInstance()
		if inInstance and missingMaps[mapID] == nil then
			missingMaps[mapID] = true
			if instanceType == "raid" and raidMaps[mapID] == nil then
				MapUtils:INFO("Missing Raid Map - zoneID: " .. mapID .. " (Send to Developer: zoneID and RaidName)")
			elseif instanceType == "party" and dungeonMaps[mapID] == nil then
				MapUtils:INFO("Missing Dungeon Map - zoneID: " .. mapID .. " (Send to Developer: zoneID and DungeonName)")
			end
		end
		return
	end

	if not IsArtEnabled(mapID) then return end
	if WorldMapFrame:GetMapID() ~= mapID then WorldMapFrame:SetMapID(mapID) end
end)

local oldGetMapArtLayers = C_Map.GetMapArtLayers
local function GetMapArtLayers(mapID)
	if not IsArtEnabled(mapID) then return oldGetMapArtLayers(mapID) end
	if dungeonMaps[mapID] then
		local num = dungeonMaps[mapID] and #dungeonMaps[mapID] or 1
		local result = {}
		for i, map in pairs(dungeonMaps[mapID]) do
			tinsert(result, {
				["layerWidth"] = 1024 * num / 4,
				["layerHeight"] = 683 / 4,
				["tileWidth"] = 1024 / 4,
				["tileHeight"] = 683 / 4,
				["minScale"] = 1,
				["maxScale"] = 2.5,
				["additionalZoomSteps"] = 6,
			})
		end
		return result
	elseif raidMaps[mapID] then
		local num = raidMaps[mapID] and #raidMaps[mapID] or 1
		local result = {}
		for i, map in pairs(raidMaps[mapID]) do
			tinsert(result, {
				["layerWidth"] = 1024 * num / 4,
				["layerHeight"] = 683 / 4,
				["tileWidth"] = 1024 / 4,
				["tileHeight"] = 683 / 4,
				["minScale"] = 1,
				["maxScale"] = 2.5,
				["additionalZoomSteps"] = 6,
			})
		end
		return result
	end
	return oldGetMapArtLayers(mapID)
end

local oldGetMapArtLayerTextures = C_Map.GetMapArtLayerTextures
local function GetMapArtLayerTextures(uiMapID, layerIndex)
	local textures = oldGetMapArtLayerTextures(uiMapID, layerIndex)
	if not IsArtEnabled(uiMapID) then return textures end
	if dungeonMaps[uiMapID] then
		textures = {}
		for i, map in pairs(dungeonMaps[uiMapID]) do
			tinsert(textures, map)
		end
	elseif raidMaps[uiMapID] then
		textures = {}
		for i, map in pairs(raidMaps[uiMapID]) do
			tinsert(textures, map)
		end
	end
	return textures
end

local function ClientHasOwnMaps()
	if C_Map.GetMapInfo(947) == nil then return true end
	for mapID in pairs(dungeonMaps) do
		if HasOwnArt(mapID) then return true end
	end

	for mapID in pairs(raidMaps) do
		if HasOwnArt(mapID) then return true end
	end
	return false
end

MapUtils.nativeInstanceMaps = ClientHasOwnMaps()
if MapUtils.nativeInstanceMaps then
	C_Map.GetMapArtLayers = GetMapArtLayers
	C_Map.GetMapArtLayerTextures = GetMapArtLayerTextures
end
