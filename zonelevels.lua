local _, MapUtils = ...
local zoneLevels = {}
zoneLevels[1411] = {1, 10}
zoneLevels[1412] = {1, 10}
zoneLevels[1413] = {10, 33}
zoneLevels[1416] = {27, 39}
zoneLevels[1417] = {30, 40}
zoneLevels[1418] = {36, 45}
zoneLevels[1419] = {46, 63}
zoneLevels[1420] = {1, 12}
zoneLevels[1421] = {10, 20}
zoneLevels[1422] = {46, 57}
zoneLevels[1423] = {54, 59}
zoneLevels[1424] = {20, 31}
zoneLevels[1425] = {41, 49}
zoneLevels[1426] = {1, 12}
zoneLevels[1427] = {43, 56}
zoneLevels[1428] = {50, 59}
zoneLevels[1429] = {1, 10}
zoneLevels[1430] = {50, 60}
zoneLevels[1431] = {10, 30}
zoneLevels[1432] = {10, 18}
zoneLevels[1433] = {15, 25}
zoneLevels[1434] = {30, 50}
zoneLevels[1435] = {36, 43}
zoneLevels[1436] = {9, 18}
zoneLevels[1437] = {20, 30}
zoneLevels[1438] = {1, 11}
zoneLevels[1439] = {11, 19}
zoneLevels[1440] = {19, 30}
zoneLevels[1441] = {24, 35}
zoneLevels[1442] = {15, 25}
zoneLevels[1443] = {30, 39}
zoneLevels[1444] = {41, 60}
zoneLevels[1445] = {36, 61}
zoneLevels[1446] = {40, 50}
zoneLevels[1447] = {42, 55}
zoneLevels[1448] = {47, 54}
zoneLevels[1449] = {48, 55}
zoneLevels[1450] = {15, 15}
zoneLevels[1451] = {55, 59}
zoneLevels[1452] = {55, 60}
zoneLevels[2482] = {60, 60}
zoneLevels[2521] = {1, 12}
zoneLevels[2548] = {35, 45}
zoneLevels[2652] = {35, 45}
local zoneRecLevels = {}
zoneRecLevels[1411] = 1
zoneRecLevels[1412] = 1
zoneRecLevels[1413] = 11
zoneRecLevels[1416] = 28
zoneRecLevels[1417] = 31
zoneRecLevels[1418] = 37
zoneRecLevels[1419] = 47
zoneRecLevels[1420] = 1
zoneRecLevels[1421] = 11
zoneRecLevels[1422] = 47
zoneRecLevels[1423] = 55
zoneRecLevels[1424] = 21
zoneRecLevels[1425] = 42
zoneRecLevels[1426] = 1
zoneRecLevels[1427] = 44
zoneRecLevels[1428] = 51
zoneRecLevels[1429] = 1
zoneRecLevels[1430] = 51
zoneRecLevels[1431] = 11
zoneRecLevels[1432] = 11
zoneRecLevels[1433] = 16
zoneRecLevels[1434] = 31
zoneRecLevels[1435] = 37
zoneRecLevels[1436] = 10
zoneRecLevels[1437] = 21
zoneRecLevels[1438] = 1
zoneRecLevels[1439] = 12
zoneRecLevels[1440] = 20
zoneRecLevels[1441] = 25
zoneRecLevels[1442] = 16
zoneRecLevels[1443] = 31
zoneRecLevels[1444] = 42
zoneRecLevels[1445] = 37
zoneRecLevels[1446] = 41
zoneRecLevels[1447] = 43
zoneRecLevels[1448] = 48
zoneRecLevels[1449] = 49
zoneRecLevels[1450] = 15
zoneRecLevels[1451] = 56
zoneRecLevels[1452] = 56
zoneRecLevels[2482] = 60
zoneRecLevels[2521] = 1
zoneRecLevels[2548] = 36
zoneRecLevels[2652] = 36
local zoneFishing = {}
zoneFishing[1411] = "1"
zoneFishing[1412] = "1"
zoneFishing[1413] = "1"
zoneFishing[1416] = "130"
zoneFishing[1417] = "130"
zoneFishing[1420] = "1"
zoneFishing[1421] = "1"
zoneFishing[1422] = "205"
zoneFishing[1423] = "330"
zoneFishing[1424] = "55"
zoneFishing[1425] = "205"
zoneFishing[1426] = "1"
zoneFishing[1428] = "330"
zoneFishing[1429] = "1"
zoneFishing[1430] = "330"
zoneFishing[1431] = "55"
zoneFishing[1432] = "1"
zoneFishing[1433] = "55"
zoneFishing[1434] = "130 (205)"
zoneFishing[1435] = "130"
zoneFishing[1436] = "1"
zoneFishing[1437] = "55"
zoneFishing[1438] = "1"
zoneFishing[1439] = "1"
zoneFishing[1440] = "55"
zoneFishing[1441] = "130"
zoneFishing[1442] = "55"
zoneFishing[1443] = "130"
zoneFishing[1444] = "205 (330)"
zoneFishing[1445] = "130"
zoneFishing[1446] = "205"
zoneFishing[1447] = "205 (330)"
zoneFishing[1448] = "205"
zoneFishing[1449] = "205"
zoneFishing[1450] = "205"
zoneFishing[1451] = "330"
zoneFishing[1452] = "330"
zoneFishing[1453] = "1"
zoneFishing[1454] = "1"
zoneFishing[1455] = "1"
zoneFishing[1456] = "1"
zoneFishing[1457] = "1"
zoneFishing[1458] = "1"
local function GetRangeText(levels)
	if levels[1] == levels[2] then return tostring(levels[1]) end

	return format("%d-%d", levels[1], levels[2])
end

local ZoneInfo = {
	inset = 14,
	lineSpacing = 2,
	levelOffset = 1000,
	justify = "LEFT",
}

function ZoneInfo.CreateText(frame, font)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	local path, size = text:GetFont()
	if path ~= nil and size ~= nil then text:SetFont(path, size, "OUTLINE") end
	text:SetJustifyH(ZoneInfo.justify)
	text:SetSpacing(ZoneInfo.lineSpacing)
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 1)

	return text
end

function ZoneInfo.Create()
	if ZoneInfo.frame ~= nil then return ZoneInfo.frame end
	local container = WorldMapFrame and WorldMapFrame.ScrollContainer
	if container == nil then return nil end
	local frame = CreateFrame("Frame", nil, WorldMapFrame)
	frame:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", ZoneInfo.inset, ZoneInfo.inset)
	frame:SetSize(1, 1)
	frame:SetFrameLevel(container:GetFrameLevel() + ZoneInfo.levelOffset)
	frame:EnableMouse(false)
	frame.title = ZoneInfo.CreateText(frame, "GameFontNormalLarge")
	frame.text = ZoneInfo.CreateText(frame, "GameFontHighlight")
	frame:Hide()
	ZoneInfo.frame = frame
	ZoneInfo.element = {
		key = "TOOLTIPWIDGET",
		title = "LID_TOOLTIPWIDGET",
		frame = frame,
		defaultPoint = {"BOTTOMLEFT", ZoneInfo.inset, ZoneInfo.inset},
		defaultAlign = "LEFT",
		OnLayout = ZoneInfo.Refresh,
		OnEditMode = ZoneInfo.Refresh,
	}

	if MapUtils.RegisterMapEditElement ~= nil then MapUtils:RegisterMapEditElement(ZoneInfo.element) end

	return frame
end

function ZoneInfo.GetZoneID(mapID)
	local container = WorldMapFrame.ScrollContainer
	if container == nil or not container:IsMouseOver() or WorldMapFrame.GetNormalizedCursorPosition == nil or C_Map.GetMapInfoAtPosition == nil then return mapID end
	local x, y = WorldMapFrame:GetNormalizedCursorPosition()
	if x == nil or y == nil then return mapID end
	local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
	if info == nil or info.mapID == nil then return mapID end

	return info.mapID
end

function ZoneInfo.GetTitle(zoneID, levelsOn)
	if zoneID == nil or C_Map.GetMapInfo == nil then return nil end
	local info = C_Map.GetMapInfo(zoneID)
	local name = info and info.name
	if name == nil or name == "" then return nil end
	local levels = zoneID and zoneLevels[zoneID]
	if levelsOn and levels ~= nil then name = format("%s %s(%s)|r", name, MapUtils:GetLevelColorCode(levels[1], levels[2]), GetRangeText(levels)) end

	return name
end

function ZoneInfo.GetLines(zoneID, recOn, fishingOn)
	local lines = {}
	local rec = zoneRecLevels[zoneID]
	if recOn and rec ~= nil then tinsert(lines, MapUtils:Trans("LID_RECOMMENDEDSTARTLEVEL", nil, rec)) end
	local fishing = zoneFishing[zoneID]
	if fishingOn and fishing ~= nil then tinsert(lines, MapUtils:Trans("LID_FISHINGLEVEL", nil, fishing)) end

	return lines
end

function ZoneInfo.GetZoneContent()
	local mapID = WorldMapFrame:GetMapID()
	local levelsOn = MapUtils:GetConfig("ZONELEVELS", true) == true
	local recOn = MapUtils:GetConfig("ZONERECLEVELS", true) == true
	local fishingOn = MapUtils:GetConfig("FISHINGLEVELS", true) == true
	local zoneID = mapID and ZoneInfo.GetZoneID(mapID)
	local title = ZoneInfo.GetTitle(zoneID, levelsOn)
	local lines = zoneID and ZoneInfo.GetLines(zoneID, recOn, fishingOn) or {}

	return title, table.concat(lines, "\n")
end

function ZoneInfo.Colorize(text, color)
	if color == nil or color.WrapTextInColorCode == nil then return text end

	return color:WrapTextInColorCode(text)
end

function ZoneInfo.GetLabelContent()
	local label = ZoneInfo.label
	if label == nil or MAP_AREA_LABEL_TYPE == nil or label.labelInfoByType == nil or label.GetHighestPriorityLabelInfo == nil then return nil end
	local info = label:GetHighestPriorityLabelInfo()
	if info == nil or info.name == nil or info.name == "" or info == label.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME] then return nil end
	local description = info.description
	if type(description) == "function" then description = description() end
	if type(description) ~= "string" or description == "" then return ZoneInfo.Colorize(info.name, info.nameColor), "" end

	return ZoneInfo.Colorize(info.name, info.nameColor), ZoneInfo.Colorize(description, info.descriptionColor)
end

function ZoneInfo.GetSample()
	local levels = {10, 20}
	local title = format("%s %s(%s)|r", MapUtils:Trans("LID_ZONENAMESAMPLE"), MapUtils:GetLevelColorCode(levels[1], levels[2]), GetRangeText(levels))
	local lines = {MapUtils:Trans("LID_RECOMMENDEDSTARTLEVEL", nil, levels[1]), MapUtils:Trans("LID_FISHINGLEVEL", nil, "75")}

	return title, table.concat(lines, "\n")
end

function ZoneInfo.Refresh()
	ZoneInfo.key = nil
	ZoneInfo.Update()
end

function ZoneInfo.Update()
	local frame = ZoneInfo.Create()
	if frame == nil then return end
	local title, body = ZoneInfo.GetLabelContent()
	if title == nil then title, body = ZoneInfo.GetZoneContent() end
	body = body or ""
	if MapUtils.IsMapEditElementVisible ~= nil and not MapUtils:IsMapEditElementVisible(ZoneInfo.element) then
		ZoneInfo.key = nil
		frame:Hide()

		return
	end

	if MapUtils.IsMapEditMode ~= nil and MapUtils:IsMapEditMode() then title, body = ZoneInfo.GetSample() end
	local align = MapUtils.GetMapEditAlign ~= nil and MapUtils:GetMapEditAlign(ZoneInfo.element) or "LEFT"
	local key = format("%s|%s|%s", tostring(title), body, align)
	if ZoneInfo.key == key then return end
	ZoneInfo.key = key
	if title == nil and body == "" then
		frame:Hide()

		return
	end

	local side = align == "CENTER" and "" or align
	frame.text:SetJustifyH(align)
	frame.text:SetText("")
	frame.text:SetText(body)
	frame.text:ClearAllPoints()
	frame.text:SetPoint("BOTTOM" .. side, frame, "BOTTOM" .. side, 0, 0)
	frame.title:SetText(title or "")
	frame.title:SetJustifyH(align)
	frame.title:ClearAllPoints()
	if body == "" then
		frame.title:SetPoint("BOTTOM" .. side, frame, "BOTTOM" .. side, 0, 0)
	else
		frame.title:SetPoint("BOTTOM" .. side, frame.text, "TOP" .. side, 0, ZoneInfo.lineSpacing)
	end

	local textWidth = body == "" and 0 or frame.text:GetStringWidth()
	local textHeight = body == "" and 0 or frame.text:GetStringHeight() + ZoneInfo.lineSpacing
	frame:SetSize(math.max(frame.title:GetStringWidth(), textWidth, 1), math.max(frame.title:GetStringHeight() + textHeight, 1))
	frame:Show()
end

function ZoneInfo.HideBlizzardText(label)
	if label.Name ~= nil then label.Name:SetAlpha(0) end
	if label.Description ~= nil then label.Description:SetAlpha(0) end
	if label.Texture ~= nil then label.Texture:SetAlpha(0) end
end

function ZoneInfo.HookLabel()
	if ZoneInfo.hooked then return true end
	if WorldMapFrame == nil or WorldMapFrame.dataProviders == nil then return false end
	for provider in pairs(WorldMapFrame.dataProviders) do
		local label = provider.Label
		if label ~= nil and label.EvaluateLabels ~= nil then
			ZoneInfo.label = label
			ZoneInfo.HideBlizzardText(label)
			hooksecurefunc(label, "EvaluateLabels", ZoneInfo.Update)
			ZoneInfo.hooked = true

			return true
		end
	end

	return false
end

if WorldMapFrame ~= nil then
	if WorldMapFrame.OnMapChanged ~= nil then hooksecurefunc(WorldMapFrame, "OnMapChanged", ZoneInfo.Update) end
	WorldMapFrame:HookScript("OnShow", function()
		ZoneInfo.HookLabel()
		ZoneInfo.Update()
	end)

	if WorldMapFrame.ScrollContainer ~= nil then WorldMapFrame.ScrollContainer:HookScript("OnLeave", ZoneInfo.Update) end
	ZoneInfo.HookLabel()
end
