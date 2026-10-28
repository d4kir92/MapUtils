local _, MapUtils = ...
MapUtils.CONVERGENCES = {
	[1411] = {
		{variant = "elemental", x = 0.4512, y = 0.1575},
	},
	[1412] = {
		{variant = "elemental", x = 0.3859, y = 0.4474},
		{variant = "elemental", x = 0.5024, y = 0.5355},
		{variant = "elemental", x = 0.5198, y = 0.3417},
	},
	[1413] = {
		{variant = "elemental", x = 0.4357, y = 0.4209},
		{variant = "elemental", x = 0.4697, y = 0.8025},
		{variant = "elemental", x = 0.5086, y = 0.1455},
		{variant = "elemental", x = 0.5461, y = 0.1486},
	},
	[1417] = {
		{variant = "elemental", x = 0.2544, y = 0.3001},
		{variant = "elemental", x = 0.5205, y = 0.5068},
		{variant = "elemental", x = 0.6833, y = 0.3042},
	},
	[1420] = {
		{variant = "elemental", x = 0.4924, y = 0.6387},
	},
	[1421] = {
		{variant = "elemental", x = 0.4936, y = 0.5277},
		{variant = "elemental", x = 0.5621, y = 0.1005},
		{variant = "elemental", x = 0.6125, y = 0.7935},
	},
	[1424] = {
		{variant = "elemental", x = 0.6027, y = 0.1064},
		{variant = "elemental", x = 0.7294, y = 0.6357},
		{variant = "elemental", x = 0.8076, y = 0.4533},
		{variant = "elemental", x = 0.8908, y = 0.5877},
	},
	[1432] = {
		{variant = "elemental", x = 0.2750, y = 0.5207},
		{variant = "elemental", x = 0.5899, y = 0.3659},
	},
	[1434] = {
		{variant = "elemental", x = 0.1335, y = 0.1502},
	},
	[1436] = {
		{variant = "elemental", x = 0.3482, y = 0.7309},
		{variant = "elemental", x = 0.4160, y = 0.8201},
		{variant = "elemental", x = 0.5967, y = 0.3622},
	},
	[1437] = {
		{variant = "elemental", x = 0.5406, y = 0.2688},
	},
	[1439] = {
		{variant = "elemental", x = 0.5842, y = 0.1977},
	},
	[1440] = {
		{variant = "elemental", x = 0.6000, y = 0.6304},
		{variant = "elemental", x = 0.7631, y = 0.6752},
		{variant = "elemental", x = 0.8607, y = 0.5867},
		{variant = "elemental", x = 0.8940, y = 0.4978},
	},
	[1442] = {
		{variant = "elemental", x = 0.8084, y = 0.9052},
	},
}
local Convergence = {
	spells = {
		elemental = 1271953,
		leyline = 1271952
	},
	icons = {
		elemental = 1259686,
		leyline = 1259705
	},
	atlas = "MagePortalAlliance",
	atlasKnown = nil,
	fallbackIcons = {
		elemental = "Interface\\Icons\\Spell_Nature_Cyclone",
		leyline = "Interface\\Icons\\Spell_Arcane_Arcane04"
	},
	labels = {
		elemental = "LID_CONVERGENCE_ELEMENTAL",
		leyline = "LID_CONVERGENCE_LEYLINE"
	},
	english = {
		["elemental convergence"] = "elemental",
		["ley line"] = "leyline",
		["leyline"] = "leyline"
	},
	factions = {
		Horde = "elemental",
		Alliance = "leyline"
	},
	store = "CONVERGENCECAPTURES",
	receivedStore = "CONVERGENCERECEIVED",
	prefix = "MapUtilsCV",
	codes = {
		elemental = "e",
		leyline = "l"
	},
	variants = {
		e = "elemental",
		l = "leyline"
	},
	replyBusyUntil = 0,
	perMessage = 9,
	maxMessages = 20,
	sendGap = 1.1,
	replyGap = 30,
	maxReceived = 500,
	replied = {},
	receivedCount = {},
	receivedNew = {},
	debugQueued = false,
	mergeYards = 40,
	hoverInterval = 0.1,
	lastHover = 0,
	scanInterval = 2,
	moveYards = 30,
	moveShare = 0.2,
	idleSeconds = 60,
	coarseStep = 6,
	fineStep = 2,
	fineMargin = 2,
	coarsePerFrame = 60,
	finePerFrame = 150,
	refreshQueued = false,
	names = nil,
	scan = nil,
	lastScan = nil,
	scanFrame = nil
}

function Convergence.IsSecret(...)
	if issecretvalue == nil then return false end
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if issecretvalue(value) then return true end
	end

	return false
end

function Convergence.GetSpellName(spellID)
	if C_Spell ~= nil and C_Spell.GetSpellName ~= nil then return C_Spell.GetSpellName(spellID) end
	if GetSpellInfo ~= nil then return (GetSpellInfo(spellID)) end

	return nil
end

function Convergence.GetNames()
	if Convergence.names ~= nil then return Convergence.names end
	local names = {}
	local complete = true
	for name, variant in pairs(Convergence.english) do
		names[name] = variant
	end

	for variant, spellID in pairs(Convergence.spells) do
		local name = Convergence.GetSpellName(spellID)
		if type(name) == "string" and name ~= "" then
			names[strlower(name)] = variant
		else
			complete = false
		end
	end

	if complete then Convergence.names = names end

	return names
end

function Convergence.GetVariantName(variant)
	return MapUtils:Trans(Convergence.labels[variant])
end

function Convergence.GetVariantIcon(variant)
	if Convergence.atlasKnown == nil then Convergence.atlasKnown = MapUtils.AtlasExists ~= nil and MapUtils:AtlasExists(Convergence.atlas) == true end
	if Convergence.atlasKnown then return Convergence.atlas end
	local icon = nil
	if C_Spell ~= nil and C_Spell.GetSpellTexture ~= nil then icon = C_Spell.GetSpellTexture(Convergence.icons[variant]) end

	return icon or Convergence.fallbackIcons[variant]
end

function Convergence.GetLineVariant(text, names)
	if type(text) ~= "string" or Convergence.IsSecret(text) then return nil end
	local clean = text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	clean = strlower(clean)
	for name, variant in pairs(names) do
		if clean:find(name, 1, true) ~= nil then return variant end
	end

	return nil
end

function Convergence.GetDataVariant(data)
	if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
	local names = Convergence.GetNames()
	for _, line in ipairs(data.lines) do
		local variant = Convergence.GetLineVariant(line.leftText, names)
		if variant ~= nil then return variant end
	end

	return nil
end

function Convergence.GetTooltipVariant(tooltip)
	local prefix = tooltip:GetName()
	if prefix == nil then return nil end
	local names = Convergence.GetNames()
	for i = 1, tooltip:NumLines() do
		local line = _G[prefix .. "TextLeft" .. i]
		local variant = line ~= nil and Convergence.GetLineVariant(line:GetText(), names) or nil
		if variant ~= nil then return variant end
	end

	return nil
end

function Convergence.GetViewYards()
	if C_Minimap ~= nil and C_Minimap.GetViewRadius ~= nil then
		local radius = C_Minimap.GetViewRadius()
		if type(radius) == "number" and not Convergence.IsSecret(radius) and radius > 0 then return radius * 2 end
	end

	if MapUtils.GetMinimapYards ~= nil then return MapUtils.GetMinimapYards() end

	return nil
end

function Convergence.GetOffsetMapPos(mapID, offsetX, offsetY)
	local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil
	local yards = Convergence.GetViewYards()
	local wx, wy, _, instanceID = UnitPosition("player")
	local facing = GetPlayerFacing ~= nil and GetPlayerFacing() or 0
	if rect == nil or yards == nil or wx == nil or wy == nil or facing == nil then return nil end
	if Convergence.IsSecret(wx, wy, facing, instanceID) or yards <= 0 then return nil end
	if rect.continentID ~= nil and instanceID ~= nil and rect.continentID ~= instanceID then return nil end
	local width = Minimap:GetWidth()
	if width == nil or width <= 0 then return nil end
	local unitsPerYard = width / yards
	local a = offsetX / unitsPerYard
	local b = offsetY / unitsPerYard
	if MapUtils:GetCVar("rotateMinimap") ~= "1" then facing = 0 end
	local cosF = math.cos(facing)
	local sinF = math.sin(facing)
	local dx = sinF * a + cosF * b
	local dy = sinF * b - cosF * a
	local x = (wy + dy - rect[1].y) / rect[2].y
	local y = (wx + dx - rect[1].x) / rect[2].x
	if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

	return x, y, rect
end

function Convergence.GetStore(key)
	key = key or Convergence.store
	if type(MAUTTAB) ~= "table" then return nil end
	if type(MAUTTAB[key]) ~= "table" then MAUTTAB[key] = {} end

	return MAUTTAB[key]
end

function Convergence.GetDistance(rect, x1, y1, x2, y2)
	if rect == nil then return math.max(math.abs(x1 - x2), math.abs(y1 - y2)) < 0.002 and 0 or math.huge end
	local dx = (x1 - x2) * rect[2].y
	local dy = (y1 - y2) * rect[2].x

	return math.sqrt(dx * dx + dy * dy)
end

function Convergence.Round(value)
	return math.floor(value * 10000 + 0.5) / 10000
end

function Convergence.QueueRefresh()
	if Convergence.refreshQueued then return end
	Convergence.refreshQueued = true
	C_Timer.After(
		1,
		function()
			Convergence.refreshQueued = false
			MapUtils:RefreshPins()
		end
	)
end

function Convergence.AddSample(mapID, variant, x, y, rect)
	local store = Convergence.GetStore()
	if store == nil then return end
	if type(store[mapID]) ~= "table" then store[mapID] = {} end
	for _, point in ipairs(store[mapID]) do
		if point.variant == variant and Convergence.GetDistance(rect, point.x, point.y, x, y) <= Convergence.mergeYards then
			point.n = (point.n or 1) + 1
			point.sx = (point.sx or point.x) + x
			point.sy = (point.sy or point.y) + y
			point.x = Convergence.Round(point.sx / point.n)
			point.y = Convergence.Round(point.sy / point.n)
			Convergence.QueueRefresh()

			return
		end
	end

	tinsert(
		store[mapID],
		{
			variant = variant,
			x = Convergence.Round(x),
			y = Convergence.Round(y),
			sx = x,
			sy = y,
			n = 1
		}
	)

	MapUtils:INFO(format("%s: %s - %s %.1f / %.1f", MapUtils:Trans("LID_CONVERGENCESAVED"), Convergence.GetVariantName(variant), Convergence.GetMapName(mapID), x * 100, y * 100))
	Convergence.QueueRefresh()
	Convergence.QueueDebugRefresh()
end

function Convergence.GetMapName(mapID)
	local info = C_Map.GetMapInfo(mapID)

	return info ~= nil and info.name or tostring(mapID)
end

function Convergence.QueueDebugRefresh()
	if Convergence.debugQueued or MapUtils.RefreshConvergenceDebug == nil then return end
	Convergence.debugQueued = true
	C_Timer.After(
		0.5,
		function()
			Convergence.debugQueued = false
			MapUtils:RefreshConvergenceDebug()
		end
	)
end

function Convergence.AddReceived(mapID, variant, x, y, rect, weight, sender)
	local store = Convergence.GetStore(Convergence.receivedStore)
	if store == nil then return false end
	if type(store[mapID]) ~= "table" then store[mapID] = {} end
	local target = nil
	for _, point in ipairs(store[mapID]) do
		if target == nil and point.variant == variant and Convergence.GetDistance(rect, point.x, point.y, x, y) <= Convergence.mergeYards then target = point end
	end

	local isNew = target == nil
	if isNew then
		target = {
			variant = variant,
			from = {}
		}

		tinsert(store[mapID], target)
	end

	if type(target.from) ~= "table" then target.from = {} end
	target.from[sender] = {
		x = x,
		y = y,
		n = weight
	}

	local sx, sy, n = 0, 0, 0
	for _, part in pairs(target.from) do
		if type(part) == "table" and type(part.x) == "number" and type(part.y) == "number" and type(part.n) == "number" then
			sx = sx + part.x * part.n
			sy = sy + part.y * part.n
			n = n + part.n
		end
	end

	if n > 0 then
		target.x = Convergence.Round(sx / n)
		target.y = Convergence.Round(sy / n)
		target.n = n
	end

	return isNew
end

function Convergence.IsSelf(sender)
	local name, realm = UnitFullName("player")
	if name == nil or sender == name then return true end

	return realm ~= nil and realm ~= "" and sender == name .. "-" .. realm
end

function Convergence.Send(message, chatType, target)
	if C_ChatInfo == nil or C_ChatInfo.SendAddonMessage == nil then return false end
	local ok, result = pcall(C_ChatInfo.SendAddonMessage, Convergence.prefix, message, chatType, target)

	return ok and (result == true or result == 0)
end

function Convergence.IsShippedPoint(mapID, point)
	if MapUtils.CONVERGENCES[mapID] == nil then return false end
	local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil

	return Convergence.IsShipped(mapID, point, rect)
end

function Convergence.BuildReply()
	local messages = {}
	local parts = {}
	local store = Convergence.GetStore()
	for mapID, points in pairs(store or {}) do
		if type(mapID) == "number" and type(points) == "table" then
			for _, point in ipairs(points) do
				local code = Convergence.codes[point.variant]
				if code ~= nil and type(point.x) == "number" and type(point.y) == "number" and not Convergence.IsShippedPoint(mapID, point) then
					tinsert(parts, format("%d,%s,%d,%d,%d", mapID, code, math.floor(point.x * 10000 + 0.5), math.floor(point.y * 10000 + 0.5), math.min(math.floor(point.n or 1), 99999)))
					if #parts >= Convergence.perMessage then
						tinsert(messages, "P;" .. table.concat(parts, ";"))
						wipe(parts)
					end
				end
			end
		end
	end

	if #parts > 0 then tinsert(messages, "P;" .. table.concat(parts, ";")) end

	return messages
end

function Convergence.Reply(sender)
	local now = GetTime()
	if now < Convergence.replyBusyUntil then return end
	if Convergence.replied[sender] ~= nil and now - Convergence.replied[sender] < Convergence.replyGap then return end
	Convergence.replied[sender] = now
	local messages = Convergence.BuildReply()
	Convergence.replyBusyUntil = now + math.min(#messages, Convergence.maxMessages) * Convergence.sendGap
	for i = 1, math.min(#messages, Convergence.maxMessages) do
		local message = messages[i]
		C_Timer.After((i - 1) * Convergence.sendGap, function() Convergence.Send(message, "WHISPER", sender) end)
	end
end

function Convergence.ReceivePart(part, sender)
	local mapText, code, xText, yText, nText = part:match("^(%d+),(%a),(%d+),(%d+),(%d+)$")
	if mapText == nil then return end
	local variant = Convergence.variants[code]
	local mapID, x, y, n = tonumber(mapText), tonumber(xText), tonumber(yText), tonumber(nText)
	if variant == nil or mapID == nil or x == nil or y == nil or n == nil then return end
	if mapID < 1 or mapID > 100000 or x > 10000 or y > 10000 or n < 1 then return end
	local count = (Convergence.receivedCount[sender] or 0) + 1
	if count > Convergence.maxReceived then return end
	Convergence.receivedCount[sender] = count
	local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil
	if rect == nil then return end
	if Convergence.AddReceived(mapID, variant, x / 10000, y / 10000, rect, math.min(n, 1000), sender) then Convergence.receivedNew[sender] = (Convergence.receivedNew[sender] or 0) + 1 end
end

function Convergence.ReportReceived()
	for sender, count in pairs(Convergence.receivedNew) do
		MapUtils:INFO(format(MapUtils:Trans("LID_CONVERGENCERECEIVED"), count, sender))
	end

	wipe(Convergence.receivedNew)
end

function Convergence.OnAddonMessage(prefix, message, sender)
	if prefix ~= Convergence.prefix or type(message) ~= "string" or type(sender) ~= "string" then return end
	if Convergence.IsSecret(prefix, message, sender) or Convergence.IsSelf(sender) then return end
	if message == "Q" then
		Convergence.Reply(sender)

		return
	end

	if message:sub(1, 2) ~= "P;" then return end
	for part in message:sub(3):gmatch("[^;]+") do
		Convergence.ReceivePart(part, sender)
	end

	if next(Convergence.receivedNew) ~= nil then C_Timer.After(1, Convergence.ReportReceived) end
	Convergence.QueueDebugRefresh()
end

function MapUtils:RequestConvergences()
	local sent = MapUtils.Comm ~= nil and MapUtils.Comm.SendPrefixed(Convergence.prefix, "Q", "ALL") or {}
	if #sent == 0 then
		MapUtils:INFO(MapUtils:Trans("LID_CONVERGENCENOREQUEST"))

		return
	end

	MapUtils:INFO(format(MapUtils:Trans("LID_CONVERGENCEREQUESTSENT"), table.concat(sent, ", ")))
end

function Convergence.CollectReport(rows, mapID, point, source)
	if type(point) ~= "table" or type(point.x) ~= "number" or type(point.y) ~= "number" or Convergence.codes[point.variant] == nil then return end
	local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil
	if MapUtils.CONVERGENCES[mapID] ~= nil and Convergence.IsShipped(mapID, point, rect) then return end
	for _, row in ipairs(rows) do
		if row.mapID == mapID and row.variant == point.variant and Convergence.GetDistance(rect, row.x, row.y, point.x, point.y) <= Convergence.mergeYards then return end
	end

	tinsert(
		rows,
		{
			mapID = mapID,
			variant = point.variant,
			x = point.x,
			y = point.y,
			text = format("%s | %d %s | %.4f %.4f | %s n=%d", point.variant, mapID, Convergence.GetMapName(mapID), point.x, point.y, source, math.floor(point.n or 1))
		}
	)
end

function Convergence.GetSenders(point)
	local senders = {}
	for sender in pairs(type(point.from) == "table" and point.from or {}) do
		tinsert(senders, sender)
	end

	table.sort(senders)

	return "from " .. table.concat(senders, ", ")
end

function MapUtils:GetConvergenceReport()
	local rows = {}
	for mapID, points in pairs(Convergence.GetStore() or {}) do
		if type(mapID) == "number" and type(points) == "table" then
			for _, point in ipairs(points) do
				Convergence.CollectReport(rows, mapID, point, "own")
			end
		end
	end

	for mapID, points in pairs(Convergence.GetStore(Convergence.receivedStore) or {}) do
		if type(mapID) == "number" and type(points) == "table" then
			for _, point in ipairs(points) do
				Convergence.CollectReport(rows, mapID, point, Convergence.GetSenders(point))
			end
		end
	end

	local lines = {}
	for _, row in ipairs(rows) do
		tinsert(lines, row.text)
	end

	table.sort(lines)

	return lines
end

function Convergence.IsController()
	if InputUtil ~= nil and InputUtil.IsGamepadUIEnabled ~= nil and InputUtil.IsGamepadUIEnabled() then return true end

	return SoftCursor ~= nil and SoftCursor.IsShown ~= nil and SoftCursor:IsShown()
end

function Convergence.CanScan()
	return Minimap ~= nil and Minimap.SetUsingSoftCursor ~= nil and Minimap.UpdateMouseoverAtPoint ~= nil and C_TooltipInfo ~= nil and C_TooltipInfo.GetMinimapMouseover ~= nil
end

function Convergence.UsesScan()
	return Convergence.CanScan() and not Convergence.IsController()
end

function Convergence.IsScanBlocked()
	return InCombatLockdown() or not Minimap:IsVisible() or Minimap:IsMouseOver()
end

function Convergence.VariantAt(scan, offsetX, offsetY)
	Minimap:UpdateMouseoverAtPoint((scan.centerX + offsetX) * scan.scale, (scan.centerY + offsetY) * scan.scale)

	return Convergence.GetDataVariant(C_TooltipInfo.GetMinimapMouseover())
end

function Convergence.ScanCoarse(scan)
	local step = Convergence.coarseStep
	local last = math.min(scan.index + Convergence.coarsePerFrame, scan.side * scan.side) - 1
	for index = scan.index, last do
		local i = index % scan.side - scan.count
		local j = math.floor(index / scan.side) - scan.count
		local offsetX = i * step
		local offsetY = j * step
		if scan.square or offsetX * offsetX + offsetY * offsetY <= scan.radius * scan.radius then
			local variant = Convergence.VariantAt(scan, offsetX, offsetY)
			if variant ~= nil then
				tinsert(
					scan.hits,
					{
						i = i,
						j = j,
						variant = variant
					}
				)
			end
		end
	end

	scan.index = last + 1
end

function Convergence.GroupHits(hits)
	local byKey = {}
	for _, hit in ipairs(hits) do
		byKey[hit.i .. ":" .. hit.j] = hit
	end

	local blips = {}
	local step = Convergence.coarseStep
	for _, hit in ipairs(hits) do
		if not hit.seen then
			hit.seen = true
			local blip = {
				i0 = hit.i,
				i1 = hit.i,
				j0 = hit.j,
				j1 = hit.j,
				variant = hit.variant,
				index = 0,
				hits = {}
			}

			local stack = {hit}
			while #stack > 0 do
				local current = tremove(stack)
				blip.i0 = math.min(blip.i0, current.i)
				blip.i1 = math.max(blip.i1, current.i)
				blip.j0 = math.min(blip.j0, current.j)
				blip.j1 = math.max(blip.j1, current.j)
				for di = -1, 1 do
					for dj = -1, 1 do
						local near = byKey[(current.i + di) .. ":" .. (current.j + dj)]
						if near ~= nil and not near.seen then
							near.seen = true
							tinsert(stack, near)
						end
					end
				end
			end

			local margin = Convergence.fineMargin
			blip.x0 = (blip.i0 - margin) * step
			blip.y0 = (blip.j0 - margin) * step
			blip.cols = math.floor((blip.i1 - blip.i0 + margin * 2) * step / Convergence.fineStep) + 1
			blip.rows = math.floor((blip.j1 - blip.j0 + margin * 2) * step / Convergence.fineStep) + 1
			tinsert(blips, blip)
		end
	end

	return blips
end

function Convergence.ScanFine(scan)
	local blip = scan.blips[scan.blip]
	if blip == nil then return end
	local total = blip.cols * blip.rows
	local last = math.min(blip.index + Convergence.finePerFrame, total) - 1
	for index = blip.index, last do
		local offsetX = blip.x0 + (index % blip.cols) * Convergence.fineStep
		local offsetY = blip.y0 + math.floor(index / blip.cols) * Convergence.fineStep
		if Convergence.VariantAt(scan, offsetX, offsetY) ~= nil then blip.hits[index] = true end
	end

	blip.index = last + 1
	if blip.index < total then return end
	scan.blip = scan.blip + 1
	Convergence.SplitBlip(scan, blip)
end

function Convergence.PushHit(blip, stack, index, valid)
	if not valid or blip.hits[index] ~= true then return end
	blip.hits[index] = false
	tinsert(stack, index)
end

function Convergence.AddFound(scan, variant, offsetX, offsetY)
	local limit = Convergence.fineStep * Convergence.fineStep * 4
	for _, center in ipairs(scan.centers) do
		local dx = center.x - offsetX
		local dy = center.y - offsetY
		if dx * dx + dy * dy < limit then return end
	end

	local found = {
		variant = variant,
		x = offsetX,
		y = offsetY
	}

	tinsert(scan.centers, found)
	tinsert(scan.found, found)
end

function Convergence.SplitBlip(scan, blip)
	for index in pairs(blip.hits) do
		if blip.hits[index] == true then
			local sx, sy, n, border = 0, 0, 0, false
			local stack = {index}
			blip.hits[index] = false
			while #stack > 0 do
				local current = tremove(stack)
				local col = current % blip.cols
				local row = math.floor(current / blip.cols)
				if col == 0 or row == 0 or col == blip.cols - 1 or row == blip.rows - 1 then border = true end
				sx = sx + blip.x0 + col * Convergence.fineStep
				sy = sy + blip.y0 + row * Convergence.fineStep
				n = n + 1
				Convergence.PushHit(blip, stack, current - 1, col > 0)
				Convergence.PushHit(blip, stack, current + 1, col < blip.cols - 1)
				Convergence.PushHit(blip, stack, current - blip.cols, true)
				Convergence.PushHit(blip, stack, current + blip.cols, true)
			end

			if not border then Convergence.AddFound(scan, blip.variant, sx / n, sy / n) end
		end
	end
end

function Convergence.ScanStep(scan)
	if scan.blips == nil then
		Convergence.ScanCoarse(scan)
		if scan.index >= scan.side * scan.side then scan.blips = Convergence.GroupHits(scan.hits) end

		return
	end

	Convergence.ScanFine(scan)
end

function Convergence.StopScan()
	Convergence.scan = nil
	if Convergence.scanFrame ~= nil then Convergence.scanFrame:Hide() end
end

function Convergence.OnScanUpdate()
	local scan = Convergence.scan
	if scan == nil or Convergence.IsScanBlocked() or C_Map.GetBestMapForUnit("player") ~= scan.mapID then
		Convergence.StopScan()

		return
	end

	Minimap:SetUsingSoftCursor(true)
	local ok = pcall(Convergence.ScanStep, scan)
	Minimap:SetUsingSoftCursor(false)
	if not ok then
		Convergence.StopScan()

		return
	end

	for i = #scan.found, 1, -1 do
		local found = tremove(scan.found, i)
		local x, y, rect = Convergence.GetOffsetMapPos(scan.mapID, found.x, found.y)
		if x ~= nil then Convergence.AddSample(scan.mapID, found.variant, x, y, rect) end
	end

	if scan.blips ~= nil and scan.blip > #scan.blips then Convergence.StopScan() end
end

function Convergence.StartScan(mapID, wx, wy, zoom)
	local width, height = Minimap:GetSize()
	local centerX, centerY = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	if width == nil or height == nil or centerX == nil or centerY == nil or scale == nil or scale <= 0 then return end
	local radius = math.min(width, height) / 2
	local count = math.floor(radius / Convergence.coarseStep)
	Convergence.scan = {
		mapID = mapID,
		centerX = centerX,
		centerY = centerY,
		scale = scale,
		radius = radius,
		count = count,
		side = count * 2 + 1,
		square = GetMinimapShape ~= nil and GetMinimapShape() == "SQUARE",
		index = 0,
		hits = {},
		blips = nil,
		blip = 1,
		found = {},
		centers = {}
	}

	local last = Convergence.lastScan or {}
	last.mapID, last.x, last.y, last.zoom, last.time = mapID, wx, wy, zoom, GetTime()
	Convergence.lastScan = last
	Convergence.scanFrame:Show()
end

function Convergence.MaybeScan()
	if Convergence.scan ~= nil or not MapUtils:IsSkyborne() or not Convergence.UsesScan() or Convergence.IsScanBlocked() or IsInInstance() then return end
	local mapID = C_Map.GetBestMapForUnit("player")
	local wx, wy = UnitPosition("player")
	local zoom = Minimap:GetZoom()
	if mapID == nil or wx == nil or wy == nil or zoom == nil or Convergence.IsSecret(mapID, wx, wy, zoom) then return end
	local last = Convergence.lastScan
	if last ~= nil and last.mapID == mapID and last.zoom == zoom and GetTime() - last.time < Convergence.idleSeconds then
		local dx = wx - last.x
		local dy = wy - last.y
		local move = math.max(Convergence.moveYards, (Convergence.GetViewYards() or 0) * Convergence.moveShare)
		if dx * dx + dy * dy < move * move then return end
	end

	Convergence.StartScan(mapID, wx, wy, zoom)
end

function Convergence.OnMinimapMouseover(tooltip)
	if not MapUtils:IsForever() or Minimap == nil or tooltip == nil then return end
	local now = GetTime()
	if now - Convergence.lastHover < Convergence.hoverInterval then return end
	Convergence.lastHover = now
	if Convergence.UsesScan() then return end
	local variant = Convergence.GetTooltipVariant(tooltip)
	if variant == nil then return end
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID == nil or Convergence.IsSecret(mapID) then return end
	local centerX, centerY = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	if centerX == nil or centerY == nil or scale == nil or scale <= 0 then return end
	local cursorX, cursorY = GetCursorPosition()
	local x, y, rect = Convergence.GetOffsetMapPos(mapID, cursorX / scale - centerX, cursorY / scale - centerY)
	if x == nil then return end
	Convergence.AddSample(mapID, variant, x, y, rect)
end

function Convergence.CreateEntry(point, captured)
	return {
		kind = "convergence",
		variant = point.variant,
		x = point.x,
		y = point.y,
		name = Convergence.GetVariantName(point.variant),
		icon = Convergence.GetVariantIcon(point.variant),
		captured = captured
	}
end

function Convergence.IsShipped(mapID, point, rect)
	for _, shipped in ipairs(MapUtils.CONVERGENCES[mapID]) do
		if shipped.variant == point.variant and Convergence.GetDistance(rect, shipped.x, shipped.y, point.x, point.y) <= Convergence.mergeYards then return true end
	end

	return false
end

function MapUtils:IsSkyborne()
	local _, raceFile = UnitRace("player")

	return raceFile == "Skyborne"
end

function MapUtils:ConvergencePinsEnabled(worldMap)
	if not MapUtils:IsForever() then return false end
	if not MapUtils:IsSkyborne() and MapUtils:GetConfig("CONVERGENCENONSKYBORNE", false) ~= true then return false end
	if worldMap then return MapUtils:GetConfig("CONVERGENCEWORLDMAPPINS", true) == true end

	return MapUtils:GetConfig("CONVERGENCEMINIMAPPINS", false) == true
end

function Convergence.MergeWowhead()
	if Convergence.wowheadMerged or type(MapUtils.CONVERGENCESWOWHEAD) ~= "table" then return end
	Convergence.wowheadMerged = true
	for mapID, points in pairs(MapUtils.CONVERGENCESWOWHEAD) do
		if type(mapID) == "number" and type(points) == "table" then
			local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil
			for _, point in ipairs(points) do
				if type(point) == "table" and Convergence.codes[point.variant] ~= nil and type(point.x) == "number" and type(point.y) == "number" then
					if MapUtils.CONVERGENCES[mapID] == nil then MapUtils.CONVERGENCES[mapID] = {} end
					local list = MapUtils.CONVERGENCES[mapID]
					local duplicate = false
					for i = #list, 1, -1 do
						local other = list[i]
						if other.variant == point.variant and Convergence.GetDistance(rect, other.x, other.y, point.x, point.y) <= Convergence.mergeYards then
							if other.wowhead then
								duplicate = true
							else
								tremove(list, i)
							end
						end
					end

					if not duplicate then
						tinsert(
							list,
							{
								variant = point.variant,
								x = point.x,
								y = point.y,
								wowhead = true
							}
						)
					end
				end
			end
		end
	end
end

function MapUtils:GetConvergencePins(mapID)
	if mapID == nil then return nil end
	Convergence.MergeWowhead()
	local variant = Convergence.factions[UnitFactionGroup("player")]
	local rect = MapUtils.GetMapRect ~= nil and MapUtils.GetMapRect(mapID) or nil
	local list = {}
	if MapUtils.CONVERGENCES[mapID] ~= nil then
		for _, point in ipairs(MapUtils.CONVERGENCES[mapID]) do
			if variant == nil or point.variant == variant then tinsert(list, Convergence.CreateEntry(point, false)) end
		end
	end

	local store = Convergence.GetStore()
	if store ~= nil and type(store[mapID]) == "table" then
		for _, point in ipairs(store[mapID]) do
			if (variant == nil or point.variant == variant) and (MapUtils.CONVERGENCES[mapID] == nil or not Convergence.IsShipped(mapID, point, rect)) then tinsert(list, Convergence.CreateEntry(point, true)) end
		end
	end

	return list
end

Convergence.loginFrame = CreateFrame("FRAME")
Convergence.loginFrame:RegisterEvent("PLAYER_LOGIN")
Convergence.loginFrame:SetScript("OnEvent", Convergence.MergeWowhead)
if GameTooltip ~= nil and GameTooltip.SetMinimapMouseover ~= nil then hooksecurefunc(GameTooltip, "SetMinimapMouseover", Convergence.OnMinimapMouseover) end
if MapUtils:IsForever() and Minimap ~= nil and C_Timer ~= nil and C_Timer.NewTicker ~= nil then
	Convergence.scanFrame = CreateFrame("FRAME")
	Convergence.scanFrame:Hide()
	Convergence.scanFrame:SetScript("OnUpdate", Convergence.OnScanUpdate)
	C_Timer.NewTicker(Convergence.scanInterval, Convergence.MaybeScan)
end

if MapUtils:IsForever() and C_ChatInfo ~= nil and C_ChatInfo.RegisterAddonMessagePrefix ~= nil then
	C_ChatInfo.RegisterAddonMessagePrefix(Convergence.prefix)
	Convergence.commFrame = CreateFrame("FRAME")
	Convergence.commFrame:RegisterEvent("CHAT_MSG_ADDON")
	Convergence.commFrame:SetScript("OnEvent", function(_, _, prefix, message, _, sender) Convergence.OnAddonMessage(prefix, message, sender) end)
end
