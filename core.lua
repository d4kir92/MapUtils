local _, MapUtils = ...
local dungeonMaps = {}
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
hooksecurefunc(
	WorldMapFrame,
	"Show",
	function()
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID == nil then return end
		if dungeonMaps[mapID] == nil then
			if IsInInstance() then
				print("Missing Dungeon Map - zoneID: " .. mapID)
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
					["layerWidth"] = 1008 * num / 4,
					["layerHeight"] = 763 / 4,
					["tileWidth"] = 1008 / 4,
					["tileHeight"] = 763 / 4,
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
