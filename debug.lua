local _, MapUtils = ...
local UPDATE_INTERVAL = 0.05
local OFFSET_X = 18
local OFFSET_Y = -8
local debugging = false
local display = nil
local updater = nil
local waypointWindow = nil
local function GetDebugWaypoint()
	if C_Map == nil or C_Map.GetUserWaypoint == nil then return nil end
	local point = C_Map.GetUserWaypoint()
	if point == nil or point.position == nil then return nil end

	return point
end

local function RefreshWaypointWindow()
	if waypointWindow == nil then return end
	local window = waypointWindow
	local point = GetDebugWaypoint()
	local enabled = point ~= nil and C_Map.SetUserWaypoint ~= nil
	window.syncing = true
	if enabled then
		local x, y = point.position.x, point.position.y
		window.coordinates:SetText(format("uiMapID: %s\nX: %.3f   Y: %.3f\nZ: %s", tostring(point.uiMapID), x * 100, y * 100, point.z ~= nil and format("%.2f", point.z) or "—"))
		local z = point.z or 0
		window.slider:SetMinMaxValues(math.min(-2000, z), math.max(2000, z))
		window.slider:SetValue(z)
		if not window.input:HasFocus() then window.input:SetText(format("%.2f", z)) end
		window.slider:Enable()
		window.input:Enable()
	else
		window.coordinates:SetText("Kein World-Map-Pin gesetzt")
		window.slider:Disable()
		window.input:Disable()
		window.input:ClearFocus()
		window.input:SetText("")
	end

	window.slider:SetAlpha(enabled and 1 or 0.4)
	window.input:SetAlpha(enabled and 1 or 0.4)
	window.syncing = false
end

local function SetWaypointHeight(value)
	if waypointWindow == nil or waypointWindow.syncing then return end
	if value == nil or value ~= value or value == math.huge or value == -math.huge then return end
	local point = GetDebugWaypoint()
	if point == nil or C_Map.SetUserWaypoint == nil then return end
	local replacement = {uiMapID = point.uiMapID, position = {x = point.position.x, y = point.position.y}, z = value}
	local wasSet = C_Map.SetUserWaypoint(replacement)
	local actual = GetDebugWaypoint()
	if wasSet ~= false and actual ~= nil and actual.z ~= nil and math.abs(actual.z - value) < 0.01 then
		waypointWindow.status:SetText(MapUtils:IsForever() and "Z gespeichert; Weltmarker bleibt clientgesteuert" or "Wegpunkt-Z gespeichert")
	else
		waypointWindow.status:SetText("Client übernimmt den Wegpunkt-Z nicht")
	end
	RefreshWaypointWindow()
end

local function CreateWaypointWindow()
	if waypointWindow ~= nil then return waypointWindow end
	local window = CreateFrame("Frame", "MapUtilsDebugWaypointWindow", WorldMapFrame, "BasicFrameTemplateWithInset")
	waypointWindow = window
	window:SetSize(360, 220)
	window:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 8, 0)
	window:SetClampedToScreen(true)
	window:SetFrameStrata("DIALOG")
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window.TitleText:SetText("MapUtils Debug – World-Map-Pin")
	window.coordinates = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	window.coordinates:SetPoint("TOPLEFT", 16, -38)
	window.coordinates:SetJustifyH("LEFT")
	local label = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 16, -108)
	label:SetText("Höhe (Z)")
	window.slider = CreateFrame("Slider", nil, window, "OptionsSliderTemplate")
	window.slider:SetPoint("TOPLEFT", 20, -140)
	window.slider:SetSize(180, 17)
	window.slider:SetMinMaxValues(-2000, 2000)
	window.slider:SetValueStep(1)
	if window.slider.SetObeyStepOnDrag ~= nil then window.slider:SetObeyStepOnDrag(true) end
	window.slider.Low:SetText("")
	window.slider.High:SetText("")
	window.slider:SetScript("OnValueChanged", function(_, value) SetWaypointHeight(value) end)
	window.input = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
	window.input:SetSize(82, 24)
	window.input:SetPoint("LEFT", window.slider, "RIGHT", 12, 0)
	window.status = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	window.status:SetPoint("TOPLEFT", 16, -185)
	window.status:SetJustifyH("LEFT")
	if MapUtils:IsForever() then window.status:SetText("Forever: Z steuert nicht die Weltmarker-Höhe") end
	window.input:SetAutoFocus(false)
	window.input:SetMaxLetters(16)
	window.input:SetScript("OnEnterPressed", function(self)
		local text = self:GetText():gsub(",", ".")
		local value = tonumber(text)
		self:ClearFocus()
		SetWaypointHeight(value)
		RefreshWaypointWindow()
	end)
	window.input:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		RefreshWaypointWindow()
	end)
	window.input:SetScript("OnEditFocusLost", function() RefreshWaypointWindow() end)
	window:Hide()

	return window
end

local function CreateDisplay()
	if display ~= nil then return display end
	display = CreateFrame("FRAME", nil, UIParent)
	display:SetFrameStrata("TOOLTIP")
	display:SetSize(1, 1)
	display.text = display:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	display.text:SetPoint("TOPLEFT")
	display.text:SetJustifyH("LEFT")
	local font, size = display.text:GetFont()
	if font ~= nil then display.text:SetFont(font, size, "OUTLINE") end
	display:Hide()

	return display
end

local function GetCursorMapPos()
	if WorldMapFrame == nil then return nil end
	local container = WorldMapFrame.ScrollContainer
	if container == nil or container.GetNormalizedCursorPosition == nil then return nil end
	local x, y = container:GetNormalizedCursorPosition()
	if x == nil or y == nil then return nil end
	if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

	return x, y
end

local function Update()
	if display == nil then return end
	if not debugging or WorldMapFrame == nil or WorldMapFrame:IsShown() ~= true then
		display:Hide()

		return
	end

	RefreshWaypointWindow()
	local x, y = GetCursorMapPos()
	if x == nil then
		display:Hide()

		return
	end

	local mapID = WorldMapFrame:GetMapID()
	display.text:SetText(format("uiMapID: %s\n%.3f, %.3f", tostring(mapID), x * 100, y * 100))
	display:SetSize(display.text:GetStringWidth(), display.text:GetStringHeight())
	local scale = UIParent:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	display:ClearAllPoints()
	display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale + OFFSET_X, cy / scale + OFFSET_Y)
	display:Show()
end

local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < UPDATE_INTERVAL then return end
	self.elapsed = 0
	Update()
end

local function GetUpdater()
	if updater ~= nil then return updater end
	if WorldMapFrame == nil then return nil end
	updater = CreateFrame("FRAME", nil, WorldMapFrame)
	updater.elapsed = 0

	return updater
end

function MapUtils:PrintPlayerPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	if pos ~= nil then
		local x, y = pos:GetXY()
		MapUtils:INFO(format("uiMapID: %s  %.3f, %.3f", tostring(mapID), x * 100, y * 100))
	else
		MapUtils:INFO(format("uiMapID: %s  no map position", tostring(mapID)))
	end

	local wy, wx, wz, instanceID = UnitPosition("player")
	if wx ~= nil then
		MapUtils:INFO(format("World: x %.2f, y %.2f, z %.2f, instanceID %s", wx, wy, wz or 0, tostring(instanceID)))
	else
		MapUtils:INFO("World position not available here")
	end
end

function MapUtils:IsDebug()
	return debugging
end

function MapUtils:ToggleDebug()
	debugging = not debugging
	CreateDisplay()
	local frame = GetUpdater()
	if frame == nil then
		debugging = false
		MapUtils:INFO("No WorldMapFrame, debug mode not available")

		return
	end

	if debugging then
		CreateWaypointWindow():Show()
		RefreshWaypointWindow()
		frame.elapsed = 0
		frame:SetScript("OnUpdate", OnUpdate)
		MapUtils:INFO("Debug mode on - the cursor shows uiMapID and coordinates while the world map is open, off again after a /reload")
	else
		frame:SetScript("OnUpdate", nil)
		display:Hide()
		if waypointWindow ~= nil then waypointWindow:Hide() end
		MapUtils:INFO("Debug mode off")
	end
end
