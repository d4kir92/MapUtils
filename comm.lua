local _, MapUtils = ...
local Comm = {
	prefix = "MapUtils",
	channel = "MapUtils",
	handlers = {},
	queue = {},
	maxQueue = 40,
	gap = 1.2,
	nextSend = 0,
	joinDelay = 12,
	joined = false
}

MapUtils.Comm = Comm
function Comm.IsSecret(...)
	if issecretvalue == nil then return false end
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if issecretvalue(value) then return true end
	end

	return false
end

function Comm.IsEnabled()
	return MapUtils:GetConfig("COMMCHANNEL", true) == true
end

function Comm.IsSelf(sender)
	local name, realm = UnitFullName("player")
	if name == nil or sender == name then return true end

	return realm ~= nil and realm ~= "" and sender == name .. "-" .. realm
end

function Comm.GetChannelNumber()
	if GetChannelName == nil then return nil end
	local number = GetChannelName(Comm.channel)
	if Comm.IsSecret(number) or type(number) ~= "number" or number <= 0 then return nil end

	return number
end

function Comm.HideChannel()
	for i = 1, NUM_CHAT_WINDOWS or 10 do
		local frame = _G["ChatFrame" .. i]
		if frame ~= nil then
			if ChatFrame_RemoveChannel ~= nil then
				pcall(ChatFrame_RemoveChannel, frame, Comm.channel)
			elseif frame.RemoveChannel ~= nil then
				pcall(frame.RemoveChannel, frame, Comm.channel)
			end
		end
	end
end

function Comm.Join()
	if not Comm.IsEnabled() or JoinTemporaryChannel == nil then return end
	if Comm.GetChannelNumber() == nil then pcall(JoinTemporaryChannel, Comm.channel) end
	Comm.joined = true
	C_Timer.After(1, Comm.HideChannel)
	C_Timer.After(5, Comm.HideChannel)
end

function Comm.Leave()
	Comm.joined = false
	if LeaveChannelByName ~= nil and Comm.GetChannelNumber() ~= nil then pcall(LeaveChannelByName, Comm.channel) end
end

function MapUtils:RefreshCommChannel()
	if Comm.IsEnabled() then
		Comm.Join()
	else
		Comm.Leave()
	end
end

function Comm.GetGroupType()
	if LE_PARTY_CATEGORY_INSTANCE ~= nil and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end

	return nil
end

function Comm.GetTargets(dist, target)
	local targets = {}
	if dist == "ALL" or dist == "CHANNEL" then
		local number = target or Comm.GetChannelNumber()
		if number ~= nil and Comm.IsEnabled() then tinsert(targets, {"CHANNEL", tostring(number)}) end
	end

	if (dist == "ALL" or dist == "GUILD") and IsInGuild() then tinsert(targets, {"GUILD"}) end
	if dist == "ALL" or dist == "GROUP" then
		local group = Comm.GetGroupType()
		if group ~= nil then tinsert(targets, {group}) end
	elseif dist == "PARTY" or dist == "RAID" or dist == "INSTANCE_CHAT" or dist == "WHISPER" then
		tinsert(targets, {dist, target})
	end

	return targets
end

function Comm.RawSend(prefix, message, chatType, target)
	if C_ChatInfo == nil or C_ChatInfo.SendAddonMessage == nil then return false end
	local ok, result = pcall(C_ChatInfo.SendAddonMessage, prefix, message, chatType, target)

	return ok and (result == nil or result == true or result == 0)
end

function Comm.Pump()
	if #Comm.queue == 0 then
		if Comm.ticker ~= nil then Comm.ticker:Cancel() end
		Comm.ticker = nil

		return
	end

	if GetTime() < Comm.nextSend then return end
	local item = tremove(Comm.queue, 1)
	Comm.nextSend = GetTime() + Comm.gap
	Comm.RawSend(item[1], item[2], item[3], item[4])
end

function Comm.Enqueue(prefix, message, chatType, target)
	if #Comm.queue >= Comm.maxQueue then return false end
	tinsert(Comm.queue, {prefix, message, chatType, target})
	if Comm.ticker == nil then Comm.ticker = C_Timer.NewTicker(0.2, Comm.Pump) end

	return true
end

function Comm.SendPrefixed(prefix, message, dist, target)
	local sent = {}
	for _, item in ipairs(Comm.GetTargets(dist, target)) do
		if Comm.Enqueue(prefix, message, item[1], item[2]) then tinsert(sent, item[1] == "CHANNEL" and Comm.channel or item[1]) end
	end

	return sent
end

function Comm.Send(tag, payload, dist, target)
	return Comm.SendPrefixed(Comm.prefix, tag .. payload, dist, target)
end

function Comm.Register(tag, handler)
	Comm.handlers[tag] = handler
end

function Comm.GetReplyTarget(chatType)
	if chatType == "CHANNEL" then return "CHANNEL", Comm.GetChannelNumber() end
	if chatType == "GUILD" or chatType == "PARTY" or chatType == "RAID" or chatType == "INSTANCE_CHAT" then return chatType, nil end

	return nil, nil
end

function Comm.OnNotice(...)
	local baseName = select(9, ...)
	if Comm.IsSecret(baseName) then return end
	if type(baseName) == "string" and strlower(baseName) == strlower(Comm.channel) then C_Timer.After(0.5, Comm.HideChannel) end
end

function Comm.OnEvent(_, event, ...)
	if event == "PLAYER_LOGIN" then
		C_Timer.After(Comm.joinDelay, Comm.Join)

		return
	end

	if event == "CHAT_MSG_CHANNEL_NOTICE" then
		Comm.OnNotice(...)

		return
	end

	local prefix, message, chatType, sender = ...
	if Comm.IsSecret(prefix, message, chatType, sender) or prefix ~= Comm.prefix then return end
	if type(message) ~= "string" or type(sender) ~= "string" or message == "" or Comm.IsSelf(sender) then return end
	local handler = Comm.handlers[message:sub(1, 1)]
	if handler ~= nil then pcall(handler, message:sub(2), sender, chatType) end
end

if C_ChatInfo ~= nil and C_ChatInfo.RegisterAddonMessagePrefix ~= nil then C_ChatInfo.RegisterAddonMessagePrefix(Comm.prefix) end
Comm.frame = CreateFrame("FRAME")
Comm.frame:RegisterEvent("PLAYER_LOGIN")
Comm.frame:RegisterEvent("CHAT_MSG_ADDON")
Comm.frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
Comm.frame:SetScript("OnEvent", Comm.OnEvent)
