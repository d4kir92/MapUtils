local _, MapUtils = ...
if MapUtils.GuildMembers == nil or MapUtils.Comm == nil then return end
local Comm = MapUtils.Comm
local Friends = {
	tag = "F",
	openPrefix = "OpenMapLoc",
	scale = 10000,
	tickInterval = 5,
	sendGap = 10,
	heartbeat = 30,
	moveEpsilon = 0.0015,
	scanDelay = 2,
	sendDelay = 1,
	expire = {
		MapUtils = 75,
		OpenMap = 150
	},
	members = {},
	online = {},
	accounts = {},
	known = {},
	greeted = {},
	greetedOpen = {},
	outbox = {},
	order = {},
	lastSent = {}
}

MapUtils.FriendMembers = Friends
function Friends.IsShown()
	if not MapUtils:IsPinCategoryEnabled("FRIENDMEMBERPINS") then return false end

	return MapUtils:GetPinScopeShown("FRIENDMEMBERPINS", true, false) or MapUtils:GetPinScopeShown("FRIENDMEMBERPINS", true, true)
end

function Friends.IsSharing()
	return MapUtils:GetConfig("FRIENDMEMBERSHARE", true) == true
end

function Friends.IsActive()
	return Friends.IsShown() or Friends.IsSharing()
end

function Friends.GetName(name, realm)
	if Comm.IsSecret(name, realm) or type(name) ~= "string" or name == "" then return nil end
	if not name:find("-", 1, true) and type(realm) == "string" and realm ~= "" then name = name .. "-" .. realm:gsub("[%s%-]", "") end
	if Ambiguate ~= nil then return Ambiguate(name, "none") end

	return name
end

function Friends.AddOnline(online, name, how)
	if name == nil or Comm.IsSelf(name) then return end
	if how.bn ~= nil or online[name] == nil then online[name] = how end
end

function Friends.ScanCharacters(online)
	if C_FriendList == nil or C_FriendList.GetNumFriends == nil or C_FriendList.GetFriendInfoByIndex == nil then return end
	local count = C_FriendList.GetNumFriends()
	if Comm.IsSecret(count) or type(count) ~= "number" then return end
	for index = 1, count do
		local info = C_FriendList.GetFriendInfoByIndex(index)
		if type(info) == "table" and not Comm.IsSecret(info.connected, info.name) and info.connected and type(info.name) == "string" then
			Friends.AddOnline(online, Friends.GetName(info.name), {
				whisper = info.name
			})
		end
	end
end

function Friends.IsSameGame(game, faction)
	if type(game) ~= "table" or Comm.IsSecret(game.isOnline, game.clientProgram, game.wowProjectID, game.factionName, game.gameAccountID) then return false end
	if not game.isOnline or game.clientProgram ~= (BNET_CLIENT_WOW or "WoW") or type(game.gameAccountID) ~= "number" then return false end
	if WOW_PROJECT_ID ~= nil and game.wowProjectID ~= WOW_PROJECT_ID then return false end

	return game.factionName == faction
end

function Friends.ScanBattleNet(online, accounts)
	if BNGetNumFriends == nil or BNSendGameData == nil or C_BattleNet == nil or C_BattleNet.GetFriendAccountInfo == nil then return end
	local count = BNGetNumFriends()
	local faction = UnitFactionGroup("player")
	if Comm.IsSecret(count, faction) or type(count) ~= "number" then return end
	for index = 1, count do
		local account = C_BattleNet.GetFriendAccountInfo(index)
		local game = type(account) == "table" and account.gameAccountInfo
		if Friends.IsSameGame(game, faction) then
			local name = Friends.GetName(game.characterName, game.realmName)
			if name ~= nil then
				Friends.AddOnline(online, name, {
					bn = game.gameAccountID
				})

				accounts[game.gameAccountID] = name
			end
		end
	end
end

function Friends.Scan()
	Friends.scanPending = nil
	local online, accounts = {}, {}
	pcall(Friends.ScanCharacters, online)
	pcall(Friends.ScanBattleNet, online, accounts)
	Friends.online, Friends.accounts = online, accounts
	for _, list in ipairs({Friends.known, Friends.greeted, Friends.greetedOpen}) do
		for name in pairs(list) do
			if online[name] == nil then list[name] = nil end
		end
	end

	for name in pairs(Friends.members) do
		if online[name] == nil then Friends.members[name] = nil end
	end

	Friends.GreetAll()
	MapUtils:MarkGuildMapDirty()
end

function Friends.QueueScan()
	if Friends.scanPending then return end
	Friends.scanPending = true
	C_Timer.After(Friends.scanDelay, Friends.Scan)
end

function Friends.Deliver(name, prefix, message)
	local how = Friends.online[name]
	if how == nil then return end
	if prefix == Comm.prefix and message:sub(2, 2):match("%d") and not Friends.IsSharing() then return end
	if how.bn ~= nil then
		pcall(BNSendGameData, how.bn, prefix, message)
	else
		Comm.RawSend(prefix, message, "WHISPER", how.whisper)
	end
end

function Friends.Pump()
	local key = tremove(Friends.order, 1)
	if key == nil then
		Friends.sender:Cancel()
		Friends.sender = nil

		return
	end

	local item = Friends.outbox[key]
	Friends.outbox[key] = nil
	if item ~= nil then Friends.Deliver(item[1], item[2], item[3]) end
end

function Friends.Queue(name, prefix, message)
	local key = name .. "\001" .. prefix
	if Friends.outbox[key] == nil then tinsert(Friends.order, key) end
	Friends.outbox[key] = {name, prefix, message}
	if Friends.sender == nil then Friends.sender = C_Timer.NewTicker(Friends.sendDelay, MapUtils.Profile("friends Pump", Friends.Pump)) end
end

function Friends.GreetAll()
	local active, shown = Friends.IsActive(), Friends.IsShown()
	for name in pairs(Friends.online) do
		if active and not Friends.greeted[name] then
			Friends.greeted[name] = true
			Friends.Queue(name, Comm.prefix, Friends.tag .. "H")
		end

		if shown and not Friends.greetedOpen[name] then
			Friends.greetedOpen[name] = true
			Friends.Queue(name, Friends.openPrefix, "H1")
		end
	end
end

function Friends.BuildMessage(mapID, x, y)
	local taxi = UnitOnTaxi ~= nil and UnitOnTaxi("player")
	local faction = UnitFactionGroup("player")
	local _, class = UnitClass("player")
	local level = UnitLevel("player")
	if Comm.IsSecret(taxi, faction, class, level) then return nil end
	if faction ~= "Horde" and faction ~= "Alliance" then faction = "" end

	return format("%s%d:%d:%d:%s:%d:%d:%s", Friends.tag, mapID, x * Friends.scale + 0.5, y * Friends.scale + 0.5, class or "", level or 0, taxi and 1 or 0, faction)
end

function Friends.Broadcast()
	if not Friends.IsSharing() or next(Friends.known) == nil then return end
	local mapID, x, y = MapUtils.GuildMembers.GetOwnPosition()
	if mapID == nil then return end
	local last, now = Friends.lastSent, GetTime()
	local moved = last.mapID ~= mapID or last.x == nil or math.abs(last.x - x) > Friends.moveEpsilon or math.abs(last.y - y) > Friends.moveEpsilon
	if last.time ~= nil and now - last.time < (moved and Friends.sendGap or Friends.heartbeat) then return end
	local message = Friends.BuildMessage(mapID, x, y)
	if message == nil then return end
	local guild = MapUtils:GetActiveGuildMap()
	local guildShares = guild ~= nil and guild.IsSharing() and IsInGuild()
	for name in pairs(Friends.known) do
		if Friends.online[name] ~= nil and not (guildShares and guild.online[name] ~= nil) then Friends.Queue(name, Comm.prefix, message) end
	end

	last.mapID, last.x, last.y, last.time = mapID, x, y, now
end

function Friends.Store(name, source, mapID, x, y, class, level, taxi, faction)
	if type(mapID) ~= "number" or mapID <= 0 or type(x) ~= "number" or type(y) ~= "number" then return end
	if x < 0 or x > 1 or y < 0 or y > 1 or (x == 0 and y == 0) then return end
	local now = GetTime()
	local member = Friends.members[name]
	if member == nil then
		member = {
			name = name
		}

		Friends.members[name] = member
	elseif source ~= "MapUtils" and member.source == "MapUtils" and now < member.expire then
		return
	end

	member.source = source
	member.mapID, member.x, member.y = mapID, x, y
	member.taxi = taxi == "1"
	member.faction = (faction == "Horde" or faction == "Alliance") and faction or nil
	if type(class) == "string" and RAID_CLASS_COLORS[class] ~= nil then member.class = class end
	if type(level) == "number" and level > 0 then member.level = level end
	member.time = now
	member.expire = now + (Friends.expire[source] or Friends.expire.MapUtils)
	MapUtils:MarkGuildMapDirty()
end

function Friends.Remove(name, source)
	local member = Friends.members[name]
	if member ~= nil and member.source == source then
		Friends.members[name] = nil
		MapUtils:MarkGuildMapDirty()
	end
end

function Friends.Receive(name, payload)
	if name == nil or Friends.online[name] == nil or not Friends.IsActive() then return end
	Friends.known[name] = true
	if payload == "H" then
		Friends.Queue(name, Comm.prefix, Friends.tag .. "A")
		Friends.lastSent.time = nil

		return
	end

	if payload == "A" then
		Friends.lastSent.time = nil

		return
	end

	local mapID, x, y, class, level, taxi, faction = strsplit(":", payload)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then return end
	Friends.Store(name, "MapUtils", tonumber(mapID), x / Friends.scale, y / Friends.scale, class, tonumber(level), taxi, faction)
end

function Friends.ReceiveOpenMap(name, text)
	if name == nil or Friends.online[name] == nil or not Friends.IsShown() then return end
	local kind, mapID, x, y, class, level = strsplit("\t", text)
	if kind == "H1" then
		Friends.Queue(name, Friends.openPrefix, "H2")
	elseif kind == "L0" then
		Friends.Remove(name, "OpenMap")
	elseif kind == "L1" then
		Friends.Store(name, "OpenMap", tonumber(mapID), tonumber(x), tonumber(y), class, tonumber(level))
	end
end

function Friends.Tick()
	local now = GetTime()
	for name, member in pairs(Friends.members) do
		if now > member.expire then
			Friends.members[name] = nil
			MapUtils:MarkGuildMapDirty()
		end
	end

	Friends.Broadcast()
end

function Friends.RefreshTicker()
	local active = Friends.IsActive()
	if active and Friends.ticker == nil then
		Friends.lastSent.time = nil
		Friends.ticker = C_Timer.NewTicker(Friends.tickInterval, MapUtils.Profile("friends Tick", Friends.Tick))
	elseif not active and Friends.ticker ~= nil then
		Friends.ticker:Cancel()
		Friends.ticker = nil
	end
end

function MapUtils:RefreshFriendMembers()
	Friends.RefreshTicker()
	Friends.GreetAll()
	MapUtils:MarkGuildMapDirty()
end

function Friends.OnEvent(_, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix, text, chatType, sender = ...
		if Comm.IsSecret(prefix, text, chatType, sender) or prefix ~= Friends.openPrefix or chatType ~= "WHISPER" or type(text) ~= "string" or #text > 255 then return end
		Friends.ReceiveOpenMap(Friends.GetName(sender), text)

		return
	end

	if event == "BN_CHAT_MSG_ADDON" then
		local prefix, text, _, accountID = ...
		if Comm.IsSecret(prefix, text, accountID) or type(text) ~= "string" or #text > 255 then return end
		local name = Friends.accounts[accountID]
		if prefix == Friends.openPrefix then
			Friends.ReceiveOpenMap(name, text)
		elseif prefix == Comm.prefix and text:sub(1, 1) == Friends.tag then
			Friends.Receive(name, text:sub(2))
		end

		return
	end

	if event == "PLAYER_LOGIN" then
		if C_FriendList ~= nil and C_FriendList.ShowFriends ~= nil then pcall(C_FriendList.ShowFriends) end
		MapUtils:RefreshFriendMembers()
	end

	Friends.QueueScan()
end

Comm.Register(Friends.tag, function(payload, sender, chatType)
	if chatType == "WHISPER" then Friends.Receive(Friends.GetName(sender), payload) end
end)

if C_ChatInfo ~= nil and C_ChatInfo.RegisterAddonMessagePrefix ~= nil then C_ChatInfo.RegisterAddonMessagePrefix(Friends.openPrefix) end
Friends.frame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "CHAT_MSG_ADDON", "BN_CHAT_MSG_ADDON"}) do
	pcall(Friends.frame.RegisterEvent, Friends.frame, event)
end

Friends.frame:SetScript("OnEvent", Friends.OnEvent)
