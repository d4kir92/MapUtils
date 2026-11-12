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

function Profiler.OnUpdate(_, delta)
	if not Profiler.active then return end
	Profiler.depth = 0
	Profiler.frames = Profiler.frames + 1
	Profiler.frameSum = Profiler.frameSum + Profiler.frameTotal
	if Profiler.frameTotal > Profiler.framePeak then Profiler.framePeak = Profiler.frameTotal end
	Profiler.TrackState(delta or 0, Profiler.frameTotal)
	Profiler.PushHistory(Profiler.frameTotal)
	Profiler.frameTotal = 0
end

Profiler.states = {}
Profiler.hitches = {}
Profiler.hitchThreshold = 0.025
Profiler.hitchMax = 20
Profiler.stateSampleInterval = 1
Profiler.countTextures = true

function MapUtils:ToggleProfilerTextureCount()
	Profiler.countTextures = not Profiler.countTextures
	MapUtils:INFO("Profiler texture counting " .. (Profiler.countTextures and "on" or "off"))
end
Profiler.mapTypeNames = {[0] = "cosmic", [1] = "world", [2] = "continent", [3] = "zone", [4] = "dungeon", [5] = "micro", [6] = "orphan"}

function Profiler.GetStateKey()
	if WorldMapFrame == nil or not WorldMapFrame:IsShown() then return "map closed", false end
	local scroll = WorldMapFrame.ScrollContainer
	local scale = scroll:GetCanvasScale() or 0
	local x, y = scroll:GetCurrentScrollX() or 0, scroll:GetCurrentScrollY() or 0
	local mapID = WorldMapFrame:GetMapID()
	local last = Profiler.lastView
	local action = "still"
	if last and last.mapID ~= mapID then
		action = "map switch"
	elseif last and math.abs(scale - last.scale) > last.scale * 0.0005 then
		action = scale > last.scale and "zoom in" or "zoom out"
	elseif last and (math.abs(x - last.x) > 0.0001 or math.abs(y - last.y) > 0.0001) then
		action = "pan"
	end

	Profiler.lastView = {mapID = mapID, scale = scale, x = x, y = y}
	local info = mapID and C_Map.GetMapInfo(mapID)
	local mapType = info and Profiler.mapTypeNames[info.mapType] or "?"
	local minScale = scroll.GetScaleForMinZoom and scroll:GetScaleForMinZoom() or 0
	local zoom = minScale > 0 and scale / minScale or 1
	local level = zoom < 1.5 and "out" or zoom < 4 and "mid" or zoom < 12 and "in" or "max"

	return format("%-10s %-9s zoom %-3s", action, mapType, level), true
end

function Profiler.TrackState(delta, lua)
	local key, open = Profiler.GetStateKey()
	local state = Profiler.states[key]
	if state == nil then
		state = {key = key, frames = 0, time = 0, lua = 0, worst = 0, slow = 0, textures = 0, masks = 0, samples = 0}
		Profiler.states[key] = state
	end

	local afterCount = Profiler.countedLastFrame
	Profiler.countedLastFrame = false
	local memory = collectgarbage("count")
	local grown = Profiler.lastMemory and memory - Profiler.lastMemory or 0
	local collected = grown < 0
	Profiler.lastMemory = memory
	if grown > 0 then state.alloc = (state.alloc or 0) + grown end
	if collected then state.gc = (state.gc or 0) + 1 end
	state.frames = state.frames + 1
	state.time = state.time + delta
	state.lua = state.lua + lua
	if delta > state.worst then state.worst = delta end
	if delta > 1 / 60 then state.slow = state.slow + 1 end
	local now = GetTime()
	if delta >= Profiler.hitchThreshold then
		local top = {}
		for label, value in pairs(Profiler.frameSelf) do
			tinsert(top, {label, value})
		end

		table.sort(top, Profiler.SortTop)
		local parts = {}
		for i = 1, math.min(4, #top) do
			tinsert(parts, format("%s %.1f", top[i][1], top[i][2]))
		end

		tinsert(Profiler.hitches, {at = now - (Profiler.startedAt or now) + Profiler.elapsed, key = key, ms = delta * 1000, lua = lua, gc = (collected and format("gc %.0f KB", -grown) or format("+%.0f KB", grown)) .. (afterCount and " count" or ""), top = table.concat(parts, ", ")})
		if #Profiler.hitches > Profiler.hitchMax then tremove(Profiler.hitches, 1) end
	end

	if open and Profiler.countTextures and (Profiler.lastStateSample == nil or now - Profiler.lastStateSample >= Profiler.stateSampleInterval) then
		Profiler.lastStateSample = now
		Profiler.countedLastFrame = true
		local results = Profiler.MeasureLayers()
		local textures, masks = 0, 0
		for _, stats in pairs(results) do
			textures, masks = textures + stats.textures, masks + stats.masks
		end

		state.textures = state.textures + textures
		state.masks = state.masks + masks
		state.samples = state.samples + 1
	end
end

function Profiler.BuildReport()
	local lines = {"MapUtils profiler report " .. date("%Y-%m-%d %H:%M:%S"), Profiler.BenchContext()}
	local duration = Profiler.GetDuration()
	tinsert(lines, format("%.1f s, %d frames, MapUtils Lua avg %.3f ms/frame, peak %.1f ms", duration, Profiler.frames, Profiler.frames > 0 and Profiler.frameSum / Profiler.frames or 0, Profiler.framePeak))
	tinsert(lines, "")
	tinsert(lines, "state      map       zoom    frames   fps   avg ms  worst ms  <60fps  lua ms  tex  masks  KB/frame  gc")
	local list = {}
	for _, state in pairs(Profiler.states) do
		tinsert(list, state)
	end

	table.sort(list, function(a, b) return a.time > b.time end)
	for _, state in ipairs(list) do
		local avg = state.frames > 0 and state.time / state.frames * 1000 or 0
		tinsert(lines, format("%s %7d %6.0f %8.2f %9.1f %6.0f%% %7.3f %5s %6s %9.1f %4d", state.key, state.frames, avg > 0 and 1000 / avg or 0, avg, state.worst * 1000, state.frames > 0 and state.slow / state.frames * 100 or 0, state.frames > 0 and state.lua / state.frames or 0, state.samples > 0 and format("%d", state.textures / state.samples) or "-", state.samples > 0 and format("%d", state.masks / state.samples) or "-", state.frames > 0 and (state.alloc or 0) / state.frames or 0, state.gc or 0))
	end

	tinsert(lines, "")
	tinsert(lines, format("Hitches >= %d ms (last %d): time, state, frame ms, MapUtils lua ms, memory change (gc = Lua garbage collection ran), top self ms", Profiler.hitchThreshold * 1000, Profiler.hitchMax))
	for _, hitch in ipairs(Profiler.hitches) do
		tinsert(lines, format("  %6.1fs %s %6.1f %6.1f %-11s %s", hitch.at, hitch.key, hitch.ms, hitch.lua, hitch.gc or "", hitch.top ~= "" and hitch.top or "-"))
	end

	tinsert(lines, "")
	tinsert(lines, "Top functions by self ms (calls / total / self / avg / peak):")
	local sorted = Profiler.GetSorted()
	for i = 1, math.min(15, #sorted) do
		local stat = sorted[i]
		tinsert(lines, format("  %-34s %7d %9.1f %9.1f %7.3f %7.2f", stat.label, stat.calls, stat.total, stat.self, stat.total / stat.calls, stat.peak))
	end

	return table.concat(lines, "\n"), lines
end

function MapUtils:ShowProfilerReport()
	local text, lines = Profiler.BuildReport()
	if type(MAUTTAB) == "table" then MAUTTAB["PROFILEREPORT"] = lines end
	Profiler.ShowBenchText(text)
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
	wipe(Profiler.states)
	wipe(Profiler.hitches)
	Profiler.lastView = nil
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
	window.layers = Profiler.CreateButton(content, "Layers", 90, function() MapUtils:ToggleRenderProfiler() end)
	window.layers:SetPoint("LEFT", window.reset, "RIGHT", 6, 0)
	window.bench = Profiler.CreateButton(content, "Benchmark", 100, function() MapUtils:RunRenderBenchmark() end)
	window.bench:SetPoint("LEFT", window.layers, "RIGHT", 6, 0)
	window.report = Profiler.CreateButton(content, "Report", 90, function() MapUtils:ShowProfilerReport() end)
	window.report:SetPoint("LEFT", window.bench, "RIGHT", 6, 0)
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
		Profiler.SavePosition(window)
		Profiler.Refresh()
	end)
	window:HookScript("OnShow", function()
		Profiler.UpdateScroll()
		Profiler.Refresh()
	end)
	window:HookScript("OnHide", Profiler.SavePosition)
	Profiler.RestorePosition(window, "main")
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

Profiler.render = {
	layers = {},
	rowHeight = 18,
	faintAlpha = 0.05,
	fpsSamples = {},
	columns = {
		{title = "Layer", width = 190, justify = "LEFT"},
		{title = "Frames", width = 56},
		{title = "Textures", width = 64},
		{title = "Masks", width = 56},
		{title = "Faint", width = 50},
		{title = "Text", width = 44},
		{title = "", width = 70},
	},
}

function MapUtils:RegisterRenderLayer(name, getter)
	local render = Profiler.render
	for _, layer in ipairs(render.layers) do
		if layer.name == name then
			layer.getter = getter

			return
		end
	end

	tinsert(render.layers, {name = name, getter = getter, enabled = true})
end

function Profiler.GetLayerFrames(layer)
	local ok, result = pcall(layer.getter)
	if not ok or result == nil then return {} end
	if type(result) ~= "table" or result.GetObjectType ~= nil then return {result} end
	local frames = {}
	for _, frame in pairs(result) do
		if type(frame) == "table" and frame.GetObjectType ~= nil then tinsert(frames, frame) end
	end

	return frames
end

function Profiler.GetAlpha(region)
	if region.GetEffectiveAlpha ~= nil then return region:GetEffectiveAlpha() end

	return region:GetAlpha()
end

function Profiler.CountRegion(region, stats)
	if not region:IsVisible() then return end
	local kind = region:GetObjectType()
	if kind == "MaskTexture" then
		stats.masks = stats.masks + 1
	elseif kind == "Texture" or kind == "Line" then
		stats.textures = stats.textures + 1
		if Profiler.GetAlpha(region) < Profiler.render.faintAlpha then stats.faint = stats.faint + 1 end
	elseif kind == "FontString" then
		stats.text = stats.text + 1
	end
end

function Profiler.CountFrame(frame, stats, skip)
	if not frame:IsVisible() then return end
	stats.frames = stats.frames + 1
	for i = 1, select("#", frame:GetRegions()) do
		Profiler.CountRegion(select(i, frame:GetRegions()), stats)
	end

	for i = 1, select("#", frame:GetChildren()) do
		local child = select(i, frame:GetChildren())
		if not skip[child] then Profiler.CountFrame(child, stats, skip) end
	end
end

function Profiler.NewStats()
	return {frames = 0, textures = 0, masks = 0, faint = 0, text = 0}
end

function Profiler.MeasureLayers()
	local render = Profiler.render
	local owner = {}
	local framesOf = {}
	for _, layer in ipairs(render.layers) do
		framesOf[layer] = Profiler.GetLayerFrames(layer)
		for _, frame in ipairs(framesOf[layer]) do
			owner[frame] = layer
		end
	end

	local results = {}
	for _, layer in ipairs(render.layers) do
		local stats = Profiler.NewStats()
		for _, frame in ipairs(framesOf[layer]) do
			local skip = {}
			for other, otherLayer in pairs(owner) do
				if other ~= frame and otherLayer ~= nil then skip[other] = true end
			end

			Profiler.CountFrame(frame, stats, skip)
		end

		results[layer] = stats
	end

	local canvas = Profiler.NewStats()
	local child = WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
	if child then Profiler.CountFrame(child, canvas, {}) end

	return results, canvas, owner
end

function Profiler.SetFrameHidden(frame, hidden)
	if not frame.mapUtilsRenderHooked then
		frame.mapUtilsRenderHooked = true
		frame.mapUtilsWanted = frame:IsShown()
		hooksecurefunc(frame, "Show", function(self)
			if self.mapUtilsRenderGuard then return end
			self.mapUtilsWanted = true
			if self.mapUtilsRenderOff then
				self.mapUtilsRenderGuard = true
				self:Hide()
				self.mapUtilsRenderGuard = false
			end
		end)
		hooksecurefunc(frame, "Hide", function(self)
			if self.mapUtilsRenderGuard then return end
			self.mapUtilsWanted = false
		end)
		hooksecurefunc(frame, "SetShown", function(self, shown)
			if self.mapUtilsRenderGuard then return end
			self.mapUtilsWanted = shown and true or false
			if shown and self.mapUtilsRenderOff then
				self.mapUtilsRenderGuard = true
				self:Hide()
				self.mapUtilsRenderGuard = false
			end
		end)
	end

	if frame.mapUtilsRenderOff == hidden then return end
	frame.mapUtilsRenderOff = hidden
	frame.mapUtilsRenderGuard = true
	if hidden then
		frame.mapUtilsWanted = frame:IsShown()
		frame:Hide()
	elseif frame.mapUtilsWanted then
		frame:Show()
	end

	frame.mapUtilsRenderGuard = false
end

function Profiler.ApplyLayers()
	for _, layer in ipairs(Profiler.render.layers) do
		if not layer.enabled or layer.touched then
			for _, frame in ipairs(Profiler.GetLayerFrames(layer)) do
				Profiler.SetFrameHidden(frame, not layer.enabled)
			end

			layer.touched = not layer.enabled
		end
	end
end

function Profiler.ToggleLayer(layer)
	layer.enabled = not layer.enabled
	layer.touched = true
	Profiler.ApplyLayers()
	wipe(Profiler.render.fpsSamples)
	Profiler.RefreshRender()
end

function Profiler.CreateRenderRow(parent, index)
	local render = Profiler.render
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(render.rowHeight)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(64 + index * render.rowHeight))
	row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	row.cells = {}
	local x = 0
	for i, column in ipairs(render.columns) do
		if i < #render.columns then
			local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			cell:SetPoint("LEFT", row, "LEFT", x + 2, 0)
			cell:SetWidth(column.width - 4)
			cell:SetJustifyH(column.justify or "RIGHT")
			cell:SetWordWrap(false)
			row.cells[i] = cell
		else
			row.button = Profiler.CreateButton(row, "On", column.width - 6, function()
				if row.layer then Profiler.ToggleLayer(row.layer) end
			end)
			row.button:SetHeight(render.rowHeight)
			row.button:SetPoint("LEFT", row, "LEFT", x + 4, 0)
		end

		x = x + column.width
	end

	return row
end

function Profiler.CreateRenderUI()
	local render = Profiler.render
	if render.window ~= nil then return render.window end
	local window = MapUtils:CreateUIWindow({
		name = "MapUtilsRenderProfiler", width = 600, height = 420,
		title = "MapUtils Render Layers", resizable = false,
	})
	window:ClearAllPoints()
	window:SetPoint("CENTER", 0, 0)
	window:SetFrameStrata("DIALOG")
	local content = window.content
	content:SetWidth(math.max(window.contentWidth or 0, 530))
	window.summary = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	window.summary:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
	window.summary:SetPoint("RIGHT", content, "RIGHT", 0, 0)
	window.summary:SetJustifyH("LEFT")
	window.summary:SetSpacing(2)
	local x = 0
	for _, column in ipairs(render.columns) do
		local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		header:SetPoint("TOPLEFT", content, "TOPLEFT", x + 2, -64)
		header:SetWidth(column.width - 4)
		header:SetJustifyH(column.justify or "RIGHT")
		header:SetText(column.title)
		x = x + column.width
	end

	window.rows = {}
	local elapsed = 0
	window:HookScript("OnUpdate", function(_, delta)
		local samples = render.fpsSamples
		tinsert(samples, GetFramerate())
		if #samples > 120 then tremove(samples, 1) end
		elapsed = elapsed + delta
		if elapsed < 0.5 then return end
		elapsed = 0
		Profiler.SavePosition(window)
		Profiler.ApplyLayers()
		Profiler.RefreshRender()
	end)
	window:HookScript("OnShow", function()
		wipe(render.fpsSamples)
		Profiler.RefreshRender()
	end)
	window:HookScript("OnHide", Profiler.SavePosition)
	Profiler.RestorePosition(window, "layers")
	render.window = window

	return window
end

function Profiler.RefreshRender()
	local render = Profiler.render
	local window = render.window
	if window == nil or not window:IsShown() then return end
	local results, canvas = Profiler.MeasureLayers()
	local fps = 0
	for _, value in ipairs(render.fpsSamples) do
		fps = fps + value
	end

	fps = #render.fpsSamples > 0 and fps / #render.fpsSamples or GetFramerate()
	local own = Profiler.NewStats()
	for _, stats in pairs(results) do
		for key, value in pairs(stats) do
			own[key] = own[key] + value
		end
	end

	local mapShown = WorldMapFrame and WorldMapFrame:IsShown()
	window.summary:SetText(format("FPS %.0f (%.1f ms)  |  map %s\nVisible on map canvas: %d frames, %d textures, %d masks (Blizzard + addons)\nMapUtils layers below: %d frames, %d textures, %d masks, %d faint (alpha < %d%%). Off hides the layer for testing.", fps, fps > 0 and 1000 / fps or 0, mapShown and "|cff40ff40open|r" or "|cffff6060closed|r", canvas.frames, canvas.textures, canvas.masks, own.frames, own.textures, own.masks, own.faint, render.faintAlpha * 100))
	for i, layer in ipairs(render.layers) do
		local row = window.rows[i]
		if row == nil then
			row = Profiler.CreateRenderRow(window.content, i)
			window.rows[i] = row
		end

		local stats = results[layer] or Profiler.NewStats()
		row.layer = layer
		row.cells[1]:SetText(layer.name)
		row.cells[1]:SetTextColor(layer.enabled and 1 or 0.5, layer.enabled and 1 or 0.5, layer.enabled and 1 or 0.5)
		row.cells[2]:SetText(stats.frames)
		row.cells[3]:SetText(stats.textures)
		row.cells[4]:SetText(stats.masks)
		row.cells[5]:SetText(stats.faint)
		row.cells[6]:SetText(stats.text)
		row.button:SetText(layer.enabled and "On" or "|cffff6060Off|r")
		row:Show()
	end

	window.content:SetHeight(64 + (#render.layers + 2) * render.rowHeight)
	if window.UpdateScroll ~= nil then window:UpdateScroll() end
end

function Profiler.RestorePosition(window, key)
	window.positionKey = key
	local saved = type(MAUTTAB) == "table" and type(MAUTTAB["PROFILERPOS"]) == "table" and MAUTTAB["PROFILERPOS"][key]
	if type(saved) ~= "table" or saved[1] == nil then return end
	window:ClearAllPoints()
	window:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
end

function Profiler.SavePosition(window)
	if type(MAUTTAB) ~= "table" or window.positionKey == nil then return end
	local point, _, relativePoint, x, y = window:GetPoint(1)
	if point == nil then return end
	MAUTTAB["PROFILERPOS"] = type(MAUTTAB["PROFILERPOS"]) == "table" and MAUTTAB["PROFILERPOS"] or {}
	local saved = MAUTTAB["PROFILERPOS"][window.positionKey]
	if saved and saved[1] == point and saved[2] == relativePoint and saved[3] == x and saved[4] == y then return end
	MAUTTAB["PROFILERPOS"][window.positionKey] = {point, relativePoint, x, y}
end

Profiler.bench = {
	settle = 0.75,
	measure = 2.5,
}

function Profiler.BenchSetLayers(states)
	for _, layer in ipairs(Profiler.render.layers) do
		local enabled = states[layer]
		if enabled == nil then enabled = true end
		if layer.enabled ~= enabled then
			layer.enabled = enabled
			layer.touched = true
		end
	end

	Profiler.ApplyLayers()
end

function Profiler.BenchContext()
	local scroll = WorldMapFrame.ScrollContainer
	local mapID = WorldMapFrame:GetMapID()
	local info = mapID and C_Map.GetMapInfo(mapID)
	local width, height = scroll:GetSize()

	return format("map %s (%s), canvas scale %.3f, view %.0fx%.0f, one map %s, flavor %s, build %s", tostring(mapID), info and info.name or "?", scroll:GetCanvasScale() or 0, width or 0, height or 0, tostring(MapUtils.IsOneMap ~= nil and MapUtils:IsOneMap()), tostring(MapUtils.GetFlavor and MapUtils:GetFlavor()), tostring(GetBuildInfo()))
end

function Profiler.BenchFinish(bench, aborted)
	bench.frame:SetScript("OnUpdate", nil)
	Profiler.BenchSetLayers(bench.original)
	Profiler.bench.running = nil
	local lines = {"MapUtils benchmark " .. date("%Y-%m-%d %H:%M:%S"), bench.context}
	if aborted then tinsert(lines, "ABORTED: " .. aborted) end
	local base = bench.results[1]
	for _, result in ipairs(bench.results) do
		local delta = base and result ~= base and format("  (%+.2f ms vs all on)", result.ms - base.ms) or ""
		tinsert(lines, format("%-22s %6.1f fps  %6.2f ms avg  %6.2f ms worst%s", result.name, result.ms > 0 and 1000 / result.ms or 0, result.ms, result.worst, delta))
	end

	tinsert(lines, "Layer counts with all on (frames / textures / masks / faint):")
	for _, layer in ipairs(Profiler.render.layers) do
		local stats = bench.counts[layer]
		if stats then tinsert(lines, format("  %-20s %4d / %5d / %4d / %4d", layer.name, stats.frames, stats.textures, stats.masks, stats.faint)) end
	end

	local canvas = bench.canvas
	tinsert(lines, format("  %-20s %4d / %5d / %4d / %4d", "whole canvas", canvas.frames, canvas.textures, canvas.masks, canvas.faint))
	local text = table.concat(lines, "\n")
	if type(MAUTTAB) == "table" then MAUTTAB["BENCH"] = lines end
	Profiler.ShowBenchText(text)
end

function Profiler.ShowBenchText(text)
	local window = Profiler.benchWindow
	if window == nil then
		window = MapUtils:CreateUIWindow({
			name = "MapUtilsBenchmark", width = 620, height = 420,
			title = "MapUtils Benchmark", resizable = false,
		})
		window:ClearAllPoints()
		window:SetPoint("CENTER")
		window:SetFrameStrata("DIALOG")
		local content = window.content
		content:SetWidth(math.max(window.contentWidth or 0, 560))
		local hint = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		hint:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
		hint:SetText("Click the text, Ctrl+A, Ctrl+C - or send a screenshot")
		window.edit = CreateFrame("EditBox", nil, content)
		window.edit:SetMultiLine(true)
		window.edit:SetAutoFocus(false)
		window.edit:SetFontObject(ChatFontNormal)
		window.edit:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -22)
		window.edit:SetWidth(560)
		window.edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		window.edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
		window:HookScript("OnHide", Profiler.SavePosition)
		Profiler.RestorePosition(window, "bench")
		Profiler.benchWindow = window
	end

	window.edit:SetText(text)
	window.edit:SetCursorPosition(0)
	local _, lineCount = text:gsub("\n", "")
	window.content:SetHeight(40 + (lineCount + 2) * 15)
	window.edit:SetHeight((lineCount + 2) * 15)
	window:Show()
	if window.UpdateScroll ~= nil then window:UpdateScroll() end
end

function MapUtils:RunRenderBenchmark()
	if Profiler.bench.running then
		MapUtils:INFO("Benchmark already running")

		return
	end

	if not WorldMapFrame:IsShown() then
		MapUtils:INFO("Open the world map first, set the view you want to measure, then run the benchmark again")

		return
	end

	local bench = {
		results = {},
		original = {},
		phases = {},
		context = Profiler.BenchContext(),
		frame = Profiler.bench.frame or CreateFrame("Frame"),
	}

	Profiler.bench.frame = bench.frame
	Profiler.bench.running = bench
	for _, layer in ipairs(Profiler.render.layers) do
		bench.original[layer] = layer.enabled
	end

	Profiler.BenchSetLayers({})
	bench.counts, bench.canvas = Profiler.MeasureLayers()
	tinsert(bench.phases, {name = "all on", states = {}})
	for _, layer in ipairs(Profiler.render.layers) do
		local stats = bench.counts[layer]
		if stats and stats.frames > 0 then tinsert(bench.phases, {name = layer.name .. " off", states = {[layer] = false}}) end
	end

	local allOff = {}
	for _, layer in ipairs(Profiler.render.layers) do
		allOff[layer] = false
	end

	tinsert(bench.phases, {name = "all off", states = allOff})
	tinsert(bench.phases, {name = "all on (again)", states = {}})
	local seconds = #bench.phases * (Profiler.bench.settle + Profiler.bench.measure)
	MapUtils:INFO(format("Benchmark started: %d steps, about %d s. Do not move or zoom the map.", #bench.phases, math.ceil(seconds)))
	local index, elapsed, sum, count, worst = 0, 0, 0, 0, 0
	local function NextPhase()
		index = index + 1
		local phase = bench.phases[index]
		if phase == nil then
			Profiler.BenchFinish(bench)

			return
		end

		Profiler.BenchSetLayers(phase.states)
		elapsed, sum, count, worst = 0, 0, 0, 0
	end

	NextPhase()
	bench.frame:SetScript("OnUpdate", function(_, delta)
		if not WorldMapFrame:IsShown() then
			Profiler.BenchFinish(bench, "world map closed")

			return
		end

		elapsed = elapsed + delta
		if elapsed < Profiler.bench.settle then return end
		sum = sum + delta
		count = count + 1
		worst = math.max(worst, delta)
		if elapsed < Profiler.bench.settle + Profiler.bench.measure then return end
		tinsert(bench.results, {name = bench.phases[index].name, ms = count > 0 and sum / count * 1000 or 0, worst = worst * 1000})
		NextPhase()
	end)
end

function MapUtils:ToggleRenderProfiler()
	local window = Profiler.CreateRenderUI()
	window:SetShown(not window:IsShown())
end

function MapUtils:ToggleProfiler()
	local window = Profiler.CreateUI()
	if window:IsShown() then
		window:Hide()
	else
		window:Show()
	end
end
