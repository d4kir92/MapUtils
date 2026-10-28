local _, MapUtils = ...
local Transport = {
	media = "Interface\\AddOns\\MapUtils\\media\\",
	icons = {
		ship = "vessel_ship",
		zeppelin = "vessel_zeppelin",
		tram = "transport_tram"
	},
	rects = {
		[0] = {44688.53, 29795.11, 32601.04, 9894.93},
		[1] = {44878.66, 29916.10, 8723.96, 14824.53}
	},
	codes = {
		era = "e",
		forever = "f",
		tbc = "t",
		wrath = "w",
		cata = "c",
		mists = "m"
	},
	decoded = {},
	zoneIndex = {},
	worldPins = {},
	minimapPins = {},
	pending = {},
	announce = {},
	lastAnnounce = {},
	received = {},
	queryGap = 600,
	staleAge = 2 * 86400,
	maxAge = 30 * 86400,
	announceGap = 600,
	perMessage = 10,
	maxPerSender = 60,
	iconSize = 22,
	minimapIconSize = 18,
	dockRadius = 150,
	dockTolerance = 15,
	interval = 0.1,
	triggerInterval = 0.8,
	triggerRadius = 20,
	minMove = 6.16,
	commitMove = 17,
	maxMove = 80,
	triggerCooldown = 30
}

MapUtils.Transport = Transport
function Transport.GetRoutes()
	return MapUtils.TRANSPORTROUTES or {}
end

function Transport.IsSecret(...)
	return MapUtils.Comm ~= nil and MapUtils.Comm.IsSecret(...)
end

function Transport.GetCode()
	return Transport.codes[MapUtils:GetFlavor() or ""] or "x"
end

function Transport.Now()
	if Transport.clockOffset ~= nil then return GetTime() + Transport.clockOffset end

	return GetServerTime()
end

function Transport.CalibrateClock()
	local frame = CreateFrame("FRAME")
	local last = GetServerTime()
	frame:SetScript(
		"OnUpdate",
		function(self)
			local now = GetServerTime()
			if now ~= last then
				Transport.clockOffset = now - GetTime()
				self:SetScript("OnUpdate", nil)
			end
		end
	)
end

function Transport.Decode(route)
	local d = {
		x = {},
		y = {},
		dx = {},
		dy = {},
		dt = {},
		dir = {},
		ddir = {},
		offset = {
			[0] = 0
		},
		plat = {},
		trig = {},
		zoning = {},
		jump = {},
		rawp = {}
	}

	local x, y, t, dir = 0, 0, 0, 0
	for i, packed in ipairs(route.points) do
		local fields = {strsplit(":", packed)}
		local dx, dy, dt, ddir = tonumber(fields[1]) or 0, tonumber(fields[2]) or 0, tonumber(fields[3]) or 0, math.rad(tonumber(fields[5]) or 0)
		x, y, t, dir = x + dx, y + dy, t + dt, dir + ddir
		d.x[i], d.y[i], d.offset[i], d.dir[i] = x, y, t, dir
		d.dx[i], d.dy[i], d.dt[i], d.ddir[i] = dx, dy, dt, ddir
		for k = 6, #fields do
			local kind, number = fields[k]:sub(1, 4), tonumber(fields[k]:sub(5))
			if kind == "plat" and number ~= nil then
				d.plat[number] = i
			elseif kind == "trig" and number ~= 0 then
				tinsert(d.trig, i)
			elseif kind == "zone" then
				d.zoning[i] = true
			elseif kind == "jump" then
				d.jump[i] = true
			elseif kind == "rawp" then
				d.rawp[i] = true
			end
		end
	end

	d.count = #route.points
	d.offset[d.count] = route.rtt

	return d
end

function Transport.Init()
	for id, route in pairs(Transport.GetRoutes()) do
		Transport.decoded[id] = Transport.Decode(route)
		for mapID, flag in pairs(route.zones or {}) do
			Transport.zoneIndex[mapID] = Transport.zoneIndex[mapID] or {}
			Transport.zoneIndex[mapID][id] = flag
		end
	end

	if next(Transport.decoded) == nil then return end
	Transport.CalibrateClock()
	C_Timer.NewTicker(Transport.triggerInterval, Transport.CheckTriggers)
	if MapUtils.Comm ~= nil then MapUtils.Comm.Register("T", Transport.OnMessage) end
	C_Timer.After(25 + math.random() * 25, function() Transport.Query(true) end)
	Transport.CreateUpdaters()
end

function Transport.GetStore()
	if type(MAUTTAB) ~= "table" then return nil end
	if type(MAUTTAB.TRANSPORTSYNC) ~= "table" then MAUTTAB.TRANSPORTSYNC = {} end
	local flavor = MapUtils:GetFlavor() or "unknown"
	if type(MAUTTAB.TRANSPORTSYNC[flavor]) ~= "table" then MAUTTAB.TRANSPORTSYNC[flavor] = {} end

	return MAUTTAB.TRANSPORTSYNC[flavor]
end

function Transport.GetKnown(id)
	local store = Transport.GetStore()
	local known = store ~= nil and store[id] or nil
	if type(known) ~= "table" or type(known.p) ~= "number" or type(known.t) ~= "number" then return nil end
	if Transport.Now() - known.t > Transport.maxAge then return nil end

	return known
end

function Transport.GetCycle(id)
	local route, known = Transport.GetRoutes()[id], Transport.GetKnown(id)
	if route == nil or known == nil then return nil end

	return (Transport.Now() - known.p) % route.rtt
end

function Transport.FindIndex(d, cycle)
	local start = d.hint or 1
	if start > d.count or start > 1 and d.offset[start - 1] > cycle then start = 1 end
	for i = start, d.count do
		if d.offset[i] > cycle then
			d.hint = i

			return i
		end
	end

	d.hint = d.count

	return d.count
end

function Transport.ToWorld(route, d, index, x, y)
	if d.rawp[index] then return route.raw, x, y end
	if route.coords >= 0 then return route.coords, x, y end
	local instance = x < 0.5 and 1 or 0
	local rect = Transport.rects[instance]

	return instance, rect[3] - rect[1] * x, rect[4] - rect[2] * y
end

function Transport.GetPosition(id)
	local route, d = Transport.GetRoutes()[id], Transport.decoded[id]
	local cycle = Transport.GetCycle(id)
	if cycle == nil or d == nil then return nil end
	local index = Transport.FindIndex(d, cycle)
	if d.jump[index] then return nil end
	local x, y, angle, zoning = d.x[index], d.y[index], d.dir[index], false
	if index > 1 then
		local f = d.dt[index] > 0 and math.min(1, math.max(0, (cycle - d.offset[index - 1]) / d.dt[index])) or 1
		x = d.x[index - 1] + d.dx[index] * f
		y = d.y[index - 1] + d.dy[index] * f
		angle = d.dir[index - 1] + d.ddir[index] * f
		zoning = d.zoning[index] == true
	end

	local instance, wx, wy = Transport.ToWorld(route, d, index, x, y)

	return instance, wx, wy, angle, zoning
end

function Transport.GetPlatformTimes(id)
	local route, d = Transport.GetRoutes()[id], Transport.decoded[id]
	local cycle = Transport.GetCycle(id)
	if cycle == nil or d == nil then return nil end
	local index = Transport.FindIndex(d, cycle)
	local list = {}
	for number, pointIndex in pairs(d.plat) do
		local docked = pointIndex == index
		local wait = docked and d.offset[pointIndex] - cycle or d.offset[pointIndex - 1] - cycle
		if wait < 0 then wait = wait + route.rtt end
		tinsert(
			list,
			{
				number = number,
				name = route.platforms[number],
				docked = docked,
				wait = wait,
				stay = d.offset[pointIndex] - d.offset[pointIndex - 1]
			}
		)
	end

	table.sort(list, function(a, b) return a.number < b.number end)

	return list
end

function Transport.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))

	return format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function Transport.FormatAge(seconds)
	seconds = math.max(60, math.floor(seconds))
	if SecondsToTime ~= nil then return SecondsToTime(seconds, true) end

	return format("%d min", math.floor(seconds / 60))
end

function Transport.ShortName(name)
	local translated = MapUtils:TransName(name) or name or "?"

	return (strsplit(",", translated))
end

function Transport.GetStatusText(entry, prefix)
	local name = prefix or Transport.ShortName(entry.name)
	if entry.docked then return format(entry.wait <= 30 and "|cffff4040%s|r" or "|cffffd100%s|r", format(MapUtils:Trans("LID_VESSELDOCKED"), name, Transport.FormatTime(entry.wait))) end

	return format("|cff4cff4c%s|r", format(MapUtils:Trans("LID_VESSELARRIVESDEPARTS"), name, Transport.FormatTime(entry.wait), Transport.FormatTime(entry.wait + entry.stay)))
end

function Transport.AddStatusLine(tooltip, entry, prefix)
	tooltip:AddLine(Transport.GetStatusText(entry, prefix))
end

function Transport.AddSourceLine(tooltip, id)
	local known = Transport.GetKnown(id)
	if known == nil then return end
	local age = Transport.FormatAge(Transport.Now() - known.t)
	if known.s == "self" then
		tooltip:AddLine(format(MapUtils:Trans("LID_VESSELSOURCESELF"), age), 0.6, 0.6, 0.6)
	else
		tooltip:AddLine(format(MapUtils:Trans("LID_VESSELSOURCE"), tostring(known.s), age), 0.6, 0.6, 0.6)
	end
end

function Transport.FillTooltip(tooltip, id)
	local route = Transport.GetRoutes()[id]
	if route == nil then return end
	tooltip:AddLine(MapUtils:TransName(route.vessel) or route.vessel, 1, 1, 1)
	local names = {}
	for number = 1, #route.platforms do
		tinsert(names, Transport.ShortName(route.platforms[number]))
	end

	tooltip:AddLine(table.concat(names, " - "), 0.6, 0.6, 0.6)
	for _, entry in ipairs(Transport.GetPlatformTimes(id) or {}) do
		Transport.AddStatusLine(tooltip, entry)
	end

	Transport.AddSourceLine(tooltip, id)
end

function Transport.RefreshTooltip(pin)
	if pin.routeID == nil or not GameTooltip:IsOwned(pin) then return end
	GameTooltip:ClearLines()
	Transport.FillTooltip(GameTooltip, pin.routeID)
	GameTooltip:Show()
	pin.tooltipTime = GetTime()
end

function Transport.OnPinEnter(pin)
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	Transport.RefreshTooltip(pin)
end

function Transport.OnPinLeave(pin)
	if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
end

function Transport.AcquirePin(list, index, parent)
	local pin = list[index]
	if pin == nil then
		pin = CreateFrame("FRAME", nil, parent)
		pin.texture = pin:CreateTexture(nil, "OVERLAY")
		pin.texture:SetAllPoints(pin)
		pin:EnableMouse(true)
		pin:SetScript("OnEnter", Transport.OnPinEnter)
		pin:SetScript("OnLeave", Transport.OnPinLeave)
		list[index] = pin
	end

	return pin
end

function Transport.ShowPin(pin, id, route, size, angle, zoning)
	pin.routeID = id
	pin:SetSize(size, size)
	local icon = Transport.media .. (Transport.icons[route.kind] or Transport.icons.ship)
	if pin.icon ~= icon then
		pin.texture:SetTexture(icon)
		pin.icon = icon
	end

	pin.texture:SetRotation(route.kind == "tram" and 0 or angle)
	pin:SetAlpha(zoning and 0.45 or 1)
	pin:ClearAllPoints()
	pin:Show()
	if GameTooltip:IsOwned(pin) and GetTime() - (pin.tooltipTime or 0) >= 1 then Transport.RefreshTooltip(pin) end
end

function Transport.HideFrom(list, first)
	for i = first, #list do
		list[i]:Hide()
		list[i].routeID = nil
	end
end

function Transport.Enabled(worldMap)
	return MapUtils:GetConfig(worldMap and "VESSELWORLDMAPPINS" or "VESSELMINIMAPPINS", true) == true
end

function Transport.GetCanvas()
	if WorldMapFrame == nil then return nil end
	if WorldMapFrame.GetCanvas ~= nil then return WorldMapFrame:GetCanvas() end
	if WorldMapFrame.ScrollContainer == nil then return nil end

	return WorldMapFrame.ScrollContainer.Child
end

function Transport.GetOneMapProjections(mapID)
	if MapUtils.IsOneMap == nil or not MapUtils:IsOneMap() or MapUtils.IsZoneDetailMap == nil or not MapUtils:IsZoneDetailMap(mapID) then return nil end
	local minX, maxX, minY, maxY = MapUtils:GetZoneDetailRawRect(mapID)
	if minX == nil then return nil end
	local space = MapUtils:GetZoneDetailSpace(mapID)
	local hostL, hostR, hostT, hostB = 0, 1, 0, 1
	if mapID ~= space then hostL, hostR, hostT, hostB = C_Map.GetMapRectOnMap(mapID, space) end
	if hostL == nil or hostR <= hostL or hostB <= hostT then return nil end
	local list = {}
	for _, continentID in ipairs(MapUtils:GetZoneDetailContinents(space)) do
		local rect = MapUtils.GetMapRect(continentID)
		local l, r, t, b = 0, 1, 0, 1
		if continentID ~= space then l, r, t, b = C_Map.GetMapRectOnMap(continentID, space) end
		if rect ~= nil and l ~= nil and r > l and b > t then
			tinsert(
				list,
				{
					rect = rect,
					ox = (l - hostL) / (hostR - hostL),
					oy = (t - hostT) / (hostB - hostT),
					sx = (r - l) / (hostR - hostL),
					sy = (b - t) / (hostB - hostT)
				}
			)
		end
	end

	list.minX, list.maxX, list.minY, list.maxY = minX, maxX, minY, maxY

	return list
end

function Transport.GetProjections(mapID)
	local list = Transport.GetOneMapProjections(mapID)
	if list ~= nil and #list > 0 then return list end
	local rect = MapUtils.GetMapRect(mapID)
	if rect == nil then return nil end

	return {
		{
			rect = rect,
			ox = 0,
			oy = 0,
			sx = 1,
			sy = 1
		},
		minX = 0,
		maxX = 1,
		minY = 0,
		maxY = 1
	}
end

function Transport.Project(projections, instance, wx, wy)
	for _, p in ipairs(projections) do
		if p.rect.continentID == instance then
			local cx, cy = (wx - p.rect[1].y) / p.rect[2].y, (wy - p.rect[1].x) / p.rect[2].x
			if cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
				local mx, my = p.ox + cx * p.sx, p.oy + cy * p.sy
				if mx >= projections.minX and mx <= projections.maxX and my >= projections.minY and my <= projections.maxY then return mx, my end
			end
		end
	end

	return nil
end

function Transport.UpdateWorld()
	local shown = 0
	local canvas = Transport.GetCanvas()
	local projections = canvas ~= nil and Transport.Enabled(true) and MapUtils.GetMapRect ~= nil and Transport.GetProjections(WorldMapFrame:GetMapID()) or nil
	if projections ~= nil and canvas:GetScale() > 0 then
		local w, h = canvas:GetWidth(), canvas:GetHeight()
		local size = Transport.iconSize / canvas:GetScale()
		for id, route in pairs(Transport.GetRoutes()) do
			local instance, wx, wy, angle, zoning = Transport.GetPosition(id)
			local mx, my = nil, nil
			if instance ~= nil then mx, my = Transport.Project(projections, instance, wx, wy) end
			if mx ~= nil then
				shown = shown + 1
				local pin = Transport.AcquirePin(Transport.worldPins, shown, canvas)
				Transport.ShowPin(pin, id, route, size, angle, zoning)
				pin:SetFrameLevel(canvas:GetFrameLevel() + 2100)
				pin:SetPoint("CENTER", canvas, "TOPLEFT", w * mx, -h * my)
			end
		end
	end

	Transport.HideFrom(Transport.worldPins, shown + 1)
end

function Transport.GetMinimapFacing()
	if MapUtils:GetCVar("rotateMinimap") ~= "1" or GetPlayerFacing == nil then return 0 end
	local facing = GetPlayerFacing()
	if facing == nil or Transport.IsSecret(facing) then return 0 end

	return facing
end

function Transport.UpdateMinimap()
	local shown = 0
	local yards = Transport.Enabled(false) and MapUtils.GetMinimapYards ~= nil and MapUtils.GetMinimapYards() or nil
	local u1, u2, _, instance = UnitPosition("player")
	if yards ~= nil and yards > 0 and u1 ~= nil and not Transport.IsSecret(u1, u2, instance) then
		local width = Minimap:GetWidth()
		local scale = width / yards
		local radius = width / 2
		local facing = Transport.GetMinimapFacing()
		local cosF, sinF = math.cos(facing), math.sin(facing)
		for id, route in pairs(Transport.GetRoutes()) do
			local vesselInstance, wx, wy, angle, zoning = Transport.GetPosition(id)
			if vesselInstance ~= nil and vesselInstance == instance then
				local dx, dy = wy - u1, wx - u2
				local sx = -(dy * cosF - dx * sinF) * scale
				local sy = (dx * cosF + dy * sinF) * scale
				if sx * sx + sy * sy <= radius * radius then
					shown = shown + 1
					local pin = Transport.AcquirePin(Transport.minimapPins, shown, Minimap)
					Transport.ShowPin(pin, id, route, Transport.minimapIconSize, angle - facing, zoning)
					pin:SetFrameLevel(Minimap:GetFrameLevel() + 12)
					pin:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
				end
			end
		end
	end

	Transport.HideFrom(Transport.minimapPins, shown + 1)
end

function Transport.CreateUpdater(parent, callback)
	local updater = CreateFrame("FRAME", nil, parent)
	updater.elapsed = 0
	updater:SetScript(
		"OnUpdate",
		function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < Transport.interval then return end
			self.elapsed = 0
			callback()
		end
	)

	return updater
end

function Transport.CreateUpdaters()
	if WorldMapFrame ~= nil then
		Transport.CreateUpdater(WorldMapFrame, Transport.UpdateWorld)
		WorldMapFrame:HookScript(
			"OnShow",
			function()
				Transport.Query(false)
			end
		)
	end

	if Minimap ~= nil then Transport.CreateUpdater(Minimap, Transport.UpdateMinimap) end
end

function MapUtils:RefreshTransports()
	Transport.UpdateWorld()
	Transport.UpdateMinimap()
end

function Transport.GetCurrentZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	if Transport.IsSecret(mapID) then return nil end
	if mapID == 1414 or mapID == 1415 then return nil end
	if mapID == nil or mapID == 0 then mapID = select(8, GetInstanceInfo()) end

	return mapID
end

function Transport.DirectionMatches(route, dx, dy, sx, sy)
	local direction = route.direction
	if direction == nil then return true end
	if direction.x and dx * sx <= 0 then return false end
	if direction.y and dy * sy <= 0 then return false end

	return true
end

function Transport.CheckTriggers()
	local _, instanceType = GetInstanceInfo()
	local zone = (instanceType ~= "party" and instanceType ~= "raid") and Transport.GetCurrentZone() or nil
	local routes = zone ~= nil and Transport.zoneIndex[zone] or nil
	if routes == nil then
		Transport.lastPos = nil

		return
	end

	local u1, u2, _, instance = UnitPosition("player")
	if u1 == nil or Transport.IsSecret(u1, u2, instance) then return end
	local last = Transport.lastPos
	Transport.lastPos = {u2, u1, instance}
	if last == nil or last[3] ~= instance then return end
	local wx, wy = u2, u1
	local dx, dy = wx - last[1], wy - last[2]
	local moved = math.sqrt(dx * dx + dy * dy)
	if moved <= Transport.minMove or moved > Transport.maxMove then return end
	if IsSwimming() or UnitOnTaxi("player") then return end
	if Transport.lastTrigger ~= nil and GetTime() - Transport.lastTrigger < Transport.triggerCooldown then return end
	for id, flag in pairs(routes) do
		local route, d = Transport.GetRoutes()[id], Transport.decoded[id]
		if flag ~= "virtual" and route ~= nil and d ~= nil then
			for _, index in ipairs(d.trig) do
				local ti, tx, ty = Transport.ToWorld(route, d, index, d.x[index], d.y[index])
				local pi, px, py = Transport.ToWorld(route, d, index - 1, d.x[index - 1], d.y[index - 1])
				if ti == instance and pi == instance and math.sqrt((wx - tx) ^ 2 + (wy - ty) ^ 2) < Transport.triggerRadius and Transport.DirectionMatches(route, dx, dy, tx - px, ty - py) then
					if moved > Transport.commitMove then
						local segment = math.sqrt((tx - px) ^ 2 + (ty - py) ^ 2)
						if segment > 0 then
							local extrapolate = -d.dt[index] + d.dt[index] * math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2) / segment
							Transport.Observe(id, d.offset[index] + extrapolate)
							Transport.lastTrigger = GetTime()
						end
					end

					return
				end
			end
		end
	end
end

function Transport.Observe(id, cycle)
	local route, store = Transport.GetRoutes()[id], Transport.GetStore()
	if route == nil or store == nil then return end
	local now = Transport.Now()
	store[id] = {
		p = (now - cycle) % route.rtt,
		t = now,
		s = "self"
	}

	Transport.QueueAnnounce(id)
end

function Transport.SyncEnabled()
	return MapUtils.Comm ~= nil and MapUtils.Comm.IsEnabled()
end

function Transport.Encode(id)
	local known = Transport.GetKnown(id)
	if known == nil then return nil end

	return format("%d,%d,%d", id, math.floor(known.p * 1000 + 0.5), math.floor(known.t))
end

function Transport.SendData(ids, dist, target)
	if not Transport.SyncEnabled() then return end
	local parts = {}
	for _, id in ipairs(ids) do
		local encoded = Transport.Encode(id)
		if encoded ~= nil then tinsert(parts, encoded) end
		if #parts >= Transport.perMessage then
			MapUtils.Comm.Send("T", "!" .. Transport.GetCode() .. table.concat(parts, ";"), dist, target)
			wipe(parts)
		end
	end

	if #parts > 0 then MapUtils.Comm.Send("T", "!" .. Transport.GetCode() .. table.concat(parts, ";"), dist, target) end
end

function Transport.GetWanted()
	local ids = {}
	for id in pairs(Transport.GetRoutes()) do
		local known = Transport.GetKnown(id)
		if known == nil or Transport.Now() - known.t > Transport.staleAge then tinsert(ids, id) end
	end

	table.sort(ids)

	return ids
end

function Transport.Query(force)
	if not Transport.SyncEnabled() then return end
	if not force and Transport.lastQuery ~= nil and GetTime() - Transport.lastQuery < Transport.queryGap then return end
	local ids = Transport.GetWanted()
	if #ids == 0 then return end
	Transport.lastQuery = GetTime()
	MapUtils.Comm.Send("T", "?" .. Transport.GetCode() .. table.concat(ids, ","), "ALL")
end

function Transport.QueueAnnounce(id)
	if Transport.lastAnnounce[id] ~= nil and GetTime() - Transport.lastAnnounce[id] < Transport.announceGap then return end
	Transport.announce[id] = true
	if Transport.announceTimer == nil then Transport.announceTimer = C_Timer.NewTimer(5 + math.random() * 10, Transport.FlushAnnounce) end
end

function Transport.FlushAnnounce()
	Transport.announceTimer = nil
	local ids = {}
	for id in pairs(Transport.announce) do
		tinsert(ids, id)
		Transport.lastAnnounce[id] = GetTime()
	end

	wipe(Transport.announce)
	if #ids > 0 then Transport.SendData(ids, "ALL") end
end

function Transport.FlushReply(key)
	local pending = Transport.pending[key]
	Transport.pending[key] = nil
	if pending == nil then return end
	local ids = {}
	for id in pairs(pending.ids) do
		tinsert(ids, id)
	end

	table.sort(ids)
	if #ids > 0 then Transport.SendData(ids, pending.dist, pending.target) end
end

function Transport.OnQuery(body, chatType)
	if not Transport.SyncEnabled() then return end
	local dist, target = MapUtils.Comm.GetReplyTarget(chatType)
	if dist == nil then return end
	local key = dist .. tostring(target or "")
	local pending = Transport.pending[key] or {
		dist = dist,
		target = target,
		ids = {}
	}

	local fresh = false
	local count = 0
	for idText in body:gmatch("%d+") do
		local id = tonumber(idText)
		local known = id ~= nil and Transport.GetKnown(id) or nil
		count = count + 1
		if count > 32 then break end
		if known ~= nil then
			pending.ids[id] = true
			if known.s == "self" and Transport.Now() - known.t < 3600 then fresh = true end
		end
	end

	if next(pending.ids) == nil then return end
	Transport.pending[key] = pending
	if pending.timer == nil then pending.timer = C_Timer.NewTimer((fresh and 1 or 2.5) + math.random() * (fresh and 2 or 5), function() Transport.FlushReply(key) end) end
end

function Transport.Suppress(id, t)
	local known = Transport.GetKnown(id)
	if known ~= nil and t + 1 < known.t then return end
	for _, pending in pairs(Transport.pending) do
		pending.ids[id] = nil
	end

	Transport.announce[id] = nil
end

function Transport.AllowSender(sender)
	local now = GetTime()
	local entry = Transport.received[sender]
	if entry == nil or now - entry.start > 60 then
		entry = {
			start = now,
			count = 0
		}

		Transport.received[sender] = entry
	end

	entry.count = entry.count + 1

	return entry.count <= Transport.maxPerSender
end

function Transport.OnData(body, sender)
	local store = Transport.GetStore()
	if store == nil then return end
	local now = Transport.Now()
	for part in body:gmatch("[^;]+") do
		if not Transport.AllowSender(sender) then return end
		local idText, phaseText, timeText = part:match("^(%d+),(%d+),(%d+)$")
		local id, phase, observed = tonumber(idText), tonumber(phaseText), tonumber(timeText)
		local route = id ~= nil and Transport.GetRoutes()[id] or nil
		if route ~= nil and phase ~= nil and observed ~= nil then
			phase = phase / 1000
			if phase >= 0 and phase < route.rtt and observed <= now + 120 and now - observed < Transport.maxAge then
				Transport.Suppress(id, observed)
				local known = Transport.GetKnown(id)
				if known == nil or observed > known.t + 1 then
					store[id] = {
						p = phase,
						t = observed,
						s = sender
					}
				end
			end
		end
	end
end

function Transport.OnMessage(payload, sender, chatType)
	local kind, code, body = payload:sub(1, 1), payload:sub(2, 2), payload:sub(3)
	if code ~= Transport.GetCode() then return end
	if kind == "?" then
		Transport.OnQuery(body, chatType)
	elseif kind == "!" then
		Transport.OnData(body, sender)
	end
end

function Transport.FindPierRoutes(instance, u1, u2, kind)
	local candidates = {}
	local best = nil
	for id, route in pairs(Transport.GetRoutes()) do
		local d = Transport.decoded[id]
		if d ~= nil and route.kind == kind then
			for number, pointIndex in pairs(d.plat) do
				local pointInstance, wx, wy = Transport.ToWorld(route, d, pointIndex, d.x[pointIndex], d.y[pointIndex])
				local distance = pointInstance == instance and math.sqrt((wx - u2) ^ 2 + (wy - u1) ^ 2) or nil
				if distance ~= nil and distance < Transport.dockRadius then
					tinsert(
						candidates,
						{
							id = id,
							number = number,
							distance = distance
						}
					)

					if best == nil or distance < best then best = distance end
				end
			end
		end
	end

	local list = {}
	for _, candidate in ipairs(candidates) do
		if candidate.distance <= best + Transport.dockTolerance then tinsert(list, candidate) end
	end

	table.sort(list, function(a, b) return a.id < b.id end)

	return list
end

function Transport.FindPlatformRoutes(kind, number)
	local list = {}
	for id, route in pairs(Transport.GetRoutes()) do
		local d = Transport.decoded[id]
		if d ~= nil and route.kind == kind and d.plat[number] ~= nil then
			tinsert(
				list,
				{
					id = id,
					number = number
				}
			)
		end
	end

	table.sort(list, function(a, b) return a.id < b.id end)

	return list
end

function MapUtils:GetTransportPlatformLines(kind, number)
	return Transport.GetCandidateLines(Transport.FindPlatformRoutes(kind, number))
end

function MapUtils:GetTransportPierLines(instance, u1, u2, kind)
	if instance == nil or u1 == nil or u2 == nil then return {} end

	return Transport.GetCandidateLines(Transport.FindPierRoutes(instance, u1, u2, kind or "ship"))
end

function Transport.GetCandidateLines(candidates)
	local lines = {}
	for _, candidate in ipairs(candidates) do
		local route = Transport.GetRoutes()[candidate.id]
		local vessel = MapUtils:TransName(route.vessel) or route.vessel
		local times = Transport.GetPlatformTimes(candidate.id)
		if times == nil then
			tinsert(lines, format("|cff999999%s|r", format(MapUtils:Trans("LID_VESSELUNKNOWN"), vessel)))
		else
			for _, entry in ipairs(times) do
				if entry.number == candidate.number then tinsert(lines, Transport.GetStatusText(entry, vessel)) end
			end
		end
	end

	return lines
end

function MapUtils:PrintTransports()
	local ids = {}
	for id in pairs(Transport.GetRoutes()) do
		tinsert(ids, id)
	end

	table.sort(ids)
	MapUtils:INFO(format("Transports: %d routes, flavor %s, clock %s, channel %s", #ids, tostring(MapUtils:GetFlavor()), Transport.clockOffset ~= nil and "synced" or "pending", tostring(MapUtils.Comm and MapUtils.Comm.GetChannelNumber() or "none")))
	for _, id in ipairs(ids) do
		local route = Transport.GetRoutes()[id]
		local known = Transport.GetKnown(id)
		if known == nil then
			MapUtils:INFO(format("[%d] %s: unknown", id, route.vessel))
		else
			local instance, wx, wy = Transport.GetPosition(id)
			MapUtils:INFO(format("[%d] %s: %s, %s ago, cycle %.1f/%.1f, pos %s %.0f %.0f", id, route.vessel, tostring(known.s), Transport.FormatAge(Transport.Now() - known.t), Transport.GetCycle(id) or -1, route.rtt, tostring(instance), wx or 0, wy or 0))
		end
	end
end

Transport.loader = CreateFrame("FRAME")
Transport.loader:RegisterEvent("PLAYER_LOGIN")
Transport.loader:SetScript("OnEvent", Transport.Init)
