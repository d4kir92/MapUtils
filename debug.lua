local _, MapUtils = ...
local UPDATE_INTERVAL = 0.05
local OFFSET_X = 18
local OFFSET_Y = -8
local debugging = false
local display = nil
local updater = nil
local waypointWindow = nil
local function GetDebugWaypoint()
	if C_Map == nil or C_Map.GetUserWaypoint == nil then return nil end
	local point = C_Map.GetUserWaypoint()
	if point == nil or point.position == nil then return nil end

	return point
end

local function RefreshWaypointWindow()
	if waypointWindow == nil then return end
	local window = waypointWindow
	local point = GetDebugWaypoint()
	local enabled = point ~= nil and C_Map.SetUserWaypoint ~= nil
	window.syncing = true
	if enabled then
		local x, y = point.position.x, point.position.y
		window.coordinates:SetText(format("uiMapID: %s\nX: %.3f   Y: %.3f\nZ: %s", tostring(point.uiMapID), x * 100, y * 100, point.z ~= nil and format("%.2f", point.z) or "—"))
		local z = point.z or 0
		window.slider:SetMinMaxValues(math.min(-2000, z), math.max(2000, z))
		window.slider:SetValue(z)
		if not window.input:HasFocus() then window.input:SetText(format("%.2f", z)) end
		window.slider:Enable()
		window.input:Enable()
	else
		window.coordinates:SetText("Kein World-Map-Pin gesetzt")
		window.slider:Disable()
		window.input:Disable()
		window.input:ClearFocus()
		window.input:SetText("")
	end

	window.slider:SetAlpha(enabled and 1 or 0.4)
	window.input:SetAlpha(enabled and 1 or 0.4)
	window.syncing = false
end

local function SetWaypointHeight(value)
	if waypointWindow == nil or waypointWindow.syncing then return end
	if value == nil or value ~= value or value == math.huge or value == -math.huge then return end
	local point = GetDebugWaypoint()
	if point == nil or C_Map.SetUserWaypoint == nil then return end
	local replacement = {uiMapID = point.uiMapID, position = {x = point.position.x, y = point.position.y}, z = value}
	local wasSet = C_Map.SetUserWaypoint(replacement)
	local actual = GetDebugWaypoint()
	if wasSet ~= false and actual ~= nil and actual.z ~= nil and math.abs(actual.z - value) < 0.01 then
		waypointWindow.status:SetText(MapUtils:IsForever() and "Z gespeichert; Weltmarker bleibt clientgesteuert" or "Wegpunkt-Z gespeichert")
	else
		waypointWindow.status:SetText("Client übernimmt den Wegpunkt-Z nicht")
	end
	RefreshWaypointWindow()
end

local function CreateWaypointWindow()
	if waypointWindow ~= nil then return waypointWindow end
	local window = CreateFrame("Frame", "MapUtilsDebugWaypointWindow", WorldMapFrame, "BasicFrameTemplateWithInset")
	waypointWindow = window
	window:SetSize(360, 220)
	window:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 8, 0)
	window:SetClampedToScreen(true)
	window:SetFrameStrata("DIALOG")
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window.TitleText:SetText("MapUtils Debug – World-Map-Pin")
	window.coordinates = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	window.coordinates:SetPoint("TOPLEFT", 16, -38)
	window.coordinates:SetJustifyH("LEFT")
	local label = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 16, -108)
	label:SetText("Höhe (Z)")
	window.slider = CreateFrame("Slider", nil, window, "OptionsSliderTemplate")
	window.slider:SetPoint("TOPLEFT", 20, -140)
	window.slider:SetSize(180, 17)
	window.slider:SetMinMaxValues(-2000, 2000)
	window.slider:SetValueStep(1)
	if window.slider.SetObeyStepOnDrag ~= nil then window.slider:SetObeyStepOnDrag(true) end
	window.slider.Low:SetText("")
	window.slider.High:SetText("")
	window.slider:SetScript("OnValueChanged", function(_, value) SetWaypointHeight(value) end)
	window.input = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
	window.input:SetSize(82, 24)
	window.input:SetPoint("LEFT", window.slider, "RIGHT", 12, 0)
	window.status = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	window.status:SetPoint("TOPLEFT", 16, -185)
	window.status:SetJustifyH("LEFT")
	if MapUtils:IsForever() then window.status:SetText("Forever: Z steuert nicht die Weltmarker-Höhe") end
	window.input:SetAutoFocus(false)
	window.input:SetMaxLetters(16)
	window.input:SetScript("OnEnterPressed", function(self)
		local text = self:GetText():gsub(",", ".")
		local value = tonumber(text)
		self:ClearFocus()
		SetWaypointHeight(value)
		RefreshWaypointWindow()
	end)
	window.input:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		RefreshWaypointWindow()
	end)
	window.input:SetScript("OnEditFocusLost", function() RefreshWaypointWindow() end)
	window:Hide()

	return window
end

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

	RefreshWaypointWindow()
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
	return format("%s|%d|%.5f|%.5f", PinEdit.GetKind(entry), mapID, entry.origX, entry.origY)
end

function PinEdit.Round(value)
	value = math.min(math.max(value, 0), 1)

	return math.floor(value * 100000 + 0.5) / 100000
end

function PinEdit.GetMapName(mapID)
	local info = mapID ~= nil and C_Map.GetMapInfo(mapID) or nil
	if info ~= nil and info.name ~= nil and info.name ~= "" then return info.name end

	return "?"
end

function PinEdit.Describe(entry)
	if entry == nil then return "" end
	if entry.kind == "crossing" then return format("dest %s %s", tostring(entry.destMapID), entry.name or "") end

	return entry.name or ""
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
		text = text .. "}"
	end

	if tracked ~= nil then text = format("%s -- %s", text, PinEdit.Describe(tracked[2])) end

	return text
end

function PinEdit.FormatAdd(record)
	return format("crossing [%s] add {%.5f, %.5f, %s, %s} -- %s", tostring(record.map), record.x, record.y, tostring(record.dest), PinEdit.GetDirection(record.up), PinEdit.GetMapName(record.dest))
end

function PinEdit.Track(mapID, entry)
	entry.origX = entry.x
	entry.origY = entry.y
	entry.origUp = entry.up
	entry.origDest = entry.destMapID
	entry.origName = entry.name
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

	entry.deleted = edit.deleted == true
	entry.worldPos = nil
end

function PinEdit.GetAddEntry(record)
	local entry = PinEdit.addEntries[record]
	if entry == nil then
		entry = {
			["kind"] = "crossing",
			["tips"] = {},
			["added"] = record
		}

		PinEdit.addEntries[record] = entry
	end

	entry.x = record.x
	entry.y = record.y
	entry.up = record.up == true
	entry.destMapID = record.dest
	entry.name = PinEdit.GetMapName(record.dest)

	return entry
end

function MapUtils:IsPinEditable(entry)
	return entry ~= nil and entry.kind ~= "flight" and entry.x ~= nil and entry.y ~= nil
end

function MapUtils:ApplyPinEdits(mapID, list, crossingsOn)
	local result = {}
	for _, entry in ipairs(list or {}) do
		if entry.origX == nil and entry.added == nil and MapUtils:IsPinEditable(entry) then PinEdit.Track(mapID, entry) end
		if not entry.deleted or debugging then tinsert(result, entry) end
	end

	if crossingsOn then
		for _, record in ipairs(PinEdit.GetTable("PINADDS")) do
			if record.map == mapID then tinsert(result, PinEdit.GetAddEntry(record)) end
		end
	end

	if #result == 0 then return nil end

	return result
end

function MapUtils:GetDebugPinAlpha(entry)
	if entry.deleted then return 0.25 end
	if debugging and PinEdit.selected ~= nil and PinEdit.selected ~= entry then return 0.5 end

	return 1
end

function PinEdit.CreateButton(parent, label, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 20)
	button:SetText(label)
	button:SetScript("OnClick", onClick)

	return button
end

function PinEdit.CreateInput(parent, label, x, y, onApply)
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
		local value = tonumber(input)
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
	MapUtils:RefreshPins()
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
	entry.name = entry.origName
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
	MapUtils:RefreshPins()
	PinEdit.Refresh()
end

function PinEdit.Add(up)
	local mapID = WorldMapFrame:GetMapID()
	if mapID == nil then return end
	if MapUtils:GetConfig("CROSSINGWORLDMAPPINS", true) ~= true then MapUtils:INFO("Zone crossings are disabled in the settings") end
	local record = {
		["map"] = mapID,
		["x"] = 0.5,
		["y"] = 0.5,
		["up"] = up == true
	}

	tinsert(PinEdit.GetTable("PINADDS"), record)
	PinEdit.selected = PinEdit.GetAddEntry(record)
	PinEdit.selectedMapID = mapID
	MapUtils:RefreshPins()
	PinEdit.Refresh()
	PinEdit.editor.dest:SetFocus()
end

function PinEdit.ResetAll()
	for _, tracked in pairs(PinEdit.tracked) do
		local entry = tracked[2]
		entry.x = entry.origX
		entry.y = entry.origY
		entry.up = entry.origUp
		entry.destMapID = entry.origDest
		entry.name = entry.origName
		entry.deleted = false
		entry.worldPos = nil
	end

	if type(MAUTTAB) == "table" then
		MAUTTAB["PINEDITS"] = {}
		MAUTTAB["PINADDS"] = {}
	end

	wipe(PinEdit.addEntries)
	PinEdit.selected = nil
	MapUtils:RefreshPins()
	PinEdit.Refresh()
end

function PinEdit.CreateWindow(name, width, height)
	local window = CreateFrame("Frame", name, WorldMapFrame, "BasicFrameTemplateWithInset")
	window:SetSize(width, height)
	window:SetClampedToScreen(true)
	window:SetFrameStrata("DIALOG")
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)

	return window
end

function PinEdit.CreateUI()
	if PinEdit.editor ~= nil then return end
	local editor = PinEdit.CreateWindow("MapUtilsDebugPinEditor", 300, 236)
	editor:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 8, -228)
	if editor.CloseButton ~= nil then
		editor.CloseButton:HookScript("OnClick", function()
			PinEdit.selected = nil
			MapUtils:RefreshPins()
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
	editor.destName = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	editor.destName:SetPoint("LEFT", editor.dest, "RIGHT", 8, 0)
	editor.destName:SetWidth(160)
	editor.destName:SetJustifyH("LEFT")
	editor.destName:SetWordWrap(false)
	for index, step in ipairs(PinEdit.steps) do
		local left = 12 + (index - 1) * 94
		local label = editor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", editor, "TOPLEFT", left, -98)
		label:SetText(tostring(step))
		for _, def in ipairs(PinEdit.arrows) do
			local button = PinEdit.CreateButton(editor, def[1], 26, function()
				local entry = PinEdit.selected
				if entry ~= nil then PinEdit.SetPos(entry.x + def[4] * step, entry.y + def[5] * step) end
			end)

			button:SetPoint("TOPLEFT", editor, "TOPLEFT", left + def[2], -114 + def[3])
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
	local output = PinEdit.CreateWindow("MapUtilsDebugPinOutput", 460, 200)
	output:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 0, -8)
	output.scroll = CreateFrame("ScrollFrame", nil, output, "UIPanelScrollFrameTemplate")
	output.scroll:SetPoint("TOPLEFT", output, "TOPLEFT", 12, -30)
	output.scroll:SetPoint("BOTTOMRIGHT", output, "BOTTOMRIGHT", -32, 36)
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
	output.addDown = PinEdit.CreateButton(output, "+ Crossing down", 120, function() PinEdit.Add(false) end)
	output.addDown:SetPoint("LEFT", output.resetAll, "RIGHT", 6, 0)
	output.addUp = PinEdit.CreateButton(output, "+ Crossing up", 110, function() PinEdit.Add(true) end)
	output.addUp:SetPoint("LEFT", output.addDown, "RIGHT", 6, 0)
	output:Hide()
	PinEdit.output = output
end

function PinEdit.Refresh()
	if PinEdit.editor == nil then return end
	if not debugging then
		PinEdit.editor:Hide()
		PinEdit.output:Hide()

		return
	end

	local lines = {}
	for key, edit in pairs(PinEdit.GetTable("PINEDITS")) do
		if type(edit) == "table" then tinsert(lines, PinEdit.FormatEdit(key, edit)) end
	end

	for _, record in ipairs(PinEdit.GetTable("PINADDS")) do
		tinsert(lines, PinEdit.FormatAdd(record))
	end

	table.sort(lines)
	PinEdit.output.TitleText:SetText(format("MapUtils Debug – Pin changes (%d)", #lines))
	PinEdit.output.edit:SetText(table.concat(lines, "\n"))
	PinEdit.output:Show()
	local entry = PinEdit.selected
	if entry == nil then
		PinEdit.editor:Hide()

		return
	end

	local editor = PinEdit.editor
	local isCrossing = entry.kind == "crossing"
	local suffix = entry.added ~= nil and " (added)" or entry.deleted and " (deleted)" or ""
	editor.info:SetText(format("%s [%d] %s%s", PinEdit.GetKind(entry), PinEdit.selectedMapID, PinEdit.Describe(entry), suffix))
	if not editor.x:HasFocus() then editor.x:SetText(format("%.5f", entry.x)) end
	if not editor.y:HasFocus() then editor.y:SetText(format("%.5f", entry.y)) end
	if not editor.dest:HasFocus() then editor.dest:SetText(entry.destMapID ~= nil and tostring(entry.destMapID) or "") end
	editor.dest:SetShown(isCrossing)
	editor.dest.label:SetShown(isCrossing)
	editor.destName:SetShown(isCrossing)
	editor.destName:SetText(entry.name or "")
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
	MapUtils:RefreshPins()
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
		CreateWaypointWindow():Show()
		RefreshWaypointWindow()
		PinEdit.CreateUI()
		PinEdit.Refresh()
		MapUtils:RefreshPins()
		frame.elapsed = 0
		frame:SetScript("OnUpdate", OnUpdate)
		MapUtils:INFO("Debug mode on - the cursor shows uiMapID and coordinates while the world map is open, off again after a /reload")
	else
		frame:SetScript("OnUpdate", nil)
		display:Hide()
		if waypointWindow ~= nil then waypointWindow:Hide() end
		PinEdit.selected = nil
		PinEdit.Refresh()
		MapUtils:RefreshPins()
		MapUtils:INFO("Debug mode off")
	end
end
function MapUtils:PrintDebugHelp()
	self:INFO("MapUtils Debug-Hilfe ([Text] ist optional):")
	self:INFO("/maputils debug help - Diese Hilfe anzeigen")
	self:INFO("/maputils debug - Debug-Anzeige ein/aus: Karten-ID, Mauskoordinaten und Wegpunkt-Z-Fenster")
	self:INFO("Wegpunkt-Z: Auf Forever wird nur der gespeicherte Z-Wert geändert; die Höhe des Weltmarkers steuert der Client.")
	self:INFO("Im Debug-Modus: Linksklick auf ein Weltkarten-Symbol (außer Flugpunkte) öffnet den Pin-Editor; X/Y eingeben + Enter oder mit den Pfeilen um 0.1 / 0.01 / 0.001 verschieben, Reset stellt den Originalwert wieder her")
	self:INFO("Pin-Editor: 'Delete' blendet das Symbol aus (im Debug-Modus halb sichtbar, 'Restore' holt es zurück); bei Zonenübergängen 'To' = Ziel-uiMapID + Enter, 'Up'/'Down' wechselt das Höhlen-Symbol")
	self:INFO("Pin-Änderungen: Fenster darunter, '+ Crossing down'/'+ Crossing up' fügt einen Zonenübergang in der Kartenmitte hinzu, 'Select all' und Strg+C zum Kopieren, 'Reset all' verwirft alle; gespeichert in SavedVariables (MAUTTAB.PINEDITS / PINADDS)")
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
