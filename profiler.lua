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
	skip = {Profile = true, ProfileTable = true, Profiler = true, ToggleProfiler = true},
	skipLabels = {["SmoothZoom.CanPan"] = true},
	tables = {},
	frameSelf = {},
	history = {},
	historyIndex = 0,
	historyCount = 0,
	historySize = 141,
	historyTop = 3,
	barWidth = 4,
	graphHeight = 80,
	graphTop = 90,
	headerTop = 178,
	rowsTop = 198,
	graphInterval = 0.1,
	graphScales = {1, 2, 5, 10, 20, 50, 100, 200, 500},
	budget = 1000 / 60,
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
		Profiler.frameSelf[label] = (Profiler.frameSelf[label] or 0) + own
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
		if type(key) == "string" and type(value) == "function" and not Profiler.skip[key] and not Profiler.skipLabels[prefix .. key] then
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

	local seen = {}
	for _, value in pairs(tables) do
		seen[value] = true
	end

	for key, value in pairs(Profiler.tables) do
		if not seen[value] then
			seen[value] = true
			tables[key] = value
		end
	end

	Profiler.WrapTable(MapUtils, "MapUtils:")
	for key, value in pairs(tables) do
		Profiler.WrapTable(value, key .. ".")
	end
end

function MapUtils.ProfileTable(name, tab)
	if type(name) ~= "string" or type(tab) ~= "table" then return end
	Profiler.tables[name] = tab
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
	Profiler.PushHistory(Profiler.frameTotal)
	Profiler.frameTotal = 0
end

function Profiler.SortTop(a, b)
	return a[2] > b[2]
end

function Profiler.PushHistory(total)
	local top = {}
	local limit = Profiler.historyTop
	for label, value in pairs(Profiler.frameSelf) do
		if #top < limit or value > top[#top][2] then
			tinsert(top, {label, value})
			table.sort(top, Profiler.SortTop)
			if #top > limit then top[#top] = nil end
		end
	end

	wipe(Profiler.frameSelf)
	Profiler.historyIndex = Profiler.historyIndex % Profiler.historySize + 1
	Profiler.history[Profiler.historyIndex] = {total = total, top = top}
	Profiler.historyCount = math.min(Profiler.historyCount + 1, Profiler.historySize)
end

function Profiler.GetHistory(age)
	if age < 0 or age >= Profiler.historyCount then return nil end
	local index = (Profiler.historyIndex - 1 - age) % Profiler.historySize + 1

	return Profiler.history[index]
end

function Profiler.Reset()
	wipe(Profiler.stats)
	wipe(Profiler.frameSelf)
	wipe(Profiler.history)
	Profiler.historyIndex = 0
	Profiler.historyCount = 0
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
	wipe(Profiler.frameSelf)
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
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -Profiler.rowsTop - (index - 1) * Profiler.rowHeight)
	row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	if index % 2 == 0 then
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetColorTexture(1, 1, 1, 0.05)
	end

	row.bar = row:CreateTexture(nil, "BORDER")
	row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
	row.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1)
	row.bar:SetWidth(1)

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

function Profiler.GetFrameColor(total)
	if total < 1 then return 0.25, 0.8, 0.25 end
	if total < 5 then return 1, 0.82, 0 end
	if total < Profiler.budget then return 1, 0.5, 0 end

	return 1, 0.15, 0.15
end

function Profiler.GetGraphScale()
	local highest = 0
	for age = 0, Profiler.historyCount - 1 do
		local entry = Profiler.GetHistory(age)
		if entry ~= nil and entry.total > highest then highest = entry.total end
	end

	for _, scale in ipairs(Profiler.graphScales) do
		if highest <= scale then return scale end
	end

	return Profiler.graphScales[#Profiler.graphScales]
end

function Profiler.CreateGraph(parent)
	local graph = CreateFrame("Frame", nil, parent)
	graph:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -Profiler.graphTop)
	graph:SetSize(Profiler.historySize * Profiler.barWidth, Profiler.graphHeight)
	graph.bg = graph:CreateTexture(nil, "BACKGROUND")
	graph.bg:SetAllPoints()
	graph.bg:SetColorTexture(0, 0, 0, 0.45)
	graph.bars = {}
	for i = 1, Profiler.historySize do
		local bar = graph:CreateTexture(nil, "ARTWORK")
		bar:SetWidth(Profiler.barWidth - 1)
		bar:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", (i - 1) * Profiler.barWidth, 0)
		bar:Hide()
		graph.bars[i] = bar
	end

	graph.budget = graph:CreateTexture(nil, "OVERLAY")
	graph.budget:SetHeight(1)
	graph.budget:SetColorTexture(1, 0.15, 0.15, 0.7)
	graph.budget:SetPoint("LEFT", graph, "LEFT", 0, 0)
	graph.budget:SetPoint("RIGHT", graph, "RIGHT", 0, 0)
	graph.budgetText = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	graph.budgetText:SetPoint("BOTTOMLEFT", graph.budget, "TOPLEFT", 2, 1)
	graph.budgetText:SetText("60 FPS budget")
	graph.scaleText = graph:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	graph.scaleText:SetPoint("TOPRIGHT", graph, "TOPRIGHT", -3, -3)
	graph.hint = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	graph.hint:SetPoint("TOPLEFT", graph, "TOPLEFT", 3, -3)
	graph.hint:SetText("ms per frame (newest right), hover a bar for details")
	graph.highlight = graph:CreateTexture(nil, "OVERLAY")
	graph.highlight:SetWidth(Profiler.barWidth)
	graph.highlight:SetPoint("TOP", graph, "TOP", 0, 0)
	graph.highlight:SetPoint("BOTTOM", graph, "BOTTOM", 0, 0)
	graph.highlight:SetColorTexture(1, 1, 1, 0.25)
	graph.highlight:Hide()
	graph:EnableMouse(true)
	graph:SetScript("OnEnter", function(self) self.hovering = true end)
	graph:SetScript("OnUpdate", Profiler.OnGraphUpdate)
	graph:SetScript("OnLeave", function(self)
		self.hovering = false
		self.hoverIndex = nil
		self.highlight:Hide()
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)

	return graph
end

function Profiler.RefreshGraph()
	local window = Profiler.window
	if window == nil or not window:IsShown() then return end
	local graph = window.graph
	local scale = Profiler.GetGraphScale()
	graph.scaleText:SetText(format("scale %s ms", scale))
	local size = Profiler.historySize
	for i, bar in ipairs(graph.bars) do
		local entry = Profiler.GetHistory(size - i)
		if entry == nil then
			bar:Hide()
		else
			bar:SetHeight(math.max(1, math.min(entry.total / scale, 1) * Profiler.graphHeight))
			bar:SetColorTexture(Profiler.GetFrameColor(entry.total))
			bar:Show()
		end
	end

	if Profiler.budget <= scale then
		graph.budget:SetPoint("LEFT", graph, "BOTTOMLEFT", 0, Profiler.budget / scale * Profiler.graphHeight)
		graph.budget:SetPoint("RIGHT", graph, "BOTTOMRIGHT", 0, Profiler.budget / scale * Profiler.graphHeight)
		graph.budget:Show()
		graph.budgetText:Show()
	else
		graph.budget:Hide()
		graph.budgetText:Hide()
	end

	Profiler.UpdateGraphHover(graph)
end

function Profiler.GetHoverIndex(graph)
	local left = graph:GetLeft()
	if left == nil then return nil end
	local x = GetCursorPosition() / graph:GetEffectiveScale() - left
	local index = math.floor(x / Profiler.barWidth) + 1
	if index < 1 or index > Profiler.historySize then return nil end

	return index
end

function Profiler.OnGraphUpdate(graph)
	if graph.hovering and Profiler.GetHoverIndex(graph) ~= graph.hoverIndex then Profiler.UpdateGraphHover(graph) end
end

function Profiler.UpdateGraphHover(graph)
	if not graph.hovering then return end
	local index = Profiler.GetHoverIndex(graph)
	graph.hoverIndex = index
	if index == nil then return end
	local age = Profiler.historySize - index
	local entry = Profiler.GetHistory(age)
	graph.highlight:ClearAllPoints()
	graph.highlight:SetPoint("TOPLEFT", graph, "TOPLEFT", (index - 1) * Profiler.barWidth, 0)
	graph.highlight:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", (index - 1) * Profiler.barWidth, 0)
	graph.highlight:Show()
	GameTooltip:SetOwner(graph, "ANCHOR_CURSOR")
	GameTooltip:ClearLines()
	if entry == nil then
		GameTooltip:AddLine("No data")
	else
		local r, g, b = Profiler.GetFrameColor(entry.total)
		GameTooltip:AddLine(format("%s ms in this frame", Profiler.FormatMs(entry.total)), r, g, b)
		GameTooltip:AddLine(age == 0 and "newest frame" or format("%d frames ago", age), 0.6, 0.6, 0.6)
		for _, item in ipairs(entry.top) do
			GameTooltip:AddDoubleLine(item[1], Profiler.FormatMs(item[2]) .. " ms self", 1, 1, 1, 1, 0.82, 0)
		end
	end

	GameTooltip:Show()
end

function Profiler.CreateUI()
	if Profiler.window ~= nil then return Profiler.window end
	local window = MapUtils:CreateUIWindow({
		name = "MapUtilsProfiler", width = 650, height = 600,
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
	window.graph = Profiler.CreateGraph(content)
	window.headers = {}
	local x = 0
	for _, column in ipairs(Profiler.columns) do
		local header = CreateFrame("Button", nil, content)
		header:SetSize(column.width, 18)
		header:SetPoint("TOPLEFT", content, "TOPLEFT", x, -Profiler.headerTop)
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

	content:SetHeight(Profiler.rowsTop + Profiler.maxRows * Profiler.rowHeight + 8)
	local elapsed = 0
	local graphElapsed = 0
	window:HookScript("OnUpdate", function(_, delta)
		graphElapsed = graphElapsed + delta
		if graphElapsed >= Profiler.graphInterval then
			graphElapsed = 0
			if Profiler.active then Profiler.RefreshGraph() end
		end

		elapsed = elapsed + delta
		if elapsed < Profiler.refreshInterval then return end
		elapsed = 0
		Profiler.Refresh()
	end)
	window:HookScript("OnShow", function()
		Profiler.UpdateScroll()
		Profiler.Refresh()
	end)
	Profiler.window = window

	return window
end

function Profiler.UpdateScroll()
	local window = Profiler.window
	if window == nil then return end
	if window.UpdateScroll ~= nil then window:UpdateScroll() end
	if window.scroll ~= nil and window.scroll.UpdateScrollChildRect ~= nil then window.scroll:UpdateScrollChildRect() end
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

	local maxSelf = 0
	for _, stat in ipairs(list) do
		if stat.self > maxSelf then maxSelf = stat.self end
	end

	local rowWidth = window.rows[1]:GetWidth()
	if rowWidth == nil or rowWidth <= 0 then rowWidth = 566 end
	for i, row in ipairs(window.rows) do
		local stat = list[i]
		if stat == nil then
			row:Hide()
		else
			row:Show()
			local cells = row.cells
			cells[1]:SetText(stat.label)
			local share = maxSelf > 0 and stat.self / maxSelf or 0
			row.bar:SetWidth(math.max(1, rowWidth * share))
			if stat.kind == "entry" then
				cells[1]:SetTextColor(1, 0.82, 0)
				row.bar:SetColorTexture(1, 0.82, 0, 0.22)
			else
				cells[1]:SetTextColor(1, 1, 1)
				row.bar:SetColorTexture(0.4, 0.7, 1, 0.22)
			end

			cells[2]:SetText(stat.calls)
			cells[3]:SetText(Profiler.FormatMs(stat.total))
			cells[4]:SetText(Profiler.FormatMs(stat.self))
			cells[5]:SetText(Profiler.FormatMs(stat.total / stat.calls))
			cells[6]:SetText(Profiler.FormatMs(stat.peak))
			cells[7]:SetText(format("%.1f", sum > 0 and stat.self / sum * 100 or 0))
		end
	end

	Profiler.RefreshGraph()
end

function MapUtils:ToggleProfiler()
	local window = Profiler.CreateUI()
	if window:IsShown() then
		window:Hide()
	else
		window:Show()
	end
end
