local _, MapUtils = ...
local MIN_SCALE = 0.5
local MAX_SCALE = 2
local SCALE_EPSILON = 0.001
local GRIP_SIZE = 26
local frame = WorldMapFrame
local ready = false
local foreign = false
local foreignMove = false
local applying = false
local dragging = false
local wasClamped = false
local sizing = nil
local lastScale = 1
local blizzardPoint = nil
local grip = nil
local scrollBarsShifted = false
local fader = nil
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
	return not foreignMove and IsEnabled("WORLDMAPMOVE")
end

local function ScaleEnabled()
	return IsEnabled("WORLDMAPSCALE")
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

local function ClampPos(left, top)
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	w = w * s
	h = h * s
	left = max(0, min(left, UIParent:GetWidth() - w))
	top = min(UIParent:GetHeight(), max(top, h))

	return left, top
end

local function SetScale(value)
	lastScale = value
	if math.abs(frame:GetScale() - value) > SCALE_EPSILON then frame:SetScale(value) end
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

local function UpdateGrip()
	if grip == nil then return end
	if foreign or not ScaleEnabled() or IsMaximized() then
		grip:Hide()
		ShiftScrollBars(false)

		return
	end

	MapUtils:RaiseSizeGrip(grip, frame)
	grip:Show()
	ShiftScrollBars(true)
end

local function Apply()
	if not ready or applying or sizing ~= nil or dragging then return end
	if IsLocked() or CheckForeign() then return end
	applying = true
	if IsMaximized() then
		SetScale(1)
	else
		local scale = 1
		if ScaleEnabled() then scale = ClampScale(MAUTTAB["WORLDMAPSCALEVALUE"]) end
		local foreignLeft, foreignTop
		if foreignMove then foreignLeft, foreignTop = GetPos() end
		SetScale(scale)
		local pos = MAUTTAB["WORLDMAPPOS"]
		if foreignMove then
			if foreignLeft ~= nil then SetPos(foreignLeft, foreignTop) end
		elseif MoveEnabled() and type(pos) == "table" and pos.x ~= nil and pos.y ~= nil then
			SetPos(ClampPos(pos.x, pos.y))
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

local function OnDragStart()
	if not ready or IsMaximized() or IsLocked() or CheckForeign() or not MoveEnabled() then return end
	dragging = true
	wasClamped = frame:IsClampedToScreen()
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:StartMoving()
end

local function OnDragStop()
	if not dragging then return end
	frame:StopMovingOrSizing()
	frame:SetUserPlaced(false)
	frame:SetClampedToScreen(wasClamped == true)
	frame:SetMovable(false)
	dragging = false
	local left, top = GetPos()
	if left ~= nil then MapUtils:SV(MAUTTAB, "WORLDMAPPOS", {["x"] = left, ["y"] = top}) end
	Apply()
end

local function GetCursorUi()
	return MapUtils:GetCursorUi()
end

local function OnSizing()
	if sizing == nil then return end
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
end

local function StopSizing()
	if sizing == nil then return end
	sizing = nil
	grip:SetScript("OnUpdate", nil)
	grip:SetButtonState("NORMAL")
	MapUtils:SV(MAUTTAB, "WORLDMAPSCALEVALUE", lastScale)
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

	grip:SetButtonState("PUSHED", true)
	grip:SetScript("OnUpdate", OnSizing)
end

local function CreateGrip()
	grip = MapUtils:CreateSizeGrip(frame, GRIP_SIZE)
	grip:SetScript("OnMouseDown", StartSizing)
	grip:SetScript("OnMouseUp", StopSizing)
	grip:SetScript("OnHide", StopSizing)
	grip:Hide()
end

local function HookDrag(region)
	if region == nil or region.RegisterForDrag == nil or not region:IsMouseEnabled() then return end
	region:RegisterForDrag("LeftButton")
	region:HookScript("OnDragStart", OnDragStart)
	region:HookScript("OnDragStop", OnDragStop)
end

function MapUtils:PrintFadeDebug()
	if fader ~= nil then fader:Debug("WorldMap") end
	if MapUtils.PrintBattlefieldFadeDebug ~= nil then MapUtils:PrintBattlefieldFadeDebug() end
end

function MapUtils:IsWorldMapByMoveAny()
	return MapUtils:IsAddOnActive("MoveAny")
end

function MapUtils:RefreshWorldMapFrame()
	Apply()
	if fader ~= nil then fader:Reset() end
end

if frame ~= nil then
	CreateGrip()
	hooksecurefunc(frame, "SetPoint", OnBlizzardPoint)
	if frame.SynchronizeDisplayState ~= nil then hooksecurefunc(frame, "SynchronizeDisplayState", Apply) end
	frame:HookScript("OnShow", Apply)
	fader = MapUtils:CreateMoveFader(
		frame,
		{
			["isEnabled"] = function() return type(MAUTTAB) == "table" and MAUTTAB["WORLDMAPFADE"] ~= false end,
			["getOpacity"] = function() return MAUTTAB["WORLDMAPFADEOPACITY"] end,
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
			if MapUtils:IsWorldMapByMoveAny() then return end
			HookDrag(frame)
			for _, key in ipairs(dragRegions) do
				HookDrag(frame[key])
			end

			if frame.BorderFrame ~= nil then HookDrag(frame.BorderFrame.TitleContainer) end
			HookDrag(WorldMapTitleButton)
			ready = true
			if frame:IsShown() then Apply() end
		end
	)
end

function MapUtils:QuestCategoriesSearching()
	return QuestScrollFrame and QuestScrollFrame.SearchBox and QuestScrollFrame.SearchBox:GetText() ~= ""
end

function MapUtils:SaveQuestCategories()
	if not self.questCategoriesReady or self.restoringQuestCategories or self:QuestCategoriesSearching() then return end
	if not self:GetConfig("REMEMBERQUESTCATEGORIES", true) then return end
	MAUTTABPC = MAUTTABPC or {}
	MAUTTABPC.QUESTCATEGORIES = MAUTTABPC.QUESTCATEGORIES or {}
	for index = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(index)
		if info and info.isHeader then
			MAUTTABPC.QUESTCATEGORIES[info.headerSortKey or info.title] = info.isCollapsed == true
		end
	end
end

function MapUtils:RestoreQuestCategories()
	if self.restoringQuestCategories or self:QuestCategoriesSearching() then return end
	if not self:GetConfig("REMEMBERQUESTCATEGORIES", true) then return end
	local states = MAUTTABPC and MAUTTABPC.QUESTCATEGORIES
	self.restoringQuestCategories = true
	if states then
		for index = C_QuestLog.GetNumQuestLogEntries(), 1, -1 do
			local info = C_QuestLog.GetInfo(index)
			if info and info.isHeader then
				local collapsed = states[info.headerSortKey or info.title]
				if collapsed == true and not info.isCollapsed then
					CollapseQuestHeader(index)
				elseif collapsed == false and info.isCollapsed then
					ExpandQuestHeader(index)
				end
			end
		end
	end
	self.restoringQuestCategories = nil
	self.questCategoriesReady = true
	self:SaveQuestCategories()
end

if MapUtils:IsForever() and C_QuestLog and CollapseQuestHeader and ExpandQuestHeader then
	hooksecurefunc("CollapseQuestHeader", function() MapUtils:SaveQuestCategories() end)
	hooksecurefunc("ExpandQuestHeader", function() MapUtils:SaveQuestCategories() end)
	WorldMapFrame:HookScript("OnShow", function() MapUtils:RestoreQuestCategories() end)
	MapUtils.questCategoriesLoader = CreateFrame("Frame")
	MapUtils.questCategoriesLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
	MapUtils.questCategoriesLoader:SetScript("OnEvent", function()
		MapUtils.questCategoriesReady = nil
		C_Timer.After(0, function() MapUtils:RestoreQuestCategories() end)
	end)
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

function WheelZoom.OnMouseWheel(container, delta)
	if not IsEnabled("WORLDMAPZOOM") or MapUtils:IsOneMap() or container.zoomLevels == nil then return end
	if WheelZoom.foreignTime == GetTime() then return end
	local x, y = container:GetNormalizedCursorPosition()
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
		if type(container[method]) == "function" then hooksecurefunc(container, method, WheelZoom.MarkForeign) end
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
	local x, y = container:GetNormalizedCursorPosition()
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
	factor = 1.2,
	spaceZoom = 12,
	zoneZoom = 6,
	leave = 0.5,
	enterArea = 2,
	leaveArea = 3.3,
	enterContinentArea = 1.1,
	cityEnter = 0.85,
	zoneEnterCover = 0.95,
	parentFit = 0.8,
	leaveContinentArea = 1.8,
	checkInterval = 0.1,
	lastCheck = 0,
	speed = 12,
	snapLog = 0.002,
	settleEpsilon = 0.0005,
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

function SmoothZoom.GetMinScale(container)
	local minScale = container:GetScaleForMinZoom()
	local parent = SmoothZoom.IsSpace(container.mapID) and SmoothZoom.GetParent(container.mapID)
	if not parent then return minScale end
	local relaxed = minScale * SmoothZoom.leave
	local hostLeft, hostRight, hostTop, hostBottom = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	local space = MapUtils:GetZoneDetailSpace()
	local parentLeft, parentRight, parentTop, parentBottom = 0, 1, 0, 1
	if parent ~= space then parentLeft, parentRight, parentTop, parentBottom = C_Map.GetMapRectOnMap(parent, space) end
	local width, height = container.Child:GetSize()
	if hostLeft == nil or parentLeft == nil or width == nil or width <= 0 or height == nil or height <= 0 then return relaxed end
	local parentWidth = (parentRight - parentLeft) * (hostRight - hostLeft) * width
	local parentHeight = (parentBottom - parentTop) * (hostBottom - hostTop) * height
	if parentWidth <= 0 or parentHeight <= 0 then return relaxed end
	local fit = math.min(container:GetWidth() / parentWidth, container:GetHeight() / parentHeight)

	return math.min(relaxed, fit * SmoothZoom.parentFit)
end

function SmoothZoom.GetMaxScale(container)
	local maxScale = container:GetScaleForMaxZoom()
	if not SmoothZoom.IsSpace(container.mapID) then return maxScale end
	local info = C_Map.GetMapInfo(container.mapID)
	local zoom = (info and info.mapType == Enum.UIMapType.Zone) and SmoothZoom.zoneZoom or SmoothZoom.spaceZoom

	return math.max(maxScale, container:GetScaleForMinZoom() * zoom)
end

function SmoothZoom.GetPanRect(mapID)
	return MapUtils:GetZoneDetailSpaceRect(mapID)
end

function SmoothZoom.GetExtents(container, scale)
	local minX, maxX, minY, maxY = container:CalculateScrollExtentsAtScale(scale)
	if not SmoothZoom.IsSpace(container.mapID) then return minX, maxX, minY, maxY end
	local left, right, top, bottom = SmoothZoom.GetPanRect(container.mapID)
	local width, height = container.Child:GetSize()
	if left == nil or width == nil or width <= 0 or height == nil or height <= 0 then return minX, maxX, minY, maxY end
	local halfWidth = container:GetWidth() / (2 * scale * width)
	local halfHeight = container:GetHeight() / (2 * scale * height)
	minX, maxX = left + halfWidth, right - halfWidth
	minY, maxY = top + halfHeight, bottom - halfHeight
	if minX > maxX then minX, maxX = (left + right) / 2, (left + right) / 2 end
	if minY > maxY then minY, maxY = (top + bottom) / 2, (top + bottom) / 2 end

	return minX, maxX, minY, maxY
end

function SmoothZoom.WidenExtents(container)
	if not MapUtils:IsOneMap() or not SmoothZoom.IsSpace(container.mapID) then return end
	container.scrollXExtentsMin, container.scrollXExtentsMax, container.scrollYExtentsMin, container.scrollYExtentsMax = SmoothZoom.GetExtents(container, container:GetCanvasScale())
end

function SmoothZoom.SetView(container, scale, x, y, targetScale, targetX, targetY)
	local minScale, maxScale = SmoothZoom.GetMinScale(container), SmoothZoom.GetMaxScale(container)
	if SmoothZoom.IsSpace(container.mapID) then maxScale = math.max(maxScale, scale, targetScale) end
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
end

function SmoothZoom.Switch(container, target)
	local fromLeft, fromRight, fromTop, fromBottom = MapUtils:GetZoneDetailSpaceRect(container.mapID)
	if fromLeft == nil and MapUtils.GetZoneDetailRawRect ~= nil then fromLeft, fromRight, fromTop, fromBottom = MapUtils:GetZoneDetailRawRect(container.mapID) end
	local toLeft, toRight, toTop, toBottom = MapUtils:GetZoneDetailSpaceRect(target)
	if toLeft == nil and MapUtils.GetZoneDetailRawRect ~= nil then toLeft, toRight, toTop, toBottom = MapUtils:GetZoneDetailRawRect(target) end
	local layers = C_Map.GetMapArtLayers(target)
	local layer = layers and layers[1]
	local width = container.Child:GetWidth()
	if fromLeft == nil or toLeft == nil or layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 or width == nil or width <= 0 then return false end
	local factor = (fromRight - fromLeft) * width / ((toRight - toLeft) * layer.layerWidth)
	local function mapX(value) return toLeft + (value - fromLeft) / (fromRight - fromLeft) * (toRight - toLeft) end
	local function mapY(value) return toTop + (value - fromTop) / (fromBottom - fromTop) * (toBottom - toTop) end
	local scale = container:GetCanvasScale()
	local x, y = container:GetCurrentScrollX() or 0.5, container:GetCurrentScrollY() or 0.5
	local targetScale = container.targetScale or scale
	local targetX, targetY = container.targetScrollX or x, container.targetScrollY or y
	if SmoothZoom.anim ~= nil then targetScale, targetX, targetY = scale, x, y end
	MapLevelZoom.lastSwitch = GetTime()
	WheelZoom.pending = nil
	WheelZoom.own = true
	frame:SetMapID(target)
	WheelZoom.own = false
	if container.mapID ~= target then return false end
	SmoothZoom.SetView(container, scale * factor, mapX(x), mapY(y), targetScale * factor, mapX(targetX), mapY(targetY))
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
	local space = MapUtils:GetZoneDetailSpace()
	local function Fits(mapID, continent)
		local l, r, t, b = C_Map.GetMapRectOnMap(mapID, space)
		if l == nil or r <= l or b <= t then return false end
		local ratio = (viewWidth / (r - l)) * (viewHeight / (b - t))
		if continent then return ratio <= ((mapID == host or MapUtils:GetZoneDetailContinent(host) == mapID) and SmoothZoom.leaveContinentArea or SmoothZoom.enterContinentArea) end

		return ratio <= ((mapID == host) and SmoothZoom.leaveArea or SmoothZoom.enterArea)
	end

	local pick = space
	if u < 0 or u > 1 or v < 0 or v > 1 then return pick end
	local info = C_Map.GetMapInfoAtPosition(space, u, v)
	local continent = info and MapUtils:GetZoneDetailContinent(info.mapID)
	if continent == nil or not SmoothZoom.IsSpace(continent) or not Fits(continent, true) then return pick end
	pick = continent
	local l, r, t, b = C_Map.GetMapRectOnMap(continent, space)
	if l == nil or r <= l or b <= t then return pick end
	local zone = C_Map.GetMapInfoAtPosition(continent, (u - l) / (r - l), (v - t) / (b - t))
	local cover = (host ~= continent and host ~= space) and 1 or SmoothZoom.zoneEnterCover
	local continentVisible = viewWidth >= (r - l) * cover and viewHeight >= (b - t) * cover
	if zone ~= nil and zone.mapID ~= continent and zone.mapType == Enum.UIMapType.Zone and SmoothZoom.IsSpace(zone.mapID) and not continentVisible then pick = zone.mapID end
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

	if city ~= nil then
		local cl, cr, ct, cb = C_Map.GetMapRectOnMap(city, space)
		local halfWidth, halfHeight = viewWidth / 2, viewHeight / 2
		if cl ~= nil and viewWidth <= SmoothZoom.cityEnter * (cr - cl) and viewHeight <= SmoothZoom.cityEnter * (cb - ct) and u - halfWidth >= cl and u + halfWidth <= cr and v - halfHeight >= ct and v + halfHeight <= cb then pick = city end
	end

	return pick
end

function SmoothZoom.CheckPick(container)
	if GetTime() - SmoothZoom.lastCheck < SmoothZoom.checkInterval then return end
	SmoothZoom.lastCheck = GetTime()
	if not SmoothZoom.CanSwitch(container) or not SmoothZoom.IsSettled(container) then return end
	local pick = SmoothZoom.PickMap(container)
	if pick ~= nil and pick ~= container.mapID and (SmoothZoom.IsSpace(pick) or MapUtils:GetZoneDetailCityZone(pick) ~= nil) then SmoothZoom.Switch(container, pick) end
end

function SmoothZoom.Step(container, elapsed)
	local anim = SmoothZoom.anim
	if anim == nil then return end
	local panning = container.mouseButtonInfo and container.mouseButtonInfo.LeftButton and container.mouseButtonInfo.LeftButton.down
	if anim.mapID ~= container.mapID or panning or not container:IsVisible() then
		SmoothZoom.anim = nil

		return
	end

	local scale = anim.scale or container:GetCanvasScale()
	local share = 1 - math.exp(-(elapsed or 0) * SmoothZoom.speed)
	local nextScale = math.exp(math.log(scale) + (math.log(anim.target) - math.log(scale)) * share)
	if math.abs(math.log(anim.target / nextScale)) < SmoothZoom.snapLog then
		nextScale = anim.target
		SmoothZoom.anim = nil
	end

	anim.scale = nextScale
	local x, y = anim.anchorX - anim.offsetX / nextScale, anim.anchorY - anim.offsetY / nextScale
	SmoothZoom.SetView(container, nextScale, x, y, nextScale, x, y)
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
	if SmoothZoom.IsSpace(container.mapID) then return true end

	return container:GetCanvasScale() > (container.baseScale or 0)
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

function SmoothZoom.OnUpdate(container, elapsed)
	SmoothZoom.SyncWheelMode(container)
	SmoothZoom.SyncCanPan(container)
	SmoothZoom.WidenExtents(container)
	if SmoothZoom.anim ~= nil then
		SmoothZoom.Step(container, elapsed)

		return
	end

	SmoothZoom.CheckPick(container)
end

function SmoothZoom.CursorAnchor(container)
	local scale = container:GetCanvasScale()
	local scrollX, scrollY = container:GetCurrentScrollX(), container:GetCurrentScrollY()
	local width, height = container.Child:GetSize()
	local left, bottom, viewWidth, viewHeight = container:GetRect()
	local effective = container:GetEffectiveScale()
	if scrollX == nil or scrollY == nil or scale == nil or scale <= 0 or width == nil or width <= 0 or height == nil or height <= 0 or left == nil or effective == nil or effective <= 0 then return nil end
	local cursorX, cursorY = GetCursorPosition()
	cursorX, cursorY = cursorX / effective, cursorY / effective
	local offsetX = (cursorX - (left + viewWidth / 2)) / (scale * width)
	local offsetY = ((bottom + viewHeight / 2) - cursorY) / (scale * height)

	return scrollX + offsetX, scrollY + offsetY, scale, scrollX, scrollY
end

function SmoothZoom.LeaveToParent(container, delta, base)
	if delta >= 0 or not SmoothZoom.CanSwitch(container) then return false end
	if base * SmoothZoom.factor ^ delta >= SmoothZoom.GetMinScale(container) * 1.001 then return false end
	local parent = SmoothZoom.GetParent(container.mapID)
	if parent == nil then return false end
	SmoothZoom.anim = nil

	return SmoothZoom.Switch(container, parent)
end

function SmoothZoom.LeaveCity(container, delta, base)
	if delta >= 0 or not MapUtils:IsOneMap() or InCombatLockdown() or MapUtils.GetZoneDetailCityZone == nil then return false end
	if base * SmoothZoom.factor ^ delta >= container:GetScaleForMinZoom() * 1.001 then return false end
	local zone = MapUtils:GetZoneDetailCityZone(container.mapID)
	if zone == nil then return false end
	SmoothZoom.anim = nil

	return SmoothZoom.Switch(container, zone)
end

function SmoothZoom.OnMouseWheel(container, delta)
	if not MapUtils:IsOneMap() or container.zoomLevels == nil or container.mapID == nil then return end
	if WheelZoom.installed and (not IsEnabled("WORLDMAPZOOM") or WheelZoom.foreignTime == GetTime()) then return end
	if MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown() then return end
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
	if SmoothZoom.LeaveToParent(container, delta, base) or SmoothZoom.LeaveCity(container, delta, base) then base = base * container:GetCanvasScale() / before end
	local minScale, maxScale = SmoothZoom.GetMinScale(container), SmoothZoom.GetMaxScale(container)
	if delta > 0 then maxScale = math.max(maxScale, base) else minScale = math.min(minScale, base) end
	local target = Clamp(base * SmoothZoom.factor ^ delta, minScale, maxScale)
	local cursorX, cursorY, scale, scrollX, scrollY = SmoothZoom.CursorAnchor(container)
	if cursorX == nil or target <= 0 then return end
	WheelZoom.pending = nil
	container.targetScale = scale
	container.zoomTarget = scale
	container.targetScrollX, container.targetScrollY = scrollX, scrollY
	SmoothZoom.anim = {
		["mapID"] = container.mapID,
		["target"] = target,
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
	for _, pool in pairs(frame.pinPools or {}) do
		if not CombatPins.seen[pool] then
			CombatPins.seen[pool] = true
			CombatPins.PointPool(pool)
		end
	end
end

function CombatPins.Sweep()
	CombatPins.sweepSoon = false
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
	if CombatPins.installed or frame == nil or not MapUtils:IsOneMap() then return end
	CombatPins.passthrough = MapCanvasPinMixin and MapCanvasPinMixin.CheckMouseButtonPassthrough
	if type(CombatPins.passthrough) ~= "function" then return end
	local propagation = SuperTrackablePinMixin and SuperTrackablePinMixin.UpdateMousePropagation
	CombatPins.propagation = type(propagation) == "function" and propagation or nil
	CombatPins.installed = true
	CombatPins.Sweep()
	CombatPins.ScanPools()
	frame:HookScript("OnShow", function() for _, pool in pairs(frame.pinPools or {}) do CombatPins.PointPool(pool) end end)
	if frame.ScrollContainer ~= nil and frame.ScrollContainer.MarkCanvasDirty ~= nil then hooksecurefunc(frame.ScrollContainer, "MarkCanvasDirty", CombatPins.ScanPools) end
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

function MapLevelZoom.Install()
	local container = WheelZoom.container
	if MapLevelZoom.installed or container == nil then return end
	MapLevelZoom.installed = true
	container:HookScript("OnUpdate", MapLevelZoom.OnUpdate)
	container:HookScript("OnMouseWheel", MapLevelZoom.OnMouseWheel)
	container:HookScript("OnUpdate", SmoothZoom.OnUpdate)
	container:HookScript("OnMouseWheel", SmoothZoom.OnMouseWheel)
end

MapLevelZoom.loader = CreateFrame("Frame")
MapLevelZoom.loader:RegisterEvent("PLAYER_LOGIN")
MapLevelZoom.loader:SetScript("OnEvent", function(sel)
	sel:UnregisterAllEvents()
	C_Timer.After(WheelZoom.installDelay, MapLevelZoom.Install)
	MapUtils:InstallCombatPins()
end)
