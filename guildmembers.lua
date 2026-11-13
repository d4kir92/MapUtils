local _, MapUtils = ...
if MapUtils.CreateGuildMap == nil then return end
local Guild = MapUtils:CreateGuildMap({
	owner = "MapUtils",
	priority = 10,
	isHidden = function(mapID)
		if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return true end
		if not MapUtils:IsPinCategoryEnabled("GUILDMEMBERPINS") then return true end

		return not MapUtils:GetGuildPinScopeShown(MapUtils:IsAzerothMap(mapID))
	end,
	getClip = function(mapID)
		if MapUtils.IsOneMap ~= nil and MapUtils.IsZoneDetailMap ~= nil and MapUtils:IsOneMap() and MapUtils:IsZoneDetailMap(mapID) then return -50, 51 end

		return 0, 1
	end,
	getZoneSpace = function(mapID)
		if MapUtils.IsZoneDetailMap ~= nil and MapUtils.GetZoneDetailSpace ~= nil and MapUtils:IsZoneDetailMap(mapID) then return MapUtils:GetZoneDetailSpace(mapID) end
	end,
	setPinScale = function(pin, scale) if MapUtils.SetCanvasPinScale ~= nil then MapUtils:SetCanvasPinScale(pin, scale) end end,
	attach = function(guild)
		if MapUtils.CanvasPinLists ~= nil then tinsert(MapUtils.CanvasPinLists, guild.pins) end
		if MapUtils.RegisterRenderLayer ~= nil then MapUtils:RegisterRenderLayer("Guild pins", function() return guild.pins end) end
		if MapUtils.CanvasPinUpdaters ~= nil then tinsert(MapUtils.CanvasPinUpdaters, function() guild.UpdatePins() end) end
	end
})

if Guild == nil then return end
MapUtils.GuildMembers = Guild
function MapUtils:RefreshGuildMembers()
	Guild.Refresh()
end

function MapUtils:GetGuildPinScopeShown(azeroth)
	if MapUtils:GetConfig("GUILDMEMBERPINS", true) ~= true then return false end
	local zone = MAUTTAB["GUILDMEMBERPINS_ZONE"] ~= false
	if not azeroth or MAUTTAB["GUILDMEMBERPINS_AZEROTH"] == nil then return zone end

	return MAUTTAB["GUILDMEMBERPINS_AZEROTH"] == true
end

function MapUtils:SetGuildPinScopeShown(azeroth, value)
	local zone, az = MapUtils:GetGuildPinScopeShown(false), MapUtils:GetGuildPinScopeShown(true)
	if azeroth then
		az = value == true
	else
		zone = value == true
	end

	MapUtils:SV(MAUTTAB, "GUILDMEMBERPINS_ZONE", zone)
	MapUtils:SV(MAUTTAB, "GUILDMEMBERPINS_AZEROTH", az)
	MapUtils:SetGuildOption("GUILDMEMBERPINS", zone or az)
end
