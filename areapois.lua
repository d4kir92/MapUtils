local _, MapUtils = ...
local flavor = MapUtils:GetFlavor()
if flavor ~= "era" and flavor ~= "tbc" then return end
if C_AreaPoiInfo == nil or C_AreaPoiInfo.GetAreaPOIInfo == nil then return end
local AreaPOIs = {
	template = "AreaPOIPinTemplate",
	towns = {
		[4] = true,
		[6] = true
	},
	capitals = {
		[8] = true,
		[16] = true,
		[18] = true,
		[29] = true,
		[33] = true,
		[38] = true,
		[1704] = true,
		[1785] = true,
		[1961] = true
	},
	maps = {},
	hooked = {}
}

MapUtils.AreaPOIs = AreaPOIs
function AreaPOIs.IsHidden(mapID, pin)
	local id = pin.areaPoiID
	if id == nil then return false end
	if AreaPOIs.capitals[id] then return MapUtils:GetConfig("CAPITALPOIS", false) ~= true end
	if MapUtils:GetConfig("TOWNPOIS", false) == true or mapID == nil then return false end
	local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, id)

	return info ~= nil and AreaPOIs.towns[info.textureIndex] == true
end

function AreaPOIs.Apply(map)
	if map == nil or map.EnumeratePinsByTemplate == nil then return end
	local mapID = map:GetMapID()
	for pin in map:EnumeratePinsByTemplate(AreaPOIs.template) do
		pin:SetShown(not AreaPOIs.IsHidden(mapID, pin))
	end
end

function AreaPOIs.Install(map)
	if map == nil or AreaPOIs.hooked[map] or type(map.dataProviders) ~= "table" then return end
	for provider in pairs(map.dataProviders) do
		if type(provider) == "table" and provider.GetPinTemplate ~= nil and provider.RefreshAllData ~= nil and provider:GetPinTemplate() == AreaPOIs.template then
			AreaPOIs.hooked[map] = true
			tinsert(AreaPOIs.maps, map)
			hooksecurefunc(
				provider,
				"RefreshAllData",
				function()
					AreaPOIs.Apply(map)
				end
			)

			AreaPOIs.Apply(map)

			return
		end
	end
end

function AreaPOIs.InstallAll()
	AreaPOIs.Install(_G["WorldMapFrame"])
	AreaPOIs.Install(_G["BattlefieldMapFrame"])
end

function MapUtils:RefreshAreaPOIs()
	AreaPOIs.InstallAll()
	for _, map in ipairs(AreaPOIs.maps) do
		AreaPOIs.Apply(map)
	end
end

AreaPOIs.loader = CreateFrame("FRAME")
AreaPOIs.loader:RegisterEvent("PLAYER_LOGIN")
AreaPOIs.loader:RegisterEvent("ADDON_LOADED")
AreaPOIs.loader:SetScript("OnEvent", AreaPOIs.InstallAll)
