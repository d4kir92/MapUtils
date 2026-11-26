local _, D4 = ...
local VERSION = 1
local TAXI_PIN = Enum and Enum.SuperTrackingMapPinType and Enum.SuperTrackingMapPinType.TaxiNode or 2
local TRACK = Enum and Enum.SuperTrackingType or {}
local TRACK_QUEST = TRACK.Quest or 0
local TRACK_WAYPOINT = TRACK.UserWaypoint or 1
local TRACK_CONTENT = TRACK.Content or 4
local TRACK_PIN = TRACK.MapPin or 6
local TRACK_VIGNETTE = TRACK.Vignette or 7
local ARROW_SIZE = 24
local POS_MAX_AGE = 3.0
local CFG = {
	["activeCount"] = 5,
	["minFix"] = 4,
	["stepActive"] = 0.03,
	["stepSleep"] = 0.25,
	["sleepPing"] = 2.0,
	["sleepDrift"] = 2.5,
	["sleepResidual"] = 2.5,
	["settleBase"] = 0.26,
	["settleMax"] = 0.85,
	["movingGap"] = 0.055,
	["idleGap"] = 0.11,
	["timeout"] = 0.4,
	["pinCheck"] = 0.08,
	["maxAge"] = 1.6,
	["rateSpan"] = 2.0,
	["gateMin"] = 8,
	["gateMax"] = 70,
	["heightSlack"] = 50,
	["acquireSlack"] = 0.6,
	["acquireMaxRes"] = 25,
	["residualGood"] = 2.0,
	["residualLimit"] = 14,
	["rejectsLose"] = 4,
	["missesLose"] = 3,
	["sameDist"] = 2.5,
	["sameDrift"] = 8,
	["sameWindow"] = 5,
	["confirmWait"] = 1.6,
	["maxSpeed"] = 45,
	["minSpeed"] = 0.4,
	["headingSpeed"] = 1.2,
	["extrapolate"] = 0.25,
	["ageWeight"] = 3,
	["zBufSize"] = 5,
}
local reg = _G["D4_InstancePos"]
if reg == nil then
	reg = {
		["version"] = 0,
		["data"] = nil,
		["leases"] = {},
		["driver"] = nil,
		["motionFrame"] = nil,
		["pos"] = {
			["active"] = false,
			["instID"] = nil,
			["phase"] = 0,
			["activeCount"] = 0,
			["slots"] = {},
			["pool"] = {},
			["poolCount"] = 0,
			["ours"] = {},
			["bad"] = {},
			["work"] = {},
			["zBuf"] = {0, 0, 0, 0, 0},
			["zSorted"] = {0, 0, 0, 0, 0},
			["zCount"] = 0,
			["zHead"] = 0,
			["curIdx"] = 1,
			["prevSlot"] = nil,
			["pending"] = false,
			["switchAt"] = 0,
			["switchedAt"] = 0,
			["lastSwitch"] = 0,
			["pinChecked"] = false,
			["pinRefused"] = false,
			["outranked"] = false,
			["settle"] = CFG.settleBase,
			["acqStart"] = 0,
			["acqFrom"] = 0,
			["acquiredAt"] = 0,
			["uncert"] = 0,
			["interval"] = 0,
			["lastDist"] = 0,
			["lastTime"] = 0,
			["lastAnchorID"] = 0,
			["misses"] = 0,
			["rejects"] = 0,
			["lastOk"] = 0,
			["moving"] = false,
			["motionSince"] = 0,
			["settleLeft"] = 0,
			["nextSleepPing"] = 0,
			["blockedUntil"] = 0,
			["stopAt"] = 0,
			["elapsed"] = 0,
			["fix"] = {
				["valid"] = false,
				["confirmed"] = false,
				["x"] = 0,
				["y"] = 0,
				["z"] = 0,
				["zMed"] = 0,
				["vx"] = 0,
				["vy"] = 0,
				["heading"] = nil,
				["time"] = 0,
				["residual"] = 999,
				["count"] = 0,
			},
			["saved"] = {
				["has"] = false,
				["quest"] = 0,
				["waypoint"] = false,
				["contentType"] = nil,
				["contentID"] = nil,
				["vignette"] = nil,
				["pinType"] = nil,
				["pinID"] = nil,
				["priority"] = nil,
			},
		},
	}
	_G["D4_InstancePos"] = reg
end

local POS = reg.pos

local function IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v) == true
end

local function IsPlayerMoving()
	if GetUnitSpeed == nil then return false end
	local s = GetUnitSpeed("player")
	return not IsSecret(s) and type(s) == "number" and s > 0
end

local function GetCurrentInstanceID()
	if IsInInstance == nil or GetInstanceInfo == nil then return nil end
	local inInst = IsInInstance()
	if not inInst then return nil end
	local instID = select(8, GetInstanceInfo())
	if IsSecret(instID) or type(instID) ~= "number" or instID <= 0 then return nil end
	return instID
end

local function ExtractArtKey(artKey)
	if artKey == nil then return nil end
	local s = tostring(artKey)
	if strfind(s, "[\\/]") ~= nil then
		s = strmatch(s, "([^\\/]+)$") or s
	end
	s = gsub(s, "%.[^%.]+$", "")
	return s
end

local function Dist3(slot, x, y, z)
	local dx = x - slot.x
	local dy = y - slot.y
	local dz = z - slot.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function SolveSym3(s11, s12, s13, s22, s23, s33, b1, b2, b3)
	local c11 = s22 * s33 - s23 * s23
	local c12 = s13 * s23 - s12 * s33
	local c13 = s12 * s23 - s13 * s22
	local det = s11 * c11 + s12 * c12 + s13 * c13
	if det == 0 or det ~= det then return nil end
	local inv = 1 / det
	local c22 = s11 * s33 - s13 * s13
	local c23 = s12 * s13 - s11 * s23
	local c33 = s11 * s22 - s12 * s12
	local x = (c11 * b1 + c12 * b2 + c13 * b3) * inv
	local y = (c12 * b1 + c22 * b2 + c23 * b3) * inv
	local z = (c13 * b1 + c23 * b2 + c33 * b3) * inv
	if x ~= x or y ~= y or z ~= z then return nil end
	return x, y, z
end

local function EstimatePos(now)
	local f = POS.fix
	local dt = now - f.time
	if dt < 0 then
		dt = 0
	elseif dt > CFG.extrapolate then
		dt = CFG.extrapolate
	end
	return f.x + f.vx * dt, f.y + f.vy * dt, f.z
end

local function ResetMotion(now)
	POS.fix.vx = 0
	POS.fix.vy = 0
	POS.motionSince = now
end

local function RoundTime()
	return POS.interval * POS.activeCount
end

local function PushHeight(z)
	local head = (POS.zHead % CFG.zBufSize) + 1
	POS.zHead = head
	POS.zBuf[head] = z
	if POS.zCount < CFG.zBufSize then POS.zCount = POS.zCount + 1 end
	local n = POS.zCount
	local s = POS.zSorted
	for i = 1, n do
		local v = POS.zBuf[i]
		local j = i - 1
		while j >= 1 and s[j] > v do
			s[j + 1] = s[j]
			j = j - 1
		end
		s[j + 1] = v
	end
	return s[math.ceil(n * 0.5)]
end

local function GatherSlots(now, maxAge, since)
	local w = POS.work
	local n = 0
	local slots = POS.slots
	for i = 1, POS.activeCount do
		local s = slots[i]
		if not s.disabled and s.time > 0 and (now - s.time) <= maxAge and s.time >= since then
			n = n + 1
			w[n] = s
		end
	end
	return n
end

local function PrepareWork(n, now, adjust)
	local w = POS.work
	local f = POS.fix
	local hasVel = adjust and f.valid and (f.vx ~= 0 or f.vy ~= 0)
	for i = 1, n do
		local s = w[i]
		local d = s.dist
		local age = now - s.time
		if age < 0 then age = 0 end
		if hasVel then
			local r = Dist3(s, f.x, f.y, f.z)
			if r > 0 then
				d = d + ((f.x - s.x) * f.vx + (f.y - s.y) * f.vy) / r * age
			end
		end
		s.useDist = d
		s.weight = adjust and (1 / (1 + CFG.ageWeight * age)) or 1
	end
end

local function SolveLinear3(n)
	local w = POS.work
	local s0 = w[1]
	local base = s0.x * s0.x + s0.y * s0.y + s0.z * s0.z - s0.useDist * s0.useDist
	local s11, s12, s13, s22, s23, s33 = 0, 0, 0, 0, 0, 0
	local b1, b2, b3 = 0, 0, 0
	for i = 2, n do
		local s = w[i]
		local ax = 2 * (s.x - s0.x)
		local ay = 2 * (s.y - s0.y)
		local az = 2 * (s.z - s0.z)
		local rhs = s.x * s.x + s.y * s.y + s.z * s.z - s.useDist * s.useDist - base
		s11 = s11 + ax * ax
		s12 = s12 + ax * ay
		s13 = s13 + ax * az
		s22 = s22 + ay * ay
		s23 = s23 + ay * az
		s33 = s33 + az * az
		b1 = b1 + ax * rhs
		b2 = b2 + ay * rhs
		b3 = b3 + az * rhs
	end
	return SolveSym3(s11, s12, s13, s22, s23, s33, b1, b2, b3)
end

local function CalcResidual(x, y, z, n)
	local w = POS.work
	local sum = 0
	local wsum = 0
	for i = 1, n do
		local s = w[i]
		local err = Dist3(s, x, y, z) - s.useDist
		sum = sum + s.weight * err * err
		wsum = wsum + s.weight
	end
	if wsum <= 0 then return 999 end
	return math.sqrt(sum / wsum)
end

local function RefineGN(x, y, z, n)
	local w = POS.work
	for _ = 1, 3 do
		local s11, s12, s13, s22, s23, s33 = 0, 0, 0, 0, 0, 0
		local b1, b2, b3 = 0, 0, 0
		for i = 1, n do
			local s = w[i]
			local dx = x - s.x
			local dy = y - s.y
			local dz = z - s.z
			local r = math.sqrt(dx * dx + dy * dy + dz * dz)
			if r > 0 then
				local wt = s.weight
				local ux = dx / r
				local uy = dy / r
				local uz = dz / r
				local err = r - s.useDist
				s11 = s11 + wt * ux * ux
				s12 = s12 + wt * ux * uy
				s13 = s13 + wt * ux * uz
				s22 = s22 + wt * uy * uy
				s23 = s23 + wt * uy * uz
				s33 = s33 + wt * uz * uz
				b1 = b1 - wt * ux * err
				b2 = b2 - wt * uy * err
				b3 = b3 - wt * uz * err
			end
		end
		local sx, sy, sz = SolveSym3(s11, s12, s13, s22, s23, s33, b1, b2, b3)
		if sx == nil then break end
		x = x + sx
		y = y + sy
		z = z + sz
		if (sx * sx + sy * sy + sz * sz) < 1e-4 then break end
	end
	return x, y, z, CalcResidual(x, y, z, n)
end

local function UpdateVelocity(now)
	local f = POS.fix
	if not f.valid or not POS.moving then return end
	local maxAge = math.max(CFG.maxAge, 1.3 * RoundTime())
	local maxSpan = math.max(CFG.rateSpan, 1.5 * RoundTime())
	local s11, s12, s22, t1, t2 = 0, 0, 0, 0, 0
	local used = 0
	local slots = POS.slots
	for i = 1, POS.activeCount do
		local s = slots[i]
		local pt = s.prevTime
		if not s.disabled and s.time > 0 and pt > 0 and pt >= POS.motionSince and (now - s.time) <= maxAge and s.time > pt and (s.time - pt) <= maxSpan then
			local r = Dist3(s, f.x, f.y, f.z)
			if r > 0 then
				local ux = (f.x - s.x) / r
				local uy = (f.y - s.y) / r
				local rate = (s.dist - s.prevDist) / (s.time - pt)
				s11 = s11 + ux * ux
				s12 = s12 + ux * uy
				s22 = s22 + uy * uy
				t1 = t1 + ux * rate
				t2 = t2 + uy * rate
				used = used + 1
			end
		end
	end
	local det = s11 * s22 - s12 * s12
	if used < 3 or det < 1e-6 then return end
	local vx = (t1 * s22 - t2 * s12) / det
	local vy = (s11 * t2 - s12 * t1) / det
	local speed = math.sqrt(vx * vx + vy * vy)
	if speed > CFG.maxSpeed or speed < CFG.minSpeed then
		f.vx = 0
		f.vy = 0
		return
	end
	f.vx = vx
	f.vy = vy
	if speed >= CFG.headingSpeed then f.heading = math.atan2(vy, vx) end
end

local function AcceptFix(x, y, z, residual, count, now)
	local f = POS.fix
	f.valid = true
	f.x = x
	f.y = y
	f.z = z
	f.zMed = PushHeight(z)
	f.time = now
	f.residual = residual
	f.count = count
	POS.rejects = 0
	if count >= 5 and residual < CFG.residualGood then
		POS.uncert = POS.uncert > 1 and POS.uncert * 0.5 or 0
		f.confirmed = true
	elseif (now - POS.acquiredAt) >= CFG.confirmWait and residual < CFG.residualLimit then
		f.confirmed = true
	end
end

local function Solve(now)
	if POS.phase == 1 then
		local n = GatherSlots(now, CFG.minFix * POS.settle + CFG.acquireSlack, POS.acqStart)
		if n < CFG.minFix then return end
		PrepareWork(n, now, false)
		local x, y, z = SolveLinear3(n)
		if x == nil then return end
		local res
		x, y, z, res = RefineGN(x, y, z, n)
		if res > CFG.acquireMaxRes then return end
		POS.zCount = 0
		POS.zHead = 0
		ResetMotion(now)
		POS.phase = 2
		POS.acquiredAt = now
		POS.uncert = 30
		POS.fix.confirmed = false
		POS.settleLeft = POS.moving and 0 or POS.activeCount
		AcceptFix(x, y, z, res, n, now)
		return
	end

	local n = GatherSlots(now, math.max(CFG.maxAge, 1.3 * RoundTime()), 0)
	if n < CFG.minFix then return end
	UpdateVelocity(now)
	PrepareWork(n, now, true)
	local ex, ey, ez = EstimatePos(now)
	local x, y, z, res = RefineGN(ex, ey, ez, n)
	if res <= CFG.residualLimit + POS.uncert * 0.5 then
		AcceptFix(x, y, z, res, n, now)
		if not POS.moving then
			if POS.settleLeft > 0 then POS.settleLeft = POS.settleLeft - 1 end
			if POS.settleLeft <= 0 and POS.fix.confirmed and res <= CFG.sleepResidual then
				POS.phase = 3
				POS.fix.vx = 0
				POS.fix.vy = 0
				POS.pending = false
				POS.nextSleepPing = now + CFG.sleepPing
			end
		end
	else
		POS.rejects = POS.rejects + 1
	end
end

local function InitSlot(slot, id, node)
	slot.id = id
	slot.x = node[1]
	slot.y = node[2]
	slot.z = node[3]
	slot.dist = 0
	slot.time = 0
	slot.prevDist = 0
	slot.prevTime = 0
	slot.misses = 0
	slot.missedAt = 0
	slot.disabled = false
	slot.useDist = 0
	slot.weight = 1
end

local function CountEnabledSlots()
	local c = 0
	for i = 1, POS.activeCount do
		if not POS.slots[i].disabled then c = c + 1 end
	end
	return c
end

local function SwapFromPool(idx, markBad)
	if POS.poolCount <= 0 or reg.data == nil or reg.data.nodes == nil then return false end
	local slot = POS.slots[idx]
	local oldID = slot.id
	local nextID = table.remove(POS.pool, 1)
	POS.poolCount = POS.poolCount - 1
	local node = reg.data.nodes[nextID]
	if node == nil then return false end
	if markBad then
		POS.bad[oldID] = true
	else
		POS.poolCount = POS.poolCount + 1
		POS.pool[POS.poolCount] = oldID
	end
	InitSlot(slot, nextID, node)
	if POS.prevSlot == slot then POS.prevSlot = nil end
	return true
end

local function IsInInitialBatch(idx)
	local seen = 0
	local total = POS.activeCount
	for off = 0, total - 1 do
		local c = ((POS.acqFrom + off) % total) + 1
		if not POS.slots[c].disabled then
			seen = seen + 1
			if c == idx then return seen <= CFG.minFix end
		end
	end
	return false
end

local function NextSlotIndex()
	local idx = POS.curIdx
	local total = POS.activeCount
	for _ = 1, total do
		idx = (idx % total) + 1
		if not POS.slots[idx].disabled and (POS.phase ~= 1 or IsInInitialBatch(idx)) then
			return idx
		end
	end
	return POS.curIdx
end

local function SwitchSlot(idx, now)
	POS.prevSlot = POS.slots[POS.curIdx]
	POS.curIdx = idx
	POS.pending = false
	POS.pinChecked = false
	POS.pinRefused = false
	POS.outranked = false
	local ok = pcall(C_SuperTrack.SetSuperTrackedMapPin, TAXI_PIN, POS.slots[idx].id)
	if not ok then POS.blockedUntil = now + 2 end
	POS.switchedAt = now
	POS.lastSwitch = now
end

local function CheckPinRefused(slot)
	if C_SuperTrack.GetSuperTrackedMapPin ~= nil then
		local ok, kind, id = pcall(C_SuperTrack.GetSuperTrackedMapPin)
		if ok and id ~= nil and (kind ~= TAXI_PIN or id ~= slot.id) then return true, false end
	end
	if C_SuperTrack.GetHighestPrioritySuperTrackingType ~= nil then
		local ok, top = pcall(C_SuperTrack.GetHighestPrioritySuperTrackingType)
		if ok and top ~= nil and top ~= TRACK_PIN then return true, true end
	end
	return false, false
end

local function LoseFix(now)
	if (now - POS.acquiredAt) < 2 then
		POS.settle = math.min(POS.settle * 1.4, CFG.settleMax)
		POS.acqFrom = (POS.acqFrom + 1) % math.max(1, POS.activeCount)
	else
		POS.settle = CFG.settleBase
	end
	POS.phase = 1
	POS.acqStart = now
	POS.fix.confirmed = false
	POS.misses = 0
	POS.rejects = 0
	POS.lastTime = 0
	ResetMotion(now)
end

local function RecordReading(slot, dist, now)
	if slot.time > 0 and slot.time >= POS.motionSince then
		slot.prevDist = slot.dist
		slot.prevTime = slot.time
	else
		slot.prevDist = 0
		slot.prevTime = 0
	end
	slot.dist = dist
	slot.time = now
	slot.misses = 0
	if POS.lastTime > 0 and (now - POS.lastTime) < 1 then
		local dt = now - POS.lastTime
		POS.interval = POS.interval > 0 and (POS.interval + 0.25 * (dt - POS.interval)) or dt
	end
	POS.lastDist = dist
	POS.lastTime = now
	POS.lastAnchorID = slot.id
	POS.misses = 0
	POS.lastOk = now
end

local function RecordMiss(slot, now)
	if slot.misses == 0 then slot.missedAt = now end
	slot.misses = slot.misses + 1
	POS.misses = POS.misses + 1
	if slot.misses >= 2 then
		local alone = POS.lastOk > slot.missedAt
		if alone or POS.phase == 1 then
			if SwapFromPool(POS.curIdx, alone) then
				POS.misses = 0
				return
			elseif alone and CountEnabledSlots() > CFG.minFix then
				slot.disabled = true
				POS.misses = 0
				return
			end
			slot.misses = 0
		end
	end
	if POS.phase ~= 1 and POS.misses >= CFG.missesLose then LoseFix(now) end
end

local function ReadDistance()
	local ok, d = pcall(C_Navigation.GetDistance)
	if not ok or IsSecret(d) then return nil, true end
	if type(d) ~= "number" then return 0, false end
	return d, false
end

local function StepSleep(now)
	if now < POS.nextSleepPing then return end
	POS.nextSleepPing = now + CFG.sleepPing
	local slot = POS.slots[POS.curIdx]
	if slot == nil then
		LoseFix(now)
		return
	end
	local refused, outranked = CheckPinRefused(slot)
	if refused then
		if outranked then
			POS.blockedUntil = now + 1.5
		else
			POS.phase = 2
			POS.settleLeft = POS.activeCount
			SwitchSlot(POS.curIdx, now)
		end
		return
	end
	local d, blocked = ReadDistance()
	if blocked then
		POS.blockedUntil = now + 3
		return
	end
	local f = POS.fix
	local expected = Dist3(slot, f.x, f.y, f.z)
	if d > 0 and math.abs(d - expected) <= CFG.sleepDrift then
		f.time = now
		return
	end
	POS.phase = 2
	POS.settleLeft = POS.activeCount
	POS.uncert = 15
	SwitchSlot(NextSlotIndex(), now)
end

local function Step(now)
	if POS.phase == 3 then
		StepSleep(now)
		return
	end
	if POS.pending then
		if now >= POS.switchAt then SwitchSlot(NextSlotIndex(), now) end
		return
	end
	local slot = POS.slots[POS.curIdx]
	if slot == nil then return end
	local d, blocked = ReadDistance()
	if blocked then
		POS.blockedUntil = now + 3
		return
	end

	local waited = now - POS.switchedAt
	local other = POS.prevSlot ~= slot and POS.prevSlot or nil
	local outcome = nil
	if not POS.pinChecked and waited >= CFG.pinCheck then
		POS.pinChecked = true
		local refused, outranked = CheckPinRefused(slot)
		POS.pinRefused = refused
		POS.outranked = outranked
	end
	if POS.pinRefused then
		outcome = "miss"
		if POS.outranked then POS.blockedUntil = now + 1.2 end
	elseif POS.phase == 1 or not POS.fix.valid then
		if d > 0 and waited >= POS.settle then
			local since = POS.lastTime > 0 and (now - POS.lastTime) or nil
			if since ~= nil and since < CFG.sameWindow and POS.lastAnchorID ~= slot.id and math.abs(d - POS.lastDist) <= (CFG.sameDist + CFG.sameDrift * since) then
				if waited >= POS.settle + CFG.timeout then outcome = "miss" end
			else
				outcome = "reading"
			end
		elseif waited >= POS.settle + CFG.timeout then
			outcome = "miss"
		end
	else
		local ex, ey, ez = EstimatePos(now)
		local expected = Dist3(slot, ex, ey, ez)
		local gate = math.min(CFG.gateMax, CFG.gateMin + POS.uncert + 3 * POS.fix.residual + 14 * (now - POS.fix.time)) + CFG.heightSlack * math.abs(ez - slot.z) / math.max(expected, 1)
		local prevExp = other ~= nil and Dist3(other, ex, ey, ez) or nil
		if d > 0 and math.abs(d - expected) <= gate then
			if prevExp == nil or math.abs(prevExp - expected) > 2 * gate or waited >= POS.settle then
				outcome = "reading"
			end
		elseif d > 0 and waited >= POS.settle and not (prevExp ~= nil and math.abs(d - prevExp) <= gate) then
			LoseFix(now)
			outcome = "lost"
		elseif waited >= CFG.timeout then
			outcome = "miss"
		end
	end

	if outcome == nil then return end
	if outcome == "reading" then
		RecordReading(slot, d, now)
		Solve(now)
		if POS.phase == 2 and POS.rejects >= CFG.rejectsLose then LoseFix(now) end
	elseif outcome == "miss" then
		RecordMiss(slot, now)
	end
	if POS.phase == 3 then return end

	POS.pending = true
	local fast = POS.moving or POS.phase == 1 or POS.fix.vx ~= 0 or POS.fix.vy ~= 0
	POS.switchAt = math.max(now, POS.lastSwitch + (fast and CFG.movingGap or CFG.idleGap))
	if now >= POS.switchAt then SwitchSlot(NextSlotIndex(), now) end
end

local function SetMarkerAlpha(visible)
	local frame = SuperTrackedFrame
	local states = Enum and Enum.NavigationState
	if type(frame) ~= "table" or frame.SetTargetAlphaForState == nil or states == nil then return end
	if states.Occluded ~= nil then pcall(frame.SetTargetAlphaForState, frame, states.Occluded, visible and 0.6 or 0) end
	if states.InRange ~= nil then pcall(frame.SetTargetAlphaForState, frame, states.InRange, visible and 1 or 0) end
end

local function SaveSuperTrack()
	local sv = POS.saved
	sv.has = true
	sv.quest = 0
	sv.waypoint = false
	sv.contentType = nil
	sv.contentID = nil
	sv.vignette = nil
	sv.pinType = nil
	sv.pinID = nil
	sv.priority = nil
	local st = C_SuperTrack
	if st == nil then return end
	if st.GetSuperTrackedQuestID ~= nil then
		local ok, q = pcall(st.GetSuperTrackedQuestID)
		if ok and q ~= nil and q ~= 0 then sv.quest = q end
	end
	if st.IsSuperTrackingUserWaypoint ~= nil then
		local ok, w = pcall(st.IsSuperTrackingUserWaypoint)
		if ok and w == true then sv.waypoint = true end
	end
	if st.GetSuperTrackedContent ~= nil then
		local ok, ct, cid = pcall(st.GetSuperTrackedContent)
		if ok and ct ~= nil and cid ~= nil then
			sv.contentType = ct
			sv.contentID = cid
		end
	end
	if st.GetSuperTrackedVignette ~= nil then
		local ok, v = pcall(st.GetSuperTrackedVignette)
		if ok and v ~= nil then sv.vignette = v end
	end
	if st.GetSuperTrackedMapPin ~= nil then
		local ok, pt, pid = pcall(st.GetSuperTrackedMapPin)
		if ok and pt ~= nil and pid ~= nil and not (pt == TAXI_PIN and POS.ours[pid]) then
			sv.pinType = pt
			sv.pinID = pid
		end
	end
	if st.GetHighestPrioritySuperTrackingType ~= nil then
		local ok, pr = pcall(st.GetHighestPrioritySuperTrackingType)
		if ok then sv.priority = pr end
	end
end

local function RestoreEntry(kind)
	local sv = POS.saved
	local st = C_SuperTrack
	if st == nil then return end
	if kind == TRACK_QUEST and sv.quest ~= 0 and st.SetSuperTrackedQuestID ~= nil then
		local ok, cur = pcall(st.GetSuperTrackedQuestID)
		if not ok or cur ~= sv.quest then pcall(st.SetSuperTrackedQuestID, sv.quest) end
	elseif kind == TRACK_WAYPOINT and sv.waypoint and st.SetSuperTrackedUserWaypoint ~= nil then
		local ok, cur = pcall(st.IsSuperTrackingUserWaypoint)
		if not ok or cur ~= true then pcall(st.SetSuperTrackedUserWaypoint, true) end
	elseif kind == TRACK_CONTENT and sv.contentType ~= nil and st.SetSuperTrackedContent ~= nil then
		local ok, ct, cid = pcall(st.GetSuperTrackedContent)
		if not ok or ct ~= sv.contentType or cid ~= sv.contentID then pcall(st.SetSuperTrackedContent, sv.contentType, sv.contentID) end
	elseif kind == TRACK_VIGNETTE and sv.vignette ~= nil and st.SetSuperTrackedVignette ~= nil then
		local ok, cur = pcall(st.GetSuperTrackedVignette)
		if not ok or cur ~= sv.vignette then pcall(st.SetSuperTrackedVignette, sv.vignette) end
	elseif kind == TRACK_PIN and sv.pinType ~= nil and st.SetSuperTrackedMapPin ~= nil then
		local ok, pt, pid = pcall(st.GetSuperTrackedMapPin)
		if not ok or pt ~= sv.pinType or pid ~= sv.pinID then pcall(st.SetSuperTrackedMapPin, sv.pinType, sv.pinID) end
	end
end

local function RestoreSuperTrack()
	local st = C_SuperTrack
	if st ~= nil and st.GetSuperTrackedMapPin ~= nil and st.ClearSuperTrackedMapPin ~= nil then
		local ok, pt, pid = pcall(st.GetSuperTrackedMapPin)
		if ok and pt == TAXI_PIN and POS.ours[pid] then pcall(st.ClearSuperTrackedMapPin) end
	end
	local sv = POS.saved
	if not sv.has then return end
	sv.has = false
	local order = {TRACK_QUEST, TRACK_WAYPOINT, TRACK_CONTENT, TRACK_VIGNETTE, TRACK_PIN}
	for i = 1, #order do
		if order[i] ~= sv.priority then RestoreEntry(order[i]) end
	end
	if sv.priority ~= nil then RestoreEntry(sv.priority) end
end

local function PlayerFactionBit()
	if UnitFactionGroup == nil then return 3 end
	local f = UnitFactionGroup("player")
	if f == "Alliance" then return 1 end
	if f == "Horde" then return 2 end
	return 3
end

local function BuildAnchorOrder(instID)
	local store = reg.data
	if store == nil or store.nodes == nil then return 0 end
	local raw = (store.anchors ~= nil and store.anchors[instID]) or store.fallback
	if raw == nil then return 0 end
	local fBit = PlayerFactionBit()
	local pref = {}
	local alt = {}
	local late = {}
	for i = 1, #raw do
		local id = raw[i]
		local node = store.nodes[id]
		if node ~= nil then
			if POS.bad[id] then
				late[#late + 1] = id
			else
				local nf = node[4] or 3
				if nf == 3 or nf == fBit then
					pref[#pref + 1] = id
				else
					alt[#alt + 1] = id
				end
			end
		end
	end
	if (#pref + #alt + #late) < CFG.minFix then return 0 end
	wipe(POS.ours)
	wipe(POS.pool)
	POS.poolCount = 0
	POS.activeCount = 0
	local function PushID(id)
		POS.ours[id] = true
		if POS.activeCount < CFG.activeCount then
			POS.activeCount = POS.activeCount + 1
			local slot = POS.slots[POS.activeCount]
			if slot == nil then
				slot = {}
				POS.slots[POS.activeCount] = slot
			end
			InitSlot(slot, id, store.nodes[id])
		else
			POS.poolCount = POS.poolCount + 1
			POS.pool[POS.poolCount] = id
		end
	end
	for i = 1, #pref do PushID(pref[i]) end
	for i = 1, #alt do PushID(alt[i]) end
	for i = 1, #late do PushID(late[i]) end
	return POS.activeCount
end

local impl = {}
local function EnsureFrames()
	if reg.driver == nil then
		local drv = CreateFrame("Frame")
		drv:Hide()
		drv:SetScript("OnUpdate", function(_, elapsed)
			local step = (POS.phase == 3 and POS.stopAt == 0) and CFG.stepSleep or CFG.stepActive
			POS.elapsed = POS.elapsed + elapsed
			if POS.elapsed < step then return end
			POS.elapsed = 0
			local now = GetTime()
			if POS.stopAt > 0 then
				if now >= POS.stopAt then impl.Stop() end
				return
			end
			if now < POS.blockedUntil then return end
			local ok = pcall(Step, now)
			if not ok then POS.blockedUntil = now + 1.5 end
		end)
		reg.driver = drv
	end
	if reg.motionFrame == nil then
		local mf = CreateFrame("Frame")
		mf:RegisterEvent("PLAYER_STARTED_MOVING")
		mf:RegisterEvent("PLAYER_STOPPED_MOVING")
		mf:RegisterEvent("PLAYER_ENTERING_WORLD")
		mf:RegisterEvent("ZONE_CHANGED_INDOORS")
		mf:RegisterEvent("ZONE_CHANGED")
		mf:SetScript("OnEvent", function(_, event)
			local now = GetTime()
			if event == "PLAYER_STARTED_MOVING" then
				POS.moving = true
				ResetMotion(now)
				if POS.active and POS.phase == 3 then
					POS.phase = 2
					POS.settleLeft = 0
					POS.elapsed = CFG.stepActive
					SwitchSlot(NextSlotIndex(), now)
				end
			elseif event == "PLAYER_STOPPED_MOVING" then
				POS.moving = false
				ResetMotion(now)
				if POS.active and POS.phase == 2 then POS.settleLeft = POS.activeCount end
			elseif event == "PLAYER_ENTERING_WORLD" then
				if GetCurrentInstanceID() == nil then
					wipe(reg.leases)
					impl.Stop()
				elseif POS.active and POS.phase == 3 then
					POS.nextSleepPing = now
				end
			elseif POS.active and POS.phase == 3 then
				POS.nextSleepPing = now
			end
		end)
		reg.motionFrame = mf
	end
end

function impl.IsAvailable()
	return C_SuperTrack ~= nil and C_SuperTrack.SetSuperTrackedMapPin ~= nil and C_Navigation ~= nil and C_Navigation.GetDistance ~= nil and reg.data ~= nil
end

function impl.Start(instID)
	if not impl.IsAvailable() or instID == nil then return false end
	if POS.active and POS.instID == instID then return true end
	if POS.active then impl.Stop() end
	if BuildAnchorOrder(instID) < CFG.minFix then return false end

	EnsureFrames()
	SaveSuperTrack()
	SetMarkerAlpha(false)
	local now = GetTime()
	POS.active = true
	POS.instID = instID
	POS.phase = 1
	POS.acqStart = now
	POS.acqFrom = 0
	POS.acquiredAt = 0
	POS.settle = CFG.settleBase
	POS.uncert = 0
	POS.interval = 0
	POS.lastDist = 0
	POS.lastTime = 0
	POS.lastAnchorID = 0
	POS.misses = 0
	POS.rejects = 0
	POS.lastOk = 0
	POS.moving = IsPlayerMoving()
	POS.blockedUntil = 0
	POS.stopAt = 0
	POS.elapsed = 0
	POS.settleLeft = 0
	POS.zCount = 0
	POS.zHead = 0
	local f = POS.fix
	f.valid = false
	f.confirmed = false
	f.heading = nil
	f.residual = 999
	f.count = 0
	ResetMotion(now)
	POS.curIdx = 1
	POS.prevSlot = nil
	SwitchSlot(1, now)
	reg.driver:Show()
	return true
end

function impl.Stop()
	POS.stopAt = 0
	if not POS.active then return end
	POS.active = false
	POS.instID = nil
	POS.phase = 0
	if reg.driver ~= nil then reg.driver:Hide() end
	POS.fix.valid = false
	POS.fix.confirmed = false
	RestoreSuperTrack()
	SetMarkerAlpha(true)
end

function impl.Request(ownerKey, instID)
	if ownerKey == nil or instID == nil then return false end
	if not impl.IsAvailable() then return false end
	reg.leases[ownerKey] = instID
	POS.stopAt = 0
	return impl.Start(instID)
end

function impl.Release(ownerKey)
	if ownerKey == nil or reg.leases[ownerKey] == nil then return end
	reg.leases[ownerKey] = nil
	local nextInst = nil
	for _, id in pairs(reg.leases) do
		nextInst = id
		break
	end
	if nextInst == nil then
		if POS.active and GetCurrentInstanceID() == POS.instID then
			POS.stopAt = GetTime() + 0.2
		else
			impl.Stop()
		end
	elseif POS.instID ~= nextInst then
		POS.stopAt = 0
		impl.Start(nextInst)
	end
end

function impl.Get()
	if not POS.active or not POS.fix.valid or not POS.fix.confirmed then return nil end
	local now = GetTime()
	local x, y = EstimatePos(now)
	local f = POS.fix
	return x, y, f.zMed, f.heading, now - f.time, f.residual, POS.phase
end

function impl.GetArtBounds(artKey)
	local store = reg.data
	if store == nil or store.art == nil or artKey == nil then return nil end
	local key = ExtractArtKey(artKey)
	if key == nil then return nil end
	return store.art[key]
end

function impl.GetLive(ownerKey, instID, enabled)
	local curInst = GetCurrentInstanceID()
	if curInst == nil or instID == nil or curInst ~= instID or enabled == false then
		impl.Release(ownerKey)
		return nil
	end
	local wx, wy, wz, heading, age
	if UnitPosition ~= nil then
		local nx, ny = UnitPosition("player")
		if not IsSecret(nx) and not IsSecret(ny) and type(nx) == "number" and type(ny) == "number" then
			impl.Release(ownerKey)
			wx, wy, age = nx, ny, 0
		end
	end
	if wx == nil then
		impl.Request(ownerKey, curInst)
		local fx, fy, fz, fhead, fage = impl.Get()
		if fx ~= nil and fage ~= nil and fage <= POS_MAX_AGE then
			wx, wy, wz, heading, age = fx, fy, fz, fhead, fage
		end
	end
	if wx == nil then return nil end
	local facing = nil
	if GetPlayerFacing ~= nil then
		local f = GetPlayerFacing()
		if not IsSecret(f) and type(f) == "number" then facing = f end
	end
	if facing == nil then facing = heading end
	return wx, wy, wz, facing, age
end

if reg.version < VERSION then
	reg.version = VERSION
	reg.impl = impl
end

function D4:RegisterInstancePosData(data)
	if type(data) == "table" then reg.data = data end
end

function D4:IsInstancePositionAvailable()
	return reg.impl.IsAvailable()
end

function D4:IsInstancePositionScanning()
	return POS.active == true
end

function D4:RequestInstancePosition(ownerKey, instID)
	return reg.impl.Request(ownerKey, instID)
end

function D4:ReleaseInstancePosition(ownerKey)
	reg.impl.Release(ownerKey)
end

function D4:GetInstancePosition()
	return reg.impl.Get()
end

function D4:GetInstanceArtBounds(artKey)
	return reg.impl.GetArtBounds(artKey)
end

function D4:GetLiveInstancePosition(ownerKey, instID, enabled)
	return reg.impl.GetLive(ownerKey, instID, enabled)
end

function D4:CreateInstancePosArrow(parent, level, size)
	local a = CreateFrame("Frame", nil, parent)
	local sz = size or ARROW_SIZE
	a:SetSize(sz, sz)
	a:EnableMouse(false)
	if level ~= nil then a:SetFrameLevel(level) end
	local tex = a:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints(a)
	tex:SetTexture("Interface\\Minimap\\MinimapArrow")
	a.tex = tex
	a:Hide()
	return a
end

function D4:HideInstancePosArrow(arrow, ownerKey)
	if arrow ~= nil then
		if arrow:IsShown() then arrow:Hide() end
		arrow._d4X = nil
		arrow._d4Y = nil
		arrow._d4Rot = nil
	end
	if ownerKey ~= nil then reg.impl.Release(ownerKey) end
end

function D4:UpdateInstancePosArrow(arrow, artTex, artKey, ownerKey, enabled)
	if arrow == nil or artTex == nil or enabled == false then
		D4:HideInstancePosArrow(arrow, ownerKey)
		return false
	end
	local bounds = reg.impl.GetArtBounds(artKey)
	if bounds == nil then
		D4:HideInstancePosArrow(arrow, ownerKey)
		return false
	end
	local wx, wy, _, facing = reg.impl.GetLive(ownerKey, bounds[1], enabled)
	if wx == nil then
		if arrow:IsShown() then arrow:Hide() end
		arrow._d4X = nil
		arrow._d4Y = nil
		return false
	end
	local dx = bounds[3] - bounds[2]
	local dy = bounds[5] - bounds[4]
	local aw = artTex:GetWidth() or 0
	local ah = artTex:GetHeight() or 0
	if dx <= 0 or dy <= 0 or aw <= 0 or ah <= 0 then
		if arrow:IsShown() then arrow:Hide() end
		return false
	end
	local u = (bounds[5] - wy) / dy
	local v = (bounds[3] - wx) / dx
	if u < -0.06 or u > 1.06 or v < -0.06 or v > 1.06 then
		if arrow:IsShown() then arrow:Hide() end
		arrow._d4X = nil
		arrow._d4Y = nil
		return false
	end
	local ax = u * aw
	local ay = -v * ah
	if arrow._d4X == nil or math.abs(ax - arrow._d4X) > 0.05 or math.abs(ay - arrow._d4Y) > 0.05 then
		arrow._d4X = ax
		arrow._d4Y = ay
		arrow:ClearAllPoints()
		arrow:SetPoint("CENTER", artTex, "TOPLEFT", ax, ay)
	end
	if facing ~= nil and (arrow._d4Rot == nil or math.abs(facing - arrow._d4Rot) > 0.005) then
		arrow._d4Rot = facing
		arrow.tex:SetRotation(facing)
	end
	if not arrow:IsShown() then arrow:Show() end
	return true
end

function D4:PrintInstancePositionStatus()
	local avail = reg.impl.IsAvailable()
	local phaseNames = {[0] = "idle", [1] = "acquiring", [2] = "tracking", [3] = "sleeping"}
	local pName = phaseNames[POS.phase] or tostring(POS.phase)
	local leaseList = {}
	for k in pairs(reg.leases) do leaseList[#leaseList + 1] = k end
	local f = POS.fix
	if f.valid then
		self:INFO(format("InstancePos: avail=%s active=%s phase=%s inst=%s leases=[%s] xyz=(%.1f, %.1f, %.1f) res=%.2f confirmed=%s", tostring(avail), tostring(POS.active), pName, tostring(POS.instID), table.concat(leaseList, ","), f.x, f.y, f.zMed, f.residual, tostring(f.confirmed)))
	else
		self:INFO(format("InstancePos: avail=%s active=%s phase=%s inst=%s leases=[%s] (no fix)", tostring(avail), tostring(POS.active), pName, tostring(POS.instID), table.concat(leaseList, ",")))
	end
end
