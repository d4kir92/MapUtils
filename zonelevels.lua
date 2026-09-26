local _, MapUtils = ...
local zoneLevels = {}
zoneLevels[1411] = {1, 10}
zoneLevels[1412] = {1, 10}
zoneLevels[1413] = {10, 25}
zoneLevels[1416] = {30, 40}
zoneLevels[1417] = {30, 40}
zoneLevels[1418] = {35, 45}
zoneLevels[1419] = {45, 55}
zoneLevels[1420] = {1, 10}
zoneLevels[1421] = {10, 20}
zoneLevels[1422] = {51, 58}
zoneLevels[1423] = {53, 60}
zoneLevels[1424] = {20, 30}
zoneLevels[1425] = {40, 50}
zoneLevels[1426] = {1, 10}
zoneLevels[1427] = {43, 50}
zoneLevels[1428] = {50, 58}
zoneLevels[1429] = {1, 10}
zoneLevels[1430] = {55, 60}
zoneLevels[1431] = {18, 30}
zoneLevels[1432] = {10, 20}
zoneLevels[1433] = {15, 25}
zoneLevels[1434] = {30, 45}
zoneLevels[1435] = {35, 45}
zoneLevels[1436] = {10, 20}
zoneLevels[1437] = {20, 30}
zoneLevels[1438] = {1, 10}
zoneLevels[1439] = {10, 20}
zoneLevels[1440] = {18, 30}
zoneLevels[1441] = {25, 35}
zoneLevels[1442] = {15, 27}
zoneLevels[1443] = {30, 40}
zoneLevels[1444] = {40, 50}
zoneLevels[1445] = {35, 45}
zoneLevels[1446] = {40, 50}
zoneLevels[1447] = {45, 55}
zoneLevels[1448] = {48, 55}
zoneLevels[1449] = {48, 55}
zoneLevels[1451] = {55, 60}
zoneLevels[1452] = {55, 60}
zoneLevels[2482] = {60, 60}
zoneLevels[2521] = {1, 12}
zoneLevels[2548] = {35, 45}
zoneLevels[2652] = {35, 45}
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

local function AppendZoneLevel(label)
	local levelsOn = MapUtils:GetConfig("ZONELEVELS", true) == true
	local fishingOn = MapUtils:GetConfig("FISHINGLEVELS", true) == true
	if not levelsOn and not fishingOn then return end
	local text = label.Name:GetText()
	if text == nil or text == "" then return end
	if WorldMapFrame.GetNormalizedCursorPosition == nil or C_Map.GetMapInfoAtPosition == nil then return end
	local mapID = WorldMapFrame:GetMapID()
	local x, y = WorldMapFrame:GetNormalizedCursorPosition()
	if mapID == nil or x == nil or y == nil then return end
	local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
	if info == nil or info.mapID == mapID or info.name == nil or text:sub(1, #info.name) ~= info.name then return end
	local levels = zoneLevels[info.mapID]
	if levelsOn and levels ~= nil and text == info.name then label.Name:SetText(format("%s%s (%s)|r", text, MapUtils:GetLevelColorCode(levels[1], levels[2]), GetRangeText(levels))) end
	local fishing = zoneFishing[info.mapID]
	if not fishingOn or fishing == nil or label.Description == nil then return end
	local description = label.Description:GetText()
	if description == nil or description == "" then label.Description:SetText(MapUtils:Trans("LID_FISHINGLEVEL", nil, fishing)) end
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
