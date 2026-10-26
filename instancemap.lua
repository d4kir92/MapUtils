local _, MapUtils = ...
local MEDIA_PATH = "Interface\\AddOns\\MapUtils\\media\\"
local PIN_TOGGLE_KEYS = {
	["boss"] = "BOSSPINS",
	["item"] = "QUESTPINS",
	["entrance"] = "ENTRANCEPINS",
	["level"] = "LEVELPINS",
}

local compendium = _G["AzerothCompendiumAPI"]
if type(compendium) == "table" and compendium.ShowInstanceMap ~= nil then
	function MapUtils:ShowInstanceMap(instances, level)
		return compendium.ShowInstanceMap(instances, level)
	end

	function MapUtils:IsInstanceMapShown()
		return compendium.IsInstanceMapShown()
	end

	function MapUtils:ToggleInstanceMap()
		if not compendium.ToggleInstanceMap() then MapUtils:INFO("No own map for this instance") end
	end

	return
end

local art = {}
local function AddArt(instanceMapID, instanceName, levels)
	art[instanceMapID] = {}
	for i, level in ipairs(levels) do
		art[instanceMapID][i] = {
			["file"] = MEDIA_PATH .. level[1],
			["key"] = tostring(level[1]),
			["instance"] = instanceName,
			["name"] = level[2],
			["width"] = 1024,
			["height"] = MapUtils.INSTANCEARTHEIGHTS ~= nil and MapUtils.INSTANCEARTHEIGHTS[tostring(level[1])] or 683,
			["fileWidth"] = 1024,
			["fileHeight"] = 1024,
			["zoom"] = 1,
		}
	end
end

for instanceMapID, entry in pairs(MapUtils.INSTANCEDATA ~= nil and MapUtils.INSTANCEDATA.art or {}) do
	AddArt(instanceMapID, entry[1], entry[2])
end

local function GetLevelLabel(levels, level)
	local instanceName = MapUtils:TransName(level.instance)
	if level.name == nil then return instanceName end
	for _, other in ipairs(levels) do
		if other.instance ~= level.instance then return instanceName .. " - " .. MapUtils:TransName(level.name) end
	end

	return MapUtils:TransName(level.name)
end

local CreateInstancePins = MapUtils.CreateInstancePins
function MapUtils:CreateInstancePins(parent, options)
	local onEnter = options.onEnter
	local getLevel = options.getLevel
	options.getLevel = function(row)
		local level = getLevel ~= nil and getLevel(row) or nil
		return level or (MapUtils:IsDebug() and 1 or nil)
	end
	options.onEnter = function(pin)
		if not pin.hoverHooked then
			pin.hoverHooked = true
			pin:HookScript("OnLeave", function(button) MapUtils:HidePinHighlight(button) end)
			pin:HookScript("OnHide", function(button) MapUtils:HidePinHighlight(button) end)
		end
		MapUtils:ShowPinHighlight(pin)
		if onEnter ~= nil then onEnter(pin) end
	end
	local onMouseUp = options.onMouseUp
	options.onMouseUp = function(pin, button)
		if button == "LeftButton" and MapUtils:IsDebug() and pin.row ~= nil and pin.row.debugEntry ~= nil then
			MapUtils:SelectDebugPin(pin.row.debugMapKey, pin.row.debugEntry)
		elseif onMouseUp ~= nil then
			onMouseUp(pin, button)
		end
	end
	local set = CreateInstancePins(self, parent, options)
	local update = set.Update
	set.Update = function(pinSet, ...)
		update(pinSet, ...)
		for _, pin in ipairs(pinSet.pins) do
			if pin.row ~= nil and pin.row.debugEntry ~= nil then pin:SetAlpha(MapUtils:GetDebugPinAlpha(pin.row.debugEntry)) end
			pin.highlight:SetAlpha(0)
		end
	end
	return set
end
local instanceMap = MapUtils:CreateInstanceMap(
	{
		["media"] = MEDIA_PATH,
		["isDisabled"] = function() return MapUtils.nativeInstanceMaps end,
		["getLevels"] = function(instanceMapID) return art[instanceMapID] end,
		["getLabel"] = GetLevelLabel,
		["getPins"] = function(info) return MapUtils:GetDebugInstancePins(info) end,
		["getBossName"] = function(row) return MapUtils:TransName(row[5]) end,
		["getLevelHint"] = function() return format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SHOWDESTMAP")) end,
		["getEntranceText"] = function(row) return MapUtils:Trans(row[4] == "raid" and "LID_RAIDENTRANCE" or "LID_DUNGEONENTRANCE") end,
		["isPinEnabled"] = function(kind) return MapUtils:IsDebug() or MapUtils:GetConfig("INSTANCEPINS_" .. strupper(kind), true) ~= false end,
		["setPinEnabled"] = function(kind, enabled) MapUtils:SetSharedOption("INSTANCEPINS_" .. strupper(kind), enabled) end,
		["getToggleText"] = function(kind, enabled) return MapUtils:Trans("LID_" .. (enabled and "HIDE" or "SHOW") .. PIN_TOGGLE_KEYS[kind]) end,
	}
)

function MapUtils:ShowInstanceMap(instances, level)
	return instanceMap:Show(instances, level)
end

function MapUtils:IsInstanceMapShown()
	return instanceMap:IsShown()
end

function MapUtils:RefreshInstanceMap()
	if MapUtils.ClearDebugInstancePins ~= nil then MapUtils:ClearDebugInstancePins() end
	instanceMap:Invalidate()
end

function MapUtils:ToggleInstanceMap()
	if not instanceMap:Toggle() then MapUtils:INFO("No own map for this instance") end
end
