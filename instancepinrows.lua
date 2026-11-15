local _, MapUtils = ...
MapUtils.INSTANCEPINS = MapUtils.INSTANCEPINS or {}
MapUtils.INSTANCEARTHEIGHTS = MapUtils.INSTANCEARTHEIGHTS or {}
local info = MapUtils.INSTANCEPININFO or {}
local keys = info.keys or {}
local raids = info.raids or {}
local bosses = info.bosses or {}
local quests = info.quests or {}
local function IsParked(x, y)
	local column = (x - 0.05) / 0.075
	local row = (y - 0.08) / 0.11
	return column > -0.01 and column < 7.01 and row > -0.01 and abs(column - floor(column + 0.5)) < 0.01 and abs(row - floor(row + 0.5)) < 0.01
end

local function BuildRow(art, entry)
	local kind, x, y, arg = entry[1], entry[2], entry[3], entry[4]
	if kind == "entrance" then return {"entrance", x, y, raids[art] and "raid" or nil} end
	if kind == "item" then return arg and {"item", x, y, arg} or nil end
	if kind == "level" then
		local key = arg and keys[arg]
		if key == nil then return nil end
		if entry[5] == true then return {"level", x, y, key, true} end
		return {"level", x, y, key}
	end

	if kind == "queststart" or kind == "questend" then
		if arg == nil then return nil end
		local quest = quests[arg] or {}
		if kind == "queststart" and quest[2] ~= nil then return {kind, x, y, arg, quest[1], quest[2]} end
		return {kind, x, y, arg, quest[1]}
	end

	if kind == "boss" then
		local boss = arg and bosses[arg]
		if boss == nil then return nil end
		if boss[5] ~= nil then MapUtils:AddName("deDE", boss[1], boss[5]) end
		return {"boss", x, y, arg, boss[1], boss[2], boss[3], boss[4]}
	end

	return nil
end

for art, entries in pairs(MapUtils.INSTANCEMAPPINS or {}) do
	local key = keys[art]
	if key ~= nil then
		local rows = {}
		for _, entry in ipairs(entries) do
			if not IsParked(entry[2], entry[3]) then
				local row = BuildRow(art, entry)
				if row ~= nil then tinsert(rows, row) end
			end
		end

		if #rows > 0 then MapUtils.INSTANCEPINS[key] = rows end
	end
end

for key, height in pairs(info.heights or {}) do
	MapUtils.INSTANCEARTHEIGHTS[key] = height
end
