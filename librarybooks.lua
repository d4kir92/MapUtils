local _, MapUtils = ...
local LibraryBooks = {
	pinsKey = "LIBRARYBOOKWORLDMAPPINS",
	minimapKey = "LIBRARYBOOKMINIMAPPINS",
	unexploredKey = "LIBRARYBOOKSHOWUNEXPLORED",
	defaults = {
		LIBRARYBOOKWORLDMAPPINS = true,
		LIBRARYBOOKMINIMAPPINS = true,
		LIBRARYBOOKSHOWUNEXPLORED = true
	},
	icon = "Interface\\Icons\\INV_Misc_Book_09",
	cache = {},
}

MapUtils.LibraryBooks = LibraryBooks
function LibraryBooks.Get(key)
	return MapUtils:GetConfig(key, LibraryBooks.defaults[key]) == true
end

function LibraryBooks.Set(key, value)
	MapUtils:SetMapOption(key, value, function() MapUtils:RefreshExploredPins() end)
	MapUtils:SetSharedSetting(key, value)
	if MapUtils.RefreshPinToggles ~= nil then MapUtils:RefreshPinToggles() end
end

function MapUtils:LibraryBookPinsAvailable()
	return MapUtils:IsForever() and type(MapUtils.LIBRARYBOOKS) == "table"
end

function MapUtils:LibraryBookPinsEnabled(minimap)
	return MapUtils:LibraryBookPinsAvailable() and LibraryBooks.Get(minimap and LibraryBooks.minimapKey or LibraryBooks.pinsKey)
end

function MapUtils:RefreshLibraryBooks()
	wipe(LibraryBooks.cache)
	LibraryBooks.signature = nil
	MapUtils:RefreshExploredPins()
end

function LibraryBooks.GetState(book)
	local api = _G["AzerothCompendiumAPI"]
	if type(api) == "table" and api.GetLibraryBookState ~= nil then
		local state, seen = api.GetLibraryBookState(book.itemId)
		if state ~= nil then return state, seen == true end
	end

	local done = C_QuestLog ~= nil and C_QuestLog.IsQuestFlaggedCompleted ~= nil and C_QuestLog.IsQuestFlaggedCompleted(book.questId)
	if done then return "done", false end
	local bags = LibraryBooks.GetCount(book.itemId, false)
	if bags > 0 then return "bag", true end
	if LibraryBooks.GetCount(book.itemId, true) > bags then return "bank", true end

	return "missing", false
end

function LibraryBooks.GetCount(itemId, includeBank)
	local getter = C_Item ~= nil and C_Item.GetItemCount or GetItemCount
	if getter == nil then return 0 end

	return tonumber(getter(itemId, includeBank)) or 0
end

function LibraryBooks.GetIcon(book)
	local icon = C_Item ~= nil and C_Item.GetItemIconByID ~= nil and C_Item.GetItemIconByID(book.itemId) or nil

	return icon or LibraryBooks.icon
end

function LibraryBooks.GetName(book)
	local name = C_Item ~= nil and C_Item.GetItemNameByID ~= nil and C_Item.GetItemNameByID(book.itemId) or nil

	return name or book.name
end

function LibraryBooks.Project(point, mapID)
	if point[1] == mapID then return point[2], point[3] end
	if C_Map == nil or C_Map.GetMapRectOnMap == nil then return nil end
	local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(point[1], mapID)
	if minX == nil or maxX == nil or minY == nil or maxY == nil or maxX <= minX or maxY <= minY then return nil end
	local x, y = minX + point[2] * (maxX - minX), minY + point[3] * (maxY - minY)
	if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

	return x, y
end

function MapUtils:GetLibraryBookPins(mapID)
	if mapID == nil or not MapUtils:LibraryBookPinsAvailable() then return nil end
	local cached = LibraryBooks.cache[mapID]
	if cached ~= nil then return cached or nil end
	local list = {}
	for _, book in ipairs(MapUtils.LIBRARYBOOKS) do
		local state, seen = LibraryBooks.GetState(book)
		if state ~= "done" then
			for _, point in ipairs(book.points) do
				local x, y = LibraryBooks.Project(point, mapID)
				if x ~= nil then
					tinsert(list, {
						kind = "librarybook",
						x = x,
						y = y,
						sourceMapID = point[1],
						source = {
							kind = "librarybook",
							x = point[2],
							y = point[3]
						},
						icon = LibraryBooks.GetIcon(book),
						name = book.name,
						book = book,
						state = state,
						seen = seen or state ~= "missing" and state ~= "questflag"
					})
				end
			end
		end
	end

	if #list == 0 then list = false end
	LibraryBooks.cache[mapID] = list

	return list or nil
end

function MapUtils:AddLibraryBookTooltip(entry)
	local book = entry.book
	GameTooltip:AddLine(LibraryBooks.GetName(book), 1, 1, 1)
	GameTooltip:AddLine(MapUtils:Trans("LID_LIBRARYBOOK"), 0.6, 0.6, 0.6)
	local state = LibraryBooks.GetState(book)
	if state == "bag" then
		GameTooltip:AddLine(MapUtils:Trans("LID_LIBRARYBOOKINBAGS"), 0.4, 1, 0.4)
	elseif state == "bank" then
		GameTooltip:AddLine(MapUtils:Trans("LID_LIBRARYBOOKINBANK"), 0.4, 1, 0.4)
	end

	if book.subzone ~= nil then GameTooltip:AddLine(book.subzone, 1, 0.82, 0) end
	if book.note ~= nil then GameTooltip:AddLine(book.note, 1, 1, 1, true) end
	GameTooltip:AddLine(MapUtils:Trans("LID_LIBRARYBOOKHIDEHINT"), 0.6, 0.6, 0.6, true)
end

function LibraryBooks.GetSignature()
	local parts = {}
	for _, book in ipairs(MapUtils.LIBRARYBOOKS) do
		local state, seen = LibraryBooks.GetState(book)
		tinsert(parts, state .. (seen and "1" or "0"))
	end

	return table.concat(parts)
end

function LibraryBooks.CheckChanged()
	if not MapUtils:LibraryBookPinsEnabled() and not MapUtils:LibraryBookPinsEnabled(true) then return end
	local signature = LibraryBooks.GetSignature()
	if LibraryBooks.signature == signature then return end
	local first = LibraryBooks.signature == nil
	LibraryBooks.signature = signature
	if first then return end
	wipe(LibraryBooks.cache)
	MapUtils:RefreshExploredPins()
end

MapUtils:RegisterSharedSettings({
	["keys"] = {LibraryBooks.pinsKey, LibraryBooks.unexploredKey},
	["getDB"] = function() return MAUTTAB end,
	["get"] = function(key) return LibraryBooks.Get(key) end,
	["set"] = function(key, value) MAUTTAB[key] = value end,
	["onChange"] = function(key, value)
		MapUtils:SetMapOption(key, value, function() MapUtils:RefreshLibraryBooks() end)
		if MapUtils.RefreshPinToggles ~= nil then MapUtils:RefreshPinToggles() end
	end,
})

LibraryBooks.frame = CreateFrame("Frame")
LibraryBooks.frame:RegisterEvent("QUEST_TURNED_IN")
LibraryBooks.frame:RegisterEvent("BAG_UPDATE_DELAYED")
LibraryBooks.frame:SetScript("OnEvent", function() LibraryBooks.CheckChanged() end)
if WorldMapFrame ~= nil then WorldMapFrame:HookScript("OnShow", function() LibraryBooks.CheckChanged() end) end
MapUtils.ProfileTable("LibraryBooks", LibraryBooks)
