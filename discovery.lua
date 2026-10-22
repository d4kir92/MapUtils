local _, MapUtils = ...
local Discovery = {
	radius = 60,
	interval = 1,
	moveYards = 5,
	maxDepth = 6,
	options = {
		pier = "PIERSHOWUNEXPLORED",
		dungeon = "DUNGEONSHOWUNEXPLORED",
		meetingstone = "MEETINGSTONESHOWUNEXPLORED",
		spirithealer = "SPIRITHEALERSHOWUNEXPLORED",
		convergence = "CONVERGENCESHOWUNEXPLORED",
		flight = "FLIGHTSHOWUNEXPLORED",
		crossing = "CROSSINGSHOWUNEXPLORED",
	},
}

MapUtils.Discovery = Discovery
function Discovery.GetStore()
	if type(MAUTTABPC) ~= "table" then MAUTTABPC = {} end
	if type(MAUTTABPC.DISCOVERED) ~= "table" then MAUTTABPC.DISCOVERED = {} end

	return MAUTTABPC.DISCOVERED
end

function Discovery.GetKind(entry)
	return entry.kind or "pier"
end

function Discovery.GetKey(mapID, entry)
	local kind = Discovery.GetKind(entry)
	if kind == "flight" and entry.nodeID ~= nil then return "flight:" .. tostring(entry.nodeID) end
	local x, y = entry.origX or entry.x, entry.origY or entry.y
	if type(x) ~= "number" or type(y) ~= "number" then return nil end

	return format("%s:%s:%d:%d", kind, tostring(mapID), math.floor(x * 1000 + 0.5), math.floor(y * 1000 + 0.5))
end

function Discovery.ShowsUnexplored(kind)
	local option = Discovery.options[kind]
	if option == nil then return true end

	return MapUtils:GetConfig(option, true) == true
end

function MapUtils:IsPinDiscovered(mapID, entry)
	local key = Discovery.GetKey(mapID, entry)
	if key == nil then return true end

	return Discovery.GetStore()[key] == true
end

function MapUtils:FilterUnexploredPins(mapID, list)
	if list == nil or not Discovery.ready or MapUtils:IsDebug() then return list end
	local active = false
	for kind in pairs(Discovery.options) do
		if not Discovery.ShowsUnexplored(kind) then
			active = true
			break
		end
	end

	if not active then return list end
	local result = {}
	for _, entry in ipairs(list) do
		if Discovery.ShowsUnexplored(Discovery.GetKind(entry)) or MapUtils:IsPinDiscovered(mapID, entry) then tinsert(result, entry) end
	end

	if #result == 0 then return nil end

	return result
end

function MapUtils:RefreshExploredPins()
	MapUtils.OneMapPinCache = {}
	MapUtils:RefreshPins()
end

function Discovery.IsSecret(...)
	if issecretvalue == nil then return false end
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if issecretvalue(value) then return true end
	end

	return false
end

function Discovery.ScanMap(mapID, wx, wy, store, changed)
	local forever = MapUtils:IsForever()
	local list = MapUtils.BuildPinList(mapID, true, true, true, true, true, forever, forever, true)
	local radiusSq = Discovery.radius * Discovery.radius
	for _, entry in ipairs(list or {}) do
		local key = Discovery.GetKey(mapID, entry)
		if key ~= nil and store[key] == nil then
			local pos = MapUtils.GetEntryWorldPos(mapID, entry)
			if pos ~= nil then
				local dx, dy = pos.x - wx, pos.y - wy
				if dx * dx + dy * dy <= radiusSq then
					store[key] = true
					changed[Discovery.GetKind(entry)] = true
				end
			end
		end
	end
end

function Discovery.Scan()
	if not Discovery.ready or C_Map == nil or C_Map.GetBestMapForUnit == nil then return end
	if IsInInstance ~= nil and IsInInstance() then return end
	local mapID = C_Map.GetBestMapForUnit("player")
	local wx, wy = UnitPosition("player")
	if mapID == nil or wx == nil or wy == nil or Discovery.IsSecret(mapID, wx, wy) then return end
	local last = Discovery.last
	if last ~= nil and last.mapID == mapID and math.abs(last.x - wx) < Discovery.moveYards and math.abs(last.y - wy) < Discovery.moveYards then return end
	Discovery.last = {
		mapID = mapID,
		x = wx,
		y = wy
	}

	local store = Discovery.GetStore()
	local changed = {}
	local depth = 0
	while mapID ~= nil and depth < Discovery.maxDepth do
		local info = C_Map.GetMapInfo(mapID)
		if info == nil or info.mapType == nil or info.mapType < 2 then break end
		Discovery.ScanMap(mapID, wx, wy, store, changed)
		mapID = info.parentMapID
		depth = depth + 1
	end

	for kind in pairs(changed) do
		if not Discovery.ShowsUnexplored(kind) then
			MapUtils:RefreshExploredPins()
			break
		end
	end
end

Discovery.frame = CreateFrame("FRAME")
Discovery.frame:RegisterEvent("PLAYER_LOGIN")
Discovery.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Discovery.frame:SetScript(
	"OnEvent",
	function(_, event)
		if event == "PLAYER_LOGIN" then
			Discovery.ready = true
			if C_Timer ~= nil and C_Timer.NewTicker ~= nil then Discovery.ticker = C_Timer.NewTicker(Discovery.interval, Discovery.Scan) end
		end

		Discovery.last = nil
		Discovery.Scan()
	end
)
