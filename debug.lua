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

	MapUtils:RefreshDebugPinContext()
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

local PinEdit = {
	["tracked"] = {},
	["addEntries"] = {},
	["instanceEntries"] = {},
	["worldKinds"] = {"pier", "dungeon", "flight", "meetingstone", "spirithealer", "crossing"},
	["instanceKinds"] = {"boss", "item", "entrance", "level"},
	["addKindIndex"] = 1,
	["steps"] = {0.1, 0.01, 0.001},
	["arrows"] = {{"^", 28, 0, 0, -1}, {"<", 0, -22, -1, 0}, {">", 56, -22, 1, 0}, {"v", 28, -44, 0, 1}},
}

function PinEdit.GetKind(entry)
	return entry.kind or "pier"
end

function PinEdit.GetTable(key)
	if type(MAUTTAB) ~= "table" then return {} end
	if type(MAUTTAB[key]) ~= "table" then MAUTTAB[key] = {} end

	return MAUTTAB[key]
end

function PinEdit.GetKey(mapID, entry)
	return format("%s|%s|%.5f|%.5f%s", PinEdit.GetKind(entry), tostring(mapID), entry.origX, entry.origY, entry.nodeID ~= nil and "|" .. entry.nodeID or "")
end

function PinEdit.Round(value)
	value = math.min(math.max(value, 0), 1)

	return math.floor(value * 100000 + 0.5) / 100000
end

function PinEdit.GetMapName(mapID)
	local info = tonumber(mapID) ~= nil and C_Map.GetMapInfo(tonumber(mapID)) or nil
	if info ~= nil and info.name ~= nil and info.name ~= "" then return info.name end

	return "?"
end

function PinEdit.Describe(entry)
	if entry == nil then return "" end
	if entry.kind == "crossing" then return format("dest %s %s", tostring(entry.destMapID), entry.name or "") end

	return entry.name or (entry.kind == "spirithealer" and MapUtils:Trans("LID_SPIRITHEALER")) or ""
end

function PinEdit.GetDirection(up)
	return up == true and "up" or "down"
end

function PinEdit.FormatEdit(key, edit)
	local kind, mapID, x, y = strsplit("|", key)
	local tracked = PinEdit.tracked[key]
	local text = format("%s [%s] {%s, %s} -> ", kind, mapID, x, y)
	if edit.deleted then
		text = text .. "delete"
	else
		text = text .. format("{%.5f, %.5f", edit.x or edit[1], edit.y or edit[2])
		if edit.up ~= nil then text = text .. ", " .. PinEdit.GetDirection(edit.up) end
		if edit.dest ~= nil then text = text .. ", dest " .. edit.dest end
		for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
			if edit[field] ~= nil then text = text .. ", " .. field .. " " .. tostring(edit[field]) end
		end
		text = text .. "}"
	end

	if tracked ~= nil then text = format("%s -- %s", text, PinEdit.Describe(tracked[2])) end

	return text
end

function PinEdit.FormatAdd(record)
	local text = format("%s [%s] add {%.5f, %.5f", record.kind or "crossing", tostring(record.map), record.x, record.y)
	if record.dest ~= nil then text = text .. ", dest " .. tostring(record.dest) end
	if record.kind == nil or record.kind == "crossing" then text = text .. ", " .. PinEdit.GetDirection(record.up) end
	for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
		if record[field] ~= nil then text = text .. ", " .. field .. " " .. tostring(record[field]) end
	end
	return text .. "} -- " .. (record.name or PinEdit.GetMapName(record.dest))
end

function PinEdit.Track(mapID, entry)
	if entry.kind == "pier" and entry.destMapID == nil and entry.routes ~= nil and entry.routes[1] ~= nil then entry.destMapID = entry.routes[1].mapID end
	entry.origX = entry.x
	entry.origY = entry.y
	entry.origUp = entry.up
	entry.origDest = entry.destMapID
	entry.origRoutes = entry.routes
	entry.origName = entry.name
	entry.origInstance = entry.instance
	entry.origInstanceMap = entry.instanceMap
	entry.origInstanceMapLevel = entry.instanceMapLevel
	entry.origTarget = entry.target
	entry.origFaction = entry.faction
	entry.origEntrance = entry.entrance
	local key = PinEdit.GetKey(mapID, entry)
	PinEdit.tracked[key] = {mapID, entry}
	local edit = PinEdit.GetTable("PINEDITS")[key]
	if type(edit) ~= "table" then return end
	entry.x = edit.x or edit[1] or entry.x
	entry.y = edit.y or edit[2] or entry.y
	if edit.up ~= nil then entry.up = edit.up end
	if edit.dest ~= nil then
		entry.destMapID = edit.dest
		entry.name = PinEdit.GetMapName(edit.dest)
	end

	for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
		if edit[field] ~= nil then entry[field] = edit[field] end
	end
	if entry.kind == "pier" and entry.destMapID ~= nil then entry.routes = {{dest = PinEdit.GetMapName(entry.destMapID), mapID = entry.destMapID}} end
	if edit.instance ~= nil then entry.instanceMap, entry.instanceMapLevel = nil, nil end
	entry.deleted = edit.deleted == true
	entry.worldPos = nil
end

function PinEdit.GetAddEntry(record)
	local entry = PinEdit.addEntries[record]
	if entry == nil then
		entry = {tips = {}, routes = {}, added = record}
		PinEdit.addEntries[record] = entry
	end
	entry.kind = record.kind or "crossing"
	entry.x, entry.y = record.x, record.y
	entry.up = record.up == true
	entry.destMapID = record.dest
	entry.name = record.name or PinEdit.GetMapName(record.dest)
	entry.instance = record.instance
	entry.target = record.target
	entry.faction = record.faction or ((entry.kind == "pier" or entry.kind == "flight") and "Neutral" or nil)
	entry.entrance = record.entrance
	entry.discoveryKnown = entry.kind == "flight"
	entry.undiscovered = false
	if entry.kind == "pier" and entry.destMapID ~= nil then entry.routes = {{dest = PinEdit.GetMapName(entry.destMapID), mapID = entry.destMapID}} end
	return entry
end

function MapUtils:IsPinEditable(entry)
	return entry ~= nil and entry.x ~= nil and entry.y ~= nil
end

function MapUtils:ApplyPinEdits(mapID, list, enabledKinds)
	local result = {}
	for _, entry in ipairs(list or {}) do
		if entry.origX == nil and entry.added == nil and MapUtils:IsPinEditable(entry) then PinEdit.Track(mapID, entry) end
		if not entry.deleted or debugging then tinsert(result, entry) end
	end
	if type(enabledKinds) ~= "table" then enabledKinds = {crossing = enabledKinds == true} end
	for _, record in ipairs(PinEdit.GetTable("PINADDS")) do
		local kind = record.kind or "crossing"
		if record.map == mapID and (debugging or enabledKinds[kind]) then tinsert(result, PinEdit.GetAddEntry(record)) end
	end
	if #result == 0 then return nil end
	return result
end

function MapUtils:GetDebugInstancePins(info, skipRefresh)
	if info.key == nil then return nil end
	local mapKey = "instance:" .. info.key
	PinEdit.instanceMapKey = mapKey
	local entries = {}
	for _, row in ipairs(MapUtils.INSTANCEPINS ~= nil and MapUtils.INSTANCEPINS[info.key] or {}) do
		local entry = PinEdit.instanceEntries[row]
		if entry == nil then
			entry = {kind = row[1], x = row[2], y = row[3], target = row[4], name = row[1] == "boss" and row[5] or nil, row = row}
			PinEdit.instanceEntries[row] = entry
		end
		tinsert(entries, entry)
	end
	local rows = {}
	for _, entry in ipairs(MapUtils:ApplyPinEdits(mapKey, entries, {boss = true, item = true, entrance = true, level = true}) or {}) do
		local row = {}
		for key, value in pairs(entry.row or {}) do row[key] = value end
		row[1], row[2], row[3], row[4] = entry.kind, entry.x, entry.y, entry.target
		if entry.kind == "boss" then
			row[5] = entry.name or "Boss"
			if entry.target ~= entry.origTarget then row[7] = nil end
		end
		if entry.kind == "item" and row[4] == nil then row[4] = 134400 end
		row.debugEntry, row.debugMapKey = entry, mapKey
		tinsert(rows, row)
	end
	if not skipRefresh then PinEdit.Refresh() end
	return rows
end

function MapUtils:RefreshDebugPinContext()
	local instance = MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
	if PinEdit.instanceContext == instance then return end
	PinEdit.instanceContext = instance
	PinEdit.addKindIndex = 1
	PinEdit.Refresh()
end
function PinEdit.RefreshPins()
	MapUtils:RefreshPins()
	if MapUtils.RefreshInstanceMap ~= nil then MapUtils:RefreshInstanceMap() end
end
function MapUtils:GetDebugPinAlpha(entry)
	if entry.deleted then return 0.25 end
	if debugging and PinEdit.selected ~= nil and PinEdit.selected ~= entry then return 0.5 end

	return 1
end

function PinEdit.CreateButton(parent, label, width, onClick)
	local button = MapUtils:CreateButton(nil, parent)
	button:SetSize(width, width <= 26 and 22 or 24)
	button:SetText(label)
	button:SetScript("OnClick", onClick)

	return button
end

function PinEdit.CreateInput(parent, label, x, y, onApply, textInput)
	local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 4)
	text:SetText(label)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(80, 18)
	box:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 22, y)
	box:SetAutoFocus(false)
	box.label = text
	box:SetScript("OnEnterPressed", function(self)
		local input = self:GetText():gsub(",", ".")
		local value = textInput and self:GetText() or tonumber(input)
		self:ClearFocus()
		if value ~= nil and PinEdit.selected ~= nil then
			onApply(PinEdit.selected, value)
		else
			PinEdit.Refresh()
		end
	end)

	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		PinEdit.Refresh()
	end)

	return box
end

function PinEdit.Save(entry)
	if entry.added ~= nil then
		entry.added.x = entry.x
		entry.added.y = entry.y
		entry.added.up = entry.up == true
		entry.added.dest = entry.destMapID
		for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
			entry.added[field] = entry[field]
		end

		return
	end

	local edits = PinEdit.GetTable("PINEDITS")
	local key = PinEdit.GetKey(PinEdit.selectedMapID, entry)
	local edit = {}
	local changed = false
	if math.abs(entry.x - entry.origX) > 0.000001 or math.abs(entry.y - entry.origY) > 0.000001 then changed = true end
	if entry.kind == "crossing" and (entry.up == true) ~= (entry.origUp == true) then
		edit.up = entry.up == true
		changed = true
	end

	if entry.destMapID ~= entry.origDest then
		edit.dest = entry.destMapID
		changed = true
	end

	for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
		local original = "orig" .. field:sub(1, 1):upper() .. field:sub(2)
		if entry[field] ~= entry[original] and entry[field] ~= nil then
			edit[field] = entry[field]
			changed = true
		end
	end
	if entry.deleted then
		edit.deleted = true
		changed = true
	end

	if not changed then
		edits[key] = nil

		return
	end

	edit.x = entry.x
	edit.y = entry.y
	edits[key] = edit
end

function PinEdit.Update(entry)
	entry.worldPos = nil
	PinEdit.Save(entry)
	PinEdit.RefreshPins()
	PinEdit.Refresh()
end

function PinEdit.SetPos(x, y)
	local entry = PinEdit.selected
	if entry == nil then return end
	entry.x = PinEdit.Round(x)
	entry.y = PinEdit.Round(y)
	PinEdit.Update(entry)
end

function PinEdit.SetDest(entry, value)
	value = math.floor(value)
	if C_Map.GetMapInfo(value) == nil then
		MapUtils:INFO(format("uiMapID %d is unknown to this client", value))
		PinEdit.Refresh()

		return
	end

	entry.destMapID = value
	entry.name = value == entry.origDest and entry.origName or PinEdit.GetMapName(value)
	if entry.kind == "pier" then entry.routes = {{dest = PinEdit.GetMapName(value), mapID = value}} end
	PinEdit.Update(entry)
end

function PinEdit.ToggleUp()
	local entry = PinEdit.selected
	if entry == nil or entry.kind ~= "crossing" then return end
	entry.up = entry.up ~= true
	PinEdit.Update(entry)
end

function PinEdit.Reset()
	local entry = PinEdit.selected
	if entry == nil or entry.added ~= nil then return end
	entry.x = entry.origX
	entry.y = entry.origY
	entry.up = entry.origUp
	entry.destMapID = entry.origDest
	entry.instanceMap = entry.origInstanceMap
	entry.instanceMapLevel = entry.origInstanceMapLevel
	entry.name = entry.origName
	for _, field in ipairs({"instance", "target", "faction", "entrance"}) do
		entry[field] = entry["orig" .. field:sub(1, 1):upper() .. field:sub(2)]
	end
	if entry.kind == "pier" then entry.routes = entry.origRoutes or entry.routes end
	entry.deleted = false
	PinEdit.Update(entry)
end

function PinEdit.Delete()
	local entry = PinEdit.selected
	if entry == nil then return end
	if entry.added == nil then
		entry.deleted = not entry.deleted
		PinEdit.Update(entry)

		return
	end

	local adds = PinEdit.GetTable("PINADDS")
	for index = #adds, 1, -1 do
		if adds[index] == entry.added then tremove(adds, index) end
	end

	PinEdit.addEntries[entry.added] = nil
	PinEdit.selected = nil
	PinEdit.RefreshPins()
	PinEdit.Refresh()
end

function PinEdit.Add(up, kind)
	local instance = MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
	local kinds = instance and PinEdit.instanceKinds or PinEdit.worldKinds
	kind = kind or kinds[PinEdit.addKindIndex] or kinds[1]
	local mapID = instance and PinEdit.instanceMapKey or WorldMapFrame:GetMapID()
	if mapID == nil then return end
	local record = {
		["map"] = mapID,
		["kind"] = kind,
		["name"] = kind == "spirithealer" and MapUtils:Trans("LID_SPIRITHEALER") or kind,
		["faction"] = (kind == "pier" or kind == "flight") and "Neutral" or nil,
		["entrance"] = kind == "dungeon" and "dungeon" or nil,
		["target"] = kind == "item" and 134400 or kind == "entrance" and "dungeon" or kind == "level" and mapID:sub(10) or nil,
		["x"] = 0.5,
		["y"] = 0.5,
		["up"] = up == true
	}

	tinsert(PinEdit.GetTable("PINADDS"), record)
	PinEdit.selected = PinEdit.GetAddEntry(record)
	PinEdit.selectedMapID = mapID
	PinEdit.RefreshPins()
	PinEdit.Refresh()
	PinEdit.editor.name:SetFocus()
end

function PinEdit.ResetAll()
	for _, tracked in pairs(PinEdit.tracked) do
		local entry = tracked[2]
		entry.x = entry.origX
		entry.y = entry.origY
		entry.up = entry.origUp
		entry.destMapID = entry.origDest
		entry.instanceMap = entry.origInstanceMap
		entry.instanceMapLevel = entry.origInstanceMapLevel
		entry.name = entry.origName
		for _, field in ipairs({"instance", "target", "faction", "entrance"}) do
			entry[field] = entry["orig" .. field:sub(1, 1):upper() .. field:sub(2)]
		end
		if entry.kind == "pier" then entry.routes = entry.origRoutes or entry.routes end
		entry.deleted = false
		entry.worldPos = nil
	end

	if type(MAUTTAB) == "table" then
		MAUTTAB["PINEDITS"] = {}
		MAUTTAB["PINADDS"] = {}
	end

	wipe(PinEdit.addEntries)
	PinEdit.selected = nil
	PinEdit.RefreshPins()
	PinEdit.Refresh()
end

function PinEdit.CreateWindow(name, width, height)
	local window = MapUtils:CreateUIWindow({
		name = name, parent = WorldMapFrame, width = width, height = height,
		title = "MapUtils Debug", resizable = false, escClose = false,
	})
	window:ClearAllPoints()
	window:SetFrameStrata("DIALOG")
	window.scrollFrame:Hide()
	if window.scrollBar ~= nil then window.scrollBar:Hide() end
	window.TitleText = window.titleBar.Title
	return window
end

function PinEdit.CreateTypeDropdown(parent)
	local modern = MapUtils:CheckTemplates("WowStyle1DropdownTemplate")
	local dropdown = modern and CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate") or MapUtils:CreateButton(nil, parent)
	dropdown:SetSize(160, 24)
	local function Select(index)
		PinEdit.addKindIndex = index
		PinEdit.Refresh()
	end
	if modern then
		dropdown:SetupMenu(function(_, root)
			local instance = MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
			for index, kind in ipairs(instance and PinEdit.instanceKinds or PinEdit.worldKinds) do
				root:CreateRadio(kind, function() return PinEdit.addKindIndex == index end, function() Select(index) end)
			end
		end)
	else
		dropdown:SetScript("OnClick", function(button)
			local instance = MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
			local entries = {}
			for index, kind in ipairs(instance and PinEdit.instanceKinds or PinEdit.worldKinds) do
				tinsert(entries, {text = kind, checked = function() return PinEdit.addKindIndex == index end, func = function() Select(index) end})
			end
			MapUtils:ShowContextMenu(button, entries)
		end)
	end
	return dropdown
end

function PinEdit.CreateUI()
	if PinEdit.editor ~= nil then return end
	local editor = PinEdit.CreateWindow("MapUtilsDebugPinEditor", 300, 328)
	editor:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 8, 0)
	if editor.CloseButton ~= nil then
		editor.CloseButton:HookScript("OnClick", function()
			PinEdit.selected = nil
			PinEdit.RefreshPins()
		end)
	end

	editor.TitleText:SetText("MapUtils Debug – Pin")
	editor.info = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	editor.info:SetPoint("TOPLEFT", editor, "TOPLEFT", 12, -30)
	editor.info:SetWidth(276)
	editor.info:SetJustifyH("LEFT")
	editor.info:SetWordWrap(false)
	editor.x = PinEdit.CreateInput(editor, "X", 12, -48, function(entry, value) PinEdit.SetPos(value, entry.y) end)
	editor.y = PinEdit.CreateInput(editor, "Y", 150, -48, function(entry, value) PinEdit.SetPos(entry.x, value) end)
	editor.dest = PinEdit.CreateInput(editor, "To", 12, -72, PinEdit.SetDest)
	editor.name = PinEdit.CreateInput(editor, "Name", 12, -98, function(entry, value)
		entry.name = value
		PinEdit.Update(entry)
	end, true)
	editor.name:SetWidth(230)
	editor.name:ClearAllPoints()
	editor.name:SetPoint("TOPLEFT", editor, "TOPLEFT", 48, -98)
	editor.target = PinEdit.CreateInput(editor, "ID", 12, -122, function(entry, value)
		if entry.kind == "dungeon" or entry.kind == "meetingstone" then
			local id = tonumber(value)
			if id == nil or id <= 0 then return end
			entry.instance = math.floor(id)
			entry.instanceMap, entry.instanceMapLevel = nil, nil
		elseif entry.kind == "boss" or entry.kind == "item" then
			local id = tonumber(value)
			if id == nil or id <= 0 then return end
			entry.target = math.floor(id)
		else
			entry.target = value
		end
		PinEdit.Update(entry)
	end, true)
	editor.faction = PinEdit.CreateButton(editor, "Neutral", 100, function()
		local entry = PinEdit.selected
		if entry == nil then return end
		entry.faction = entry.faction == "Neutral" and "Alliance" or entry.faction == "Alliance" and "Horde" or "Neutral"
		PinEdit.Update(entry)
	end)
	editor.faction:SetPoint("TOPLEFT", editor, "TOPLEFT", 150, -122)
	editor.entrance = PinEdit.CreateButton(editor, "Dungeon", 100, function()
		local entry = PinEdit.selected
		if entry == nil then return end
		local value = entry.kind == "entrance" and entry.target or entry.entrance
		value = value == "raid" and "dungeon" or "raid"
		if entry.kind == "entrance" then entry.target = value else entry.entrance = value end
		PinEdit.Update(entry)
	end)
	editor.entrance:SetPoint("TOPLEFT", editor, "TOPLEFT", 150, -146)
	editor.destName = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	editor.destName:SetPoint("LEFT", editor.dest, "RIGHT", 8, 0)
	editor.destName:SetWidth(160)
	editor.destName:SetJustifyH("LEFT")
	editor.destName:SetWordWrap(false)
	for index, step in ipairs(PinEdit.steps) do
		local left = 12 + (index - 1) * 94
		local label = editor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", editor, "TOPLEFT", left, -178)
		label:SetText(tostring(step))
		for _, def in ipairs(PinEdit.arrows) do
			local button = PinEdit.CreateButton(editor, def[1], 26, function()
				local entry = PinEdit.selected
				if entry ~= nil then PinEdit.SetPos(entry.x + def[4] * step, entry.y + def[5] * step) end
			end)

			button:SetPoint("TOPLEFT", editor, "TOPLEFT", left + def[2], -194 + def[3])
		end
	end

	editor.reset = PinEdit.CreateButton(editor, "Reset", 70, PinEdit.Reset)
	editor.reset:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 12, 10)
	editor.delete = PinEdit.CreateButton(editor, "Delete", 70, PinEdit.Delete)
	editor.delete:SetPoint("LEFT", editor.reset, "RIGHT", 6, 0)
	editor.up = PinEdit.CreateButton(editor, "Down", 70, PinEdit.ToggleUp)
	editor.up:SetPoint("LEFT", editor.delete, "RIGHT", 6, 0)
	editor:Hide()
	PinEdit.editor = editor
	local output = PinEdit.CreateWindow("MapUtilsDebugPinOutput", 460, 226)
	output:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 0, -8)
	output.scroll = CreateFrame("ScrollFrame", nil, output, "UIPanelScrollFrameTemplate")
	output.scroll:SetPoint("TOPLEFT", output, "TOPLEFT", 12, -30)
	output.scroll:SetPoint("BOTTOMRIGHT", output, "BOTTOMRIGHT", -32, 62)
	output.edit = CreateFrame("EditBox", nil, output.scroll)
	output.edit:SetMultiLine(true)
	output.edit:SetAutoFocus(false)
	output.edit:SetFontObject(ChatFontNormal)
	output.edit:SetWidth(410)
	output.edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	output.scroll:SetScrollChild(output.edit)
	output.select = PinEdit.CreateButton(output, "Select all", 80, function()
		output.edit:SetFocus()
		output.edit:HighlightText()
	end)

	output.select:SetPoint("BOTTOMLEFT", output, "BOTTOMLEFT", 12, 10)
	output.resetAll = PinEdit.CreateButton(output, "Reset all", 80, PinEdit.ResetAll)
	output.resetAll:SetPoint("LEFT", output.select, "RIGHT", 6, 0)
	output.kind = PinEdit.CreateTypeDropdown(output)
	output.kind:SetPoint("BOTTOMLEFT", output, "BOTTOMLEFT", 12, 36)
	output.add = PinEdit.CreateButton(output, "+ Add pin", 100, function() PinEdit.Add(false) end)
	output.add:SetPoint("LEFT", output.kind, "RIGHT", 6, 0)
	output:Hide()
	PinEdit.output = output
end

function PinEdit.PrimeSources()
	if MapUtils.PrimeDebugPinMap == nil then return end
	local maps = {}
	for key in pairs(PinEdit.GetTable("PINEDITS")) do
		local _, mapID = strsplit("|", key)
		if mapID ~= nil then maps[tonumber(mapID) or mapID] = true end
	end
	for _, record in ipairs(PinEdit.GetTable("PINADDS")) do
		if record.map ~= nil then maps[record.map] = true end
	end
	for mapID in pairs(maps) do
		MapUtils:PrimeDebugPinMap(mapID)
	end
end

function PinEdit.IsDifferent(key, edit)
	local tracked = PinEdit.tracked[key]
	if tracked == nil then return false end
	if edit.deleted then return true end
	local entry = tracked[2]
	local x, y = edit.x or edit[1], edit.y or edit[2]
	if x ~= nil and math.abs(x - entry.origX) > 0.000001 then return true end
	if y ~= nil and math.abs(y - entry.origY) > 0.000001 then return true end
	if edit.up ~= nil and (edit.up == true) ~= (entry.origUp == true) then return true end
	if edit.dest ~= nil and edit.dest ~= entry.origDest then return true end
	for _, field in ipairs({"name", "instance", "target", "faction", "entrance"}) do
		local original = "orig" .. field:sub(1, 1):upper() .. field:sub(2)
		if edit[field] ~= nil and edit[field] ~= entry[original] then return true end
	end
	return false
end

function PinEdit.IsNew(record)
	local kind = record.kind or "crossing"
	for _, tracked in pairs(PinEdit.tracked) do
		local entry = tracked[2]
		if tracked[1] == record.map and PinEdit.GetKind(entry) == kind and math.abs(record.x - entry.origX) <= 0.000001 and math.abs(record.y - entry.origY) <= 0.000001 then
			local same = true
			if kind == "crossing" and ((record.up == true) ~= (entry.origUp == true) or record.dest ~= entry.origDest) then same = false end
			if kind == "pier" and record.dest ~= entry.origDest then same = false end
			for _, field in ipairs({"instance", "target", "faction", "entrance"}) do
				local original = "orig" .. field:sub(1, 1):upper() .. field:sub(2)
				if record[field] ~= nil and record[field] ~= entry[original] then same = false end
			end
			if record.name ~= nil and record.name ~= kind and record.name ~= entry.origName and not (kind == "spirithealer" and entry.origName == nil and record.name == MapUtils:Trans("LID_SPIRITHEALER")) then same = false end
			if same then return false end
		end
	end
	return true
end
function PinEdit.Refresh()
	if PinEdit.editor == nil then return end
	if not debugging then
		PinEdit.editor:Hide()
		PinEdit.output:Hide()

		return
	end

	PinEdit.PrimeSources()
	local lines = {}
	for key, edit in pairs(PinEdit.GetTable("PINEDITS")) do
		if type(edit) == "table" and PinEdit.IsDifferent(key, edit) then tinsert(lines, PinEdit.FormatEdit(key, edit)) end
	end

	for _, record in ipairs(PinEdit.GetTable("PINADDS")) do
		if PinEdit.IsNew(record) then tinsert(lines, PinEdit.FormatAdd(record)) end
	end

	table.sort(lines)
	PinEdit.output.TitleText:SetText(format("MapUtils Debug – Pin changes (%d)", #lines))
	PinEdit.output.edit:SetText(table.concat(lines, "\n"))
	local instance = MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()
	local kinds = instance and PinEdit.instanceKinds or PinEdit.worldKinds
	MapUtils:SetDropdownText(PinEdit.output.kind, kinds[PinEdit.addKindIndex] or kinds[1])
	PinEdit.output:Show()
	local entry = PinEdit.selected
	if entry == nil then
		PinEdit.editor:Hide()

		return
	end

	local editor = PinEdit.editor
	local isCrossing = entry.kind == "crossing"
	local suffix = entry.added ~= nil and " (added)" or entry.deleted and " (deleted)" or ""
	editor.info:SetText(format("%s [%s] %s%s", PinEdit.GetKind(entry), tostring(PinEdit.selectedMapID), PinEdit.Describe(entry), suffix))
	if not editor.x:HasFocus() then editor.x:SetText(format("%.5f", entry.x)) end
	if not editor.y:HasFocus() then editor.y:SetText(format("%.5f", entry.y)) end
	if not editor.dest:HasFocus() then editor.dest:SetText(entry.destMapID ~= nil and tostring(entry.destMapID) or "") end
	editor.dest:SetShown(isCrossing or entry.kind == "pier")
	editor.dest.label:SetShown(isCrossing or entry.kind == "pier")
	editor.destName:SetShown(isCrossing or entry.kind == "pier")
	editor.destName:SetText(entry.name or "")
	local hasTarget = entry.kind == "dungeon" or entry.kind == "meetingstone" or entry.kind == "boss" or entry.kind == "item" or entry.kind == "level"
	if not editor.name:HasFocus() then editor.name:SetText(PinEdit.Describe(entry)) end
	if not editor.target:HasFocus() then editor.target:SetText(tostring(entry.instance or entry.target or "")) end
	editor.target:SetShown(hasTarget)
	editor.target.label:SetShown(hasTarget)
	editor.target.label:SetText(entry.kind == "level" and "To" or "ID")
	editor.faction:SetShown(entry.kind == "pier" or entry.kind == "flight")
	editor.faction:SetText(entry.faction or "Neutral")
	editor.entrance:SetShown(entry.kind == "dungeon" or entry.kind == "entrance")
	editor.entrance:SetText(entry.kind == "entrance" and tostring(entry.target or "dungeon") or entry.entrance or "dungeon")
	editor.up:SetShown(isCrossing)
	editor.up:SetText(entry.up == true and "Up" or "Down")
	editor.reset:SetEnabled(entry.added == nil)
	editor.delete:SetText(entry.deleted and "Restore" or "Delete")
	editor:Show()
end

function MapUtils:SelectDebugPin(mapID, entry)
	if not debugging or mapID == nil or not MapUtils:IsPinEditable(entry) then return end
	if entry.origX == nil and entry.added == nil then PinEdit.Track(mapID, entry) end
	PinEdit.CreateUI()
	PinEdit.selected = entry
	PinEdit.selectedMapID = mapID
	PinEdit.RefreshPins()
	PinEdit.Refresh()
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
		PinEdit.CreateUI()
		PinEdit.Refresh()
		PinEdit.RefreshPins()
		frame.elapsed = 0
		frame:SetScript("OnUpdate", OnUpdate)
		MapUtils:INFO("Debug mode on - the cursor shows uiMapID and coordinates while the world map is open, off again after a /reload")
	else
		frame:SetScript("OnUpdate", nil)
		display:Hide()
		PinEdit.selected = nil
		PinEdit.Refresh()
		PinEdit.RefreshPins()
		MapUtils:INFO("Debug mode off")
	end
end
function MapUtils:PrintDebugHelp()
	self:INFO("MapUtils Debug-Hilfe ([Text] ist optional):")
	self:INFO("/maputils debug help - Diese Hilfe anzeigen")
	self:INFO("/maputils debug - Debug-Anzeige ein/aus: Karten-ID, Mauskoordinaten und Pin-Editor")
	self:INFO("Im Debug-Modus: Linksklick auf ein Weltkarten- oder Instanz-Symbol öffnet den Pin-Editor; X/Y eingeben + Enter oder mit den Pfeilen um 0.1 / 0.01 / 0.001 verschieben, Reset stellt den Originalwert wieder her")
	self:INFO("Pin-Editor: 'Delete' blendet das Symbol aus (im Debug-Modus schwach sichtbar, 'Restore' holt es zurück); bei Zonenübergängen 'To' = Ziel-uiMapID + Enter, 'Up'/'Down' wechselt das Höhlen-Symbol")
	self:INFO("Pin-Änderungen: Im Dropdown die Pin-Art wählen, '+ Add pin' erstellt einen Pin in der Kartenmitte; auch auf Instanzkarten. Pin anklicken, Name/ID/Ziel setzen oder Delete/Restore verwenden. 'Select all' und Strg+C kopiert Änderungen, 'Reset all' verwirft alle; gespeichert in MAUTTAB.PINEDITS / PINADDS")
	self:INFO("/maputils pos - Spielerposition ausgeben")
	self:INFO("/maputils fade - Diagnose zum Ein-/Ausblenden von Weltkarte und Gebietskarte ausgeben")
	self:INFO("/mappins debug - Karten-, Symbol- und Wegpunktstatus ausgeben")
	self:INFO("/mappins debug <Name> - Nur passende Symbole prüfen, z. B. /mappins debug ratchet")
	self:INFO("Für Symbol-Diagnosen zuerst die betroffene Karte öffnen. Der Namensfilter ignoriert Groß-/Kleinschreibung.")
	self:INFO("/mappins icon - Verfügbare Symbolvarianten prüfen")
	self:INFO("/mappins icon <Atlas oder Texturpfad> - Pier-Symbol testweise ändern")
	self:INFO("/mappins icon reset - Pier-Symbol zurücksetzen")
	self:INFO("/mappins lfg [Text] - Dungeon-Namen, IDs und Levelbereiche abfragen")
	self:INFO("/mappins activities [Text] - Gruppensuche-Aktivitäten und Levelbereiche abfragen")
	self:INFO("/mappins maps [Text] - Karten-Namen und IDs abfragen")
	self:INFO("/mappins entrances - Dungeon-Eingänge aus der Client-API abfragen")
	self:INFO("/mappins [Notiz] - Aktuelle Spielerkoordinaten speichern")
	self:INFO("/mappins list - Gespeicherte Aufnahmen anzeigen")
	self:INFO("/mappins clear - Gespeicherte Aufnahmen löschen")
	self:INFO("Gefilterte Symbol-Diagnosen und Datenabfragen werden gespeichert; /reload oder Ausloggen schreibt sie in SavedVariables/MapUtils.lua.")
	self:INFO("/mapdocks unterstützt dieselben Befehle wie /mappins.")
end
