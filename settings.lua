local _, MapUtils = ...
local ICON = MapUtils:GetAddonIcon()
local DEFAULT_WIDTH = 620
local DEFAULT_HEIGHT = 420
local MIN_WIDTH = 500
local DISCORD = "https://discord.gg/RaQas87749"
local ADDED_0927 = "2026-09-27"
local ADDED_0928 = "2026-09-28"
local ADDED_1003 = "2026-10-03"
local ADDED_1004 = "2026-10-04"
local ADDED_1017 = "2026-10-17"
local ADDED_1019 = "2026-10-19"
local ADDED_1022 = "2026-10-22"
local ADDED_1104 = "2026-11-04"
local SHARED_KEYS = {"DUNGEONWORLDMAPPINS", "MEETINGSTONEWORLDMAPPINS", "DUNGEONMINIMAPPINS", "MEETINGSTONEMINIMAPPINS", "INSTANCEPINS_BOSS", "INSTANCEPINS_ITEM", "INSTANCEPINS_ENTRANCE", "INSTANCEPINS_LEVEL"}
local maset = nil
local sharedCheckboxes = {}
local cvarCheckboxes = {}
local guildCheckboxes = {}
local optionCheckboxes = {}

MapUtils:RegisterSharedSettings({
	keys = {"GUILDMEMBERPINS", "GUILDMEMBERLEVEL", "GUILDMEMBERNAME", "GUILDMEMBERSHARE", "GUILDMEMBERZONES"},
	getDB = function()
		MAUTTAB = MAUTTAB or {}

		return MAUTTAB
	end,
	get = function(key)
		local value = MAUTTAB[key]
		if value == nil and GHTABPC then value = GHTABPC[key] end
		if value == nil then value = key == "GUILDMEMBERPINS" or key == "GUILDMEMBERSHARE" or key == "GUILDMEMBERZONES" end
		MAUTTAB[key] = value

		return value
	end,
	set = function(key, value) MAUTTAB[key] = value end,
	onChange = function(key, value)
		if guildCheckboxes[key] then
			guildCheckboxes[key]:SetChecked(value)
			maset:UpdateDependencies()
		end
		if MapUtils.RefreshGuildMembers then MapUtils:RefreshGuildMembers() end
	end
})

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

function MapUtils:SetMapOption(key, value, func)
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, key, value)
	if optionCheckboxes[key] then
		optionCheckboxes[key]:SetChecked(value)
		if maset ~= nil then maset:UpdateDependencies() end
	end
	if func then func() end
end

function MapUtils:SetGuildOption(key, value)
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, key, value)
	MapUtils:SetSharedSetting(key, value)
	if guildCheckboxes[key] then
		guildCheckboxes[key]:SetChecked(value)
		if maset ~= nil then maset:UpdateDependencies() end
	end
	if MapUtils.RefreshGuildMembers then MapUtils:RefreshGuildMembers() end
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
	optionCheckboxes[key] = maset:AddCheckbox({
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

	return optionCheckboxes[key]
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

local function GetCVarValue(cvar)
	local getter = C_CVar and C_CVar.GetCVar or GetCVar
	if getter == nil then return nil end

	return getter(cvar)
end

local function AddCVarCheckbox(cvar, label, added)
	if GetCVarValue(cvar) == nil then return AddCheckbox(strupper(cvar), MapUtils:GetCoordsOptionDefault(cvar), function() MapUtils:RefreshCoords() end, label, added) end
	cvarCheckboxes[strlower(cvar)] = maset:AddCheckbox(
		{
			["label"] = label,
			["search"] = cvar,
			["added"] = added,
			["value"] = GetCVarValue(cvar) == "1",
			["func"] = function(value)
				local setter = C_CVar and C_CVar.SetCVar or SetCVar
				if setter ~= nil then setter(cvar, value and "1" or "0") end
				MapUtils:RefreshCoords()
				maset:UpdateDependencies()
			end
		}
	)

	return cvarCheckboxes[strlower(cvar)]
end

local function IsAnyCoordsShown()
	return MapUtils:IsCoordsOptionEnabled("worldMapShowPlayerCoords") or MapUtils:IsCoordsOptionEnabled("worldMapShowCursorCoords")
end

local function AddTooltip(control, titleKey, textKey)
	if control == nil then return end
	local function OnEnter(sel)
		GameTooltip:SetOwner(sel, "ANCHOR_RIGHT")
		GameTooltip:SetText(MapUtils:Trans(titleKey), 1, 1, 1)
		GameTooltip:AddLine(MapUtils:Trans(textKey), nil, nil, nil, true)
		GameTooltip:Show()
	end

	local function OnLeave(sel)
		if GameTooltip:GetOwner() == sel then GameTooltip:Hide() end
	end

	for _, region in ipairs({control, control.holder}) do
		if region.EnableMouse ~= nil and (region ~= control or region.IsMouseEnabled ~= nil and not region:IsMouseEnabled()) then region:EnableMouse(true) end
		region:HookScript("OnEnter", OnEnter)
		region:HookScript("OnLeave", OnLeave)
	end
end

local function AddExploreCheckbox(prefix)
	AddTooltip(AddCheckbox(prefix .. "SHOWUNEXPLORED", true, function() MapUtils:RefreshExploredPins() end, "LID_SHOWUNEXPLORED", ADDED_1022), "LID_SHOWUNEXPLORED", "LID_SHOWUNEXPLOREDDESC")
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
			if func then func(value) end
		end
	})
end

local function AddSlider(key, default, minValue, maxValue, step, func, label, added, commitOnRelease)
	return maset:AddSlider({
		["label"] = label or ("LID_" .. key),
		["search"] = key,
		["added"] = added,
		["value"] = MapUtils:GetConfig(key, default),
		["min"] = minValue,
		["max"] = maxValue,
		["step"] = step,
		["decimals"] = 0,
		["commitOnRelease"] = commitOnRelease,
		["func"] = function(value)
			MapUtils:SV(MAUTTAB, key, value)
			if func then func() end
		end
	})
end

local function AddPinEnabled(key, refresh, label, added)
	return AddCheckbox(key .. "_ENABLED", true, function()
		if refresh then refresh() end
		if MapUtils.RefreshPinToggles then MapUtils:RefreshPinToggles() end
	end, label or "LID_WORLDMAPPINS", added)
end

local function AddPinSize(key, refresh)
	local pv = MapUtils.PinVisibility
	local slider = AddSlider(key .. "_SIZE", MapUtils:GetPinSizeDefault(key), pv.sizeMin, pv.sizeMax, pv.sizeStep, refresh, "LID_PINSIZE", "2026-11-13", true)
	Requires(slider, key .. "_ENABLED")

	return slider
end

local function AddPinCategory(key, refresh, label, added)
	local control = AddPinEnabled(key, refresh, label, added)
	AddPinSize(key, refresh)

	return control
end

local function RefreshPins()
	MapUtils:RefreshPins()
end

local function AddTerrainFadeSliders(prefix, city)
	local startValue, endValue = MapUtils:GetTerrainFadeThresholds(city)
	local start, finish
	start = AddSlider(prefix .. "START", startValue, 0, 1990, 10, function()
		if start.value >= finish.value then
			finish.slider:SetValue(start.value + 10)
		else
			MapUtils:RefreshZoneDetail()
		end
	end, nil, "2026-11-11", true)
	finish = AddSlider(prefix .. "END", endValue, 10, 2000, 10, function()
		if finish.value <= start.value then
			start.slider:SetValue(finish.value - 10)
		else
			MapUtils:RefreshZoneDetail()
		end
	end, nil, "2026-11-11", true)

	return function(style)
		local shown = style == "MIXED"
		maset:SetElementShown(start, shown)
		maset:SetElementShown(finish, shown)
	end
end

local function HandleSlash(args)
	local sub = strlower(strtrim(args or ""))
	if sub:match("^debug%s+help$") then
		MapUtils:PrintDebugHelp()
	elseif sub == "debug masks" then
		MapUtils:ToggleDebugMaskWindow()
	elseif sub == "debug" then
		MapUtils:ToggleDebug()
	elseif sub == "profile" then
		MapUtils:ToggleProfiler()
	elseif sub == "count" and MapUtils.ToggleProfilerTextureCount ~= nil then
		MapUtils:ToggleProfilerTextureCount()
	elseif sub == "report" and MapUtils.ShowProfilerReport ~= nil then
		MapUtils:ShowProfilerReport()
	elseif sub == "bench" and MapUtils.RunRenderBenchmark ~= nil then
		MapUtils:RunRenderBenchmark()
	elseif sub == "pos" then
		MapUtils:PrintPlayerPosition()
	elseif sub == "fade" then
		MapUtils:PrintFadeDebug()
	elseif sub == "preload" and MapUtils.TogglePreloadVisible ~= nil then
		MapUtils:TogglePreloadVisible()
	elseif sub == "tiles" and MapUtils.PrintMinimapTileDebug ~= nil then
		MapUtils:PrintMinimapTileDebug()
	elseif sub == "map" then
		MapUtils:ToggleInstanceMap()
	elseif sub == "transports" and MapUtils.PrintTransports ~= nil then
		MapUtils:PrintTransports()
	elseif sub == "shiplog" and MapUtils.ToggleTransportLog ~= nil then
		MapUtils:ToggleTransportLog()
	else
		MapUtils:ToggleSettings()
	end
end

function MapUtils:InitSetting()
	if maset ~= nil then return end
	MAUTTAB = MAUTTAB or {}
	MapUtils:SetVersion()
	MapUtils:SetAppendTab(MAUTTAB)
	maset = MapUtils:CreateUIWindow({
		["name"] = "MapUtilsSettings",
		["pTab"] = {"CENTER"},
		["width"] = math.max(MIN_WIDTH, MapUtils:GetConfig("WINDOWWIDTH", DEFAULT_WIDTH)),
		["height"] = MapUtils:GetConfig("WINDOWHEIGHT", DEFAULT_HEIGHT),
		["minWidth"] = MIN_WIDTH,
		["navigation"] = true,
		["minHeight"] = 220,
		["onResize"] = function(width, height)
			MapUtils:SV(MAUTTAB, "WINDOWWIDTH", width)
			MapUtils:SV(MAUTTAB, "WINDOWHEIGHT", height)
		end,
		["getCollapsed"] = function(key) return GetCollapsed(key) end,
		["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
		["title"] = format("|T%d:16:16:0:0|t MapUtils v%s", ICON, MapUtils:GetAddonVersion())
	})

	MAUTTAB.WHATSNEW = MAUTTAB.WHATSNEW or {}
	MapUtils.WhatsNew = MapUtils:CreateUIWhatsNew({
		["name"] = "MapUtilsWhatsNew",
		["title"] = format("|T%d:16:16:0:0|t MapUtils v%s", ICON, MapUtils:GetAddonVersion()),
		["db"] = MAUTTAB.WHATSNEW,
		["since"] = "2026-11-13",
		["getSettings"] = function() return maset end
	})

	maset:SuspendLayout()
	local canImport = MapUtils:CanImportExport()
	maset:AddSearch({["rightInset"] = canImport and 128 or 0})
	if canImport then
		local importBtn = CreateFrame("Button", "MapUtilsSettingsImportExport", maset.header, "UIPanelButtonTemplate")
		importBtn:SetSize(120, 22)
		importBtn:SetPoint("RIGHT", maset.header, "RIGHT", -2, 1)
		importBtn:SetText(MapUtils:Trans("LID_IMPORTEXPORT"))
		importBtn:SetScript("OnClick", function() MapUtils:ToggleImportExport() end)
	end

	local footer = maset:AddFooter({["height"] = 24})
	footer.Discord = CreateFrame("EditBox", "MapUtilsSettingsDiscord", footer, "InputBoxTemplate")
	footer.Discord:SetPoint("LEFT", footer, "LEFT", 12, 0)
	footer.Discord:SetSize(220, 20)
	footer.Discord:SetAutoFocus(false)
	footer.Discord:SetText(DISCORD)
	footer.Discord:SetCursorPosition(0)
	footer.Discord:SetScript("OnTextChanged", function(sel, userInput)
		if userInput then
			sel:SetText(DISCORD)
			sel:HighlightText()
		end
	end)

	footer.Discord:SetScript("OnEditFocusGained", function(sel) sel:HighlightText() end)
	footer.Discord:SetScript("OnEscapePressed", function(sel) sel:ClearFocus() end)
	AddCategory("GENERAL")
	AddCheckbox("MMBTN", MapUtils:GetWoWBuild() ~= "RETAIL", function()
		if MAUTTAB["MMBTN"] then
			MapUtils:ShowMMBtn("MapUtils")
		else
			MapUtils:HideMMBtn("MapUtils")
		end
	end)

	MapUtils.WhatsNew:AddSettingsCheckbox(maset, "2026-11-13")
	if MapUtils.RefreshCommChannel then AddTooltip(AddCheckbox("COMMCHANNEL", true, function() MapUtils:RefreshCommChannel() end, nil, "2026-10-28"), "LID_COMMCHANNEL", "LID_COMMCHANNELDESC") end
	AddCategory("WORLDMAP", nil, nil, ADDED_0927)
	if MapUtils.RefreshGuildMembers then
		local guildPins = AddPinEnabled("GUILDMEMBERPINS", function() MapUtils:RefreshGuildMembers() end, "LID_GUILDMEMBERPINS", "2026-10-29")
		AddTooltip(guildPins, "LID_GUILDMEMBERPINS", "LID_GUILDMEMBERPINSDESC")
		for _, key in ipairs({"GUILDMEMBERLEVEL", "GUILDMEMBERNAME", "GUILDMEMBERSHARE", "GUILDMEMBERZONES"}) do
			local default = key == "GUILDMEMBERSHARE" or key == "GUILDMEMBERZONES"
			local control = AddCheckbox(key, default, function()
				MapUtils:SetSharedSetting(key, MapUtils:GetConfig(key, default))
				MapUtils:RefreshGuildMembers()
			end, nil, key == "GUILDMEMBERZONES" and "2026-11-11" or (default and "2026-10-29" or "2026-11-06"))
			guildCheckboxes[key] = control
			if key ~= "GUILDMEMBERSHARE" then Requires(control, "GUILDMEMBERPINS_ENABLED") end
			AddTooltip(control, "LID_" .. key, "LID_" .. key .. "DESC")
		end
	end
	if MapUtils.RefreshCustomMarkers then AddTooltip(AddPinCategory("CUSTOMMARKERWORLDMAPPINS", function() MapUtils:RefreshCustomMarkers() end, "LID_CUSTOMMARKERWORLDMAPPINS", "2026-11-13"), "LID_CUSTOMMARKERWORLDMAPPINS", "LID_CUSTOMMARKERWORLDMAPPINSDESC") end
	if MapUtils:IsForever() or MapUtils.RefreshQuestTurnIns or MapUtils.RefreshQuestGivers then AddCategory("QUESTS", 2, nil, ADDED_1104) end
	if MapUtils:IsForever() then AddCheckbox("REMEMBERQUESTCATEGORIES", true, function() MapUtils:RestoreQuestCategories() end) end
	if MapUtils.RefreshQuestGivers then
		AddTooltip(AddPinCategory("QUESTGIVERWORLDMAPPINS", function() MapUtils:RefreshQuestGivers() end, "LID_QUESTGIVERWORLDMAPPINS", ADDED_1104), "LID_QUESTGIVERWORLDMAPPINS", "LID_QUESTGIVERWORLDMAPPINSDESC")
		for _, key in ipairs({"QUESTGIVEREVENT", "QUESTGIVERDAILY", "QUESTGIVERREP"}) do
			Requires(AddCheckbox(key, false, function() MapUtils:RefreshQuestGivers() end, nil, ADDED_1104), "QUESTGIVERWORLDMAPPINS_ENABLED")
		end

		if MapUtils:GetQuestTurnInDefault() then AddTooltip(AddCheckbox("QUESTGIVERTURNIN", true, function() MapUtils:RefreshQuestGivers() end, nil, ADDED_1104), "LID_QUESTGIVERTURNIN", "LID_QUESTGIVERTURNINDESC") end
	end

	if MapUtils.RefreshQuestTurnIns then AddPinCategory("QUESTTURNINWORLDMAPPINS", function() MapUtils:RefreshQuestTurnIns() end, "LID_QUESTTURNINWORLDMAPPINS", "2026-10-07") end
	AddCategory("MAPWINDOW", 2, nil, ADDED_0927)
	local byMoveAny = MapUtils:IsWorldMapByMoveAny()
	for _, key in ipairs({"WORLDMAPMOVE", "WORLDMAPSCALE"}) do
		local label = nil
		if byMoveAny then label = MapUtils:Trans("LID_" .. key) .. " |cffff8000(" .. MapUtils:Trans("LID_HANDLEDBYMOVEANY") .. ")|r" end
		local checkbox = AddCheckbox(key, true, function() MapUtils:RefreshWorldMapFrame() end, label, ADDED_0927)
		if byMoveAny then maset:AddDependency(checkbox, function() return false end, 0) end
	end
	if MapUtils.IsSimpleMapFrameAvailable and MapUtils:IsSimpleMapFrameAvailable() then
		local byLeatrix = MapUtils:IsSimpleMapFrameByLeatrix()
		local label = nil
		local byEllesmere = MapUtils:IsSimpleMapFrameByEllesmere()
		if byLeatrix then label = MapUtils:Trans("LID_WORLDMAPSIMPLE") .. " |cffff8000(" .. MapUtils:Trans("LID_REVEALLEATRIX") .. ")|r" elseif byEllesmere then label = MapUtils:Trans("LID_WORLDMAPSIMPLE") .. " |cffff8000(EllesmereUI)|r" end
		local simple = AddCheckbox("WORLDMAPSIMPLE", false, function() MapUtils:RefreshSimpleMapFrame() end, label, "2026-11-05")
		AddTooltip(simple, "LID_WORLDMAPSIMPLE", "LID_WORLDMAPSIMPLEDESC")
		if byLeatrix or byEllesmere then maset:AddDependency(simple, function() return false end, 0) end
	end

	local wheelZoomAvailable = MapUtils.IsWorldMapWheelZoomAvailable and MapUtils:IsWorldMapWheelZoomAvailable()
	if wheelZoomAvailable then AddCheckbox("WORLDMAPZOOM", true, nil, nil, "2026-10-08") end
	AddTooltip(AddCheckbox("REMEMBERMAPVIEW", false, nil, nil, "2026-11-05"), "LID_REMEMBERMAPVIEW", "LID_REMEMBERMAPVIEWDESC")
	MapUtils:IsOneMap()
	local oneMap = AddCheckbox(
		"ONEMAP",
		true,
		function()
			MapUtils:RefreshZoneDetail()
			MapUtils.OneMapPinCache = {}
			MapUtils:RefreshPins()
			MapUtils:InstallCombatPins()
		end, nil, ADDED_1022
	)
	if wheelZoomAvailable then Requires(oneMap, "WORLDMAPZOOM") end
	AddTooltip(oneMap, "LID_ONEMAP", "LID_ONEMAPDESC")
	local mapStyles = {}
	for _, key in ipairs({"MIXED", "MAP", "TERRAIN"}) do
		tinsert(
			mapStyles,
			{
				["value"] = key,
				["label"] = MapUtils:Trans("LID_MAPSTYLE" .. key)
			}
		)
	end

	local showZoneFade, showCityFade
	local zoneStyle = AddDropdown("MAPSTYLE", "MIXED", mapStyles, function(style)
		showZoneFade(style)
		MapUtils:RefreshZoneDetail()
	end, "LID_ZONEMAPSTYLE", ADDED_1022)
	AddTooltip(zoneStyle, "LID_ZONEMAPSTYLE", "LID_MAPSTYLEDESC")
	showZoneFade = AddTerrainFadeSliders("ZONETERRAINFADE", false)
	showZoneFade(MapUtils:GetConfig("MAPSTYLE", "MIXED"))
	local cityStyle = AddDropdown("CITYMAPSTYLE", MapUtils:GetConfig("MAPSTYLE", "MIXED"), mapStyles, function(style)
		showCityFade(style)
		MapUtils:RefreshZoneDetail()
	end, nil, ADDED_1022)
	AddTooltip(cityStyle, "LID_CITYMAPSTYLE", "LID_MAPSTYLEDESC")
	showCityFade = AddTerrainFadeSliders("CITYTERRAINFADE", true)
	showCityFade(MapUtils:GetConfig("CITYMAPSTYLE", "MIXED"))
	AddCategory("NAVIGATION", 2, nil, ADDED_0928)
	AddTooltip(AddCheckbox("ALWAYSSHOWWAYPOINT", false, nil, nil, ADDED_0928), "LID_ALWAYSSHOWWAYPOINT", "LID_ALWAYSSHOWWAYPOINTDESC")
	if (C_Navigation and C_Navigation.GetDistance) or WorldMapPin_GetDistance then
		AddDropdown("WAYPOINTDISTANCE", "METERS", {
			{["value"] = "METERS", ["label"] = MapUtils:Trans("LID_DISTANCEMETERS")},
			{["value"] = "YARDS", ["label"] = MapUtils:Trans("LID_DISTANCEYARDS")}
		})
	end

	AddCategory("MAPFADE", 2, nil, ADDED_0927)
	AddCheckbox("WORLDMAPFADE", true, function() MapUtils:RefreshWorldMapFrame() end, nil, ADDED_0927)
	Requires(AddSlider("WORLDMAPFADEOPACITY", 50, 0, 100, 5, nil, nil, ADDED_0927), "WORLDMAPFADE")
	if MapUtils.nativeInstanceMaps then
		AddCategory("INSTANCEMAPS", 2, nil, ADDED_0927)
		AddCheckbox("DUNGEONMAPS", true, nil, nil, ADDED_0927)
		AddCheckbox("RAIDMAPS", true, nil, nil, ADDED_0927)
	end

	AddCategory("MAPLABELS", 2)
	AddCVarCheckbox("worldMapShowPlayerCoords", "LID_SHOWPLAYERCOORDS", ADDED_1019)
	AddCVarCheckbox("worldMapShowCursorCoords", "LID_SHOWCURSORCOORDS", ADDED_1019)
	maset:AddDependency(
		AddDropdown(
			"COORDSSTYLE",
			"WIDGET",
			{
				{["value"] = "WIDGET", ["label"] = MapUtils:Trans("LID_COORDSSTYLEWIDGET")},
				{["value"] = "POSITION", ["label"] = MapUtils:Trans("LID_COORDSSTYLEPOSITION")}
			},
			function() MapUtils:RefreshCoords() end, nil, "2026-11-12"
		),
		IsAnyCoordsShown
	)
	maset:AddDependency(AddCVarCheckbox("coordsByTenths", "LID_COORDSBYTENTHS", ADDED_1019), IsAnyCoordsShown)
	AddCheckbox("ZONELEVELS", true)
	AddCheckbox("ZONERECLEVELS", true, nil, nil, "2026-10-02")
	AddCheckbox("FISHINGLEVELS", true)
	if MapUtils:HasRevealData() then
		AddCategory("REVEAL", 2, nil, ADDED_0928)
		local revealLabel = nil
		if MapUtils:IsRevealedByLeatrix() then revealLabel = MapUtils:Trans("LID_REVEALMAP") .. " |cffff8000(" .. MapUtils:Trans("LID_REVEALLEATRIX") .. ")|r" end
		AddCheckbox("REVEALMAP", true, function() MapUtils:RefreshReveal() MapUtils:RefreshZoneDetail() end, revealLabel, ADDED_0928)
		local tint = AddDropdown("REVEALTINT", "BLUE", MapUtils:GetRevealTintChoices(), function() MapUtils:RefreshReveal() MapUtils:RefreshZoneDetail() end, nil, ADDED_0928)
		maset:AddDependency(tint, function() return type(MAUTTAB) == "table" and (MAUTTAB["REVEALMAP"] == true or MAUTTAB["MAPSTYLE"] ~= "MAP" or (MAUTTAB["CITYMAPSTYLE"] or MAUTTAB["MAPSTYLE"]) ~= "MAP") end, 0)
	end

	AddCategory("BATTLEFIELDMAP", nil, nil, ADDED_0927)
	AddCategory("BATTLEFIELDMAPWINDOW", 2, "LID_MAPWINDOW", ADDED_0927)
	AddCheckbox("BATTLEFIELDMAPSCALE", true, function() MapUtils:RefreshBattlefieldMap() end, nil, ADDED_0927)
	AddCategory("BATTLEFIELDMAPFADECAT", 2, "LID_MAPFADE", ADDED_0927)
	AddCheckbox("BATTLEFIELDMAPFADE", true, function() MapUtils:RefreshBattlefieldMap() end, nil, ADDED_0927)
	Requires(AddSlider("BATTLEFIELDMAPFADEOPACITY", 50, 0, 100, 5, function() MapUtils:RefreshBattlefieldMap() end, "LID_WORLDMAPFADEOPACITY", ADDED_0927), "BATTLEFIELDMAPFADE")
	AddCategory("MAPICONS")
	AddCategory("PIERS", 2)
	AddDropdown("PIERICONSTYLE", "NEW", {
		{value = "NEW", label = MapUtils:Trans("LID_PIERICONNEW")},
		{value = "PORTALS", label = MapUtils:Trans("LID_PIERICONPORTALS")},
	}, function() MapUtils:RefreshPins() end)
	AddPinCategory("WORLDMAPPINS", RefreshPins)
	AddCheckbox("MINIMAPPINS", true, function() MapUtils:RefreshPins() end)
	if MapUtils.TRANSPORTROUTES ~= nil then
		AddPinCategory("VESSELWORLDMAPPINS", function() MapUtils:RefreshTransports() end, "LID_VESSELWORLDMAPPINS", "2026-10-28")
		AddCheckbox("VESSELMINIMAPPINS", true, function() MapUtils:RefreshTransports() end, nil, "2026-10-28")
	end

	AddExploreCheckbox("PIER")
	AddCategory("DUNGEONS", 2)
	AddPinCategory("DUNGEONWORLDMAPPINS", RefreshPins)
	AddSharedCheckbox("DUNGEONMINIMAPPINS", "LID_MINIMAPPINS")
	AddExploreCheckbox("DUNGEON")
	AddCategory("MEETINGSTONES", 2, nil, ADDED_0928)
	AddPinCategory("MEETINGSTONEWORLDMAPPINS", RefreshPins, nil, ADDED_0928)
	AddSharedCheckbox("MEETINGSTONEMINIMAPPINS", "LID_MINIMAPPINS", ADDED_0928)
	AddExploreCheckbox("MEETINGSTONE")
	if not MapUtils.nativeInstanceMaps then
		AddCategory("INSTANCEMAPPINS", 2, "LID_INSTANCEMAPS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_BOSS", "LID_SHOWBOSSPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_ITEM", "LID_SHOWQUESTPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_ENTRANCE", "LID_SHOWENTRANCEPINS", ADDED_1004)
		AddSharedCheckbox("INSTANCEPINS_LEVEL", "LID_SHOWLEVELPINS", ADDED_1004)
	end

	if MapUtils:IsForever() then
		AddCategory("SPIRITHEALERS", 2, nil, "2026-10-06")
		AddPinCategory("SPIRITHEALERWORLDMAPPINS", RefreshPins)
		AddCheckbox("SPIRITHEALERMINIMAPPINS", false, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS")
		AddDropdown("SPIRITHEALERSTYLE", "NORMAL", {
			{value = "NORMAL", label = MapUtils:Trans("LID_NORMAL")},
			{value = "CHIBI", label = "Chibi"},
		}, function() MapUtils:RefreshPins() end)
		AddExploreCheckbox("SPIRITHEALER")
		AddCategory("CONVERGENCES", 2, nil, ADDED_1017)
		AddPinCategory("CONVERGENCEWORLDMAPPINS", RefreshPins, nil, ADDED_1017)
		AddCheckbox("CONVERGENCEMINIMAPPINS", false, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS", ADDED_1017)
		AddCheckbox("CONVERGENCENONSKYBORNE", false, function() MapUtils:RefreshPins() end, "LID_CONVERGENCENONSKYBORNE", ADDED_1017)
		AddExploreCheckbox("CONVERGENCE")
	end

	if MapUtils.CanShowGatherNodes ~= nil and MapUtils:CanShowGatherNodes() then
		AddCategory("GATHERNODES", 2, nil, "2026-10-26")
		AddCheckbox("GATHERNODEMINIMAPICONS", true, function() MapUtils:RefreshGatherNodes() end, "LID_MINIMAPPINS", "2026-10-26")
	end

	AddCategory("FLIGHTPOINTS", 2)
	AddPinCategory("FLIGHTWORLDMAPPINS", RefreshPins)
	AddCheckbox("FLIGHTMINIMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS")
	AddExploreCheckbox("FLIGHT")
	AddCategory("ZONECROSSINGS", 2, nil, ADDED_1003)
	AddPinCategory("CROSSINGWORLDMAPPINS", RefreshPins, nil, ADDED_1003)
	AddExploreCheckbox("CROSSING")
	if MapUtils.RefreshAreaPOIs ~= nil then
		AddCategory("AREAPOIS", 2, nil, "2026-10-28")
		AddPinEnabled("TOWNPOIS", function() MapUtils:RefreshAreaPOIs() end, "LID_TOWNPOIS", "2026-10-28")
		AddPinEnabled("CAPITALPOIS", function() MapUtils:RefreshAreaPOIs() end, "LID_CAPITALPOIS", "2026-10-28")
	end

	if MapUtils:LibraryBookPinsAvailable() then
		AddCategory("FOREVER", 2, nil, "2026-11-13")
		AddCategory("LIBRARYBOOKS", 3, nil, "2026-11-13")
		AddPinCategory("LIBRARYBOOKWORLDMAPPINS", function() MapUtils:RefreshLibraryBooks() end, nil, "2026-11-13")
		AddCheckbox("LIBRARYBOOKMINIMAPPINS", true, function() MapUtils:RefreshPins() end, "LID_MINIMAPPINS", "2026-11-13")
		AddTooltip(AddCheckbox("LIBRARYBOOKSHOWUNEXPLORED", true, function() MapUtils.LibraryBooks.Set("LIBRARYBOOKSHOWUNEXPLORED", MAUTTAB["LIBRARYBOOKSHOWUNEXPLORED"] == true) end, "LID_SHOWUNEXPLORED", "2026-11-13"), "LID_SHOWUNEXPLORED", "LID_LIBRARYBOOKSHOWUNEXPLOREDDESC")
	end

	maset:UpdateDependencies()
	maset:ResumeLayout()
	MapUtils:CreateMinimapButton({
		["name"] = "MapUtils",
		["icon"] = ICON,
		["dbtab"] = MAUTTAB,
		["vTT"] = {{format("|T%d:16:16:0:0|t MapUtils", ICON), "v" .. MapUtils:GetAddonVersion()}, {MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_OPENSETTINGS")}, {MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_HIDEMINIMAPBUTTON")}},
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
loader:RegisterEvent("CVAR_UPDATE")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "CVAR_UPDATE" then
		local checkbox = type(name) == "string" and cvarCheckboxes[strlower(name)]
		if checkbox then
			checkbox:SetChecked(GetCVarValue(name) == "1")
			maset:UpdateDependencies()
		end
	elseif event == "PLAYER_LOGIN" then
		MapUtils:InitSetting()
		MapUtils:RegisterCompendiumTabs()
	elseif event == "PLAYER_ENTERING_WORLD" then
		loader:UnregisterEvent(event)
		if MapUtils.WhatsNew ~= nil then MapUtils.WhatsNew:ShowIfNew() end
	elseif name == "AzerothCompendium" then
		MapUtils:RegisterCompendiumTabs()
	end
end)
MapUtils:RegisterCompendiumTabs()
