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

local function ApplyZoneLevel(label, text, mapID, levelsOn, recOn, fishingOn)
	if WorldMapFrame.GetNormalizedCursorPosition == nil or C_Map.GetMapInfoAtPosition == nil then return end
	local x, y = WorldMapFrame:GetNormalizedCursorPosition()
	if mapID == nil or x == nil or y == nil then return end
	local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
	if info == nil or info.mapID == mapID or info.name == nil or text:sub(1, #info.name) ~= info.name then return end
	local levels = zoneLevels[info.mapID]
	if levelsOn and levels ~= nil and text == info.name then label.Name:SetText(format("%s%s (%s)|r", text, MapUtils:GetLevelColorCode(levels[1], levels[2]), GetRangeText(levels))) end
	if label.Description == nil then return end
	local rec = zoneRecLevels[info.mapID]
	local recText = nil
	if recOn and rec ~= nil then recText = MapUtils:Trans("LID_RECOMMENDEDSTARTLEVEL", nil, rec) end
	local fishing = zoneFishing[info.mapID]
	local fishingText = nil
	if fishingOn and fishing ~= nil then fishingText = MapUtils:Trans("LID_FISHINGLEVEL", nil, fishing) end
	if recText == nil and fishingText == nil then return end
	local description = label.Description:GetText()
	if description == nil or description == "" then
		if recText ~= nil and fishingText ~= nil then
			label.Description:SetText(recText .. "\n" .. fishingText)
		else
			label.Description:SetText(recText or fishingText)
		end
	elseif recText ~= nil and description:find(recText, 1, true) == nil then
		label.Description:SetText(recText .. "\n" .. description)
	end
end

local applied = {}
local function GetDescriptionText(label)
	if label.Description == nil then return nil end

	return label.Description:GetText()
end

local function AppendZoneLevel(label)
	local levelsOn = MapUtils:GetConfig("ZONELEVELS", true) == true
	local recOn = MapUtils:GetConfig("ZONERECLEVELS", true) == true
	local fishingOn = MapUtils:GetConfig("FISHINGLEVELS", true) == true
	if not levelsOn and not recOn and not fishingOn then return end
	local text = label.Name:GetText()
	if text == nil or text == "" then return end
	local mapID = WorldMapFrame:GetMapID()
	local options = (levelsOn and 1 or 0) + (recOn and 2 or 0) + (fishingOn and 4 or 0)
	if applied.label == label and applied.name == text and applied.description == GetDescriptionText(label) and applied.mapID == mapID and applied.options == options then return end
	ApplyZoneLevel(label, text, mapID, levelsOn, recOn, fishingOn)
	applied.label = label
	applied.name = label.Name:GetText()
	applied.description = GetDescriptionText(label)
	applied.mapID = mapID
	applied.options = options
end

local hooked = false
local function HookAreaLabel()
	if hooked then return true end
	if WorldMapFrame == nil or WorldMapFrame.dataProviders == nil then return false end
	for provider in pairs(WorldMapFrame.dataProviders) do
		local label = provider.Label
		if label ~= nil and label.Name ~= nil and label.EvaluateLabels ~= nil then
			hooksecurefunc(label, "EvaluateLabels", AppendZoneLevel)
			hooked = true

			return true
		end
	end

	return false
end

if WorldMapFrame ~= nil and not HookAreaLabel() then WorldMapFrame:HookScript("OnShow", HookAreaLabel) end
