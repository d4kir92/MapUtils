local _, MapUtils = ...
local LibraryBooks = {
	pinsKey = "LIBRARYBOOKWORLDMAPPINS",
	unexploredKey = "LIBRARYBOOKSHOWUNEXPLORED",
	defaults = {
		LIBRARYBOOKWORLDMAPPINS = false,
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

function MapUtils:LibraryBookPinsEnabled()
	return MapUtils:LibraryBookPinsAvailable() and LibraryBooks.Get(LibraryBooks.pinsKey)
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

	return done and "done" or "missing", false
end

function LibraryBooks.GetIcon(book)
	local icon = C_Item ~= nil and C_Item.GetItemIconByID ~= nil and C_Item.GetItemIconByID(book.itemId) or nil

	return icon or LibraryBooks.icon
end

function LibraryBooks.GetName(book)
	local name = C_Item ~= nil and C_Item.GetItemNameByID ~= nil and C_Item.GetItemNameByID(book.itemId) or nil

	return name or book.name
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
				if point[1] == mapID then
					tinsert(list, {
						kind = "librarybook",
						x = point[2],
						y = point[3],
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
	if book.subzone ~= nil then GameTooltip:AddLine(book.subzone, 1, 0.82, 0) end
	if book.note ~= nil then GameTooltip:AddLine(book.note, 1, 1, 1, true) end
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
	if not MapUtils:LibraryBookPinsEnabled() then return end
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
LibraryBooks.frame:SetScript("OnEvent", function() LibraryBooks.CheckChanged() end)
if WorldMapFrame ~= nil then WorldMapFrame:HookScript("OnShow", function() LibraryBooks.CheckChanged() end) end
MapUtils.ProfileTable("LibraryBooks", LibraryBooks)
