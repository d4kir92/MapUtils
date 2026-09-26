local _, MapUtils = ...
local ICON = 134269
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 300
local maset = nil
local function GetTocVersion()
	if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata("MapUtils", "Version") end
	if GetAddOnMetadata then return GetAddOnMetadata("MapUtils", "Version") end

	return "0.0.0"
end

function MapUtils:GetConfig(key, value)
	MAUTTAB = MAUTTAB or {}
	if MAUTTAB[key] == nil then MAUTTAB[key] = value end

	return MAUTTAB[key]
end

function MapUtils:ToggleSettings()
	if maset == nil then return end
	maset:Toggle()
end

local function GetCollapsed(key)
	if key == nil then return nil end
	if type(MAUTTAB) ~= "table" then return nil end
	if type(MAUTTAB["COLLAPSED"]) ~= "table" then return nil end

	return MAUTTAB["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
	if key == nil then return end
	if type(MAUTTAB) ~= "table" then return end
	if type(MAUTTAB["COLLAPSED"]) ~= "table" then MAUTTAB["COLLAPSED"] = {} end
	if collapsed then
		MAUTTAB["COLLAPSED"][key] = true
	else
		MAUTTAB["COLLAPSED"][key] = nil
	end
end

local function AddCategory(key, level)
	maset:AddCategory({
		["label"] = "LID_" .. key,
		["key"] = key,
		["search"] = key,
		["level"] = level
	})
end

local function AddCheckbox(key, default, func, label)
	maset:AddCheckbox({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["value"] = MapUtils:GetConfig(key, default),
		["func"] = function(value)
			MapUtils:SV(MAUTTAB, key, value)
			if func then func() end
		end
	})
end

local function HandleSlash(args)
	local sub = strlower(strtrim(args or ""))
	if sub == "debug" then
		MapUtils:ToggleDebug()
	elseif sub == "map" then
		MapUtils:ToggleInstanceMap()
	else
		MapUtils:ToggleSettings()
	end
end

function MapUtils:InitSetting()
	if maset ~= nil then return end
	MAUTTAB = MAUTTAB or {}
	MapUtils:SetVersion(ICON, GetTocVersion())
	MapUtils:SetAppendTab(MAUTTAB)
	maset = MapUtils:CreateUIWindow({
		["name"] = "MapUtilsSettings",
		["pTab"] = {"CENTER"},
		["width"] = MapUtils:GetConfig("WINDOWWIDTH", DEFAULT_WIDTH),
		["height"] = MapUtils:GetConfig("WINDOWHEIGHT", DEFAULT_HEIGHT),
		["minWidth"] = 340,
		["minHeight"] = 220,
		["onResize"] = function(width, height)
			MapUtils:SV(MAUTTAB, "WINDOWWIDTH", width)
			MapUtils:SV(MAUTTAB, "WINDOWHEIGHT", height)
		end,
		["getCollapsed"] = function(key) return GetCollapsed(key) end,
		["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
		["title"] = format("|T%d:16:16:0:0|t MapUtils v%s", ICON, GetTocVersion())
	})

	maset:SuspendLayout()
	maset:AddSearch()
	AddCategory("GENERAL")
	AddCheckbox("MMBTN", MapUtils:GetWoWBuild() ~= "RETAIL", function()
		if MAUTTAB["MMBTN"] then
			MapUtils:ShowMMBtn("MapUtils")
		else
			MapUtils:HideMMBtn("MapUtils")
		end
	end)

	AddCheckbox("INSTANCEMAP", true)
	AddCheckbox("ZONELEVELS", true)
	AddCheckbox("FISHINGLEVELS", true)
	AddCategory("PIERS")
	AddCheckbox("WORLDMAPPINS", true, function() MapUtils:RefreshPins() end)
	AddCheckbox("MINIMAPPINS", true, function() MapUtils:RefreshPins() end)
	AddCategory("DUNGEONS")
	AddCheckbox("DUNGEONWORLDMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_WORLDMAPPINS")
	AddCheckbox("DUNGEONMINIMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS")
	AddCategory("FLIGHTPOINTS")
	AddCheckbox("FLIGHTWORLDMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_WORLDMAPPINS")
	AddCheckbox("FLIGHTMINIMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS")
	maset:ResumeLayout()
	MapUtils:CreateMinimapButton({
		["name"] = "MapUtils",
		["icon"] = ICON,
		["dbtab"] = MAUTTAB,
		["vTT"] = {{format("|T%d:16:16:0:0|t MapUtils", ICON), "v" .. GetTocVersion()}, {MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_OPENSETTINGS")}, {MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_HIDEMINIMAPBUTTON")}},
		["funcL"] = function() MapUtils:ToggleSettings() end,
		["funcR"] = function()
			MapUtils:SV(MAUTTAB, "MMBTN", false)
			MapUtils:INFO("Minimap Button is now hidden.")
			MapUtils:HideMMBtn("MapUtils")
		end,
		["dbkey"] = "MMBTN"
	})

	MapUtils:AddSlash("maputils", HandleSlash)
end

local loader = CreateFrame("FRAME")
MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
loader:SetScript("OnEvent", function() MapUtils:InitSetting() end)
