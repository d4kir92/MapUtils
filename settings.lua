local _, MapUtils = ...
local ICON = 134269
local DEFAULT_WIDTH = 420
local DEFAULT_HEIGHT = 300
local ADDED_0927 = "2026-09-27"
local ADDED_0928 = "2026-09-28"
local ADDED_1003 = "2026-10-03"
local ADDED_1004 = "2026-10-04"
local SHARED_KEYS = {"DUNGEONWORLDMAPPINS", "MEETINGSTONEWORLDMAPPINS", "DUNGEONMINIMAPPINS", "MEETINGSTONEMINIMAPPINS", "INSTANCEPINS_BOSS", "INSTANCEPINS_ITEM", "INSTANCEPINS_ENTRANCE", "INSTANCEPINS_LEVEL"}
local maset = nil
local sharedCheckboxes = {}
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

function MapUtils:OnSharedOptionChanged(key, value)
	if sharedCheckboxes[key] ~= nil then sharedCheckboxes[key]:SetChecked(value) end
	MapUtils:RefreshPins()
	if MapUtils.RefreshInstanceMap ~= nil then MapUtils:RefreshInstanceMap() end
end

function MapUtils:SetSharedOption(key, value)
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, key, value)
	MapUtils:SetSharedSetting(key, value)
	MapUtils:OnSharedOptionChanged(key, value)
end

MapUtils:RegisterSharedSettings(
	{
		["keys"] = SHARED_KEYS,
		["getDB"] = function() return MAUTTAB end,
		["get"] = function(key) return MapUtils:GetConfig(key, true) end,
		["set"] = function(key, value) MAUTTAB[key] = value end,
		["onChange"] = function(key, value) MapUtils:OnSharedOptionChanged(key, value) end,
	}
)

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

local function AddCategory(key, level, label, added)
	maset:AddCategory({
		["label"] = label or ("LID_" .. key),
		["key"] = key,
		["search"] = key,
		["level"] = level,
		["added"] = added
	})
end

local function Requires(control, key)
	return maset:AddDependency(control, function() return type(MAUTTAB) == "table" and MAUTTAB[key] == true end)
end

local function AddCheckbox(key, default, func, label, added)
	return maset:AddCheckbox({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["added"] = added,
		["value"] = MapUtils:GetConfig(key, default),
		["func"] = function(value)
			MapUtils:SV(MAUTTAB, key, value)
			if func then func() end
			maset:UpdateDependencies()
		end
	})
end

local function AddSharedCheckbox(key, label, added)
	sharedCheckboxes[key] = maset:AddCheckbox(
		{
			["label"] = label,
			["search"] = key,
			["added"] = added,
			["value"] = MapUtils:GetConfig(key, true),
			["func"] = function(value) MapUtils:SetSharedOption(key, value) end
		}
	)
end

local function AddDropdown(key, default, choices, func, label, added)
	return maset:AddDropdown({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["added"] = added,
		["value"] = MapUtils:GetConfig(key, default),
		["choices"] = choices,
		["func"] = function(value)
			MapUtils:SV(MAUTTAB, key, value)
			if func then func() end
		end
	})
end

local function AddSlider(key, default, minValue, maxValue, step, func, label, added)
	return maset:AddSlider({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["added"] = added,
		["value"] = MapUtils:GetConfig(key, default),
		["min"] = minValue,
		["max"] = maxValue,
		["step"] = step,
		["decimals"] = 0,
		["func"] = function(value)
			MapUtils:SV(MAUTTAB, key, value)
			if func then func() end
		end
	})
end

local function HandleSlash(args)
	local sub = strlower(strtrim(args or ""))
	if sub:match("^debug%s+help$") then
		MapUtils:PrintDebugHelp()
	elseif sub == "debug" then
		MapUtils:ToggleDebug()
	elseif sub == "pos" then
		MapUtils:PrintPlayerPosition()
	elseif sub == "fade" then
		MapUtils:PrintFadeDebug()
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

	AddCategory("WORLDMAP", nil, nil, ADDED_0927)
	if MapUtils:IsForever() then AddCheckbox("REMEMBERQUESTCATEGORIES", true, function() MapUtils:RestoreQuestCategories() end) end
	AddCategory("MAPWINDOW", 2, nil, ADDED_0927)
	AddCheckbox("WORLDMAPMOVE", true, function() MapUtils:RefreshWorldMapFrame() end, nil, ADDED_0927)
	AddCheckbox("WORLDMAPSCALE", true, function() MapUtils:RefreshWorldMapFrame() end, nil, ADDED_0927)
	AddCategory("NAVIGATION", 2, nil, ADDED_0928)
	AddCheckbox("ALWAYSSHOWWAYPOINT", false, nil, nil, ADDED_0928)
	AddCategory("MAPFADE", 2, nil, ADDED_0927)
	AddCheckbox("WORLDMAPFADE", false, function() MapUtils:RefreshWorldMapFrame() end, nil, ADDED_0927)
	Requires(AddSlider("WORLDMAPFADEOPACITY", 50, 0, 100, 5, nil, nil, ADDED_0927), "WORLDMAPFADE")
	if MapUtils.nativeInstanceMaps then
		AddCategory("INSTANCEMAPS", 2, nil, ADDED_0927)
		AddCheckbox("DUNGEONMAPS", true, nil, nil, ADDED_0927)
		AddCheckbox("RAIDMAPS", true, nil, nil, ADDED_0927)
	end

	AddCategory("MAPLABELS", 2)
	AddCheckbox("ZONELEVELS", true)
	AddCheckbox("ZONERECLEVELS", true, nil, nil, "2026-10-02")
	AddCheckbox("FISHINGLEVELS", true)
	if MapUtils:HasRevealData() then
		AddCategory("REVEAL", 2, nil, ADDED_0928)
		local revealLabel = nil
		if MapUtils:IsRevealedByLeatrix() then revealLabel = MapUtils:Trans("LID_REVEALMAP") .. " |cffff8000(" .. MapUtils:Trans("LID_REVEALLEATRIX") .. ")|r" end
		AddCheckbox("REVEALMAP", true, function() MapUtils:RefreshReveal() end, revealLabel, ADDED_0928)
		Requires(AddDropdown("REVEALTINT", "BLUE", MapUtils:GetRevealTintChoices(), function() MapUtils:RefreshReveal() end, nil, ADDED_0928), "REVEALMAP")
	end

	AddCategory("BATTLEFIELDMAP", nil, nil, ADDED_0927)
	AddCategory("BATTLEFIELDMAPWINDOW", 2, "LID_MAPWINDOW", ADDED_0927)
	AddCheckbox("BATTLEFIELDMAPSCALE", true, function() MapUtils:RefreshBattlefieldMap() end, nil, ADDED_0927)
	AddCategory("BATTLEFIELDMAPFADECAT", 2, "LID_MAPFADE", ADDED_0927)
	AddCheckbox("BATTLEFIELDMAPFADE", false, function() MapUtils:RefreshBattlefieldMap() end, nil, ADDED_0927)
	Requires(AddSlider("BATTLEFIELDMAPFADEOPACITY", 50, 0, 100, 5, function() MapUtils:RefreshBattlefieldMap() end, "LID_WORLDMAPFADEOPACITY", ADDED_0927), "BATTLEFIELDMAPFADE")
	AddCategory("MAPICONS")
	AddCategory("PIERS", 2)
	AddCheckbox("WORLDMAPPINS", true, function() MapUtils:RefreshPins() end)
	AddCheckbox("MINIMAPPINS", true, function() MapUtils:RefreshPins() end)
	AddCategory("DUNGEONS", 2)
	AddSharedCheckbox("DUNGEONWORLDMAPPINS", "LID_WORLDMAPPINS")
	AddSharedCheckbox("DUNGEONMINIMAPPINS", "LID_MINIMAPPINS")
	AddCategory("MEETINGSTONES", 2, nil, ADDED_0928)
	AddSharedCheckbox("MEETINGSTONEWORLDMAPPINS", "LID_WORLDMAPPINS", ADDED_0928)
	AddSharedCheckbox("MEETINGSTONEMINIMAPPINS", "LID_MINIMAPPINS", ADDED_0928)
	if not MapUtils.nativeInstanceMaps then
		AddCategory("INSTANCEMAPPINS", 2, "LID_INSTANCEMAPS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_BOSS", "LID_SHOWBOSSPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_ITEM", "LID_SHOWQUESTPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_ENTRANCE", "LID_SHOWENTRANCEPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_LEVEL", "LID_SHOWLEVELPINS", ADDED_1004)
	end

	AddCategory("FLIGHTPOINTS", 2)
	AddCheckbox("FLIGHTWORLDMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_WORLDMAPPINS")
	AddCheckbox("FLIGHTMINIMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS")
	AddCategory("ZONECROSSINGS", 2, nil, ADDED_1003)
	AddCheckbox("CROSSINGWORLDMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_WORLDMAPPINS", ADDED_1003)
	maset:UpdateDependencies()
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

function MapUtils:RegisterCompendiumTabs()
	local api = _G["AzerothCompendiumAPI"]
	if type(api) ~= "table" or type(api.RegisterTab) ~= "function" then return end
	api.RegisterTab("MapUtils", {
		label = "MapUtils",
		icon = ICON,
		onClick = function()
			if maset ~= nil then maset:Show() end
		end
	})
end

loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		MapUtils:InitSetting()
		MapUtils:RegisterCompendiumTabs()
	elseif name == "AzerothCompendium" then
		MapUtils:RegisterCompendiumTabs()
	end
end)
MapUtils:RegisterCompendiumTabs()