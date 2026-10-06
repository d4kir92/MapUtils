local _, MapUtils = ...
local updater
local function IsEnabled(key)
	local getter = C_CVar and C_CVar.GetCVarBool or GetCVarBool
	return getter ~= nil and getter(key) == true
end

local function ShowCoords(label, x, y, px, py, width, height)
	if x == nil or y == nil or px == nil or py == nil or x < 0 or x > 1 or y < 0 or y > 1 then
		label:Hide()
		return
	end

	label:ClearAllPoints()
	label:SetPoint("CENTER", updater, "TOPLEFT", width * math.max(0.1, math.min(0.9, px)), -height * math.max(0.1, math.min(0.9, py + 0.1)))
	local text
	if IsEnabled("coordsByTenths") then
		text = format("%.1f, %.1f", x * 100, y * 100)
	else
		text = format("%d, %d", math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5))
	end

	if label:GetText() ~= text then label:SetText(text) end
	label:Show()
end

local nativePanel
local nativeAlpha
local function RefreshNativeCoords(enabled)
	if nativePanel == nil and WorldMapFrame ~= nil then
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

function MapUtils:RefreshCoords()
	if updater == nil then return end
	updater.player:Hide()
	updater.cursor:Hide()
	local enabled = MapUtils:GetConfig("COORDSIMPROVEMENTS", true) == true
	RefreshNativeCoords(enabled)
	if not enabled then return end
	local map = WorldMapFrame
	local scroll = map.ScrollContainer
	local child = scroll.Child
	local width, height = scroll:GetSize()
	if width == nil or height == nil or width <= 0 or height <= 0 then return end
	if child == nil then return end
	local childWidth, childHeight = child:GetSize()
	if childWidth == nil or childHeight == nil or childWidth <= 0 or childHeight <= 0 then return end
	local scrollScale, childScale = scroll:GetEffectiveScale(), child:GetEffectiveScale()
	if scrollScale == nil or childScale == nil or scrollScale <= 0 or childScale <= 0 then return end
	if IsEnabled("worldMapShowCursorCoords") and scroll.GetNormalizedCursorPosition ~= nil then
		local x, y = scroll:GetNormalizedCursorPosition()
		local cx, cy = GetCursorPosition()
		local scale = scrollScale
		local left, top = scroll:GetLeft(), scroll:GetTop()
		if left ~= nil and top ~= nil then
			local px, py = (cx / scale - left) / width, (top - cy / scale) / height
			if px >= 0 and px <= 1 and py >= 0 and py <= 1 then ShowCoords(updater.cursor, x, y, px, py, width, height) end
		end
	end

	if IsEnabled("worldMapShowPlayerCoords") and C_Map and C_Map.GetPlayerMapPosition and child ~= nil then
		local mapID = map:GetMapID()
		local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
		if pos ~= nil then
			local x, y = pos:GetXY()
			local scale = childScale / scrollScale
			local left, top = child:GetLeft(), child:GetTop()
			local scrollLeft, scrollTop = scroll:GetLeft(), scroll:GetTop()
			if left ~= nil and top ~= nil and scrollLeft ~= nil and scrollTop ~= nil then
				local px = (left * scale - scrollLeft + x * childWidth * scale) / width
				local py = (scrollTop - top * scale + y * childHeight * scale) / height
				if px >= 0 and px <= 1 and py >= 0 and py <= 1 then ShowCoords(updater.player, x, y, px, py, width, height) end
			end
		end
	end
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

	local elapsedTotal = 0
	updater:SetScript("OnShow", function()
		elapsedTotal = 0
		updater.player:Hide()
		updater.cursor:Hide()
	end)
	updater:SetScript("OnUpdate", function(_, elapsed)
		elapsedTotal = elapsedTotal + elapsed
		if elapsedTotal < 0.05 then return end
		elapsedTotal = 0
		MapUtils:RefreshCoords()
	end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", InitCoords)
