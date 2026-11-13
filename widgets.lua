local _, MapUtils = ...
local map = WorldMapFrame
if map == nil or map.ScrollContainer == nil then return end
local Widgets = {
	inset = 14,
	levelOffset = 1000,
}

local Toggles = {
	size = 18,
	gap = 3,
	iconInset = 1,
	menuIcon = 14,
	offAlpha = 0.4,
	expandIcon = "Interface\\Buttons\\UI-PlusButton-Up",
	collapseIcon = "Interface\\Buttons\\UI-MinusButton-Up",
	glowTemplate = "ActionButtonSpellAlertTemplate",
	glowScale = 1.25,
	glowColor = {1, 0.82, 0},
	glowThickness = 1,
	glowLayers = {{0, 1}, {1, 0.35}},
	sidebarPad = 3,
	sidebarAlpha = 0.6,
	handleSize = 1.5,
	handleInset = 2,
	handleColor = {1, 0.82, 0, 0.9},
	hoverMargin = 16,
	slideTime = 0.15,
	closeDelay = 0.4,
	buttons = {},
	eye = {
		label = "LID_ALLMAPICONS",
		all = true,
		atlas = {"GM-icon-visible", "socialqueuing-icon-eye"},
		file = "Interface\\Icons\\INV_Misc_Eye_01"
	},
	categories = {
		{
			key = "WORLDMAPPINS",
			label = "LID_PIERS",
			default = true,
			refresh = "RefreshPins",
			atlas = {"TaxiNode_Continent_Neutral"},
			file = "Interface\\Icons\\Spell_Arcane_PortalStormwind"
		},
		{
			key = "VESSELWORLDMAPPINS",
			label = "LID_VESSELS",
			default = true,
			refresh = "RefreshTransports",
			file = "Interface\\AddOns\\MapUtils\\media\\vessel_ship",
			available = function() return MapUtils.TRANSPORTROUTES ~= nil end
		},
		{
			key = "DUNGEONWORLDMAPPINS",
			label = "LID_DUNGEONS",
			default = true,
			shared = true,
			atlas = {"Dungeon", "DungeonSkull"},
			file = "Interface\\Icons\\INV_Misc_Bone_Skull_02"
		},
		{
			key = "MEETINGSTONEWORLDMAPPINS",
			label = "LID_MEETINGSTONES",
			default = true,
			shared = true,
			file = "Interface\\AddOns\\MapUtils\\media\\meetingstone"
		},
		{
			key = "SPIRITHEALERWORLDMAPPINS",
			label = "LID_SPIRITHEALERS",
			default = false,
			refresh = "RefreshPins",
			file = "Interface\\AddOns\\MapUtils\\media\\spirithealer",
			available = function() return MapUtils:IsForever() end
		},
		{
			key = "CONVERGENCEWORLDMAPPINS",
			label = "LID_CONVERGENCES",
			default = true,
			refresh = "RefreshPins",
			file = "Interface\\Icons\\Spell_Arcane_Arcane04",
			available = function() return MapUtils:IsForever() end
		},
		{
			key = "LIBRARYBOOKWORLDMAPPINS",
			label = "LID_LIBRARYBOOKS",
			default = true,
			sync = true,
			file = "Interface\\Icons\\INV_Misc_Book_09",
			available = function() return MapUtils.LibraryBookPinsAvailable ~= nil and MapUtils:LibraryBookPinsAvailable() end
		},
		{
			key = "FLIGHTWORLDMAPPINS",
			label = "LID_FLIGHTPOINTS",
			default = true,
			refresh = "RefreshPins",
			atlas = {"TaxiNode_Neutral"},
			file = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green"
		},
		{
			key = "CROSSINGWORLDMAPPINS",
			label = "LID_ZONECROSSINGS",
			default = true,
			refresh = "RefreshPins",
			atlas = {"CaveUnderground-Down"},
			file = "Interface\\Icons\\INV_Misc_Map_01"
		},
		{
			key = "QUESTGIVERWORLDMAPPINS",
			label = "LID_QUESTGIVERS",
			default = true,
			refresh = "RefreshQuestGivers",
			file = "Interface\\GossipFrame\\AvailableQuestIcon",
			available = function() return MapUtils.RefreshQuestGivers ~= nil end
		},
		{
			key = "QUESTTURNINWORLDMAPPINS",
			label = "LID_QUESTTURNINS",
			default = true,
			refresh = "RefreshQuestTurnIns",
			file = "Interface\\GossipFrame\\ActiveQuestIcon",
			available = function() return MapUtils.RefreshQuestTurnIns ~= nil end
		},
		{
			key = "GUILDMEMBERPINS",
			label = "LID_GUILDMEMBERS",
			default = true,
			guild = true,
			file = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
			available = function() return MapUtils.RefreshGuildMembers ~= nil and MapUtils.SetGuildOption ~= nil end
		},
		{
			key = "TOWNPOIS",
			label = "LID_TOWNS",
			default = false,
			refresh = "RefreshAreaPOIs",
			file = "Interface\\Minimap\\Tracking\\Innkeeper",
			available = function() return MapUtils.RefreshAreaPOIs ~= nil end
		},
		{
			key = "CAPITALPOIS",
			label = "LID_CAPITALS",
			default = false,
			refresh = "RefreshAreaPOIs",
			file = "Interface\\Icons\\INV_BannerPVP_02",
			available = function() return MapUtils.RefreshAreaPOIs ~= nil end
		},
	},
}

local Notify = {
	holdTime = 2,
	fadeTime = 1,
	top = 40,
	minWidth = 40,
	minHeight = 12,
}

local Party = {
	gap = 2,
	rowGap = 12,
	interval = 1,
	maxMembers = 4,
	offColor = {0.5, 0.5, 0.5},
	sampleClasses = {"WARRIOR", "PRIEST", "MAGE", "HUNTER"},
	buttons = {},
}

local Player = {
	size = 24,
	icon = "Interface\\Minimap\\MinimapArrow",
}

function Widgets.CreateFrame()
	local container = map.ScrollContainer
	local frame = CreateFrame("Frame", nil, map)
	frame:SetSize(1, 1)
	frame:SetFrameLevel(container:GetFrameLevel() + Widgets.levelOffset)

	return frame
end

function Widgets.SetOutline(text)
	local path, size = text:GetFont()
	if path ~= nil and size ~= nil then text:SetFont(path, size, "OUTLINE") end
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 1)
end

function Widgets.IsEditing()
	return MapUtils.IsMapEditMode ~= nil and MapUtils:IsMapEditMode()
end

function Toggles.IsAvailable(category)
	return category.available == nil or category.available()
end

function Toggles.IsEnabled(category)
	return Toggles.IsAvailable(category) and MapUtils:IsPinCategoryEnabled(category.key)
end

function Toggles.IsOn(category, azeroth)
	if category.guild then return MapUtils:GetGuildPinScopeShown(azeroth) end

	return MapUtils:GetPinScopeShown(category.key, category.default, azeroth)
end

function Toggles.AreAllOn(azeroth)
	local any = false
	for _, category in ipairs(Toggles.categories) do
		if Toggles.IsEnabled(category) then
			any = true
			if not Toggles.IsOn(category, azeroth) then return false end
		end
	end

	return any
end

function Toggles.GetState(category, azeroth)
	if category.all then return Toggles.AreAllOn(azeroth) end

	return Toggles.IsOn(category, azeroth)
end

function Toggles.RefreshCategory(category)
	if category.shared then
		MapUtils:RefreshPins()
		if MapUtils.RefreshInstanceMap ~= nil then MapUtils:RefreshInstanceMap() end
	elseif category.sync then
		MapUtils:RefreshLibraryBooks()
	else
		local refresh = MapUtils[category.refresh]
		if refresh ~= nil then refresh(MapUtils) end
	end
end

function Toggles.Apply(category, azeroth, value)
	if category.guild then
		MapUtils:SetGuildPinScopeShown(azeroth, value)

		return
	end

	if azeroth then
		MapUtils:SetPinAzerothShown(category.key, category.default, value)
		Toggles.RefreshCategory(category)

		return
	end

	MapUtils:KeepPinAzerothState(category.key, category.default)
	if category.shared then
		MapUtils:SetSharedOption(category.key, value)
	elseif category.sync then
		MapUtils.LibraryBooks.Set(category.key, value)
	else
		MapUtils:SetMapOption(category.key, value, function() Toggles.RefreshCategory(category) end)
	end
end

function Toggles.Set(category, azeroth, value)
	Toggles.Apply(category, azeroth, value)
	Notify.Show(Toggles.GetIconMarkup(category) .. MapUtils:Trans(category.label), azeroth, value)
	Toggles.Refresh()
end

function Toggles.SetAll(azeroth, value)
	for _, category in ipairs(Toggles.categories) do
		if Toggles.IsEnabled(category) and Toggles.IsOn(category, azeroth) ~= value then Toggles.Apply(category, azeroth, value) end
	end

	Notify.Show(Toggles.GetIconMarkup(Toggles.eye) .. MapUtils:Trans(Toggles.eye.label), azeroth, value)
	Toggles.Refresh()
end

function Toggles.Click(category, mouseButton)
	local azeroth = mouseButton == "RightButton"
	if category.all then
		Toggles.SetAll(azeroth, not Toggles.AreAllOn(azeroth))
	else
		Toggles.Set(category, azeroth, not Toggles.IsOn(category, azeroth))
	end
end

function Toggles.GetIcon(category)
	if category.atlas ~= nil and MapUtils.FindAtlas ~= nil then
		local atlas = MapUtils:FindAtlas(category.atlas)
		if atlas ~= nil then return atlas, true end
	end

	return category.file, false
end

function Toggles.GetIconMarkup(category)
	local icon, isAtlas = Toggles.GetIcon(category)
	if isAtlas then return format("|A:%s:%d:%d|a ", icon, Toggles.menuIcon, Toggles.menuIcon) end

	return format("|T%s:%d:%d|t ", icon, Toggles.menuIcon, Toggles.menuIcon)
end

function Toggles.GetIconTexture(category)
	local icon, isAtlas = Toggles.GetIcon(category)
	if isAtlas and C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil then
		local info = C_Texture.GetAtlasInfo(icon)
		local file = info and (info.file or info.filename)
		if file ~= nil then return file, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord end
	end

	return category.file, 0, 1, 0, 1
end

function Toggles.GetStateText(on)
	if on then return "|cff20ff20" .. MapUtils:Trans("LID_STATUSSHOWN") .. "|r" end

	return "|cffff4040" .. MapUtils:Trans("LID_STATUSHIDDEN") .. "|r"
end

function MapUtils:RefreshPinToggles()
	Toggles.Layout()
end

function Toggles.GetMenuEntry(category)
	return {
		["text"] = Toggles.GetIconMarkup(category) .. MapUtils:Trans(category.label),
		["dual"] = true,
		["zone"] = function() return Toggles.GetState(category, false) end,
		["azeroth"] = function() return Toggles.GetState(category, true) end,
		["func"] = function(mouseButton) Toggles.Click(category, mouseButton) end,
	}
end

function MapUtils:GetPinToggleEntries()
	local entries = {
		{
			["title"] = true,
			["text"] = format("|cffffd100%s|r %s   |cffffd100%s|r %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_ZONEMAP"), MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_AZEROTHMAP")),
		},
		Toggles.GetMenuEntry(Toggles.eye),
	}

	for _, category in ipairs(Toggles.categories) do
		if Toggles.IsEnabled(category) then
			local entry = Toggles.GetMenuEntry(category)
			if category.guild then
				entry.children = {
					{
						["text"] = MapUtils:Trans("LID_GUILDMEMBERZONES"),
						["checked"] = function() return MapUtils:GetConfig("GUILDMEMBERZONES", true) == true end,
						["func"] = function()
							MapUtils:SetGuildOption("GUILDMEMBERZONES", not MapUtils:GetConfig("GUILDMEMBERZONES", true))
						end,
					},
				}
			end

			tinsert(entries, entry)
		end
	end

	return entries
end

function Toggles.ShowTooltip(button)
	local category = button.category
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(MapUtils:Trans(category.label))
	GameTooltip:AddDoubleLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_ZONEMAP")), Toggles.GetStateText(Toggles.GetState(category, false)), 1, 1, 1)
	GameTooltip:AddDoubleLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_AZEROTHMAP")), Toggles.GetStateText(Toggles.GetState(category, true)), 1, 1, 1)
	GameTooltip:Show()
end

function Toggles.CreateHalf(button, left)
	local inset = Toggles.iconInset
	local texture = button:CreateTexture(nil, "ARTWORK")
	if left then
		texture:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
		texture:SetPoint("BOTTOMRIGHT", button, "BOTTOM", 0, inset)
	else
		texture:SetPoint("TOPLEFT", button, "TOP", 0, -inset)
		texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
	end

	return texture
end

function Toggles.CreateGlow(button)
	if DoesTemplateExist ~= nil and DoesTemplateExist(Toggles.glowTemplate) then
		local alert = CreateFrame("Frame", nil, button, Toggles.glowTemplate)
		alert:SetSize(Toggles.size * Toggles.glowScale, Toggles.size * Toggles.glowScale)
		alert:SetPoint("CENTER", button, "CENTER", 0, 0)
		alert:SetFrameLevel(button:GetFrameLevel() + 1)
		alert:EnableMouse(false)
		if alert.ProcLoop ~= nil then
			alert:HookScript("OnShow", function(self) if not self.ProcLoop:IsPlaying() then self.ProcLoop:Play() end end)
			alert:HookScript("OnHide", function(self) self.ProcLoop:Stop() end)
		end

		return alert
	end

	return Toggles.CreateOutline(button)
end

function Toggles.CreateOutline(button)
	local glow = CreateFrame("Frame", nil, button)
	glow:SetAllPoints(button)
	glow:SetFrameLevel(button:GetFrameLevel() + 1)
	glow:EnableMouse(false)
	local color = Toggles.glowColor
	for index, layer in ipairs(Toggles.glowLayers) do
		local offset, alpha = layer[1], layer[2]
		for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
			local line = glow:CreateTexture(nil, "OVERLAY", nil, index)
			line:SetColorTexture(color[1], color[2], color[3], alpha)
			line:SetBlendMode("ADD")
			if side == "TOP" or side == "BOTTOM" then
				local y = side == "TOP" and offset or -offset
				line:SetPoint(side .. "LEFT", glow, side .. "LEFT", -offset, y)
				line:SetPoint(side .. "RIGHT", glow, side .. "RIGHT", offset, y)
				line:SetHeight(Toggles.glowThickness)
			else
				local x = side == "LEFT" and -offset or offset
				line:SetPoint("TOP" .. side, glow, "TOP" .. side, x, offset)
				line:SetPoint("BOTTOM" .. side, glow, "BOTTOM" .. side, x, -offset)
				line:SetWidth(Toggles.glowThickness)
			end
		end
	end

	return glow
end

function Toggles.CreateButton(category)
	local button = CreateFrame("Button", nil, Toggles.content)
	button:SetSize(Toggles.size, Toggles.size)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button.category = category
	button.left = Toggles.CreateHalf(button, true)
	button.right = Toggles.CreateHalf(button, false)
	local file, l, r, t, b = Toggles.GetIconTexture(category)
	local middle = l + (r - l) / 2
	button.left:SetTexture(file)
	button.left:SetTexCoord(l, middle, t, b)
	button.right:SetTexture(file)
	button.right:SetTexCoord(middle, r, t, b)
	button.full = button:CreateTexture(nil, "ARTWORK")
	button.full:SetPoint("TOPLEFT", button, "TOPLEFT", Toggles.iconInset, -Toggles.iconInset)
	button.full:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -Toggles.iconInset, Toggles.iconInset)
	button.full:SetTexture(file)
	button.full:SetTexCoord(l, r, t, b)
	button.glow = Toggles.CreateGlow(button)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnClick", function(self, mouseButton)
		Toggles.Click(self.category, mouseButton)
		Toggles.ShowTooltip(self)
	end)

	button:SetScript("OnEnter", Toggles.ShowTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)

	return button
end

function Toggles.SetHalf(texture, on)
	texture:SetDesaturated(not on)
	texture:SetAlpha(on and 1 or Toggles.offAlpha)
end

function Toggles.Refresh()
	if Toggles.eyeButton == nil then return end
	local list = {Toggles.eyeButton}
	for _, button in ipairs(Toggles.buttons) do
		tinsert(list, button)
	end

	local glow = MapUtils:GetMapEditIconStyle(Toggles.element) == "GLOW"
	for _, button in ipairs(list) do
		local zone, azeroth = Toggles.GetState(button.category, false), Toggles.GetState(button.category, true)
		button.left:SetShown(not glow)
		button.right:SetShown(not glow)
		button.full:SetShown(glow)
		button.glow:SetShown(glow and zone)
		if glow then
			Toggles.SetHalf(button.full, azeroth)
		else
			Toggles.SetHalf(button.left, zone)
			Toggles.SetHalf(button.right, azeroth)
		end
	end
end

function Toggles.GetStyle()
	return MapUtils:GetMapEditStyle(Toggles.element)
end

function Toggles.IsCollapsed()
	return Toggles.GetStyle() == "COLLAPSE" and MapUtils:GetConfig("TOGGLEWIDGET_COLLAPSED", false) == true
end

function Toggles.ShowCollapseTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(MapUtils:Trans(Toggles.IsCollapsed() and "LID_EXPAND" or "LID_COLLAPSE"))
	GameTooltip:Show()
end

function Toggles.CreateCollapseButton()
	local button = CreateFrame("Button", nil, Toggles.content)
	button:SetSize(Toggles.size, Toggles.size)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.icon:SetSize(Toggles.size - 2, Toggles.size - 2)
	button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
	button:SetScript("OnClick", function(self)
		MAUTTAB = MAUTTAB or {}
		MapUtils:SV(MAUTTAB, "TOGGLEWIDGET_COLLAPSED", not Toggles.IsCollapsed())
		Toggles.Layout()
		Toggles.ShowCollapseTooltip(self)
	end)

	button:SetScript("OnEnter", Toggles.ShowCollapseTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)

	return button
end

function Toggles.GetVisibleButtons()
	local list = {}
	local collapsible = Toggles.GetStyle() == "COLLAPSE"
	local expanded = not Toggles.IsCollapsed()
	Toggles.collapseButton:SetShown(collapsible)
	Toggles.collapseButton.icon:SetTexture(expanded and Toggles.collapseIcon or Toggles.expandIcon)
	if collapsible then tinsert(list, Toggles.collapseButton) end
	Toggles.eyeButton:SetShown(expanded)
	if expanded then tinsert(list, Toggles.eyeButton) end
	for _, button in ipairs(Toggles.buttons) do
		local shown = expanded and Toggles.IsEnabled(button.category)
		button:SetShown(shown)
		if shown then tinsert(list, button) end
	end

	return list
end

function Toggles.IsNear()
	local frame = Toggles.frame
	local left, right, bottom, top = frame:GetLeft(), frame:GetRight(), frame:GetBottom(), frame:GetTop()
	if left == nil then return false end
	local scale = frame:GetEffectiveScale()
	local x, y = GetCursorPosition()
	x, y = x / scale, y / scale
	local margin = Toggles.hoverMargin
	if not Toggles.open then
		local edge = Toggles.edge
		if edge == "RIGHT" then
			left = right - margin
		elseif edge == "LEFT" then
			right = left + margin
		elseif edge == "TOP" then
			bottom = top - margin
		else
			top = bottom + margin
		end
	end

	return x >= left - margin and x <= right + margin and y >= bottom - margin and y <= top + margin
end

function Toggles.ApplySlide()
	local frame, content = Toggles.frame, Toggles.content
	local progress = Toggles.progress
	local dx, dy = 0, 0
	if Toggles.edge ~= nil then
		local hidden = 1 - progress
		if Toggles.edge == "RIGHT" then
			dx = frame:GetWidth() * hidden
		elseif Toggles.edge == "LEFT" then
			dx = -frame:GetWidth() * hidden
		elseif Toggles.edge == "TOP" then
			dy = frame:GetHeight() * hidden
		else
			dy = -frame:GetHeight() * hidden
		end
	end

	content:ClearAllPoints()
	content:SetPoint("TOPLEFT", Toggles.clip, "TOPLEFT", dx, dy)
	content:SetAlpha(progress)
	content:SetShown(progress > 0)
	Toggles.handle:SetShown(Toggles.edge ~= nil and progress < 1)
	Toggles.handle:SetAlpha(1 - progress)
end

function Toggles.OnSlideUpdate(_, elapsed)
	if Toggles.edge == nil then return end
	local near = Widgets.IsEditing() or Toggles.IsNear()
	if near then
		Toggles.open = true
		Toggles.closeTimer = Toggles.closeDelay
	elseif Toggles.open then
		Toggles.closeTimer = (Toggles.closeTimer or 0) - elapsed
		if Toggles.closeTimer <= 0 then Toggles.open = false end
	end

	local target = Toggles.open and 1 or 0
	if Toggles.progress == target then return end
	local step = elapsed / Toggles.slideTime
	if target > Toggles.progress then
		Toggles.progress = math.min(target, Toggles.progress + step)
	else
		Toggles.progress = math.max(target, Toggles.progress - step)
	end

	Toggles.ApplySlide()
end

function Toggles.LayoutHandle(edge)
	local handle, frame = Toggles.handle, Toggles.frame
	handle:ClearAllPoints()
	if edge == nil then return end
	local size, inset = Toggles.handleSize, Toggles.handleInset
	if edge == "LEFT" or edge == "RIGHT" then
		handle:SetPoint("TOP" .. edge, frame, "TOP" .. edge, 0, -inset)
		handle:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge, 0, inset)
		handle:SetWidth(size)
	else
		handle:SetPoint(edge .. "LEFT", frame, edge .. "LEFT", inset, 0)
		handle:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT", -inset, 0)
		handle:SetHeight(size)
	end
end

function Toggles.Layout()
	local frame = Toggles.frame
	if frame == nil then return end
	local sidebar = Toggles.GetStyle() == "SIDEBAR"
	local edge = sidebar and MapUtils:GetMapEditEdge(Toggles.element) or nil
	local vertical = MapUtils:GetMapEditOrientation(Toggles.element) ~= "HORIZONTAL"
	if sidebar then vertical = edge == "LEFT" or edge == "RIGHT" end
	local pad = sidebar and Toggles.sidebarPad or 0
	local list = Toggles.GetVisibleButtons()
	local previous = nil
	for _, button in ipairs(list) do
		button:ClearAllPoints()
		if previous == nil then
			button:SetPoint("TOPLEFT", Toggles.content, "TOPLEFT", pad, -pad)
		elseif vertical then
			button:SetPoint("TOP", previous, "BOTTOM", 0, -Toggles.gap)
		else
			button:SetPoint("LEFT", previous, "RIGHT", Toggles.gap, 0)
		end

		previous = button
	end

	local count = math.max(#list, 1)
	local length = count * Toggles.size + (count - 1) * Toggles.gap + pad * 2
	local depth = Toggles.size + pad * 2
	if vertical then
		frame:SetSize(depth, length)
	else
		frame:SetSize(length, depth)
	end

	Toggles.content:SetSize(frame:GetSize())
	Toggles.content.bg:SetShown(sidebar)
	Toggles.edge = edge
	Toggles.LayoutHandle(edge)
	if edge == nil or Widgets.IsEditing() then
		Toggles.open = edge ~= nil
		Toggles.progress = 1
	end

	Toggles.ApplySlide()
	frame:SetShown(MapUtils:IsMapEditElementVisible(Toggles.element))
	Toggles.Refresh()
end

function Toggles.Create()
	Toggles.frame = Widgets.CreateFrame()
	Toggles.clip = CreateFrame("Frame", nil, Toggles.frame)
	Toggles.clip:SetAllPoints(Toggles.frame)
	if Toggles.clip.SetClipsChildren ~= nil then Toggles.clip:SetClipsChildren(true) end
	Toggles.clip:SetScript("OnUpdate", function(self, elapsed) Toggles.OnSlideUpdate(self, elapsed) end)
	Toggles.content = CreateFrame("Frame", nil, Toggles.clip)
	Toggles.content.bg = Toggles.content:CreateTexture(nil, "BACKGROUND")
	Toggles.content.bg:SetAllPoints(Toggles.content)
	Toggles.content.bg:SetColorTexture(0, 0, 0, Toggles.sidebarAlpha)
	Toggles.handle = Toggles.frame:CreateTexture(nil, "OVERLAY")
	Toggles.handle:SetColorTexture(Toggles.handleColor[1], Toggles.handleColor[2], Toggles.handleColor[3], Toggles.handleColor[4])
	Toggles.progress = 1
	Toggles.element = {
		key = "TOGGLEWIDGET",
		title = "LID_TOGGLEWIDGET",
		frame = Toggles.frame,
		defaultPoint = {"TOPRIGHT", -Widgets.inset, -Widgets.inset},
		defaultAlign = "RIGHT",
		defaultOrientation = "VERTICAL",
		defaultEdge = "RIGHT",
		options = {
			orientation = true,
			scale = true,
			styles = true,
			iconStyles = true
		},
		OnLayout = Toggles.Layout,
		OnEditMode = Toggles.Layout,
	}

	Toggles.collapseButton = Toggles.CreateCollapseButton()
	Toggles.eyeButton = Toggles.CreateButton(Toggles.eye)
	for _, category in ipairs(Toggles.categories) do
		if Toggles.IsAvailable(category) then tinsert(Toggles.buttons, Toggles.CreateButton(category)) end
	end

	MapUtils:RegisterMapEditElement(Toggles.element)
end

function Notify.Render(text)
	local frame = Notify.frame
	local align = MapUtils:GetMapEditAlign(Notify.element)
	local point = align == "CENTER" and "CENTER" or align
	frame.text:ClearAllPoints()
	frame.text:SetPoint(point, frame, point, 0, 0)
	frame.text:SetJustifyH(align)
	frame.text:SetText(text)
	frame:SetSize(math.max(frame.text:GetStringWidth(), Notify.minWidth), math.max(frame.text:GetStringHeight(), Notify.minHeight))
end

function Notify.Show(label, azeroth, value)
	if Notify.frame == nil or Widgets.IsEditing() then return end
	local key = format("LID_NOTIFY%s%s", azeroth and "AZEROTH" or "ZONE", value and "SHOWN" or "HIDDEN")
	Notify.Render(MapUtils:Trans(key, nil, label))
	Notify.remaining = Notify.holdTime + Notify.fadeTime
	Notify.frame.text:SetAlpha(1)
end

function Notify.OnUpdate(_, elapsed)
	if Notify.remaining == nil or Widgets.IsEditing() then return end
	Notify.remaining = Notify.remaining - elapsed
	if Notify.remaining <= 0 then
		Notify.remaining = nil
		Notify.frame.text:SetText("")

		return
	end

	Notify.frame.text:SetAlpha(math.min(1, Notify.remaining / Notify.fadeTime))
end

function Notify.Layout()
	local frame = Notify.frame
	if frame == nil then return end
	if Widgets.IsEditing() then
		Notify.remaining = nil
		frame.text:SetAlpha(1)
		Notify.Render(MapUtils:Trans("LID_NOTIFYWIDGET"))
	elseif Notify.remaining == nil then
		Notify.Render("")
	end

	frame:SetShown(MapUtils:IsMapEditElementVisible(Notify.element))
end

function Notify.Create()
	local frame = Widgets.CreateFrame()
	Notify.frame = frame
	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	Notify.element = {
		key = "NOTIFYWIDGET",
		title = "LID_NOTIFYWIDGET",
		frame = frame,
		defaultPoint = {"TOP", 0, -Notify.top},
		defaultAlign = "CENTER",
		options = {
			align = true,
			scale = true
		},
		OnLayout = Notify.Layout,
		OnEditMode = Notify.Layout,
	}

	frame:SetScript("OnUpdate", function(self, elapsed) Notify.OnUpdate(self, elapsed) end)
	MapUtils:RegisterMapEditElement(Notify.element)
end

function Party.GetMembers()
	local members = {}
	for i = 1, Party.maxMembers do
		local unit = "party" .. i
		if UnitExists(unit) then tinsert(members, unit) end
	end

	return members
end

function Party.CreateButton()
	local button = CreateFrame("Button", nil, Party.frame)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	Widgets.SetOutline(button.text)
	button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
	button:SetScript("OnClick", function(self) if self.unit ~= nil then MapUtils:CenterWorldMapOnUnit(self.unit) end end)

	return button
end

function Party.GetButton(index)
	if Party.buttons[index] == nil then Party.buttons[index] = Party.CreateButton() end

	return Party.buttons[index]
end

function Party.GetEntry(unit)
	local _, class = UnitClass(unit)
	local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	local known = MapUtils:GetUnitMapPosition(unit) ~= nil
	if not known or color == nil then color = {
		r = Party.offColor[1],
		g = Party.offColor[2],
		b = Party.offColor[3]
	} end

	return UnitName(unit) or unit, color, known
end

function Party.GetSample()
	local entries = {}
	for _, class in ipairs(Party.sampleClasses) do
		local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or {
			r = 1,
			g = 1,
			b = 1
		}

		local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class
		tinsert(entries, {nil, name, color, false})
	end

	return entries
end

function Party.Update(force)
	local frame = Party.frame
	if frame == nil then return end
	local entries = {}
	if Widgets.IsEditing() then
		entries = Party.GetSample()
	else
		for _, unit in ipairs(Party.GetMembers()) do
			local name, color, known = Party.GetEntry(unit)
			tinsert(entries, {unit, name, color, known})
		end
	end

	local align = MapUtils:GetMapEditAlign(Party.element)
	local vertical = MapUtils:GetMapEditOrientation(Party.element) ~= "HORIZONTAL"
	local keyParts = {align, tostring(vertical)}
	for _, entry in ipairs(entries) do
		tinsert(keyParts, format("%s:%s:%s", tostring(entry[1]), entry[2], tostring(entry[4])))
	end

	local key = table.concat(keyParts, "|")
	if not force and Party.key == key then return end
	Party.key = key
	Party.Layout(entries, align, vertical)
end

function Party.Layout(entries, align, vertical)
	local frame = Party.frame
	local side = align == "CENTER" and "" or align
	local width, height, previous = 0, 0, nil
	for index, button in ipairs(Party.buttons) do
		if index > #entries then button:Hide() end
	end

	for index, entry in ipairs(entries) do
		local button = Party.GetButton(index)
		button.unit = entry[1]
		button.text:SetText(entry[2])
		button.text:SetTextColor(entry[3].r, entry[3].g, entry[3].b)
		button:SetEnabled(entry[4])
		local w, h = button.text:GetStringWidth(), button.text:GetStringHeight()
		button:SetSize(math.max(w, 1), math.max(h, 1))
		button:ClearAllPoints()
		if vertical then
			if previous == nil then
				button:SetPoint("TOP" .. side, frame, "TOP" .. side, 0, 0)
			else
				button:SetPoint("TOP" .. side, previous, "BOTTOM" .. side, 0, -Party.gap)
			end

			width = math.max(width, w)
			height = height + h + (previous and Party.gap or 0)
		else
			if previous == nil then
				button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			else
				button:SetPoint("LEFT", previous, "RIGHT", Party.rowGap, 0)
			end

			width = width + w + (previous and Party.rowGap or 0)
			height = math.max(height, h)
		end

		button:Show()
		previous = button
	end

	frame:SetSize(math.max(width, 1), math.max(height, 1))
	frame:SetShown(#entries > 0 and MapUtils:IsMapEditElementVisible(Party.element))
end

function Party.Create()
	Party.frame = Widgets.CreateFrame()
	Party.element = {
		key = "PARTYWIDGET",
		title = "LID_PARTYWIDGET",
		frame = Party.frame,
		defaultPoint = {"LEFT", Widgets.inset, 0},
		defaultAlign = "LEFT",
		defaultOrientation = "VERTICAL",
		options = {
			align = true,
			orientation = true,
			scale = true
		},
		OnLayout = function() Party.Update(true) end,
		OnEditMode = function() Party.Update(true) end,
	}

	MapUtils:RegisterMapEditElement(Party.element)
	local events = CreateFrame("Frame")
	for _, event in ipairs({"GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "UNIT_NAME_UPDATE"}) do
		pcall(events.RegisterEvent, events, event)
	end

	events:SetScript("OnEvent", MapUtils.Profile("widgets party events", function() if map:IsShown() then Party.Update() end end))
	local elapsed = 0
	events:SetScript("OnUpdate", MapUtils.Profile("widgets party OnUpdate", function(_, delta)
		if not map:IsShown() then return end
		elapsed = elapsed + delta
		if elapsed < Party.interval then return end
		elapsed = 0
		Party.Update()
	end))
end

function Player.ShowTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOP")
	GameTooltip:SetText(MapUtils:Trans("LID_CENTERONPLAYER"))
	GameTooltip:Show()
end

function Player.Layout()
	local frame = Player.frame
	if frame == nil then return end
	frame:SetSize(Player.size, Player.size)
	frame:SetShown(MapUtils:IsMapEditElementVisible(Player.element))
end

function Player.Create()
	local frame = Widgets.CreateFrame()
	Player.frame = frame
	local button = CreateFrame("Button", nil, frame)
	button:SetAllPoints(frame)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints(button)
	button.icon:SetTexture(Player.icon)
	button:SetHighlightTexture(Player.icon, "ADD")
	button:SetScript("OnClick", function() MapUtils:CenterWorldMapOnUnit("player") end)
	button:SetScript("OnEnter", Player.ShowTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Player.button = button
	Player.element = {
		key = "PLAYERWIDGET",
		title = "LID_PLAYERWIDGET",
		frame = frame,
		defaultPoint = {"BOTTOM", 0, Widgets.inset},
		defaultAlign = "CENTER",
		options = {
			scale = true
		},
		OnLayout = Player.Layout,
		OnEditMode = Player.Layout,
	}

	MapUtils:RegisterMapEditElement(Player.element)
end

function Widgets.Init()
	if Widgets.ready or MapUtils.RegisterMapEditElement == nil or MapUtils.GetConfig == nil then return end
	Widgets.ready = true
	Toggles.Create()
	Notify.Create()
	Party.Create()
	Player.Create()
	map:HookScript("OnShow", function()
		Toggles.Layout()
		Party.Update(true)
	end)
end

Widgets.loader = CreateFrame("Frame")
Widgets.loader:RegisterEvent("PLAYER_LOGIN")
Widgets.loader:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	Widgets.Init()
end)
MapUtils.ProfileTable("Widgets", Widgets)
MapUtils.ProfileTable("Toggles", Toggles)
MapUtils.ProfileTable("Notify", Notify)
MapUtils.ProfileTable("Party", Party)
MapUtils.ProfileTable("Player", Player)
