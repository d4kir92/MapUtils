local _, MapUtils = ...
local map = WorldMapFrame
if map == nil then return end
local EditMode = {
	elements = {},
	active = false,
	pad = 2,
	snap = 10,
	guideLevel = 2500,
	gridLevel = 900,
	gridSize = 5,
	gridMajor = 5,
	gridAlpha = 0.07,
	gridMajorAlpha = 0.18,
	scaleMin = 50,
	scaleMax = 200,
	scaleStep = 5,
	highlightKit = "editmode-actionbar-highlight",
	selectedKit = "editmode-actionbar-selected",
	fallbackColor = {0.25, 0.6, 1},
	selectedColor = {1, 0.82, 0},
	guideColor = {1, 0.15, 0.15, 0.9},
	settingNames = {"POINT", "X", "Y", "CX", "ALIGN", "SCALE", "ORIENT", "SHOWN"},
	hiddenColor = {1, 0.2, 0.2},
	aligns = {"AUTO", "LEFT", "CENTER", "RIGHT"},
	alignKeys = {
		["AUTO"] = "LID_ALIGNAUTO",
		["LEFT"] = "LID_ALIGNLEFT",
		["CENTER"] = "LID_ALIGNCENTER",
		["RIGHT"] = "LID_ALIGNRIGHT",
	},
	orients = {"VERTICAL", "HORIZONTAL"},
	orientKeys = {
		["VERTICAL"] = "LID_VERTICAL",
		["HORIZONTAL"] = "LID_HORIZONTAL",
	},
	layout = {
		["TopRightCorner"] = {
			atlas = "%s-NineSlice-Corner",
			mirrorLayout = true,
			x = 8,
			y = 8
		},
		["TopLeftCorner"] = {
			atlas = "%s-NineSlice-Corner",
			mirrorLayout = true,
			x = -8,
			y = 8
		},
		["BottomLeftCorner"] = {
			atlas = "%s-NineSlice-Corner",
			mirrorLayout = true,
			x = -8,
			y = -8
		},
		["BottomRightCorner"] = {
			atlas = "%s-NineSlice-Corner",
			mirrorLayout = true,
			x = 8,
			y = -8
		},
		["TopEdge"] = {
			atlas = "_%s-NineSlice-EdgeTop"
		},
		["BottomEdge"] = {
			atlas = "_%s-NineSlice-EdgeBottom"
		},
		["LeftEdge"] = {
			atlas = "!%s-NineSlice-EdgeLeft"
		},
		["RightEdge"] = {
			atlas = "!%s-NineSlice-EdgeRight"
		},
		["Center"] = {
			atlas = "%s-NineSlice-Center",
			x = -8,
			y = 8,
			x1 = 8,
			y1 = -8
		},
	},
}

function EditMode.Get(element, name, default)
	return MapUtils:GetConfig(element.key .. "_" .. name, default)
end

function EditMode.Set(element, name, value)
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, element.key .. "_" .. name, value)
end

function EditMode.Clamp(value, minValue, maxValue)
	return math.min(math.max(value, minValue), maxValue)
end

function EditMode.HasOption(element, option)
	local options = element.options or {
		align = true,
		scale = true
	}

	return options[option] == true
end

function EditMode.GetRatio(element)
	local scale = map.ScrollContainer:GetEffectiveScale()
	if scale == nil or scale == 0 then return 1 end

	return element.frame:GetEffectiveScale() / scale
end

function EditMode.GetAlign(element)
	local align = EditMode.Get(element, "ALIGN", "AUTO")
	if align ~= "AUTO" then return align end
	local cx = EditMode.Get(element, "CX", nil)
	if cx == nil then return element.defaultAlign or "LEFT" end
	if cx < 1 / 3 then return "LEFT" end
	if cx > 2 / 3 then return "RIGHT" end

	return "CENTER"
end

function EditMode.GetOrientation(element)
	return EditMode.Get(element, "ORIENT", element.defaultOrientation or "VERTICAL")
end

function EditMode.GetScale(element)
	return EditMode.Get(element, "SCALE", 100)
end

function EditMode.GetRect(element)
	local frame = element.frame
	local container = map.ScrollContainer
	local w, h = container:GetWidth(), container:GetHeight()
	local cl, cb = container:GetLeft(), container:GetBottom()
	if frame:GetLeft() == nil or cl == nil or cb == nil or w == nil or h == nil or w <= 0 or h <= 0 then return nil end
	local ratio = EditMode.GetRatio(element)

	return frame:GetLeft() * ratio - cl, frame:GetRight() * ratio - cl, frame:GetBottom() * ratio - cb, frame:GetTop() * ratio - cb, w, h
end

function EditMode.Save(element)
	local left, right, bottom, top, w, h = EditMode.GetRect(element)
	if left == nil then return end
	local shiftX = EditMode.Clamp(left, 0, math.max(w - (right - left), 0)) - left
	local shiftY = EditMode.Clamp(bottom, 0, math.max(h - (top - bottom), 0)) - bottom
	left, right, bottom, top = left + shiftX, right + shiftX, bottom + shiftY, top + shiftY
	local cy = EditMode.Clamp((bottom + top) / 2 / h, 0, 1)
	EditMode.Set(element, "CX", EditMode.Clamp((left + right) / 2 / w, 0, 1))
	local align = EditMode.GetAlign(element)
	local x = (left + right) / 2
	if align == "LEFT" then
		x = left
	elseif align == "RIGHT" then
		x = right
	end

	local vertical = cy < 0.5 and "BOTTOM" or "TOP"
	local y = vertical == "BOTTOM" and bottom or top
	EditMode.Set(element, "POINT", vertical .. (align == "CENTER" and "" or align))
	EditMode.Set(element, "X", EditMode.Clamp(x / w, 0, 1))
	EditMode.Set(element, "Y", EditMode.Clamp(y / h, 0, 1))
end

function EditMode.Apply(element)
	local frame = element.frame
	local container = map.ScrollContainer
	if frame == nil or container == nil then return end
	frame:SetScale(EditMode.GetScale(element) / 100)
	local ratio = EditMode.GetRatio(element)
	local point = EditMode.Get(element, "POINT", nil)
	frame:ClearAllPoints()
	if point == nil then
		local default = element.defaultPoint
		frame:SetPoint(default[1], container, default[1], default[2] / ratio, default[3] / ratio)
	else
		local w, h = container:GetWidth(), container:GetHeight()
		frame:SetPoint(point, container, "BOTTOMLEFT", EditMode.Get(element, "X", 0) * w / ratio, EditMode.Get(element, "Y", 0) * h / ratio)
	end

	if element.OnLayout ~= nil then element.OnLayout() end
end

function EditMode.ApplyAll()
	for _, element in ipairs(EditMode.elements) do
		EditMode.Apply(element)
	end
end

function EditMode.Reset(element)
	MAUTTAB = MAUTTAB or {}
	for _, name in ipairs(EditMode.settingNames) do
		MAUTTAB[element.key .. "_" .. name] = nil
	end

	EditMode.Apply(element)
end

function EditMode.HasNineSlice()
	if EditMode.nineSlice == nil then EditMode.nineSlice = NineSliceUtil ~= nil and NineSliceUtil.ApplyLayout ~= nil and MapUtils.AtlasExists ~= nil and MapUtils:AtlasExists(EditMode.highlightKit .. "-NineSlice-Center") == true end

	return EditMode.nineSlice
end

function EditMode.IsShown(element)
	return EditMode.Get(element, "SHOWN", true) ~= false
end

function EditMode.TintPieces(mover, hidden)
	for name in pairs(EditMode.layout) do
		local piece = mover[name]
		if piece ~= nil then
			piece:SetDesaturated(hidden)
			if hidden then
				piece:SetVertexColor(EditMode.hiddenColor[1], EditMode.hiddenColor[2], EditMode.hiddenColor[3])
			else
				piece:SetVertexColor(1, 1, 1)
			end
		end
	end
end

function EditMode.Skin(mover, selected)
	if selected == nil then selected = mover.selected == true end
	local hidden = mover.element ~= nil and not EditMode.IsShown(mover.element)
	local state = format("%s:%s", tostring(selected), tostring(hidden))
	if mover.skinState == state then return end
	mover.skinState = state
	mover.selected = selected
	if EditMode.HasNineSlice() then
		NineSliceUtil.ApplyLayout(mover, EditMode.layout, selected and EditMode.selectedKit or EditMode.highlightKit)
		EditMode.TintPieces(mover, hidden)

		return
	end

	if mover.SetBackdrop == nil then return end
	local color = selected and EditMode.selectedColor or EditMode.fallbackColor
	if hidden then color = EditMode.hiddenColor end
	mover:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = {
			left = 3,
			right = 3,
			top = 3,
			bottom = 3
		}
	})

	mover:SetBackdropColor(color[1], color[2], color[3], 0.25)
	mover:SetBackdropBorderColor(color[1], color[2], color[3], 1)
end

function EditMode.CreateGuides()
	if EditMode.guides ~= nil then return EditMode.guides end
	local container = map.ScrollContainer
	local guides = CreateFrame("Frame", nil, map)
	guides:SetAllPoints(container)
	guides:SetFrameLevel(container:GetFrameLevel() + EditMode.guideLevel)
	guides:EnableMouse(false)
	local color = EditMode.guideColor
	guides.vertical = guides:CreateTexture(nil, "OVERLAY")
	guides.vertical:SetColorTexture(color[1], color[2], color[3], color[4])
	guides.vertical:SetWidth(2)
	guides.vertical:SetPoint("TOP", guides, "TOP", 0, 0)
	guides.vertical:SetPoint("BOTTOM", guides, "BOTTOM", 0, 0)
	guides.horizontal = guides:CreateTexture(nil, "OVERLAY")
	guides.horizontal:SetColorTexture(color[1], color[2], color[3], color[4])
	guides.horizontal:SetHeight(2)
	guides.horizontal:SetPoint("LEFT", guides, "LEFT", 0, 0)
	guides.horizontal:SetPoint("RIGHT", guides, "RIGHT", 0, 0)
	guides:SetScript("OnUpdate", EditMode.UpdateDrag)

	guides:Hide()
	EditMode.guides = guides

	return guides
end

function EditMode.GetCursor()
	local container = map.ScrollContainer
	local x, y = GetCursorPosition()
	local scale = container:GetEffectiveScale()

	return x / scale - container:GetLeft(), y / scale - container:GetBottom()
end

function EditMode.IsGrid()
	return MapUtils:GetConfig("EDITMODEGRID", false) == true
end

function EditMode.SnapGrid(value, length)
	if not EditMode.IsGrid() then return value end
	local center = length / 2

	return center + math.floor((value - center) / EditMode.gridSize + 0.5) * EditMode.gridSize
end

function EditMode.AddGridLine(grid, index, horizontal, offset, major)
	local line = grid.lines[index]
	if line == nil then
		line = grid:CreateTexture(nil, "BACKGROUND")
		grid.lines[index] = line
	end

	local alpha = major and EditMode.gridMajorAlpha or EditMode.gridAlpha
	line:SetColorTexture(1, 1, 1, alpha)
	line:ClearAllPoints()
	if horizontal then
		line:SetHeight(1)
		line:SetPoint("LEFT", grid, "LEFT", 0, offset)
		line:SetPoint("RIGHT", grid, "RIGHT", 0, offset)
	else
		line:SetWidth(1)
		line:SetPoint("TOP", grid, "TOP", offset, 0)
		line:SetPoint("BOTTOM", grid, "BOTTOM", offset, 0)
	end

	line:Show()
end

function EditMode.BuildGrid(grid)
	local w, h = grid:GetWidth(), grid:GetHeight()
	if w == nil or h == nil or w <= 0 or h <= 0 then return end
	local size = EditMode.gridSize
	local index = 0
	for _, axis in ipairs({{false, w}, {true, h}}) do
		local steps = math.floor(axis[2] / 2 / size)
		for step = -steps, steps do
			index = index + 1
			EditMode.AddGridLine(grid, index, axis[1], step * size, step % EditMode.gridMajor == 0)
		end
	end

	for i = index + 1, #grid.lines do
		grid.lines[i]:Hide()
	end
end

function EditMode.UpdateGrid()
	local show = EditMode.active and EditMode.IsGrid()
	if not show and EditMode.grid == nil then return end
	if EditMode.grid == nil then
		local container = map.ScrollContainer
		local grid = CreateFrame("Frame", nil, map)
		grid:SetAllPoints(container)
		grid:SetFrameLevel(container:GetFrameLevel() + EditMode.gridLevel)
		grid:EnableMouse(false)
		grid.lines = {}
		grid:SetScript("OnSizeChanged", EditMode.BuildGrid)
		EditMode.grid = grid
	end

	EditMode.grid:SetShown(show)
	if show then EditMode.BuildGrid(EditMode.grid) end
end

function EditMode.UpdateDrag(guides)
	local drag = guides.drag
	if drag == nil then return end
	local container = map.ScrollContainer
	local w, h = container:GetWidth(), container:GetHeight()
	local x, y = EditMode.GetCursor()
	local left = EditMode.SnapGrid(x + drag.offsetX, w)
	local bottom = EditMode.SnapGrid(y + drag.offsetY, h)
	left = EditMode.Clamp(left, 0, math.max(w - drag.width, 0))
	bottom = EditMode.Clamp(bottom, 0, math.max(h - drag.height, 0))
	local snapX = math.abs(left + drag.width / 2 - w / 2) <= EditMode.snap
	local snapY = math.abs(bottom + drag.height / 2 - h / 2) <= EditMode.snap
	if snapX then left = w / 2 - drag.width / 2 end
	if snapY then bottom = h / 2 - drag.height / 2 end
	guides.vertical:SetShown(snapX)
	guides.horizontal:SetShown(snapY)
	local frame = drag.element.frame
	local ratio = EditMode.GetRatio(drag.element)
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", left / ratio, bottom / ratio)
end

function EditMode.StartDrag(element)
	local left, right, bottom, top = EditMode.GetRect(element)
	if left == nil then return end
	local x, y = EditMode.GetCursor()
	local guides = EditMode.CreateGuides()
	guides.drag = {
		element = element,
		offsetX = left - x,
		offsetY = bottom - y,
		width = right - left,
		height = top - bottom
	}

	guides.vertical:Hide()
	guides.horizontal:Hide()
	guides:Show()
end

function EditMode.StopDrag(element)
	local guides = EditMode.guides
	if guides == nil or guides.drag == nil then return end
	EditMode.UpdateDrag(guides)
	guides.drag = nil
	guides:Hide()
	EditMode.Save(element)
	EditMode.Apply(element)
	if EditMode.panel ~= nil and EditMode.panel:IsShown() and EditMode.panel.element == element then EditMode.ShowPanel(element) end
end

function EditMode.CreateMover(element)
	local frame = element.frame
	local pad = EditMode.pad
	local template = nil
	if not EditMode.HasNineSlice() and BackdropTemplateMixin ~= nil then template = "BackdropTemplate" end
	local mover = CreateFrame("Button", nil, frame, template)
	mover:SetPoint("TOPLEFT", frame, "TOPLEFT", -pad, pad)
	mover:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", pad, -pad)
	mover:SetFrameLevel(frame:GetFrameLevel() + 20)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("RightButtonUp")
	mover:SetScript("OnDragStart", function() EditMode.StartDrag(element) end)
	mover:SetScript("OnDragStop", function() EditMode.StopDrag(element) end)
	mover:SetScript("OnClick", function(_, button) if button == "RightButton" then EditMode.ShowPanel(element) end end)
	mover.element = element
	EditMode.Skin(mover, false)
	mover:Hide()
	element.mover = mover
end

function EditMode.CreateSlider(panel, parent)
	local template = "OptionsSliderTemplate"
	if DoesTemplateExist ~= nil and DoesTemplateExist("MinimalSliderTemplate") then
		template = "MinimalSliderTemplate"
	elseif DoesTemplateExist ~= nil and DoesTemplateExist("UISliderTemplate") then
		template = "UISliderTemplate"
	end

	local slider = CreateFrame("Slider", nil, parent, template)
	slider:SetOrientation("HORIZONTAL")
	slider:SetSize(226, 16)
	slider:SetMinMaxValues(EditMode.scaleMin, EditMode.scaleMax)
	slider:SetValueStep(EditMode.scaleStep)
	if slider.SetObeyStepOnDrag ~= nil then slider:SetObeyStepOnDrag(true) end
	slider:SetScript("OnValueChanged", function(_, value)
		if panel.updating or panel.element == nil then return end
		value = math.floor(value / EditMode.scaleStep + 0.5) * EditMode.scaleStep
		EditMode.Set(panel.element, "SCALE", value)
		EditMode.Apply(panel.element)
		EditMode.Save(panel.element)
		EditMode.Apply(panel.element)
		EditMode.RefreshPanel()
	end)

	return slider
end

function EditMode.CreateChoiceRow(panel, labelKey, onClick)
	local row = CreateFrame("Frame", nil, panel)
	row:SetSize(226, 24)
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
	row.label:SetText(MapUtils:Trans(labelKey))
	row.button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.button:SetSize(110, 22)
	row.button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	row.button:SetScript("OnClick", onClick)

	return row
end

function EditMode.CreatePanel()
	if EditMode.panel ~= nil then return EditMode.panel end
	local panel = CreateFrame("Frame", nil, map, BackdropTemplateMixin and "BackdropTemplate" or nil)
	panel:SetSize(250, 150)
	panel:SetFrameStrata("DIALOG")
	panel:SetClampedToScreen(true)
	panel:EnableMouse(true)
	if panel.SetBackdrop ~= nil then
		panel:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 14,
			insets = {
				left = 3,
				right = 3,
				top = 3,
				bottom = 3
			}
		})

		panel:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
		panel:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	end

	panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() panel:Hide() end)
	panel.shownRow = CreateFrame("Frame", nil, panel)
	panel.shownRow:SetSize(226, 24)
	panel.shownCheck = CreateFrame("CheckButton", nil, panel.shownRow, "UICheckButtonTemplate")
	panel.shownCheck:SetSize(24, 24)
	panel.shownCheck:SetPoint("LEFT", panel.shownRow, "LEFT", -4, 0)
	panel.shownLabel = panel.shownRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	panel.shownLabel:SetPoint("LEFT", panel.shownCheck, "RIGHT", 2, 0)
	panel.shownLabel:SetText(MapUtils:Trans("LID_SHOWWIDGET"))
	panel.shownCheck:SetScript("OnClick", function(self)
		local element = panel.element
		if element == nil then return end
		EditMode.Set(element, "SHOWN", self:GetChecked() == true)
		EditMode.Apply(element)
		EditMode.Skin(element.mover)
	end)

	panel.alignRow = EditMode.CreateChoiceRow(panel, "LID_TEXTALIGN", function(self) EditMode.ShowChoiceMenu(self, "ALIGN", EditMode.aligns, EditMode.alignKeys, "AUTO") end)
	panel.orientRow = EditMode.CreateChoiceRow(panel, "LID_ORIENTATION", function(self) EditMode.ShowChoiceMenu(self, "ORIENT", EditMode.orients, EditMode.orientKeys, panel.element.defaultOrientation or "VERTICAL") end)
	panel.scaleRow = CreateFrame("Frame", nil, panel)
	panel.scaleRow:SetSize(226, 40)
	panel.scaleLabel = panel.scaleRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	panel.scaleLabel:SetPoint("TOPLEFT", panel.scaleRow, "TOPLEFT", 0, 0)
	panel.slider = EditMode.CreateSlider(panel, panel.scaleRow)
	panel.slider:SetPoint("TOPLEFT", panel.scaleRow, "TOPLEFT", 0, -18)
	panel.reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	panel.reset:SetSize(226, 22)
	panel.reset:SetText(MapUtils:Trans("LID_RESET"))
	panel.reset:SetScript("OnClick", function()
		if panel.element == nil then return end
		EditMode.Reset(panel.element)
		EditMode.ShowPanel(panel.element)
	end)

	panel:SetScript("OnHide", function(self)
		if self.element ~= nil and self.element.mover ~= nil then EditMode.Skin(self.element.mover, false) end
		self.element = nil
	end)

	panel:Hide()
	EditMode.panel = panel

	return panel
end

function EditMode.LayoutPanel(panel, element)
	local y = -36
	local rows = {
		{panel.shownRow, true, 28},
		{panel.alignRow, EditMode.HasOption(element, "align"), 28},
		{panel.orientRow, EditMode.HasOption(element, "orientation"), 28},
		{panel.scaleRow, EditMode.HasOption(element, "scale"), 44},
		{panel.reset, true, 30},
	}

	for _, row in ipairs(rows) do
		row[1]:ClearAllPoints()
		row[1]:SetShown(row[2])
		if row[2] then
			row[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
			y = y - row[3]
		end
	end

	panel:SetHeight(-y + 6)
end

function EditMode.RefreshPanel()
	local panel = EditMode.panel
	local element = panel and panel.element
	if element == nil then return end
	panel.title:SetText(MapUtils:Trans(element.title))
	panel.shownCheck:SetChecked(EditMode.IsShown(element))
	panel.alignRow.button:SetText(MapUtils:Trans(EditMode.alignKeys[EditMode.Get(element, "ALIGN", "AUTO")] or "LID_ALIGNAUTO"))
	panel.orientRow.button:SetText(MapUtils:Trans(EditMode.orientKeys[EditMode.GetOrientation(element)] or "LID_VERTICAL"))
	local scale = EditMode.GetScale(element)
	panel.scaleLabel:SetText(MapUtils:Trans("LID_WIDGETSCALE", nil, scale))
	panel.updating = true
	panel.slider:SetValue(scale)
	panel.updating = false
end

function EditMode.ShowPanel(element)
	local panel = EditMode.CreatePanel()
	if panel.element ~= nil and panel.element ~= element and panel.element.mover ~= nil then EditMode.Skin(panel.element.mover, false) end
	panel.element = element
	EditMode.Skin(element.mover, true)
	EditMode.LayoutPanel(panel, element)
	EditMode.RefreshPanel()
	local point = EditMode.Get(element, "POINT", nil) or element.defaultPoint[1]
	panel:ClearAllPoints()
	if point:sub(1, 3) == "TOP" or point == "LEFT" or point == "RIGHT" then
		panel:SetPoint("TOPLEFT", element.mover, "BOTTOMLEFT", 0, -10)
	else
		panel:SetPoint("BOTTOMLEFT", element.mover, "TOPLEFT", 0, 10)
	end

	panel:Show()
end

function EditMode.ShowChoiceMenu(owner, name, values, keys, default)
	local element = EditMode.panel and EditMode.panel.element
	if element == nil then return end
	local entries = {}
	for _, value in ipairs(values) do
		tinsert(entries, {
			["text"] = MapUtils:Trans(keys[value]),
			["radio"] = true,
			["checked"] = function() return EditMode.Get(element, name, default) == value end,
			["func"] = function()
				EditMode.Set(element, name, value)
				if name == "ALIGN" then EditMode.Save(element) end
				EditMode.Apply(element)
				EditMode.RefreshPanel()
			end,
		})
	end

	MapUtils:ShowEntryMenu(owner, entries)
end

function MapUtils:IsMapEditMode()
	return EditMode.active
end

function MapUtils:SetMapEditMode(active)
	EditMode.active = active == true
	for _, element in ipairs(EditMode.elements) do
		element.mover:SetShown(EditMode.active)
		if element.OnEditMode ~= nil then element.OnEditMode(EditMode.active) end
	end

	if not EditMode.active and EditMode.panel ~= nil then EditMode.panel:Hide() end
	EditMode.UpdateGrid()
end

function MapUtils:IsMapEditGrid()
	return EditMode.IsGrid()
end

function MapUtils:SetMapEditGrid(enabled)
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, "EDITMODEGRID", enabled == true)
	EditMode.UpdateGrid()
end

function MapUtils:GetMapEditAlign(element)
	return EditMode.GetAlign(element)
end

function MapUtils:GetMapEditOrientation(element)
	return EditMode.GetOrientation(element)
end

function MapUtils:IsMapEditElementVisible(element)
	return EditMode.active or EditMode.IsShown(element)
end

function MapUtils:RegisterMapEditElement(element)
	tinsert(EditMode.elements, element)
	EditMode.CreateMover(element)
	element.mover:SetShown(EditMode.active)
	EditMode.Apply(element)
end

map:HookScript("OnShow", EditMode.ApplyAll)
map:HookScript("OnHide", function() if EditMode.active then MapUtils:SetMapEditMode(false) end end)
if map.ScrollContainer ~= nil then map.ScrollContainer:HookScript("OnSizeChanged", EditMode.ApplyAll) end
MapUtils.ProfileTable("EditMode", EditMode)
