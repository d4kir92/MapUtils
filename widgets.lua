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
	offAlpha = 0.4,
	buttons = {},
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

local Party = {
	gap = 2,
	rowGap = 12,
	interval = 1,
	maxMembers = 4,
	offColor = {0.5, 0.5, 0.5},
	sampleClasses = {"WARRIOR", "PRIEST", "MAGE", "HUNTER"},
	buttons = {},
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

function Toggles.IsOn(category)
	return MapUtils:GetConfig(category.key, category.default) == true
end

function Toggles.Set(category, value)
	if category.shared then
		MapUtils:SetSharedOption(category.key, value)
	elseif category.guild then
		MapUtils:SetGuildOption(category.key, value)
	else
		MapUtils:SetMapOption(category.key, value, function()
			local refresh = MapUtils[category.refresh]
			if refresh ~= nil then refresh(MapUtils) end
		end)
	end

	Toggles.Refresh()
end

function Toggles.GetIcon(category)
	if category.atlas ~= nil and MapUtils.FindAtlas ~= nil then
		local atlas = MapUtils:FindAtlas(category.atlas)
		if atlas ~= nil then return atlas, true end
	end

	return category.file, false
end

function Toggles.ShowTooltip(button)
	local category = button.category
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(MapUtils:Trans(category.label))
	GameTooltip:AddLine(MapUtils:Trans(Toggles.IsOn(category) and "LID_CLICKTOHIDE" or "LID_CLICKTOSHOW"), 1, 1, 1)
	GameTooltip:Show()
end

function Toggles.CreateButton(category)
	local button = CreateFrame("Button", nil, Toggles.frame)
	button:SetSize(Toggles.size, Toggles.size)
	button.category = category
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", Toggles.iconInset, -Toggles.iconInset)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -Toggles.iconInset, Toggles.iconInset)
	local icon, isAtlas = Toggles.GetIcon(category)
	if isAtlas then
		button.icon:SetAtlas(icon)
	else
		button.icon:SetTexture(icon)
	end

	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnClick", function(self)
		Toggles.Set(self.category, not Toggles.IsOn(self.category))
		Toggles.ShowTooltip(self)
	end)

	button:SetScript("OnEnter", Toggles.ShowTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)

	return button
end

function Toggles.Refresh()
	for _, button in ipairs(Toggles.buttons) do
		local on = Toggles.IsOn(button.category)
		button.icon:SetDesaturated(not on)
		button.icon:SetAlpha(on and 1 or Toggles.offAlpha)
	end
end

function Toggles.Layout()
	local frame = Toggles.frame
	if frame == nil then return end
	local vertical = MapUtils:GetMapEditOrientation(Toggles.element) ~= "HORIZONTAL"
	local previous = nil
	for _, button in ipairs(Toggles.buttons) do
		button:ClearAllPoints()
		if previous == nil then
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		elseif vertical then
			button:SetPoint("TOP", previous, "BOTTOM", 0, -Toggles.gap)
		else
			button:SetPoint("LEFT", previous, "RIGHT", Toggles.gap, 0)
		end

		previous = button
	end

	local count = math.max(#Toggles.buttons, 1)
	local length = count * Toggles.size + (count - 1) * Toggles.gap
	if vertical then
		frame:SetSize(Toggles.size, length)
	else
		frame:SetSize(length, Toggles.size)
	end

	Toggles.Refresh()
end

function Toggles.Create()
	Toggles.frame = Widgets.CreateFrame()
	for _, category in ipairs(Toggles.categories) do
		if category.available == nil or category.available() then tinsert(Toggles.buttons, Toggles.CreateButton(category)) end
	end

	Toggles.element = {
		key = "TOGGLEWIDGET",
		title = "LID_TOGGLEWIDGET",
		frame = Toggles.frame,
		defaultPoint = {"TOPRIGHT", -Widgets.inset, -Widgets.inset},
		defaultAlign = "RIGHT",
		defaultOrientation = "VERTICAL",
		options = {
			orientation = true,
			scale = true
		},
		OnLayout = Toggles.Layout,
	}

	MapUtils:RegisterMapEditElement(Toggles.element)
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
	frame:SetShown(#entries > 0)
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

	events:SetScript("OnEvent", function() if map:IsShown() then Party.Update() end end)
	local elapsed = 0
	events:SetScript("OnUpdate", function(_, delta)
		if not map:IsShown() then return end
		elapsed = elapsed + delta
		if elapsed < Party.interval then return end
		elapsed = 0
		Party.Update()
	end)
end

function Widgets.Init()
	if Widgets.ready or MapUtils.RegisterMapEditElement == nil or MapUtils.GetConfig == nil then return end
	Widgets.ready = true
	Toggles.Create()
	Party.Create()
	map:HookScript("OnShow", function()
		Toggles.Refresh()
		Party.Update(true)
	end)
end

Widgets.loader = CreateFrame("Frame")
Widgets.loader:RegisterEvent("PLAYER_LOGIN")
Widgets.loader:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	Widgets.Init()
end)
