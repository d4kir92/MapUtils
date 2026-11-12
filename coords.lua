local _, MapUtils = ...
local updater
function MapUtils:HasCoordsCVar(cvar)
	local getter = C_CVar and C_CVar.GetCVar or GetCVar
	return getter ~= nil and getter(cvar) ~= nil
end

function MapUtils:GetCoordsOptionDefault(cvar)
	return cvar ~= "coordsByTenths"
end

function MapUtils:IsCoordsOptionEnabled(cvar)
	if MapUtils:HasCoordsCVar(cvar) then
		local getter = C_CVar and C_CVar.GetCVarBool or GetCVarBool
		return getter ~= nil and getter(cvar) == true
	end

	return MapUtils:GetConfig(strupper(cvar), MapUtils:GetCoordsOptionDefault(cvar)) == true
end

local function IsEnabled(key)
	return MapUtils:IsCoordsOptionEnabled(key)
end

local state = {optionsTime = -1, optionsInterval = 0.5, version = 0, last = {}}
local function ReadOptions()
	local now = GetTime()
	if now - state.optionsTime < state.optionsInterval then return end
	state.optionsTime = now
	local enabled = true
	local cursorOn = IsEnabled("worldMapShowCursorCoords")
	local playerOn = IsEnabled("worldMapShowPlayerCoords")
	local tenths = IsEnabled("coordsByTenths")
	local widget = MapUtils:GetConfig("COORDSSTYLE", "WIDGET") ~= "POSITION"
	if enabled ~= state.enabled or cursorOn ~= state.cursorOn or playerOn ~= state.playerOn or tenths ~= state.tenths or widget ~= state.widget then
		state.enabled, state.cursorOn, state.playerOn, state.tenths, state.widget = enabled, cursorOn, playerOn, tenths, widget
		state.version = state.version + 1
	end
end

local function FormatCoords(x, y)
	if state.tenths then return format("%.1f, %.1f", x * 100, y * 100) end

	return format("%d, %d", math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5))
end

local function RefreshWidget()
	local widget = updater.widget
	local editing = MapUtils.IsMapEditMode ~= nil and MapUtils:IsMapEditMode()
	local shown = state.widget and (state.playerOn or state.cursorOn or editing)
	widget:SetShown(shown == true)
	if not shown then return end
	local vertical = widget.element ~= nil and MapUtils.GetMapEditOrientation ~= nil and MapUtils:GetMapEditOrientation(widget.element) == "VERTICAL"
	local width, height = 0, 0
	local previous
	for _, key in ipairs({"player", "cursor"}) do
		local text = widget[key]
		local on = editing or key == "player" and state.playerOn or key == "cursor" and state.cursorOn
		text:SetShown(on)
		if on then
			text:ClearAllPoints()
			widget.measure:SetText(format("|cffffd100%s|r %s", MapUtils:Trans(key == "player" and "LID_COORDSPLAYER" or "LID_COORDSCURSOR"), state.tenths and "100.0, 100.0" or "100, 100"))
			local w, h = math.ceil(widget.measure:GetStringWidth()) + 2, text:GetStringHeight()
			text:SetWidth(w)
			if previous == nil then
				text:SetPoint("TOPLEFT", widget, "TOPLEFT", 8, -4)
				width, height = w, h
			elseif vertical then
				text:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
				width, height = math.max(width, w), height + h + 2
			else
				text:SetPoint("LEFT", previous, "RIGHT", 12, 0)
				width, height = width + w + 12, math.max(height, h)
			end

			previous = text
		end
	end

	widget:SetSize(math.max(40, width + 16), height + 8)
end

local function LayoutWidget()
	local widget = updater and updater.widget
	if widget == nil then return end
	local toggle = WorldMapFrame.SidePanelToggle
	if toggle ~= nil and MapUtils:GetConfig("COORDSWIDGET_POINT", nil) == nil then
		local scale = widget:GetScale()
		widget:ClearAllPoints()
		widget:SetPoint("BOTTOM", WorldMapFrame.ScrollContainer, "BOTTOM", 0, 14 / scale)
		widget:SetPoint("RIGHT", toggle, "LEFT", -8 / scale, 0)
	end

	RefreshWidget()
end

local function ShowCoords(key, x, y, px, py, width, height, offsetY)
	local valid = x ~= nil and y ~= nil and px ~= nil and py ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1
	if state.widget then
		updater[key]:Hide()
		local text = format("|cffffd100%s|r %s", MapUtils:Trans(key == "player" and "LID_COORDSPLAYER" or "LID_COORDSCURSOR"), valid and FormatCoords(x, y) or "-")
		local label = updater.widget[key]
		if label:GetText() ~= text then label:SetText(text) end

		return
	end

	local label = updater[key]
	if not valid then
		label:Hide()
		return
	end

	label:ClearAllPoints()
	label:SetPoint("CENTER", updater, "TOPLEFT", width * math.max(0.1, math.min(0.9, px)), -height * math.max(0.1, math.min(0.9, py + offsetY)))
	local text = FormatCoords(x, y)
	if label:GetText() ~= text then label:SetText(text) end
	label:Show()
end

local playerPos = {}
local linearMaps = {}
local function IsLinearMap(mapID)
	if linearMaps[mapID] == nil then
		local info = C_Map.GetMapInfo(mapID)
		local continentType = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
		linearMaps[mapID] = info ~= nil and info.mapType ~= nil and info.mapType >= continentType
	end

	return linearMaps[mapID]
end

local function GetPlayerPos(mapID)
	if mapID == nil then return nil end
	local wy, wx = UnitPosition("player")
	if wx == nil or wx ~= playerPos.wx or wy ~= playerPos.wy or mapID ~= playerPos.mapID then
		playerPos.x, playerPos.y = nil, nil
		if MapUtils.GetPlayerMapPos ~= nil and IsLinearMap(mapID) then playerPos.x, playerPos.y = MapUtils.GetPlayerMapPos(mapID) end
		if playerPos.x == nil then
			local pos = C_Map.GetPlayerMapPosition(mapID, "player")
			if pos ~= nil then playerPos.x, playerPos.y = pos:GetXY() end
		end
		playerPos.wx, playerPos.wy, playerPos.mapID = wx, wy, mapID
	end

	return playerPos.x, playerPos.y
end

local nativePanel
local nativeSearched = false
local nativeAlpha
local function RefreshNativeCoords(enabled)
	if not nativeSearched and WorldMapFrame ~= nil then
		nativeSearched = true
		for _, frame in ipairs({WorldMapFrame:GetChildren()}) do
			if frame.PlayerCoords ~= nil and frame.CursorCoords ~= nil then
				nativePanel = frame
				break
			end
		end
	end

	if nativePanel == nil then return end
	if enabled then
		if nativeAlpha == nil then nativeAlpha = nativePanel:GetAlpha() end
		if nativePanel:GetAlpha() ~= 0 then nativePanel:SetAlpha(0) end
	elseif nativeAlpha ~= nil then
		nativePanel:SetAlpha(nativeAlpha)
		nativeAlpha = nil
	end
end

local function HideAll()
	ShowCoords("player")
	ShowCoords("cursor")
	updater.widget:Hide()
	state.last.version = nil
end

local function RefreshCursor(scroll, width, height, scrollScale, scrollLeft, scrollTop, viewChanged)
	local last = state.last
	if not state.cursorOn or scroll.GetNormalizedCursorPosition == nil or not scroll:IsMouseOver() then
		if last.cx ~= nil then
			ShowCoords("cursor")
			last.cx, last.cy = nil, nil
		end

		return
	end

	local cx, cy = GetCursorPosition()
	if not viewChanged and cx == last.cx and cy == last.cy then return end
	last.cx, last.cy = cx, cy
	local x, y = scroll:GetNormalizedCursorPosition()
	local px, py = (cx / scrollScale - scrollLeft) / width, (scrollTop - cy / scrollScale) / height
	if px >= 0 and px <= 1 and py >= 0 and py <= 1 then
		ShowCoords("cursor", x, y, px, py, width, height, -0.1)
	else
		ShowCoords("cursor")
	end
end

local function RefreshPlayer(child, mapID, width, height, scrollScale, childScale, scrollLeft, scrollTop, viewChanged)
	local last = state.last
	if not state.playerOn or C_Map == nil or C_Map.GetPlayerMapPosition == nil then
		ShowCoords("player")
		last.wx, last.wy = nil, nil

		return
	end

	local wy, wx = UnitPosition("player")
	if not viewChanged and wx ~= nil and wx == last.wx and wy == last.wy then return end
	last.wx, last.wy = wx, wy
	local x, y = GetPlayerPos(mapID)
	local left, top = child:GetLeft(), child:GetTop()
	local childWidth, childHeight = child:GetSize()
	if x == nil or y == nil or left == nil or top == nil or childWidth == nil or childHeight == nil then
		ShowCoords("player")

		return
	end

	local scale = childScale / scrollScale
	local px = (left * scale - scrollLeft + x * childWidth * scale) / width
	local py = (scrollTop - top * scale + y * childHeight * scale) / height
	if px >= 0 and px <= 1 and py >= 0 and py <= 1 then
		ShowCoords("player", x, y, px, py, width, height, 0.1)
	else
		ShowCoords("player")
	end
end

function MapUtils:RefreshCoords()
	if updater == nil then return end
	ReadOptions()
	RefreshNativeCoords(state.enabled)
	if not state.enabled then
		HideAll()

		return
	end

	local map = WorldMapFrame
	local scroll = map.ScrollContainer
	local child = scroll.Child
	local width, height = scroll:GetSize()
	local scrollScale = scroll:GetEffectiveScale()
	local childScale = child and child:GetEffectiveScale()
	local scrollLeft, scrollTop = scroll:GetLeft(), scroll:GetTop()
	if child == nil or width == nil or height == nil or width <= 0 or height <= 0 or scrollScale == nil or scrollScale <= 0 or childScale == nil or childScale <= 0 or scrollLeft == nil or scrollTop == nil then
		HideAll()

		return
	end

	local left, top = child:GetLeft(), child:GetTop()
	local mapID = map:GetMapID()
	local last = state.last
	local viewChanged = last.version ~= state.version or last.mapID ~= mapID or last.width ~= width or last.height ~= height or last.scrollScale ~= scrollScale or last.childScale ~= childScale or last.scrollLeft ~= scrollLeft or last.scrollTop ~= scrollTop or last.left ~= left or last.top ~= top
	if viewChanged then
		last.version, last.mapID, last.width, last.height = state.version, mapID, width, height
		last.scrollScale, last.childScale, last.scrollLeft, last.scrollTop, last.left, last.top = scrollScale, childScale, scrollLeft, scrollTop, left, top
	end

	RefreshCursor(scroll, width, height, scrollScale, scrollLeft, scrollTop, viewChanged)
	RefreshPlayer(child, mapID, width, height, scrollScale, childScale, scrollLeft, scrollTop, viewChanged)
	if viewChanged then RefreshWidget() end
end

local function InitCoords()
	if updater ~= nil or WorldMapFrame == nil or WorldMapFrame.ScrollContainer == nil then return end
	updater = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
	updater:SetAllPoints()
	updater:SetFrameLevel(WorldMapFrame.ScrollContainer:GetFrameLevel() + 100)
	updater:EnableMouse(false)
	for _, key in ipairs({"player", "cursor"}) do
		updater[key] = updater:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		updater[key]:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
		updater[key]:Hide()
	end

	local widget = CreateFrame("Frame", nil, updater)
	widget:SetSize(40, 20)
	widget:EnableMouse(false)
	widget:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT", -4, 4)

	for _, key in ipairs({"player", "cursor"}) do
		widget[key] = widget:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		widget[key]:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
		widget[key]:SetJustifyH("LEFT")
		widget[key]:SetWordWrap(false)
		widget[key]:SetText(format("|cffffd100%s|r -", MapUtils:Trans(key == "player" and "LID_COORDSPLAYER" or "LID_COORDSCURSOR")))
	end

	widget.measure = widget:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	widget.measure:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
	widget.measure:Hide()
	widget:Hide()
	updater.widget = widget
	if MapUtils.RegisterMapEditElement ~= nil then
		widget.element = {
			key = "COORDSWIDGET",
			title = "LID_COORDSWIDGET",
			frame = widget,
			defaultPoint = {"BOTTOMRIGHT", -14, 14},
			defaultAlign = "RIGHT",
			defaultOrientation = "HORIZONTAL",
			options = {
				orientation = true,
				scale = true
			},
			OnLayout = LayoutWidget,
			OnEditMode = LayoutWidget,
		}

		MapUtils:RegisterMapEditElement(widget.element)
	end

	updater:SetScript("OnShow", function()
		ShowCoords("player")
		ShowCoords("cursor")
		state.last = {}
		state.optionsTime = -1
	end)
	updater:SetScript("OnUpdate", MapUtils.Profile("coords OnUpdate", function() MapUtils:RefreshCoords() end))
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", InitCoords)
