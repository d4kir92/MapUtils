local _, MapUtils = ...
local flavor = MapUtils:GetFlavor()
if flavor ~= "era" and flavor ~= "tbc" and flavor ~= "forever" then return end
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
function AreaPOIs.GetID(pin)
	if pin.areaPoiID ~= nil then return pin.areaPoiID end
	if type(pin.poiInfo) == "table" and pin.poiInfo.areaPoiID ~= nil then return pin.poiInfo.areaPoiID end
	if pin.GetAreaPOIID ~= nil then return pin:GetAreaPOIID() end

	return nil
end

function AreaPOIs.IsHidden(mapID, pin)
	local id = AreaPOIs.GetID(pin)
	if id == nil then return false end
	if AreaPOIs.capitals[id] then return MapUtils:GetConfig("CAPITALPOIS", false) ~= true end
	if MapUtils:GetConfig("TOWNPOIS", false) == true or mapID == nil then return false end
	local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, id)
	if info == nil and type(pin.poiInfo) == "table" and pin.poiInfo.areaPoiID == id then info = pin.poiInfo end

	return info ~= nil and AreaPOIs.towns[info.textureIndex] == true
end

function AreaPOIs.OnPinShow(pin)
	local map = pin.GetMap and pin:GetMap()
	if map ~= nil and map.GetMapID ~= nil and AreaPOIs.IsHidden(map:GetMapID(), pin) then pin:Hide() end
end

function AreaPOIs.Apply(map)
	if map == nil or map.EnumeratePinsByTemplate == nil then return end
	local mapID = map:GetMapID()
	for pin in map:EnumeratePinsByTemplate(AreaPOIs.template) do
		if not AreaPOIs.hooked[pin] then
			AreaPOIs.hooked[pin] = true
			pin:HookScript("OnShow", AreaPOIs.OnPinShow)
		end

		pin:SetShown(not AreaPOIs.IsHidden(mapID, pin))
	end
end

function AreaPOIs.GetTemplate(provider)
	local ok, template = pcall(provider.GetPinTemplate, provider)
	if ok then return template end

	return nil
end

function AreaPOIs.Install(map)
	if map == nil or AreaPOIs.hooked[map] or type(map.dataProviders) ~= "table" then return end
	for provider in pairs(map.dataProviders) do
		if type(provider) == "table" and provider.GetPinTemplate ~= nil and provider.RefreshAllData ~= nil and AreaPOIs.GetTemplate(provider) == AreaPOIs.template then
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

function AreaPOIs.Report()
	local map = _G["WorldMapFrame"]
	if map == nil or map.pinPools == nil then return end
	local mapID = map:GetMapID()
	MapUtils:INFO(format("map %s | TOWNPOIS %s | CAPITALPOIS %s | hooked %s", tostring(mapID), tostring(MapUtils:GetConfig("TOWNPOIS", false)), tostring(MapUtils:GetConfig("CAPITALPOIS", false)), tostring(AreaPOIs.hooked[map] == true)))
	for template, pool in pairs(map.pinPools) do
		if pool.EnumerateActive ~= nil then
			for pin in pool:EnumerateActive() do
				local id = AreaPOIs.GetID(pin)
				if id ~= nil or type(pin.name) == "string" then
					local info = id and mapID and C_AreaPoiInfo.GetAreaPOIInfo(mapID, id)
					local index = info and info.textureIndex or pin.poiInfo and pin.poiInfo.textureIndex
					MapUtils:INFO(format("%s | %s | id %s | textureIndex %s | atlas %s | shown %s | alpha %.2f | hidden %s | hook %s", tostring(template), tostring(pin.name), tostring(id), tostring(index), tostring(info and info.atlasName), tostring(pin:IsShown()), pin:GetAlpha(), tostring(template == AreaPOIs.template and AreaPOIs.IsHidden(mapID, pin)), tostring(AreaPOIs.hooked[pin] == true)))
				end
			end
		end
	end
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
