local _, MapUtils = ...
if MapUtils.CreateGuildMap == nil then return end
local Guild = MapUtils:CreateGuildMap({
	owner = "MapUtils",
	priority = 10,
	isHidden = function() return MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() end,
	getClip = function(mapID)
		if MapUtils.IsOneMap ~= nil and MapUtils.IsZoneDetailMap ~= nil and MapUtils:IsOneMap() and MapUtils:IsZoneDetailMap(mapID) then return -50, 51 end

		return 0, 1
	end,
	setPinScale = function(pin, scale) if MapUtils.SetCanvasPinScale ~= nil then MapUtils:SetCanvasPinScale(pin, scale) end end,
	attach = function(guild)
		if MapUtils.CanvasPinLists ~= nil then tinsert(MapUtils.CanvasPinLists, guild.pins) end
		if MapUtils.CanvasPinUpdaters ~= nil then tinsert(MapUtils.CanvasPinUpdaters, function() guild.UpdatePins() end) end
	end
})

if Guild == nil then return end
MapUtils.GuildMembers = Guild
function MapUtils:RefreshGuildMembers()
	Guild.Refresh()
end
