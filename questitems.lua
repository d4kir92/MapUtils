local _, MapUtils = ...
if GameTooltip == nil then return end
MapUtils.HasQuestItemTooltip = true

local QUEST_ITEM_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Questitem or 12
local REPEATABLE_COLOR = "|cff3399ff"
local ACTIVE_COLOR = "|cffffd100"
local READY_COLOR = "|cff40ff40"
local COMPLETED_COLOR = "|cff999999"
local INACTIVE_COLOR = "|cffff6b6b"
local MUTED_TITLE_COLOR = "|cffb0b0b0"
local MAX_INACTIVE = 3

local QI = {
	["dirty"] = true,
	["active"] = {},
	["specialItems"] = {},
	["byItemName"] = {},
	["byQuest"] = {},
	["stamped"] = setmetatable({}, {__mode = "k"})
}

function QI.IsSecret(value)
	return MapUtils.IsSecret ~= nil and MapUtils:IsSecret(value)
end

function QI.ItemIDFromLink(link)
	if type(link) ~= "string" or QI.IsSecret(link) then return nil end
	local id = string.match(link, "item:(%d+)")

	return id and tonumber(id) or nil
end

function QI.CleanObjectiveName(text)
	local cleaned = string.gsub(text, "%s*[:ï¼š]%s*%d+%s*/%s*%d+%s*$", "")
	cleaned = string.gsub(cleaned, "^%s*%d+%s*/%s*%d+%s*", "")
	cleaned = string.gsub(cleaned, "%s*%(%s*%d+%s*/%s*%d+%s*%)%s*$", "")
	cleaned = string.match(cleaned, "^%s*(.-)%s*$") or ""
	if cleaned == "" then return nil end

	return string.lower(cleaned)
end

function QI.IndexObjective(questID, text, fulfilled, required, finished)
	local key = QI.CleanObjectiveName(text)
	local entry = {
		["questID"] = questID,
		["key"] = key,
		["lowerText"] = string.lower(text),
		["fulfilled"] = fulfilled,
		["required"] = required,
		["finished"] = finished
	}
	local qList = QI.byQuest[questID]
	if qList == nil then
		qList = {}
		QI.byQuest[questID] = qList
	end

	tinsert(qList, entry)
	if key ~= nil then
		local nList = QI.byItemName[key]
		if nList == nil then
			nList = {}
			QI.byItemName[key] = nList
		end

		tinsert(nList, entry)
	end
end

function QI.ParseObjectiveCounts(text, fulfilled, required)
	if fulfilled ~= nil and required ~= nil then return fulfilled, required end
	local a, b = string.match(text, "(%d+)%s*/%s*(%d+)")
	if a and b then return tonumber(a), tonumber(b) end

	return fulfilled, required
end

function QI.IndexQuestObjectives(questID, logIndex)
	if C_QuestLog and C_QuestLog.GetQuestObjectives then
		local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
		if ok and type(objectives) == "table" then
			for _, obj in ipairs(objectives) do
				if type(obj) == "table" and obj.type == "item" and type(obj.text) == "string" and not QI.IsSecret(obj.text) then
					local fulfilled = type(obj.numFulfilled) == "number" and not QI.IsSecret(obj.numFulfilled) and obj.numFulfilled or nil
					local required = type(obj.numRequired) == "number" and not QI.IsSecret(obj.numRequired) and obj.numRequired or nil
					fulfilled, required = QI.ParseObjectiveCounts(obj.text, fulfilled, required)
					QI.IndexObjective(questID, obj.text, fulfilled, required, obj.finished == true)
				end
			end

			return
		end
	end

	if logIndex and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
		local count = GetNumQuestLeaderBoards(logIndex) or 0
		for i = 1, count do
			local desc, objType, finished = GetQuestLogLeaderBoard(i, logIndex)
			if objType == "item" and type(desc) == "string" and not QI.IsSecret(desc) then
				local fulfilled, required = QI.ParseObjectiveCounts(desc, nil, nil)
				QI.IndexObjective(questID, desc, fulfilled, required, finished == true or finished == 1)
			end
		end
	end
end

function QI.IndexSpecialItem(questID, logIndex)
	if not logIndex or not GetQuestLogSpecialItemInfo then return end
	local link = GetQuestLogSpecialItemInfo(logIndex)
	local itemID = QI.ItemIDFromLink(link)
	if itemID == nil then return end
	local list = QI.specialItems[itemID]
	if list == nil then
		list = {}
		QI.specialItems[itemID] = list
	end

	tinsert(list, questID)
end

function QI.EnsureLog()
	if not QI.dirty then return end
	QI.dirty = false
	wipe(QI.active)
	wipe(QI.specialItems)
	wipe(QI.byItemName)
	wipe(QI.byQuest)
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
		for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
			local info = C_QuestLog.GetInfo(index)
			if info and not info.isHeader and info.questID and not QI.IsSecret(info.questID) then
				local questID = info.questID
				local done = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
				if done == nil then done = info.isComplete end
				local title = type(info.title) == "string" and not QI.IsSecret(info.title) and info.title or nil
				local level = type(info.level) == "number" and not QI.IsSecret(info.level) and info.level or nil
				QI.active[questID] = {
					["title"] = title,
					["level"] = level,
					["complete"] = done == true or done == 1
				}
				QI.IndexQuestObjectives(questID, index)
				QI.IndexSpecialItem(questID, index)
			end
		end
	elseif GetNumQuestLogEntries and GetQuestLogTitle then
		for index = 1, GetNumQuestLogEntries() or 0 do
			local title, level, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
			if not isHeader and questID and not QI.IsSecret(questID) then
				QI.active[questID] = {
					["title"] = type(title) == "string" and not QI.IsSecret(title) and title or nil,
					["level"] = type(level) == "number" and not QI.IsSecret(level) and level or nil,
					["complete"] = isComplete == 1 or isComplete == true
				}
				QI.IndexQuestObjectives(questID, index)
				QI.IndexSpecialItem(questID, index)
			end
		end
	end
end

function QI.IsQuestDone(questID)
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(questID) == true end
	if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(questID) == true end

	return false
end

function QI.GetPlayerSide()
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	if faction == "Alliance" then return 1 end
	if faction == "Horde" then return 2 end

	return 0
end

function QI.GetItemDetails(tooltip, data)
	local itemID, itemName = nil, nil
	if type(data) == "table" and type(data.id) == "number" and not QI.IsSecret(data.id) then itemID = data.id end
	if tooltip.GetItem then
		local name, link = tooltip:GetItem()
		if type(name) == "string" and name ~= "" and not QI.IsSecret(name) then itemName = name end
		if itemID == nil then itemID = QI.ItemIDFromLink(link) end
	end

	if itemID == nil then return nil, nil, nil end
	local classID = nil
	if C_Item and C_Item.GetItemInfoInstant then
		classID = select(6, C_Item.GetItemInfoInstant(itemID))
	elseif GetItemInfoInstant then
		classID = select(6, GetItemInfoInstant(itemID))
	end

	if itemName == nil then
		if C_Item and C_Item.GetItemNameByID then
			local name = C_Item.GetItemNameByID(itemID)
			if type(name) == "string" and name ~= "" and not QI.IsSecret(name) then itemName = name end
		end

		if itemName == nil then
			local name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(itemID) or (GetItemInfo and GetItemInfo(itemID))
			if type(name) == "string" and name ~= "" and not QI.IsSecret(name) then itemName = name end
		end
	end

	return itemID, itemName, classID
end

function QI.ScanTooltipFlags(tooltip, data)
	local isQuestLine, isStartLine = false, false
	if type(data) == "table" and type(data.lines) == "table" then
		for _, entry in ipairs(data.lines) do
			local text = type(entry) == "table" and entry.leftText or nil
			if type(text) == "string" and not QI.IsSecret(text) then
				if ITEM_BIND_QUEST and text == ITEM_BIND_QUEST then isQuestLine = true end
				if ITEM_STARTS_QUEST and text == ITEM_STARTS_QUEST then
					isQuestLine = true
					isStartLine = true
				end
			end
		end

		if isQuestLine or isStartLine then return isQuestLine, isStartLine end
	end

	local name = tooltip.GetName and tooltip:GetName()
	if type(name) ~= "string" then return false, false end
	local numLines = tooltip.NumLines and tooltip:NumLines() or 0
	for i = 2, numLines do
		local line = _G[name .. "TextLeft" .. i]
		local text = line and line.GetText and line:GetText()
		if type(text) == "string" and not QI.IsSecret(text) then
			if ITEM_BIND_QUEST and text == ITEM_BIND_QUEST then isQuestLine = true end
			if ITEM_STARTS_QUEST and text == ITEM_STARTS_QUEST then
				isQuestLine = true
				isStartLine = true
			end
		end
	end

	return isQuestLine, isStartLine
end

function QI.GetBagQuestInfo(tooltip, itemID)
	local owner = tooltip.GetOwner and tooltip:GetOwner()
	if owner == nil or (owner.IsForbidden and owner:IsForbidden()) then return false, nil end
	local bag = owner.GetBagID and owner:GetBagID()
	if bag == nil then
		local parent = owner.GetParent and owner:GetParent()
		if parent and parent.GetID then bag = parent:GetID() end
	end

	local slot = owner.GetID and owner:GetID()
	if type(bag) ~= "number" or type(slot) ~= "number" or bag < 0 or slot < 1 then return false, nil end
	local bagItemID = nil
	if C_Container and C_Container.GetContainerItemID then
		bagItemID = C_Container.GetContainerItemID(bag, slot)
	elseif GetContainerItemID then
		bagItemID = GetContainerItemID(bag, slot)
	end

	if bagItemID ~= itemID then return false, nil end
	if C_Container and C_Container.GetContainerItemQuestInfo then
		local info = C_Container.GetContainerItemQuestInfo(bag, slot)
		if type(info) == "table" then
			local qid = type(info.questID) == "number" and info.questID > 0 and info.questID or nil

			return info.isQuestItem == true or qid ~= nil, qid
		end
	elseif GetContainerItemQuestInfo then
		local isQuest, questID = GetContainerItemQuestInfo(bag, slot)
		local qid = type(questID) == "number" and questID > 0 and questID or nil

		return isQuest == true or isQuest == 1 or qid ~= nil, qid
	end

	return false, nil
end

function QI.FindObjectiveProgress(questID, lowerName)
	local list = QI.byQuest[questID]
	if list == nil or #list == 0 then return nil end
	if lowerName then
		for _, obj in ipairs(list) do
			if obj.key == lowerName then return obj end
		end

		for _, obj in ipairs(list) do
			if string.find(obj.lowerText, lowerName, 1, true) then return obj end
		end
	end

	if #list == 1 then return list[1] end

	return nil
end

function QI.GetQuestTitle(questID, activeInfo, quest)
	if activeInfo and activeInfo.title and activeInfo.title ~= "" then return activeInfo.title end
	local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
	if type(title) == "string" and title ~= "" and not QI.IsSecret(title) then return title end
	if quest and type(quest[3]) == "string" and quest[3] ~= "" then return quest[3] end

	return tostring(questID)
end

function QI.GetQuestColor(questID, quest, muted)
	if MapUtils.GetQuestPinKind then
		local kind = MapUtils:GetQuestPinKind(questID, quest, true)
		if kind == 3 and MapUtils.QUEST_RAID_COLOR then return MapUtils.QUEST_RAID_COLOR end
		if kind == 2 and MapUtils.QUEST_DUNGEON_COLOR then return MapUtils.QUEST_DUNGEON_COLOR end
		if kind == 1 and MapUtils.QUEST_PVP_COLOR then return MapUtils.QUEST_PVP_COLOR end
	end

	if quest then
		local cat = quest[5]
		if cat == 2 or cat == 3 or (cat == 1 and quest[23] and math.floor(quest[23]) % 2 == 1) then return REPEATABLE_COLOR end
	end

	return muted and MUTED_TITLE_COLOR or ACTIVE_COLOR
end

function QI.AddCandidate(candidates, order, questID, startsQuest)
	if type(questID) ~= "number" or questID <= 0 then return end
	local existing = candidates[questID]
	if existing == nil then
		candidates[questID] = {
			["questID"] = questID,
			["starts"] = startsQuest == true
		}
		tinsert(order, questID)
	elseif startsQuest then
		existing.starts = true
	end
end

function QI.CollectEntries(itemID, itemName, isQuestItem, isStartItem, bagQuestID)
	QI.EnsureLog()
	local candidates, order = {}, {}
	local dbItems = MapUtils.QUESTITEMS
	local raw = dbItems and dbItems[itemID]
	if type(raw) == "number" then
		QI.AddCandidate(candidates, order, math.abs(raw), raw < 0)
	elseif type(raw) == "table" then
		for _, v in ipairs(raw) do
			if type(v) == "number" then QI.AddCandidate(candidates, order, math.abs(v), v < 0) end
		end
	end

	if bagQuestID then QI.AddCandidate(candidates, order, bagQuestID, true) end
	local special = QI.specialItems[itemID]
	if special then
		for _, qid in ipairs(special) do
			QI.AddCandidate(candidates, order, qid, false)
		end
	end

	local lowerName = itemName and string.lower(itemName) or nil
	if lowerName then
		local byName = QI.byItemName[lowerName]
		if byName then
			for _, obj in ipairs(byName) do
				QI.AddCandidate(candidates, order, obj.questID, false)
			end
		end
	end

	if #order == 0 then return nil end
	local infoTable = MapUtils.QUESTINFO
	local playerSide = QI.GetPlayerSide()
	local activeList, startsList, inactiveList = {}, {}, {}
	for _, questID in ipairs(order) do
		local cand = candidates[questID]
		local activeInfo = QI.active[questID]
		local isActive = activeInfo ~= nil
		local isDone = not isActive and QI.IsQuestDone(questID)
		local quest = infoTable and infoTable[questID]
		local side = quest and quest[4]
		local wrongSide = not isActive and not isDone and playerSide > 0 and side and side > 0 and side ~= playerSide
		if not wrongSide then
			local title = QI.GetQuestTitle(questID, activeInfo, quest)
			local level = (activeInfo and activeInfo.level) or (quest and quest[1])
			if type(level) ~= "number" or level <= 0 then level = nil end
			if isActive then
				local status, statusColor = nil, ACTIVE_COLOR
				if activeInfo.complete then
					status = MapUtils:Trans("LID_QUESTITEMREADY")
					statusColor = READY_COLOR
				else
					local prog = QI.FindObjectiveProgress(questID, lowerName)
					if prog and prog.fulfilled ~= nil and prog.required ~= nil and prog.required > 0 then
						status = prog.fulfilled .. "/" .. prog.required
						statusColor = prog.finished and READY_COLOR or ACTIVE_COLOR
					else
						status = MapUtils:Trans("LID_QUESTITEMACTIVE")
						statusColor = ACTIVE_COLOR
					end
				end

				tinsert(activeList, {
					["questID"] = questID,
					["quest"] = quest,
					["title"] = title,
					["level"] = level,
					["status"] = status,
					["statusColor"] = statusColor,
					["muted"] = false
				})
			elseif isQuestItem or isStartItem then
				if not isDone and (cand.starts or (isStartItem and #order == 1)) then
					tinsert(startsList, {
						["questID"] = questID,
						["quest"] = quest,
						["title"] = title,
						["level"] = level,
						["status"] = MapUtils:Trans("LID_QUESTITEMSTARTS"),
						["statusColor"] = ACTIVE_COLOR,
						["muted"] = false
					})
				elseif isDone then
					tinsert(inactiveList, {
						["questID"] = questID,
						["quest"] = quest,
						["title"] = title,
						["level"] = level,
						["status"] = MapUtils:Trans("LID_QUESTITEMCOMPLETED"),
						["statusColor"] = COMPLETED_COLOR,
						["muted"] = true,
						["priority"] = 1
					})
				else
					tinsert(inactiveList, {
						["questID"] = questID,
						["quest"] = quest,
						["title"] = title,
						["level"] = level,
						["status"] = MapUtils:Trans("LID_QUESTITEMNOTINLOG"),
						["statusColor"] = INACTIVE_COLOR,
						["muted"] = true,
						["priority"] = 2
					})
				end
			end
		end
	end

	if #activeList > 0 or #startsList > 0 then
		local out = {}
		for _, entry in ipairs(activeList) do
			tinsert(out, entry)
		end

		for _, entry in ipairs(startsList) do
			tinsert(out, entry)
		end

		return out, 0
	end

	if not (isQuestItem or isStartItem) or #inactiveList == 0 then return nil, 0 end
	table.sort(inactiveList, function(a, b)
		if a.priority ~= b.priority then return a.priority < b.priority end

		return a.questID < b.questID
	end)
	local out = {}
	local limit = math.min(#inactiveList, MAX_INACTIVE)
	for i = 1, limit do
		tinsert(out, inactiveList[i])
	end

	return out, #inactiveList - limit
end

function QI.OnTooltipSetItem(tooltip, data)
	if tooltip == nil or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
	if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
	if not MapUtils:GetConfig("QUESTITEMTOOLTIP", true) then return end
	if QI.stamped[tooltip] then return end
	local itemID, itemName, classID = QI.GetItemDetails(tooltip, data)
	if itemID == nil then return end
	local isQuestLine, isStartLine = QI.ScanTooltipFlags(tooltip, data)
	local bagQuestItem, bagQuestID = false, nil
	if tooltip == GameTooltip then bagQuestItem, bagQuestID = QI.GetBagQuestInfo(tooltip, itemID) end
	local isQuestItem = classID == QUEST_ITEM_CLASS or isQuestLine or bagQuestItem
	local isStartItem = isStartLine or bagQuestID ~= nil
	local entries, overflow = QI.CollectEntries(itemID, itemName, isQuestItem, isStartItem, bagQuestID)
	if entries == nil or #entries == 0 then return end
	QI.stamped[tooltip] = true
	local icon = MapUtils.GetAddonIcon and MapUtils:GetAddonIcon()
	local prefix = icon and ("|T" .. icon .. ":14:14:0:0|t ") or ""
	for _, entry in ipairs(entries) do
		local color = QI.GetQuestColor(entry.questID, entry.quest, entry.muted)
		local levelText = entry.level and ("[" .. entry.level .. "] ") or ""
		local left = prefix .. color .. levelText .. entry.title .. "|r"
		local right = entry.statusColor .. entry.status .. "|r"
		tooltip:AddDoubleLine(left, right)
	end

	if overflow > 0 then tooltip:AddLine(prefix .. MUTED_TITLE_COLOR .. "+" .. overflow .. "|r") end
end

function QI.ClearStamp(tooltip)
	QI.stamped[tooltip] = nil
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "UNIT_QUEST_LOG_CHANGED", "BAG_UPDATE_DELAYED"}) do
	if MapUtils.RegisterEvent then
		MapUtils:RegisterEvent(eventFrame, event)
	else
		pcall(eventFrame.RegisterEvent, eventFrame, event)
	end
end

eventFrame:SetScript("OnEvent", function()
	QI.dirty = true
end)

for _, tip in ipairs({GameTooltip, ItemRefTooltip}) do
	if tip then
		if tip:HasScript("OnTooltipCleared") then tip:HookScript("OnTooltipCleared", QI.ClearStamp) end
		if tip:HasScript("OnHide") then tip:HookScript("OnHide", QI.ClearStamp) end
	end
end

if ItemRefTooltip and GameTooltip and ItemRefTooltip:HasScript("OnTooltipSetItem") and GameTooltip:HasScript("OnTooltipSetItem") then
	ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip) QI.OnTooltipSetItem(tooltip) end)
	GameTooltip:HookScript("OnTooltipSetItem", function(tooltip) QI.OnTooltipSetItem(tooltip) end)
elseif TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, QI.OnTooltipSetItem)
end
