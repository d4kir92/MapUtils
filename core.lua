local _, MapUtils = ...
MapUtils:SetAddonOutput("MapUtils", 134269)
local dungeonMaps = {}
local raidMaps = {}
-- Classic ERA:
dungeonMaps[225] = {"Interface\\AddOns\\MapUtils\\media\\225"} -- The Stockade
-- TBC:
dungeonMaps[246] = {"Interface\\AddOns\\MapUtils\\media\\246"} -- The Shattered Halls
dungeonMaps[256] = {"Interface\\AddOns\\MapUtils\\media\\256"} -- Auchenaikrypta
dungeonMaps[257] = {"Interface\\AddOns\\MapUtils\\media\\257"} -- Auchenaikrypta
dungeonMaps[258] = {"Interface\\AddOns\\MapUtils\\media\\258"} -- Sethekkhallen
dungeonMaps[259] = {"Interface\\AddOns\\MapUtils\\media\\259"} -- Sethekkhallen
dungeonMaps[260] = {"Interface\\AddOns\\MapUtils\\media\\260"} -- Schattenlabyrinth
dungeonMaps[261] = {"Interface\\AddOns\\MapUtils\\media\\261"} -- Der Blutkessel
dungeonMaps[262] = {"Interface\\AddOns\\MapUtils\\media\\262"} -- The Underbog
dungeonMaps[263] = {"Interface\\AddOns\\MapUtils\\media\\263"} -- The Steamvault
dungeonMaps[265] = {"Interface\\AddOns\\MapUtils\\media\\265"} -- The Slave Pens
dungeonMaps[266] = {"Interface\\AddOns\\MapUtils\\media\\266"} -- The Botanica
dungeonMaps[267] = {"Interface\\AddOns\\MapUtils\\media\\267"} -- The Mechanar
dungeonMaps[268] = {"Interface\\AddOns\\MapUtils\\media\\268"} -- The Mechanar
dungeonMaps[269] = {"Interface\\AddOns\\MapUtils\\media\\269"} -- The Arcatraz
dungeonMaps[270] = {"Interface\\AddOns\\MapUtils\\media\\270"} -- The Arcatraz
dungeonMaps[271] = {"Interface\\AddOns\\MapUtils\\media\\271"} -- The Arcatraz
dungeonMaps[272] = {"Interface\\AddOns\\MapUtils\\media\\272"} -- Managruft
dungeonMaps[273] = {"Interface\\AddOns\\MapUtils\\media\\273"} -- The Black Morass
dungeonMaps[274] = {"Interface\\AddOns\\MapUtils\\media\\274"} -- Old Hillsbrad Foothills
dungeonMaps[347] = {"Interface\\AddOns\\MapUtils\\media\\347"} -- Höllenfeuerbollwerk
raidMaps[330] = {"Interface\\AddOns\\MapUtils\\media\\330"} -- Gruul's Lair
raidMaps[331] = {"Interface\\AddOns\\MapUtils\\media\\331"} -- Magtheridon's Lair
raidMaps[350] = {"Interface\\AddOns\\MapUtils\\media\\350"} -- Karazhan
raidMaps[351] = {"Interface\\AddOns\\MapUtils\\media\\351"} -- Karazhan
raidMaps[352] = {"Interface\\AddOns\\MapUtils\\media\\352"} -- Karazhan
raidMaps[353] = {"Interface\\AddOns\\MapUtils\\media\\353"} -- Karazhan
raidMaps[354] = {"Interface\\AddOns\\MapUtils\\media\\354"} -- Karazhan
raidMaps[355] = {"Interface\\AddOns\\MapUtils\\media\\355"} -- Karazhan
raidMaps[356] = {"Interface\\AddOns\\MapUtils\\media\\356"} -- Karazhan
raidMaps[357] = {"Interface\\AddOns\\MapUtils\\media\\357"} -- Karazhan
raidMaps[358] = {"Interface\\AddOns\\MapUtils\\media\\358"} -- Karazhan
raidMaps[359] = {"Interface\\AddOns\\MapUtils\\media\\359"} -- Karazhan
raidMaps[360] = {"Interface\\AddOns\\MapUtils\\media\\360"} -- Karazhan
raidMaps[361] = {"Interface\\AddOns\\MapUtils\\media\\361"} -- Karazhan
raidMaps[362] = {"Interface\\AddOns\\MapUtils\\media\\362"} -- Karazhan
raidMaps[363] = {"Interface\\AddOns\\MapUtils\\media\\363"} -- Karazhan
raidMaps[364] = {"Interface\\AddOns\\MapUtils\\media\\364"} -- Karazhan
raidMaps[365] = {"Interface\\AddOns\\MapUtils\\media\\365"} -- Karazhan
raidMaps[366] = {"Interface\\AddOns\\MapUtils\\media\\366"} -- Karazhan
local missingMaps = {}
hooksecurefunc(
	WorldMapFrame,
	"Show",
	function()
		local mapID = C_Map.GetBestMapForUnit("player")
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

		WorldMapFrame.mapID = mapID
		WorldMapFrame:SetMapID(mapID)
		WorldMapFrame:RefreshDetailLayers()
	end
)

local oldGetMapArtLayers = C_Map.GetMapArtLayers
function C_Map.GetMapArtLayers(mapID)
	if mapID == nil then return oldGetMapArtLayers(mapID) end
	if dungeonMaps[mapID] then
		local num = dungeonMaps[mapID] and #dungeonMaps[mapID] or 1
		local result = {}
		for i, map in pairs(dungeonMaps[mapID]) do
			tinsert(
				result,
				{
					["layerWidth"] = 1024 * num / 4,
					["layerHeight"] = 683 / 4,
					["tileWidth"] = 1024 / 4,
					["tileHeight"] = 683 / 4,
					["minScale"] = 1,
					["maxScale"] = 2.5,
					["additionalZoomSteps"] = 6,
				}
			)
		end

		return result
	end

	return oldGetMapArtLayers(mapID)
end

local oldGetMapArtLayerTextures = C_Map.GetMapArtLayerTextures
function C_Map.GetMapArtLayerTextures(uiMapID, layerIndex)
	local textures = oldGetMapArtLayerTextures(uiMapID, layerIndex)
	if dungeonMaps[uiMapID] then
		textures = {}
		for i, map in pairs(dungeonMaps[uiMapID]) do
			tinsert(textures, map)
		end
	end

	return textures
end
