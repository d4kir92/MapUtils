local _, MapUtils = ...
if WorldMapFrame == nil or C_Map == nil then return end
local CM = {
	key = "CUSTOMMARKERWORLDMAPPINS",
	size = 20,
	level = 2550,
	labelSize = 11,
	pins = {},
	columns = 10,
	rows = 10,
	iconButtonSize = 32,
	iconStep = 36,
	defaultIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
	circleMask = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
	macroIconSources = {"GetLooseMacroIcons", "GetLooseMacroItemIcons", "GetMacroIcons", "GetMacroItemIcons"},
}

MapUtils.CustomMarkers = CM
function CM.GetList()
	MAUTTAB = MAUTTAB or {}
	if type(MAUTTAB["CUSTOMMARKERS"]) ~= "table" then MAUTTAB["CUSTOMMARKERS"] = {} end

	return MAUTTAB["CUSTOMMARKERS"]
end

function CM.ResolveIcon(icon)
	if icon == nil or icon == "" then return CM.defaultIcon end

	return tonumber(icon) or icon
end

function CM.CreateMask(owner, anchor)
	if owner.CreateMaskTexture == nil then return nil end
	local mask = owner:CreateMaskTexture()
	mask:SetTexture(CM.circleMask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(anchor)

	return mask
end

function CM.AddMask(texture, mask)
	if mask ~= nil and texture ~= nil and texture.AddMaskTexture ~= nil then texture:AddMaskTexture(mask) end
end

function CM.CreateRoundIcon(owner)
	owner.outline = owner:CreateTexture(nil, "BACKGROUND")
	owner.outline:SetAllPoints(owner)
	owner.outline:SetColorTexture(0, 0, 0, 1)
	owner.icon = owner:CreateTexture(nil, "ARTWORK")
	owner.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	owner.outerMask = CM.CreateMask(owner, owner)
	owner.innerMask = CM.CreateMask(owner, owner.icon)
	CM.AddMask(owner.outline, owner.outerMask)
	CM.AddMask(owner.icon, owner.innerMask)
	CM.SetRoundInset(owner, 1)
end

function CM.SetRoundInset(owner, inset)
	if owner.roundInset == inset then return end
	owner.roundInset = inset
	owner.icon:ClearAllPoints()
	owner.icon:SetPoint("TOPLEFT", owner, "TOPLEFT", inset, -inset)
	owner.icon:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -inset, inset)
end

function CM.IsInstanceShown()
	return MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
end

function CM.GetClip(mapID)
	if MapUtils.IsOneMap ~= nil and MapUtils.IsZoneDetailMap ~= nil and MapUtils:IsOneMap() and MapUtils:IsZoneDetailMap(mapID) then return -50, 51 end

	return 0, 1
end

function CM.ToWorld(mapID, x, y)
	if CM.IsWorldType(mapID) then return nil end
	local rect = MapUtils.GetMapRect and MapUtils.GetMapRect(mapID)
	if rect == nil then return nil end

	return rect.continentID, rect[1].x + rect[2].x * y, rect[1].y + rect[2].y * x
end

function CM.GetMapPos(marker, mapID)
	if marker.mapID == mapID then return marker.x, marker.y end
	if CM.IsWorldType(mapID) then return CM.ProjectUp(marker.mapID, mapID, marker.x, marker.y) end
	if CM.IsWorldType(marker.mapID) then return CM.ProjectDown(mapID, marker.mapID, marker.x, marker.y) end
	if marker.continent == nil or marker.wx == nil or marker.wy == nil then return nil end
	local rect = MapUtils.GetMapRect and MapUtils.GetMapRect(mapID)
	if rect == nil or rect.continentID ~= marker.continent then return nil end

	return (marker.wy - rect[1].y) / rect[2].y, (marker.wx - rect[1].x) / rect[2].x
end

function CM.IsWorldType(mapID)
	local info = mapID and C_Map.GetMapInfo(mapID)
	if info == nil or info.mapType == nil or Enum == nil or Enum.UIMapType == nil then return false end

	return info.mapType == Enum.UIMapType.Cosmic or info.mapType == Enum.UIMapType.World
end

function CM.ProjectUp(fromID, toID, x, y)
	for _ = 1, 10 do
		if fromID == toID then return x, y end
		local info = C_Map.GetMapInfo(fromID)
		local parentID = info and info.parentMapID
		if parentID == nil or parentID == 0 or C_Map.GetMapRectOnMap == nil then return nil end
		local ok, left, right, top, bottom = pcall(C_Map.GetMapRectOnMap, fromID, parentID)
		if not ok or left == nil or right == nil or top == nil or bottom == nil or right <= left or bottom <= top then return nil end
		x, y = left + (right - left) * x, top + (bottom - top) * y
		fromID = parentID
	end
end

function CM.ProjectDown(mapID, ancestorID, x, y)
	local left, top = CM.ProjectUp(mapID, ancestorID, 0, 0)
	local right, bottom = CM.ProjectUp(mapID, ancestorID, 1, 1)
	if left == nil or right == nil or right <= left or bottom <= top then return nil end

	return (x - left) / (right - left), (y - top) / (bottom - top)
end

function CM.IsShown(mapID)
	if mapID == nil or CM.IsInstanceShown() then return false end

	return MapUtils:IsPinShownOnMap(CM.key, true, mapID)
end

function CM.HidePins()
	for _, pin in ipairs(CM.pins) do
		pin:Hide()
	end
end

function CM.OnEnter(pin)
	local marker = pin.marker
	if marker == nil then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	GameTooltip:SetText((marker.name or "") ~= "" and marker.name or MapUtils:Trans("LID_CUSTOMMARKERDEFAULTNAME"), 1, 0.82, 0)
	local info = C_Map.GetMapInfo(marker.mapID)
	if info ~= nil and info.name ~= nil then GameTooltip:AddLine(format("%s (%.1f, %.1f)", info.name, marker.x * 100, marker.y * 100), 1, 1, 1) end
	GameTooltip:AddLine(" ")
	if MapUtils:HasWaypointSupport() then GameTooltip:AddLine(format("|cffffd100%s|r %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SETWAYPOINT")), 1, 1, 1) end
	GameTooltip:AddLine(format("|cffffd100%s|r %s", MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_CUSTOMMARKEREDIT")), 1, 1, 1)
	GameTooltip:Show()
end

function CM.SetWaypoint(pin)
	local marker = pin.marker
	if marker == nil or not MapUtils:HasWaypointSupport() then return end
	local mapID, x, y = marker.mapID, marker.x, marker.y
	if x < 0 or x > 1 or y < 0 or y > 1 then
		mapID = WorldMapFrame:GetMapID()
		x, y = CM.GetMapPos(marker, mapID)
		if x == nil then return end
	end

	if MapUtils:SetTrackedWaypoint(mapID, x, y) and SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON then PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON) end
end

function CM.OnClick(pin, button)
	if button == "LeftButton" then
		CM.SetWaypoint(pin)
	elseif pin.marker ~= nil then
		GameTooltip:Hide()
		CM.OpenDialog(pin.marker)
	end
end

function CM.CreatePin(canvas)
	local pin = CreateFrame("Button", nil, canvas)
	pin:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
	CM.CreateRoundIcon(pin)
	pin.highlight = pin:CreateTexture(nil, "HIGHLIGHT")
	pin.highlight:SetAllPoints(pin)
	pin.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	pin.highlight:SetBlendMode("ADD")
	CM.AddMask(pin.highlight, pin.outerMask)
	pin.label = pin:CreateFontString(nil, "OVERLAY")
	pin.label:SetPoint("TOP", pin, "BOTTOM", 0, -1)
	pin:SetScript("OnEnter", CM.OnEnter)
	pin:SetScript("OnLeave", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
	pin:SetScript("OnHide", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
	pin:SetScript("OnClick", CM.OnClick)

	return pin
end

function CM.UpdatePins()
	local mapID = WorldMapFrame:GetMapID()
	if not CM.IsShown(mapID) then return CM.HidePins() end
	local canvas = WorldMapFrame:GetCanvas()
	if canvas == nil then return end
	local scale = canvas:GetScale()
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if scale == nil or scale <= 0 or width <= 0 or height <= 0 then return CM.HidePins() end
	local pinScale = scale / MapUtils:GetPinSizeFactor(CM.key)
	local low, high = CM.GetClip(mapID)
	local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local count = 0
	for _, marker in ipairs(CM.GetList()) do
		local x, y = CM.GetMapPos(marker, mapID)
		if x ~= nil and x >= low and x <= high and y >= low and y <= high then
			count = count + 1
			local pin = CM.pins[count]
			if pin == nil then
				pin = CM.CreatePin(canvas)
				CM.pins[count] = pin
			end

			pin.marker = marker
			pin.icon:SetTexture(CM.ResolveIcon(marker.icon))
			pin:SetSize(CM.size / pinScale, CM.size / pinScale)
			CM.SetRoundInset(pin, 1 / scale)
			pin.label:SetFont(font, CM.labelSize / pinScale, "OUTLINE")
			pin.label:SetText(marker.name or "")
			pin:SetFrameLevel(canvas:GetFrameLevel() + CM.level)
			MapUtils:SetCanvasPinScale(pin, scale)
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", canvas, "TOPLEFT", width * x, -height * y)
			pin:Show()
		end
	end

	for index = count + 1, #CM.pins do
		CM.pins[index]:Hide()
	end
end

function MapUtils:RefreshCustomMarkers()
	CM.UpdatePins()
	if MapUtils.RescaleCanvasPins ~= nil then MapUtils:RescaleCanvasPins() end
end

function CM.Save()
	local dialog = CM.dialog
	local name = strtrim(dialog.nameBox:GetText() or "")
	local marker = dialog.marker
	if marker == nil then
		marker = dialog.pending
		tinsert(CM.GetList(), marker)
	end

	marker.name = name
	marker.icon = dialog.icon
	dialog:Hide()
	MapUtils:RefreshCustomMarkers()
end

function CM.Delete()
	local dialog = CM.dialog
	local list = CM.GetList()
	for index, marker in ipairs(list) do
		if marker == dialog.marker then
			tremove(list, index)
			break
		end
	end

	dialog:Hide()
	MapUtils:RefreshCustomMarkers()
end

function CM.NormalizeIcon(icon)
	if type(icon) == "string" and not icon:find("\\", 1, true) then return "Interface\\Icons\\" .. icon end

	return icon
end

function CM.GetIcons()
	if CM.iconList ~= nil then return CM.iconList end
	local raw = {}
	for _, name in ipairs(CM.macroIconSources) do
		local fn = _G[name]
		if fn ~= nil then pcall(fn, raw) end
	end

	if #raw == 0 and GetNumMacroIcons ~= nil and GetMacroIconInfo ~= nil then
		for index = 1, GetNumMacroIcons() do
			tinsert(raw, GetMacroIconInfo(index))
		end
	end

	local list, seen = {CM.defaultIcon}, {[CM.defaultIcon] = true, [134400] = true}
	for _, icon in ipairs(raw) do
		icon = CM.NormalizeIcon(icon)
		if icon ~= nil and not seen[icon] then
			seen[icon] = true
			tinsert(list, icon)
		end
	end

	CM.iconList = list

	return list
end

function CM.UpdateGrid()
	local dialog = CM.dialog
	local icons = CM.GetIcons()
	local scroll = dialog.scroll
	FauxScrollFrame_Update(scroll, math.ceil(#icons / CM.columns), CM.rows, CM.iconStep)
	local first = FauxScrollFrame_GetOffset(scroll) * CM.columns
	for index, button in ipairs(dialog.iconButtons) do
		local icon = icons[first + index]
		button.path = icon
		if icon ~= nil then
			button.icon:SetTexture(icon)
			button.selected:SetShown(icon == dialog.icon)
			button:Show()
		else
			button:Hide()
		end
	end
end

function CM.SelectIcon(icon)
	local dialog = CM.dialog
	dialog.icon = icon
	dialog.preview.icon:SetTexture(CM.ResolveIcon(icon))
	CM.UpdateGrid()
end

function CM.ScrollToIcon(icon)
	local dialog = CM.dialog
	local row = 0
	for index, entry in ipairs(CM.GetIcons()) do
		if entry == icon then
			row = math.floor((index - 1) / CM.columns)
			break
		end
	end

	local bar = dialog.scroll.ScrollBar or _G[dialog.scroll:GetName() .. "ScrollBar"]
	local maxRow = math.max(0, math.ceil(#CM.GetIcons() / CM.columns) - CM.rows)
	if bar ~= nil then bar:SetValue(math.min(math.max(row - math.floor(CM.rows / 2), 0), maxRow) * CM.iconStep) end
	CM.UpdateGrid()
end

function CM.CreateEditBox(parent, width)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 20)
	box:SetAutoFocus(false)
	box:SetScript("OnEscapePressed", function() parent:Hide() end)

	return box
end

function CM.CreateIconButton(dialog, index)
	local size, step = CM.iconButtonSize, CM.iconStep
	local button = CreateFrame("Button", nil, dialog)
	button:SetSize(size, size)
	button:SetPoint("TOPLEFT", dialog.scroll, "TOPLEFT", ((index - 1) % CM.columns) * step, -math.floor((index - 1) / CM.columns) * step)
	CM.CreateRoundIcon(button)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	CM.AddMask(button:GetHighlightTexture(), button.outerMask)
	button.selected = button:CreateTexture(nil, "OVERLAY")
	button.selected:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	button.selected:SetBlendMode("ADD")
	button.selected:SetAllPoints(button)
	CM.AddMask(button.selected, button.outerMask)
	button:SetScript("OnClick", function(self) if self.path ~= nil then CM.SelectIcon(self.path) end end)

	return button
end

function CM.CreateDialog()
	local step = CM.iconStep
	local gridWidth, gridHeight = CM.columns * step - (step - CM.iconButtonSize), CM.rows * step - (step - CM.iconButtonSize)
	local width = gridWidth + 60
	local dialog = MapUtils:CreateUIWindowFrame("MapUtilsCustomMarkerDialog", UIParent)
	dialog:SetSize(width, gridHeight + 130)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")
	dialog:SetToplevel(true)
	dialog:EnableMouse(true)
	dialog:SetMovable(true)
	dialog:SetClampedToScreen(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	tinsert(UISpecialFrames, "MapUtilsCustomMarkerDialog")
	dialog.title = dialog.TitleText
	if dialog.title == nil then
		dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		dialog.title:SetPoint("TOP", 0, -5)
	end

	if dialog.CloseButton ~= nil then dialog.CloseButton:SetScript("OnClick", function() dialog:Hide() end) end
	dialog.preview = CreateFrame("Frame", nil, dialog)
	dialog.preview:SetSize(32, 32)
	dialog.preview:SetPoint("TOPLEFT", 16, -32)
	CM.CreateRoundIcon(dialog.preview)
	dialog.nameBox = CM.CreateEditBox(dialog, width - 76)
	dialog.nameBox:SetPoint("LEFT", dialog.preview, "RIGHT", 14, 0)
	dialog.nameBox:SetMaxLetters(60)
	dialog.nameBox:SetScript("OnEnterPressed", CM.Save)
	dialog.scroll = CreateFrame("ScrollFrame", "MapUtilsCustomMarkerIconScroll", dialog, "FauxScrollFrameTemplate")
	dialog.scroll:SetPoint("TOPLEFT", 16, -76)
	dialog.scroll:SetSize(gridWidth, gridHeight)
	dialog.scroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, step, CM.UpdateGrid) end)
	dialog.iconButtons = {}
	for index = 1, CM.columns * CM.rows do
		tinsert(dialog.iconButtons, CM.CreateIconButton(dialog, index))
	end

	local buttonWidth = math.floor((width - 40) / 3)
	dialog.saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	dialog.saveButton:SetSize(buttonWidth, 22)
	dialog.saveButton:SetPoint("BOTTOMLEFT", 16, 12)
	dialog.saveButton:SetText(SAVE or "Save")
	dialog.saveButton:SetScript("OnClick", CM.Save)
	dialog.deleteButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	dialog.deleteButton:SetSize(buttonWidth, 22)
	dialog.deleteButton:SetPoint("LEFT", dialog.saveButton, "RIGHT", 4, 0)
	dialog.deleteButton:SetText(DELETE or "Delete")
	dialog.deleteButton:SetScript("OnClick", CM.Delete)
	dialog.cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	dialog.cancelButton:SetSize(buttonWidth, 22)
	dialog.cancelButton:SetPoint("LEFT", dialog.deleteButton, "RIGHT", 4, 0)
	dialog.cancelButton:SetText(CANCEL or "Cancel")
	dialog.cancelButton:SetScript("OnClick", function() dialog:Hide() end)
	dialog:SetScript("OnHide", function(self)
		self.marker = nil
		self.pending = nil
	end)

	dialog:Hide()
	CM.dialog = dialog

	return dialog
end

function CM.OpenDialog(marker, pending)
	local dialog = CM.dialog or CM.CreateDialog()
	dialog.marker = marker
	dialog.pending = pending
	local source = marker or pending
	dialog.title:SetText(MapUtils:Trans(marker and "LID_CUSTOMMARKEREDIT" or "LID_CUSTOMMARKERNEW"))
	dialog.deleteButton:SetEnabled(marker ~= nil)
	dialog:Show()
	dialog:Raise()
	dialog.icon = source.icon or CM.defaultIcon
	dialog.preview.icon:SetTexture(CM.ResolveIcon(dialog.icon))
	CM.ScrollToIcon(dialog.icon)
	dialog.nameBox:SetText(source.name or "")
	dialog.nameBox:SetFocus()
	dialog.nameBox:HighlightText()
end

function CM.OnContainerMouseUp(container, button)
	if button ~= "MiddleButton" or container.GetNormalizedCursorPosition == nil then return end
	local mapID = WorldMapFrame:GetMapID()
	if not CM.IsShown(mapID) then return end
	local x, y = container:GetNormalizedCursorPosition()
	if x == nil or y == nil then return end
	local continent, wx, wy = CM.ToWorld(mapID, x, y)
	CM.OpenDialog(nil, {
		mapID = mapID,
		x = x,
		y = y,
		continent = continent,
		wx = wx,
		wy = wy,
		name = "",
		icon = CM.defaultIcon
	})
end

tinsert(MapUtils.CanvasPinLists, CM.pins)
tinsert(MapUtils.CanvasPinUpdaters, CM.UpdatePins)
if MapUtils.RegisterRenderLayer ~= nil then MapUtils:RegisterRenderLayer("Custom markers", function() return CM.pins end) end
if WorldMapFrame.ScrollContainer ~= nil then WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", MapUtils.Profile("custommarkers mouse up", CM.OnContainerMouseUp)) end
WorldMapFrame:HookScript("OnShow", function() if MapUtils.QueueCanvasPinsUpdate ~= nil then MapUtils:QueueCanvasPinsUpdate() end end)
