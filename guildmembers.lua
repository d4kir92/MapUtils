local _, MapUtils = ...
if WorldMapFrame == nil or C_Map == nil or C_Map.GetBestMapForUnit == nil or C_Map.GetPlayerMapPosition == nil or C_Map.GetMapRectOnMap == nil then return end
local Guild = {
	tag = "G",
	scale = 10000,
	sendInterval = 5,
	heartbeat = 30,
	moveEpsilon = 0.0015,
	expireOwn = 75,
	checkInterval = 0.1,
	pruneInterval = 2,
	dotSize = 12,
	border = 1.5,
	mask = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
	fallbackColor = {
		r = 0.2,
		g = 1,
		b = 0.4
	},
	members = {},
	pins = {},
	rects = {},
	elapsed = 0,
	sincePrune = 0,
	dirty = true,
	lastSent = {}
}

MapUtils.GuildMembers = Guild
function Guild.IsSecret(...)
	return MapUtils.Comm ~= nil and MapUtils.Comm.IsSecret(...)
end

function Guild.IsShown()
	return MapUtils:GetConfig("GUILDMEMBERPINS", true) == true
end

function Guild.IsSharing()
	return MapUtils:GetConfig("GUILDMEMBERSHARE", true) == true
end

function Guild.GetName(sender)
	if Ambiguate ~= nil then return Ambiguate(sender, "none") end

	return sender
end

function Guild.GetOwnPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	if Guild.IsSecret(mapID) or type(mapID) ~= "number" then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if pos == nil then return nil end
	local x, y = pos:GetXY()
	if Guild.IsSecret(x, y) or type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return nil end

	return mapID, x, y
end

function Guild.CanSend()
	if not Guild.IsSharing() or not IsInGuild() or MapUtils.Comm == nil then return false end
	if C_GuildInfo ~= nil and C_GuildInfo.CanSpeakInGuildChat ~= nil and not C_GuildInfo.CanSpeakInGuildChat() then return false end

	return true
end

function Guild.Broadcast()
	if not Guild.CanSend() then return end
	local mapID, x, y = Guild.GetOwnPosition()
	if mapID == nil then return end
	local last = Guild.lastSent
	local now = GetTime()
	local moved = last.mapID ~= mapID or last.x == nil or math.abs(last.x - x) > Guild.moveEpsilon or math.abs(last.y - y) > Guild.moveEpsilon
	if not moved and last.time ~= nil and now - last.time < Guild.heartbeat then return end
	local _, class = UnitClass("player")
	local message = format("%s%d:%d:%d:%s:%d", Guild.tag, mapID, x * Guild.scale + 0.5, y * Guild.scale + 0.5, class or "", UnitLevel("player") or 0)
	if MapUtils.Comm.RawSend(MapUtils.Comm.prefix, message, "GUILD") then
		last.mapID, last.x, last.y, last.time = mapID, x, y, now
	end
end

function Guild.RefreshTicker()
	local active = Guild.IsSharing() and IsInGuild()
	if active and Guild.ticker == nil then
		Guild.lastSent.time = nil
		Guild.ticker = C_Timer.NewTicker(Guild.sendInterval, Guild.Broadcast)
		C_Timer.After(1, Guild.Broadcast)
	elseif not active and Guild.ticker ~= nil then
		Guild.ticker:Cancel()
		Guild.ticker = nil
	end
end

Guild.sources = {
	MapUtils = 75,
	GuildMapDots = 15,
	GuildAtlas = 150,
	GuildCrest = 30,
	Kinship = 1900
}

function Guild.Store(sender, source, mapID, x, y, class, level)
	if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" or mapID <= 0 then return end
	if x < 0 or x > 1 or y < 0 or y > 1 or (x == 0 and y == 0) then return end
	local name = Guild.GetName(sender)
	if name == nil or name == "" then return end
	Guild.online[name] = true
	local now = GetTime()
	local member = Guild.members[name]
	if member == nil then
		member = {
			name = name
		}

		Guild.members[name] = member
	elseif source ~= "MapUtils" and member.source == "MapUtils" and now < member.expire then
		return
	end

	member.source = source
	member.mapID, member.x, member.y = mapID, x, y
	if type(class) == "string" and RAID_CLASS_COLORS[class] ~= nil then member.class = class end
	if type(level) == "number" and level > 0 then member.level = level end
	member.time = now
	member.expire = now + (Guild.sources[source] or Guild.expireOwn)
	Guild.dirty = true
end

function Guild.Remove(sender, source)
	local name = Guild.GetName(sender)
	local member = name and Guild.members[name]
	if member ~= nil and member.source == source then
		Guild.members[name] = nil
		Guild.dirty = true
	end
end

function Guild.OnOwn(payload, sender, chatType)
	if chatType ~= "GUILD" then return end
	local mapID, x, y, class, level = strsplit(":", payload)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then return end
	Guild.Store(sender, "MapUtils", tonumber(mapID), x / Guild.scale, y / Guild.scale, class, tonumber(level))
end

Guild.parsers = {
	GMD1 = function(message, sender)
		local tag, mapID, x, y, class = strsplit("|", message)
		x, y = tonumber(x), tonumber(y)
		if tag ~= "P" or x == nil or y == nil then return end
		Guild.Store(sender, "GuildMapDots", tonumber(mapID), x / Guild.scale, y / Guild.scale, class)
	end,
	GQHMAP = function(message, sender)
		if message == "0" then return Guild.Remove(sender, "GuildAtlas") end
		local mapID, x, y = message:match("^1;(%d+);([%d%.]+);([%d%.]+)$")
		Guild.Store(sender, "GuildAtlas", tonumber(mapID), tonumber(x), tonumber(y))
	end,
	GCF1 = function(message, sender)
		local mapID, x, y, class, level = message:match("^1~POS~[^~]*~(%d+)~([%d%.]+)~([%d%.]+)~(%u+)~(%d+)~%d+$")
		Guild.Store(sender, "GuildCrest", tonumber(mapID), tonumber(x), tonumber(y), class, tonumber(level))
	end,
	Kinship = function(message, sender)
		local kind, body = message:match("^(%u):(.*)$")
		if kind == "P" then
			local mapID, x, y = body:match("^(%d+):(%d+):(%d+):")
			x, y = tonumber(x), tonumber(y)
			if x == nil or y == nil then return end
			Guild.Store(sender, "Kinship", tonumber(mapID), x / 1000, y / 1000)
		elseif kind == "D" then
			Guild.OnKinshipChunk(sender, body)
		end
	end
}

Guild.kinship = {}
function Guild.OnKinshipChunk(sender, body)
	local id, index, total, chunk = body:match("^(%d+):(%d+):(%d+):(.*)$")
	index, total = tonumber(index), tonumber(total)
	if id == nil or total < 1 or total > 30 or index < 1 or index > total then return end
	local now = GetTime()
	for key, partial in pairs(Guild.kinship) do
		if now - partial.time > 30 then Guild.kinship[key] = nil end
	end

	local key = sender .. "#" .. id
	local partial = Guild.kinship[key]
	if partial == nil then
		partial = {
			total = total,
			count = 0,
			parts = {},
			time = now
		}

		Guild.kinship[key] = partial
	end

	if partial.total ~= total or partial.parts[index] ~= nil then return end
	partial.parts[index] = chunk
	partial.count = partial.count + 1
	if partial.count < total then return end
	Guild.kinship[key] = nil
	local fields = {}
	for pair in table.concat(partial.parts):gmatch("[^;]+") do
		local k, v = pair:match("^(%w+)=(.*)$")
		if k == "c" or k == "l" or k == "mp" or k == "px" or k == "py" then fields[k] = v:gsub("~(%x%x)", function(h) return string.char(tonumber(h, 16)) end) end
	end

	local x, y = tonumber(fields.px), tonumber(fields.py)
	if x == nil or y == nil then return end
	Guild.Store(sender, "Kinship", tonumber(fields.mp), x / 1000, y / 1000, fields.c, tonumber(fields.l))
end

Guild.online = {}
function Guild.UpdateRoster()
	if GetNumGuildMembers == nil or GetGuildRosterInfo == nil then return end
	local count = GetNumGuildMembers()
	if Guild.IsSecret(count) or type(count) ~= "number" or count <= 0 then return end
	wipe(Guild.online)
	for index = 1, count do
		local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(index)
		if not Guild.IsSecret(name, online) and type(name) == "string" then Guild.online[Guild.GetName(name)] = online and true or false end
	end

	for name in pairs(Guild.members) do
		if Guild.online[name] == false then
			Guild.members[name] = nil
			Guild.dirty = true
		end
	end
end

function Guild.RequestRoster()
	local now = GetTime()
	if Guild.lastRoster ~= nil and now - Guild.lastRoster < 30 then return end
	Guild.lastRoster = now
	if C_GuildInfo ~= nil and C_GuildInfo.GuildRoster ~= nil then
		pcall(C_GuildInfo.GuildRoster)
	elseif GuildRoster ~= nil then
		pcall(GuildRoster)
	end
end

function Guild.Prune()
	local now = GetTime()
	for name, member in pairs(Guild.members) do
		if now > member.expire then
			Guild.members[name] = nil
			Guild.dirty = true
		end
	end
end

function Guild.GetRect(sourceID, targetID)
	local key = sourceID * 100000 + targetID
	local rect = Guild.rects[key]
	if rect == nil then
		local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(sourceID, targetID)
		if minX ~= nil and maxX ~= nil and minY ~= nil and maxY ~= nil and minX < maxX and minY < maxY then
			rect = {minX, maxX, minY, maxY}
		else
			rect = false
		end

		Guild.rects[key] = rect
	end

	return rect or nil
end

function Guild.Project(sourceID, targetID, x, y)
	local visited = {}
	while sourceID ~= targetID do
		if visited[sourceID] then return nil end
		visited[sourceID] = true
		local rect = Guild.GetRect(sourceID, targetID)
		if rect ~= nil then return rect[1] + x * (rect[2] - rect[1]), rect[3] + y * (rect[4] - rect[3]) end
		local info = C_Map.GetMapInfo(sourceID)
		local parentID = info and info.parentMapID
		if parentID == nil or parentID == 0 then return nil end
		rect = Guild.GetRect(sourceID, parentID)
		if rect == nil then return nil end
		x, y = rect[1] + x * (rect[2] - rect[1]), rect[3] + y * (rect[4] - rect[3])
		sourceID = parentID
	end

	return x, y
end

function Guild.IsGrouped(name)
	return UnitInParty(name) or UnitInRaid(name)
end

function Guild.OnPinEnter(pin)
	local member = pin.member
	if member == nil then return end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	local color = RAID_CLASS_COLORS[member.class or ""] or Guild.fallbackColor
	GameTooltip:SetText(member.name, color.r, color.g, color.b)
	local info = C_Map.GetMapInfo(member.mapID)
	if member.level ~= nil then
		GameTooltip:AddLine(format("%s %d", LEVEL or "Level", member.level), 1, 1, 1)
	end

	if info ~= nil and info.name ~= nil then GameTooltip:AddLine(info.name, 1, 1, 1) end
	GameTooltip:AddLine(format(MapUtils:Trans("LID_GUILDMEMBERSEEN"), math.max(0, math.floor(GetTime() - member.time))), 0.7, 0.7, 0.7)
	if member.source ~= nil then GameTooltip:AddLine(member.source, 0.5, 0.5, 0.5) end
	GameTooltip:Show()
end

function Guild.CreatePin(canvas)
	local pin = CreateFrame("Frame", nil, canvas)
	pin:EnableMouse(true)
	pin.border = pin:CreateTexture(nil, "BACKGROUND")
	pin.border:SetAllPoints()
	pin.border:SetTexture(Guild.mask)
	pin.border:SetVertexColor(0, 0, 0, 0.9)
	pin.dot = pin:CreateTexture(nil, "ARTWORK")
	pin.dot:SetTexture(Guild.mask)
	pin:SetScript("OnEnter", Guild.OnPinEnter)
	pin:SetScript("OnLeave", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
	pin:SetScript("OnHide", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)

	return pin
end

function Guild.GetPinLevel(canvas)
	if not InCombatLockdown() and WorldMapFrame.GetPinFrameLevelsManager ~= nil then
		local manager = WorldMapFrame:GetPinFrameLevelsManager()
		if manager ~= nil and manager.GetValidFrameLevel ~= nil then
			local ok, level = pcall(manager.GetValidFrameLevel, manager, "PIN_FRAME_LEVEL_GROUP_MEMBER")
			if ok and type(level) == "number" then return level end
		end
	end

	return canvas:GetFrameLevel() + 30
end

function Guild.HidePins()
	for _, pin in ipairs(Guild.pins) do
		pin:Hide()
	end
end

function Guild.UpdatePins()
	local canvas = WorldMapFrame:GetCanvas()
	local mapID = WorldMapFrame:GetMapID()
	if canvas == nil or mapID == nil or not Guild.IsShown() or (MapUtils.IsInstanceMapShown ~= nil and MapUtils:IsInstanceMapShown()) then
		Guild.HidePins()

		return
	end

	local scale = canvas:GetScale()
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if scale == nil or scale <= 0 or width <= 0 or height <= 0 then
		Guild.HidePins()

		return
	end

	local size, inset = Guild.dotSize / scale, Guild.border / scale
	local level = Guild.GetPinLevel(canvas)
	local count = 0
	for name, member in pairs(Guild.members) do
		if not Guild.IsGrouped(name) then
			local x, y = Guild.Project(member.mapID, mapID, member.x, member.y)
			if x ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
				count = count + 1
				local pin = Guild.pins[count]
				if pin == nil then
					pin = Guild.CreatePin(canvas)
					Guild.pins[count] = pin
				end

				pin.member = member
				if pin:GetFrameLevel() ~= level then pin:SetFrameLevel(level) end
				pin:SetSize(size, size)
				pin.dot:ClearAllPoints()
				pin.dot:SetPoint("TOPLEFT", inset, -inset)
				pin.dot:SetPoint("BOTTOMRIGHT", -inset, inset)
				local color = RAID_CLASS_COLORS[member.class or ""] or Guild.fallbackColor
				pin.dot:SetVertexColor(color.r, color.g, color.b, 1)
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", canvas, "TOPLEFT", width * x, -height * y)
				pin:Show()
			end
		end
	end

	for index = count + 1, #Guild.pins do
		Guild.pins[index]:Hide()
	end
end

function Guild.OnUpdate(_, elapsed)
	Guild.elapsed = Guild.elapsed + elapsed
	if Guild.elapsed < Guild.checkInterval then return end
	Guild.sincePrune = Guild.sincePrune + Guild.elapsed
	Guild.elapsed = 0
	if Guild.sincePrune >= Guild.pruneInterval then
		Guild.sincePrune = 0
		Guild.Prune()
	end

	local canvas = WorldMapFrame:GetCanvas()
	local mapID = WorldMapFrame:GetMapID()
	local scale = canvas and canvas:GetScale()
	local width = canvas and canvas:GetWidth()
	if not Guild.dirty and mapID == Guild.lastMapID and scale == Guild.lastScale and width == Guild.lastWidth then return end
	Guild.dirty = false
	Guild.lastMapID, Guild.lastScale, Guild.lastWidth = mapID, scale, width
	Guild.UpdatePins()
end

function MapUtils:RefreshGuildMembers()
	Guild.dirty = true
	Guild.RefreshTicker()
	if not Guild.IsShown() then Guild.HidePins() end
end

function Guild.OnEvent(_, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix, message, chatType, sender = ...
		if Guild.IsSecret(prefix) then return end
		local parser = Guild.parsers[prefix]
		if parser == nil or Guild.IsSecret(message, chatType, sender) or chatType ~= "GUILD" then return end
		if type(message) ~= "string" or type(sender) ~= "string" or #message > 255 or (MapUtils.Comm ~= nil and MapUtils.Comm.IsSelf(sender)) then return end
		pcall(parser, message, sender)

		return
	end

	if event == "GROUP_ROSTER_UPDATE" then
		Guild.dirty = true

		return
	end

	if event == "GUILD_ROSTER_UPDATE" then
		Guild.UpdateRoster()

		return
	end

	Guild.RefreshTicker()
end

if MapUtils.Comm ~= nil then MapUtils.Comm.Register(Guild.tag, Guild.OnOwn) end
if C_ChatInfo ~= nil and C_ChatInfo.RegisterAddonMessagePrefix ~= nil then
	for prefix in pairs(Guild.parsers) do
		C_ChatInfo.RegisterAddonMessagePrefix(prefix)
	end
end

Guild.frame = CreateFrame("Frame")
Guild.frame:RegisterEvent("PLAYER_LOGIN")
Guild.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
Guild.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
Guild.frame:RegisterEvent("GUILD_ROSTER_UPDATE")
Guild.frame:RegisterEvent("CHAT_MSG_ADDON")
Guild.frame:SetScript("OnEvent", Guild.OnEvent)
Guild.updater = CreateFrame("Frame", nil, WorldMapFrame)
Guild.updater:SetScript("OnUpdate", Guild.OnUpdate)
WorldMapFrame:HookScript("OnShow", function()
	Guild.dirty = true
	Guild.elapsed = Guild.checkInterval
	Guild.sincePrune = Guild.pruneInterval
	if IsInGuild() then Guild.RequestRoster() end
end)

WorldMapFrame:HookScript("OnHide", Guild.HidePins)
