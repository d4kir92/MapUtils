local _, MapUtils = ...
local Transport = {
	media = "Interface\\AddOns\\MapUtils\\media\\",
	icons = {
		ship = "vessel_ship",
		zeppelin = "vessel_zeppelin",
		tram = "vessel_tram"
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
	worldPins = {},
	minimapPins = {},
	pending = {},
	announce = {},
	lastAnnounce = {},
	lastTriggers = {},
	samples = {},
	sampleCount = 0,
	evalFore = {},
	evalSide = {},
	cands = {},
	received = {},
	queryGap = 600,
	staleQueryGap = 1800,
	maxAge = 30 * 86400,
	selfPriority = 6 * 3600,
	futureTolerance = 5,
	driftAge = 8 * 3600,
	announceGap = 600,
	perMessage = 10,
	maxPerSender = 60,
	iconSize = 22,
	minimapIconSize = 18,
	dockRadius = 150,
	dockTolerance = 15,
	interval = 0.1,
	triggerInterval = 0.5,
	triggerCooldown = 25,
	windowMax = 7.0,
	windowMin = 4.5,
	minSamples = 10,
	maxGap = 2.5,
	maxStepSpeed = 80,
	minNetDist = 45,
	minShipArc = 95,
	minShipSpeed = 17.5,
	safePlayerSpeed = 19.5,
	minExcessDist = 22,
	ambiguityGap = 10,
	ambiguityCap = 22,
	hullLimits = {
		ship = {
			search = 42,
			maxFore = 35,
			maxSide = 28,
			foreSpan = 54,
			sideSpan = 28
		},
		zeppelin = {
			search = 34,
			maxFore = 28,
			maxSide = 24,
			foreSpan = 42,
			sideSpan = 24
		},
		tram = {
			search = 22,
			maxFore = 22,
			maxSide = 16,
			foreSpan = 32,
			sideSpan = 16
		}
	},
	logLimit = 5000
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
		rtt = route.rtt,
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
		inst = {},
		wx = {},
		wy = {},
		segLen = {},
		segSpd = {},
		bounds = {},
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

		local inst, wx, wy = Transport.ToWorld(route, d, i, x, y)
		d.inst[i], d.wx[i], d.wy[i] = inst, wx, wy
		if i > 1 and not d.jump[i] and not d.zoning[i] and inst == d.inst[i - 1] and dt > 0 then
			local px, py = d.wx[i - 1], d.wy[i - 1]
			local segLen = math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2)
			local segSpd = segLen / dt
			d.segLen[i], d.segSpd[i] = segLen, segSpd
			if segSpd >= 6 then
				local b = d.bounds[inst]
				if b == nil then
					d.bounds[inst] = {math.min(wx, px), math.max(wx, px), math.min(wy, py), math.max(wy, py)}
				else
					b[1] = math.min(b[1], wx, px)
					b[2] = math.max(b[2], wx, px)
					b[3] = math.min(b[3], wy, py)
					b[4] = math.max(b[4], wy, py)
				end
			end
		else
			d.segLen[i], d.segSpd[i] = 0, 0
		end
	end

	d.count = #route.points
	d.offset[d.count] = route.rtt

	return d
end

function Transport.Init()
	for id, route in pairs(Transport.GetRoutes()) do
		Transport.decoded[id] = Transport.Decode(route)
	end

	if next(Transport.decoded) == nil then return end
	Transport.CalibrateClock()
	C_Timer.NewTicker(Transport.triggerInterval, MapUtils.Profile("transports CheckTriggers", Transport.CheckTriggers))
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

function Transport.GetBuild()
	local _, build = GetBuildInfo()

	return tostring(build or "")
end

function Transport.GetKnown(id)
	local store = Transport.GetStore()
	local known = store ~= nil and store[id] or nil
	if type(known) ~= "table" or type(known.p) ~= "number" or type(known.t) ~= "number" then return nil end
	if Transport.Now() - known.t > Transport.maxAge then return nil end
	if known.b == nil then known.b = Transport.GetBuild() end

	return known
end

function Transport.IsOutdated(known)
	return known ~= nil and known.b ~= Transport.GetBuild()
end

function Transport.GetWarning(known)
	if known == nil then return nil end
	if Transport.IsOutdated(known) then return MapUtils:Trans("LID_VESSELOUTDATED") end
	if Transport.Now() - known.t > Transport.driftAge then return format(MapUtils:Trans("LID_VESSELDRIFT"), math.floor(Transport.driftAge / 3600)) end

	return nil
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

function Transport.GetPlatformWorld(kind, number)
	Transport.platformWorld = Transport.platformWorld or {}
	local key = kind .. number
	if Transport.platformWorld[key] == nil then
		local instance, pos = nil, nil
		if MapUtils.GetTransportPlatformWorldPos ~= nil then instance, pos = MapUtils:GetTransportPlatformWorldPos(kind, number) end
		Transport.platformWorld[key] = instance ~= nil and {instance, pos.y, pos.x} or false
	end

	return Transport.platformWorld[key] or nil
end

function Transport.GetWorldMapPosition(id)
	local instance, wx, wy, angle, zoning = Transport.GetPosition(id)
	local route, d = Transport.GetRoutes()[id], Transport.decoded[id]
	if instance == nil or route.kind ~= "tram" or d.plat[1] == nil or d.plat[2] == nil then return instance, wx, wy, angle, zoning end
	local from, to = Transport.GetPlatformWorld(route.kind, 1), Transport.GetPlatformWorld(route.kind, 2)
	local x1, x2 = d.x[d.plat[1]], d.x[d.plat[2]]
	if from == nil or to == nil or from[1] ~= to[1] or x1 == x2 then return nil end
	local f = math.min(1, math.max(0, (wx - x1) / (x2 - x1)))

	return from[1], from[2] + (to[2] - from[2]) * f, from[3] + (to[3] - from[3]) * f, 0, false
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

	local warning = Transport.GetWarning(known)
	if warning ~= nil then tooltip:AddLine(warning, 1, 0.6, 0.2, true) end
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
		pin.outline = {}
		for i = 1, 8 do
			local texture = pin:CreateTexture(nil, "OVERLAY", nil, -1)
			texture:SetVertexColor(0, 0, 0, 1)
			if texture.SetSnapToPixelGrid ~= nil then texture:SetSnapToPixelGrid(false) end
			if texture.SetTexelSnappingBias ~= nil then texture:SetTexelSnappingBias(0) end
			pin.outline[i] = texture
		end

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

	local rotation = route.kind == "tram" and 0 or angle
	pin.texture:SetRotation(rotation)
	local _, physicalHeight = GetPhysicalScreenSize()
	local effective = pin:GetEffectiveScale()
	local step = (physicalHeight ~= nil and physicalHeight > 0 and effective > 0) and 768 / physicalHeight / effective or 1
	for i, texture in ipairs(pin.outline) do
		local outlineAngle = (i - 1) * math.pi / 4
		texture:SetTexture(icon)
		texture:SetRotation(rotation)
		texture:ClearAllPoints()
		texture:SetPoint("CENTER", pin, "CENTER", math.floor(math.cos(outlineAngle) + 0.5) * step, math.floor(math.sin(outlineAngle) + 0.5) * step)
		texture:SetSize(size, size)
	end

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
	if worldMap then return MapUtils:IsPinShownOnMap("VESSELWORLDMAPPINS", true) end

	return MapUtils:GetConfig("VESSELMINIMAPPINS", true) == true
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

	for _, extra in ipairs(Transport.GetOtherInstanceZones(space)) do
		local l, r, t, b = C_Map.GetMapRectOnMap(extra.mapID, space)
		if l ~= nil and r > l and b > t then
			tinsert(
				list,
				{
					rect = extra.rect,
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

function Transport.GetOtherInstanceZones(space)
	Transport.otherZones = Transport.otherZones or {}
	if Transport.otherZones[space] ~= nil then return Transport.otherZones[space] end
	local list, instances = {}, {}
	for _, continentID in ipairs(MapUtils:GetZoneDetailContinents(space)) do
		local rect = MapUtils.GetMapRect(continentID)
		if rect ~= nil then instances[rect.continentID] = true end
	end

	for _, continentID in ipairs(MapUtils:GetZoneDetailContinents(space)) do
		for _, child in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false) or {}) do
			local rect = MapUtils.GetMapRect(child.mapID)
			if rect ~= nil and rect.continentID ~= nil and not instances[rect.continentID] then
				tinsert(
					list,
					{
						mapID = child.mapID,
						rect = rect
					}
				)
			end
		end
	end

	Transport.otherZones[space] = list

	return list
end

function Transport.GetProjections(mapID)
	local list = Transport.GetOneMapProjections(mapID)
	if list ~= nil and #list > 0 then return list end
	Transport.projectionCache = Transport.projectionCache or {}
	if Transport.projectionCache[mapID] ~= nil then return Transport.projectionCache[mapID] end
	local rect = MapUtils.GetMapRect(mapID)
	if rect == nil then return nil end
	local projections = {
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

	for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone, false) or {}) do
		local childRect = MapUtils.GetMapRect(child.mapID)
		if childRect ~= nil and childRect.continentID ~= nil and childRect.continentID ~= rect.continentID then
			local l, r, t, b = C_Map.GetMapRectOnMap(child.mapID, mapID)
			if l ~= nil and r > l and b > t then
				tinsert(
					projections,
					{
						rect = childRect,
						ox = l,
						oy = t,
						sx = r - l,
						sy = b - t
					}
				)
			end
		end
	end

	Transport.projectionCache[mapID] = projections

	return projections
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
	local canvas = WorldMapFrame ~= nil and WorldMapFrame:IsShown() and Transport.GetCanvas() or nil
	local scale = canvas ~= nil and canvas:GetScale() or nil
	local projections = scale ~= nil and scale > 0 and Transport.Enabled(true) and MapUtils.GetMapRect ~= nil and Transport.GetProjections(WorldMapFrame:GetMapID()) or nil
	if projections ~= nil then
		local w, h = canvas:GetWidth(), canvas:GetHeight()
		if w ~= nil and h ~= nil and w > 0 and h > 0 then
			local size = Transport.iconSize / scale * MapUtils:GetPinSizeFactor("VESSELWORLDMAPPINS")
			for id, route in pairs(Transport.GetRoutes()) do
				local instance, wx, wy, angle, zoning = Transport.GetWorldMapPosition(id)
				local mx, my = nil, nil
				if instance ~= nil then mx, my = Transport.Project(projections, instance, wx, wy) end
				if mx ~= nil then
					shown = shown + 1
					local pin = Transport.AcquirePin(Transport.worldPins, shown, canvas)
					if MapUtils.SetCanvasPinScale ~= nil then MapUtils:SetCanvasPinScale(pin, scale) end
					Transport.ShowPin(pin, id, route, size, angle, zoning)
					pin:SetFrameLevel(canvas:GetFrameLevel() + 2100)
					pin:SetPoint("CENTER", canvas, "TOPLEFT", w * mx, -h * my)
				end
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
		MapUtils.CanvasPinLists = MapUtils.CanvasPinLists or {}
		tinsert(MapUtils.CanvasPinLists, Transport.worldPins)
		MapUtils.CanvasPinUpdaters = MapUtils.CanvasPinUpdaters or {}
		tinsert(MapUtils.CanvasPinUpdaters, Transport.UpdateWorld)
		MapUtils.UpdateWorldTransportsNow = Transport.UpdateWorld
		Transport.CreateUpdater(WorldMapFrame, MapUtils.Profile("transports UpdateWorld", Transport.UpdateWorld))
		WorldMapFrame:HookScript(
			"OnShow",
			function()
				Transport.Query(false)
				Transport.UpdateWorld()
			end
		)
		WorldMapFrame:HookScript(
			"OnHide",
			function()
				Transport.HideFrom(Transport.worldPins, 1)
			end
		)
	end

	if Minimap ~= nil then Transport.CreateUpdater(Minimap, MapUtils.Profile("transports UpdateMinimap", Transport.UpdateMinimap)) end
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

function Transport.ClearSamples()
	Transport.sampleCount = 0
end

function Transport.PushSample(now, wx, wy, instance, speed)
	local samples, count = Transport.samples, Transport.sampleCount
	local drop = 0
	while drop < count and now - samples[drop + 1].t > Transport.windowMax do
		drop = drop + 1
	end

	if drop > 0 then
		for i = 1, count - drop do
			local dst, src = samples[i], samples[i + drop]
			dst.t, dst.x, dst.y, dst.inst, dst.spd = src.t, src.x, src.y, src.inst, src.spd
		end

		count = count - drop
	end

	count = count + 1
	local slot = samples[count]
	if slot == nil then
		slot = {}
		samples[count] = slot
	end

	slot.t, slot.x, slot.y, slot.inst, slot.spd = now, wx, wy, instance, speed
	Transport.sampleCount = count
end

function Transport.SampleRoute(d, cycle)
	local c = cycle % d.rtt
	local lo, hi = 1, d.count
	while lo < hi do
		local mid = math.floor((lo + hi) * 0.5)
		if d.offset[mid] > c then
			hi = mid
		else
			lo = mid + 1
		end
	end

	if lo <= 1 or d.jump[lo] or d.zoning[lo] or d.inst[lo] ~= d.inst[lo - 1] or d.dt[lo] <= 0 then return nil end
	local dt = d.dt[lo]
	local f = math.min(1, math.max(0, (c - d.offset[lo - 1]) / dt))
	local ax, ay = d.wx[lo - 1], d.wy[lo - 1]
	local dx, dy = d.wx[lo] - ax, d.wy[lo] - ay

	return d.inst[lo], ax + dx * f, ay + dy * f, dx / dt, dy / dt, d.segSpd[lo], d.dir[lo - 1] + d.ddir[lo] * f
end

function Transport.EvaluateCandidate(route, d, phase0)
	local lim = Transport.hullLimits[route.kind] or Transport.hullLimits.ship
	local samples, n = Transport.samples, Transport.sampleCount
	local inst = samples[n].inst
	local phase = phase0
	for _ = 1, 2 do
		local num, den = 0, 0
		for k = 1, n do
			local s = samples[k]
			local pInst, px, py, vx, vy = Transport.SampleRoute(d, s.t - phase)
			if pInst ~= inst then return nil end
			num = num + (s.x - px) * vx + (s.y - py) * vy
			den = den + vx * vx + vy * vy
		end

		if den < 10 then return nil end
		local dp = -num / den
		if dp > 2.5 then
			dp = 2.5
		elseif dp < -2.5 then
			dp = -2.5
		end

		phase = phase + dp
	end

	local fores, sides = Transport.evalFore, Transport.evalSide
	local shipArc, playerAlong, excessDist, speedSamples = 0, 0, 0, 0
	local minFore, maxFore = math.huge, -math.huge
	local minSide, maxSide = math.huge, -math.huge
	local sumFore, sumSide = 0, 0
	local prevPx, prevPy, prevS = nil, nil, nil
	for k = 1, n do
		local s = samples[k]
		local pInst, px, py, vx, vy, spd, dir = Transport.SampleRoute(d, s.t - phase)
		if pInst ~= inst then return nil end
		local rx, ry = s.x - px, s.y - py
		local ux, uy
		if spd >= 4 then
			ux, uy = vx / spd, vy / spd
		else
			ux, uy = math.sin(dir), math.cos(dir)
		end

		local fore = rx * ux + ry * uy
		local side = rx * uy - ry * ux
		if math.abs(fore) > lim.maxFore or math.abs(side) > lim.maxSide then return nil end
		if fore < minFore then minFore = fore end
		if fore > maxFore then maxFore = fore end
		if side < minSide then minSide = side end
		if side > maxSide then maxSide = side end
		sumFore = sumFore + fore
		sumSide = sumSide + side
		fores[k] = fore
		sides[k] = side
		if prevS ~= nil then
			local dsx, dsy = px - prevPx, py - prevPy
			local seg = math.sqrt(dsx * dsx + dsy * dsy)
			shipArc = shipArc + seg
			if seg > 0.1 then playerAlong = playerAlong + ((s.x - prevS.x) * dsx + (s.y - prevS.y) * dsy) / seg end
			local dt = s.t - prevS.t
			if s.spd ~= nil and prevS.spd ~= nil and dt > 0 then
				local wStep = math.sqrt((s.x - prevS.x) ^ 2 + (s.y - prevS.y) ^ 2)
				excessDist = excessDist + wStep - math.max(s.spd, prevS.spd) * dt
				speedSamples = speedSamples + 1
			end
		end

		prevPx, prevPy, prevS = px, py, s
	end

	local span = samples[n].t - samples[1].t
	if span <= 0 then return nil end
	local shipAvgSpd = shipArc / span
	local playerAvgAlong = playerAlong / span
	local foreSpan = maxFore - minFore
	local sideSpan = maxSide - minSide
	if shipArc < Transport.minShipArc or shipAvgSpd < Transport.minShipSpeed then return nil end
	if foreSpan > lim.foreSpan or sideSpan > lim.sideSpan then return nil end
	if playerAvgAlong < Transport.safePlayerSpeed and (speedSamples < n - 2 or excessDist < Transport.minExcessDist) then return nil end

	local meanF, meanS = sumFore / n, sumSide / n
	local sq = 0
	for k = 1, n do
		local df, ds = fores[k] - meanF, sides[k] - meanS
		sq = sq + df * df + ds * ds
	end

	local score = math.sqrt(sq / n) + 0.35 * math.abs(meanS)

	return score, (samples[n].t - phase) % d.rtt
end

function Transport.MatchRoute(route, d)
	local last = Transport.samples[Transport.sampleCount]
	local b = d.bounds[last.inst]
	if b == nil then return nil end
	local lim = Transport.hullLimits[route.kind] or Transport.hullLimits.ship
	local lx, ly = last.x, last.y
	if lx < b[1] - lim.search or lx > b[2] + lim.search or ly < b[3] - lim.search or ly > b[4] + lim.search then return nil end
	local cands, candCount = Transport.cands, 0
	local inRun, runBestDist, runBestCycle = false, math.huge, 0
	for i = 2, d.count do
		if d.segLen[i] <= 0 or d.segSpd[i] < 6 or d.inst[i] ~= last.inst then
			if inRun then
				candCount = candCount + 1
				cands[candCount] = runBestCycle
				inRun, runBestDist = false, math.huge
			end
		else
			local ax, ay = d.wx[i - 1], d.wy[i - 1]
			local vx, vy = d.wx[i] - ax, d.wy[i] - ay
			local len2 = vx * vx + vy * vy
			local u = ((lx - ax) * vx + (ly - ay) * vy) / len2
			if u < 0 then
				u = 0
			elseif u > 1 then
				u = 1
			end

			local dist = math.sqrt((lx - (ax + vx * u)) ^ 2 + (ly - (ay + vy * u)) ^ 2)
			if dist <= lim.search then
				if not inRun or dist < runBestDist then
					inRun = true
					runBestDist = dist
					runBestCycle = d.offset[i - 1] + u * d.dt[i]
				end
			elseif inRun then
				candCount = candCount + 1
				cands[candCount] = runBestCycle
				inRun, runBestDist = false, math.huge
			end
		end
	end

	if inRun then
		candCount = candCount + 1
		cands[candCount] = runBestCycle
	end

	local bestScore, bestCycle = nil, nil
	for i = 1, candCount do
		local score, cycle = Transport.EvaluateCandidate(route, d, last.t - cands[i])
		if score ~= nil and (bestScore == nil or score < bestScore) then bestScore, bestCycle = score, cycle end
	end

	return bestScore, bestCycle
end

function Transport.GetLog()
	if type(MAUTTAB) ~= "table" or type(MAUTTAB.TRANSPORTLOG) ~= "table" or not MAUTTAB.TRANSPORTLOG.on then return nil end
	local flavor = MapUtils:GetFlavor() or "unknown"
	if type(MAUTTAB.TRANSPORTLOG[flavor]) ~= "table" then MAUTTAB.TRANSPORTLOG[flavor] = {} end

	return MAUTTAB.TRANSPORTLOG[flavor]
end

function Transport.NearestTrigger(instance, wx, wy)
	local bestID, bestIndex, bestDistance = 0, 0, math.huge
	for id, route in pairs(Transport.GetRoutes()) do
		local d = Transport.decoded[id]
		if d ~= nil then
			for _, index in ipairs(d.trig) do
				local ti, tx, ty = Transport.ToWorld(route, d, index, d.x[index], d.y[index])
				local distance = ti == instance and math.sqrt((wx - tx) ^ 2 + (wy - ty) ^ 2) or math.huge
				if distance < bestDistance then bestID, bestIndex, bestDistance = id, index, distance end
			end
		end
	end

	return bestID, bestIndex, bestDistance
end

function Transport.Record()
	local log = Transport.GetLog()
	if log == nil then return end
	local u1, u2, _, instance = UnitPosition("player")
	if u1 == nil or Transport.IsSecret(u1, u2, instance) then return end
	if UnitOnTaxi("player") then return end
	local id, index, distance = Transport.NearestTrigger(instance, u2, u1)
	if #log >= Transport.logLimit then table.remove(log, 1) end
	tinsert(log, format("%d:%.1f:%.1f:%d:%s:%d:%d:%.0f:%s", GetServerTime(), u2, u1, instance, tostring(Transport.GetCurrentZone() or 0), id, index, math.min(distance, 99999), IsSwimming() and "s" or "-"))
end

function MapUtils:ToggleTransportLog()
	if type(MAUTTAB) ~= "table" then return end
	if type(MAUTTAB.TRANSPORTLOG) ~= "table" then MAUTTAB.TRANSPORTLOG = {} end
	MAUTTAB.TRANSPORTLOG.on = not MAUTTAB.TRANSPORTLOG.on
	local log = MAUTTAB.TRANSPORTLOG[MapUtils:GetFlavor() or "unknown"]
	MapUtils:INFO(format("Transport log %s (%d entries, saved on /reload or logout)", MAUTTAB.TRANSPORTLOG.on and "ON" or "OFF", type(log) == "table" and #log or 0))
end

function Transport.CheckTriggers()
	Transport.Record()
	local _, instanceType = GetInstanceInfo()
	if instanceType == "party" or instanceType == "raid" then
		Transport.ClearSamples()

		return
	end

	local u1, u2, _, instance = UnitPosition("player")
	if u1 == nil or Transport.IsSecret(u1, u2, instance) then
		Transport.ClearSamples()

		return
	end

	if IsSwimming() or UnitOnTaxi("player") or (IsFlying ~= nil and IsFlying()) then
		Transport.ClearSamples()

		return
	end

	local speed = GetUnitSpeed ~= nil and GetUnitSpeed("player") or nil
	if speed ~= nil and (Transport.IsSecret(speed) or type(speed) ~= "number") then speed = nil end
	local now, wx, wy = GetTime(), u2, u1
	if Transport.sampleCount > 0 then
		local prev = Transport.samples[Transport.sampleCount]
		local dt = now - prev.t
		if prev.inst ~= instance or dt <= 0 or dt > Transport.maxGap then
			Transport.ClearSamples()
		else
			local step = math.sqrt((wx - prev.x) ^ 2 + (wy - prev.y) ^ 2)
			if step > Transport.maxStepSpeed * dt + 10 then Transport.ClearSamples() end
		end
	end

	Transport.PushSample(now, wx, wy, instance, speed)
	local count = Transport.sampleCount
	if count < Transport.minSamples then return end
	local first, last = Transport.samples[1], Transport.samples[count]
	if last.t - first.t < Transport.windowMin then return end
	local netDist = math.sqrt((last.x - first.x) ^ 2 + (last.y - first.y) ^ 2)
	if netDist < Transport.minNetDist then return end
	local bestID, bestScore, bestCycle, secondScore = nil, nil, nil, nil
	for id, route in pairs(Transport.GetRoutes()) do
		local d = Transport.decoded[id]
		if d ~= nil then
			local score, cycle = Transport.MatchRoute(route, d)
			if score ~= nil then
				if bestScore == nil or score < bestScore then
					secondScore = bestScore
					bestID, bestScore, bestCycle = id, score, cycle
				elseif secondScore == nil or score < secondScore then
					secondScore = score
				end
			end
		end
	end

	if bestID == nil then return end
	if secondScore ~= nil and secondScore < bestScore + Transport.ambiguityGap and secondScore < Transport.ambiguityCap then return end
	local prev = Transport.lastTriggers[bestID]
	if prev ~= nil and now - prev.t < Transport.triggerCooldown and (now - prev.t < 3 or bestScore >= prev.score * 0.5 or prev.score - bestScore < 2) then return end

	Transport.Observe(bestID, bestCycle)
	Transport.lastTriggers[bestID] = {
		t = now,
		score = bestScore
	}
end

function Transport.Observe(id, cycle)
	local route, store = Transport.GetRoutes()[id], Transport.GetStore()
	if route == nil or store == nil then return end
	local now = Transport.Now()
	store[id] = {
		p = (now - cycle) % route.rtt,
		t = now,
		s = "self",
		b = Transport.GetBuild()
	}

	Transport.QueueAnnounce(id)
end

function Transport.SyncEnabled()
	return MapUtils.Comm ~= nil and MapUtils.Comm.IsEnabled()
end

function Transport.Encode(id)
	local known = Transport.GetKnown(id)
	if known == nil or known.s ~= "self" or Transport.IsOutdated(known) then return nil end

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

function Transport.IsStale(known)
	return Transport.IsOutdated(known) or Transport.Now() - known.t > Transport.driftAge
end

function Transport.GetWanted()
	local missing, stale = {}, {}
	for id in pairs(Transport.GetRoutes()) do
		local known = Transport.GetKnown(id)
		if known == nil then
			tinsert(missing, id)
		elseif Transport.IsStale(known) then
			tinsert(stale, id)
		end
	end

	table.sort(missing)
	table.sort(stale)

	return missing, stale
end

function Transport.Query(force)
	if not Transport.SyncEnabled() then return end
	local now = GetTime()
	if not force and Transport.lastQuery ~= nil and now - Transport.lastQuery < Transport.queryGap then return end
	local missing, stale = Transport.GetWanted()
	if #stale > 0 and not force and Transport.lastStaleQuery ~= nil and now - Transport.lastStaleQuery < Transport.staleQueryGap then wipe(stale) end
	if #missing == 0 and #stale == 0 then return end
	Transport.lastQuery = now
	local body = table.concat(missing, ",")
	if #stale > 0 then
		Transport.lastStaleQuery = now
		body = body .. "|" .. table.concat(stale, ",")
	end

	MapUtils.Comm.Send("T", "?" .. Transport.GetCode() .. body, "ALL")
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
	local missingText, staleText = body:match("^([^|]*)|?(.*)$")
	for _, part in ipairs({{missingText or "", false}, {staleText or "", true}}) do
		for idText in part[1]:gmatch("%d+") do
			local id = tonumber(idText)
			local known = id ~= nil and Transport.GetKnown(id) or nil
			count = count + 1
			if count > 32 then break end
			if known ~= nil and known.s == "self" and not Transport.IsOutdated(known) and (not part[2] or not Transport.IsStale(known)) then
				pending.ids[id] = true
				if Transport.Now() - known.t < 3600 then fresh = true end
			end
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
			if phase >= 0 and phase < route.rtt and observed <= now + Transport.futureTolerance and now - observed < Transport.maxAge then
				Transport.Suppress(id, observed)
				local known = Transport.GetKnown(id)
				local ownFresh = known ~= nil and known.s == "self" and not Transport.IsOutdated(known) and observed - known.t < Transport.selfPriority
				if not ownFresh and (known == nil or observed > known.t + 1) then
					store[id] = {
						p = phase,
						t = observed,
						s = sender,
						b = Transport.GetBuild()
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
	local warnings, warned = {}, {}
	for _, candidate in ipairs(candidates) do
		local route = Transport.GetRoutes()[candidate.id]
		local vessel = MapUtils:TransName(route.vessel) or route.vessel
		local times = Transport.GetPlatformTimes(candidate.id)
		local warning = times ~= nil and Transport.GetWarning(Transport.GetKnown(candidate.id)) or nil
		if warning ~= nil and not warned[warning] then
			warned[warning] = true
			tinsert(warnings, warning)
		end
		if times == nil then
			tinsert(lines, format("|cff999999%s|r", format(MapUtils:Trans("LID_VESSELUNKNOWN"), vessel)))
		else
			for _, entry in ipairs(times) do
				if entry.number == candidate.number then tinsert(lines, Transport.GetStatusText(entry, vessel)) end
			end
		end
	end

	for _, warning in ipairs(warnings) do
		tinsert(lines, format("|cffff9933%s|r", warning))
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
