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
local NAV_BUTTON_MIN_TEXT = 60
local art = {}
local function AddArt(instanceMapID, instanceName, levels)
	art[instanceMapID] = {}
	for i, level in ipairs(levels) do
		art[instanceMapID][i] = {
			["file"] = MEDIA_PATH .. level[1],
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

AddArt(2999, "Ruins of Lordaeron", {{2999}})
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
local levelMenu = nil
local hiddenFor = nil
local forced = nil
local forcedMapID = nil
local forcedIndex = 1
local selected = {}
local shownLevels = nil
local shownIndex = nil
local shownInstance = nil
local lastKey = nil
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

local function FindSteppers(control)
	local dec = control.DecrementButton
	local inc = control.IncrementButton
	if dec and inc then return dec, inc end
	local found = {}
	for _, child in ipairs({control:GetChildren()}) do
		if child ~= control.Dropdown and child.SetEnabled and child.GetObjectType and child:GetObjectType() == "Button" then tinsert(found, child) end
	end

	table.sort(found, function(a, b) return (a:GetLeft() or 0) < (b:GetLeft() or 0) end)

	return dec or found[1], inc or found[2]
end

local function CreateStepperControl(container)
	local control = CreateFrame("Frame", nil, container, "SettingsDropdownWithButtonsTemplate")
	control:SetWidth(LEVEL_BUTTON_WIDTH + LEVEL_STEPPER_PAD)
	if control.Dropdown then control.Dropdown:SetWidth(LEVEL_BUTTON_WIDTH) end
	local dec, inc = FindSteppers(control)
	local setEnabled = {}
	local function Lock(button)
		if button == nil then return end
		setEnabled[button] = button.SetEnabled
		local nop = function() end
		button.SetEnabled = nop
		button.Enable = nop
		button.Disable = nop
	end

	Lock(dec)
	Lock(inc)
	local function UpdateSteppers()
		local count = shownLevels and #shownLevels or 0
		local index = shownIndex or 1
		if dec then setEnabled[dec](dec, index > 1) end
		if inc then setEnabled[inc](inc, index < count) end
	end

	if dec then dec:SetScript("OnClick", function() StepLevel(-1) end) end
	if inc then inc:SetScript("OnClick", function() StepLevel(1) end) end
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
		local dropdown = self.Dropdown
		if dropdown ~= nil then
			if dropdown.SetDefaultText then dropdown:SetDefaultText(text) end
			if dropdown.Update then dropdown:Update() end
			if dropdown.SetText then dropdown:SetText(text) end
		end

		UpdateSteppers()
		if C_Timer then C_Timer.After(0, UpdateSteppers) end
	end

	control:HookScript("OnShow", UpdateSteppers)

	return control
end

local function OpenLevelMenu(owner)
	local levels = shownLevels
	if levels == nil then return end
	if MenuUtil ~= nil and MenuUtil.CreateContextMenu ~= nil then
		MenuUtil.CreateContextMenu(
			owner,
			function(_, root)
				for i, level in ipairs(levels) do
					root:CreateRadio(GetLevelLabel(levels, level), function() return shownIndex == i end, function() SelectLevel(i) end)
				end
			end
		)

		return
	end

	if UIDropDownMenu_Initialize == nil or ToggleDropDownMenu == nil then return end
	if levelMenu == nil then
		levelMenu = CreateFrame("FRAME", "MapUtilsInstanceLevelMenu", UIParent, "UIDropDownMenuTemplate")
	end

	UIDropDownMenu_Initialize(
		levelMenu,
		function()
			for i, level in ipairs(levels) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = GetLevelLabel(levels, level)
				info.checked = shownIndex == i
				info.func = function() SelectLevel(i) end
				UIDropDownMenu_AddButton(info)
			end
		end, "MENU"
	)

	ToggleDropDownMenu(1, nil, levelMenu, owner, 0, 0)
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
	if arrow ~= nil then arrow:Show() end
	if button.selected ~= nil then button.selected:Show() end
	function button:Reanchor()
		local list = navBar.navList
		local last = list[#list]
		if last == nil then return end
		local space = (navBar:GetRight() or 0) - (last:GetRight() or 0) - NAV_BUTTON_EXTRA
		local width = min(self.textWidth or 0, max(space, NAV_BUTTON_MIN_TEXT))
		self.text:SetWidth(width)
		self:SetWidth(width + NAV_BUTTON_EXTRA)
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
		levelButton:SetFrameLevel(overlay:GetFrameLevel() + 10)
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
	if MapUtils:GetConfig("INSTANCEMAP", true) ~= true then return nil end
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

	if #levels > 1 then
		if levelButton.Reanchor ~= nil then levelButton:Reanchor() end
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
