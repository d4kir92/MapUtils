local _, MapUtils = ...
local WORLD = 947
local CONTINENTS = {1414, 1415, 1945}
local SPACE_OF = {
	[1414] = WORLD,
	[1415] = WORLD,
	[1945] = 1945
}
local MODE_OFF = "OFF"
local MODE_AREAS = "AREAS"
local MODE_FULL = "FULL"
local SAMPLE_STEPS = 9
local FRAME_LEVEL_OFFSET = 5
local NO_TINT = {1, 1, 1, 1}
local MASK_PATH = "Interface\\AddOns\\MapUtils\\media\\zonemasks\\"
local EDGE_PATH = MASK_PATH .. "edge"
local TERRAIN_FADE_START = 660
local TERRAIN_FADE_END = 800
local ROUND_PATH = MASK_PATH .. "round"
local TILE_SHIFTS = {
	["tbc"] = {
		[1414530] = {165.6, 0}
	}
}
local ART_SHIFTS = {
	["tbc"] = {
		[1943] = -0.061,
		[1947] = -0.235,
		[1950] = -0.0761
	}
}
local CITY_MAPS = {
	[1453] = true,
	[1454] = true,
	[1455] = true,
	[1456] = true,
	[1457] = true,
	[1458] = true,
	[1947] = true,
	[1954] = true,
	[1955] = true
}
local UNDERGROUND = {
	[1455] = {"ironforge-detail", -4350, -600},
	[1458] = {"undercity-detail", 2124, 924}
}
local HIGHLIGHT_CLIP = {
	[1941] = true,
	[1942] = true,
	[1957] = true
}
local CITY_RING = {0.5, 0.75, 1}
local CITY_RING_STEPS = 16
local container = nil
local zones = {}
local cities = {}
local hiddenMaskGroups = {}
local maskFiles = {}

local function IsMapMaskGroupHidden(group)
	return hiddenMaskGroups[group] == true
end
local mapMasks = setmetatable({}, {__mode = "k"})

local function IsMapMaskHidden(mask)
	return IsMapMaskGroupHidden(mask.mapMaskGroup) or maskFiles[mask.mapMaskFile] == true
end

local function SyncMapMask(texture, masks, mask)
	local attached = not IsMapMaskHidden(mask)
	if attached == masks[mask] then return end
	if attached then
		texture:AddMaskTexture(mask)
	else
		texture:RemoveMaskTexture(mask)
	end

	masks[mask] = attached
end

local function SetMapMaskTexture(mask, file, wrap)
	local wasHidden = IsMapMaskHidden(mask)
	mask.mapMaskFile = file
	if maskFiles[file] == nil then
		maskFiles[file] = false
		MapUtils.debugMaskFileRevision = (MapUtils.debugMaskFileRevision or 0) + 1
	end

	mask:SetTexture(file, wrap, wrap)
	if wasHidden == IsMapMaskHidden(mask) then return end
	for texture, masks in pairs(mapMasks) do
		if masks[mask] ~= nil then SyncMapMask(texture, masks, mask) end
	end
end

local function AddMapMask(texture, mask)
	local masks = mapMasks[texture]
	if masks == nil then
		masks = {}
		mapMasks[texture] = masks
	end

	if masks[mask] == nil then masks[mask] = false end
	SyncMapMask(texture, masks, mask)
end

local function RemoveMapMask(texture, mask)
	local masks = mapMasks[texture]
	if masks == nil then return end
	if masks[mask] then texture:RemoveMaskTexture(mask) end
	masks[mask] = nil
end

function MapUtils:IsDebugMapMaskGroupHidden(group)
	return IsMapMaskGroupHidden(group)
end

function MapUtils:SetDebugMapMaskGroupsHidden(groups, hidden)
	local changed = {}
	for _, group in ipairs(groups) do
		hiddenMaskGroups[group] = hidden and true or nil
		changed[group] = true
	end

	for texture, masks in pairs(mapMasks) do
		for mask in pairs(masks) do
			if changed[mask.mapMaskGroup] then SyncMapMask(texture, masks, mask) end
		end
	end
end

function MapUtils:SetDebugMapMaskFileHidden(file, hidden)
	maskFiles[file] = hidden
	for texture, masks in pairs(mapMasks) do
		for mask in pairs(masks) do
			if mask.mapMaskFile == file then SyncMapMask(texture, masks, mask) end
		end
	end
end

local unders = {}
local masks = {}
local hooked = false
local preload = {}
local base = {
	["continents"] = {},
	["world"] = {}
}

local function NewArt(mapID)
	local frame = CreateFrame("FRAME", nil, container)
	local edge = frame:CreateMaskTexture()
	edge.mapMaskGroup = mapID
	SetMapMaskTexture(edge, EDGE_PATH, "CLAMPTOBLACKADDITIVE")
	edge:SetAllPoints(frame)

	return {
		["frame"] = frame,
		["edge"] = edge,
		["textures"] = {},
		["count"] = 0
	}
end

local function GetZone(mapID)
	local zone = zones[mapID]
	if zone == nil then
		zone = NewArt(mapID)
		zones[mapID] = zone
	end

	return zone
end

local function GetUnder(mapID)
	local under = unders[mapID]
	if under == nil then
		under = NewArt(mapID)
		unders[mapID] = under
	end

	return under
end

local function GetCity(mapID)
	local city = cities[mapID]
	if city == nil then
		city = NewArt(mapID)
		city.mask = city.frame:CreateMaskTexture()
		city.mask.mapMaskGroup = mapID
		city.maskPath = CITY_MAPS[mapID] and MASK_PATH .. "city_" .. mapID or ROUND_PATH
		SetMapMaskTexture(city.mask, city.maskPath, "CLAMPTOBLACKADDITIVE")
		city.mask:SetAllPoints(city.frame)
		city.masked = true
		cities[mapID] = city
	end

	return city
end

local function ClearZone(zone)
	for i = 1, zone.count do
		zone.textures[i]:Hide()
	end

	zone.count = 0
	zone.frame:Hide()
end

local function ClearAll()
	for _, zone in pairs(zones) do
		ClearZone(zone)
	end

	for _, under in pairs(unders) do
		ClearZone(under)
	end

	for _, city in pairs(cities) do
		ClearZone(city)
	end

	if container then container:Hide() end
end

local function AcquireTexture(zone)
	zone.count = zone.count + 1
	local texture = zone.textures[zone.count]
	if texture == nil then
		texture = zone.frame:CreateTexture(nil, "ARTWORK")
		zone.textures[zone.count] = texture
		AddMapMask(texture, zone.edge)
		if zone.masked then AddMapMask(texture, zone.mask) end
		if zone.hmasked then AddMapMask(texture, zone.hmask) end
	end

	return texture
end

local function GetFileSize(pixels)
	local size = 16
	while size < pixels do
		size = size * 2
	end

	return size
end

local function GetTileSize(total, tile, index, count)
	if index < count then return tile, tile end
	local pixels = total % tile
	if pixels == 0 then pixels = tile end

	return pixels, GetFileSize(pixels)
end

local function PlaceTile(zone, fileID, x, y, pixelWidth, pixelHeight, fileWidth, fileHeight, drawLayer, tint)
	local texture = AcquireTexture(zone)
	texture:SetDrawLayer(drawLayer, 0)
	texture:SetTexture(fileID, nil, nil, "TRILINEAR")
	texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
	texture:SetSize(pixelWidth * zone.scaleX, pixelHeight * zone.scaleY)
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", zone.frame, "TOPLEFT", x * zone.scaleX, -y * zone.scaleY)
	texture:SetDesaturated(tint[5] == true)
	texture:SetVertexColor(tint[1], tint[2], tint[3], tint[4])
	texture:Show()
end

local function DrawBase(zone, mapID, layer)
	local files = C_Map.GetMapArtLayerTextures(mapID, 1)
	if files == nil then return end
	local cols = math.ceil(layer.layerWidth / layer.tileWidth)
	local rows = math.ceil(layer.layerHeight / layer.tileHeight)
	for row = 1, rows do
		local pixelHeight, fileHeight = GetTileSize(layer.layerHeight, layer.tileHeight, row, rows)
		for col = 1, cols do
			local fileID = files[(row - 1) * cols + col]
			if fileID ~= nil then
				local pixelWidth, fileWidth = GetTileSize(layer.layerWidth, layer.tileWidth, col, cols)
				PlaceTile(zone, fileID, layer.tileWidth * (col - 1), layer.tileHeight * (row - 1), pixelWidth, pixelHeight, fileWidth, fileHeight, "BACKGROUND", NO_TINT)
			end
		end
	end
end

local function DrawOverlays(zone, mapID, layer)
	local artID = C_Map.GetMapArtID(mapID)
	local overlays = artID and MapUtils.GetRevealOverlays and MapUtils:GetRevealOverlays(artID)
	if overlays == nil then return end
	local explored = {}
	local exploredTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID)
	if exploredTextures ~= nil then
		for _, info in ipairs(exploredTextures) do
			explored[info.offsetX .. ":" .. info.offsetY] = true
		end
	end

	local tint = MapUtils.GetRevealTint and MapUtils:GetRevealTint(mapID)
	for _, overlay in ipairs(overlays) do
		local isExplored = explored[overlay.offsetX .. ":" .. overlay.offsetY] == true
		local overlayTint = isExplored and NO_TINT or tint
		if overlayTint ~= nil then
			local wide = math.ceil(overlay.width / layer.tileWidth)
			local tall = math.ceil(overlay.height / layer.tileHeight)
			for row = 1, tall do
				local pixelHeight, fileHeight = GetTileSize(overlay.height, layer.tileHeight, row, tall)
				for col = 1, wide do
					local fileID = overlay.files[(row - 1) * wide + col]
					if fileID ~= nil then
						local pixelWidth, fileWidth = GetTileSize(overlay.width, layer.tileWidth, col, wide)
						PlaceTile(zone, fileID, overlay.offsetX + layer.tileWidth * (col - 1), overlay.offsetY + layer.tileHeight * (row - 1), pixelWidth, pixelHeight, fileWidth, fileHeight, "ARTWORK", overlayTint)
					end
				end
			end
		end
	end
end

local function GetMaskName(fileID)
	local flavor = MapUtils.GetRevealFlavor ~= nil and MapUtils:GetRevealFlavor()
	local files = flavor and MapUtils.ZONEMASKFILES and MapUtils.ZONEMASKFILES[flavor]
	local name = files and files[fileID]
	if name ~= nil then return name or nil end
	if MapUtils.ZONEMASKS and MapUtils.ZONEMASKS[fileID] then return tostring(fileID) end

	return nil
end

local function RectOn(mapID, space)
	if mapID == space then return 0, 1, 0, 1 end

	return C_Map.GetMapRectOnMap(mapID, space)
end

local function FindHighlight(continentID, mapID, left, right, top, bottom)
	for i = 0, SAMPLE_STEPS * SAMPLE_STEPS - 1 do
		local step = (i % 2 == 0) and (i / 2) or (SAMPLE_STEPS * SAMPLE_STEPS - 1 - (i - 1) / 2)
		local x = left + (right - left) * ((step % SAMPLE_STEPS) + 0.5) / SAMPLE_STEPS
		local y = top + (bottom - top) * (math.floor(step / SAMPLE_STEPS) + 0.5) / SAMPLE_STEPS
		local info = C_Map.GetMapInfoAtPosition(continentID, x, y)
		if info ~= nil and (info.mapID == mapID or (MapUtils.IsMapInside ~= nil and MapUtils.IsMapInside(info.mapID, mapID))) then
			local fileDataID, _, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = C_Map.GetMapHighlightInfoAtPosition(continentID, x, y)
			local file = fileDataID and GetMaskName(fileDataID)
			if file and textureX > 0 and textureY > 0 and texPercentageX > 0 and texPercentageY > 0 then
				return {
					["file"] = file,
					["x"] = scrollChildX,
					["y"] = scrollChildY,
					["width"] = textureX / texPercentageX,
					["height"] = textureY / texPercentageY
				}
			end

			return false
		end
	end

	return false
end

local function GetHighlight(continentID, mapID, left, right, top, bottom)
	local key = continentID .. ":" .. mapID
	if masks[key] == nil then masks[key] = FindHighlight(continentID, mapID, left, right, top, bottom) end

	return masks[key]
end

local function SetMasked(zone, masked)
	if zone.masked == masked then return end
	zone.masked = masked
	for i = 1, #zone.textures do
		if masked then
			AddMapMask(zone.textures[i], zone.mask)
		else
			RemoveMapMask(zone.textures[i], zone.mask)
		end
	end
end

local function SetHighlightMasked(zone, masked)
	if zone.hmasked == masked then return end
	zone.hmasked = masked
	for i = 1, #zone.textures do
		if masked then
			AddMapMask(zone.textures[i], zone.hmask)
		else
			RemoveMapMask(zone.textures[i], zone.hmask)
		end
	end
end

local function ApplyMask(zone, highlight, left, top, width, height)
	if zone.hmask == nil then zone.hmask = zone.frame:CreateMaskTexture() end
	SetHighlightMasked(zone, true)
	zone.hmask.mapMaskGroup = zone.edge.mapMaskGroup
	zone.highlightPath = MASK_PATH .. highlight.file
	SetMapMaskTexture(zone.hmask, zone.highlightPath, "CLAMPTOBLACKADDITIVE")
	zone.hmask:SetSize(highlight.width * width, highlight.height * height)
	zone.hmask:ClearAllPoints()
	zone.hmask:SetPoint("TOPLEFT", zone.frame, "TOPLEFT", (highlight.x - left) * width, -(highlight.y - top) * height)
end

local function GetArtMask(mapID)
	local flavor = MapUtils.GetRevealFlavor ~= nil and MapUtils:GetRevealFlavor()
	local list = flavor and MapUtils.ZONEARTMASKS and MapUtils.ZONEARTMASKS[flavor]
	local artID = list and C_Map.GetMapArtID(mapID)

	return artID and list[artID] or nil
end

local function ArtRect(mapID, space)
	local left, right, top, bottom = RectOn(mapID, space)
	if left == nil then return nil end
	local flavorShifts = ART_SHIFTS[MapUtils:GetFlavor() or ""]
	local shift = flavorShifts and flavorShifts[mapID] and flavorShifts[mapID] * (bottom - top) or 0

	return left, right, top + shift, bottom + shift, shift
end

local function DrawZone(continentID, continentRect, mapID, mode, width, height)
	local left, right, top, bottom, shift = ArtRect(mapID, container.space)
	if left == nil or right <= left or bottom <= top then return end
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	if layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 or layer.layerHeight <= 0 then return end
	local zone = GetZone(mapID)
	local frameWidth = (right - left) * width
	local frameHeight = (bottom - top) * height
	zone.scaleX = frameWidth / layer.layerWidth
	zone.scaleY = frameHeight / layer.layerHeight
	zone.frame:ClearAllPoints()
	zone.frame:SetPoint("TOPLEFT", container, "TOPLEFT", left * width, -top * height)
	zone.frame:SetSize(frameWidth, frameHeight)
	local highlight = false
	local artMask = mode == MODE_FULL and GetArtMask(mapID)
	if mode == MODE_FULL and (not artMask or HIGHLIGHT_CLIP[mapID]) then
		local l, r, t, b = C_Map.GetMapRectOnMap(mapID, continentID)
		if l ~= nil and r > l and b > t then highlight = GetHighlight(continentID, mapID, l, r, t, b) end
	end

	if artMask then
		if zone.mask == nil then zone.mask = zone.frame:CreateMaskTexture() end
		zone.mask.mapMaskGroup = mapID
		SetMasked(zone, true)
		zone.maskPath = MASK_PATH .. artMask
		SetMapMaskTexture(zone.mask, zone.maskPath, "CLAMPTOBLACKADDITIVE")
		zone.mask:ClearAllPoints()
		zone.mask:SetAllPoints(zone.frame)
	else
		SetMasked(zone, false)
	end

	if not highlight then
		SetHighlightMasked(zone, false)
	else
		local continentWidth, continentHeight = continentRect[2] - continentRect[1], continentRect[4] - continentRect[3]
		ApplyMask(
			zone,
			{
				["file"] = highlight.file,
				["x"] = continentRect[1] + highlight.x * continentWidth,
				["y"] = continentRect[3] + highlight.y * continentHeight + shift,
				["width"] = highlight.width * continentWidth,
				["height"] = highlight.height * continentHeight
			},
			left,
			top,
			width,
			height
		)
	end

	if artMask or highlight then
		DrawBase(zone, mapID, layer)
		local geometry = base.continents[continentID] and base.continents[continentID].maskGeometry
		if geometry ~= nil then
			local under = GetUnder(mapID)
			if under.mask == nil then under.mask = under.frame:CreateMaskTexture() end
			under.mask.mapMaskGroup = WORLD
			under.maskPath = geometry[1]
			SetMapMaskTexture(under.mask, under.maskPath, "CLAMPTOBLACKADDITIVE")
			under.mask:SetSize(geometry[2], geometry[3])
			under.mask:ClearAllPoints()
			under.mask:SetPoint("TOPLEFT", container, "TOPLEFT", geometry[4], geometry[5])
			SetMasked(under, true)
			under.scaleX, under.scaleY = zone.scaleX, zone.scaleY
			under.frame:ClearAllPoints()
			under.frame:SetAllPoints(zone.frame)
			DrawBase(under, mapID, layer)
			under.frame:Show()
		end
	end

	DrawOverlays(zone, mapID, layer)
	zone.frame:Show()
end

local insideCache = {}
local function IsInside(mapID, ancestorID)
	if mapID == nil or ancestorID == nil then return false end
	local cached = insideCache[mapID]
	if cached ~= nil and cached[ancestorID] ~= nil then return cached[ancestorID] end
	local info = C_Map.GetMapInfo(mapID)
	if info == nil then return false end
	local result = false
	local guard = 0
	while info ~= nil and info.parentMapID ~= nil and info.parentMapID > 0 and guard < 10 do
		if info.parentMapID == ancestorID then
			result = true
			break
		end

		info = C_Map.GetMapInfo(info.parentMapID)
		guard = guard + 1
	end

	if cached == nil then
		cached = {}
		insideCache[mapID] = cached
	end

	cached[ancestorID] = result

	return result
end

MapUtils.IsMapInside = IsInside
local function HasArt(mapID)
	local zone = zones[mapID]

	return zone ~= nil and zone.count > 0
end

local function GetContinent(mapID)
	for _, continentID in ipairs(CONTINENTS) do
		if mapID == continentID or IsInside(mapID, continentID) then return continentID end
	end

	return nil
end

function MapUtils:GetDebugMapMaskFiles()
	local files = {}
	local function Add(file)
		if file == nil or files[file] then return end
		local name = type(file) == "number" and tostring(file) or file:match("[^\\]+$") .. ".blp"
		files[file] = {file = file, name = name, hidden = maskFiles[file] == true}
	end

	Add(EDGE_PATH)
	Add(ROUND_PATH)
	for file in pairs(maskFiles) do Add(file) end
	for mapID in pairs(CITY_MAPS) do Add(MASK_PATH .. "city_" .. mapID) end
	local flavor = self.GetRevealFlavor and self:GetRevealFlavor()
	for fileID in pairs(self.ZONEMASKS or {}) do
		local name = GetMaskName(fileID)
		if name then Add(MASK_PATH .. name) end
	end

	for _, name in pairs(self.ZONEMASKFILES and self.ZONEMASKFILES[flavor] or {}) do
		if name then Add(MASK_PATH .. name) end
	end

	for _, name in pairs(self.ZONEARTMASKS and self.ZONEARTMASKS[flavor] or {}) do
		Add(MASK_PATH .. name)
	end

	local list = {}
	for _, entry in pairs(files) do tinsert(list, entry) end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function MapUtils:GetDebugMapMaskZones()
	local list, seen = {}, {}
	local function Add(info)
		if info == nil or seen[info.mapID] then return end
		seen[info.mapID] = true
		tinsert(list, info)
	end

	for _, continentID in ipairs(CONTINENTS) do
		for _, info in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, true) or {}) do
			Add(info)
		end
	end

	for mapID in pairs(CITY_MAPS) do
		Add(C_Map.GetMapInfo(mapID))
	end

	table.sort(list, function(a, b)
		if a.name == b.name then return a.mapID < b.mapID end
		return a.name < b.name
	end)
	return list
end

function MapUtils:GetMapMaskFilename(mapID)
	if mapID == nil then return nil end
	if CITY_MAPS[mapID] then return "city_" .. mapID .. ".blp" end

	local artMask = GetArtMask(mapID)
	if artMask then return artMask .. ".blp" end

	local continentID = GetContinent(mapID)
	if continentID == nil then return nil end
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, continentID)
	if left == nil or right <= left or bottom <= top then return nil end

	local highlight = GetHighlight(continentID, mapID, left, right, top, bottom)
	return highlight and (highlight.file .. ".blp") or nil
end

function MapUtils:GetMapMaskFilenamesAtCursor(mapID, cursorX, cursorY)
	local files, seen = {}, {}
	local function ContainsCursor(region, scale)
		local left, bottom, width, height = region:GetRect()
		local x, y = cursorX / scale, cursorY / scale
		return left ~= nil and x >= left and x <= left + width and y >= bottom and y <= bottom + height
	end

	local function AddMask(path, region, scale)
		if IsMapMaskHidden(region) then return end
		local name = path:match("[^\\]+$") .. ".blp"
		if not seen[name] and ContainsCursor(region, scale) then
			seen[name] = true
			tinsert(files, name)
		end
	end

	if container and container:IsVisible() then
		for _, group in ipairs({cities, zones, unders}) do
			for _, art in pairs(group) do
				local scale = art.frame:GetEffectiveScale()
				if art.count > 0 and art.frame:IsVisible() and ContainsCursor(art.frame, scale) then
					if art.masked then AddMask(art.maskPath, art.mask, scale) end
					if art.hmasked then AddMask(art.highlightPath, art.hmask, scale) end
					AddMask(EDGE_PATH, art.edge, scale)
				end
			end
		end

		local scale = container:GetEffectiveScale()
		for _, entry in pairs(base.continents) do
			if entry.drawn and entry.pool[1] and entry.pool[1]:IsVisible() and ContainsCursor(entry.edge, scale) then
				if entry.maskGeometry then AddMask(entry.maskGeometry[1], entry.mask, scale) end
				AddMask(EDGE_PATH, entry.edge, scale)
			end
		end
	end

	if #files == 0 and not IsMapMaskGroupHidden(mapID) then
		local file = self:GetMapMaskFilename(mapID)
		if file and not maskFiles[MASK_PATH .. file:sub(1, -5)] then tinsert(files, file) end
	end

	table.sort(files)
	return files
end

local function GetSpace(mapID)
	if mapID == WORLD then return WORLD end
	local continentID = mapID and GetContinent(mapID)

	return continentID and SPACE_OF[continentID]
end

local function GetStyle(mapID)
	if type(MAUTTAB) ~= "table" then return "MIXED" end
	local zoneStyle = MAUTTAB["MAPSTYLE"] or "MIXED"
	local cityStyle = MAUTTAB["CITYMAPSTYLE"] or zoneStyle
	if mapID == nil or cityStyle == zoneStyle then return zoneStyle end
	return CITY_MAPS[mapID] and cityStyle or zoneStyle
end

function MapUtils:GetTerrainFadeThresholds(city)
	local settings = type(MAUTTAB) == "table" and MAUTTAB or {}
	local prefix = city and "CITYTERRAINFADE" or "ZONETERRAINFADE"
	local start = tonumber(settings[prefix .. "START"]) or TERRAIN_FADE_START
	local finish = tonumber(settings[prefix .. "END"]) or TERRAIN_FADE_END

	return start, math.max(start + 10, finish)
end

local function GetEmbeddedCityStyle(mapID)
	if not mapID then return nil end
	local style = type(MAUTTAB) == "table" and MAUTTAB["CITYMAPSTYLE"]
	if not style then return nil end
	if style == GetStyle() then
		if style ~= "MIXED" then return nil end
		local zoneStart, zoneEnd = MapUtils:GetTerrainFadeThresholds(false)
		local cityStart, cityEnd = MapUtils:GetTerrainFadeThresholds(true)
		if zoneStart == cityStart and zoneEnd == cityEnd then return nil end
	end
	if CITY_MAPS[mapID] then return MapUtils:IsOneMap() and style or nil end
	local info = C_Map.GetMapInfo(mapID)
	if info and info.mapType == Enum.UIMapType.Zone or MapUtils:IsOneMap() and GetSpace(mapID) then return style end
end

local function GetMode(mapID)
	if MapUtils.IsOneMap and MapUtils:IsOneMap() then return MODE_FULL end

	return GetStyle(mapID) == "MAP" and not GetEmbeddedCityStyle(mapID) and MODE_OFF or MODE_AREAS
end

local rectCache = {}
local function ComputeSpaceRect(mapID)
	local space = GetSpace(mapID)
	if space == nil then return nil end
	if mapID == space then return 0, 1, 0, 1 end
	local info = C_Map.GetMapInfo(mapID)
	if info == nil then return nil end
	local continentID = GetContinent(mapID)
	if continentID == nil or (mapID ~= continentID and info.mapType ~= Enum.UIMapType.Zone) then return nil end
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, space)
	if left == nil or right <= left or bottom <= top then return nil end
	local width, height = right - left, bottom - top

	return -left / width, (1 - left) / width, -top / height, (1 - top) / height
end

local function RawSpaceRect(mapID)
	if mapID == nil then return nil end
	local cached = rectCache[mapID]
	if cached == nil then
		local left, right, top, bottom = ComputeSpaceRect(mapID)
		cached = left ~= nil and {left, right, top, bottom} or false
		rectCache[mapID] = cached
	end

	if cached == false then return nil end

	return cached[1], cached[2], cached[3], cached[4]
end

local function GetSpaceRect(mapID)
	if container == nil or container.built == nil or GetSpace(mapID) ~= container.space then return nil end
	if mapID ~= WORLD then
		local continentID = GetContinent(mapID)
		local entry = continentID and base.continents[continentID]
		if not entry or not entry.drawn then return nil end
		local city = cities[mapID]
		if mapID ~= continentID and not HasArt(mapID) and (city == nil or city.count == 0) then return nil end
	end

	return RawSpaceRect(mapID)
end

function MapUtils:IsZoneDetailMap(mapID)
	if GetMode() ~= MODE_FULL then return false end

	return GetSpaceRect(mapID) ~= nil
end

function MapUtils:GetZoneDetailSpaceRect(mapID)
	if GetMode() ~= MODE_FULL then return nil end

	return GetSpaceRect(mapID)
end

function MapUtils:GetZoneDetailSpace(mapID)
	return GetSpace(mapID) or WORLD
end

function MapUtils:GetZoneDetailContinent(mapID)
	return GetContinent(mapID)
end

function MapUtils:GetZoneDetailContinents(space)
	local list = {}
	for _, continentID in ipairs(CONTINENTS) do
		local entry = base.continents[continentID]
		if SPACE_OF[continentID] == space and entry ~= nil and entry.drawn then tinsert(list, continentID) end
	end

	return list
end

function MapUtils:GetZoneDetailRawRect(mapID)
	return RawSpaceRect(mapID)
end

function MapUtils:GetZoneDetailCityAt(space, x, y)
	if container == nil or container.space ~= space then return nil end
	local best, bestArea
	for mapID, city in pairs(cities) do
		if city.count > 0 then
			local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, space)
			if left ~= nil and x >= left and x <= right and y >= top and y <= bottom then
				local area = (right - left) * (bottom - top)
				if area > 0 and (bestArea == nil or area < bestArea) then
					best, bestArea = mapID, area
				end
			end
		end
	end

	return best
end

function MapUtils:GetZoneDetailCityZone(mapID)
	local mode = GetMode(mapID)
	if mode ~= MODE_AREAS and mode ~= MODE_FULL or container == nil or container.built == nil or mapID == nil or HasArt(mapID) then return nil end
	local info = C_Map.GetMapInfo(mapID)
	local continentID = info and info.mapType == Enum.UIMapType.Zone and GetContinent(mapID)
	local entry = continentID and base.continents[continentID]
	if not entry or not entry.drawn or mapID == continentID then return nil end
	if info.parentMapID ~= nil and info.parentMapID ~= continentID and HasArt(info.parentMapID) then return info.parentMapID end
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, continentID)
	if left == nil then return nil end
	container.cityZones = container.cityZones or {}
	if container.cityZones[mapID] ~= nil then return container.cityZones[mapID] or nil end
	local x, y = (left + right) / 2, (top + bottom) / 2
	local votes, best = {}, nil
	for _, radius in ipairs(CITY_RING) do
		for step = 0, CITY_RING_STEPS - 1 do
			local angle = step * 2 * math.pi / CITY_RING_STEPS
			local at = C_Map.GetMapInfoAtPosition(continentID, x + math.cos(angle) * radius * (right - left) / 2, y + math.sin(angle) * radius * (bottom - top) / 2)
			if at ~= nil and at.mapID ~= mapID and HasArt(at.mapID) then
				votes[at.mapID] = (votes[at.mapID] or 0) + 1
				if best == nil or votes[at.mapID] > votes[best] then best = at.mapID end
			end
		end
	end

	if best ~= nil then
		container.cityZones[mapID] = best

		return best
	end

	local bestArea = nil
	local children = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false)
	for _, child in ipairs(children or {}) do
		if child.mapID ~= mapID and HasArt(child.mapID) then
			local l, r, t, b = C_Map.GetMapRectOnMap(child.mapID, continentID)
			if l ~= nil and x >= l and x <= r and y >= t and y <= b then
				local area = (r - l) * (b - t)
				if bestArea == nil or area < bestArea then best, bestArea = child.mapID, area end
			end
		end
	end

	container.cityZones[mapID] = best or false

	return best
end

function MapUtils:GetZoneDetailSources()
	local sources = {}
	for _, continentID in ipairs(CONTINENTS) do
		local entry = base.continents[continentID]
		if entry ~= nil and entry.drawn then
			tinsert(sources, continentID)
			local children = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, true)
			if children ~= nil then
				for _, child in ipairs(children) do
					tinsert(sources, child.mapID)
				end
			end
		end
	end

	return sources
end

local function PreloadMap(mapID)
	local files = C_Map.GetMapArtLayerTextures(mapID, 1)
	if files == nil then return end
	for _, fileID in ipairs(files) do
		if fileID and not preload.files[fileID] then
			preload.files[fileID] = true
			local texture = preload.frame:CreateTexture(nil, "BACKGROUND")
			texture:SetSize(1, 1)
			texture:SetPoint("TOPLEFT")
			texture:SetTexture(fileID, nil, nil, "TRILINEAR")
			texture:SetAlpha(0.01)
		end
	end
end

local function Preload()
	if preload.done then return end
	preload.done = true
	preload.frame = CreateFrame("FRAME", nil, WorldMapFrame.ScrollContainer)
	preload.frame:SetSize(1, 1)
	preload.frame:SetPoint("TOPLEFT")
	preload.frame:EnableMouse(false)
	preload.files = {}
	PreloadMap(WORLD)
	for _, continentID in ipairs(CONTINENTS) do
		PreloadMap(continentID)
		local children = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false)
		if children ~= nil then
			for _, child in ipairs(children) do
				PreloadMap(child.mapID)
			end
		end
	end
end

local function DrawTileLayer(pool, mapID, offsetX, offsetY, scale, drawLayer, mask, edge)
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	local files = C_Map.GetMapArtLayerTextures(mapID, 1)
	if layer == nil or files == nil then return false end
	local cols = math.ceil(layer.layerWidth / layer.tileWidth)
	local rows = math.ceil(layer.layerHeight / layer.tileHeight)
	for row = 1, rows do
		local pixelHeight, fileHeight = GetTileSize(layer.layerHeight, layer.tileHeight, row, rows)
		for col = 1, cols do
			local fileID = files[(row - 1) * cols + col]
			if fileID ~= nil then
				local pixelWidth, fileWidth = GetTileSize(layer.layerWidth, layer.tileWidth, col, cols)
				local index = (row - 1) * cols + col
				local texture = pool[index]
				if texture == nil then
					texture = container:CreateTexture(nil, drawLayer)
					if mask ~= nil then AddMapMask(texture, mask) end
					if edge ~= nil then AddMapMask(texture, edge) end
					pool[index] = texture
				end

				texture:SetTexture(fileID, nil, nil, "TRILINEAR")
				texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
				texture:SetSize(pixelWidth * scale, pixelHeight * scale)
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", container, "TOPLEFT", offsetX + layer.tileWidth * (col - 1) * scale, -(offsetY + layer.tileHeight * (row - 1) * scale))
				texture.used = true
			end
		end
	end

	return true
end

local function DrawCity(mapID, width, height)
	local left, right, top, bottom = ArtRect(mapID, container.space)
	if left == nil or right <= left or bottom <= top then return end
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	if layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 or layer.layerHeight <= 0 then return end
	local city = GetCity(mapID)
	local frameWidth = (right - left) * width
	local frameHeight = (bottom - top) * height
	city.scaleX = frameWidth / layer.layerWidth
	city.scaleY = frameHeight / layer.layerHeight
	city.frame:ClearAllPoints()
	city.frame:SetPoint("TOPLEFT", container, "TOPLEFT", left * width, -top * height)
	city.frame:SetSize(frameWidth, frameHeight)
	city.bounds = {left, right, top, bottom}
	DrawBase(city, mapID, layer)
	city.frame:Hide()
end

local function DrawContinent(continentID, refWidth, refHeight)
	local entry = base.continents[continentID]
	if entry == nil then
		entry = {
			["pool"] = {}
		}

		base.continents[continentID] = entry
	end

	entry.drawn = false
	if MapUtils.ZONEMASKS == nil then return nil end
	local space = container.space
	local left, right, top, bottom = RectOn(continentID, space)
	if left == nil or right <= left or bottom <= top then return nil end
	local own = continentID == space
	local highlight = not own and FindHighlight(space, continentID, left, right, top, bottom)
	local layers = C_Map.GetMapArtLayers(continentID)
	local layer = layers and layers[1]
	if (not own and not highlight) or layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 then return nil end
	entry.maskGeometry = nil
	if highlight then
		if entry.mask == nil then entry.mask = container:CreateMaskTexture() end
		entry.mask.mapMaskGroup = WORLD
		SetMapMaskTexture(entry.mask, MASK_PATH .. highlight.file, "CLAMPTOBLACKADDITIVE")
		entry.mask:SetSize(highlight.width * refWidth, highlight.height * refHeight)
		entry.mask:ClearAllPoints()
		entry.mask:SetPoint("TOPLEFT", container, "TOPLEFT", highlight.x * refWidth, -highlight.y * refHeight)
		entry.maskGeometry = {MASK_PATH .. highlight.file, highlight.width * refWidth, highlight.height * refHeight, highlight.x * refWidth, -highlight.y * refHeight}
	end

	if entry.edge == nil then
		entry.edge = container:CreateMaskTexture()
		SetMapMaskTexture(entry.edge, EDGE_PATH, "CLAMPTOBLACKADDITIVE")
	end

	entry.edge.mapMaskGroup = continentID
	entry.edge:SetSize((right - left) * refWidth, (bottom - top) * refHeight)
	entry.edge:ClearAllPoints()
	entry.edge:SetPoint("TOPLEFT", container, "TOPLEFT", left * refWidth, -top * refHeight)
	if not DrawTileLayer(entry.pool, continentID, left * refWidth, top * refHeight, (right - left) * refWidth / layer.layerWidth, "BORDER", highlight and entry.mask or nil, entry.edge) then return nil end
	entry.drawn = true

	return {left, right, top, bottom}
end

local function ShowBase(shown)
	for _, entry in pairs(base.continents) do
		for _, texture in pairs(entry.pool) do
			texture:SetShown(shown and entry.drawn and texture.used == true)
		end
	end

	for _, texture in pairs(base.world) do
		texture:SetShown(shown and texture.used == true)
	end

	for _, list in ipairs({unders, zones}) do
		for _, art in pairs(list) do
			art.frame:SetShown(shown and art.count > 0)
		end
	end
end

local function GetCityHostRect(mapID)
	if MapUtils:GetZoneDetailCityZone(mapID) == nil then return nil end

	return RawSpaceRect(mapID)
end

local function Build(mode, space)
	Preload()
	ClearAll()
	for _, entry in pairs(base.continents) do
		entry.drawn = false
		for _, texture in pairs(entry.pool) do
			texture.used = nil
			texture:Hide()
		end
	end

	for _, texture in pairs(base.world) do
		texture.used = nil
		texture:Hide()
	end

	container.built = mode
	container.space = space
	container.cityZones = {}
	local layers = C_Map.GetMapArtLayers(space)
	local layer = layers and layers[1]
	if layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 then return false end
	local refWidth, refHeight = layer.layerWidth, layer.layerHeight
	container.refWidth = refWidth
	container.refHeight = refHeight
	container:SetSize(refWidth, refHeight)
	if mode == MODE_FULL and space == WORLD then DrawTileLayer(base.world, WORLD, 0, 0, 1, "BACKGROUND") end
	for _, continentID in ipairs(CONTINENTS) do
		local continentRect = SPACE_OF[continentID] == space and DrawContinent(continentID, refWidth, refHeight)
		if mode == MODE_AREAS and SPACE_OF[continentID] == space and not continentRect then
			local entry = base.continents[continentID]
			entry.drawn = true
			entry.maskGeometry = nil
		end

		if continentRect and mode == MODE_FULL then
			local children = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false)
			if children ~= nil then
				for _, info in ipairs(children) do
					DrawZone(continentID, continentRect, info.mapID, mode, refWidth, refHeight)
				end
			end

			local all = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, true)
			for _, info in ipairs(all or {}) do
				if not HasArt(info.mapID) then DrawCity(info.mapID, refWidth, refHeight) end
			end
		end

		if SPACE_OF[continentID] == space and base.continents[continentID].drawn and (mode == MODE_FULL or GetEmbeddedCityStyle(WorldMapFrame:GetMapID())) then
			for mapID in pairs(CITY_MAPS) do
				if GetContinent(mapID) == continentID and (cities[mapID] == nil or cities[mapID].count == 0) then DrawCity(mapID, refWidth, refHeight) end
			end
		end
	end

	return true
end

local function GetHostRect(mapID)
	if container.built == MODE_AREAS then return RawSpaceRect(mapID) end
	if container.cityMode then return GetCityHostRect(mapID) end

	return GetSpaceRect(mapID)
end

local function Layout(mapID, width, height)
	local left, right, top = GetHostRect(mapID)
	if left == nil or container.refWidth == nil then return false end
	local scale = (right - left) * width / container.refWidth
	if scale <= 0 then return false end
	container:SetScale(scale)
	container:ClearAllPoints()
	container:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", left * width / scale, -top * height / scale)

	return true
end

local MinimapLayer
local function SyncBlizzardArt()
	local cityDetail = MinimapLayer.cityDetailHost ~= nil and MinimapLayer.cityDetailHost == WorldMapFrame:GetMapID()
	local hide = cityDetail or container ~= nil and container:IsShown() and container.built == MODE_FULL and (not container.cityMode or GetEmbeddedCityStyle(WorldMapFrame:GetMapID()) ~= nil)
	if container and container:IsShown() and not hide and MinimapLayer.frame then
		local level = container:GetFrameLevel() + 4
		for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
			level = math.max(level, pin:GetFrameLevel() + 1)
		end

		if MinimapLayer.frame:GetFrameLevel() ~= level then MinimapLayer.frame:SetFrameLevel(level) end
	end

	local cityLevel = MinimapLayer.frame and MinimapLayer.frame:GetFrameLevel() + 1
	if cityLevel and GetEmbeddedCityStyle(WorldMapFrame:GetMapID()) then
		for mapID, city in pairs(cities) do
			if CITY_MAPS[mapID] and city.frame:GetFrameLevel() ~= cityLevel then city.frame:SetFrameLevel(cityLevel) end
			if city.terrain and city.terrain:GetFrameLevel() ~= cityLevel + 1 then city.terrain:SetFrameLevel(cityLevel + 1) end
		end
	end

	if not hide and not container.blizzardHidden then return end
	container.blizzardHidden = hide
	if WorldMapFrame.detailLayerPool ~= nil then
		for layer in WorldMapFrame.detailLayerPool:EnumerateActive() do
			if layer:IsShown() == hide then layer:SetShown(not hide) end
		end
	end

	for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
		if pin:IsShown() == hide then pin:SetShown(not hide) end
	end
end

local function Update(force)
	if container == nil then return end
	local mapID = WorldMapFrame:GetMapID()
	local mode = GetMode(mapID)
	local child = WorldMapFrame.ScrollContainer.Child
	local width, height = child:GetWidth(), child:GetHeight()
	if mode ~= MODE_AREAS and mode ~= MODE_FULL or width == nil or width <= 0 or height == nil or height <= 0 or RawSpaceRect(mapID) == nil then
		container.signature = nil
		container:Hide()

		return
	end

	local space = GetSpace(mapID)
	if force or container.built ~= mode or container.space ~= space then
		container.signature = nil
		if not Build(mode, space) then return end
		MinimapLayer.explorationSignature = nil
	end

	container.cityMode = mode == MODE_FULL and GetSpaceRect(mapID) == nil
	if container.cityMode and GetCityHostRect(mapID) == nil then
		container.signature = nil
		container.cityMode = false
		container:Hide()

		return
	end

	ShowBase(mode == MODE_FULL and (not container.cityMode or GetEmbeddedCityStyle(mapID) ~= nil))

	local signature = format("%s:%.1f:%.1f", tostring(mapID), width, height)
	if signature ~= container.signature then
		container.signature = signature
		if not Layout(mapID, width, height) then
			container:Hide()

			return
		end
	end

	local level = child:GetFrameLevel() + FRAME_LEVEL_OFFSET
	container:SetFrameLevel(level)
	for _, under in pairs(unders) do
		under.frame:SetFrameLevel(level + 1)
	end

	for _, zone in pairs(zones) do
		zone.frame:SetFrameLevel(level + 2)
	end

	if MinimapLayer.frame == nil then MinimapLayer.frame = CreateFrame("FRAME", nil, container) end
	MinimapLayer.frame:SetAllPoints(container)
	MinimapLayer.frame:SetFrameLevel(level + 4)
	MinimapLayer.frame:Show()
	for _, city in pairs(cities) do
		city.frame:SetFrameLevel(level + 3)
	end

	container:Show()
	MinimapLayer.signature = nil
	MinimapLayer.Update()
end

function MapUtils:RefreshZoneDetail()
	Update(true)
	if container ~= nil then MinimapLayer.UpdateCityDetail() end
	SyncBlizzardArt()
end

MinimapLayer = {
	tile = 1600 / 3,
	instances = {
		[1414] = 1,
		[1415] = 0,
		[1945] = 530
	},
	data = {},
	parsed = {},
	sources = {},
	debugInfo = {},
	transforms = {},
	samplePoints = {{0.25, 0.25}, {0.75, 0.25}, {0.25, 0.75}, {0.75, 0.75}, {0.5, 0.5}, {0.5, 0.9}, {0.9, 0.5}, {0.1, 0.5}, {0.5, 0.1}, {0.9, 0.9}, {0.1, 0.9}},
	masks = {},
	waterMasks = {},
	explorationMasks = {},
	explored = {},
	active = {},
	pools = {},
	maxAlpha = 1,
	maxTiles = 100,
	desaturation = 0.35,
	tint = {1, 0.93, 0.8},
	terrainMaxTiles = 400,
	lodData = {},
	lodParsed = {},
	lodPath = "Interface\\AddOns\\MapUtils\\media\\minimaplod\\"
}

function MapUtils:AddMinimapTiles(dataFlavor, instance, data)
	if MapUtils.GetRevealFlavor == nil or dataFlavor ~= MapUtils:GetRevealFlavor() then return end
	MinimapLayer.data[instance] = data
end

function MinimapLayer.GetTiles(instance)
	if MinimapLayer.parsed[instance] ~= nil then return MinimapLayer.parsed[instance] end
	local data = MinimapLayer.data[instance]
	if data == nil then return nil end
	local tiles = {}
	for key, fileID in string.gmatch(data, "(%d+)=(%d+)") do
		tiles[tonumber(key)] = tonumber(fileID)
	end

	MinimapLayer.parsed[instance] = tiles

	return tiles
end

function MinimapLayer.GetSources(continentID)
	local list = MinimapLayer.sources[continentID]
	if list ~= nil then return list end
	list = {}
	MinimapLayer.sources[continentID] = list
	local instance = MinimapLayer.instances[continentID]
	if instance == nil then return list end
	tinsert(
		list,
		{
			["id"] = continentID,
			["continentID"] = continentID,
			["instance"] = instance,
			["mapID"] = continentID
		}
	)

	if C_Map.GetWorldPosFromMapPos == nil or CreateVector2D == nil then return list end
	local extra = {}
	for _, child in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false) or {}) do
		local childInstance = C_Map.GetWorldPosFromMapPos(child.mapID, CreateVector2D(0.5, 0.5))
		if childInstance ~= nil and childInstance ~= instance and MinimapLayer.data[childInstance] ~= nil then
			local source = extra[childInstance]
			if source == nil then
				source = {
					["id"] = continentID * 1000 + childInstance,
					["continentID"] = continentID,
					["instance"] = childInstance,
					["mapID"] = child.mapID,
					["bounds"] = {}
				}

				extra[childInstance] = source
				tinsert(list, source)
			end

			local bounds = source.bounds
			for _, corner in ipairs({{0, 0}, {1, 1}}) do
				local _, position = C_Map.GetWorldPosFromMapPos(child.mapID, CreateVector2D(corner[1], corner[2]))
				if position ~= nil then
					local yardX, yardY = position:GetXY()
					bounds[1], bounds[2] = math.min(bounds[1] or yardX, yardX), math.max(bounds[2] or yardX, yardX)
					bounds[3], bounds[4] = math.min(bounds[3] or yardY, yardY), math.max(bounds[4] or yardY, yardY)
				end
			end
		end
	end

	return list
end

function MinimapLayer.GetTransform(source)
	local transform = MinimapLayer.transforms[source.id]
	if transform ~= nil then return transform or nil end
	MinimapLayer.transforms[source.id] = false
	if C_Map.GetWorldPosFromMapPos == nil or CreateVector2D == nil then return nil end
	local left, right, top, bottom = RectOn(source.mapID, SPACE_OF[source.continentID])
	if left == nil or right <= left or bottom <= top then return nil end
	local points = {}
	for _, point in ipairs(MinimapLayer.samplePoints) do
		local instance, position = C_Map.GetWorldPosFromMapPos(source.mapID, CreateVector2D(point[1], point[2]))
		if position ~= nil and instance == source.instance then
			local count = #points
			local usable = count < 2
			if count == 2 then usable = (points[2][5] - points[1][5]) * (point[2] - points[1][6]) - (points[2][6] - points[1][6]) * (point[1] - points[1][5]) ~= 0 end
			if usable then
				local yardX, yardY = position:GetXY()
				tinsert(points, {yardX, yardY, left + point[1] * (right - left), top + point[2] * (bottom - top), point[1], point[2]})
				if #points == 3 then break end
			end
		end
	end

	if #points < 3 then return nil end
	local dX1, dY1 = points[2][1] - points[1][1], points[2][2] - points[1][2]
	local dX2, dY2 = points[3][1] - points[1][1], points[3][2] - points[1][2]
	local denominator = dX1 * dY2 - dY1 * dX2
	if denominator == 0 then return nil end
	local du1, du2 = points[2][3] - points[1][3], points[3][3] - points[1][3]
	local dv1, dv2 = points[2][4] - points[1][4], points[3][4] - points[1][4]
	local a, b = (du1 * dY2 - dY1 * du2) / denominator, (dX1 * du2 - du1 * dX2) / denominator
	local c, d = (dv1 * dY2 - dY1 * dv2) / denominator, (dX1 * dv2 - dv1 * dX2) / denominator
	transform = {points[1][3] - a * points[1][1] - b * points[1][2], points[1][4] - c * points[1][1] - d * points[1][2], a, b, c, d}
	local flavorShifts = TILE_SHIFTS[MapUtils:GetFlavor() or ""]
	local shift = flavorShifts and flavorShifts[source.id]
	if shift ~= nil then
		transform[1] = transform[1] + a * shift[1] + b * shift[2]
		transform[2] = transform[2] + c * shift[1] + d * shift[2]
	end
	local det = a * d - b * c
	if det == 0 then return nil end
	transform[7] = det
	MinimapLayer.transforms[source.id] = transform

	return transform
end

function MinimapLayer.ToWorld(transform, x, y)
	return transform[1] + transform[3] * x + transform[4] * y, transform[2] + transform[5] * x + transform[6] * y
end

function MinimapLayer.ToYards(transform, u, v)
	local du, dv = u - transform[1], v - transform[2]

	return (transform[6] * du - transform[4] * dv) / transform[7], (transform[3] * dv - transform[5] * du) / transform[7]
end

function MinimapLayer.GetMask(continentID)
	local geometry = base.continents[continentID] and base.continents[continentID].maskGeometry
	if geometry == nil then return nil end
	local mask = MinimapLayer.masks[continentID]
	if mask == nil then
		mask = MinimapLayer.frame:CreateMaskTexture()
		MinimapLayer.masks[continentID] = mask
	end

	mask.mapMaskGroup = WORLD
	SetMapMaskTexture(mask, geometry[1], "CLAMPTOBLACKADDITIVE")
	mask:SetSize(geometry[2], geometry[3])
	mask:ClearAllPoints()
	mask:SetPoint("TOPLEFT", container, "TOPLEFT", geometry[4], geometry[5])

	return mask
end

function MinimapLayer.Release(key)
	local texture = MinimapLayer.active[key]
	texture:Hide()
	if texture.explorationMask then
		RemoveMapMask(texture, texture.explorationMask)
		texture.explorationMask = nil
	end
	MinimapLayer.active[key] = nil
	tinsert(MinimapLayer.pools[texture.continentID], texture)
end

function MinimapLayer.HideAll()
	for key in pairs(MinimapLayer.active) do
		MinimapLayer.Release(key)
	end

	MinimapLayer.signature = nil
end

function MinimapLayer.Acquire(continentID, mask, parent)
	local pool = MinimapLayer.pools[continentID]
	if pool == nil then
		pool = {}
		MinimapLayer.pools[continentID] = pool
	end

	local texture = tremove(pool)
	if texture == nil then
		texture = MinimapLayer.frame:CreateTexture(nil, "ARTWORK")
		if texture.SetSnapToPixelGrid ~= nil then texture:SetSnapToPixelGrid(false) end
		if texture.SetTexelSnappingBias ~= nil then texture:SetTexelSnappingBias(0) end
		texture.continentID = continentID
		if texture.SetDesaturation ~= nil then texture:SetDesaturation(MinimapLayer.desaturation) end
	end

	texture:SetParent(parent or MinimapLayer.frame)
	if texture.mask ~= mask then
		if texture.mask ~= nil then RemoveMapMask(texture, texture.mask) end
		if mask ~= nil then AddMapMask(texture, mask) end
		texture.mask = mask
	end

	return texture
end

function MinimapLayer.CollectExploration(continentID, mapID, usedMasks)
	local left, right, top, bottom
	if container.built == MODE_FULL then
		left, right, top, bottom = ArtRect(mapID, container.space)
	else
		left, right, top, bottom = RectOn(mapID, container.space)
	end

	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	if left == nil or right <= left or bottom <= top or not layer or layer.layerWidth <= 0 or layer.layerHeight <= 0 then return end
	local sx, sy = (right - left) / layer.layerWidth, (bottom - top) / layer.layerHeight
	local explored = C_MapExplorationInfo.GetExploredMapTextures(mapID)
	local pieces = MinimapLayer.explored[continentID]
	for _, info in ipairs(explored or {}) do
		local cols, rows = math.ceil(info.textureWidth / layer.tileWidth), math.ceil(info.textureHeight / layer.tileHeight)
		for row = 1, rows do
			local height, fileHeight = GetTileSize(info.textureHeight, layer.tileHeight, row, rows)
			for col = 1, cols do
				local fileID = info.fileDataIDs[(row - 1) * cols + col]
				if fileID and fileID > 0 then
					local width, fileWidth = GetTileSize(info.textureWidth, layer.tileWidth, col, cols)
					local x = left + (info.offsetX + (col - 1) * layer.tileWidth) * sx
					local y = top + (info.offsetY + (row - 1) * layer.tileHeight) * sy
					local index = #usedMasks + 1
					local mask = MinimapLayer.explorationMasks[index]
					if not mask then
						mask = MinimapLayer.frame:CreateMaskTexture()
						MinimapLayer.explorationMasks[index] = mask
					end

					mask.mapMaskGroup = mapID
					SetMapMaskTexture(mask, fileID, "CLAMP")
					mask:ClearAllPoints()
					mask:SetPoint("TOPLEFT", container, "TOPLEFT", x * container.refWidth, -y * container.refHeight)
					mask:SetSize(fileWidth * sx * container.refWidth, fileHeight * sy * container.refHeight)
					tinsert(usedMasks, mask)
					tinsert(pieces, {x, x + width * sx, y, y + height * sy, mask})
				end
			end
		end
	end
end

function MinimapLayer.UpdateExploration(host)
	local signature = container.built == MODE_AREAS and host or container.space
	if MinimapLayer.explorationSignature == signature then return end
	MinimapLayer.HideAll()
	MinimapLayer.explorationSignature = signature
	MinimapLayer.intersections = {}
	local hostInfo = C_Map.GetMapInfo(host)
	local singleZone = container.built == MODE_AREAS and hostInfo and hostInfo.mapType == Enum.UIMapType.Zone
	local usedMasks = {}
	for _, continentID in ipairs(CONTINENTS) do
		MinimapLayer.explored[continentID] = {}
		local entry = base.continents[continentID]
		if entry and entry.drawn and (container.built == MODE_FULL or host == WORLD or GetContinent(host) == continentID) then
			if singleZone then
				if GetContinent(host) == continentID then MinimapLayer.CollectExploration(continentID, host, usedMasks) end
			else
				for _, info in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false) or {}) do
					MinimapLayer.CollectExploration(continentID, info.mapID, usedMasks)
				end
			end
		end
	end
end

function MinimapLayer.Place(wanted, key, continentID, mask, transform, northX, westY, size, source, fogTint, fadedLOD, tileX, tileY, city)
	local u1, v1 = MinimapLayer.ToWorld(transform, northX, westY)
	local u2, v2 = MinimapLayer.ToWorld(transform, northX - size, westY - size)
	local left, right = math.min(u1, u2), math.max(u1, u2)
	local top, bottom = math.min(v1, v2), math.max(v1, v2)
	local width, height = right - left, bottom - top
	wanted[key] = true
	if not MinimapLayer.active[key] then
		local texture = MinimapLayer.Acquire(continentID, mask, city and city.terrain)
		texture:SetDrawLayer("ARTWORK", -1)
		local desaturation = 1 - (1 - MinimapLayer.desaturation) * fogTint[4]
		texture:SetDesaturation(fogTint[5] and 1 or desaturation)
		texture:SetVertexColor(fogTint[1] * MinimapLayer.tint[1], fogTint[2] * MinimapLayer.tint[2], fogTint[3] * MinimapLayer.tint[3], 1)
		local group = fadedLOD and fadedLOD.group
		local name = group and fadedLOD.pieces[math.floor(tileX / group) * 64 + math.floor(tileY / group)]
		if name then
			local x, y = tileX % group, tileY % group
			texture:SetTexture(MinimapLayer.lodPath .. name, nil, nil, "LINEAR")
			texture:SetTexCoord(x / group, (x + 1) / group, y / group, (y + 1) / group)
		else
			texture:SetTexture(source, "CLAMP", "CLAMP", "LINEAR")
			texture:SetTexCoord(0, 1, 0, 1)
		end
		texture:ClearAllPoints()
		texture:SetPoint("TOPLEFT", container, "TOPLEFT", left * container.refWidth, -top * container.refHeight)
		texture:SetSize(width * container.refWidth, height * container.refHeight)
		texture:Show()
		MinimapLayer.active[key] = texture
	end

	if not city then
		for mapID, overlay in pairs(MinimapLayer.cityOverlays) do
			local l, r, t, b = unpack(overlay.bounds)
			if left < r and right > l and top < b and bottom > t then
				MinimapLayer.Place(wanted, key .. ":city:" .. mapID, continentID, overlay.mask, transform, northX, westY, size, source, fogTint, fadedLOD, tileX, tileY, overlay)
			end
		end
	end

	local pieces = MinimapLayer.intersections[key]
	if not pieces then
		pieces = {}
		MinimapLayer.intersections[key] = pieces
		for index, piece in ipairs(MinimapLayer.explored[continentID]) do
			local l, r = math.max(left, piece[1]), math.min(right, piece[2])
			local t, b = math.max(top, piece[3]), math.min(bottom, piece[4])
			if l < r and t < b then
				tinsert(pieces, {l, r, t, b, piece[5], key .. ":" .. index})
			end
		end
	end

	for _, piece in ipairs(pieces) do
		local l, r, t, b, explorationMask, pieceKey = unpack(piece)
		wanted[pieceKey] = true
		if not MinimapLayer.active[pieceKey] then
			local texture = MinimapLayer.Acquire(continentID, mask, city and city.terrain)
			texture:SetDrawLayer("ARTWORK", 0)
			texture:SetDesaturation(MinimapLayer.desaturation)
			texture:SetVertexColor(unpack(MinimapLayer.tint))
			texture:SetTexture(source, "CLAMP", "CLAMP", "LINEAR")
			texture:SetTexCoord((l - left) / width, (r - left) / width, (t - top) / height, (b - top) / height)
			texture:ClearAllPoints()
			texture:SetPoint("TOPLEFT", container, "TOPLEFT", l * container.refWidth, -t * container.refHeight)
			texture:SetSize((r - l) * container.refWidth, (b - t) * container.refHeight)
			AddMapMask(texture, explorationMask)
			texture.explorationMask = explorationMask
			texture:Show()
			MinimapLayer.active[pieceKey] = texture
		end
	end
end

function MinimapLayer.GetWaterMask(source, tileX, tileY, transform)
	local lod = MinimapLayer.GetLOD(source.instance)
	if lod == nil then return nil end
	local col, row = math.floor(tileX / lod.group), math.floor(tileY / lod.group)
	local name = lod.masks[col * 64 + row]
	if name == nil then return nil end
	local key = source.id * 4096 + col * 64 + row
	local mask = MinimapLayer.waterMasks[key]
	if mask == nil then
		mask = MinimapLayer.frame:CreateMaskTexture()
		mask.mapMaskGroup = source.continentID
		SetMapMaskTexture(mask, MinimapLayer.lodPath .. name, "CLAMP")
		local size = lod.group * MinimapLayer.tile
		local northX, westY = (32 - row * lod.group) * MinimapLayer.tile, (32 - col * lod.group) * MinimapLayer.tile
		local u1, v1 = MinimapLayer.ToWorld(transform, northX, westY)
		local u2, v2 = MinimapLayer.ToWorld(transform, northX - size, westY - size)
		mask:SetPoint("TOPLEFT", container, "TOPLEFT", math.min(u1, u2) * container.refWidth, -math.min(v1, v2) * container.refHeight)
		mask:SetSize(math.abs(u2 - u1) * container.refWidth, math.abs(v2 - v1) * container.refHeight)
		MinimapLayer.waterMasks[key] = mask
	end

	return mask
end

function MinimapLayer.GetLOD(instance)
	if MinimapLayer.lodParsed[instance] ~= nil then return MinimapLayer.lodParsed[instance] or nil end
	local data = MinimapLayer.lodData[instance]
	if data == nil then
		MinimapLayer.lodParsed[instance] = false

		return nil
	end

	local pieces, waterMasks = {}, {}
	for key, name, mask in string.gmatch(data.pieces, "(%d+)=([%w_]+)/([%w_]+)") do
		pieces[tonumber(key)] = name
		waterMasks[tonumber(key)] = mask
	end

	MinimapLayer.lodParsed[instance] = {
		["group"] = data.group,
		["pieces"] = pieces,
		["masks"] = waterMasks
	}

	return MinimapLayer.lodParsed[instance]
end

function MapUtils:AddMinimapLOD(dataFlavor, instance, group, data)
	if MapUtils.GetRevealFlavor == nil or dataFlavor ~= MapUtils:GetRevealFlavor() then return end
	MinimapLayer.lodData[instance] = {
		["group"] = group,
		["pieces"] = data
	}
end

function MinimapLayer.ShowCityDetail(mapID, detail, host, width, height, level)
	local child = WorldMapFrame.ScrollContainer.Child
	local frame = detail.frame
	if frame == nil then
		frame = CreateFrame("FRAME", nil, child)
		frame:EnableMouse(false)
		frame.texture = frame:CreateTexture(nil, "ARTWORK")
		frame.texture:SetTexture("Interface\\AddOns\\MapUtils\\media\\" .. detail[1], nil, nil, "TRILINEAR")
		frame.texture:SetAllPoints(frame)
		frame.texture:SetDesaturation(MinimapLayer.desaturation)
		frame.texture:SetVertexColor(unpack(MinimapLayer.tint))
		detail.frame = frame
	end

	if frame.host ~= host or frame.width ~= width or frame.height ~= height then
		local firstInstance, first = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
		local lastInstance, last = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
		if first == nil or last == nil or firstInstance ~= 0 or lastInstance ~= 0 then return false end
		local north, west = first:GetXY()
		local south, east = last:GetXY()
		if north <= south or west <= east then return false end

		local left, right, top, bottom = 0, 1, 0, 1
		if host ~= mapID then
			local hostLeft, hostRight, hostTop, hostBottom = RawSpaceRect(host)
			local cityLeft, cityRight, cityTop, cityBottom = ArtRect(mapID, container.space)
			if hostLeft == nil or cityLeft == nil then return false end
			left, right = hostLeft + cityLeft * (hostRight - hostLeft), hostLeft + cityRight * (hostRight - hostLeft)
			top, bottom = hostTop + cityTop * (hostBottom - hostTop), hostTop + cityBottom * (hostBottom - hostTop)
		end

		local scaleX = (right - left) * width / (west - east)
		local scaleY = (bottom - top) * height / (north - south)
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", child, "TOPLEFT", left * width + (west - detail[3]) * scaleX, -top * height - (north - detail[2]) * scaleY)
		frame:SetSize(1024 * scaleX, 1024 * scaleY)
		frame.host, frame.width, frame.height = host, width, height
	end

	frame:SetFrameLevel(level or child:GetFrameLevel() + FRAME_LEVEL_OFFSET + 6)

	return true
end

function MinimapLayer.GetTerrainShare(tilePixels, start, finish)
	return (tilePixels - start) / (finish - start)
end

function MinimapLayer.UpdateCityDetail()
	local host = WorldMapFrame:GetMapID()
	local scroll = WorldMapFrame.ScrollContainer
	local flavor = MapUtils:GetFlavor()
	local supported = flavor == "era" or flavor == "tbc" or flavor == "forever"
	local width, height = scroll.Child:GetSize()
	local world = container:IsShown() and container.built == MODE_FULL and not container.cityMode
	local cityStart, cityEnd = MapUtils:GetTerrainFadeThresholds(true)
	local terrainFrame = MinimapLayer.frame
	local embeddedStyle = GetEmbeddedCityStyle(host)
	for mapID, city in pairs(cities) do
		local embedded = embeddedStyle ~= nil and CITY_MAPS[mapID] == true and container:IsShown()
		city.frame:SetShown((world or embedded) and city.count > 0)
		if city.terrain then city.terrain:SetShown(embedded and embeddedStyle ~= "MAP" and not UNDERGROUND[mapID]) end
	end

	MinimapLayer.cityDetailHost = nil
	for mapID, detail in pairs(UNDERGROUND) do
		local city = cities[mapID]
		local alpha = 0
		local onCityMap = host == mapID
		local embedded = embeddedStyle and city and city.frame:IsShown()
		local detailStyle = GetStyle(mapID)
		local canShow = supported and detailStyle ~= "MAP" and width > 0 and height > 0 and (onCityMap or embedded or world and city and city.count > 0)
		local level = embedded and city.frame:GetFrameLevel() + 2
		if canShow and MinimapLayer.ShowCityDetail(mapID, detail, host, width, height, level) then
			local mask = (embedded or world and not onCityMap) and city and city.masked and city.mask or nil
			if detail.frame.cityMask ~= mask then
				if detail.frame.cityMask then RemoveMapMask(detail.frame.texture, detail.frame.cityMask) end
				if mask then AddMapMask(detail.frame.texture, mask) end
				detail.frame.cityMask = mask
			end

			if detailStyle == "TERRAIN" then
				alpha = MinimapLayer.maxAlpha
			elseif onCityMap or embedded then
				local tilePixels = detail.frame:GetWidth() * MinimapLayer.tile / 1024 * scroll:GetCanvasScale()
				alpha = MinimapLayer.maxAlpha * math.max(0, math.min(1, MinimapLayer.GetTerrainShare(tilePixels, cityStart, cityEnd)))
			elseif terrainFrame then
				alpha = terrainFrame:GetAlpha()
			end
		end

		if detail.frame then
			detail.frame:SetAlpha(alpha)
			detail.frame:SetShown(alpha > 0)
		end

		if onCityMap and alpha >= MinimapLayer.maxAlpha then MinimapLayer.cityDetailHost = host end
	end
end

function MinimapLayer.Update()
	if container == nil or MinimapLayer.frame == nil then return end
	local host = WorldMapFrame:GetMapID()
	local embeddedStyle = GetEmbeddedCityStyle(host)
	local style = GetStyle(not embeddedStyle and host or nil)
	local cityTerrain = embeddedStyle and embeddedStyle ~= "MAP"
	if not container:IsShown() or container.refWidth == nil or style == "MAP" and not cityTerrain then
		if MinimapLayer.signature ~= nil or next(MinimapLayer.active) ~= nil then MinimapLayer.HideAll() end

		return
	end

	local terrain = style == "TERRAIN"
	local zoneStart, zoneEnd = MapUtils:GetTerrainFadeThresholds(not embeddedStyle and CITY_MAPS[host])
	local cityStart, cityEnd = MapUtils:GetTerrainFadeThresholds(true)
	local fogTint = MapUtils:GetSelectedRevealTint()
	local scrollContainer = WorldMapFrame.ScrollContainer
	local hostLeft, hostRight, hostTop, hostBottom = GetHostRect(host)
	local scale = scrollContainer:GetCanvasScale()
	local x, y = scrollContainer:GetCurrentScrollX(), scrollContainer:GetCurrentScrollY()
	local width, height = scrollContainer.Child:GetSize()
	if hostLeft == nil or x == nil or y == nil or scale == nil or scale <= 0 or width == nil or width <= 0 or height == nil or height <= 0 then return end
	MinimapLayer.UpdateExploration(host)
	local signature = format("%s:%s:%.5f:%.5f:%.5f", tostring(host), style, scale, x, y)
	if signature == MinimapLayer.signature then return end
	MinimapLayer.signature = signature
	local spaceWidth, spaceHeight = hostRight - hostLeft, hostBottom - hostTop
	local centerU, centerV = (x - hostLeft) / spaceWidth, (y - hostTop) / spaceHeight
	local halfU = scrollContainer:GetWidth() / (2 * scale * width) / spaceWidth
	local halfV = scrollContainer:GetHeight() / (2 * scale * height) / spaceHeight
	local wanted = {}
	local alpha = 0
	local cityAlpha = 0
	MinimapLayer.cityOverlays = {}
	if cityTerrain then
		for mapID, city in pairs(cities) do
			if CITY_MAPS[mapID] and not UNDERGROUND[mapID] and city.count > 0 then
				if not city.terrain then city.terrain = CreateFrame("FRAME", nil, city.frame) end
				MinimapLayer.cityOverlays[mapID] = city
			end
		end
	end

	for _, continentID in ipairs(CONTINENTS) do
		local entry = base.continents[continentID]
		for _, source in ipairs(entry and entry.drawn and MinimapLayer.GetSources(continentID) or {}) do
			local transform = MinimapLayer.GetTransform(source)
			local tiles = transform and MinimapLayer.GetTiles(source.instance)
			local info = {
				["transform"] = transform ~= nil,
				["tiles"] = tiles ~= nil
			}

			MinimapLayer.debugInfo[source.id] = info
			if tiles then
				local tileU = math.abs(transform[4]) * MinimapLayer.tile
				local tilePixels = tileU * spaceWidth * width * scale
				local share = terrain and 1 or style ~= "MAP" and MinimapLayer.GetTerrainShare(tilePixels, zoneStart, zoneEnd) or 0
				local cityShare = embeddedStyle == "TERRAIN" and 1 or cityTerrain and MinimapLayer.GetTerrainShare(tilePixels, cityStart, cityEnd) or 0
				info.tilePixels, info.share = tilePixels, share
				if share > 0 or cityShare > 0 then
					local minX, maxX, minY, maxY
					for _, corner in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
						local yardX, yardY = MinimapLayer.ToYards(transform, centerU + corner[1] * halfU, centerV + corner[2] * halfV)
						minX, maxX = math.min(minX or yardX, yardX), math.max(maxX or yardX, yardX)
						minY, maxY = math.min(minY or yardY, yardY), math.max(maxY or yardY, yardY)
					end

					local bounds = source.bounds
					if bounds ~= nil and bounds[1] ~= nil and bounds[3] ~= nil then
						minX, maxX = math.max(minX, bounds[1]), math.min(maxX, bounds[2])
						minY, maxY = math.max(minY, bounds[3]), math.min(maxY, bounds[4])
					end

					local x0, x1 = math.max(0, math.floor(32 - maxY / MinimapLayer.tile)), math.min(63, math.floor(32 - minY / MinimapLayer.tile))
					local y0, y1 = math.max(0, math.floor(32 - maxX / MinimapLayer.tile)), math.min(63, math.floor(32 - minX / MinimapLayer.tile))
					local count = (x1 - x0 + 1) * (y1 - y0 + 1)
					info.range = format("x %d-%d y %d-%d (%d)", x0, x1, y0, y1, count)
					local useTerrain = terrain or embeddedStyle == "TERRAIN"
					local lod = useTerrain and count > MinimapLayer.terrainMaxTiles and MinimapLayer.GetLOD(source.instance)
					if minX <= maxX and minY <= maxY and x1 >= x0 and y1 >= y0 and (count <= (useTerrain and MinimapLayer.terrainMaxTiles or MinimapLayer.maxTiles) or lod) then
						if terrain or count <= MinimapLayer.maxTiles then alpha = math.max(alpha, MinimapLayer.maxAlpha * math.min(1, share)) end
						if embeddedStyle == "TERRAIN" or count <= MinimapLayer.maxTiles then cityAlpha = math.max(cityAlpha, MinimapLayer.maxAlpha * math.min(1, cityShare)) end
						info.drawn = lod and "lod" or "tiles"
						local mask = MinimapLayer.GetMask(continentID)
						if lod then
							local group = lod.group
							for col = math.floor(x0 / group), math.floor(x1 / group) do
								for row = math.floor(y0 / group), math.floor(y1 / group) do
									local name = lod.pieces[col * 64 + row]
									if name ~= nil then
										local key = -(source.id * 4096 + col * 64 + row)
										local northX, westY = (32 - row * group) * MinimapLayer.tile, (32 - col * group) * MinimapLayer.tile
										MinimapLayer.Place(wanted, key, continentID, mask, transform, northX, westY, group * MinimapLayer.tile, MinimapLayer.lodPath .. name, fogTint)
									end
								end
							end
						else
							local fadedLOD = fogTint[4] < 1 and MinimapLayer.GetLOD(source.instance)
							for tileX = x0, x1 do
								for tileY = y0, y1 do
									local fileID = tiles[tileX * 64 + tileY]
									if fileID ~= nil then
										local key = source.id * 4096 + tileX * 64 + tileY
										local tileMask = MinimapLayer.GetWaterMask(source, tileX, tileY, transform) or mask
										MinimapLayer.Place(wanted, key, continentID, tileMask, transform, (32 - tileY) * MinimapLayer.tile, (32 - tileX) * MinimapLayer.tile, MinimapLayer.tile, fileID, fogTint, fadedLOD, tileX, tileY)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	for key in pairs(MinimapLayer.active) do
		if not wanted[key] then MinimapLayer.Release(key) end
	end

	MinimapLayer.frame:SetAlpha(alpha)
	for _, city in pairs(MinimapLayer.cityOverlays) do
		city.terrain:SetAlpha(cityAlpha)
	end
end

function MapUtils:GetZoneDetailTilePixelsPerScale(mapID)
	local style = GetStyle(mapID)
	if container == nil or container.refWidth == nil or style == "MAP" and GetEmbeddedCityStyle(mapID) ~= "MIXED" then return nil end
	local detail = UNDERGROUND[mapID]
	if detail and detail.frame and detail.frame.host == mapID then return detail.frame:GetWidth() * MinimapLayer.tile / 1024 end
	local left, right = GetSpaceRect(mapID)
	local continentID = left and GetContinent(mapID)
	local entry = continentID and base.continents[continentID]
	if not entry or not entry.drawn then return nil end
	local source = MinimapLayer.GetSources(continentID)[1]
	local transform = source and MinimapLayer.GetTransform(source)
	if transform == nil or MinimapLayer.GetTiles(source.instance) == nil then return nil end
	local width = WorldMapFrame.ScrollContainer.Child:GetWidth()
	if width == nil or width <= 0 then return nil end

	return math.abs(transform[4]) * MinimapLayer.tile * (right - left) * width
end

function MapUtils:GetZoneDetailTileFullPixels(mapID)
	local style = GetStyle(mapID)
	local _, finish = MapUtils:GetTerrainFadeThresholds(CITY_MAPS[mapID])
	if GetEmbeddedCityStyle(mapID) == "MIXED" then
		local _, zoneEnd = MapUtils:GetTerrainFadeThresholds(false)
		local _, cityEnd = MapUtils:GetTerrainFadeThresholds(true)
		finish = math.max(GetStyle() == "MIXED" and zoneEnd or 0, cityEnd)
	elseif style ~= "MIXED" then
		finish = TERRAIN_FADE_END
	end

	return finish
end

function MapUtils:PrintMinimapTileDebug()
	local host = WorldMapFrame and WorldMapFrame:GetMapID()
	local scrollContainer = WorldMapFrame and WorldMapFrame.ScrollContainer
	local style = GetStyle(host)
	MinimapLayer.debugLines = {}
	MinimapLayer.DebugLine(format("Tiles: host %s, flavor %s, style %s, mode %s, space %s", tostring(host), tostring(MapUtils.GetRevealFlavor and MapUtils:GetRevealFlavor()), tostring(style), GetMode(host), tostring(container and container.space)))
	if container == nil then return end
	MinimapLayer.DebugLine(format("container shown %s, cityMode %s, hostRect %s, scale %s, frame alpha %s", tostring(container:IsShown()), tostring(container.cityMode), tostring(GetSpaceRect(host) ~= nil), scrollContainer and format("%.3f", scrollContainer:GetCanvasScale()) or "?", MinimapLayer.frame and format("%.2f", MinimapLayer.frame:GetAlpha()) or "?"))
	for _, continentID in ipairs(CONTINENTS) do
		local entry = base.continents[continentID]
		if entry ~= nil and entry.drawn then
			local geometry = entry.maskGeometry
			MinimapLayer.DebugLine(format("continent %s mask %s", tostring(continentID), geometry and format("%s size %.1f x %.1f at %.1f, %.1f (ref %s x %s)", tostring(geometry[1]):match("[^\\]+$") or "?", geometry[2], geometry[3], geometry[4], geometry[5], tostring(container.refWidth), tostring(container.refHeight)) or "none"))
			for _, source in ipairs(MinimapLayer.GetSources(continentID)) do
				local info = MinimapLayer.debugInfo[source.id] or {}
				local samples = {}
				for _, point in ipairs(MinimapLayer.samplePoints) do
					local instance = C_Map.GetWorldPosFromMapPos(source.mapID, CreateVector2D(point[1], point[2]))
					tinsert(samples, tostring(instance))
				end

				MinimapLayer.DebugLine(format("source %s: map %s instance %s data %s, transform %s, px/tile %s, share %s, %s, drawn %s", tostring(source.id), tostring(source.mapID), tostring(source.instance), tostring(MinimapLayer.data[source.instance] ~= nil), tostring(info.transform), info.tilePixels and format("%.1f", info.tilePixels) or "-", info.share and format("%.2f", info.share) or "-", info.range or "no range", tostring(info.drawn or false)))
				MinimapLayer.DebugLine("  sample instances: " .. table.concat(samples, ","))
				local transform = MinimapLayer.transforms[source.id]
				if transform then MinimapLayer.DebugLine(format("  transform %.6g %.6g %.6g %.6g %.6g %.6g", transform[1], transform[2], transform[3], transform[4], transform[5], transform[6])) end
			end

			for _, child in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone, false) or {}) do
				local childInstance, topLeft = C_Map.GetWorldPosFromMapPos(child.mapID, CreateVector2D(0, 0))
				local _, bottomRight = C_Map.GetWorldPosFromMapPos(child.mapID, CreateVector2D(1, 1))
				if childInstance ~= nil and childInstance ~= MinimapLayer.instances[continentID] and topLeft ~= nil and bottomRight ~= nil then
					local rects = {}
					for _, space in ipairs({continentID, SPACE_OF[continentID]}) do
						local left, right, top, bottom = RectOn(child.mapID, space)
						tinsert(rects, format("on %s %s", tostring(space), left and format("%.5f %.5f %.5f %.5f", left, right, top, bottom) or "nil"))
					end

					MinimapLayer.DebugLine(format("  child %d %s instance %s world %.1f %.1f / %.1f %.1f, %s", child.mapID, tostring(child.name), tostring(childInstance), topLeft.x, topLeft.y, bottomRight.x, bottomRight.y, table.concat(rects, ", ")))
				end
			end
		end
	end

	local active = 0
	for _ in pairs(MinimapLayer.active) do
		active = active + 1
	end

	local left, right, top, bottom = GetSpaceRect(host)
	MinimapLayer.DebugLine(format("active textures %d, spaceRect %s, maxZoom %s, view %s", active, left and format("%.4f %.4f %.4f %.4f", left, right, top, bottom) or "nil", scrollContainer and scrollContainer.GetScaleForMaxZoom and format("%.3f", scrollContainer:GetScaleForMaxZoom()) or "?", scrollContainer and format("%.0fx%.0f", scrollContainer:GetWidth(), scrollContainer:GetHeight()) or "?"))
	if type(MAUTTAB) == "table" then MAUTTAB["TILEDEBUG"] = MinimapLayer.debugLines end
end

function MinimapLayer.DebugLine(text)
	tinsert(MinimapLayer.debugLines, text)
	MapUtils:INFO(text)
end

local function Install()
	if hooked then return true end
	if WorldMapFrame == nil or WorldMapFrame.ScrollContainer == nil or WorldMapFrame.ScrollContainer.Child == nil then return false end
	hooked = true
	local child = WorldMapFrame.ScrollContainer.Child
	container = CreateFrame("FRAME", nil, child)
	container:EnableMouse(false)
	container:Hide()
	local function Refresh()
		Update(false)
		MinimapLayer.UpdateCityDetail()
		SyncBlizzardArt()
	end

	hooksecurefunc(WorldMapFrame, "OnMapChanged", MapUtils.Profile("zonedetail Refresh", Refresh))
	WorldMapFrame:HookScript("OnShow", MapUtils.Profile("zonedetail Refresh", Refresh))
	child:HookScript("OnSizeChanged", MapUtils.Profile("zonedetail Refresh", Refresh))
	WorldMapFrame.ScrollContainer:HookScript(
		"OnUpdate",
		MapUtils.Profile("zonedetail OnUpdate", function()
			MinimapLayer.Update()
			MinimapLayer.UpdateCityDetail()
			SyncBlizzardArt()
		end)
	)

	return true
end

local loader = CreateFrame("FRAME")
MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
MapUtils:RegisterEvent(loader, "ADDON_LOADED")
MapUtils:RegisterEvent(loader, "MAP_EXPLORATION_UPDATED")
loader:SetScript(
	"OnEvent",
	function(self, event)
		if event == "MAP_EXPLORATION_UPDATED" then
			if container then
				container.built = nil
				if WorldMapFrame:IsShown() then MapUtils:RefreshZoneDetail() end
			end

			return
		end

		Install()
	end
)
