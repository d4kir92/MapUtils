local addonName, MapUtils = ...
local Profiler = {
	active = false,
	stats = {},
	child = {},
	depth = 0,
	frameTotal = 0,
	frames = 0,
	frameSum = 0,
	framePeak = 0,
	startedAt = nil,
	elapsed = 0,
	originals = {},
	sortKey = "self",
	maxRows = 40,
	rowHeight = 16,
	refreshInterval = 0.5,
	skip = {Profile = true, Profiler = true, ToggleProfiler = true},
}

MapUtils.Profiler = Profiler
function Profiler.Record(label, kind, total, own)
	local stat = Profiler.stats[label]
	if stat == nil then
		stat = {label = label, kind = kind, calls = 0, total = 0, self = 0, peak = 0}
		Profiler.stats[label] = stat
	end

	stat.calls = stat.calls + 1
	stat.total = stat.total + total
	stat.self = stat.self + own
	if total > stat.peak then stat.peak = total end
end

function Profiler.Finish(label, kind, start, ...)
	local elapsed = debugprofilestop() - start
	local depth = Profiler.depth
	if depth > 0 then
		local own = elapsed - (Profiler.child[depth] or 0)
		Profiler.depth = depth - 1
		if depth > 1 then
			Profiler.child[depth - 1] = (Profiler.child[depth - 1] or 0) + elapsed
		else
			Profiler.frameTotal = Profiler.frameTotal + elapsed
		end

		Profiler.Record(label, kind, elapsed, own)
	end

	return ...
end

function Profiler.Wrap(label, kind, fn)
	return function(...)
		if not Profiler.active then return fn(...) end
		local depth = Profiler.depth + 1
		Profiler.depth = depth
		Profiler.child[depth] = 0
		local start = debugprofilestop()

		return Profiler.Finish(label, kind, start, fn(...))
	end
end

function MapUtils.Profile(label, fn)
	if type(fn) ~= "function" then return fn end

	return Profiler.Wrap(label, "entry", fn)
end

function Profiler.IsPlainTable(value)
	if type(value) ~= "table" or value == Profiler or value == MapUtils then return false end
	if getmetatable(value) ~= nil then return false end
	if type(rawget(value, 0)) == "userdata" then return false end

	return true
end

function Profiler.WrapTable(tab, prefix)
	for key, value in pairs(tab) do
		if type(key) == "string" and type(value) == "function" and not Profiler.skip[key] then
			local wrapped = Profiler.Wrap(prefix .. key, "method", value)
			tab[key] = wrapped
			tinsert(Profiler.originals, {tab, key, value, wrapped})
		end
	end
end

function Profiler.WrapMethods()
	if #Profiler.originals > 0 then return end
	local tables = {}
	for key, value in pairs(MapUtils) do
		if type(key) == "string" and not Profiler.skip[key] and Profiler.IsPlainTable(value) then tables[key] = value end
	end

	Profiler.WrapTable(MapUtils, "MapUtils:")
	for key, value in pairs(tables) do
		Profiler.WrapTable(value, key .. ".")
	end
end

function Profiler.UnwrapMethods()
	for i = #Profiler.originals, 1, -1 do
		local entry = Profiler.originals[i]
		if entry[1][entry[2]] == entry[4] then entry[1][entry[2]] = entry[3] end
	end

	wipe(Profiler.originals)
end

function Profiler.OnUpdate()
	if not Profiler.active then return end
	Profiler.depth = 0
	Profiler.frames = Profiler.frames + 1
	Profiler.frameSum = Profiler.frameSum + Profiler.frameTotal
	if Profiler.frameTotal > Profiler.framePeak then Profiler.framePeak = Profiler.frameTotal end
	Profiler.frameTotal = 0
end

function Profiler.Reset()
	wipe(Profiler.stats)
	Profiler.frames = 0
	Profiler.frameSum = 0
	Profiler.framePeak = 0
	Profiler.frameTotal = 0
	Profiler.elapsed = 0
	if Profiler.active then Profiler.startedAt = GetTime() end
	Profiler.Refresh()
end

function Profiler.Start()
	if Profiler.active then return end
	Profiler.WrapMethods()
	Profiler.depth = 0
	Profiler.frameTotal = 0
	Profiler.startedAt = GetTime()
	Profiler.active = true
	if Profiler.ticker == nil then
		Profiler.ticker = CreateFrame("Frame")
		Profiler.ticker:SetScript("OnUpdate", Profiler.OnUpdate)
	end

	Profiler.ticker:Show()
	Profiler.Refresh()
end

function Profiler.Stop()
	if not Profiler.active then return end
	Profiler.active = false
	Profiler.elapsed = Profiler.elapsed + GetTime() - (Profiler.startedAt or GetTime())
	Profiler.startedAt = nil
	Profiler.depth = 0
	if Profiler.ticker ~= nil then Profiler.ticker:Hide() end
	Profiler.UnwrapMethods()
	Profiler.Refresh()
end

function Profiler.GetDuration()
	local duration = Profiler.elapsed
	if Profiler.startedAt ~= nil then duration = duration + GetTime() - Profiler.startedAt end

	return duration
end

function Profiler.GetBlizzardMetric(name)
	if C_AddOnProfiler == nil or C_AddOnProfiler.GetAddOnMetric == nil or Enum == nil or Enum.AddOnProfilerMetric == nil then return nil end
	local metric = Enum.AddOnProfilerMetric[name]
	if metric == nil then return nil end
	local ok, value = pcall(C_AddOnProfiler.GetAddOnMetric, addonName, metric)
	if ok and type(value) == "number" then return value end

	return nil
end

function Profiler.GetSorted()
	local list = {}
	local sum = 0
	for _, stat in pairs(Profiler.stats) do
		tinsert(list, stat)
		sum = sum + stat.self
	end

	local key = Profiler.sortKey
	table.sort(
		list,
		function(a, b)
			local va, vb
			if key == "avg" then
				va, vb = a.total / a.calls, b.total / b.calls
			elseif key == "label" then
				return a.label < b.label
			else
				va, vb = a[key], b[key]
			end

			if va == vb then return a.label < b.label end

			return va > vb
		end
	)

	return list, sum
end

Profiler.columns = {
	{key = "label", title = "Function", width = 214, justify = "LEFT"},
	{key = "calls", title = "Calls", width = 52},
	{key = "total", title = "Total ms", width = 66},
	{key = "self", title = "Self ms", width = 66},
	{key = "avg", title = "Avg ms", width = 58},
	{key = "peak", title = "Peak ms", width = 58},
	{key = "pct", title = "Self %", width = 52},
}

function Profiler.CreateButton(parent, label, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 22)
	button:SetText(label)
	button:SetScript("OnClick", onClick)

	return button
end

function Profiler.CreateRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(Profiler.rowHeight)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -112 - (index - 1) * Profiler.rowHeight)
	row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	if index % 2 == 0 then
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetColorTexture(1, 1, 1, 0.05)
	end

	row.cells = {}
	local x = 0
	for i, column in ipairs(Profiler.columns) do
		local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cell:SetPoint("LEFT", row, "LEFT", x + 2, 0)
		cell:SetWidth(column.width - 4)
		cell:SetJustifyH(column.justify or "RIGHT")
		cell:SetWordWrap(false)
		row.cells[i] = cell
		x = x + column.width
	end

	return row
end

function Profiler.CreateUI()
	if Profiler.window ~= nil then return Profiler.window end
	local window = MapUtils:CreateUIWindow({
		name = "MapUtilsProfiler", width = 650, height = 520,
		title = "MapUtils Profiler", resizable = false,
	})
	window:ClearAllPoints()
	window:SetPoint("CENTER")
	window:SetFrameStrata("DIALOG")
	local content = window.content
	content:SetWidth(math.max(window.contentWidth or 0, 566))
	window.toggle = Profiler.CreateButton(content, "Start", 90, function()
		if Profiler.active then
			Profiler.Stop()
		else
			Profiler.Start()
		end
	end)
	window.toggle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
	window.reset = Profiler.CreateButton(content, "Reset", 90, Profiler.Reset)
	window.reset:SetPoint("LEFT", window.toggle, "RIGHT", 6, 0)
	window.summary = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	window.summary:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -32)
	window.summary:SetPoint("RIGHT", content, "RIGHT", 0, 0)
	window.summary:SetJustifyH("LEFT")
	window.summary:SetSpacing(2)
	window.headers = {}
	local x = 0
	for _, column in ipairs(Profiler.columns) do
		local header = CreateFrame("Button", nil, content)
		header:SetSize(column.width, 18)
		header:SetPoint("TOPLEFT", content, "TOPLEFT", x, -92)
		header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		header.text:SetPoint("LEFT", 2, 0)
		header.text:SetPoint("RIGHT", -2, 0)
		header.text:SetJustifyH(column.justify or "RIGHT")
		header.column = column
		header:SetScript("OnClick", function()
			Profiler.sortKey = column.key == "pct" and "self" or column.key
			Profiler.Refresh()
		end)
		tinsert(window.headers, header)
		x = x + column.width
	end

	window.rows = {}
	for i = 1, Profiler.maxRows do
		window.rows[i] = Profiler.CreateRow(content, i)
	end

	content:SetHeight(112 + Profiler.maxRows * Profiler.rowHeight + 8)
	local elapsed = 0
	window:HookScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		if elapsed < Profiler.refreshInterval then return end
		elapsed = 0
		Profiler.Refresh()
	end)
	window:HookScript("OnShow", Profiler.Refresh)
	Profiler.window = window

	return window
end

function Profiler.FormatMs(value)
	if value >= 100 then return format("%.0f", value) end
	if value >= 10 then return format("%.1f", value) end

	return format("%.3f", value)
end

function Profiler.Refresh()
	local window = Profiler.window
	if window == nil or not window:IsShown() then return end
	window.toggle:SetText(Profiler.active and "Stop" or "Start")
	local duration = Profiler.GetDuration()
	local list, sum = Profiler.GetSorted()
	local frames = Profiler.frames
	local lines = {}
	tinsert(lines, format("%s  |  %.1f s  |  %d frames  |  measured %s ms (%s ms/s)", Profiler.active and "|cff40ff40Running|r" or "|cffff6060Stopped|r", duration, frames, Profiler.FormatMs(sum), Profiler.FormatMs(duration > 0 and sum / duration or 0)))
	tinsert(lines, format("Per frame: avg %s ms, peak %s ms  |  |cffffd100yellow|r = entry point (OnUpdate/event/hook), white = method", Profiler.FormatMs(frames > 0 and Profiler.frameSum / frames or 0), Profiler.FormatMs(Profiler.framePeak)))
	local recent = Profiler.GetBlizzardMetric("RecentAverageTime")
	local peak = Profiler.GetBlizzardMetric("PeakTime")
	if recent ~= nil then
		tinsert(lines, format("Blizzard addon profiler: recent avg %s ms/frame, peak %s ms (includes libs and unwrapped code)", Profiler.FormatMs(recent), Profiler.FormatMs(peak or 0)))
	else
		tinsert(lines, "Total ms includes nested calls, Self ms excludes them. Click a column to sort.")
	end

	window.summary:SetText(table.concat(lines, "\n"))
	for _, header in ipairs(window.headers) do
		local key = header.column.key
		local active = Profiler.sortKey == key or (key == "pct" and Profiler.sortKey == "self")
		header.text:SetText(active and ("|cffffffff" .. header.column.title .. "|r") or header.column.title)
	end

	for i, row in ipairs(window.rows) do
		local stat = list[i]
		if stat == nil then
			row:Hide()
		else
			row:Show()
			local cells = row.cells
			cells[1]:SetText(stat.label)
			if stat.kind == "entry" then
				cells[1]:SetTextColor(1, 0.82, 0)
			else
				cells[1]:SetTextColor(1, 1, 1)
			end

			cells[2]:SetText(stat.calls)
			cells[3]:SetText(Profiler.FormatMs(stat.total))
			cells[4]:SetText(Profiler.FormatMs(stat.self))
			cells[5]:SetText(Profiler.FormatMs(stat.total / stat.calls))
			cells[6]:SetText(Profiler.FormatMs(stat.peak))
			cells[7]:SetText(format("%.1f", sum > 0 and stat.self / sum * 100 or 0))
		end
	end
end

function MapUtils:ToggleProfiler()
	local window = Profiler.CreateUI()
	if window:IsShown() then
		window:Hide()
	else
		window:Show()
	end
end
