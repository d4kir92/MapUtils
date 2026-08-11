local _, MapUtils = ...
MapUtils:SetAddonOutput("MapUtils", 134269)
local dungeonMaps = {}
local raidMaps = {}
-- Classic ERA Dungeons:
dungeonMaps[213] = {
	"Interface\\AddOns\\MapUtils\\media\\213" -- Ragefire Chasm
}

dungeonMaps[219] = {
	"Interface\\AddOns\\MapUtils\\media\\219" -- Zul'Farrak
}

dungeonMaps[220] = {
	"Interface\\AddOns\\MapUtils\\media\\220" -- The Temple of Atal'Hakkar
}

dungeonMaps[221] = {
	"Interface\\AddOns\\MapUtils\\media\\221" -- Blackfathom Deeps - The Pool of Ask'Ar
}

dungeonMaps[222] = {
	"Interface\\AddOns\\MapUtils\\media\\222" -- Blackfathom Deeps - Moonshrine Sanctum
}

dungeonMaps[223] = {
	"Interface\\AddOns\\MapUtils\\media\\223" -- Blackfathom Deeps - The Forgotten Pool
}

dungeonMaps[225] = {
	"Interface\\AddOns\\MapUtils\\media\\225" -- The Stockade
}

dungeonMaps[226] = {
	"Interface\\AddOns\\MapUtils\\media\\226" -- Gnomeregan - The Hall of Gears
}

dungeonMaps[227] = {
	"Interface\\AddOns\\MapUtils\\media\\227" -- Gnomeregan - The Dormitory
}

dungeonMaps[228] = {
	"Interface\\AddOns\\MapUtils\\media\\228" -- Gnomeregan - Launch Bay
}

dungeonMaps[229] = {
	"Interface\\AddOns\\MapUtils\\media\\229" -- Gnomeregan - Tinkers' Court
}

dungeonMaps[230] = {
	"Interface\\AddOns\\MapUtils\\media\\230" -- Uldaman - Hall of the Keepers
}

dungeonMaps[231] = {
	"Interface\\AddOns\\MapUtils\\media\\231" -- Uldaman - Khaz'Goroth's Seat
}

dungeonMaps[234] = {
	"Interface\\AddOns\\MapUtils\\media\\234" -- Dire Maul
}

dungeonMaps[235] = {
	"Interface\\AddOns\\MapUtils\\media\\235" -- Dire Maul - Gordok Commons
}

dungeonMaps[236] = {
	"Interface\\AddOns\\MapUtils\\media\\236" -- Dire Maul - Capital Gardens
}

dungeonMaps[237] = {
	"Interface\\AddOns\\MapUtils\\media\\237" -- Dire Maul - Court of the Highborne
}

dungeonMaps[238] = {
	"Interface\\AddOns\\MapUtils\\media\\238" -- Dire Maul - Prison of Immol'Thar
}

dungeonMaps[239] = {
	"Interface\\AddOns\\MapUtils\\media\\239" -- Dire Maul - Warpwood Quarter
}

dungeonMaps[240] = {
	"Interface\\AddOns\\MapUtils\\media\\240" -- Dire Maul - The Shrine of Eldretharr
}

dungeonMaps[242] = {
	"Interface\\AddOns\\MapUtils\\media\\242" -- Blackrock Depths - Detention Block
}

dungeonMaps[243] = {
	"Interface\\AddOns\\MapUtils\\media\\243" -- Blackrock Depths - Shadowforge City
}

dungeonMaps[250] = {
	"Interface\\AddOns\\MapUtils\\media\\250" -- Blackrock Spire - Tazz'Alor
}

dungeonMaps[251] = {
	"Interface\\AddOns\\MapUtils\\media\\251" -- Blackrock Spire - Skitterweb Tunnels
}

dungeonMaps[252] = {
	"Interface\\AddOns\\MapUtils\\media\\252" -- Blackrock Spire - Hordemar City
}

dungeonMaps[253] = {
	"Interface\\AddOns\\MapUtils\\media\\253" -- Blackrock Spire - Hall of Blackhand
}

dungeonMaps[254] = {
	"Interface\\AddOns\\MapUtils\\media\\254" -- Blackrock Spire - Halycon's Lair
}

dungeonMaps[255] = {
	"Interface\\AddOns\\MapUtils\\media\\255" -- Blackrock Spire - Chamber of Battle
}

dungeonMaps[279] = {
	"Interface\\AddOns\\MapUtils\\media\\279" -- Wailing Caverns
}

dungeonMaps[280] = {
	"Interface\\AddOns\\MapUtils\\media\\280" -- Maraudon - Caverns of Maraudon
}

dungeonMaps[281] = {
	"Interface\\AddOns\\MapUtils\\media\\281" -- Maraudon - Zaetar's Grave
}

dungeonMaps[291] = {
	"Interface\\AddOns\\MapUtils\\media\\291" -- The Deadmines
}

dungeonMaps[292] = {
	"Interface\\AddOns\\MapUtils\\media\\292" -- The Deadmines - Ironclad Cove
}

dungeonMaps[300] = {
	"Interface\\AddOns\\MapUtils\\media\\300" -- Razorfen Downs
}

dungeonMaps[301] = {
	"Interface\\AddOns\\MapUtils\\media\\301" -- Razorfen Kraul
}

dungeonMaps[302] = {
	"Interface\\AddOns\\MapUtils\\media\\302" -- Scarlet Monastery - Graveyard
}

dungeonMaps[303] = {
	"Interface\\AddOns\\MapUtils\\media\\303" -- Scarlet Monastery - Library
}

dungeonMaps[304] = {
	"Interface\\AddOns\\MapUtils\\media\\304" -- Scarlet Monastery - Armory
}

dungeonMaps[305] = {
	"Interface\\AddOns\\MapUtils\\media\\305" -- Scarlet Monastery - Cathedral
}

dungeonMaps[306] = {
	"Interface\\AddOns\\MapUtils\\media\\306" -- Scholomance - The Reliquary
}

dungeonMaps[307] = {
	"Interface\\AddOns\\MapUtils\\media\\307" -- Scholomance - Chamber of Summoning
}

dungeonMaps[308] = {
	"Interface\\AddOns\\MapUtils\\media\\308" -- Scholomance - The Upper Study
}

dungeonMaps[309] = {
	"Interface\\AddOns\\MapUtils\\media\\309" -- Scholomance - Headmaster's Study
}

dungeonMaps[310] = {
	"Interface\\AddOns\\MapUtils\\media\\310" -- Shadowfang Keep - The Courtyard
}

dungeonMaps[311] = {
	"Interface\\AddOns\\MapUtils\\media\\311" -- Shadowfang Keep - Dining Hall
}

dungeonMaps[312] = {
	"Interface\\AddOns\\MapUtils\\media\\312" -- Shadowfang Keep - The Vacant Den
}

dungeonMaps[313] = {
	"Interface\\AddOns\\MapUtils\\media\\313" -- Shadowfang Keep - Lower Observatory
}

dungeonMaps[314] = {
	"Interface\\AddOns\\MapUtils\\media\\314" -- Shadowfang Keep - Upper Observatory
}

dungeonMaps[315] = {
	"Interface\\AddOns\\MapUtils\\media\\315" -- Shadowfang Keep - Lord Godfrey's Chamber
}

dungeonMaps[316] = {
	"Interface\\AddOns\\MapUtils\\media\\316" -- Shadowfang Keep - The Wall Walk
}

dungeonMaps[317] = {
	"Interface\\AddOns\\MapUtils\\media\\317" -- Stratholme - Crusader's Square
}

dungeonMaps[318] = {
	"Interface\\AddOns\\MapUtils\\media\\318" -- Stratholme - The Gauntlet
}

-- Classic ERA Raids:
raidMaps[232] = {
	"Interface\\AddOns\\MapUtils\\media\\232" -- Molten Core
}

raidMaps[233] = {
	"Interface\\AddOns\\MapUtils\\media\\233" -- Zul'Gurub
}

raidMaps[247] = {
	"Interface\\AddOns\\MapUtils\\media\\247" -- Ruins of Ahn'Qiraj
}

raidMaps[248] = {
	"Interface\\AddOns\\MapUtils\\media\\248" -- Onyxia's Lair
}

raidMaps[287] = {
	"Interface\\AddOns\\MapUtils\\media\\287" -- Blackwing Lair - Dragonmaw Garrison
}

raidMaps[288] = {
	"Interface\\AddOns\\MapUtils\\media\\288" -- Blackwing Lair - Halls of Strife
}

raidMaps[289] = {
	"Interface\\AddOns\\MapUtils\\media\\289" -- Blackwing Lair - Crimson Laboratories
}

raidMaps[290] = {
	"Interface\\AddOns\\MapUtils\\media\\290" -- Blackwing Lair - Nefarian's Lair
}

raidMaps[319] = {
	"Interface\\AddOns\\MapUtils\\media\\319" -- Ahn'Qiraj - The Hive Undergrounds
}

raidMaps[320] = {
	"Interface\\AddOns\\MapUtils\\media\\320" -- Ahn'Qiraj - The Temple Gates
}

raidMaps[321] = {
	"Interface\\AddOns\\MapUtils\\media\\321" -- Ahn'Qiraj - Vault of C'Thun
}

-- TBC Dungeons:
dungeonMaps[246] = {
	"Interface\\AddOns\\MapUtils\\media\\246" -- The Shattered Halls
}

dungeonMaps[256] = {
	"Interface\\AddOns\\MapUtils\\media\\256" -- Auchenaikrypta
}

dungeonMaps[257] = {
	"Interface\\AddOns\\MapUtils\\media\\257" -- Auchenaikrypta
}

dungeonMaps[258] = {
	"Interface\\AddOns\\MapUtils\\media\\258" -- Sethekkhallen
}

dungeonMaps[259] = {
	"Interface\\AddOns\\MapUtils\\media\\259" -- Sethekkhallen
}

dungeonMaps[260] = {
	"Interface\\AddOns\\MapUtils\\media\\260" -- Schattenlabyrinth
}

dungeonMaps[261] = {
	"Interface\\AddOns\\MapUtils\\media\\261" -- Der Blutkessel
}

dungeonMaps[262] = {
	"Interface\\AddOns\\MapUtils\\media\\262" -- The Underbog
}

dungeonMaps[263] = {
	"Interface\\AddOns\\MapUtils\\media\\263" -- The Steamvault
}

dungeonMaps[265] = {
	"Interface\\AddOns\\MapUtils\\media\\265" -- The Slave Pens
}

dungeonMaps[266] = {
	"Interface\\AddOns\\MapUtils\\media\\266" -- The Botanica
}

dungeonMaps[267] = {
	"Interface\\AddOns\\MapUtils\\media\\267" -- The Mechanar
}

dungeonMaps[268] = {
	"Interface\\AddOns\\MapUtils\\media\\268" -- The Mechanar
}

dungeonMaps[269] = {
	"Interface\\AddOns\\MapUtils\\media\\269" -- The Arcatraz
}

dungeonMaps[270] = {
	"Interface\\AddOns\\MapUtils\\media\\270" -- The Arcatraz
}

dungeonMaps[271] = {
	"Interface\\AddOns\\MapUtils\\media\\271" -- The Arcatraz
}

dungeonMaps[272] = {
	"Interface\\AddOns\\MapUtils\\media\\272" -- Managruft
}

dungeonMaps[273] = {
	"Interface\\AddOns\\MapUtils\\media\\273" -- The Black Morass
}

dungeonMaps[274] = {
	"Interface\\AddOns\\MapUtils\\media\\274" -- Old Hillsbrad Foothills
}

dungeonMaps[347] = {
	"Interface\\AddOns\\MapUtils\\media\\347" -- Höllenfeuerbollwerk
}

-- TBC Raids:
raidMaps[330] = {
	"Interface\\AddOns\\MapUtils\\media\\330" -- Gruul's Lair
}

raidMaps[331] = {
	"Interface\\AddOns\\MapUtils\\media\\331" -- Magtheridon's Lair
}

raidMaps[350] = {
	"Interface\\AddOns\\MapUtils\\media\\350" -- Karazhan
}

raidMaps[351] = {
	"Interface\\AddOns\\MapUtils\\media\\351" -- Karazhan
}

raidMaps[352] = {
	"Interface\\AddOns\\MapUtils\\media\\352" -- Karazhan
}

raidMaps[353] = {
	"Interface\\AddOns\\MapUtils\\media\\353" -- Karazhan
}

raidMaps[354] = {
	"Interface\\AddOns\\MapUtils\\media\\354" -- Karazhan
}

raidMaps[355] = {
	"Interface\\AddOns\\MapUtils\\media\\355" -- Karazhan
}

raidMaps[356] = {
	"Interface\\AddOns\\MapUtils\\media\\356" -- Karazhan
}

raidMaps[357] = {
	"Interface\\AddOns\\MapUtils\\media\\357" -- Karazhan
}

raidMaps[358] = {
	"Interface\\AddOns\\MapUtils\\media\\358" -- Karazhan
}

raidMaps[359] = {
	"Interface\\AddOns\\MapUtils\\media\\359" -- Karazhan
}

raidMaps[360] = {
	"Interface\\AddOns\\MapUtils\\media\\360" -- Karazhan
}

raidMaps[361] = {
	"Interface\\AddOns\\MapUtils\\media\\361" -- Karazhan
}

raidMaps[362] = {
	"Interface\\AddOns\\MapUtils\\media\\362" -- Karazhan
}

raidMaps[363] = {
	"Interface\\AddOns\\MapUtils\\media\\363" -- Karazhan
}

raidMaps[364] = {
	"Interface\\AddOns\\MapUtils\\media\\364" -- Karazhan
}

raidMaps[365] = {
	"Interface\\AddOns\\MapUtils\\media\\365" -- Karazhan
}

raidMaps[366] = {
	"Interface\\AddOns\\MapUtils\\media\\366" -- Karazhan
}

local instanceToMap = {}
instanceToMap[389] = 213 -- Ragefire Chasm
instanceToMap[209] = 219 -- Zul'Farrak
instanceToMap[109] = 220 -- The Temple of Atal'Hakkar
instanceToMap[48] = 221 -- Blackfathom Deeps
instanceToMap[34] = 225 -- The Stockade
instanceToMap[90] = 226 -- Gnomeregan
instanceToMap[70] = 230 -- Uldaman
instanceToMap[429] = 234 -- Dire Maul
instanceToMap[230] = 242 -- Blackrock Depths
instanceToMap[229] = 250 -- Blackrock Spire
instanceToMap[43] = 279 -- Wailing Caverns
instanceToMap[349] = 280 -- Maraudon
instanceToMap[36] = 291 -- The Deadmines
instanceToMap[129] = 300 -- Razorfen Downs
instanceToMap[47] = 301 -- Razorfen Kraul
instanceToMap[189] = 302 -- Scarlet Monastery
instanceToMap[289] = 306 -- Scholomance
instanceToMap[33] = 310 -- Shadowfang Keep
instanceToMap[329] = 317 -- Stratholme
instanceToMap[409] = 232 -- Molten Core
instanceToMap[309] = 233 -- Zul'Gurub
instanceToMap[509] = 247 -- Ruins of Ahn'Qiraj
instanceToMap[249] = 248 -- Onyxia's Lair
instanceToMap[469] = 287 -- Blackwing Lair
instanceToMap[531] = 319 -- Temple of Ahn'Qiraj
instanceToMap[540] = 246 -- The Shattered Halls
instanceToMap[542] = 261 -- The Blood Furnace
instanceToMap[543] = 347 -- Hellfire Ramparts
instanceToMap[545] = 263 -- The Steamvault
instanceToMap[546] = 262 -- The Underbog
instanceToMap[547] = 265 -- The Slave Pens
instanceToMap[552] = 269 -- The Arcatraz
instanceToMap[553] = 266 -- The Botanica
instanceToMap[554] = 267 -- The Mechanar
instanceToMap[555] = 260 -- Shadow Labyrinth
instanceToMap[556] = 258 -- Sethekk Halls
instanceToMap[557] = 272 -- Mana-Tombs
instanceToMap[558] = 256 -- Auchenai Crypts
instanceToMap[269] = 273 -- The Black Morass
instanceToMap[560] = 274 -- Old Hillsbrad Foothills
instanceToMap[565] = 330 -- Gruul's Lair
instanceToMap[544] = 331 -- Magtheridon's Lair
instanceToMap[532] = 350 -- Karazhan
local missingMaps = {}
hooksecurefunc(WorldMapFrame, "Show", function()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
		if instanceMapID and instanceToMap[instanceMapID] then mapID = instanceToMap[instanceMapID] end
	end

	if mapID == nil then return end
	if dungeonMaps[mapID] == nil and raidMaps[mapID] == nil then
		local inInstance, instanceType = IsInInstance()
		if inInstance and missingMaps[mapID] == nil then
			missingMaps[mapID] = true
			if instanceType == "raid" and raidMaps[mapID] == nil then
				MapUtils:INFO("Missing Raid Map - zoneID: " .. mapID .. " (Send to Developer: zoneID and RaidName)")
			elseif instanceType == "party" and dungeonMaps[mapID] == nil then
				MapUtils:INFO("Missing Dungeon Map - zoneID: " .. mapID .. " (Send to Developer: zoneID and DungeonName)")
			end
		end
		return
	end

	WorldMapFrame.mapID = mapID
	WorldMapFrame:SetMapID(mapID)
	WorldMapFrame:RefreshDetailLayers()
end)

local oldGetMapArtLayers = C_Map.GetMapArtLayers
function C_Map.GetMapArtLayers(mapID)
	if mapID == nil then return oldGetMapArtLayers(mapID) end
	if dungeonMaps[mapID] then
		local num = dungeonMaps[mapID] and #dungeonMaps[mapID] or 1
		local result = {}
		for i, map in pairs(dungeonMaps[mapID]) do
			tinsert(result, {
				["layerWidth"] = 1024 * num / 4,
				["layerHeight"] = 683 / 4,
				["tileWidth"] = 1024 / 4,
				["tileHeight"] = 683 / 4,
				["minScale"] = 1,
				["maxScale"] = 2.5,
				["additionalZoomSteps"] = 6,
			})
		end
		return result
	elseif raidMaps[mapID] then
		local num = raidMaps[mapID] and #raidMaps[mapID] or 1
		local result = {}
		for i, map in pairs(raidMaps[mapID]) do
			tinsert(result, {
				["layerWidth"] = 1024 * num / 4,
				["layerHeight"] = 683 / 4,
				["tileWidth"] = 1024 / 4,
				["tileHeight"] = 683 / 4,
				["minScale"] = 1,
				["maxScale"] = 2.5,
				["additionalZoomSteps"] = 6,
			})
		end
		return result
	end
	return oldGetMapArtLayers(mapID)
end

local oldGetMapArtLayerTextures = C_Map.GetMapArtLayerTextures
function C_Map.GetMapArtLayerTextures(uiMapID, layerIndex)
	local textures = oldGetMapArtLayerTextures(uiMapID, layerIndex)
	if dungeonMaps[uiMapID] then
		textures = {}
		for i, map in pairs(dungeonMaps[uiMapID]) do
			tinsert(textures, map)
		end
	elseif raidMaps[uiMapID] then
		textures = {}
		for i, map in pairs(raidMaps[uiMapID]) do
			tinsert(textures, map)
		end
	end
	return textures
end
