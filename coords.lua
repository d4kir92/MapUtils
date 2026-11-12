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
	local enabled = MapUtils:GetConfig("COORDSIMPROVEMENTS", true) == true or not MapUtils:HasCoordsCVar("worldMapShowPlayerCoords")
	local cursorOn = IsEnabled("worldMapShowCursorCoords")
	local playerOn = IsEnabled("worldMapShowPlayerCoords")
	local tenths = IsEnabled("coordsByTenths")
	if enabled ~= state.enabled or cursorOn ~= state.cursorOn or playerOn ~= state.playerOn or tenths ~= state.tenths then
		state.enabled, state.cursorOn, state.playerOn, state.tenths = enabled, cursorOn, playerOn, tenths
		state.version = state.version + 1
	end
end

local function ShowCoords(label, x, y, px, py, width, height, offsetY)
	if x == nil or y == nil or px == nil or py == nil or x < 0 or x > 1 or y < 0 or y > 1 then
		label:Hide()
		return
	end

	label:ClearAllPoints()
	label:SetPoint("CENTER", updater, "TOPLEFT", width * math.max(0.1, math.min(0.9, px)), -height * math.max(0.1, math.min(0.9, py + offsetY)))
	local text
	if state.tenths then
		text = format("%.1f, %.1f", x * 100, y * 100)
	else
		text = format("%d, %d", math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5))
	end

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
	updater.player:Hide()
	updater.cursor:Hide()
	state.last.version = nil
end

local function RefreshCursor(scroll, width, height, scrollScale, scrollLeft, scrollTop, viewChanged)
	local last = state.last
	if not state.cursorOn or scroll.GetNormalizedCursorPosition == nil or not scroll:IsMouseOver() then
		if last.cx ~= nil then
			updater.cursor:Hide()
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
		ShowCoords(updater.cursor, x, y, px, py, width, height, -0.1)
	else
		updater.cursor:Hide()
	end
end

local function RefreshPlayer(child, mapID, width, height, scrollScale, childScale, scrollLeft, scrollTop, viewChanged)
	local last = state.last
	if not state.playerOn or C_Map == nil or C_Map.GetPlayerMapPosition == nil then
		updater.player:Hide()
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
		updater.player:Hide()

		return
	end

	local scale = childScale / scrollScale
	local px = (left * scale - scrollLeft + x * childWidth * scale) / width
	local py = (scrollTop - top * scale + y * childHeight * scale) / height
	if px >= 0 and px <= 1 and py >= 0 and py <= 1 then
		ShowCoords(updater.player, x, y, px, py, width, height, 0.1)
	else
		updater.player:Hide()
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

	updater:SetScript("OnShow", function()
		updater.player:Hide()
		updater.cursor:Hide()
		state.last = {}
		state.optionsTime = -1
	end)
	updater:SetScript("OnUpdate", MapUtils.Profile("coords OnUpdate", function() MapUtils:RefreshCoords() end))
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", InitCoords)
