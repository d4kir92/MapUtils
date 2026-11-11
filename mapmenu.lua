local AddonName, MapUtils = ...
local map = WorldMapFrame
if map == nil then return end
local MapMenu = {
	circle = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
	circleSize = 14,
	navSize = 20,
	navInset = 6,
	cogAtlas = "QuestLog-icon-setting",
	cogTexture = "Interface\\Buttons\\UI-OptionsButton",
	offColor = {
		r = 0.5,
		g = 0.5,
		b = 0.5
	},
}

function MapMenu.Circle(color)
	local size = MapMenu.circleSize

	return format("|T%s:%d:%d:0:0:64:64:0:64:0:64:%d:%d:%d|t ", MapMenu.circle, size, size, color.r * 255, color.g * 255, color.b * 255)
end

function MapMenu.AddParty(entries)
	local first = true
	for i = 1, 4 do
		local unit = "party" .. i
		if UnitExists(unit) then
			if first then
				tinsert(entries, {["divider"] = true})
				first = false
			end

			local _, class = UnitClass(unit)
			local color = class and RAID_CLASS_COLORS[class] or MapMenu.offColor
			tinsert(entries, {
				["text"] = MapMenu.Circle(color) .. (UnitName(unit) or unit),
				["disabled"] = MapUtils:GetUnitMapPosition(unit) == nil,
				["func"] = function() MapUtils:CenterWorldMapOnUnit(unit) end,
			})
		end
	end
end

function MapMenu.AddPinToggles(entries)
	if MapUtils.GetPinToggleEntries == nil then return end
	local toggles = MapUtils:GetPinToggleEntries()
	if #toggles == 0 then return end
	tinsert(entries, {["divider"] = true})
	for _, entry in ipairs(toggles) do
		tinsert(entries, entry)
	end
end

function MapMenu.GetEntries()
	local entries = {
		{
			["text"] = MapUtils:Trans("LID_EDITMODE"),
			["checked"] = function() return MapUtils.IsMapEditMode ~= nil and MapUtils:IsMapEditMode() end,
			["func"] = function() if MapUtils.SetMapEditMode ~= nil then MapUtils:SetMapEditMode(not MapUtils:IsMapEditMode()) end end,
		},
		{
			["text"] = MapUtils:Trans("LID_EDITMODEGRID"),
			["checked"] = function() return MapUtils.IsMapEditGrid ~= nil and MapUtils:IsMapEditGrid() end,
			["func"] = function() if MapUtils.SetMapEditGrid ~= nil then MapUtils:SetMapEditGrid(not MapUtils:IsMapEditGrid()) end end,
		},
		{
			["text"] = MapUtils:Trans("LID_OPENSETTINGS"),
			["func"] = function() MapUtils:ToggleSettings() end,
		}
	}

	MapMenu.AddPinToggles(entries)
	MapMenu.AddParty(entries)

	return entries
end

function MapMenu.AddModernEntry(root, entry)
	if entry.divider then
		root:CreateDivider()

		return
	end

	local element = nil
	if entry.checked ~= nil and entry.radio then
		element = root:CreateRadio(entry.text, entry.checked, entry.func)
	elseif entry.checked ~= nil then
		element = root:CreateCheckbox(entry.text, entry.checked, entry.func)
	else
		element = root:CreateButton(entry.text, entry.func)
	end

	if entry.disabled and element ~= nil and element.SetEnabled ~= nil then element:SetEnabled(false) end
end

function MapMenu.Show(owner)
	MapUtils:ShowEntryMenu(owner, MapMenu.GetEntries())
end

function MapUtils:ShowEntryMenu(owner, entries)
	if MenuUtil ~= nil and MenuUtil.CreateContextMenu ~= nil then
		MenuUtil.CreateContextMenu(owner, function(_, root)
			for _, entry in ipairs(entries) do
				MapMenu.AddModernEntry(root, entry)
			end
		end)

		return
	end

	if UIDropDownMenu_Initialize == nil or ToggleDropDownMenu == nil then return end
	if MapMenu.dropdown == nil then MapMenu.dropdown = CreateFrame("Frame", AddonName .. "MapMenu", UIParent, "UIDropDownMenuTemplate") end
	UIDropDownMenu_Initialize(MapMenu.dropdown, function()
		for _, entry in ipairs(entries) do
			local info = UIDropDownMenu_CreateInfo()
			info.notCheckable = entry.checked == nil
			if entry.checked ~= nil then
				info.checked = entry.checked()
				info.isNotRadio = not entry.radio
			end

			if entry.divider then
				info.text = ""
				info.disabled = true
			else
				info.text = entry.text
				info.func = entry.func
				info.disabled = entry.disabled
			end

			UIDropDownMenu_AddButton(info)
		end
	end, "MENU")

	ToggleDropDownMenu(1, nil, MapMenu.dropdown, owner, 0, 0)
end

function MapUtils:LayoutMapMenuButton()
	local button = MapMenu.button
	if button == nil then return end
	local nav = map.NavBar
	button:ClearAllPoints()
	if nav ~= nil then
		button:SetSize(MapMenu.navSize, MapMenu.navSize)
		button:SetPoint("RIGHT", nav, "RIGHT", -MapMenu.navInset, 0)
		button:SetFrameLevel(nav:GetFrameLevel() + 5)

		return
	end

	local anchor = MapMenu.anchor
	button:SetSize(anchor:GetSize())
	button:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
	button:SetFrameLevel(anchor:GetFrameLevel())
end

function MapMenu.Create()
	local border = map.BorderFrame
	local arrow = border and border.MaximizeMinimizeFrame
	local parent = map
	if map.NavBar == nil then
		parent = arrow or border
		MapMenu.anchor = arrow and (arrow.MapUtilsFullscreenButton or arrow) or (border and border.CloseButton) or WorldMapFrameCloseButton
		if parent == nil or MapMenu.anchor == nil then return end
	end

	local button = CreateFrame("Button", nil, parent)
	MapMenu.button = button
	MapUtils.MapMenuButton = button
	MapUtils:LayoutMapMenuButton()
	local icon = button:CreateTexture(nil, "ARTWORK")
	if MapUtils:AtlasExists(MapMenu.cogAtlas) then
		icon:SetAtlas(MapMenu.cogAtlas)
	else
		icon:SetTexture(MapMenu.cogTexture)
	end

	local function LayoutIcon(self, width, height)
		icon:ClearAllPoints()
		icon:SetPoint("CENTER", self, "CENTER", 0, 0)
		icon:SetSize(width * 0.7, height * 0.7)
	end

	button:SetScript("OnSizeChanged", LayoutIcon)
	LayoutIcon(button, button:GetSize())
	button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	button:SetScript("OnMouseDown", function() icon:SetPoint("CENTER", button, "CENTER", 1, -1) end)
	button:SetScript("OnMouseUp", function() icon:SetPoint("CENTER", button, "CENTER", 0, 0) end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(MapUtils:Trans("LID_MAPMENU"))
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnClick", function(self)
		GameTooltip:Hide()
		MapMenu.Show(self)
	end)
end

MapMenu.Create()
