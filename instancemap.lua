local _, MapUtils = ...
local DEFAULT_ART_WIDTH = 1024
local DEFAULT_ART_HEIGHT = 1024
local UPDATE_INTERVAL = 0.05
local OVERLAY_LEVEL = 3000
local MEDIA_PATH = "Interface\\AddOns\\MapUtils\\media\\"
local LEVEL_BUTTON_WIDTH = 260
local LEVEL_BUTTON_HEIGHT = 22
local LEVEL_BUTTON_OFFSET = 8
local LEVEL_STEPPER_PAD = 70
local NAV_BUTTON_EXTRA = 53
local NAV_BUTTON_PLAIN = 30
local NAV_BUTTON_MIN_TEXT = 60
local PIN_TOGGLE_OFFSET_X = 40
local PIN_TOGGLE_OFFSET_Y = 10
local PIN_TOGGLE_KEYS = {
	["boss"] = "BOSSPINS",
	["item"] = "QUESTPINS",
	["entrance"] = "ENTRANCEPINS",
	["level"] = "LEVELPINS",
}

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
			["height"] = level[3] or 683,
			["fileWidth"] = 1024,
			["fileHeight"] = 1024,
			["zoom"] = 1,
		}
	end
end

AddArt(2959, "City of Dalaran", {{2959, "City of Dalaran (1)"}, {"2959_2", "City of Dalaran (2)"}})
AddArt(2998, "Excavation Site: Wetlands", {{2998}})
AddArt(2999, "Ruins of Lordaeron", {{2999}})
AddArt(3065, "Hall of the Thanes", {{3065}})
AddArt(389, "Ragefire Chasm", {{213}})
AddArt(36, "The Deadmines", {{291}, {292, "Ironclad Cove"}})
AddArt(43, "Wailing Caverns", {{279}})
AddArt(33, "Shadowfang Keep", {{310, "The Courtyard"}, {311, "Dining Hall"}, {312, "The Vacant Den"}, {313, "Lower Observatory"}, {314, "Upper Observatory"}, {316, "The Wall Walk"}, {315, "Lord Godfrey's Chamber"}})
AddArt(34, "The Stockade", {{225, nil, 670}})
AddArt(48, "Blackfathom Deeps", {{221, "The Pool of Ask'Ar"}, {222, "Moonshrine Sanctum"}, {223, "The Forgotten Pool"}})
AddArt(90, "Gnomeregan", {{226, "The Hall of Gears"}, {227, "The Dormitory"}, {228, "Launch Bay"}, {229, "Tinkers' Court"}})
AddArt(47, "Razorfen Kraul", {{301}})
AddArt(189, "Scarlet Monastery", {{302, "Graveyard"}, {303, "Library"}, {304, "Armory"}, {305, "Cathedral"}})
AddArt(129, "Razorfen Downs", {{300}})
AddArt(70, "Uldaman", {{230, "Hall of the Keepers"}, {231, "Khaz'Goroth's Seat"}})
AddArt(209, "Zul'Farrak", {{219}})
AddArt(349, "Maraudon", {{280, "Caverns of Maraudon"}, {281, "Zaetar's Grave"}})
AddArt(109, "Temple of Atal'Hakkar", {{220}})
AddArt(230, "Blackrock Depths", {{242, "Detention Block"}, {243, "Shadowforge City"}})
AddArt(229, "Blackrock Spire", {{250, "Tazz'Alor"}, {251, "Skitterweb Tunnels"}, {252, "Hordemar City"}, {253, "Hall of Blackhand"}, {254, "Halycon's Lair"}, {255, "Chamber of Battle"}})
AddArt(409, "Molten Core", {{232}})
AddArt(469, "Blackwing Lair", {{287, "Dragonmaw Garrison"}, {288, "Halls of Strife"}, {289, "Crimson Laboratories"}, {290, "Nefarian's Lair"}})
AddArt(429, "Dire Maul", {{234}, {235, "Gordok Commons"}, {236, "Capital Gardens"}, {237, "Court of the Highborne"}, {238, "Prison of Immol'Thar"}, {239, "Warpwood Quarter"}, {240, "The Shrine of Eldretharr"}})
AddArt(289, "Scholomance", {{306, "The Reliquary"}, {307, "Chamber of Summoning"}, {308, "The Upper Study"}, {309, "Headmaster's Study"}})
AddArt(329, "Stratholme", {{317, "Crusader's Square"}, {318, "The Gauntlet"}})
AddArt(309, "Zul'Gurub", {{233}})
AddArt(249, "Onyxia's Lair", {{248}})
AddArt(509, "Ruins of Ahn'Qiraj", {{247}})
AddArt(531, "Temple of Ahn'Qiraj", {{319, "The Hive Undergrounds"}, {320, "The Temple Gates"}, {321, "Vault of C'Thun"}})
AddArt(533, "Naxxramas", {{162, "The Construct Quarter"}, {163, "The Arachnid Quarter"}, {164, "The Military Quarter"}, {165, "The Plague Quarter"}, {166, "The Lower Necropolis"}, {167, "The Upper Necropolis"}})
local overlay = nil
local levelButton = nil
local hiddenFor = nil
local forced = nil
local forcedMapID = nil
local forcedIndex = 1
local selected = {}
local shownLevels = nil
local shownIndex = nil
local shownInstance = nil
local lastKey = nil
local mapPinSet = nil
local mapPinKey = nil
local Refresh = nil
local function GetChild()
	if WorldMapFrame == nil then return nil end
	if WorldMapFrame.ScrollContainer == nil then return nil end

	return WorldMapFrame.ScrollContainer.Child
end

local function GetInstanceArt()
	if MapUtils.nativeInstanceMaps then return nil end
	local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	if instanceMapID == nil then return nil end

	return art[instanceMapID], instanceMapID
end

local function GetPlayerMapID()
	if MapUtil ~= nil and MapUtil.GetDisplayableMapForPlayer ~= nil then return MapUtil.GetDisplayableMapForPlayer() end
	if C_Map ~= nil and C_Map.GetBestMapForUnit ~= nil then return C_Map.GetBestMapForUnit("player") end

	return nil
end

local function GetLevelLabel(levels, level)
	local instanceName = MapUtils:TransName(level.instance)
	if level.name == nil then return instanceName end
	for _, other in ipairs(levels) do
		if other.instance ~= level.instance then return instanceName .. " - " .. MapUtils:TransName(level.name) end
	end

	return MapUtils:TransName(level.name)
end

local function ClearForced()
	forced = nil
	forcedMapID = nil
	forcedIndex = 1
end

local function SelectLevel(index)
	if forced ~= nil then
		forcedIndex = index
	elseif shownInstance ~= nil then
		selected[shownInstance] = index
	end

	Refresh()
end

local function StepLevel(delta)
	if shownLevels == nil or shownIndex == nil then return end
	local index = shownIndex + delta
	if index < 1 or index > #shownLevels then return end
	SelectLevel(index)
end

local function CreateStepperControl(container)
	local control = CreateFrame("Frame", nil, container, "SettingsDropdownWithButtonsTemplate")
	control:SetWidth(LEVEL_BUTTON_WIDTH + LEVEL_STEPPER_PAD)
	if control.Dropdown then control.Dropdown:SetWidth(LEVEL_BUTTON_WIDTH) end
	local steppers = MapUtils:SetupDropdownSteppers(control, function() StepLevel(-1) end, function() StepLevel(1) end, true)
	local function UpdateSteppers()
		local count = shownLevels and #shownLevels or 0
		local index = shownIndex or 1
		steppers:SetEnabled(index > 1, index < count)
	end

	if control.Dropdown and control.Dropdown.SetupMenu then
		control.Dropdown:SetupMenu(
			function(_, root)
				local levels = shownLevels
				if levels == nil then return end
				for i, level in ipairs(levels) do
					root:CreateRadio(GetLevelLabel(levels, level), function() return shownIndex == i end, function() SelectLevel(i) end)
				end
			end
		)
	end

	function control:SetLabel(text)
		MapUtils:SetDropdownText(self.Dropdown, text)
		UpdateSteppers()
		if C_Timer then C_Timer.After(0, UpdateSteppers) end
	end

	control:HookScript("OnShow", UpdateSteppers)

	return control
end

local function OpenLevelMenu(owner)
	local levels = shownLevels
	if levels == nil then return end
	local entries = {}
	for i, level in ipairs(levels) do
		tinsert(
			entries,
			{
				["text"] = GetLevelLabel(levels, level),
				["checked"] = function() return shownIndex == i end,
				["func"] = function() SelectLevel(i) end,
			}
		)
	end

	MapUtils:ShowContextMenu(owner, entries)
end

local function GetNavBar()
	if WorldMapFrame == nil then return nil end
	local navBar = WorldMapFrame.NavBar
	if navBar == nil or type(navBar.navList) ~= "table" then return nil end
	if MapUtils.CheckTemplates == nil or not MapUtils:CheckTemplates("NavButtonTemplate") then return nil end

	return navBar
end

local function SetupLevelMenu(dropdown)
	if dropdown == nil or dropdown.SetupMenu == nil then return end
	dropdown:SetupMenu(
		function(_, root)
			local levels = shownLevels
			if levels == nil then return end
			for i, level in ipairs(levels) do
				root:CreateRadio(GetLevelLabel(levels, level), function() return shownIndex == i end, function() SelectLevel(i) end)
			end
		end
	)
end

local function CreateNavButton(navBar)
	local button = CreateFrame("Button", nil, navBar, "NavButtonTemplate")
	button.listFunc = function() return nil end
	local arrow = button.MenuArrowButton
	button:RegisterForClicks("LeftButtonUp")
	button:SetScript(
		"OnClick",
		function(self)
			if arrow ~= nil and arrow.OpenMenu ~= nil then
				arrow:OpenMenu()
			else
				OpenLevelMenu(self)
			end
		end
	)

	if NavBar_ButtonOnEnter ~= nil then button:SetScript("OnEnter", NavBar_ButtonOnEnter) end
	if NavBar_ButtonOnLeave ~= nil then button:SetScript("OnLeave", NavBar_ButtonOnLeave) end
	button:HookScript("OnShow", function() SetupLevelMenu(arrow) end)
	SetupLevelMenu(arrow)
	if button.selected ~= nil then button.selected:Show() end
	function button:Reanchor()
		local list = navBar.navList
		local last = list[#list]
		if last == nil then return end
		local hasMenu = shownLevels ~= nil and #shownLevels > 1
		local extra = hasMenu and NAV_BUTTON_EXTRA or NAV_BUTTON_PLAIN
		if arrow ~= nil then arrow:SetShown(hasMenu) end
		if self:IsEnabled() ~= hasMenu then self:SetEnabled(hasMenu) end
		local space = (navBar:GetRight() or 0) - (last:GetRight() or 0) - extra
		local width = min(self.textWidth or 0, max(space, NAV_BUTTON_MIN_TEXT))
		self.text:SetWidth(width)
		self:SetWidth(width + extra)
		if self.anchor ~= last then
			self.anchor = last
			self:ClearAllPoints()
			self:SetPoint("LEFT", last, "RIGHT", 0, 0)
		end

		self:SetFrameLevel(max(navBar:GetFrameLevel(), last:GetFrameLevel() - 1))
	end

	function button:SetLabel(text)
		self.text:SetWidth(0)
		self:SetText(text)
		self.textWidth = self.text:GetStringWidth()
		self:Reanchor()
	end

	button:Hide()

	return button
end

local function ToggleOverlay()
	if forced ~= nil then
		ClearForced()
		Refresh()

		return
	end

	local info, instanceMapID = GetInstanceArt()
	if info == nil then return end
	if hiddenFor == instanceMapID then
		hiddenFor = nil
	else
		hiddenFor = instanceMapID
	end

	Refresh()
end

local function OnCanvasMouseUp(_, button)
	if button ~= "RightButton" then return end
	ToggleOverlay()
end

local function GetCompendium()
	local api = _G["AzerothCompendiumAPI"]
	if type(api) ~= "table" or api.ShowBossLoot == nil then return nil end

	return api
end

local function FindLevelIndex(levels, key)
	for index, level in ipairs(levels or {}) do
		if level.key == key then return index end
	end

	return nil
end

local function OnMapPinEnter(pin)
	local row = pin.row
	if row == nil then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	if row[1] == "boss" then
		GameTooltip:SetText(MapUtils:TransName(row[5]))
		if row[6] then GameTooltip:AddLine(format("%s %d", LEVEL or "Level", row[6]), 1, 1, 1) end
		if GetCompendium() ~= nil then GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SHOWBOSSLOOT")), 0.6, 0.6, 0.6) end
	elseif row[1] == "item" then
		if GameTooltip.SetItemByID ~= nil then
			GameTooltip:SetItemByID(row[4])
		else
			GameTooltip:SetHyperlink("item:" .. row[4])
		end
	elseif row[1] == "level" then
		GameTooltip:SetText(GetLevelLabel(shownLevels, shownLevels[pin.level]))
		GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SHOWDESTMAP")), 0.6, 0.6, 0.6)
	else
		GameTooltip:SetText(MapUtils:Trans(row[4] == "raid" and "LID_RAIDENTRANCE" or "LID_DUNGEONENTRANCE"))
	end

	GameTooltip:Show()
end

local function OnMapPinLeave(pin)
	if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
end

local function OnMapPinMouseUp(pin, button)
	if not pin:IsMouseOver() then return end
	if button == "RightButton" then
		ToggleOverlay()

		return
	end

	local row = pin.row
	if button ~= "LeftButton" or row == nil then return end
	if row[1] == "level" then
		OnMapPinLeave(pin)
		SelectLevel(pin.level)
	elseif row[1] == "boss" then
		local api = GetCompendium()
		local info = shownLevels ~= nil and shownLevels[shownIndex] or nil
		if api == nil or info == nil then return end
		OnMapPinLeave(pin)
		api.ShowBossLoot(info.key, row[4])
	end
end

local function HideMapPins()
	if mapPinKey == nil then return end
	mapPinKey = nil
	if mapPinSet ~= nil then mapPinSet:Hide() end
end

local function UpdateMapPins(info)
	local scale = GetChild():GetScale()
	local rows = MapUtils.INSTANCEPINS ~= nil and info.key ~= nil and MapUtils.INSTANCEPINS[info.key] or nil
	if rows == nil or scale == nil or scale <= 0 or MapUtils.CreateInstancePins == nil then
		HideMapPins()

		return
	end

	local key = format("%s|%.4f|%.1f|%.1f", info.key, scale, overlay.art:GetWidth(), overlay.art:GetHeight())
	if key == mapPinKey then return end
	mapPinKey = key
	if mapPinSet == nil then
		mapPinSet = MapUtils:CreateInstancePins(
			overlay,
			{
				["media"] = MEDIA_PATH,
				["onEnter"] = OnMapPinEnter,
				["onLeave"] = OnMapPinLeave,
				["onMouseUp"] = OnMapPinMouseUp,
				["getLevel"] = function(row) return FindLevelIndex(shownLevels, row[4]) end,
				["isEnabled"] = function(kind) return MapUtils:GetConfig("INSTANCEPINS_" .. strupper(kind), true) ~= false end,
				["setEnabled"] = function(kind, enabled)
					MAUTTAB = MAUTTAB or {}
					MAUTTAB["INSTANCEPINS_" .. strupper(kind)] = enabled
					mapPinKey = nil
					Refresh()
				end,
				["getToggleText"] = function(kind, enabled) return MapUtils:Trans("LID_" .. (enabled and "HIDE" or "SHOW") .. PIN_TOGGLE_KEYS[kind]) end,
			}
		)

		local container = WorldMapFrame.ScrollContainer
		local toggles = mapPinSet:CreateToggles(container)
		toggles:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -PIN_TOGGLE_OFFSET_X, PIN_TOGGLE_OFFSET_Y)
		toggles:SetFrameLevel(overlay:GetFrameLevel() + 1000)
	end

	mapPinSet:Update(rows, overlay.art, scale)
	mapPinSet.toggles:Show()
end

local function CreateOverlay()
	if overlay ~= nil then return overlay end
	local child = GetChild()
	if child == nil then return nil end
	overlay = CreateFrame("FRAME", nil, child)
	overlay:SetFrameLevel(child:GetFrameLevel() + OVERLAY_LEVEL)
	overlay:EnableMouse(true)
	overlay:SetScript("OnMouseUp", OnCanvasMouseUp)
	overlay:SetAllPoints(child)
	overlay.bg = overlay:CreateTexture(nil, "BACKGROUND")
	overlay.bg:SetAllPoints(overlay)
	overlay.bg:SetColorTexture(0, 0, 0, 1)
	overlay.art = overlay:CreateTexture(nil, "ARTWORK")
	overlay.art:SetPoint("CENTER", overlay, "CENTER", 0, 0)
	overlay:Hide()
	local container = WorldMapFrame.ScrollContainer
	local navBar = GetNavBar()
	if navBar ~= nil then
		levelButton = CreateNavButton(navBar)
	elseif MapUtils.CheckTemplates ~= nil and MapUtils:CheckTemplates("SettingsDropdownWithButtonsTemplate") then
		levelButton = CreateStepperControl(container)
	else
		levelButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
		levelButton:SetSize(LEVEL_BUTTON_WIDTH, LEVEL_BUTTON_HEIGHT)
		levelButton:SetScript("OnClick", OpenLevelMenu)
		levelButton.SetLabel = levelButton.SetText
	end

	if navBar == nil then
		levelButton:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", LEVEL_BUTTON_OFFSET, LEVEL_BUTTON_OFFSET)
		levelButton:SetFrameLevel(overlay:GetFrameLevel() + 1000)
	end

	levelButton:Hide()
	container:HookScript("OnMouseUp", OnCanvasMouseUp)
	WorldMapFrame:HookScript(
		"OnShow",
		function()
			hiddenFor = nil
			ClearForced()
		end
	)

	return overlay
end

local function Layout(info)
	local child = GetChild()
	if child == nil then return end
	local w = child:GetWidth()
	local h = child:GetHeight()
	if w == nil or h == nil or w <= 0 or h <= 0 then return end
	local ratio = (info.height or DEFAULT_ART_HEIGHT) / (info.width or DEFAULT_ART_WIDTH)
	local width = w
	local height = w * ratio
	if height > h then
		height = h
		width = h / ratio
	end

	local zoom = info.zoom or 1
	overlay.art:SetSize(width * zoom, height * zoom)
end

local function GetVisibleLevels()
	if WorldMapFrame == nil or WorldMapFrame.GetMapID == nil then return nil end
	if forced ~= nil then
		if WorldMapFrame:GetMapID() == forcedMapID then return forced, forcedIndex, nil end
		ClearForced()
	end

	local levels, instanceMapID = GetInstanceArt()
	if levels == nil then return nil end
	if hiddenFor == instanceMapID then return nil end
	local playerMapID = GetPlayerMapID()
	if playerMapID ~= nil and WorldMapFrame:GetMapID() ~= playerMapID then return nil end

	return levels, selected[instanceMapID] or 1, instanceMapID
end

Refresh = function()
	local levels, index, instanceMapID = GetVisibleLevels()
	if levels == nil then
		lastKey = nil
		shownLevels = nil
		shownIndex = nil
		shownInstance = nil
		HideMapPins()
		if overlay ~= nil then
			overlay:Hide()
			levelButton:Hide()
		end

		return
	end

	if CreateOverlay() == nil then return end
	if levels[index] == nil then index = 1 end
	local info = levels[index]
	shownLevels = levels
	shownIndex = index
	shownInstance = instanceMapID
	local child = GetChild()
	local key = format("%s|%.1f|%.1f", info.file, child:GetWidth() or 0, child:GetHeight() or 0)
	if key ~= lastKey then
		lastKey = key
		overlay.art:SetTexture(info.file)
		local width = info.width or DEFAULT_ART_WIDTH
		local height = info.height or DEFAULT_ART_HEIGHT
		overlay.art:SetTexCoord(0, width / (info.fileWidth or width), 0, height / (info.fileHeight or height))
		Layout(info)
		levelButton:SetLabel(GetLevelLabel(levels, info))
	end

	UpdateMapPins(info)

	if levelButton.Reanchor ~= nil then
		levelButton:Reanchor()
		if not levelButton:IsShown() then levelButton:Show() end
	elseif #levels > 1 then
		if not levelButton:IsShown() then levelButton:Show() end
	elseif levelButton:IsShown() then
		levelButton:Hide()
	end

	if not overlay:IsShown() then overlay:Show() end
end

function MapUtils:ShowInstanceMap(instances, level)
	if instances == nil then return false end
	if type(instances) ~= "table" then
		instances = {instances}
	end

	local levels = {}
	for _, instanceMapID in ipairs(instances) do
		for _, info in ipairs(art[instanceMapID] or {}) do
			tinsert(levels, info)
		end
	end

	if #levels == 0 then return false end
	if WorldMapFrame == nil or WorldMapFrame.GetMapID == nil then return false end
	if WorldMapFrame:IsShown() ~= true then return false end
	forced = levels
	forcedMapID = WorldMapFrame:GetMapID()
	forcedIndex = level or 1
	hiddenFor = nil
	lastKey = nil
	Refresh()

	return true
end

function MapUtils:IsInstanceMapShown()
	return overlay ~= nil and overlay:IsShown()
end

function MapUtils:ToggleInstanceMap()
	if forced == nil and GetInstanceArt() == nil then
		MapUtils:INFO("No own map for this instance")

		return
	end

	ToggleOverlay()
end

if WorldMapFrame ~= nil then
	local updater = CreateFrame("FRAME", nil, WorldMapFrame)
	updater.elapsed = 0
	updater:SetScript(
		"OnUpdate",
		function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < UPDATE_INTERVAL then return end
			self.elapsed = 0
			Refresh()
		end
	)
end
