local _, MapUtils = ...
local MIN_SCALE = 0.5
local MAX_SCALE = 2
local SCALE_EPSILON = 0.001
local GRIP_SIZE = 26
local MAP_SIZE = {
	["minWidth"] = 500,
	["minHeight"] = 300,
	["custom"] = false,
	["buttonInner"] = 0.6,
	["footerInset"] = 2,
	["borderLift"] = 500,
	["rimShare"] = 0.65,
	["leftRimShare"] = 0.4,
	["detailsInset"] = 0
}
local frame = WorldMapFrame
local ready = false
local foreign = false
local foreignMove = false
local applying = false
local dragging = false
local originalClampTop
local sizing = nil
local lastScale = 1
local blizzardPoint = nil
local grip = nil
local scrollBarsShifted = false
local fader = nil
local fullscreenWasMaximized
local dragRegions = {"BorderFrame", "TitleCanvasSpacerFrame", "MiniBorderFrame"}
function MapUtils:GetCursorUi()
	local x, y = GetCursorPosition()
	local s = UIParent:GetEffectiveScale()

	return x / s, y / s
end
local function IsEnabled(key)
	return type(MAUTTAB) ~= "table" or MAUTTAB[key] ~= false
end

local function MoveEnabled()
	return not foreignMove and not MapUtils:IsWorldMapByOneForAll() and IsEnabled("WORLDMAPMOVE")
end

local function ScaleEnabled()
	return not MapUtils:IsWorldMapByOneForAll() and IsEnabled("WORLDMAPSCALE")
end

local function IsMaximized()
	return frame.IsMaximized ~= nil and frame:IsMaximized() == true
end

local function IsLocked()
	return InCombatLockdown() and frame:IsProtected()
end

local function CheckForeign()
	if foreign then return true end
	if not dragging and frame:IsMovable() then
		foreignMove = true
	end

	if math.abs(frame:GetScale() - lastScale) > SCALE_EPSILON then
		foreign = true
	end

	if foreign and grip ~= nil then grip:Hide() end

	return foreign
end

local function ToUi()
	return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

local function GetPos()
	local left = frame:GetLeft()
	local top = frame:GetTop()
	if left == nil or top == nil then return nil end
	local k = ToUi()

	return left * k, top * k
end

local function SetPos(left, top)
	local k = ToUi()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / k, top / k)
end

local function GetUnitSize()
	local k = ToUi() / frame:GetScale()

	return frame:GetWidth() * k, frame:GetHeight() * k
end

local function GetMaxScale()
	local w, h = GetUnitSize()
	if w <= 0 or h <= 0 then return MAX_SCALE end

	return min(MAX_SCALE, UIParent:GetWidth() / w, UIParent:GetHeight() / h)
end

local function ClampScale(value, maxScale)
	maxScale = maxScale or GetMaxScale()

	return max(min(MIN_SCALE, maxScale), min(value or 1, maxScale))
end

local function UpdateTopClamp()
	local gap = 0
	if not MapUtils:IsWorldMapFullscreen() and MoveEnabled() and MapUtils.GetSimpleMapTopGap then
		gap = MapUtils:GetSimpleMapTopGap()
	end
	if gap > 0 then
		local left, right, top, bottom = frame:GetClampRectInsets()
		if originalClampTop == nil then originalClampTop = top end
		if top ~= -gap then frame:SetClampRectInsets(left, right, -gap, bottom) end
	elseif originalClampTop ~= nil then
		local left, right, _, bottom = frame:GetClampRectInsets()
		frame:SetClampRectInsets(left, right, originalClampTop, bottom)
		originalClampTop = nil
	end

	return gap * ToUi()
end

local function ClampPos(left, top, topGap)
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	w = w * s
	h = h * s
	left = max(0, min(left, UIParent:GetWidth() - w))
	top = min(UIParent:GetHeight() + (topGap or 0), max(top, h))

	return left, top
end

local function SetScale(value)
	lastScale = value
	if math.abs(frame:GetScale() - value) > SCALE_EPSILON then frame:SetScale(value) end
end

function MAP_SIZE.ClassicUI()
	return ClassicUIForeverAPI ~= nil and ClassicUIForeverAPI.IsOn ~= nil and ClassicUIForeverAPI.IsOn("worldMap") == true
end

function MAP_SIZE.CanResize()
	return not MAP_SIZE.ClassicUI() and frame.minimizedWidth ~= nil and frame.minimizedHeight ~= nil and not IsMaximized()
end

function MAP_SIZE.QuestExtra()
	if frame.QuestLog ~= nil and frame.QuestLog:IsShown() and frame.questLogWidth ~= nil then return frame.questLogWidth end

	return 0
end

function MAP_SIZE.Get()
	local size = MAUTTAB["WORLDMAPSIZE"]
	if not ScaleEnabled() or not MAP_SIZE.CanResize() or type(size) ~= "table" or size.w == nil or size.h == nil then return nil end

	return size.w, size.h
end

function MAP_SIZE.Clamp(w, h, left, top)
	local k = ToUi()
	local maxW = (UIParent:GetWidth() - (left or 0)) / k - MAP_SIZE.QuestExtra()
	local maxH = (top or UIParent:GetHeight()) / k

	return max(MAP_SIZE.minWidth, min(w, maxW)), max(MAP_SIZE.minHeight, min(h, maxH))
end

function MAP_SIZE.Set(w, h)
	local width = w + MAP_SIZE.QuestExtra()
	if math.abs(frame:GetWidth() - width) <= SCALE_EPSILON and math.abs(frame:GetHeight() - h) <= SCALE_EPSILON then return false end
	frame:SetSize(width, h)
	MAP_SIZE.LayoutBorder()
	MAP_SIZE.SyncCanvas()

	return true
end

function MAP_SIZE.BorderParts()
	if MAP_SIZE.borderParts ~= nil then return MAP_SIZE.borderParts end
	local parts = {}
	for _, region in ipairs({frame.BorderFrame:GetRegions()}) do
		if region:GetObjectType() == "Texture" then tinsert(parts, region) end
	end
	if MiniBorderLeft ~= nil then tinsert(parts, MiniBorderLeft) end
	if MiniBorderRight ~= nil then tinsert(parts, MiniBorderRight) end
	MAP_SIZE.borderParts = parts

	return parts
end

function MAP_SIZE.CreateBorder()
	if MAP_SIZE.border ~= nil then return MAP_SIZE.border end
	local border = CreateFrame("Frame", nil, frame)
	border:SetAllPoints(frame)
	border.back = CreateFrame("Frame", nil, border)
	border.back:SetAllPoints(frame.ScrollContainer or frame)
	border.bg = border.back:CreateTexture(nil, "BACKGROUND")
	border.bg:SetAllPoints(border.back)
	border.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
	if frame.ScrollContainer ~= nil then
		border.headerBg = border.back:CreateTexture(nil, "BACKGROUND")
		border.headerBg:SetPoint("BOTTOMLEFT", frame.ScrollContainer, "TOPLEFT", 0, 0)
		border.headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
		border.headerBg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
	end
	if border.headerBg ~= nil and C_Texture.GetAtlasInfo("_UI-Frame-TitleTileBg") ~= nil then
		border.titleBg = border.back:CreateTexture(nil, "BACKGROUND", nil, 1)
		border.titleBg:SetAtlas("_UI-Frame-TitleTileBg", true)
		border.titleBg:SetPoint("TOPLEFT", border.headerBg, "TOPLEFT", 0, -1)
		border.titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -3)
	end
	NineSliceUtil.ApplyLayoutByName(border, "ButtonFrameTemplateNoPortrait")
	MAP_SIZE.border = border

	return border
end

function MAP_SIZE.LevelBorder(border)
	local containerLevel = frame.ScrollContainer and frame.ScrollContainer:GetFrameLevel() or frame:GetFrameLevel()
	local strata = frame:GetFrameStrata()
	border:SetFrameStrata(strata)
	border:SetFrameLevel(containerLevel + MAP_SIZE.borderLift)
	border.back:SetFrameStrata(strata)
	border.back:SetFrameLevel(max(0, min(frame:GetFrameLevel(), containerLevel - 1)))
end

function MAP_SIZE.ResolveLayout()
	local close = WorldMapFrameCloseButton
	if close == nil or not frame:IsShown() or IsLocked() or applying or dragging or sizing ~= nil then return end
	local left, top = GetPos()
	if left == nil then return end
	applying = true
	SetPos(left + 1, top)
	applying = false
	C_Timer.After(0.5, function()
		if dragging or sizing ~= nil or IsLocked() then return end
		applying = true
		SetPos(left, top)
		applying = false
	end)
end

function MAP_SIZE.RaiseButtons(custom)
	local border = MAP_SIZE.border
	local cover = custom and border or frame.BorderFrame
	if cover == nil then return end
	local level = cover:GetFrameLevel() + 2
	local arrow = frame.MaximizeMinimizeFrame
	local buttons = {WorldMapFrameCloseButton, arrow}
	if arrow ~= nil then
		tinsert(buttons, arrow.MaximizeButton)
		tinsert(buttons, arrow.MinimizeButton)
		tinsert(buttons, arrow.MapUtilsFullscreenButton)
	end
	for _, button in pairs(buttons) do
		if button ~= nil and button:GetFrameLevel() < level and not (InCombatLockdown() and button:IsProtected()) then button:SetFrameLevel(level) end
	end
	if MapUtils.LayoutMapMenuButton ~= nil then MapUtils:LayoutMapMenuButton() end
end

function MAP_SIZE.LayoutBorder()
	if frame.MiniBorderFrame == nil or frame.BorderFrame == nil or NineSliceUtil == nil or NineSliceUtil.GetLayout == nil or NineSliceUtil.GetLayout("ButtonFrameTemplateNoPortrait") == nil then return end
	local custom = MAP_SIZE.CanResize() or MapUtils:IsWorldMapFullscreen()
	if not custom and MAP_SIZE.border == nil then return end
	for _, region in ipairs(MAP_SIZE.BorderParts()) do
		region:SetAlpha(custom and 0 or 1)
	end
	local border = MAP_SIZE.CreateBorder()
	border:SetShown(custom)
	if custom then MAP_SIZE.LevelBorder(border) end
	MAP_SIZE.LayoutCloseButton(custom)
	MAP_SIZE.LayoutFooter(custom)
	MAP_SIZE.RaiseButtons(custom)
	if grip ~= nil then
		grip:ClearAllPoints()
		if custom then
			grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 4)
		else
			grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
		end
	end
end

function MAP_SIZE.LayoutFooter(custom)
	local container = frame.ScrollContainer
	if container == nil or (InCombatLockdown() and container:IsProtected()) then return end
	MAP_SIZE.footerPoints = MAP_SIZE.footerPoints or {}
	local inset = MAP_SIZE.footerInset
	local border = MAP_SIZE.border
	local left = border and border.LeftEdge and border.LeftEdge:GetWidth() * MAP_SIZE.leftRimShare or inset
	local bottom = border and border.BottomEdge and border.BottomEdge:GetHeight() * MAP_SIZE.rimShare or inset
	local targets = {
		["TOPLEFT"] = function(_, y) return max(inset, left), y end,
		["BOTTOMRIGHT"] = function() return -inset, max(inset, bottom) end
	}
	local changed = false
	for i = 1, container:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = container:GetPoint(i)
		local target = targets[point]
		if target ~= nil then
			local saved = MAP_SIZE.footerPoints[point]
			if custom then
				local tx, ty = target(x, saved and saved[5] or y)
				if saved == nil or x ~= tx or y ~= ty then MAP_SIZE.footerPoints[point] = {point, relativeTo, relativePoint, x, y} end
				if x ~= tx or y ~= ty then
					container:SetPoint(point, relativeTo, relativePoint, tx, ty)
					changed = true
				end
			elseif saved ~= nil then
				local tx, ty = target(x, saved[5])
				if x == tx and y == ty then
					container:SetPoint(unpack(saved))
					changed = true
				end
				MAP_SIZE.footerPoints[point] = nil
			end
		end
	end
	if changed then MAP_SIZE.SyncCanvas() end
end

function MAP_SIZE.LayoutCloseButton(custom)
	local close = WorldMapFrameCloseButton
	if close == nil or (InCombatLockdown() and close:IsProtected()) then return end
	if custom then
		if MAP_SIZE.closePoint == nil then
			local point, relativeTo, relativePoint, x, y = close:GetPoint(1)
			if point == nil then return end
			MAP_SIZE.closePoint = {point, relativeTo, relativePoint, x, y}
		end
		close:ClearAllPoints()
		close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 5)
	elseif MAP_SIZE.closePoint ~= nil then
		local point, relativeTo, _, x, y = close:GetPoint(1)
		if point == "TOPRIGHT" and relativeTo == frame and x == 4 and y == 5 then
			close:ClearAllPoints()
			close:SetPoint(unpack(MAP_SIZE.closePoint))
		end
		MAP_SIZE.closePoint = nil
	end
end

function MAP_SIZE.SyncCanvas()
	if frame.OnFrameSizeChanged == nil then return end
	MAP_SIZE.canvasPending = true
	if not frame:IsVisible() then return end
	local container = frame.ScrollContainer
	if container ~= nil then
		local w, h = container:GetSize()
		if w == nil or h == nil or w <= 0 or h <= 0 then return end
	end

	MAP_SIZE.canvasPending = false
	frame:OnFrameSizeChanged()
end

function MAP_SIZE.AnchoredSize(container)
	local left, top, right, bottom
	for i = 1, container:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = container:GetPoint(i)
		if relativeTo == frame and point == relativePoint then
			if point == "TOPLEFT" then left, top = x, y end
			if point == "BOTTOMRIGHT" then right, bottom = x, y end
		end
	end
	if left == nil or right == nil then return 0, 0 end

	return frame:GetWidth() - left + right, frame:GetHeight() + top - bottom
end

function MAP_SIZE.InstallSizeFallback()
	local container = frame.ScrollContainer
	if container == nil or frame.MiniBorderFrame == nil or MAP_SIZE.nativeWidth ~= nil then return end
	MAP_SIZE.nativeWidth, MAP_SIZE.nativeHeight = container.GetWidth, container.GetHeight
	container.GetWidth = function(self)
		local width = MAP_SIZE.nativeWidth(self)
		if width > 0 then return width end
		local anchored = MAP_SIZE.AnchoredSize(self)

		return max(0, anchored)
	end

	container.GetHeight = function(self)
		local height = MAP_SIZE.nativeHeight(self)
		if height > 0 then return height end
		local _, anchored = MAP_SIZE.AnchoredSize(self)

		return max(0, anchored)
	end
end

function MAP_SIZE.CheckCanvas()
	local container = frame.ScrollContainer
	local base = container and container.baseScale
	if base ~= nil and not (base > 0 and base < math.huge) then MAP_SIZE.canvasPending = true end
	if MAP_SIZE.canvasPending then MAP_SIZE.SyncCanvas() end
end

function MAP_SIZE.Apply()
	if not MAP_SIZE.CanResize() then return end
	local w, h = MAP_SIZE.Get()
	if w ~= nil then
		MAP_SIZE.custom = true
		MAP_SIZE.Set(MAP_SIZE.Clamp(w, h))
	elseif MAP_SIZE.custom then
		MAP_SIZE.custom = false
		MAP_SIZE.Set(frame.minimizedWidth, frame.minimizedHeight)
		MAP_SIZE.LayoutBorder()
	end

	MapUtils:LayoutQuestDetails()
end

function MapUtils:LayoutQuestDetails(inset)
	if inset ~= nil then MAP_SIZE.detailsInset = inset end
	local details = QuestMapFrame and QuestMapFrame.DetailsFrame
	if details == nil or details.ScrollFrame == nil or MAP_SIZE.ClassicUI() then return end
	if InCombatLockdown() and (details:IsProtected() or details.ScrollFrame:IsProtected()) then return end
	if MAP_SIZE.detailsHeight == nil then MAP_SIZE.detailsHeight, MAP_SIZE.detailsScrollHeight = details:GetHeight(), details.ScrollFrame:GetHeight() end
	local delta = -MAP_SIZE.detailsInset
	if MAP_SIZE.custom and MAP_SIZE.CanResize() then delta = delta + frame:GetHeight() - frame.minimizedHeight end
	details:SetHeight(max(1, MAP_SIZE.detailsHeight + delta))
	details.ScrollFrame:SetHeight(max(1, MAP_SIZE.detailsScrollHeight + delta))
end

local function NormalizePoint(point, relativeTo, relativePoint, x, y)
	if type(relativeTo) == "number" then return point, frame:GetParent(), point, relativeTo, relativePoint or 0 end

	return point, relativeTo or frame:GetParent(), relativePoint or point, x or 0, y or 0
end

local function GetScrollBars()
	local bars = {}
	local frames = {QuestScrollFrame, QuestMapDetailsScrollFrame}
	if QuestMapFrame ~= nil and QuestMapFrame.MapLegend ~= nil then tinsert(frames, QuestMapFrame.MapLegend.ScrollFrame) end
	for _, scrollFrame in ipairs(frames) do
		if scrollFrame ~= nil and scrollFrame.ScrollBar ~= nil then tinsert(bars, scrollFrame.ScrollBar) end
	end

	return bars
end

local function ShiftScrollBars(shifted)
	if shifted == scrollBarsShifted then return end
	if IsLocked() then return end
	scrollBarsShifted = shifted
	local offset = shifted and GRIP_SIZE or -GRIP_SIZE
	for _, bar in ipairs(GetScrollBars()) do
		for i = 1, bar:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = bar:GetPoint(i)
			if point ~= nil and string.find(point, "BOTTOM", 1, true) then
				bar:SetPoint(point, relativeTo, relativePoint, x, y + offset)
			end
		end
	end
end

function MAP_SIZE.LayoutToggle(gripShown)
	local toggle = frame.SidePanelToggle
	if toggle == nil or (InCombatLockdown() and toggle:IsProtected()) then return end
	local raise = gripShown and frame.QuestLog ~= nil and not frame.QuestLog:IsShown()
	if raise == (MAP_SIZE.togglePoint ~= nil) then return end
	if raise then
		local point, relativeTo, relativePoint, x, y = toggle:GetPoint(1)
		if point == nil then return end
		MAP_SIZE.togglePoint = {point, relativeTo, relativePoint, x, y}
		toggle:ClearAllPoints()
		toggle:SetPoint(point, relativeTo, relativePoint, x, (y or 0) + GRIP_SIZE - 4)
	else
		toggle:ClearAllPoints()
		toggle:SetPoint(unpack(MAP_SIZE.togglePoint))
		MAP_SIZE.togglePoint = nil
	end
end

local function UpdateGrip()
	if grip == nil then return end
	if foreign or not ScaleEnabled() or IsMaximized() then
		grip:Hide()
		ShiftScrollBars(false)
		MAP_SIZE.LayoutToggle(false)

		return
	end

	MapUtils:RaiseSizeGrip(grip, frame)
	grip:Show()
	ShiftScrollBars(true)
	MAP_SIZE.LayoutToggle(true)
end

local function Apply()
	if applying or sizing ~= nil or dragging then return end
	if fullscreenWasMaximized ~= nil and IsMaximized() then
		if IsLocked() then return end
		applying = true
		UpdateTopClamp()
		local k = ToUi()
		local width, height = UIParent:GetWidth() / k, UIParent:GetHeight() / k
		local sizeChanged = math.abs(frame:GetWidth() - width) > SCALE_EPSILON or math.abs(frame:GetHeight() - height) > SCALE_EPSILON
		if sizeChanged then frame:SetSize(width, height) end
		SetPos(0, UIParent:GetHeight())
		if sizeChanged then MAP_SIZE.SyncCanvas() end
		applying = false
		UpdateGrip()
		return
	end
	if not ready then return end
	if IsLocked() or CheckForeign() then return end
	applying = true
	if IsMaximized() then
		SetScale(1)
		local topGap = UpdateTopClamp()
		local pos = MAUTTAB["WORLDMAPMAXIMIZEDPOS"]
		if MoveEnabled() and type(pos) == "table" and pos.x ~= nil and pos.y ~= nil then
			SetPos(ClampPos(pos.x, pos.y, topGap))
		end
	else
		local scale = 1
		if ScaleEnabled() then scale = ClampScale(MAUTTAB["WORLDMAPSCALEVALUE"]) end
		local foreignLeft, foreignTop
		if foreignMove then foreignLeft, foreignTop = GetPos() end
		SetScale(scale)
		MAP_SIZE.Apply()
		local topGap = UpdateTopClamp()
		local pos = MAUTTAB["WORLDMAPPOS"]
		if foreignMove then
			if foreignLeft ~= nil then SetPos(foreignLeft, foreignTop) end
		elseif MoveEnabled() and type(pos) == "table" and pos.x ~= nil and pos.y ~= nil then
			SetPos(ClampPos(pos.x, pos.y, topGap))
		elseif blizzardPoint ~= nil then
			local point, relativeTo, relativePoint, x, y = unpack(blizzardPoint)
			frame:ClearAllPoints()
			frame:SetPoint(point, relativeTo, relativePoint, x / scale, y / scale)
			local left, top = GetPos()
			if left ~= nil then
				local cl, ct = ClampPos(left, top)
				if cl ~= left or ct ~= top then SetPos(cl, ct) end
			end
		end
	end

	applying = false
	UpdateGrip()
end

local function OnBlizzardPoint(_, ...)
	if applying or sizing ~= nil or dragging then return end
	blizzardPoint = {NormalizePoint(...)}
	Apply()
end

function MAP_SIZE.OnDragging()
	local drag = MAP_SIZE.drag
	if drag == nil then return end
	local x, y = MapUtils:GetCursorUi()
	SetPos(ClampPos(drag.left + x - drag.x, drag.top + y - drag.y, drag.topGap))
end

local function OnDragStart(region)
	local why = (not ready and "not ready") or (MapUtils:IsWorldMapFullscreen() and "fullscreen") or (IsLocked() and "combat locked") or (CheckForeign() and "foreign scale") or (not MoveEnabled() and "move disabled") or nil
	MAP_SIZE.dragNote = (why or "started") .. " via " .. tostring(region and region.GetDebugName and region:GetDebugName())
	if why then return end
	local left, top = GetPos()
	if left == nil then return end
	local x, y = MapUtils:GetCursorUi()
	MAP_SIZE.drag = {
		["x"] = x,
		["y"] = y,
		["left"] = left,
		["top"] = top,
		["topGap"] = UpdateTopClamp()
	}

	dragging = true
	MAP_SIZE.dragDriver = MAP_SIZE.dragDriver or CreateFrame("Frame")
	MAP_SIZE.dragDriver:SetScript("OnUpdate", MAP_SIZE.OnDragging)
end

local function OnDragStop()
	if not dragging then return end
	MAP_SIZE.OnDragging()
	MAP_SIZE.dragDriver:SetScript("OnUpdate", nil)
	MAP_SIZE.drag = nil
	dragging = false
	local left, top = GetPos()
	local key = IsMaximized() and "WORLDMAPMAXIMIZEDPOS" or "WORLDMAPPOS"
	if left ~= nil then MapUtils:SV(MAUTTAB, key, {["x"] = left, ["y"] = top}) end
	Apply()
end

local function GetCursorUi()
	return MapUtils:GetCursorUi()
end

function MAP_SIZE.ShowTooltip()
	if not MAP_SIZE.CanResize() then
		MapUtils:ShowScaleGripTooltip(grip)

		return
	end

	local shift = MapUtils:Trans("LID_SHIFT") .. " + "
	GameTooltip:SetOwner(grip, "ANCHOR_RIGHT")
	GameTooltip:SetText(MapUtils:Trans("LID_WINDOWSIZE", nil, math.floor(frame:GetWidth() - MAP_SIZE.QuestExtra() + 0.5), math.floor(frame:GetHeight() + 0.5)))
	GameTooltip:AddLine(MapUtils:Trans("LID_WIDGETSCALE", nil, math.floor(frame:GetScale() * 100 + 0.5)), 1, 1, 1)
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_DRAGTORESIZE")), 1, 1, 1)
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", shift .. MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_DRAGTOSCALE")), 1, 1, 1)
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_RESETSIZE")), 1, 1, 1)
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", shift .. MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_RESETSCALE", nil, 100)), 1, 1, 1)
	GameTooltip:Show()
end

function MAP_SIZE.OnSizing()
	local x, y = GetCursorUi()
	local k = ToUi()
	local w, h = MAP_SIZE.Clamp(sizing.width + (x - sizing.x) / k, sizing.height + (sizing.y - y) / k, sizing.left, sizing.top)
	applying = true
	MAP_SIZE.custom = true
	MAP_SIZE.Set(w, h)
	SetPos(sizing.left, sizing.top)
	applying = false
	MAP_SIZE.ShowTooltip()
end

local function OnSizing()
	if sizing == nil then return end
	if sizing.mode == "size" then return MAP_SIZE.OnSizing() end
	local x, y = GetCursorUi()
	local w = sizing.width + x - sizing.x
	local h = sizing.height + sizing.y - y
	local scale = sizing.scale * max(w / sizing.width, h / sizing.height)
	local unitW, unitH = GetUnitSize()
	local maxScale = min(GetMaxScale(), (UIParent:GetWidth() - sizing.left) / unitW, sizing.top / unitH)
	applying = true
	SetScale(ClampScale(scale, maxScale))
	SetPos(sizing.left, sizing.top)
	applying = false
	MAP_SIZE.ShowTooltip()
end

local function StopSizing()
	if sizing == nil then return end
	local mode = sizing.mode
	sizing = nil
	grip:SetScript("OnUpdate", nil)
	grip:SetButtonState("NORMAL")
	if mode == "size" then
		MapUtils:SV(MAUTTAB, "WORLDMAPSIZE", {["w"] = frame:GetWidth() - MAP_SIZE.QuestExtra(), ["h"] = frame:GetHeight()})
	else
		MapUtils:SV(MAUTTAB, "WORLDMAPSCALEVALUE", lastScale)
	end
	if MoveEnabled() then
		local left, top = GetPos()
		if left ~= nil then MapUtils:SV(MAUTTAB, "WORLDMAPPOS", {["x"] = left, ["y"] = top}) end
	end

	Apply()
end

local function StartSizing(_, button)
	if button ~= "LeftButton" or IsLocked() or CheckForeign() then return end
	local left, top = GetPos()
	if left == nil then return end
	local x, y = GetCursorUi()
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	sizing = {
		["x"] = x,
		["y"] = y,
		["left"] = left,
		["top"] = top,
		["width"] = w * s,
		["height"] = h * s,
		["scale"] = s
	}

	if not IsShiftKeyDown() and MAP_SIZE.CanResize() then
		sizing.mode = "size"
		sizing.width = frame:GetWidth() - MAP_SIZE.QuestExtra()
		sizing.height = frame:GetHeight()
	end

	grip:SetButtonState("PUSHED", true)
	grip:SetScript("OnUpdate", OnSizing)
end

function MapUtils:ShowScaleGripTooltip(target)
	if target.getScale == nil then return end
	GameTooltip:SetOwner(target, "ANCHOR_RIGHT")
	GameTooltip:SetText(MapUtils:Trans("LID_WIDGETSCALE", nil, math.floor(target.getScale() * 100 + 0.5)))
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_DRAGTOSCALE")), 1, 1, 1)
	GameTooltip:AddLine(format("|cffffd100%s|r  %s", MapUtils:Trans("LID_RIGHTCLICK"), MapUtils:Trans("LID_RESETSCALE", nil, 100)), 1, 1, 1)
	GameTooltip:Show()
end

function MapUtils:SetupScaleGrip(target, getScale, reset)
	target.getScale = getScale
	target:SetScript("OnEnter", function(owner) MapUtils:ShowScaleGripTooltip(owner) end)
	target:SetScript("OnLeave", function(owner) if owner:GetScript("OnUpdate") == nil and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end end)
	target:HookScript("OnMouseUp", function(owner, button)
		if button == "RightButton" then reset() end
		if owner:IsMouseOver() then
			MapUtils:ShowScaleGripTooltip(owner)
		elseif GameTooltip:IsOwned(owner) then
			GameTooltip:Hide()
		end
	end)
end

local function CreateGrip()
	grip = MapUtils:CreateSizeGrip(frame, GRIP_SIZE)
	grip:ClearAllPoints()
	grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
	grip:SetScript("OnMouseDown", StartSizing)
	grip:SetScript("OnHide", StopSizing)
	grip.getScale = function() return frame:GetScale() end
	grip:SetScript("OnEnter", MAP_SIZE.ShowTooltip)
	grip:SetScript("OnLeave", function() if sizing == nil and GameTooltip:IsOwned(grip) then GameTooltip:Hide() end end)
	grip:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			if not IsLocked() and not CheckForeign() then
				if IsShiftKeyDown() or not MAP_SIZE.CanResize() then
					MapUtils:SV(MAUTTAB, "WORLDMAPSCALEVALUE", 1)
				else
					MapUtils:SV(MAUTTAB, "WORLDMAPSIZE", nil)
				end

				Apply()
			end
		else
			StopSizing()
		end

		if grip:IsMouseOver() then
			MAP_SIZE.ShowTooltip()
		elseif GameTooltip:IsOwned(grip) then
			GameTooltip:Hide()
		end
	end)

	grip:Hide()
end

local function HookDrag(region)
	MAP_SIZE.dragRegions = MAP_SIZE.dragRegions or {}
	if region == nil or region.RegisterForDrag == nil then return end
	local name = tostring(region:GetDebugName())
	if not region:IsMouseEnabled() then
		MAP_SIZE.dragRegions[#MAP_SIZE.dragRegions + 1] = name .. " = no mouse"
		return
	end
	local blizzard = region == WorldMapTitleButton and region:GetScript("OnDragStart") == WorldMapTitleButton_OnDragStart
	if not blizzard and (region:GetScript("OnDragStart") or region:GetScript("OnDragStop")) then
		MAP_SIZE.dragRegions[#MAP_SIZE.dragRegions + 1] = name .. " = foreign drag script"
		foreignMove = true
		return
	end
	MAP_SIZE.dragRegions[#MAP_SIZE.dragRegions + 1] = name .. " = hooked"
	region:RegisterForDrag("LeftButton")
	region:HookScript("OnDragStart", OnDragStart)
	region:HookScript("OnDragStop", OnDragStop)
end

function MapUtils:PrintWorldMapMoveDebug()
	local mover = _G["WorldMapFrameMove"]
	local moverText = mover == nil and "nil" or (mover == MapUtils.worldMapMover and "MapUtils" or "other")
	print("|cff00ccffMapUtils move|r ready", ready, "foreign", foreign, "foreignMove", foreignMove, "dragging", dragging, "moveEnabled", MoveEnabled(), "setting", IsEnabled("WORLDMAPMOVE"), "oneForAll", MapUtils:IsWorldMapByOneForAll())
	print("|cff00ccffMapUtils move|r movable", frame:IsMovable(), "scale", frame:GetScale(), "lastScale", lastScale, "maximized", IsMaximized(), "fullscreen", MapUtils:IsWorldMapFullscreen(), "mover", moverText, "lastDrag", MAP_SIZE.dragNote)
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	local left, top = GetPos()
	print("|cff00ccffMapUtils move|r size", string.format("%.0fx%.0f", frame:GetWidth(), frame:GetHeight()), "onScreen", string.format("%.0fx%.0f", w * s, h * s), "screen", string.format("%.0fx%.0f", UIParent:GetWidth(), UIParent:GetHeight()), "pos", tostring(left), tostring(top), "clamped", frame:IsClampedToScreen(), "insets", frame:GetClampRectInsets())
	for _, line in ipairs(MAP_SIZE.dragRegions or {}) do
		print("|cff00ccffMapUtils move|r region", line)
	end

	local foci = GetMouseFoci and GetMouseFoci() or {GetMouseFocus and GetMouseFocus()}
	for _, focus in ipairs(foci) do
		local ok, name, drag = pcall(function() return tostring(focus:GetDebugName()), focus.GetScript ~= nil and focus:GetScript("OnDragStart") ~= nil end)
		print("|cff00ccffMapUtils move|r mouse", ok and name or "?", "drag", ok and tostring(drag) or "?")
	end
end

function MapUtils:PrintFadeDebug()
	MapUtils:PrintWorldMapMoveDebug()
	if fader ~= nil then fader:Debug("WorldMap") end
	if MapUtils.PrintBattlefieldFadeDebug ~= nil then MapUtils:PrintBattlefieldFadeDebug() end
end

function MapUtils:IsWorldMapByOneForAll()
	return frame ~= nil and frame.ofaMovable == true
end

function MapUtils:GetWorldMapMover()
	if MapUtils:IsAddOnActive("OneForAll") then return "OneForAll" end

	return nil
end

function MapUtils:SyncWorldMapMover()
	local take = MoveEnabled() and MapUtils:IsAddOnActive("ClassicUIForever")
	local mover = MapUtils.worldMapMover
	if take and _G["WorldMapFrameMove"] == nil then
		if mover == nil then
			mover = CreateFrame("Frame")
			mover:Hide()
			MapUtils.worldMapMover = mover
		end

		_G["WorldMapFrameMove"] = mover
	elseif not take and mover ~= nil and _G["WorldMapFrameMove"] == mover then
		_G["WorldMapFrameMove"] = nil
	end
end

function MapUtils:RefreshWorldMapFrame()
	MapUtils:SyncWorldMapMover()
	Apply()
	if fader ~= nil then fader:Reset() end
end

function MapUtils:IsWorldMapFullscreen()
	return fullscreenWasMaximized ~= nil and IsMaximized()
end

function MapUtils:IsClassicWorldMapSkinned()
	return frame ~= nil and frame.BorderFrame ~= nil and frame.BorderFrame.fcui ~= nil and MapUtils:IsAddOnActive("ClassicUIForever")
end

local function CreateFullscreenButton()
	local arrow = frame.BorderFrame and frame.BorderFrame.MaximizeMinimizeFrame or frame.MaximizeMinimizeFrame
	if not arrow or not arrow.Maximize or not arrow.Minimize or not frame.SynchronizeDisplayState then return end

	local button = CreateFrame("Button", nil, arrow, "UIPanelCloseButton")
	arrow.MapUtilsFullscreenButton = button
	function MapUtils:LayoutWorldMapFullscreenButton()
		if self.IsSimpleMapFrameActive ~= nil and self:IsSimpleMapFrameActive() then return end
		local gap = self:IsClassicWorldMapSkinned() and 8 or -2
		local anchor = arrow
		button:SetSize(arrow:GetSize())
		if frame.MiniBorderFrame ~= nil then
			local visible = arrow.MaximizeButton
			if visible == nil or not visible:IsShown() then visible = arrow.MinimizeButton or visible end
			local close = WorldMapFrameCloseButton
			if visible ~= nil and close ~= nil then
				local w, h = close:GetSize()
				local pad = w * (1 - MAP_SIZE.buttonInner) / 2
				local spacing = 4
				if close:GetLeft() ~= nil and visible:GetRight() ~= nil then spacing = max(0, close:GetLeft() - visible:GetRight() + pad * 2) end
				anchor = visible
				button:SetSize(w * MAP_SIZE.buttonInner, h * MAP_SIZE.buttonInner)
				gap = pad - spacing
			end
		end
		button:ClearAllPoints()
		button:SetPoint("RIGHT", anchor, "LEFT", gap, 0)
	end

	MapUtils:LayoutWorldMapFullscreenButton()
	local atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("RedButton-MiniCondense")
	local pressedAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("RedButton-MiniCondense-Pressed")
	local hasNativeDash = atlas and (atlas.file or atlas.filename)
	local face, art, pressed
	local classicSkin = false
	local classicFace = button:CreateTexture(nil, "ARTWORK")
	classicFace:SetAllPoints(button)
	classicFace:Hide()
	local classicCenter = button:CreateTexture(nil, "ARTWORK", nil, 1)
	classicCenter:SetPoint("CENTER", button, "CENTER", 0, 0)
	classicCenter:SetColorTexture(0.075, 0.075, 0.075, 1)
	classicCenter:Hide()
	local function LayoutFace(self, width, height)
		classicCenter:SetSize(width * 0.52, height * 0.52)
		if art then
			art.top:SetHeight(height * 0.49)
			art.middle:SetHeight(height * 0.29)
			art.bottom:SetHeight(height * 0.22)
		else
			face:SetSize(width * 0.56, height * 0.46)
			face:SetPoint("CENTER", self, "CENTER", 0, -height * 0.05)
		end
	end

	local function PaintArt()
		local info = pressed and pressedAtlas and (pressedAtlas.file or pressedAtlas.filename) and pressedAtlas or atlas
		local file = info.file or info.filename
		local left, right, top, bottom = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
		local function V(share) return top + (bottom - top) * share end
		for _, piece in ipairs({art.full, art.top, art.middle, art.bottom}) do
			piece:SetTexture(file)
		end

		art.full:SetTexCoord(left, right, top, bottom)
		art.top:SetTexCoord(left, right, top, V(0.49))
		art.middle:SetTexCoord(left, right, V(0.27), V(0.49))
		art.bottom:SetTexCoord(left, right, V(0.78), bottom)
	end

	if hasNativeDash then
		for _, texture in ipairs({button:GetNormalTexture(), button:GetPushedTexture()}) do
			texture:SetTexture(nil)
		end

		art = {}
		for _, key in ipairs({"full", "top", "middle", "bottom"}) do
			art[key] = button:CreateTexture(nil, "ARTWORK")
		end

		art.full:SetAllPoints(button)
		art.top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		art.top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
		art.middle:SetPoint("TOPLEFT", art.top, "BOTTOMLEFT", 0, 0)
		art.middle:SetPoint("TOPRIGHT", art.top, "BOTTOMRIGHT", 0, 0)
		art.bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
		art.bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
		PaintArt()

	else
		face = button:CreateTexture(nil, "ARTWORK")
		face:SetColorTexture(0.4, 0.06, 0.02)
	end

	button:SetScript("OnSizeChanged", LayoutFace)
	LayoutFace(button, button:GetSize())

	local corners = {}
	for _, corner in ipairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}) do
		local horizontal = button:CreateTexture(nil, "OVERLAY", nil, 7)
		horizontal:SetColorTexture(1, 0.82, 0.2)
		local vertical = button:CreateTexture(nil, "OVERLAY", nil, 7)
		vertical:SetColorTexture(1, 0.82, 0.2)
		corners[corner] = {horizontal, vertical}
	end

	local function LayoutCorners(classic)
		local length = classic and 3 or 4
		for corner, pieces in pairs(corners) do
			local x = corner:find("LEFT") and 5 or -5
			local y = corner:find("TOP") and -5 or 5
			local anchor = corner
			if classic then
				anchor = "CENTER"
				x, y = -x, -y
			end

			pieces[1]:SetSize(length, 1)
			pieces[2]:SetSize(1, length)
			for _, piece in ipairs(pieces) do
				piece:SetPoint(corner, button, anchor, x, y)
			end
		end
	end

	LayoutCorners(false)
	local dash = button:CreateTexture(nil, "OVERLAY", nil, 7)
	dash:SetColorTexture(1, 0.82, 0.2)
	dash:SetSize(8, 1)
	dash:SetPoint("BOTTOM", 0, 5)
	dash:Hide()

	local function RefreshClassicFace()
		local source = arrow.MaximizeButton
		local texture = source and (pressed and source:GetPushedTexture() or source:GetNormalTexture())
		local file = texture and texture:GetTexture()
		local shown = classicSkin and file ~= nil
		if shown then
			classicFace:SetTexture(file)
			classicFace:SetTexCoord(texture:GetTexCoord())
			classicFace:SetVertexColor(texture:GetVertexColor())
		end

		classicFace:SetShown(shown)
		classicCenter:SetShown(shown)

		return shown
	end
	local function ShowTooltip()
		local key = MapUtils:IsWorldMapFullscreen() and "LID_FULLSCREENEXIT" or "LID_FULLSCREENENTER"
		GameTooltip:SetText(MapUtils:Trans(key))
		GameTooltip:Show()
	end

	local function RefreshArtwork()
		local fullscreen = MapUtils:IsWorldMapFullscreen()
		local classic = MapUtils:IsClassicWorldMapSkinned()
		if classic or classicSkin or frame.MiniBorderFrame ~= nil then MapUtils:LayoutWorldMapFullscreenButton() end
		if classicSkin ~= classic then
			classicSkin = classic
			LayoutCorners(classic)
			if MapUtils.LayoutMapMenuButton ~= nil then MapUtils:LayoutMapMenuButton() end
		end

		local classicFaceShown = RefreshClassicFace()
		if face then face:SetShown(not classicFaceShown) end
		if art then
			art.full:SetShown(not classicFaceShown and fullscreen)
			art.top:SetShown(not classicFaceShown and not fullscreen)
			art.middle:SetShown(not classicFaceShown and not fullscreen)
			art.bottom:SetShown(not classicFaceShown and not fullscreen)
		end
		for _, pieces in pairs(corners) do
			pieces[1]:SetShown(not fullscreen)
			pieces[2]:SetShown(not fullscreen)
		end
		dash:SetShown(fullscreen and (classicFaceShown or not hasNativeDash))
		if GameTooltip:IsOwned(button) then ShowTooltip() end
	end

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		ShowTooltip()
	end)
	local artworkQueued
	local function QueueArtwork()
		if artworkQueued or not frame:IsShown() then return end
		artworkQueued = true
		C_Timer.After(0, function()
			artworkQueued = nil
			if frame:IsShown() then RefreshArtwork() end
		end)
	end

	button:HookScript("OnMouseDown", function()
		pressed = true
		if art then PaintArt() end
		RefreshClassicFace()
	end)
	button:HookScript("OnMouseUp", function()
		pressed = false
		if art then PaintArt() end
		RefreshClassicFace()
	end)
	button:HookScript("OnShow", QueueArtwork)
	hooksecurefunc(arrow, "SetPoint", QueueArtwork)
	hooksecurefunc(arrow, "SetSize", QueueArtwork)
	hooksecurefunc(frame, "SynchronizeDisplayState", MapUtils.Profile("mapframe RefreshArtwork", RefreshArtwork))
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnClick", function()
		if IsLocked() then return end
		if fullscreenWasMaximized ~= nil then
			local wasMaximized = fullscreenWasMaximized
			fullscreenWasMaximized = nil
			if wasMaximized then
				if frame.UpdateMaximizedSize ~= nil then
					frame:UpdateMaximizedSize()
				else
					frame:SynchronizeDisplayState()
				end
			else
				arrow:Minimize()
			end
		else
			fullscreenWasMaximized = IsMaximized()
			if not fullscreenWasMaximized then arrow:Maximize() end
		end
		Apply()
		MAP_SIZE.LayoutBorder()
		RefreshArtwork()
	end)
	if frame.UpdateMaximizedSize ~= nil then
		hooksecurefunc(frame, "UpdateMaximizedSize", function()
			if fullscreenWasMaximized ~= nil then Apply() end
		end)
	end
end

if frame ~= nil then
	if frame.BlackoutFrame ~= nil then
		frame.BlackoutFrame:SetAlpha(0)
		frame.BlackoutFrame:EnableMouse(false)
	end
	CreateGrip()
	MAP_SIZE.InstallSizeFallback()
	hooksecurefunc(frame, "SetPoint", OnBlizzardPoint)
	CreateFullscreenButton()
	if frame.SynchronizeDisplayState ~= nil then
		hooksecurefunc(frame, "SynchronizeDisplayState", function()
			if fullscreenWasMaximized ~= nil and not IsMaximized() then
				fullscreenWasMaximized = nil
			end
			Apply()
			MAP_SIZE.LayoutBorder()
			C_Timer.After(0, function()
				MAP_SIZE.LayoutBorder()
				MAP_SIZE.ResolveLayout()
			end)
			C_Timer.After(0.1, MAP_SIZE.ResolveLayout)
		end)
	end
	frame:HookScript("OnShow", function()
		Apply()
		MAP_SIZE.LayoutBorder()
		MAP_SIZE.CheckCanvas()
		if MAP_SIZE.canvasPending then C_Timer.After(0, MAP_SIZE.CheckCanvas) end
		C_Timer.After(0, MAP_SIZE.ResolveLayout)
		C_Timer.After(0.1, MAP_SIZE.ResolveLayout)
	end)
	if frame.ScrollContainer ~= nil then frame.ScrollContainer:HookScript("OnSizeChanged", MAP_SIZE.CheckCanvas) end
	frame:HookScript("OnSizeChanged", function() Apply() end)
	if frame.OnFrameSizeChanged ~= nil then hooksecurefunc(frame, "OnFrameSizeChanged", function() MapUtils:LayoutQuestDetails() end) end
	if frame.SidePanelToggle ~= nil then
		for _, button in ipairs({frame.SidePanelToggle.OpenButton, frame.SidePanelToggle.CloseButton}) do
			for _, region in ipairs({button:GetRegions()}) do
				local atlas = region.GetAtlas and region:GetAtlas()
				if type(atlas) == "string" and atlas:find("MapCornerShadow", 1, true) then
					region:SetAlpha(0)
					region:Hide()
				end
			end
		end
	end

	if QuestMapFrame ~= nil then
		QuestMapFrame:HookScript("OnShow", UpdateGrip)
		QuestMapFrame:HookScript("OnHide", UpdateGrip)
	end
	fader = MapUtils:CreateMoveFader(
		frame,
		{
			["isEnabled"] = function() return PlayerMovementFrameFader ~= nil or (type(MAUTTAB) == "table" and MAUTTAB["WORLDMAPFADE"] ~= false) end,
			["getOpacity"] = function()
				if type(MAUTTAB) ~= "table" or MAUTTAB["WORLDMAPFADE"] == false then return 100 end

				return MAUTTAB["WORLDMAPFADEOPACITY"]
			end,
			["hookSetAlpha"] = true,
			["isBusy"] = function() return dragging or sizing ~= nil end
		}
	)
	frame:HookScript("OnHide", OnDragStop)
	local loader = CreateFrame("FRAME")
	MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
	loader:SetScript(
		"OnEvent",
		function()
			MAUTTAB = MAUTTAB or {}
			HookDrag(frame)
			for _, key in ipairs(dragRegions) do
				HookDrag(frame[key])
			end

			if frame.BorderFrame ~= nil then HookDrag(frame.BorderFrame.TitleContainer) end
			HookDrag(WorldMapTitleButton)
			MapUtils:SyncWorldMapMover()
			ready = true
			if frame:IsShown() then Apply() end
		end
	)
end

local WheelZoom = {
	installDelay = 3,
	container = WorldMapFrame and WorldMapFrame.ScrollContainer,
	zoomMethods = {"InstantPanAndZoom", "SetZoomTarget", "ZoomIn", "ZoomOut"},
}
WheelZoom.disabledByBlizzard = WheelZoom.container ~= nil and nop ~= nil and WheelZoom.container:GetScript("OnMouseWheel") == nop
function MapUtils:IsWorldMapWheelZoomAvailable()
	return WheelZoom.disabledByBlizzard == true
end

function WheelZoom.MarkForeign()
	if not WheelZoom.own then WheelZoom.foreignTime = GetTime() end
end

function WheelZoom.Apply()
	local pending = WheelZoom.pending
	WheelZoom.pending = nil
	local container = WheelZoom.container
	if pending == nil or not container:IsVisible() then return end
	if WheelZoom.foreignTime ~= nil and WheelZoom.foreignTime >= pending.time then return end
	if math.abs(container:GetCanvasScale() - pending.scale) > SCALE_EPSILON then return end
	local zoomOut, zoomIn = container:GetCurrentZoomRange()
	local target = pending.delta > 0 and zoomIn or zoomOut
	if target == nil or math.abs(target - container:GetCanvasScale()) <= SCALE_EPSILON then return end
	WheelZoom.own = true
	container:InstantPanAndZoom(target, pending.x, pending.y)
	WheelZoom.own = false
end

function MapUtils:GetFollowZoomAnchor(container)
	if MapUtils.IsFollowingPlayer == nil or not MapUtils:IsFollowingPlayer() or container.mapID == nil or C_Map.GetPlayerMapPosition == nil then return nil end
	local pos = C_Map.GetPlayerMapPosition(container.mapID, "player")
	if pos == nil then return nil end
	local x, y = pos:GetXY()
	if x == nil or y == nil or MapUtils:IsSecret(x) or MapUtils:IsSecret(y) or (x == 0 and y == 0) or x < 0 or x > 1 or y < 0 or y > 1 then return nil end

	return x, y
end

function MapUtils:GetZoomAnchor(container)
	local x, y = MapUtils:GetFollowZoomAnchor(container)
	if x ~= nil then return x, y end

	return container:GetNormalizedCursorPosition()
end

function WheelZoom.OnMouseWheel(container, delta)
	if not IsEnabled("WORLDMAPZOOM") or MapUtils:IsOneMap() or container.zoomLevels == nil then return end
	if WheelZoom.foreignTime == GetTime() then return end
	local x, y = MapUtils:GetZoomAnchor(container)
	WheelZoom.pending = {
		["delta"] = delta,
		["x"] = x,
		["y"] = y,
		["time"] = GetTime(),
		["scale"] = container:GetCanvasScale(),
	}
	C_Timer.After(0, WheelZoom.Apply)
end

function WheelZoom.Install()
	if WheelZoom.installed or not WheelZoom.disabledByBlizzard then return end
	local container = WheelZoom.container
	if container:GetScript("OnMouseWheel") ~= nop then return end
	WheelZoom.installed = true
	for _, method in ipairs(WheelZoom.zoomMethods) do
		if type(container[method]) == "function" then hooksecurefunc(container, method, MapUtils.Profile("mapframe WheelZoom MarkForeign", WheelZoom.MarkForeign)) end
	end

	container:EnableMouseWheel(true)
	container:HookScript("OnMouseWheel", WheelZoom.OnMouseWheel)
end

if WheelZoom.disabledByBlizzard then
	WheelZoom.loader = CreateFrame("Frame")
	WheelZoom.loader:RegisterEvent("PLAYER_LOGIN")
	WheelZoom.loader:SetScript("OnEvent", function(sel)
		sel:UnregisterAllEvents()
		C_Timer.After(WheelZoom.installDelay, WheelZoom.Install)
	end)
end

local MapLevelZoom = {
	cooldown = 0.3,
	lastSwitch = 0,
	fillShare = 0.9,
}

function MapLevelZoom.OnUpdate(container)
	local snap = MapLevelZoom.snap
	if snap == nil then
		snap = {}
		MapLevelZoom.snap = snap
	end

	snap.mapID = container.mapID
	snap.scale = container:GetCanvasScale()
	snap.target = container.targetScale
end

function MapLevelZoom.AtScale(snap, scale)
	return scale ~= nil and snap.target ~= nil and math.abs(snap.scale - scale) <= SCALE_EPSILON and math.abs(snap.target - snap.scale) <= SCALE_EPSILON
end

function MapLevelZoom.ChildAtCursor(container, mapID)
	local x, y = MapUtils:GetZoomAnchor(container)
	if x == nil or y == nil then return nil end
	local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
	if info and info.mapID ~= mapID then return info.mapID end

	return nil
end

function MapLevelZoom.FillsView(container, snap, child, mapID)
	local left, right, top, bottom = C_Map.GetMapRectOnMap(child, mapID)
	if left == nil or right == nil or top == nil or bottom == nil then return false end
	local childWidth, childHeight = container.Child:GetSize()
	local scale = math.max(snap.scale, snap.target or snap.scale)
	if childWidth == nil or childHeight == nil or childWidth <= 0 or childHeight <= 0 or scale <= 0 then return false end
	local viewWidth = container:GetWidth() / scale / childWidth
	local viewHeight = container:GetHeight() / scale / childHeight
	if viewWidth <= 0 or viewHeight <= 0 then return false end

	return math.max((right - left) / viewWidth, (bottom - top) / viewHeight) >= MapLevelZoom.fillShare
end

function MapLevelZoom.Target(container, snap, delta)
	local mapID = snap.mapID
	local info = C_Map.GetMapInfo(mapID)
	if info == nil then return nil end
	if delta < 0 then
		if not MapLevelZoom.AtScale(snap, container:GetScaleForMinZoom()) then return nil end
		if info.parentMapID and info.parentMapID > 0 then return info.parentMapID end

		return nil
	end

	local child = MapLevelZoom.ChildAtCursor(container, mapID)
	if child == nil then return nil end
	if WheelZoom.installed and not IsEnabled("WORLDMAPZOOM") then return child end
	if MapLevelZoom.AtScale(snap, container:GetScaleForMaxZoom()) or MapLevelZoom.FillsView(container, snap, child, mapID) then return child end

	return nil
end

function MapLevelZoom.OnMouseWheel(container, delta)
	local snap = MapLevelZoom.snap
	if snap == nil or snap.mapID == nil or snap.mapID ~= container.mapID or container.zoomLevels == nil then return end
	if not MapUtils:IsOneMap() or InCombatLockdown() then return end
	if MapUtils.IsZoneDetailMap ~= nil and MapUtils:IsZoneDetailMap(container.mapID) then return end
	if delta < 0 and MapUtils.GetZoneDetailCityZone ~= nil and MapUtils:GetZoneDetailCityZone(container.mapID) ~= nil then return end
	if GetTime() - MapLevelZoom.lastSwitch < MapLevelZoom.cooldown then return end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return end
	local target = MapLevelZoom.Target(container, snap, delta)
	if target == nil or C_Map.GetMapInfo(target) == nil then return end
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	frame:SetMapID(target)
end

local SmoothZoom = {
	extents = {time = 0},
	extentsInterval = 0.5,
	factor = 1.22,
	spaceZoom = 12,
	zoneZoom = 6,
	tileFullMargin = 1.15,
	panEdge = 0.3,
	panOpenShare = 0.55,
	worldPanOpenShare = 0.99,
	worldMapID = 947,
	enterArea = 2,
	leaveArea = 3.3,
	enterContinentArea = 1.1,
	cityEnterShare = 0.5,
	zoneEnterCover = 0.95,
	leaveContinentArea = 1.8,
	minZoomPick = 1.02,
	checkInterval = 0.1,
	lastCheck = 0,
	speed = 13,
	snapLog = 0.002,
	settleEpsilon = 0.0005,
	centerDuration = 0.6,
	pinZoomRange = 150,
}

function MapUtils:IsOneMap()
	if type(MAUTTAB) ~= "table" then return false end
	if MAUTTAB["ONEMAP"] == nil then MAUTTAB["ONEMAP"] = true end

	return MAUTTAB["ONEMAP"] == true
end

function SmoothZoom.IsSpace(mapID)
	return mapID ~= nil and MapUtils.IsZoneDetailMap ~= nil and MapUtils:IsZoneDetailMap(mapID)
end

function SmoothZoom.CanSwitch(container)
	if not MapUtils:IsOneMap() or InCombatLockdown() or container.zoomLevels == nil then return false end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return false end

	return SmoothZoom.IsSpace(container.mapID)
end

function SmoothZoom.GetParent(mapID)
	local info = C_Map.GetMapInfo(mapID)
	local parent = info and info.parentMapID
	if parent == nil or parent <= 0 or not SmoothZoom.IsSpace(parent) then return nil end

	return parent
end

function SmoothZoom.GetFitOnHost(container, mapID)
	local hostLeft, hostRight, hostTop, hostBottom = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	if hostLeft == nil or mapID == nil or hostRight <= hostLeft or hostBottom <= hostTop then return nil end
	local left, right, top, bottom = SmoothZoom.RectOn(mapID, MapUtils:GetZoneDetailSpace(container.mapID))
	local width, height = container.Child:GetSize()
	if left == nil or right <= left or bottom <= top or width == nil or width <= 0 or height == nil or height <= 0 then return nil end

	return math.min(container:GetWidth() / ((right - left) * (hostRight - hostLeft) * width), container:GetHeight() / ((bottom - top) * (hostBottom - hostTop) * height))
end

function SmoothZoom.GetSpaceFit(container)
	return SmoothZoom.GetFitOnHost(container, MapUtils:GetZoneDetailSpace(container.mapID))
end

function SmoothZoom.GetMinScale(container)
	local minScale = container:GetScaleForMinZoom()
	if MapUtils.GetZoneDetailCityZone ~= nil and MapUtils:GetZoneDetailCityZone(container.mapID) ~= nil then return minScale end
	if not SmoothZoom.IsSpace(container.mapID) then return minScale end
	local fit = SmoothZoom.GetSpaceFit(container)
	if fit == nil or fit <= 0 then return minScale end

	return math.min(minScale, fit)
end

function SmoothZoom.GetDeepestScale(container, x, y)
	local host = container.mapID
	local left, right, top, bottom = MapUtils:GetZoneDetailSpaceRect(host)
	x, y = x or container:GetCurrentScrollX(), y or container:GetCurrentScrollY()
	if left == nil or x == nil or y == nil or right <= left or bottom <= top then return nil end
	local space = MapUtils:GetZoneDetailSpace(host)
	local preferred = MapUtils:GetZoneDetailContinent(host)
	local continent, zone = SmoothZoom.ContinentAt(space, (x - left) / (right - left), (y - top) / (bottom - top), preferred)
	if continent == nil then continent = preferred or MapUtils:GetZoneDetailContinents(space)[1] end
	local deepest
	local function Raise(value)
		if type(value) == "number" and value > 0 and (deepest == nil or value > deepest) then deepest = value end
	end

	local continentFit = continent and SmoothZoom.GetFitOnHost(container, continent)
	Raise(continentFit and continentFit * SmoothZoom.spaceZoom)
	if zone ~= nil and zone.mapType == Enum.UIMapType.Zone and SmoothZoom.IsSpace(zone.mapID) then
		local zoneFit = SmoothZoom.GetFitOnHost(container, zone.mapID)
		Raise(zoneFit and zoneFit * SmoothZoom.zoneZoom)
		local perScale = MapUtils.GetZoneDetailTilePixelsPerScale ~= nil and MapUtils:GetZoneDetailTilePixelsPerScale(zone.mapID)
		local zoneLeft, zoneRight = MapUtils:GetZoneDetailSpaceRect(zone.mapID)
		if perScale and perScale > 0 and zoneLeft ~= nil and zoneRight > zoneLeft then Raise(MapUtils:GetZoneDetailTileFullPixels(zone.mapID) * SmoothZoom.tileFullMargin / (perScale * (right - left) / (zoneRight - zoneLeft))) end
	end

	return deepest
end

function SmoothZoom.GetMaxScale(container, x, y)
	local maxScale = container:GetScaleForMaxZoom()
	local mapID = container.mapID
	if SmoothZoom.IsSpace(mapID) then
		local deepest = SmoothZoom.GetDeepestScale(container, x, y)
		if deepest ~= nil then return math.max(maxScale, deepest) end
	end
	local info = mapID and C_Map.GetMapInfo(mapID)
	local zone = info and info.mapType == Enum.UIMapType.Zone
	if mapID == 1458 or SmoothZoom.IsSpace(mapID) then
		local zoom = (zone or mapID == 1458) and SmoothZoom.zoneZoom or SmoothZoom.spaceZoom
		maxScale = math.max(maxScale, container:GetScaleForMinZoom() * zoom)
	end
	if zone and MapUtils.GetZoneDetailTilePixelsPerScale ~= nil then
		local perScale = MapUtils:GetZoneDetailTilePixelsPerScale(mapID)
		if perScale ~= nil and perScale > 0 then maxScale = math.max(maxScale, MapUtils:GetZoneDetailTileFullPixels(mapID) * SmoothZoom.tileFullMargin / perScale) end
	end

	return maxScale
end

function SmoothZoom.GetPanRect(mapID)
	return MapUtils:GetZoneDetailSpaceRect(mapID)
end

function SmoothZoom.PanRoom(share, openShare)
	local open = Clamp((1 - share) / (1 - (openShare or SmoothZoom.panOpenShare)), 0, 1)

	return 1 - (1 - open) * (1 - open)
end

function SmoothZoom.PanRange(low, high, half, room)
	local centre, size = (low + high) / 2, (high - low) / 2
	local reach = size >= half and size - half or (half - size) * room
	reach = reach + half * 2 * SmoothZoom.panEdge * room

	return centre - reach, centre + reach
end

function SmoothZoom.GetExtents(container, scale)
	local minX, maxX, minY, maxY = container:CalculateScrollExtentsAtScale(scale)
	if not MapUtils:IsOneMap() or container.mapID == nil or scale <= 0 then return minX, maxX, minY, maxY end
	local left, right, top, bottom = 0, 1, 0, 1
	local space = SmoothZoom.IsSpace(container.mapID)
	if space then left, right, top, bottom = SmoothZoom.GetPanRect(container.mapID) end
	local width, height = container.Child:GetSize()
	if left == nil or width == nil or width <= 0 or height == nil or height <= 0 then return minX, maxX, minY, maxY end
	local viewWidth, viewHeight = container:GetWidth(), container:GetHeight()
	local fit = space and SmoothZoom.GetSpaceFit(container)
	if type(fit) == "number" and fit > 0 then
		local halfWidth, halfHeight = viewWidth / 2 / (scale * width), viewHeight / 2 / (scale * height)
		local roomScale = scale
		local anim = SmoothZoom.anim
		if anim ~= nil and anim.mapID == container.mapID and anim.target ~= nil and anim.target > scale then roomScale = anim.target end
		local shareX, shareY = halfWidth * 2 / (right - left) * scale / roomScale, halfHeight * 2 / (bottom - top) * scale / roomScale
		local roomX, roomY
		if container.mapID == SmoothZoom.worldMapID then
			roomX, roomY = SmoothZoom.PanRoom(shareX, SmoothZoom.worldPanOpenShare), SmoothZoom.PanRoom(shareY, SmoothZoom.worldPanOpenShare)
		else
			roomX = SmoothZoom.PanRoom(math.max(shareX, shareY))
			roomY = roomX
		end

		local lowX, highX = SmoothZoom.PanRange(left, right, halfWidth, roomX)
		local lowY, highY = SmoothZoom.PanRange(top, bottom, halfHeight, roomY)

		return lowX, highX, lowY, highY
	end
	local scaledWidth, scaledHeight = scale * width, scale * height
	local visibleSize = 10 / container:GetEffectiveScale()
	local visibleWidth = math.min(visibleSize, viewWidth, (right - left) * scaledWidth)
	local visibleHeight = math.min(visibleSize, viewHeight, (bottom - top) * scaledHeight)
	local offsetX = (viewWidth / 2 - visibleWidth) / scaledWidth
	local offsetY = (viewHeight / 2 - visibleHeight) / scaledHeight

	return left - offsetX, right + offsetX, top - offsetY, bottom + offsetY
end

function SmoothZoom.WidenExtents(container)
	if not MapUtils:IsOneMap() or container.mapID == nil then return end
	local scale = container:GetCanvasScale()
	local width, height = container:GetSize()
	local now = GetTime()
	local cache = SmoothZoom.extents
	if cache.mapID == container.mapID and cache.scale == scale and cache.width == width and cache.height == height and now - cache.time < SmoothZoom.extentsInterval and container.scrollXExtentsMin == cache[1] and container.scrollXExtentsMax == cache[2] and container.scrollYExtentsMin == cache[3] and container.scrollYExtentsMax == cache[4] then return end
	container.scrollXExtentsMin, container.scrollXExtentsMax, container.scrollYExtentsMin, container.scrollYExtentsMax = SmoothZoom.GetExtents(container, scale)
	cache.mapID, cache.scale, cache.width, cache.height, cache.time = container.mapID, scale, width, height, now
	cache[1], cache[2], cache[3], cache[4] = container.scrollXExtentsMin, container.scrollXExtentsMax, container.scrollYExtentsMin, container.scrollYExtentsMax
end

function SmoothZoom.SetView(container, scale, x, y, targetScale, targetX, targetY, preserveCityScale)
	local minScale = SmoothZoom.GetMinScale(container)
	local maxScale = SmoothZoom.IsSpace(container.mapID) and math.max(scale, targetScale) or SmoothZoom.GetMaxScale(container)
	if preserveCityScale then minScale = math.min(minScale, scale, targetScale) end
	if preserveCityScale or SmoothZoom.IsSpace(container.mapID) then maxScale = math.max(maxScale, scale, targetScale) end
	scale = Clamp(scale, minScale, maxScale)
	targetScale = Clamp(targetScale, minScale, maxScale)
	container.currentScale = scale
	container.targetScale = targetScale
	container.zoomTarget = targetScale
	container.Child:SetScale(scale)
	container:CalculateScrollExtents()
	SmoothZoom.WidenExtents(container)
	x = Clamp(x, container.scrollXExtentsMin, container.scrollXExtentsMax)
	y = Clamp(y, container.scrollYExtentsMin, container.scrollYExtentsMax)
	local minX, maxX, minY, maxY = SmoothZoom.GetExtents(container, targetScale)
	container.currentScrollX, container.currentScrollY = x, y
	container.targetScrollX, container.targetScrollY = Clamp(targetX, minX, maxX), Clamp(targetY, minY, maxY)
	container:SetNormalizedHorizontalScroll(x)
	container:SetNormalizedVerticalScroll(y)
	container:GetMap():OnCanvasScaleChanged()
	container:MarkAreaTriggersDirty()
	container:MarkViewRectDirty()
	if SmoothZoom.viewMapID ~= container.mapID then
		SmoothZoom.viewMapID = container.mapID
		if MapUtils.UpdateZoneDetailView ~= nil then MapUtils:UpdateZoneDetailView() end
	end
end

function SmoothZoom.Switch(container, target, keepCurrentView)
	local fromLeft, fromRight, fromTop, fromBottom = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	if fromLeft == nil and MapUtils.GetZoneDetailRawRect ~= nil then fromLeft, fromRight, fromTop, fromBottom = MapUtils:GetZoneDetailRawRect(container.mapID) end
	local toLeft, toRight, toTop, toBottom = MapUtils:GetZoneDetailSpaceRect(target)
	if toLeft == nil and MapUtils.GetZoneDetailRawRect ~= nil then toLeft, toRight, toTop, toBottom = MapUtils:GetZoneDetailRawRect(target) end
	local layers = C_Map.GetMapArtLayers(target)
	local layer = layers and layers[1]
	local width = container.Child:GetWidth()
	if fromLeft == nil or toLeft == nil or layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 or width == nil or width <= 0 then return false end
	local city = MapUtils:GetZoneDetailCityZone(target) ~= nil
	local function mapX(value) return toLeft + (value - fromLeft) / (fromRight - fromLeft) * (toRight - toLeft) end
	local function mapY(value) return toTop + (value - fromTop) / (fromBottom - fromTop) * (toBottom - toTop) end
	local scale = container:GetCanvasScale()
	local x, y = container:GetCurrentScrollX() or 0.5, container:GetCurrentScrollY() or 0.5
	local targetScale = container.targetScale or scale
	local targetX, targetY = container.targetScrollX or x, container.targetScrollY or y
	if keepCurrentView or SmoothZoom.anim ~= nil then targetScale, targetX, targetY = scale, x, y end
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	WheelZoom.own = true
	MapUtils.zoneSwitching = true
	frame:SetMapID(target)
	MapUtils.zoneSwitching = false
	WheelZoom.own = false
	if container.mapID ~= target then
		if MapUtils.UpdateZoneDetailView ~= nil then MapUtils:UpdateZoneDetailView() end

		return false
	end

	SmoothZoom.pickMapID = target
	local targetWidth = container.Child:GetWidth()
	if targetWidth == nil or targetWidth <= 0 then targetWidth = layer.layerWidth end
	local factor = (fromRight - fromLeft) * width / ((toRight - toLeft) * targetWidth)
	SmoothZoom.SetView(container, scale * factor, mapX(x), mapY(y), targetScale * factor, mapX(targetX), mapY(targetY), city)
	SmoothZoom.ShowLoadedArt()
	if MapUtils.UpdateWorldPinsNow ~= nil then MapUtils.UpdateWorldPinsNow() end

	return true
end

function SmoothZoom.ShowLoadedArt()
	if frame.detailLayerPool ~= nil then
		for layer in frame.detailLayerPool:EnumerateActive() do
			if layer.textureLoadGroup == nil or layer.textureLoadGroup:IsFullyLoaded() then layer:SetAlpha(layer:GetLayerAlpha() * layer:GetGlobalAlpha()) end
		end
	end

	if frame.EnumeratePinsByTemplate ~= nil then
		for pin in frame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
			if pin.textureLoadGroup == nil or pin.textureLoadGroup:IsFullyLoaded() then pin:SetAlpha(frame:GetGlobalAlpha()) end
		end
	end
end

function SmoothZoom.IsSettled(container)
	if SmoothZoom.anim ~= nil then return false end
	if container.mouseButtonInfo and container.mouseButtonInfo.LeftButton and container.mouseButtonInfo.LeftButton.down then return false end
	local scale = container:GetCanvasScale()
	if container.targetScale ~= nil and math.abs(container.targetScale - scale) > scale * SmoothZoom.settleEpsilon then return false end
	local x, y = container:GetCurrentScrollX(), container:GetCurrentScrollY()
	if x == nil or y == nil then return false end
	if container.targetScrollX ~= nil and math.abs(container.targetScrollX - x) > SmoothZoom.settleEpsilon then return false end
	if container.targetScrollY ~= nil and math.abs(container.targetScrollY - y) > SmoothZoom.settleEpsilon then return false end

	return true
end

function SmoothZoom.RectOn(mapID, space)
	if mapID == space then return 0, 1, 0, 1 end

	return C_Map.GetMapRectOnMap(mapID, space)
end

function SmoothZoom.PickMap(container)
	local host = container.mapID
	local left, right, top, bottom = MapUtils:GetZoneDetailSpaceRect(host)
	local scale = container:GetCanvasScale()
	local x, y = container:GetCurrentScrollX(), container:GetCurrentScrollY()
	local width, height = container.Child:GetSize()
	if left == nil or x == nil or y == nil or scale <= 0 or width == nil or width <= 0 or height == nil or height <= 0 then return nil end
	local spaceWidth, spaceHeight = right - left, bottom - top
	local u, v = (x - left) / spaceWidth, (y - top) / spaceHeight
	local viewWidth = container:GetWidth() / (scale * width) / spaceWidth
	local viewHeight = container:GetHeight() / (scale * height) / spaceHeight
	local space = MapUtils:GetZoneDetailSpace(host)
	local function Fits(mapID, continent)
		local l, r, t, b = SmoothZoom.RectOn(mapID, space)
		if l == nil or r <= l or b <= t then return false end
		local ratio = (viewWidth / (r - l)) * (viewHeight / (b - t))
		if continent then return ratio <= ((mapID == host or MapUtils:GetZoneDetailContinent(host) == mapID) and SmoothZoom.leaveContinentArea or SmoothZoom.enterContinentArea) end

		return ratio <= ((mapID == host) and SmoothZoom.leaveArea or SmoothZoom.enterArea)
	end

	local pick = space
	if u < 0 or u > 1 or v < 0 or v > 1 then return pick end
	local hostCity = MapUtils.GetZoneDetailCityZone ~= nil and MapUtils:GetZoneDetailCityZone(host) ~= nil
	if not hostCity and scale <= SmoothZoom.GetMinScale(container) * SmoothZoom.minZoomPick then return pick end
	local cityAtCenter = MapUtils:GetZoneDetailCityAt(space, u, v)
	local continent, zone
	if cityAtCenter ~= nil then
		continent = MapUtils:GetZoneDetailContinent(cityAtCenter)
		zone = C_Map.GetMapInfo(cityAtCenter)
	else
		continent, zone = SmoothZoom.ContinentAt(space, u, v, MapUtils:GetZoneDetailContinent(host))
	end
	if continent == nil or not SmoothZoom.IsSpace(continent) or not Fits(continent, true) then return pick end
	pick = continent
	local l, r, t, b = SmoothZoom.RectOn(continent, space)
	if l == nil or r <= l or b <= t then return pick end
	local cover = (host ~= continent and host ~= space) and 1 or SmoothZoom.zoneEnterCover
	local continentVisible = viewWidth >= (r - l) * cover and viewHeight >= (b - t) * cover
	if zone ~= nil and zone.mapID ~= continent and zone.mapType == Enum.UIMapType.Zone and SmoothZoom.IsSpace(zone.mapID) and not continentVisible
		and (not SmoothZoom.zoomingOut or zone.mapID == host or MapUtils:GetZoneDetailCityZone(zone.mapID) == nil) then
		pick = zone.mapID
	end
	if pick == continent and zone ~= nil and not continentVisible and MapUtils.GetZoneDetailCityZone ~= nil then
		local around = MapUtils:GetZoneDetailCityZone(zone.mapID)
		if around ~= nil and SmoothZoom.IsSpace(around) then pick = around end
	end
	local city = zone ~= nil and MapUtils.GetZoneDetailCityZone ~= nil and MapUtils:GetZoneDetailCityZone(zone.mapID) ~= nil and zone.mapID or nil
	if city == nil and pick ~= continent then
		local zl, zr, zt, zb = C_Map.GetMapRectOnMap(pick, space)
		local inner = zl ~= nil and zr > zl and zb > zt and C_Map.GetMapInfoAtPosition(pick, (u - zl) / (zr - zl), (v - zt) / (zb - zt))
		if inner and inner.mapID ~= pick and MapUtils:GetZoneDetailCityZone(inner.mapID) ~= nil then city = inner.mapID end
	end

	city = cityAtCenter or city
	if city ~= nil and not continentVisible and (city == host or not SmoothZoom.zoomingOut) then
		local cl, cr, ct, cb = C_Map.GetMapRectOnMap(city, space)
		if cl ~= nil and u >= cl and u <= cr and v >= ct and v <= cb then
			if SmoothZoom.IsSpace(city) then return city end

			local halfWidth, halfHeight = viewWidth / 2, viewHeight / 2
			local overlapWidth = math.min(cr, u + halfWidth) - math.max(cl, u - halfWidth)
			local overlapHeight = math.min(cb, v + halfHeight) - math.max(ct, v - halfHeight)
			if overlapWidth * overlapHeight >= viewWidth * viewHeight * SmoothZoom.cityEnterShare then pick = city end
		end
	end

	if pick == continent and not continentVisible then
		for _, radius in ipairs({0.1, 0.25}) do
			for direction = 0, 7 do
				local angle = direction * math.pi / 4
				local sampleX = u + math.cos(angle) * viewWidth * radius
				local sampleY = v + math.sin(angle) * viewHeight * radius
				if sampleX >= l and sampleX <= r and sampleY >= t and sampleY <= b then
					local nearby = SmoothZoom.ZoneAt(continent, space, sampleX, sampleY, l, r, t, b)
					if nearby ~= nil and nearby.mapType == Enum.UIMapType.Zone and SmoothZoom.IsSpace(nearby.mapID) and MapUtils:GetZoneDetailCityZone(nearby.mapID) == nil then return nearby.mapID end
				end
			end
		end
	end

	return pick
end

function SmoothZoom.ZoneAt(continent, space, u, v, left, right, top, bottom)
	local zone = C_Map.GetMapInfoAtPosition(continent, (u - left) / (right - left), (v - top) / (bottom - top))
	if zone == nil or zone.mapID == continent or not MapUtils.IsMapInside(zone.mapID, continent) then return nil end
	local l, r, t, b = SmoothZoom.RectOn(zone.mapID, space)
	if l ~= nil and u >= l and u <= r and v >= t and v <= b then return zone end
end

function SmoothZoom.ContinentAt(space, u, v, preferred)
	if MapUtils.GetZoneDetailContinents == nil then return nil end
	local fallback, foundContinent, foundZone
	for _, continent in ipairs(MapUtils:GetZoneDetailContinents(space)) do
		local l, r, t, b = SmoothZoom.RectOn(continent, space)
		if l ~= nil and r > l and b > t and u >= l and u <= r and v >= t and v <= b then
			local zone = SmoothZoom.ZoneAt(continent, space, u, v, l, r, t, b)
			if zone ~= nil and continent == preferred then return continent, zone end
			if zone ~= nil and foundZone == nil then foundContinent, foundZone = continent, zone end
			if fallback == nil or continent == preferred then fallback = continent end
		end
	end

	return foundContinent or fallback, foundZone
end

function SmoothZoom.ClickTarget(host, x, y)
	local left, right, top, bottom = MapUtils:GetZoneDetailSpaceRect(host)
	if left == nil or x == nil or y == nil or right <= left or bottom <= top then return nil end
	local space = MapUtils:GetZoneDetailSpace(host)
	local continent, zone = SmoothZoom.ContinentAt(space, (x - left) / (right - left), (y - top) / (bottom - top), MapUtils:GetZoneDetailContinent(host))
	if continent == nil or zone == nil or zone.mapType ~= Enum.UIMapType.Zone then return nil end
	if host == space and continent ~= space then return continent, continent, space end

	return zone.mapID, continent, space
end

function MapUtils:GetOneMapTargetAt(host, x, y)
	if not SmoothZoom.IsSpace(host) then return nil end

	return SmoothZoom.ClickTarget(host, x, y)
end

function SmoothZoom.OnCanvasClick(map, button, x, y)
	if button == "RightButton" and MapUtils:IsOneMap() and not (MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()) then return SmoothZoom.GlideOut(WheelZoom.container) end
	if button ~= "LeftButton" or not MapUtils:IsOneMap() or MapUtils.GetZoneDetailContinents == nil then return false end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return false end
	local host = map:GetMapID()
	if not SmoothZoom.IsSpace(host) then return false end
	local cursorX, cursorY = SmoothZoom.CanvasCursor(map.ScrollContainer)
	local target = SmoothZoom.ClickTarget(host, cursorX or x, cursorY or y)
	if target == nil or target == host then return false end
	SmoothZoom.anim = nil
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	if not SmoothZoom.GlideInto(WheelZoom.container, target) then map:SetMapID(target) end

	return true
end

function SmoothZoom.Glide(container, toScale, toX, toY, onDone)
	if container == nil or toScale == nil or toScale <= 0 then return false end
	SmoothZoom.anim = nil
	SmoothZoom.center = {
		["mapID"] = container.mapID,
		["fromScale"] = container:GetCanvasScale(),
		["toScale"] = toScale,
		["fromX"] = container:GetCurrentScrollX() or 0.5,
		["fromY"] = container:GetCurrentScrollY() or 0.5,
		["toX"] = toX,
		["toY"] = toY,
		["time"] = 0,
		["oneMap"] = true,
		["glide"] = true,
		["onDone"] = onDone,
	}
	if not MapUtils:GetConfig("ONEMAPTRANSITIONS", false) then SmoothZoom.StepCenter(container, SmoothZoom.centerDuration) end

	return true
end

function SmoothZoom.GlideInto(container, target)
	if not MapUtils:GetConfig("ONEMAPTRANSITIONS", false) then return false end
	if container == nil or not SmoothZoom.CanSwitch(container) then return false end
	local hostLeft, hostRight, hostTop, hostBottom = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	local space = MapUtils:GetZoneDetailSpace(container.mapID)
	local left, right, top, bottom = SmoothZoom.RectOn(target, space)
	local width, height = container.Child:GetSize()
	if hostLeft == nil or left == nil or hostRight <= hostLeft or hostBottom <= hostTop or width == nil or width <= 0 or height == nil or height <= 0 then return false end
	local l = hostLeft + left * (hostRight - hostLeft)
	local r = hostLeft + right * (hostRight - hostLeft)
	local t = hostTop + top * (hostBottom - hostTop)
	local b = hostTop + bottom * (hostBottom - hostTop)
	if r <= l or b <= t then return false end
	local scale = math.min(container:GetWidth() / ((r - l) * width), container:GetHeight() / ((b - t) * height))

	return SmoothZoom.Glide(
		container,
		scale,
		(l + r) / 2,
		(t + b) / 2,
		function()
			if not SmoothZoom.Switch(container, target, true) then
				MapLevelZoom.lastSwitch = GetTime()
				frame:SetMapID(target)
			end

			SmoothZoom.userMoved = false
		end
	)
end

function SmoothZoom.GlideOut(container)
	if container == nil or not MapUtils:IsOneMap() or InCombatLockdown() or container.zoomLevels == nil then return false end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return false end
	local parent = MapUtils.GetZoneDetailCityZone ~= nil and MapUtils:GetZoneDetailCityZone(container.mapID) or nil
	if parent == nil and not SmoothZoom.CanSwitch(container) then return false end
	parent = parent or SmoothZoom.GetParent(container.mapID)
	if parent == nil then return false end
	SmoothZoom.anim = nil
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	if not SmoothZoom.Switch(container, parent, true) then return false end
	SmoothZoom.userMoved = false

	return SmoothZoom.Glide(container, container:GetScaleForMinZoom(), 0.5, 0.5)
end

function MapUtils:GlideToMap(mapID, x, y)
	local container = WheelZoom.container
	if frame == nil or container == nil or mapID == nil or IsLocked() then return false end
	if not SmoothZoom.CanSwitch(container) or not SmoothZoom.IsSpace(mapID) then return false end
	if container.mapID == mapID and x == nil then return false end
	SmoothZoom.anim = nil
	SmoothZoom.center = nil
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	if container.mapID ~= mapID and not SmoothZoom.Switch(container, mapID, true) then return false end
	SmoothZoom.userMoved = false
	SmoothZoom.dragMapID = nil
	local minScale = container:GetScaleForMinZoom()
	if x == nil or y == nil then return SmoothZoom.Glide(container, minScale, 0.5, 0.5) end

	return SmoothZoom.Glide(container, math.max(container:GetCanvasScale(), minScale), x, y)
end

function SmoothZoom.CheckPick(container, finishedDrag)
	if not finishedDrag and GetTime() - SmoothZoom.lastCheck < SmoothZoom.checkInterval then return end
	SmoothZoom.lastCheck = GetTime()
	if not SmoothZoom.CanSwitch(container) or (not finishedDrag and not SmoothZoom.IsSettled(container)) then return end
	if SmoothZoom.pickMapID ~= container.mapID then
		SmoothZoom.pickMapID = container.mapID
		SmoothZoom.userMoved = false
	end

	if not SmoothZoom.userMoved and not finishedDrag then return end
	local pick = SmoothZoom.PickMap(container)
	if pick ~= nil and pick ~= container.mapID and (SmoothZoom.IsSpace(pick) or MapUtils:GetZoneDetailCityZone(pick) ~= nil) then SmoothZoom.Switch(container, pick, finishedDrag) end
end

function SmoothZoom.Step(container, elapsed)
	local anim = SmoothZoom.anim
	if anim == nil then return end
	if anim.mapID ~= container.mapID or not container:IsVisible() then
		SmoothZoom.anim = nil

		return
	end

	local scale = anim.scale or container:GetCanvasScale()
	local panning = container.mouseButtonInfo and container.mouseButtonInfo.LeftButton and container.mouseButtonInfo.LeftButton.down or false
	if panning then
		local offsetX, offsetY = SmoothZoom.CursorOffset(container)
		if offsetX ~= nil then
			local x, y = container:GetCurrentScrollX(), container:GetCurrentScrollY()
			if not anim.dragging and x ~= nil and y ~= nil then anim.anchorX, anim.anchorY = x + offsetX / scale, y + offsetY / scale end
			anim.offsetX, anim.offsetY = offsetX, offsetY
		end

		anim.startScale, anim.correctX, anim.correctY = scale, nil, nil
	end

	anim.dragging = panning
	local share = 1 - math.exp(-(elapsed or 0) * SmoothZoom.speed)
	local nextScale = math.exp(math.log(scale) + (math.log(anim.target) - math.log(scale)) * share)
	if math.abs(math.log(anim.target / nextScale)) < SmoothZoom.snapLog then
		nextScale = anim.target
		SmoothZoom.anim = nil
	end

	anim.startScale = anim.startScale or scale
	anim.scale = nextScale
	local x, y = anim.anchorX - anim.offsetX / nextScale, anim.anchorY - anim.offsetY / nextScale
	if anim.target < anim.startScale and not panning then
		if anim.correctX == nil then
			local minX, maxX, minY, maxY = SmoothZoom.GetExtents(container, anim.target)
			local finalX, finalY = anim.anchorX - anim.offsetX / anim.target, anim.anchorY - anim.offsetY / anim.target
			anim.correctX, anim.correctY = Clamp(finalX, minX, maxX) - finalX, Clamp(finalY, minY, maxY) - finalY
		end

		local progress = Clamp(math.log(nextScale / anim.startScale) / math.log(anim.target / anim.startScale), 0, 1)
		x, y = x + anim.correctX * progress, y + anim.correctY * progress
	end

	SmoothZoom.SetView(container, nextScale, x, y, nextScale, x, y, anim.preserveCityScale)
end

function SmoothZoom.SyncWheelMode(container)
	if container.SetMouseWheelZoomMode == nil or MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE == nil then return end
	if MapUtils:IsOneMap() then
		if container.mouseWheelZoomMode ~= MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE then
			SmoothZoom.blizzardWheelMode = container.mouseWheelZoomMode
			container:SetMouseWheelZoomMode(MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE)
		end
	elseif SmoothZoom.blizzardWheelMode ~= nil then
		container:SetMouseWheelZoomMode(SmoothZoom.blizzardWheelMode)
		SmoothZoom.blizzardWheelMode = nil
	end
end

function SmoothZoom.CanPan(container)
	return container.mapID ~= nil
end

function SmoothZoom.SyncCanPan(container)
	if MapUtils:IsOneMap() then
		if container.CanPan ~= SmoothZoom.CanPan then
			SmoothZoom.blizzardCanPan = container.CanPan
			container.CanPan = SmoothZoom.CanPan
		end
	elseif SmoothZoom.blizzardCanPan ~= nil then
		container.CanPan = SmoothZoom.blizzardCanPan
		SmoothZoom.blizzardCanPan = nil
	end
end

function SmoothZoom.IsGamepad()
	return C_InputInterfaceStyle ~= nil and InputUtil ~= nil and InputUtil.IsGamepadUIEnabled ~= nil and InputUtil.IsGamepadUIEnabled() == true
end

function SmoothZoom.OnUpdate(container, elapsed)
	if SmoothZoom.IsGamepad() then return end
	local panning = container.mouseButtonInfo and container.mouseButtonInfo.LeftButton and container.mouseButtonInfo.LeftButton.down
	local finishedDrag = not panning and SmoothZoom.dragMapID ~= nil and SmoothZoom.dragMapID == container.mapID
	if panning then
		SmoothZoom.dragMapID = container.mapID
		SmoothZoom.userMoved = true
		SmoothZoom.zoomingOut = false
	else
		SmoothZoom.dragMapID = nil
	end
	SmoothZoom.SyncWheelMode(container)
	SmoothZoom.SyncCanPan(container)
	SmoothZoom.WidenExtents(container)
	if SmoothZoom.center ~= nil then
		if panning or SmoothZoom.anim ~= nil then
			SmoothZoom.center = nil
		else
			SmoothZoom.StepCenter(container, elapsed)

			return
		end
	end

	if SmoothZoom.anim ~= nil then
		SmoothZoom.Step(container, elapsed)

		return
	end

	SmoothZoom.CheckPick(container, finishedDrag)
end

function SmoothZoom.CursorOffset(container)
	local width, height = container.Child:GetSize()
	local left, bottom, viewWidth, viewHeight = container:GetRect()
	local effective = container:GetEffectiveScale()
	if width == nil or width <= 0 or height == nil or height <= 0 or left == nil or effective == nil or effective <= 0 then return nil end
	local cursorX, cursorY = GetCursorPosition()
	cursorX, cursorY = cursorX / effective, cursorY / effective

	return (cursorX - (left + viewWidth / 2)) / width, ((bottom + viewHeight / 2) - cursorY) / height
end

function SmoothZoom.CursorAnchor(container)
	local scale = container:GetCanvasScale()
	local scrollX, scrollY = container:GetCurrentScrollX(), container:GetCurrentScrollY()
	if scrollX == nil or scrollY == nil or scale == nil or scale <= 0 then return nil end
	local playerX, playerY = MapUtils:GetFollowZoomAnchor(container)
	if playerX ~= nil then return playerX, playerY, scale, scrollX, scrollY end
	local offsetX, offsetY = SmoothZoom.CursorOffset(container)
	if offsetX == nil then return nil end

	return scrollX + offsetX / scale, scrollY + offsetY / scale, scale, scrollX, scrollY
end

function SmoothZoom.LeaveCity(container, delta, base)
	if delta >= 0 or not MapUtils:IsOneMap() or InCombatLockdown() or MapUtils.GetZoneDetailCityZone == nil then return false end
	if base * SmoothZoom.factor ^ delta >= container:GetScaleForMinZoom() * 1.001 then return false end
	local zone = MapUtils:GetZoneDetailCityZone(container.mapID)
	if zone == nil then return false end
	SmoothZoom.anim = nil

	return SmoothZoom.Switch(container, zone)
end

function MapUtils:GetOneMapZoomPercent()
	local container = WheelZoom.container
	if container == nil or not MapUtils:IsOneMap() or not SmoothZoom.IsSpace(container.mapID) then return nil end
	local left, right = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	local width, view = container.Child:GetWidth(), container:GetWidth()
	if left == nil or right <= left or width == nil or width <= 0 or view == nil or view <= 0 then return nil end
	local share = container:GetCanvasScale() * width * (right - left) / view

	return Clamp(math.log(math.max(share, 1)) / math.log(SmoothZoom.pinZoomRange), 0, 1)
end

function MapUtils:IsSmoothZooming()
	return SmoothZoom.anim ~= nil or SmoothZoom.center ~= nil
end

function SmoothZoom.OnMouseWheel(container, delta)
	if not MapUtils:IsOneMap() or container.zoomLevels == nil or container.mapID == nil then return end
	if WheelZoom.installed and (not IsEnabled("WORLDMAPZOOM") or WheelZoom.foreignTime == GetTime()) then return end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return end
	SmoothZoom.userMoved = true
	SmoothZoom.zoomingOut = delta < 0
	local currentX, currentY = container:GetCurrentScrollX(), container:GetCurrentScrollY()
	if currentX ~= nil and currentY ~= nil then
		container.targetScale = container:GetCanvasScale()
		container.zoomTarget = container.targetScale
		container.targetScrollX, container.targetScrollY = currentX, currentY
	end

	local anim = SmoothZoom.anim
	if anim ~= nil and anim.mapID ~= container.mapID then anim = nil end
	local base = anim and anim.target or container:GetCanvasScale()
	local before = container:GetCanvasScale()
	if SmoothZoom.LeaveCity(container, delta, base) then base = base * container:GetCanvasScale() / before end
	local cursorX, cursorY, scale, scrollX, scrollY = SmoothZoom.CursorAnchor(container)
	if cursorX == nil then return end
	local minScale, maxScale = SmoothZoom.GetMinScale(container), SmoothZoom.GetMaxScale(container, cursorX, cursorY)
	local city = MapUtils:GetZoneDetailCityZone(container.mapID) ~= nil
	if delta > 0 then maxScale = math.max(maxScale, base) end
	if delta < 0 or city then minScale = math.min(minScale, base) end
	local target = Clamp(base * SmoothZoom.factor ^ delta, minScale, maxScale)
	if target <= 0 then return end
	WheelZoom.pending = nil
	container.targetScale = scale
	container.zoomTarget = scale
	container.targetScrollX, container.targetScrollY = scrollX, scrollY
	SmoothZoom.anim = {
		["mapID"] = container.mapID,
		["target"] = target,
		["preserveCityScale"] = city,
		["anchorX"] = cursorX,
		["anchorY"] = cursorY,
		["offsetX"] = (cursorX - scrollX) * scale,
		["offsetY"] = (cursorY - scrollY) * scale,
		["scale"] = scale,
	}
end

local CombatPins = {
	waiting = setmetatable({}, {
		__mode = "k"
	}),
	seen = setmetatable({}, {
		__mode = "k"
	}),
}

function CombatPins.IsGamepad()
	return C_InputInterfaceStyle ~= nil or InputUtil ~= nil and InputUtil.IsGamepadUIEnabled ~= nil and InputUtil.IsGamepadUIEnabled() == true
end

function CombatPins.Wait(pin, key, ...)
	local entry = CombatPins.waiting[pin] or {}
	CombatPins.waiting[pin] = entry
	entry[key] = {
		["n"] = select("#", ...),
		...
	}
end

function CombatPins.Done(pin, key)
	local entry = CombatPins.waiting[pin]
	if entry == nil then return end
	entry[key] = nil
	if entry.passthrough == nil and entry.propagation == nil then CombatPins.waiting[pin] = nil end
end

function CombatPins.Passthrough(pin, ...)
	if InCombatLockdown() then return CombatPins.Wait(pin, "passthrough", ...) end
	CombatPins.Done(pin, "passthrough")

	return CombatPins.passthrough(pin, ...)
end

function CombatPins.Propagation(pin, ...)
	if InCombatLockdown() then return CombatPins.Wait(pin, "propagation", ...) end
	CombatPins.Done(pin, "propagation")

	return CombatPins.propagation(pin, ...)
end

function CombatPins.Point(value)
	if type(value) ~= "table" then return end
	local ok, method = pcall(rawget, value, "CheckMouseButtonPassthrough")
	if ok and method == CombatPins.passthrough then value.CheckMouseButtonPassthrough = CombatPins.Passthrough end
	if CombatPins.propagation ~= nil then
		ok, method = pcall(rawget, value, "UpdateMousePropagation")
		if ok and method == CombatPins.propagation then value.UpdateMousePropagation = CombatPins.Propagation end
	end
end

function CombatPins.PointPool(pool)
	if CombatPins.IsGamepad() then return end
	for _, enumerate in ipairs({"EnumerateActive", "EnumerateInactive"}) do
		if type(pool[enumerate]) == "function" then
			local ok, iterator, state, start = pcall(pool[enumerate], pool)
			if ok and iterator then
				for pin in iterator, state, start do
					CombatPins.Point(pin)
				end
			end
		end
	end
end

function CombatPins.ScanPools()
	if CombatPins.IsGamepad() then return end
	for _, pool in pairs(frame.pinPools or {}) do
		if not CombatPins.seen[pool] then
			CombatPins.seen[pool] = true
			CombatPins.PointPool(pool)
		end
	end
end

function CombatPins.Sweep()
	CombatPins.sweepSoon = false
	if CombatPins.IsGamepad() then return end
	for _, value in pairs(_G) do
		CombatPins.Point(value)
	end

	for _, pool in pairs(frame.pinPools or {}) do
		CombatPins.PointPool(pool)
	end
end

function CombatPins.Flush()
	if InCombatLockdown() then return end
	for pin, entry in pairs(CombatPins.waiting) do
		CombatPins.waiting[pin] = nil
		if pin.IsForbidden ~= nil and not pin:IsForbidden() and (pin.GetMap == nil or pin:GetMap() ~= nil) then
			if entry.passthrough then pcall(CombatPins.passthrough, pin, unpack(entry.passthrough, 1, entry.passthrough.n)) end
			if entry.propagation then pcall(CombatPins.propagation, pin, unpack(entry.propagation, 1, entry.propagation.n)) end
		end
	end
end

function MapUtils:InstallCombatPins()
	if CombatPins.installed or frame == nil or CombatPins.IsGamepad() then return end
	CombatPins.passthrough = MapCanvasPinMixin and MapCanvasPinMixin.CheckMouseButtonPassthrough
	if type(CombatPins.passthrough) ~= "function" then return end
	local propagation = SuperTrackablePinMixin and SuperTrackablePinMixin.UpdateMousePropagation
	CombatPins.propagation = type(propagation) == "function" and propagation or nil
	CombatPins.installed = true
	CombatPins.Sweep()
	CombatPins.ScanPools()
	frame:HookScript("OnShow", function() for _, pool in pairs(frame.pinPools or {}) do CombatPins.PointPool(pool) end end)
	if frame.ScrollContainer ~= nil and frame.ScrollContainer.MarkCanvasDirty ~= nil then hooksecurefunc(frame.ScrollContainer, "MarkCanvasDirty", MapUtils.Profile("mapframe CombatPins ScanPools", CombatPins.ScanPools)) end
	CombatPins.events = CreateFrame("Frame")
	CombatPins.events:RegisterEvent("ADDON_LOADED")
	CombatPins.events:RegisterEvent("PLAYER_REGEN_ENABLED")
	CombatPins.events:SetScript(
		"OnEvent",
		function(_, event)
			if event == "PLAYER_REGEN_ENABLED" then
				CombatPins.Flush()
			elseif not CombatPins.sweepSoon then
				CombatPins.sweepSoon = true
				C_Timer.After(0, CombatPins.Sweep)
			end
		end
	)
end

function SmoothZoom.ScaledCursorPosition(container)
	local x, y = GetCursorPosition()
	local effective = container:GetEffectiveScale()
	if effective == nil or effective <= 0 then return x, y end

	return x / effective, y / effective
end

function SmoothZoom.CanvasCursor(container)
	local child = container and container.Child
	local scale = container and container:GetCanvasScale()
	local left, top = child and child:GetLeft(), child and child:GetTop()
	local width, height = child and child:GetWidth(), child and child:GetHeight()
	if scale == nil or scale <= 0 or left == nil or top == nil or width == nil or width <= 0 or height == nil or height <= 0 then return nil end
	local x, y = SmoothZoom.ScaledCursorPosition(container)

	return (x / scale - left) / width, (top - y / scale) / height
end

function MapUtils:GetOneMapCursor()
	return SmoothZoom.CanvasCursor(WorldMapFrame and WorldMapFrame.ScrollContainer)
end

function SmoothZoom.InstallCursorFix()
	local container = WheelZoom.container
	if container == nil or type(container.GetCursorPosition) ~= "function" or MapUtils:IsForever() then return end
	container.GetCursorPosition = SmoothZoom.ScaledCursorPosition
end

function SmoothZoom.InstallSpokenPlacesDragGuard()
	local places = _G.SpokenPlaces
	local container = WheelZoom.container
	if container == nil or places == nil or type(places.AreaAt) ~= "function" then return end

	local startX, startY, dragged
	local function CheckDrag()
		local x, y = GetCursorPosition()
		local scale = container:GetEffectiveScale()
		local dx, dy = x - startX, y - startY
		dragged = dragged or dx * dx + dy * dy > 20 * scale * scale
		return dragged
	end

	container:HookScript("OnMouseDown", function(_, button)
		if button ~= "LeftButton" then return end
		startX, startY = GetCursorPosition()
		dragged = false
	end)
	container:HookScript("OnUpdate", function()
		if startX == nil then return end
		if IsMouseButtonDown("LeftButton") then
			CheckDrag()
		else
			startX = nil
		end
	end)
	container:HookScript("OnHide", function() startX = nil end)

	local areaAt = places.AreaAt
	places.AreaAt = function(self, ...)
		if startX ~= nil and not IsMouseButtonDown("LeftButton") and CheckDrag() then return nil end

		return areaAt(self, ...)
	end
end

function MapUtils:GetUnitMapPosition(unit)
	if C_Map == nil or C_Map.GetBestMapForUnit == nil or C_Map.GetPlayerMapPosition == nil then return nil end
	local mapID = C_Map.GetBestMapForUnit(unit)
	if mapID == nil or MapUtils:IsSecret(mapID) then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, unit)
	if pos == nil then return nil end
	local x, y = pos:GetXY()
	if x == nil or y == nil or MapUtils:IsSecret(x) or MapUtils:IsSecret(y) or (x == 0 and y == 0) then return nil end

	return mapID, x, y
end

function MapUtils:CenterWorldMapOnUnit(unit, follow)
	local container = WheelZoom.container
	if frame == nil or container == nil or IsLocked() then return false end
	if follow and (SmoothZoom.anim ~= nil or SmoothZoom.center ~= nil or WheelZoom.pending ~= nil or IsMouseButtonDown("LeftButton")) then return false end
	local mapID, x, y = MapUtils:GetUnitMapPosition(unit)
	if mapID == nil then return false end
	local shown = frame:GetMapID()
	if follow and shown ~= nil and shown ~= mapID then
		local pos = C_Map.GetPlayerMapPosition(shown, unit)
		local px, py
		if pos ~= nil then px, py = pos:GetXY() end
		if px ~= nil and py ~= nil and not MapUtils:IsSecret(px) and not MapUtils:IsSecret(py) and px >= 0 and px <= 1 and py >= 0 and py <= 1 and (px ~= 0 or py ~= 0) then mapID, x, y = shown, px, py end
	end

	local instant = follow and shown == mapID
	if instant and math.abs(container:GetNormalizedHorizontalScroll() - x) < 0.0001 and math.abs(container:GetNormalizedVerticalScroll() - y) < 0.0001 then return true end
	SmoothZoom.anim = nil
	SmoothZoom.center = nil
	WheelZoom.pending = nil
	local switched = false
	if frame:GetMapID() ~= mapID and SmoothZoom.CanSwitch(container) and SmoothZoom.IsSpace(mapID) then
		MapLevelZoom.lastSwitch = GetTime()
		switched = SmoothZoom.Switch(container, mapID, true)
	end

	if frame:GetMapID() ~= mapID then
		MapLevelZoom.lastSwitch = GetTime()
		WheelZoom.own = true
		frame:SetMapID(mapID)
		WheelZoom.own = false
		if frame:GetMapID() ~= mapID then return false end
	end

	local scale = container:GetCanvasScale()
	local center = {
		["mapID"] = mapID,
		["fromScale"] = scale,
		["toScale"] = scale,
		["fromX"] = container:GetNormalizedHorizontalScroll(),
		["fromY"] = container:GetNormalizedVerticalScroll(),
		["toX"] = x,
		["toY"] = y,
		["time"] = 0,
	}

	if MapUtils:IsOneMap() and container.zoomLevels ~= nil and SmoothZoom.IsSpace(mapID) then
		SmoothZoom.pickMapID = mapID
		SmoothZoom.userMoved = false
		SmoothZoom.dragMapID = nil
		center.oneMap = true
		if switched then
			center.glide = true
			center.fromX, center.fromY = container:GetCurrentScrollX() or center.fromX, container:GetCurrentScrollY() or center.fromY
			if not follow then center.toScale = math.max(scale, container:GetScaleForMinZoom()) end
		end
	else
		if container.InstantPanAndZoom == nil then return false end
		local minScale = container.GetScaleForMinZoom and container:GetScaleForMinZoom()
		local maxScale = container.GetScaleForMaxZoom and container:GetScaleForMaxZoom()
		if not follow and minScale ~= nil and maxScale ~= nil and scale <= minScale + SCALE_EPSILON then center.toScale = maxScale end
	end

	if instant then center.time = SmoothZoom.centerDuration end
	SmoothZoom.center = center
	if not MapLevelZoom.installed or (switched and not MapUtils:GetConfig("ONEMAPTRANSITIONS", false)) then SmoothZoom.StepCenter(container, SmoothZoom.centerDuration) end

	return true
end

function SmoothZoom.StepCenter(container, elapsed)
	local center = SmoothZoom.center
	if center == nil then return end
	if center.mapID ~= container.mapID or not container:IsVisible() then
		SmoothZoom.center = nil

		return
	end

	center.time = center.time + (elapsed or 0)
	local t = math.min(center.time / SmoothZoom.centerDuration, 1)
	local share = 1 - (1 - t) ^ 3
	local scale = math.exp(math.log(center.fromScale) + (math.log(center.toScale) - math.log(center.fromScale)) * share)
	local x = center.fromX + (center.toX - center.fromX) * share
	local y = center.fromY + (center.toY - center.fromY) * share
	if t >= 1 then SmoothZoom.center = nil end
	if center.oneMap then
		SmoothZoom.SetView(container, scale, x, y, scale, x, y, center.glide)
		SmoothZoom.ShowLoadedArt()
		if MapUtils.UpdateWorldPinsNow ~= nil then MapUtils.UpdateWorldPinsNow() end
	else
		WheelZoom.own = true
		container:InstantPanAndZoom(scale, x, y)
		WheelZoom.own = false
	end

	if t >= 1 and center.onDone ~= nil then center.onDone() end
end

function MapLevelZoom.Install()
	local container = WheelZoom.container
	if MapLevelZoom.installed or container == nil then return end
	MapLevelZoom.installed = true
	container:HookScript("OnUpdate", MapUtils.Profile("mapframe MapLevelZoom OnUpdate", MapLevelZoom.OnUpdate))
	container:HookScript("OnMouseWheel", MapLevelZoom.OnMouseWheel)
	container:HookScript("OnUpdate", MapUtils.Profile("mapframe SmoothZoom OnUpdate", SmoothZoom.OnUpdate))
	container:HookScript("OnMouseWheel", SmoothZoom.OnMouseWheel)
	if frame ~= nil and frame.AddCanvasClickHandler ~= nil then frame:AddCanvasClickHandler(SmoothZoom.OnCanvasClick, 100) end
end

local MapView = {}
function MapView.ReleaseMap()
	if C_InputInterfaceStyle == nil or not MapUtils:IsForever() or frame == nil or frame.mapID == nil or MapUtil == nil or MapUtil.GetDisplayableMapForPlayer == nil then return end
	local released = MapUtil.GetDisplayableMapForPlayer() == 947 and 1414 or 947
	if frame:GetMapID() == released then return end
	frame.mapID = released
	if WheelZoom.container ~= nil then WheelZoom.container.zoomTarget = nil end
end

function MapView.Save()
	local container = WheelZoom.container
	local mode = MapUtils:GetMapViewMode()
	if mode == "PLAYER" or container == nil or container.mapID == nil then
		MapView.saved = nil

		return
	end

	local scale = container.targetScale or container:GetCanvasScale()
	local x = container.targetScrollX or container:GetCurrentScrollX()
	local y = container.targetScrollY or container:GetCurrentScrollY()
	local anim = SmoothZoom.anim
	if anim ~= nil and anim.mapID == container.mapID and anim.target ~= nil and anim.target > 0 then
		scale = anim.target
		x, y = anim.anchorX - anim.offsetX / scale, anim.anchorY - anim.offsetY / scale
	end

	if scale == nil or scale <= 0 or x == nil or y == nil then
		MapView.saved = nil

		return
	end

	if mode == "ZOOM" then
		local minScale = container:GetScaleForMinZoom()
		MapView.saved = minScale ~= nil and minScale > 0 and {
			["zoom"] = scale / minScale,
		} or nil

		return
	end

	MapView.saved = {
		["mapID"] = container.mapID,
		["scale"] = scale,
		["x"] = x,
		["y"] = y,
	}
end

MapView.guardTime = 0.5
function MapView.ApplyZoom(container, zoom)
	local mapID = container.mapID
	local minScale = mapID and container:GetScaleForMinZoom()
	if minScale == nil or minScale <= 0 then return end
	local x, y = 0.5, 0.5
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if pos ~= nil then
		local px, py = pos:GetXY()
		if px ~= nil and py ~= nil and (px ~= 0 or py ~= 0) then x, y = px, py end
	end

	local scale = minScale * zoom
	SmoothZoom.pickMapID = mapID
	SmoothZoom.SetView(container, scale, x, y, scale, x, y)
	SmoothZoom.userMoved = false
	if MapUtils.UpdateWorldPinsNow ~= nil then MapUtils.UpdateWorldPinsNow() end
end

function MapView.Apply()
	local saved = MapView.pending
	local container = WheelZoom.container
	if saved == nil or MapView.applying or not container:IsVisible() then return end
	if GetTime() > MapView.guardUntil or SmoothZoom.userMoved or InCombatLockdown() then
		MapView.pending = nil

		return
	end

	MapView.applying = true
	SmoothZoom.anim = nil
	WheelZoom.pending = nil
	if saved.zoom ~= nil then
		MapView.ApplyZoom(container, saved.zoom)
		MapView.applying = false

		return
	end

	if container.mapID ~= saved.mapID then
		MapLevelZoom.lastSwitch = GetTime()
		WheelZoom.own = true
		frame:SetMapID(saved.mapID)
		WheelZoom.own = false
	end

	if container.mapID == saved.mapID then
		SmoothZoom.pickMapID = saved.mapID
		SmoothZoom.SetView(container, saved.scale, saved.x, saved.y, saved.scale, saved.x, saved.y)
		SmoothZoom.userMoved = false
		if MapUtils.UpdateWorldPinsNow ~= nil then MapUtils.UpdateWorldPinsNow() end
	else
		MapView.pending = nil
	end

	MapView.applying = false
end

function MapView.OnResetZoom()
	local pending = MapView.pending
	if pending ~= nil and not MapView.applying and (pending.zoom ~= nil or WheelZoom.container.mapID == pending.mapID) then MapView.Apply() end
end

function MapView.Restore()
	local saved = MapView.saved
	MapView.pending = nil
	if saved == nil or SmoothZoom.IsGamepad() then return end
	local mode = MapUtils:GetMapViewMode()
	if mode == "PLAYER" or (mode == "ZOOM") ~= (saved.zoom ~= nil) then return end
	if InCombatLockdown() or IsInInstance() or (saved.zoom == nil and C_Map.GetMapInfo(saved.mapID) == nil) then return end
	MapView.pending = saved
	MapView.guardUntil = GetTime() + MapView.guardTime
	SmoothZoom.userMoved = false
	MapView.Apply()
	C_Timer.After(0, MapView.Apply)
	C_Timer.After(0.1, MapView.Apply)
end

if frame ~= nil and WheelZoom.container ~= nil then
	frame:HookScript("OnHide", function()
		MapView.pending = nil
		MapView.Save()
		MapView.ReleaseMap()
	end)

	frame:HookScript("OnShow", MapView.Restore)
	if WheelZoom.container.ResetZoom ~= nil then hooksecurefunc(WheelZoom.container, "ResetZoom", MapView.OnResetZoom) end
end

MapLevelZoom.loader = CreateFrame("Frame")
MapLevelZoom.loader:RegisterEvent("PLAYER_LOGIN")
MapLevelZoom.loader:SetScript("OnEvent", function(sel)
	sel:UnregisterAllEvents()
	SmoothZoom.InstallCursorFix()
	SmoothZoom.InstallSpokenPlacesDragGuard()
	C_Timer.After(WheelZoom.installDelay, MapLevelZoom.Install)
	MapUtils:InstallCombatPins()
end)
MapUtils.ProfileTable("SmoothZoom", SmoothZoom)
MapUtils.ProfileTable("MapLevelZoom", MapLevelZoom)
MapUtils.ProfileTable("WheelZoom", WheelZoom)
MapUtils.ProfileTable("CombatPins", CombatPins)
MapUtils.ProfileTable("MapView", MapView)
