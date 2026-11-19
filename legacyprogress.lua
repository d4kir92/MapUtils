local _, MapUtils = ...
if not MapUtils:IsForever() then return end
local Legacy = {
	exploreCategories = {14777, 14778},
	dungeonAchievements = {62031, 62032, 62033, 64016, 64017, 64018},
	exploreByZone = {
		[1411] = 728,
		[1412] = 736,
		[1413] = 750,
		[1416] = 760,
		[1417] = 761,
		[1418] = 765,
		[1419] = 766,
		[1420] = 768,
		[1421] = 769,
		[1422] = 770,
		[1423] = 771,
		[1424] = 772,
		[1425] = 773,
		[1426] = 627,
		[1427] = 774,
		[1428] = 775,
		[1429] = 776,
		[1430] = 777,
		[1431] = 778,
		[1432] = 779,
		[1433] = 780,
		[1434] = 781,
		[1435] = 782,
		[1436] = 802,
		[1437] = 841,
		[1438] = 842,
		[1439] = 844,
		[1440] = 845,
		[1441] = 846,
		[1442] = 847,
		[1443] = 848,
		[1444] = 849,
		[1445] = 850,
		[1446] = 851,
		[1447] = 852,
		[1448] = 853,
		[1449] = 854,
		[1450] = 855,
		[1451] = 856,
		[1452] = 857,
	},
	dungeons = {
		{zones = {1420, 1458}, ids = {230760, 116049, 234131, 117729}, asset = 250657},
		{zones = {1437}, ids = {230761, 116054, 234132, 117730}, asset = 260326},
		{zones = {1436}, ids = {230762, 3262, 234133, 117731}, asset = 639},
		{zones = {1413}, ids = {230763, 18524, 234134, 117732}, asset = 3654},
		{zones = {1454, 1455}, ids = {230766, 19213, 234135, 117733}},
		{zones = {1421}, ids = {231426, 3263, 234136, 117734}, asset = 4275},
		{zones = {1416, 1421}, ids = {230769, 116050, 234138, 117735}, asset = 246020},
		{zones = {1434}, ids = {230770, 116053, 234139, 117736}},
		{zones = {1440}, ids = {230771, 18526, 234140, 117737}, asset = 4829},
		{zones = {1426}, ids = {230772, 18529, 234141, 117738}},
		{zones = {1413}, ids = {230773, 18528, 234142, 117739}},
		{zones = {1420}, ids = {230774, 116058, 234143, 117740}},
		{zones = {1420}, ids = {230775, 116059, 234144, 117741}},
		{zones = {1420}, ids = {230776, 116060, 234145, 117742}},
		{zones = {1420}, ids = {230777, 3264, 234146, 117743}},
		{zones = {2548}, ids = {230778, 116052, 234147, 117744}},
		{zones = {1413}, ids = {230780, 18530, 234149, 117745}, asset = 7358},
		{zones = {1418}, ids = {230781, 18531, 234150, 117746}},
		{zones = {1446}, ids = {230782, 3265, 234151, 117747}},
		{zones = {1443}, ids = {230783, 18532, 234152, 117748}},
		{zones = {1445}, ids = {230784, 116057, 234153, 117749}, asset = 255702},
		{zones = {1435}, ids = {230785, 18533, 234154, 117750}},
		{zones = {1427, 1428}, ids = {230786, 3266, 234155, 117751}},
		{zones = {1427, 1428}, ids = {230787, 18534, 234156, 117752}},
		{zones = {1427, 1428}, ids = {230788, 3268, 234157, 117753}},
		{zones = {1422}, ids = {230789, 19263, 234158, 117754}},
		{zones = {1423}, ids = {230790, 119884, 234159, 117755}},
		{zones = {1423}, ids = {230791, 18471, 234160, 117756}},
		{zones = {1444}, ids = {230792, 545, 234161, 117757}},
		{zones = {1444}, ids = {230793, 18535, 234162, 117758}},
		{zones = {1444}, ids = {230794, 546, 234163, 117759}},
		{zones = {1449}, ids = {230795, 116056, 234164, 117760}},
		{zones = {1447}, ids = {230796, 116055, 234165, 117761}},
	},
	iconSize = 14,
	doneIcon = "Interface\\RaidFrame\\ReadyCheck-Ready",
	missingIcon = "Interface\\RaidFrame\\ReadyCheck-NotReady",
	exploreIcon = "Interface\\Icons\\INV_Misc_Map_01",
	dungeonIcon = "Interface\\Icons\\INV_Misc_Key_14",
	cache = {},
	foundExplore = {},
}

function Legacy.Icon(texture)
	if texture == nil then return "" end

	return format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t ", texture, Legacy.iconSize, Legacy.iconSize)
end

function Legacy.StatusIcon(done)
	return format("|T%s:%d:%d|t ", done and Legacy.doneIcon or Legacy.missingIcon, Legacy.iconSize, Legacy.iconSize)
end

function Legacy.FindExploreByName(zoneID)
	if GetCategoryNumAchievements == nil or C_Map.GetMapInfo == nil then return nil end
	local info = C_Map.GetMapInfo(zoneID)
	local zoneName = info and info.name
	if zoneName == nil or zoneName == "" then return nil end
	for _, categoryID in ipairs(Legacy.exploreCategories) do
		local count = GetCategoryNumAchievements(categoryID)
		for index = 1, count or 0 do
			local achievementID, name = GetAchievementInfo(categoryID, index)
			if achievementID ~= nil and type(name) == "string" and name:find(zoneName, 1, true) then return achievementID end
		end
	end

	return nil
end

function Legacy.GetExploreAchievement(zoneID)
	local found = Legacy.foundExplore[zoneID]
	if found == nil then
		found = Legacy.exploreByZone[zoneID] or Legacy.FindExploreByName(zoneID) or false
		Legacy.foundExplore[zoneID] = found
	end

	return found or nil
end

function Legacy.GetExploreProgress(zoneID)
	local achievementID = Legacy.GetExploreAchievement(zoneID)
	if achievementID == nil or GetAchievementNumCriteria == nil then return nil end
	local ok, id, _, _, completed, _, _, _, _, _, icon, _, _, wasEarnedByMe = pcall(GetAchievementInfo, achievementID)
	if not ok or id == nil then return nil end
	local total = GetAchievementNumCriteria(achievementID) or 0
	if total <= 0 then return nil end
	local allDone = completed and wasEarnedByMe ~= false
	local progress = {done = 0, total = total, icon = icon, items = {}}
	for index = 1, total do
		local name, _, criteriaDone = GetAchievementCriteriaInfo(achievementID, index)
		local itemDone = allDone or criteriaDone == true
		if itemDone then progress.done = progress.done + 1 end
		tinsert(progress.items, {name = name or "?", done = itemDone})
	end

	return progress
end

function Legacy.MatchDungeon(criteriaID, assetID)
	for _, dungeon in ipairs(Legacy.dungeons) do
		if assetID ~= nil and assetID ~= 0 and dungeon.asset == assetID then return dungeon end
		for _, id in ipairs(dungeon.ids) do
			if id == criteriaID then return dungeon end
		end
	end

	return nil
end

function Legacy.ScanDungeons()
	if Legacy.dungeonState ~= nil then return Legacy.dungeonState end
	local state = {found = {}, done = {}, names = {}, order = {}}
	for _, achievementID in ipairs(Legacy.dungeonAchievements) do
		local ok, id, _, _, _, _, _, _, _, _, icon = pcall(GetAchievementInfo, achievementID)
		if ok and id ~= nil and GetAchievementNumCriteria ~= nil then
			state.icon = state.icon or icon
			for index = 1, GetAchievementNumCriteria(achievementID) or 0 do
				local name, _, completed, _, _, _, _, assetID, _, criteriaID = GetAchievementCriteriaInfo(achievementID, index)
				local dungeon = Legacy.MatchDungeon(criteriaID, assetID)
				if dungeon ~= nil then
					if not state.found[dungeon] then tinsert(state.order, dungeon) end
					state.found[dungeon] = true
					state.names[dungeon] = state.names[dungeon] or name
					if completed then state.done[dungeon] = true end
				end
			end
		end
	end

	Legacy.dungeonState = state

	return state
end

function Legacy.GetDungeonProgress(zoneID)
	local state = Legacy.ScanDungeons()
	local progress = {done = 0, total = 0, icon = state.icon, items = {}}
	for _, dungeon in ipairs(state.order) do
		for _, id in ipairs(dungeon.zones) do
			if id == zoneID then
				local itemDone = state.done[dungeon] == true
				progress.total = progress.total + 1
				if itemDone then progress.done = progress.done + 1 end
				tinsert(progress.items, {name = state.names[dungeon] or "?", done = itemDone})
				break
			end
		end
	end

	if progress.total == 0 then return nil end

	return progress
end

function Legacy.FormatLine(key, icon, done, total)
	local text = MapUtils:Trans(key, nil, done, total)
	if done >= total then
		text = Legacy.Icon(icon) .. "|cff20ff20" .. text .. "|r " .. Legacy.StatusIcon(true)
	else
		text = Legacy.Icon(icon) .. text
	end

	return text
end

function Legacy.Build(zoneID)
	local data = {lines = {}, sections = {}}
	local explore = Legacy.GetExploreProgress(zoneID)
	if explore ~= nil then
		explore.key = "LID_LEGACYEXPLORED"
		explore.icon = explore.icon or Legacy.exploreIcon
		tinsert(data.sections, explore)
	end

	local dungeons = Legacy.GetDungeonProgress(zoneID)
	if dungeons ~= nil then
		dungeons.key = "LID_LEGACYDUNGEONS"
		dungeons.icon = dungeons.icon or Legacy.dungeonIcon
		tinsert(data.sections, dungeons)
	end

	for _, section in ipairs(data.sections) do
		tinsert(data.lines, Legacy.FormatLine(section.key, section.icon, section.done, section.total))
	end

	return data
end

function Legacy.Get(zoneID)
	if zoneID == nil or MapUtils:GetConfig("LEGACYPROGRESS", true) ~= true then return nil end
	local data = Legacy.cache[zoneID]
	if data == nil then
		data = Legacy.Build(zoneID)
		Legacy.cache[zoneID] = data
	end

	return data
end

function MapUtils:GetLegacyProgressLines(zoneID)
	local data = Legacy.Get(zoneID)

	return data and data.lines
end

function MapUtils:HasLegacyProgress(zoneID)
	local data = Legacy.Get(zoneID)

	return data ~= nil and #data.sections > 0
end

function Legacy.SortItems(items)
	local sorted = {}
	for i, item in ipairs(items) do
		sorted[i] = item
	end

	table.sort(
		sorted,
		function(a, b)
			if a.done ~= b.done then return not a.done end

			return a.name < b.name
		end
	)

	return sorted
end

function MapUtils:AddLegacyProgressTooltip(tooltip, zoneID)
	local data = Legacy.Get(zoneID)
	if data == nil or #data.sections == 0 then return false end
	local info = C_Map.GetMapInfo(zoneID)
	tooltip:AddLine(info and info.name or MapUtils:Trans("LID_LEGACYPROGRESS"))
	for _, section in ipairs(data.sections) do
		tooltip:AddLine(" ")
		local r, g, b = 1, 0.82, 0
		if section.done >= section.total then r, g, b = 0.13, 1, 0.13 end
		tooltip:AddLine(Legacy.Icon(section.icon) .. MapUtils:Trans(section.key, nil, section.done, section.total), r, g, b)
		for _, item in ipairs(Legacy.SortItems(section.items)) do
			if item.done then
				tooltip:AddLine(Legacy.StatusIcon(true) .. item.name, 0.5, 0.5, 0.5)
			else
				tooltip:AddLine(Legacy.StatusIcon(false) .. item.name, 1, 1, 1)
			end
		end
	end

	return true
end

function MapUtils:GetLegacyProgressVersion()
	return Legacy.version or 0
end

function Legacy.Invalidate()
	Legacy.cache = {}
	Legacy.dungeonState = nil
	Legacy.version = (Legacy.version or 0) + 1
	if MapUtils.RefreshZoneInfo ~= nil and WorldMapFrame ~= nil and WorldMapFrame:IsShown() then MapUtils:RefreshZoneInfo() end
end

Legacy.frame = CreateFrame("Frame")
Legacy.frame:RegisterEvent("ACHIEVEMENT_EARNED")
Legacy.frame:RegisterEvent("CRITERIA_UPDATE")
Legacy.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Legacy.frame:SetScript(
	"OnEvent",
	MapUtils.Profile(
		"legacyprogress OnEvent",
		function(_, event)
			if event == "PLAYER_ENTERING_WORLD" then Legacy.foundExplore = {} end
			Legacy.Invalidate()
		end
	)
)

MapUtils.ProfileTable("LegacyProgress", Legacy)
