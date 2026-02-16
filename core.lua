local _, MapUtils = ...
local dungeonMaps = {}
dungeonMaps[256] = {"Interface\\AddOns\\MapUtils\\media\\256-1", "Interface\\AddOns\\MapUtils\\media\\256-2"} -- Auchenaikrypta
dungeonMaps[258] = {"Interface\\AddOns\\MapUtils\\media\\258-1", "Interface\\AddOns\\MapUtils\\media\\258-2"} -- Sethekkhallen
dungeonMaps[260] = {"Interface\\AddOns\\MapUtils\\media\\260"} -- Schattenlabyrinth
dungeonMaps[272] = {"Interface\\AddOns\\MapUtils\\media\\272"} -- Managruft
dungeonMaps[347] = {"Interface\\AddOns\\MapUtils\\media\\347"} -- Höllenfeuerbollwerk
hooksecurefunc(
	WorldMapFrame,
	"Show",
	function()
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID == nil then return end
		if dungeonMaps[mapID] == nil then
			if true then
				print("mapID: " .. mapID)
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
					["layerHeight"] = 768 / 4,
					["tileWidth"] = 1024 / 4,
					["tileHeight"] = 768 / 4,
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
		for i, map in pairs(dungeonMaps[uiMapID]) do
			tinsert(textures, map)
		end
	end

	return textures
end
