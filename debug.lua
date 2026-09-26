local _, MapUtils = ...
local UPDATE_INTERVAL = 0.05
local OFFSET_X = 18
local OFFSET_Y = -8
local debugging = false
local display = nil
local updater = nil
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
		frame.elapsed = 0
		frame:SetScript("OnUpdate", OnUpdate)
		MapUtils:INFO("Debug mode on - the cursor shows uiMapID and coordinates while the world map is open, off again after a /reload")
	else
		frame:SetScript("OnUpdate", nil)
		display:Hide()
		MapUtils:INFO("Debug mode off")
	end
end
