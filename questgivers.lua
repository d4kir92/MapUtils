local _, MapUtils = ...
if WorldMapFrame == nil or C_Map == nil or MapUtils.QUESTGIVERS == nil or MapUtils.QUESTINFO == nil then return end
local GIVERS = MapUtils.QUESTGIVERS
local INFO = MapUtils.QUESTINFO
local QG = {}
local ICON_ATLAS = "QuestNormal"
local ICON_FILE = "Interface\\GossipFrame\\AvailableQuestIcon"
local TURNIN_ATLAS = "QuestTurnin"
local TURNIN_FILE = "Interface\\GossipFrame\\ActiveQuestIcon"
local ICON_SIZE = 18
local CIRCLE_NORMAL = "UI-QuestPoi-QuestNumber"
local CIRCLE_PUSHED = "UI-QuestPoi-QuestNumber-Pressed"
local CIRCLE_TRACKED = "UI-QuestPoi-QuestNumber-SuperTracked"
local CIRCLE_TRACKED_PUSHED = "UI-QuestPoi-QuestNumber-Pressed-SuperTracked"
local CIRCLE_HIGHLIGHT = "UI-QuestPoi-InnerGlow"
local CIRCLE_SCALE = 1.4
local ICON_SCALE = 0.8
local WAYPOINT_TOLERANCE = 0.001
local WAYPOINT_TEMPLATE = "WaypointLocationPinTemplate"
local PIN_LEVEL = 2500
local TOOLTIP_GIVERS = 8
local COLLECT_DELAY = 0.5
local CATEGORY_KEYS = {"QUESTGIVEREVENT", "QUESTGIVERDAILY", "QUESTGIVERREP"}
local CATEGORY_TAGS = {"LID_QUESTTAGEVENT", "LID_QUESTTAGDAILY", "LID_QUESTTAGREP"}
local SKILL_SPELLS = {
	[129] = 3273,
	[164] = 2018,
	[165] = 2108,
	[171] = 2259,
	[182] = 2366,
	[185] = 2550,
	[186] = 2575,
	[197] = 3908,
	[202] = 4036,
	[333] = 7411,
	[356] = 7620,
	[393] = 8613,
	[755] = 25229,
	[773] = 45357,
}

local updater = CreateFrame("Frame", nil, WorldMapFrame)
local pins = {}
if MapUtils.CanvasPinLists ~= nil then tinsert(MapUtils.CanvasPinLists, pins) end
if MapUtils.RegisterRenderLayer ~= nil then MapUtils:RegisterRenderLayer("Quest givers", function() return pins end) end
local spots = {}
local clusters = {}
local sources = {}
local cells = {}
local inLog = {}
local complete = {}
local nativeQuests = {current = {}, pending = {}}
local skills = {}
local player = {}
local enabledCategories = {}
local dirty = true
local layoutKey = nil
local lastMapID = nil
local lastCollect = 0
local elapsedTime = 0
function QG.IsAddOnLoaded(name)
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) == true end
	if IsAddOnLoaded then return IsAddOnLoaded(name) == true end

	return false
end

function QG.IsDone(questID)
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(questID) == true end
	if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(questID) == true end

	return false
end

function QG.HasBit(mask, bit)
	return math.floor(mask / 2 ^ (bit - 1)) % 2 == 1
end

function QG.SpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
	if GetSpellInfo then return (GetSpellInfo(spellID)) end

	return nil
end

function QG.KnowsSpell(spellID)
	if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
	if IsSpellKnown and IsSpellKnown(spellID) then return true end

	return false
end

function QG.GetStanding(factionID)
	if C_Reputation and C_Reputation.GetFactionDataByID then
		local data = C_Reputation.GetFactionDataByID(factionID)
		if data and data.name then return data.currentStanding end

		return nil
	end

	if GetFactionInfoByID then
		local name, _, _, _, _, barValue = GetFactionInfoByID(factionID)
		if name then return barValue end
	end

	return nil
end

function QG.ReadLog()
	wipe(inLog)
	wipe(complete)
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
		for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
			local info = C_QuestLog.GetInfo(index)
			if info and not info.isHeader and info.questID then
				inLog[info.questID] = true
				local done = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID)
				if done == nil then done = info.isComplete end
				if done == true or done == 1 then complete[info.questID] = true end
			end
		end
	elseif GetNumQuestLogEntries and GetQuestLogTitle then
		for index = 1, GetNumQuestLogEntries() or 0 do
			local _, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
			if not isHeader and questID then
				inLog[questID] = true
				if isComplete == 1 or isComplete == true then complete[questID] = true end
			end
		end
	end
end

function MapUtils:GetQuestTurnInDefault()
	return MapUtils.RefreshQuestTurnIns == nil
end

function QG.ReadSkills()
	wipe(skills)
	if GetProfessions and GetProfessionInfo then
		for _, index in pairs({GetProfessions()}) do
			local _, _, rank, _, _, _, skillLine = GetProfessionInfo(index)
			if skillLine then skills[skillLine] = rank or 0 end
		end
	end

	if GetNumSkillLines and GetSkillLineInfo then
		local byName = {}
		for skillID, spellID in pairs(SKILL_SPELLS) do
			local name = QG.SpellName(spellID)
			if name then byName[name] = skillID end
		end

		for index = 1, GetNumSkillLines() or 0 do
			local name, isHeader, _, rank = GetSkillLineInfo(index)
			local skillID = name and byName[name]
			if not isHeader and skillID then skills[skillID] = math.max(skills[skillID] or 0, rank or 0) end
		end
	end
end

function QG.ReadPlayer()
	player.level = UnitLevel("player") or 1
	local faction = UnitFactionGroup("player")
	player.side = faction == "Alliance" and 1 or faction == "Horde" and 2 or 0
	player.race = select(3, UnitRace("player"))
	player.class = select(3, UnitClass("player"))
	local range = GetQuestGreenRange and GetQuestGreenRange("player")
	if type(range) ~= "number" then
		if player.level <= 5 then
			range = 5
		elseif player.level <= 39 then
			range = math.floor(player.level / 10) + 5
		else
			range = math.floor(player.level / 5) + 1
		end
	end

	player.green = range
	for index, key in ipairs(CATEGORY_KEYS) do
		enabledCategories[index] = MapUtils:GetConfig(key, false) == true
	end
end

function QG.AllDone(list)
	for _, questID in ipairs(list) do
		if not QG.IsDone(questID) then return false end
	end

	return true
end

function QG.AnyDone(list)
	for _, questID in ipairs(list) do
		if QG.IsDone(questID) then return true end
	end

	return false
end

function QG.AnyTaken(list)
	for _, questID in ipairs(list) do
		if inLog[questID] or QG.IsDone(questID) then return true end
	end

	return false
end

function QG.GetLevel(quest)
	if quest[1] > 0 then return quest[1] end

	return player.level
end

function QG.IsAvailable(questID, quest, giverSide)
	if inLog[questID] or quest[2] > player.level then return false end
	local level = QG.GetLevel(quest)
	if player.level - level > player.green or level - player.level >= 10 then return false end
	if GetQuestDifficultyColor and QuestDifficultyColors and QuestDifficultyColors.trivial and GetQuestDifficultyColor(level) == QuestDifficultyColors.trivial then return false end
	if quest[6] and player.level > quest[6] then return false end
	if player.side ~= 0 and ((quest[4] and quest[4] ~= player.side) or (giverSide and giverSide ~= player.side)) then return false end
	if quest[5] and not enabledCategories[quest[5]] then return false end
	if quest[7] and player.race and not QG.HasBit(quest[7], player.race) then return false end
	if quest[8] and player.class and not QG.HasBit(quest[8], player.class) then return false end
	if QG.IsDone(questID) then return false end
	if quest[9] and not QG.AllDone(quest[9]) then return false end
	if quest[10] and not QG.AnyDone(quest[10]) then return false end
	if quest[11] and QG.AnyTaken(quest[11]) then return false end
	if quest[12] and (inLog[quest[12]] or QG.IsDone(quest[12])) then return false end
	if quest[13] and (skills[quest[13][1]] or -1) < quest[13][2] then return false end
	if quest[14] and (QG.GetStanding(quest[14][1]) or -math.huge) < quest[14][2] then return false end
	if quest[15] and (QG.GetStanding(quest[15][1]) or -math.huge) >= quest[15][2] then return false end
	if quest[16] and QG.KnowsSpell(math.abs(quest[16])) ~= (quest[16] > 0) then return false end
	if quest[17] and not inLog[quest[17]] then return false end

	return true
end

function QG.GetMapRect(sourceID, targetID)
	local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, sourceID, targetID)
	if ok and minX and maxX and minY and maxY and minX < maxX and minY < maxY then return minX, maxX, minY, maxY end

	return nil
end

function QG.ProjectRect(sourceID, targetID)
	local left, right, top, bottom = 0, 1, 0, 1
	local visited = {}
	while sourceID ~= targetID do
		if visited[sourceID] then return nil end
		visited[sourceID] = true
		local minX, maxX, minY, maxY = QG.GetMapRect(sourceID, targetID)
		if minX then return minX + left * (maxX - minX), minX + right * (maxX - minX), minY + top * (maxY - minY), minY + bottom * (maxY - minY) end
		local info = C_Map.GetMapInfo(sourceID)
		local parentID = info and info.parentMapID
		if parentID == nil or parentID == 0 then return nil end
		minX, maxX, minY, maxY = QG.GetMapRect(sourceID, parentID)
		if minX == nil then return nil end
		left, right, top, bottom = minX + left * (maxX - minX), minX + right * (maxX - minX), minY + top * (maxY - minY), minY + bottom * (maxY - minY)
		sourceID = parentID
	end

	return left, right, top, bottom
end

function QG.GetSources(mapID)
	local foreign = MapUtils:GetOneMapQuestSources(mapID)
	local cached = sources[mapID]
	if cached and cached.foreign == foreign then return cached end
	local list = {
		["foreign"] = foreign
	}

	local seen = {}
	if GIVERS[mapID] then
		seen[mapID] = true
		tinsert(list, {mapID, 0, 1, 0, 1})
	end

	local children = C_Map.GetMapChildrenInfo and C_Map.GetMapChildrenInfo(mapID, nil, true)
	for _, child in ipairs(children or {}) do
		local childID = child.mapID
		if childID and not seen[childID] and GIVERS[childID] then
			seen[childID] = true
			local left, right, top, bottom = QG.ProjectRect(childID, mapID)
			if left then tinsert(list, {childID, left, right, top, bottom}) end
		end
	end

	for _, source in ipairs(foreign or {}) do
		local sourceID = source[1]
		if not seen[sourceID] and GIVERS[sourceID] then
			seen[sourceID] = true
			tinsert(list, {sourceID, source[2], source[3], source[4], source[5], true})
		end
	end

	sources[mapID] = list

	return list
end

function QG.IsShownOnMap(mapID)
	if mapID == nil or C_Map.GetMapInfo(mapID) == nil or QG.IsAddOnLoaded("Questie") then return false end
	QG.showStarts = MapUtils:GetConfig("QUESTGIVERWORLDMAPPINS", true) == true
	QG.showEnds = MapUtils:GetQuestTurnInDefault() and MapUtils:GetConfig("QUESTGIVERTURNIN", true) == true
	if not QG.showStarts and not QG.showEnds then return false end

	return #QG.GetSources(mapID) > 0
end

function QG.GetTurnIns(giver)
	if not QG.showEnds or giver[5] == nil then return nil end
	local quests = nil
	for _, questID in ipairs(giver[5]) do
		if complete[questID] and not nativeQuests.current[questID] then
			quests = quests or {}
			tinsert(quests, questID)
		end
	end

	return quests
end

function QG.GetAvailableCache()
	local logCount, logSum, doneCount, doneSum = 0, 0, 0, 0
	for questID in pairs(inLog) do
		logCount, logSum = logCount + 1, logSum + questID
	end

	for questID in pairs(complete) do
		doneCount, doneSum = doneCount + 1, doneSum + questID
	end

	local key = format("%d:%d:%d:%s:%s:%d:%d:%d:%d", player.level or 0, player.green or 0, player.side or 0, tostring(QG.showStarts), tostring(QG.showEnds), logCount, logSum, doneCount, doneSum)
	for index = 1, #CATEGORY_KEYS do
		key = key .. (enabledCategories[index] and "1" or "0")
	end

	local now = GetTime()
	if QG.available == nil or QG.stale or QG.availableKey ~= key or now - (QG.availableTime or 0) > 30 then
		QG.available = {}
		QG.availableKey = key
		QG.availableTime = now
		QG.stale = false
	end

	return QG.available
end

function QG.Collect(mapID)
	wipe(spots)
	if not QG.IsShownOnMap(mapID) then return end
	QG.ReadPlayer()
	QG.ReadLog()
	QG.ReadSkills()
	local available = QG.GetAvailableCache()
	for _, source in ipairs(QG.GetSources(mapID)) do
		local sourceID, left, right, top, bottom, outside = source[1], source[2], source[3], source[4], source[5], source[6]
		for _, giver in ipairs(GIVERS[sourceID]) do
			local quests = nil
			if QG.showStarts then
				for _, questID in ipairs(giver[3]) do
					local quest = INFO[questID]
					local key = giver[4] and (questID * 4 + giver[4]) or questID * 4
					if available[key] == nil then available[key] = quest ~= nil and QG.IsAvailable(questID, quest, giver[4]) end
					if available[key] then
						quests = quests or {}
						tinsert(quests, questID)
					end
				end
			end

			local turnins = QG.GetTurnIns(giver)
			if quests or turnins then
				for _, coord in ipairs(giver[2]) do
					local localX, localY = math.floor(coord / 1000) / 1000, (coord % 1000) / 1000
					local x, y = left + localX * (right - left), top + localY * (bottom - top)
					if outside or x >= 0 and x <= 1 and y >= 0 and y <= 1 then
						tinsert(
							spots,
							{
								["giver"] = giver,
								["name"] = giver[1],
								["mapID"] = sourceID,
								["localX"] = localX,
								["localY"] = localY,
								["x"] = x,
								["y"] = y,
								["quests"] = quests,
								["turnins"] = turnins
							}
						)
					end
				end
			end
		end
	end
end

function QG.GetTitle(questID, fallback)
	local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
	if type(title) == "string" and title ~= "" and not MapUtils:IsSecret(title) then return title end

	return fallback
end

function QG.GetXP(quest)
	local data = quest[19]
	if type(data) ~= "table" then return 0 end
	local charLevel = UnitLevel("player") or 1
	local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
	if maxLevel and charLevel >= maxLevel then return 0 end
	local xp = data[2] * math.min(10, math.max(1, 2 * (data[1] - charLevel) + 20)) / 10
	if xp <= 100 then
		xp = 5 * math.floor((xp + 2) / 5)
	elseif xp <= 500 then
		xp = 10 * math.floor((xp + 5) / 10)
	elseif xp <= 1000 then
		xp = 25 * math.floor((xp + 12) / 25)
	else
		xp = 50 * math.floor((xp + 25) / 50)
	end

	return math.floor(xp)
end

function QG.GetMoney(questID)
	if GetQuestLogRewardMoney == nil then return 0 end
	local ok, money = pcall(GetQuestLogRewardMoney, questID)
	if ok and type(money) == "number" and not MapUtils:IsSecret(money) and money > 0 then return money end

	return 0
end

function QG.GetFactionName(factionID)
	if C_Reputation and C_Reputation.GetFactionDataByID then
		local data = C_Reputation.GetFactionDataByID(factionID)
		if data and data.name then return data.name end
	end

	if GetFactionInfoByID then
		local name = GetFactionInfoByID(factionID)
		if name then return name end
	end

	return nil
end

function QG.VisibleLength(text)
	return #text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "  ")
end

function QG.AddWrapped(text, indent, r, g, b)
	local line = ""
	for word in text:gmatch("%S+") do
		if line == "" then
			line = word
		elseif QG.VisibleLength(line) + 1 + QG.VisibleLength(word) > QG.WRAP then
			GameTooltip:AddLine(indent .. line, r, g, b)
			line = word
		else
			line = line .. " " .. word
		end
	end

	if line ~= "" then GameTooltip:AddLine(indent .. line, r, g, b) end
end

QG.WRAP = 44
QG.INDENT = "  "
QG.CHAIN_INDENT = "     "
function QG.AddQuestDetails(questID, quest)
	if quest[20] then QG.AddWrapped(quest[20], QG.INDENT, 0.85, 0.85, 0.85) end
	local rewards = {}
	local xp = QG.GetXP(quest)
	if xp > 0 then tinsert(rewards, format("%s %s", BreakUpLargeNumbers and BreakUpLargeNumbers(xp) or xp, MapUtils:Trans("LID_QUESTXP"))) end
	local money = QG.GetMoney(questID)
	if money > 0 and GetCoinTextureString then tinsert(rewards, GetCoinTextureString(money)) end
	if #rewards > 0 then QG.AddWrapped(format("|cffffd100%s:|r %s", MapUtils:Trans("LID_QUESTREWARD"), table.concat(rewards, "  ")), QG.INDENT, 1, 1, 1) end
	local reputation = quest[21]
	if type(reputation) == "table" then
		local parts = {}
		for i = 1, #reputation - 1, 2 do
			local name = QG.GetFactionName(reputation[i])
			if name then tinsert(parts, format("%+d %s", reputation[i + 1], name)) end
		end

		if #parts > 0 then QG.AddWrapped(format("|cffffd100%s:|r %s", MapUtils:Trans("LID_QUESTREPUTATION"), table.concat(parts, ", ")), QG.INDENT, 0.55, 0.65, 1) end
	end

	local nextID = quest[18]
	local seen = {
		[questID] = true
	}

	local first = true
	while nextID and INFO[nextID] and not seen[nextID] do
		seen[nextID] = true
		if first then
			GameTooltip:AddLine(format("%s%s:", QG.INDENT, MapUtils:Trans("LID_QUESTNEXT")), 1, 0.82, 0)
			first = false
		end

		GameTooltip:AddLine(QG.CHAIN_INDENT .. QG.GetTitle(nextID, INFO[nextID][3]), 0.75, 0.75, 0.75)
		nextID = INFO[nextID][18]
	end
end

function QG.AddQuestLines(quests)
	local details = IsShiftKeyDown()
	for index, questID in ipairs(quests) do
		local quest = INFO[questID]
		local level = QG.GetLevel(quest)
		local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
		local tag = ""
		if quest[5] then tag = " |cff9d9d9d(" .. MapUtils:Trans(CATEGORY_TAGS[quest[5]]) .. ")|r" end
		if details and index > 1 then GameTooltip:AddLine(" ") end
		if color then
			GameTooltip:AddLine(format("%s[%d] %s%s", QG.INDENT, level, QG.GetTitle(questID, quest[3]), tag), color.r, color.g, color.b, true)
		else
			GameTooltip:AddLine(format("%s[%d] %s%s", QG.INDENT, level, QG.GetTitle(questID, quest[3]), tag), 1, 1, 1, true)
		end

		if details then QG.AddQuestDetails(questID, quest) end
	end

	return #quests > 0
end

function QG.OnEnter(pin)
	local cluster = pin.cluster
	if cluster == nil then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	QG.hovered = pin
	local hasQuests = false
	local seen = {}
	local first = true
	local shown = 0
	local hidden = 0
	for _, spot in ipairs(cluster.spots) do
		if not seen[spot.giver] and shown >= TOOLTIP_GIVERS then
			seen[spot.giver] = true
			hidden = hidden + 1
		elseif not seen[spot.giver] then
			seen[spot.giver] = true
			shown = shown + 1
			if first then
				GameTooltip:SetText(spot.name, 1, 0.82, 0)
				first = false
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(spot.name, 1, 0.82, 0)
			end

			for _, questID in ipairs(spot.turnins or {}) do
				local quest = INFO[questID]
				GameTooltip:AddLine(format("%s%s: %s", QG.INDENT, MapUtils:Trans("LID_QUESTTURNIN"), QG.GetTitle(questID, quest and quest[3] or tostring(questID))), 0.25, 1, 0.25, true)
			end

			if QG.AddQuestLines(spot.quests or {}) then hasQuests = true end
		end
	end

	if hidden > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format("+%d", hidden), 0.6, 0.6, 0.6)
	end

	local shiftHint = hasQuests and not IsShiftKeyDown()
	if shiftHint or MapUtils:HasWaypointSupport() then GameTooltip:AddLine(" ") end
	if shiftHint then GameTooltip:AddLine(format("|cffffd100%s|r %s", MapUtils:Trans("LID_SHIFT"), MapUtils:Trans("LID_QUESTMOREINFO")), 1, 1, 1) end
	if MapUtils:HasWaypointSupport() then GameTooltip:AddLine(format("|cffffd100%s|r %s", MapUtils:Trans("LID_LEFTCLICK"), MapUtils:Trans("LID_SETWAYPOINT")), 1, 1, 1) end
	GameTooltip:Show()
end

function QG.OnClick(pin, button)
	if button == "RightButton" then
		local info = C_Map.GetMapInfo(WorldMapFrame:GetMapID())
		if info and info.parentMapID and info.parentMapID > 0 then WorldMapFrame:SetMapID(info.parentMapID) end

		return
	end

	local mapID, x, y = QG.GetTarget(pin)
	if mapID == nil or not MapUtils:HasWaypointSupport() then return end
	local key = format("%d|%.4f|%.4f", mapID, x, y)
	if QG.waypoint ~= nil and QG.waypoint.key == key and MapUtils:HasUserWaypoint() then
		MapUtils:ClearUserWaypoint()
		MapUtils:SetWaypointTracked(false)
		QG.waypoint = nil
		if SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_REMOVE then PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_REMOVE) end
		QG.UpdateStyles()

		return
	end

	if MapUtils:SetTrackedWaypoint(mapID, x, y) then
		local point = MapUtils:GetUserWaypoint()
		QG.waypoint = nil
		if point ~= nil and point.position ~= nil then
			QG.waypoint = {
				key = key,
				mapID = point.uiMapID,
				x = point.position.x,
				y = point.position.y
			}
		end

		if SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON then PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON) end
	end

	QG.UpdateStyles()
end

function QG.GetTarget(pin)
	local cluster = pin.cluster
	if cluster == nil or lastMapID == nil then return nil end
	local spot = cluster.spots[1]
	if spot.mapID ~= lastMapID then return spot.mapID, spot.localX, spot.localY end

	return lastMapID, cluster.x, cluster.y
end

function QG.GetTrackedKey()
	local waypoint = QG.waypoint
	if waypoint == nil or not MapUtils:HasUserWaypoint() or not MapUtils:IsWaypointTracked() then return nil end
	local point = MapUtils:GetUserWaypoint()
	if point == nil or point.position == nil or point.uiMapID ~= waypoint.mapID then return nil end
	if math.abs(point.position.x - waypoint.x) > WAYPOINT_TOLERANCE or math.abs(point.position.y - waypoint.y) > WAYPOINT_TOLERANCE then return nil end

	return waypoint.key
end

function QG.SetAtlas(texture, atlas)
	if not MapUtils:HasAtlasOrFallback(atlas) then
		texture:Hide()

		return
	end

	MapUtils:SetAtlasOrFallback(texture, atlas)
	texture:Show()
end

function QG.GetWaypointLevel()
	if WorldMapFrame.GetPinFrameLevelsManager == nil then return nil end
	local manager = WorldMapFrame:GetPinFrameLevelsManager()
	if manager == nil or manager.GetValidFrameLevel == nil then return nil end

	return manager:GetValidFrameLevel("PIN_FRAME_LEVEL_WAYPOINT_LOCATION")
end

function QG.UpdateStyle(pin, trackedKey)
	local tracked = false
	if trackedKey ~= nil and pin.cluster ~= nil then
		local mapID, x, y = QG.GetTarget(pin)
		tracked = mapID ~= nil and format("%d|%.4f|%.4f", mapID, x, y) == trackedKey
	end

	local level = pin.baseLevel or pin:GetFrameLevel()
	if tracked then
		local waypointLevel = QG.GetWaypointLevel()
		if waypointLevel ~= nil and waypointLevel >= level then level = waypointLevel + 1 end
	end

	if pin:GetFrameLevel() ~= level then pin:SetFrameLevel(level) end
	if pin.tracked == tracked then return tracked end
	pin.tracked = tracked
	QG.SetAtlas(pin.normal, tracked and CIRCLE_TRACKED or CIRCLE_NORMAL)
	QG.SetAtlas(pin.pushed, tracked and CIRCLE_TRACKED_PUSHED or CIRCLE_PUSHED)

	return tracked
end

function QG.SetWaypointPinsHidden(hide)
	if WorldMapFrame.EnumeratePinsByTemplate == nil then return end
	for pin in WorldMapFrame:EnumeratePinsByTemplate(WAYPOINT_TEMPLATE) do
		if hide then
			pin:SetAlpha(0)
		elseif QG.waypointHidden then
			pin:SetAlpha(1)
		end
	end

	QG.waypointHidden = hide
end

function QG.UpdateStyles()
	local trackedKey = QG.GetTrackedKey()
	local anyTracked = false
	for _, pin in ipairs(pins) do
		if pin:IsShown() and QG.UpdateStyle(pin, trackedKey) then anyTracked = true end
	end

	if anyTracked or QG.waypointHidden then QG.SetWaypointPinsHidden(anyTracked) end
end

function QG.CreatePin(canvas)
	local pin = CreateFrame("Button", nil, canvas)
	pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	pin.normal = pin:CreateTexture(nil, "ARTWORK")
	pin.pushed = pin:CreateTexture(nil, "ARTWORK")
	pin.highlight = pin:CreateTexture(nil, "OVERLAY")
	pin.icon = pin:CreateTexture(nil, "ARTWORK", nil, 1)
	for _, texture in ipairs({pin.normal, pin.pushed, pin.highlight, pin.icon}) do
		texture:SetPoint("CENTER")
	end

	QG.SetAtlas(pin.normal, CIRCLE_NORMAL)
	QG.SetAtlas(pin.pushed, CIRCLE_PUSHED)
	QG.SetAtlas(pin.highlight, CIRCLE_HIGHLIGHT)
	pin:SetNormalTexture(pin.normal)
	pin:SetPushedTexture(pin.pushed)
	pin:SetHighlightTexture(pin.highlight, "ADD")
	pin.tracked = false

	pin:SetScript("OnEnter", QG.OnEnter)
	pin:SetScript("OnLeave", function(sel) if GameTooltip:IsOwned(sel) then GameTooltip:Hide() end end)
	pin:SetScript("OnHide", function(sel) if GameTooltip:IsOwned(sel) then GameTooltip:Hide() end end)
	pin:SetScript("OnClick", QG.OnClick)

	return pin
end

function QG.SetPinIcon(pin, turnin)
	if pin.turnin == turnin then return end
	pin.turnin = turnin
	local atlas = turnin and TURNIN_ATLAS or ICON_ATLAS
	if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
		pin.icon:SetAtlas(atlas)
	else
		pin.icon:SetTexture(turnin and TURNIN_FILE or ICON_FILE)
	end
end

function QG.HasTurnIn(cluster)
	for _, spot in ipairs(cluster.spots) do
		if spot.turnins then return true end
	end

	return false
end

function QG.HidePins()
	for _, pin in ipairs(pins) do
		pin:Hide()
		pin.cluster = nil
	end

	if QG.waypointHidden then QG.SetWaypointPinsHidden(false) end
	layoutKey = nil
end

function QG.BuildClusters(width, height, limit)
	wipe(clusters)
	wipe(cells)
	for _, spot in ipairs(spots) do
		local key = math.floor(spot.x * width / limit) * 100000 + math.floor(spot.y * height / limit)
		local cluster = cells[key]
		if cluster == nil then
			cluster = {
				["x"] = 0,
				["y"] = 0,
				["count"] = 0,
				["spots"] = {}
			}

			cells[key] = cluster
			tinsert(clusters, cluster)
		end

		cluster.x = (cluster.x * cluster.count + spot.x) / (cluster.count + 1)
		cluster.y = (cluster.y * cluster.count + spot.y) / (cluster.count + 1)
		cluster.count = cluster.count + 1
		tinsert(cluster.spots, spot)
	end

	local limitSquared = limit * limit
	local merged = true
	while merged do
		merged = false
		local i = 1
		while i <= #clusters do
			local a = clusters[i]
			local j = i + 1
			while j <= #clusters do
				local b = clusters[j]
				local dx, dy = (a.x - b.x) * width, (a.y - b.y) * height
				if dx * dx + dy * dy < limitSquared then
					local count = a.count + b.count
					a.x = (a.x * a.count + b.x * b.count) / count
					a.y = (a.y * a.count + b.y * b.count) / count
					a.count = count
					for _, spot in ipairs(b.spots) do
						tinsert(a.spots, spot)
					end

					table.remove(clusters, j)
					merged = true
				else
					j = j + 1
				end
			end

			i = i + 1
		end
	end
end

function QG.Layout(canvas)
	local scale = canvas:GetScale()
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if scale == nil or scale <= 0 or width <= 0 or height <= 0 then return end
	local key = format("%s|%s|%s|%d", scale, width, height, #spots)
	if key == layoutKey then return end
	layoutKey = key
	local size = ICON_SIZE / scale
	QG.BuildClusters(width, height, size)
	local level = canvas:GetFrameLevel() + PIN_LEVEL
	for index, cluster in ipairs(clusters) do
		local pin = pins[index]
		if pin == nil then
			pin = QG.CreatePin(canvas)
			pins[index] = pin
		end

		pin.cluster = cluster
		QG.SetPinIcon(pin, QG.HasTurnIn(cluster))
		pin:SetSize(size, size)
		local circle = size * CIRCLE_SCALE
		for _, texture in ipairs({pin.normal, pin.pushed, pin.highlight}) do
			texture:SetSize(circle, circle)
		end

		pin.icon:SetSize(size * ICON_SCALE, size * ICON_SCALE)
		local extend = (circle - size) / 2
		pin:SetHitRectInsets(-extend, -extend, -extend, -extend)
		pin.baseLevel = level
		pin:SetFrameLevel(level)
		MapUtils:SetCanvasPinScale(pin, scale)
		pin:ClearAllPoints()
		pin:SetPoint("CENTER", canvas, "TOPLEFT", width * cluster.x, -height * cluster.y)
		pin:Show()
		if GameTooltip:IsOwned(pin) then QG.OnEnter(pin) end
	end

	for index = #clusters + 1, #pins do
		pins[index]:Hide()
		pins[index].cluster = nil
	end
end

function QG.Update()
	if MapUtils:UpdateVisibleQuestPins(nativeQuests) then dirty = true end
	local mapID = WorldMapFrame:GetMapID()
	local now = GetTime()
	if mapID ~= lastMapID or (dirty and now - lastCollect >= COLLECT_DELAY) then
		if mapID ~= lastMapID then QG.HidePins() end
		dirty = false
		lastMapID = mapID
		lastCollect = now
		layoutKey = nil
		QG.Collect(mapID)
	end

	local canvas = WorldMapFrame:GetCanvas()
	if canvas then QG.Layout(canvas) end
	QG.UpdateStyles()
end

if MapUtils.CanvasPinUpdaters ~= nil then tinsert(MapUtils.CanvasPinUpdaters, QG.Update) end
function MapUtils:RefreshQuestGivers()
	dirty = true
	QG.stale = true
	lastCollect = 0
	QG.HidePins()
end

updater:RegisterEvent("QUEST_LOG_UPDATE")
updater:RegisterEvent("QUEST_TURNED_IN")
updater:RegisterEvent("PLAYER_LEVEL_UP")
updater:RegisterEvent("SKILL_LINES_CHANGED")
updater:RegisterEvent("UPDATE_FACTION")
updater:RegisterEvent("MODIFIER_STATE_CHANGED")
updater:SetScript(
	"OnEvent",
	function(_, event)
		if event == "QUEST_LOG_UPDATE" then
			dirty = true

			return
		end

		if event ~= "MODIFIER_STATE_CHANGED" then
			dirty = true
			QG.stale = true

			return
		end

		local pin = QG.hovered
		if pin and pin:IsShown() and GameTooltip:IsOwned(pin) then QG.OnEnter(pin) end
	end
)
updater:SetScript(
	"OnUpdate",
	MapUtils.Profile("questgivers OnUpdate", function(_, elapsed)
		elapsedTime = elapsedTime + elapsed
		if elapsedTime < 0.1 then return end
		elapsedTime = 0
		QG.Update()
	end)
)

WorldMapFrame:HookScript(
	"OnShow",
	function()
		dirty = true
		elapsedTime = 0.1
	end
)

WorldMapFrame:HookScript("OnHide", QG.HidePins)
MapUtils.ProfileTable("QG", QG)
