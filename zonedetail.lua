local _, MapUtils = ...
local WORLD = 947
local CONTINENTS = {1414, 1415}
local MODE_OFF = "OFF"
local MODE_AREAS = "AREAS"
local MODE_FULL = "FULL"
local SAMPLE_STEPS = 9
local FRAME_LEVEL_OFFSET = 5
local NO_TINT = {1, 1, 1, 1}
local MASK_PATH = "Interface\\AddOns\\MapUtils\\media\\zonemasks\\"
local EDGE_PATH = MASK_PATH .. "edge"
local ROUND_PATH = MASK_PATH .. "round"
local CITY_FADE = {0.05, 0.2}
local UNDERGROUND = {
	[1455] = true,
	[1458] = true
}
local CITY_RING = {0.5, 0.75, 1}
local CITY_RING_STEPS = 16
local container = nil
local zones = {}
local cities = {}
local unders = {}
local masks = {}
local hooked = false
local preload = {}
local base = {
	["continents"] = {},
	["world"] = {}
}

local function GetMode()
	if MapUtils.IsOneMap == nil or not MapUtils:IsOneMap() then return MODE_OFF end

	return MODE_FULL
end

local function NewArt()
	local frame = CreateFrame("FRAME", nil, container)
	local edge = frame:CreateMaskTexture()
	edge:SetTexture(EDGE_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
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
		zone = NewArt()
		zones[mapID] = zone
	end

	return zone
end

local function GetUnder(mapID)
	local under = unders[mapID]
	if under == nil then
		under = NewArt()
		unders[mapID] = under
	end

	return under
end

local function GetCity(mapID)
	local city = cities[mapID]
	if city == nil then
		city = NewArt()
		city.mask = city.frame:CreateMaskTexture()
		city.mask:SetTexture(ROUND_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
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
		texture:AddMaskTexture(zone.edge)
		if zone.masked then texture:AddMaskTexture(zone.mask) end
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

local function FindHighlight(continentID, mapID, left, right, top, bottom)
	for i = 0, SAMPLE_STEPS * SAMPLE_STEPS - 1 do
		local step = (i % 2 == 0) and (i / 2) or (SAMPLE_STEPS * SAMPLE_STEPS - 1 - (i - 1) / 2)
		local x = left + (right - left) * ((step % SAMPLE_STEPS) + 0.5) / SAMPLE_STEPS
		local y = top + (bottom - top) * (math.floor(step / SAMPLE_STEPS) + 0.5) / SAMPLE_STEPS
		local info = C_Map.GetMapInfoAtPosition(continentID, x, y)
		if info ~= nil and (info.mapID == mapID or (MapUtils.IsMapInside ~= nil and MapUtils.IsMapInside(info.mapID, mapID))) then
			local fileDataID, _, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = C_Map.GetMapHighlightInfoAtPosition(continentID, x, y)
			if fileDataID and MapUtils.ZONEMASKS and MapUtils.ZONEMASKS[fileDataID] and textureX > 0 and textureY > 0 and texPercentageX > 0 and texPercentageY > 0 then
				return {
					["fileID"] = fileDataID,
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
			zone.textures[i]:AddMaskTexture(zone.mask)
		else
			zone.textures[i]:RemoveMaskTexture(zone.mask)
		end
	end
end

local function ApplyMask(zone, highlight, left, top, width, height)
	if zone.mask == nil then zone.mask = zone.frame:CreateMaskTexture() end
	SetMasked(zone, true)
	zone.mask:SetTexture(MASK_PATH .. highlight.fileID, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	zone.mask:SetSize(highlight.width * width, highlight.height * height)
	zone.mask:ClearAllPoints()
	zone.mask:SetPoint("TOPLEFT", zone.frame, "TOPLEFT", (highlight.x - left) * width, -(highlight.y - top) * height)
end

local function GetArtMask(mapID)
	local flavor = MapUtils.GetRevealFlavor ~= nil and MapUtils:GetRevealFlavor()
	local list = flavor and MapUtils.ZONEARTMASKS and MapUtils.ZONEARTMASKS[flavor]
	local artID = list and C_Map.GetMapArtID(mapID)

	return artID and list[artID] or nil
end

local function DrawZone(continentID, continentRect, mapID, mode, width, height)
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, WORLD)
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
	if mode == MODE_FULL and not artMask then
		local l, r, t, b = C_Map.GetMapRectOnMap(mapID, continentID)
		if l ~= nil and r > l and b > t then highlight = GetHighlight(continentID, mapID, l, r, t, b) end
	end

	if artMask then
		if zone.mask == nil then zone.mask = zone.frame:CreateMaskTexture() end
		SetMasked(zone, true)
		zone.mask:SetTexture(MASK_PATH .. artMask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		zone.mask:ClearAllPoints()
		zone.mask:SetAllPoints(zone.frame)
	elseif highlight then
		local continentWidth, continentHeight = continentRect[2] - continentRect[1], continentRect[4] - continentRect[3]
		ApplyMask(
			zone,
			{
				["fileID"] = highlight.fileID,
				["x"] = continentRect[1] + highlight.x * continentWidth,
				["y"] = continentRect[3] + highlight.y * continentHeight,
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
		local under = GetUnder(mapID)
		local geometry = base.continents[continentID] and base.continents[continentID].maskGeometry
		if geometry ~= nil then
			if under.mask == nil then under.mask = under.frame:CreateMaskTexture() end
			under.mask:SetTexture(geometry[1], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			under.mask:SetSize(geometry[2], geometry[3])
			under.mask:ClearAllPoints()
			under.mask:SetPoint("TOPLEFT", container, "TOPLEFT", geometry[4], geometry[5])
			SetMasked(under, true)
		end

		under.scaleX, under.scaleY = zone.scaleX, zone.scaleY
		under.frame:ClearAllPoints()
		under.frame:SetAllPoints(zone.frame)
		DrawBase(under, mapID, layer)
		under.frame:Show()
	else
		SetMasked(zone, false)
	end

	DrawOverlays(zone, mapID, layer)
	zone.frame:Show()
end

local function IsInside(mapID, ancestorID)
	local info = C_Map.GetMapInfo(mapID)
	local guard = 0
	while info ~= nil and info.parentMapID ~= nil and info.parentMapID > 0 and guard < 10 do
		if info.parentMapID == ancestorID then return true end
		info = C_Map.GetMapInfo(info.parentMapID)
		guard = guard + 1
	end

	return false
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

local function RawSpaceRect(mapID)
	if mapID == nil then return nil end
	if mapID == WORLD then return 0, 1, 0, 1 end
	local info = C_Map.GetMapInfo(mapID)
	if info == nil then return nil end
	local continentID = GetContinent(mapID)
	if continentID == nil or (mapID ~= continentID and info.mapType ~= Enum.UIMapType.Zone) then return nil end
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, WORLD)
	if left == nil or right <= left or bottom <= top then return nil end
	local width, height = right - left, bottom - top

	return -left / width, (1 - left) / width, -top / height, (1 - top) / height
end

local function GetSpaceRect(mapID)
	if container == nil or container.built == nil then return nil end
	if mapID ~= WORLD then
		local continentID = GetContinent(mapID)
		local entry = continentID and base.continents[continentID]
		if not entry or not entry.drawn then return nil end
		if mapID ~= continentID and not HasArt(mapID) then return nil end
	end

	return RawSpaceRect(mapID)
end

function MapUtils:IsZoneDetailMap(mapID)
	local mode = GetMode()
	if mode ~= MODE_AREAS and mode ~= MODE_FULL then return false end

	return GetSpaceRect(mapID) ~= nil
end

function MapUtils:GetZoneDetailSpaceRect(mapID)
	if not MapUtils:IsZoneDetailMap(mapID) then return nil end

	return GetSpaceRect(mapID)
end

function MapUtils:GetZoneDetailSpace()
	return WORLD
end

function MapUtils:GetZoneDetailContinent(mapID)
	return GetContinent(mapID)
end

function MapUtils:GetZoneDetailRawRect(mapID)
	return RawSpaceRect(mapID)
end

function MapUtils:GetZoneDetailCityZone(mapID)
	local mode = GetMode()
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
					if mask ~= nil then texture:AddMaskTexture(mask) end
					if edge ~= nil then texture:AddMaskTexture(edge) end
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
	local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, WORLD)
	if left == nil or right <= left or bottom <= top then return end
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[1]
	if layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 or layer.layerHeight <= 0 then return end
	local city = GetCity(mapID)
	local frameWidth = (right - left) * width
	local frameHeight = (bottom - top) * height
	city.scaleX = frameWidth / layer.layerWidth
	city.scaleY = frameHeight / layer.layerHeight
	city.worldWidth = right - left
	city.frame:ClearAllPoints()
	city.frame:SetPoint("TOPLEFT", container, "TOPLEFT", left * width, -top * height)
	city.frame:SetSize(frameWidth, frameHeight)
	DrawBase(city, mapID, layer)
	city.frame:SetAlpha(0)
	city.frame:Show()
end

local function UpdateCityAlpha()
	if container == nil or not container:IsShown() or container.refWidth == nil then return end
	local scrollContainer = WorldMapFrame.ScrollContainer
	local scale = container:GetScale() * scrollContainer.Child:GetScale()
	local viewWidth = scrollContainer:GetWidth()
	if scale == container.cityScale or viewWidth == nil or viewWidth <= 0 then return end
	container.cityScale = scale
	for _, city in pairs(cities) do
		if city.count > 0 and city.worldWidth ~= nil then
			local share = city.worldWidth * container.refWidth * scale / viewWidth
			city.frame:SetAlpha(math.max(0, math.min(1, (share - CITY_FADE[1]) / (CITY_FADE[2] - CITY_FADE[1]))))
		end
	end
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
	local left, right, top, bottom = C_Map.GetMapRectOnMap(continentID, WORLD)
	if left == nil or right <= left or bottom <= top then return nil end
	local highlight = FindHighlight(WORLD, continentID, left, right, top, bottom)
	local layers = C_Map.GetMapArtLayers(continentID)
	local layer = layers and layers[1]
	if not highlight or layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 then return nil end
	if entry.mask == nil then entry.mask = container:CreateMaskTexture() end
	entry.mask:SetTexture(MASK_PATH .. highlight.fileID, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	entry.mask:SetSize(highlight.width * refWidth, highlight.height * refHeight)
	entry.mask:ClearAllPoints()
	entry.mask:SetPoint("TOPLEFT", container, "TOPLEFT", highlight.x * refWidth, -highlight.y * refHeight)
	entry.maskGeometry = {MASK_PATH .. highlight.fileID, highlight.width * refWidth, highlight.height * refHeight, highlight.x * refWidth, -highlight.y * refHeight}
	if entry.edge == nil then
		entry.edge = container:CreateMaskTexture()
		entry.edge:SetTexture(EDGE_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	end

	entry.edge:SetSize((right - left) * refWidth, (bottom - top) * refHeight)
	entry.edge:ClearAllPoints()
	entry.edge:SetPoint("TOPLEFT", container, "TOPLEFT", left * refWidth, -top * refHeight)
	if not DrawTileLayer(entry.pool, continentID, left * refWidth, top * refHeight, (right - left) * refWidth / layer.layerWidth, "BORDER", entry.mask, entry.edge) then return nil end
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

	for _, list in ipairs({unders, zones, cities}) do
		for _, art in pairs(list) do
			art.frame:SetShown(shown and art.count > 0)
		end
	end
end

local function GetCityHostRect(mapID)
	if UNDERGROUND[mapID] or MapUtils:GetZoneDetailCityZone(mapID) == nil then return nil end

	return RawSpaceRect(mapID)
end

local function Build(mode)
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
	container.cityZones = {}
	local layers = C_Map.GetMapArtLayers(WORLD)
	local layer = layers and layers[1]
	if layer == nil or layer.layerWidth == nil or layer.layerWidth <= 0 then return false end
	local refWidth, refHeight = layer.layerWidth, layer.layerHeight
	container.refWidth = refWidth
	container.refHeight = refHeight
	container:SetSize(refWidth, refHeight)
	if mode == MODE_FULL then DrawTileLayer(base.world, WORLD, 0, 0, 1, "BACKGROUND") end
	for _, continentID in ipairs(CONTINENTS) do
		local continentRect = mode == MODE_FULL and DrawContinent(continentID, refWidth, refHeight)
		if continentRect then
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
	end

	container.cityScale = nil

	return true
end

local function Layout(mapID, width, height)
	local left, right, top = GetSpaceRect(mapID)
	if left == nil then left, right, top = GetCityHostRect(mapID) end
	if left == nil or container.refWidth == nil then return false end
	local scale = (right - left) * width / container.refWidth
	if scale <= 0 then return false end
	container:SetScale(scale)
	container:ClearAllPoints()
	container:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", left * width / scale, -top * height / scale)

	return true
end

local function SyncBlizzardArt()
	local hide = container ~= nil and container:IsShown() and not container.cityMode
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

local MinimapLayer
local function Update(force)
	if container == nil then return end
	local mode = GetMode()
	local mapID = WorldMapFrame:GetMapID()
	local child = WorldMapFrame.ScrollContainer.Child
	local width, height = child:GetWidth(), child:GetHeight()
	if mode ~= MODE_AREAS and mode ~= MODE_FULL or width == nil or width <= 0 or height == nil or height <= 0 or RawSpaceRect(mapID) == nil then
		container.signature = nil
		container:Hide()

		return
	end

	if force or container.built ~= mode then
		container.signature = nil
		if not Build(mode) then return end
	end

	container.cityMode = GetSpaceRect(mapID) == nil
	if container.cityMode and GetCityHostRect(mapID) == nil then
		container.signature = nil
		container.cityMode = false
		container:Hide()

		return
	end

	ShowBase(not container.cityMode)

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
	container.cityScale = nil
	UpdateCityAlpha()
	MinimapLayer.signature = nil
	MinimapLayer.Update()
end

function MapUtils:RefreshZoneDetail()
	Update(true)
	SyncBlizzardArt()
end

MinimapLayer = {
	tile = 1600 / 3,
	instances = {
		[1414] = 1,
		[1415] = 0
	},
	data = {},
	parsed = {},
	transforms = {},
	masks = {},
	waterMasks = {},
	active = {},
	pools = {},
	fadeStart = 140,
	fadeEnd = 320,
	maxAlpha = 1,
	maxTiles = 100,
	desaturation = 0.35,
	tint = {1, 0.93, 0.8},
	cityFactor = 2.5,
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

function MinimapLayer.GetTransform(continentID)
	local transform = MinimapLayer.transforms[continentID]
	if transform ~= nil then return transform or nil end
	MinimapLayer.transforms[continentID] = false
	local instance = MinimapLayer.instances[continentID]
	if instance == nil or C_Map.GetWorldPosFromMapPos == nil or CreateVector2D == nil then return nil end
	local left, right, top, bottom = C_Map.GetMapRectOnMap(continentID, WORLD)
	if left == nil or right <= left or bottom <= top then return nil end
	local points = {}
	for _, point in ipairs({{0.25, 0.25}, {0.75, 0.25}, {0.25, 0.75}}) do
		local _, position = C_Map.GetWorldPosFromMapPos(continentID, CreateVector2D(point[1], point[2]))
		if position == nil then return nil end
		local yardX, yardY = position:GetXY()
		tinsert(points, {yardX, yardY, left + point[1] * (right - left), top + point[2] * (bottom - top)})
	end

	local dX1, dY1 = points[2][1] - points[1][1], points[2][2] - points[1][2]
	local dX2, dY2 = points[3][1] - points[1][1], points[3][2] - points[1][2]
	local denominator = dX1 * dY2 - dY1 * dX2
	if denominator == 0 then return nil end
	local du1, du2 = points[2][3] - points[1][3], points[3][3] - points[1][3]
	local dv1, dv2 = points[2][4] - points[1][4], points[3][4] - points[1][4]
	local a, b = (du1 * dY2 - dY1 * du2) / denominator, (dX1 * du2 - du1 * dX2) / denominator
	local c, d = (dv1 * dY2 - dY1 * dv2) / denominator, (dX1 * dv2 - dv1 * dX2) / denominator
	transform = {points[1][3] - a * points[1][1] - b * points[1][2], points[1][4] - c * points[1][1] - d * points[1][2], a, b, c, d}
	local det = a * d - b * c
	if det == 0 then return nil end
	transform[7] = det
	MinimapLayer.transforms[continentID] = transform

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

	mask:SetTexture(geometry[1], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetSize(geometry[2], geometry[3])
	mask:ClearAllPoints()
	mask:SetPoint("TOPLEFT", container, "TOPLEFT", geometry[4], geometry[5])

	return mask
end

function MinimapLayer.Release(key)
	local texture = MinimapLayer.active[key]
	texture:Hide()
	MinimapLayer.active[key] = nil
	tinsert(MinimapLayer.pools[texture.continentID], texture)
end

function MinimapLayer.HideAll()
	for key in pairs(MinimapLayer.active) do
		MinimapLayer.Release(key)
	end

	MinimapLayer.signature = nil
end

function MinimapLayer.Acquire(continentID, mask)
	local pool = MinimapLayer.pools[continentID]
	if pool == nil then
		pool = {}
		MinimapLayer.pools[continentID] = pool
	end

	local texture = tremove(pool)
	if texture == nil then
		texture = MinimapLayer.frame:CreateTexture(nil, "ARTWORK")
		texture.continentID = continentID
		if texture.SetDesaturation ~= nil then texture:SetDesaturation(MinimapLayer.desaturation) end
		texture:SetVertexColor(MinimapLayer.tint[1], MinimapLayer.tint[2], MinimapLayer.tint[3])
	end

	if texture.mask ~= mask then
		if texture.mask ~= nil then texture:RemoveMaskTexture(texture.mask) end
		if mask ~= nil then texture:AddMaskTexture(mask) end
		texture.mask = mask
	end

	return texture
end

function MinimapLayer.Place(texture, transform, northX, westY, size, source)
	local u1, v1 = MinimapLayer.ToWorld(transform, northX, westY)
	local u2, v2 = MinimapLayer.ToWorld(transform, northX - size, westY - size)
	texture:SetTexture(source, nil, nil, "LINEAR")
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", container, "TOPLEFT", math.min(u1, u2) * container.refWidth, -math.min(v1, v2) * container.refHeight)
	texture:SetSize(math.abs(u2 - u1) * container.refWidth, math.abs(v2 - v1) * container.refHeight)
	texture:Show()
	MinimapLayer.lastPlaced = texture
end

function MinimapLayer.GetWaterMask(continentID, tileX, tileY, transform)
	local lod = MinimapLayer.GetLOD(MinimapLayer.instances[continentID])
	if lod == nil then return nil end
	local col, row = math.floor(tileX / lod.group), math.floor(tileY / lod.group)
	local name = lod.masks[col * 64 + row]
	if name == nil then return nil end
	local key = continentID * 4096 + col * 64 + row
	local mask = MinimapLayer.waterMasks[key]
	if mask == nil then
		mask = MinimapLayer.frame:CreateMaskTexture()
		mask:SetTexture(MinimapLayer.lodPath .. name, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
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

function MinimapLayer.Update()
	if container == nil or MinimapLayer.frame == nil then return end
	local style = type(MAUTTAB) == "table" and MAUTTAB["MAPSTYLE"] or "MIXED"
	if not container:IsShown() or container.refWidth == nil or style == "MAP" then
		if MinimapLayer.signature ~= nil then MinimapLayer.HideAll() end

		return
	end

	local terrain = style == "TERRAIN"
	local scrollContainer = WorldMapFrame.ScrollContainer
	local host = WorldMapFrame:GetMapID()
	local hostLeft, hostRight, hostTop, hostBottom = GetSpaceRect(host)
	if hostLeft == nil and container.cityMode then hostLeft, hostRight, hostTop, hostBottom = GetCityHostRect(host) end
	local scale = scrollContainer:GetCanvasScale()
	local x, y = scrollContainer:GetCurrentScrollX(), scrollContainer:GetCurrentScrollY()
	local width, height = scrollContainer.Child:GetSize()
	if hostLeft == nil or x == nil or y == nil or scale == nil or scale <= 0 or width == nil or width <= 0 or height == nil or height <= 0 then return end
	local signature = format("%s:%s:%.5f:%.5f:%.5f", tostring(host), style, scale, x, y)
	if signature == MinimapLayer.signature then return end
	MinimapLayer.signature = signature
	local spaceWidth, spaceHeight = hostRight - hostLeft, hostBottom - hostTop
	local centerU, centerV = (x - hostLeft) / spaceWidth, (y - hostTop) / spaceHeight
	local halfU = scrollContainer:GetWidth() / (2 * scale * width) / spaceWidth
	local halfV = scrollContainer:GetHeight() / (2 * scale * height) / spaceHeight
	local wanted = {}
	local alpha = 0
	for _, continentID in ipairs(CONTINENTS) do
		local entry = base.continents[continentID]
		local transform = entry and entry.drawn and MinimapLayer.GetTransform(continentID)
		local tiles = transform and MinimapLayer.GetTiles(MinimapLayer.instances[continentID])
		if tiles then
			local tileU = math.abs(transform[4]) * MinimapLayer.tile
			local tilePixels = tileU * spaceWidth * width * scale
			local factor = container.cityMode and MinimapLayer.cityFactor or 1
			local fadeStart, fadeEnd = MinimapLayer.fadeStart * factor, MinimapLayer.fadeEnd * factor
			local maxScale = container.cityMode and scrollContainer.GetScaleForMaxZoom ~= nil and scrollContainer:GetScaleForMaxZoom()
			if maxScale and maxScale > 0 then
				local maxPixels = tilePixels * maxScale / scale
				if maxPixels < fadeEnd then fadeStart, fadeEnd = fadeStart * maxPixels / fadeEnd, maxPixels end
			end

			local share = (tilePixels - fadeStart) / (fadeEnd - fadeStart)
			if terrain then share = 1 end
			if share > 0 then
				local minX, maxX, minY, maxY
				for _, corner in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
					local yardX, yardY = MinimapLayer.ToYards(transform, centerU + corner[1] * halfU, centerV + corner[2] * halfV)
					minX, maxX = math.min(minX or yardX, yardX), math.max(maxX or yardX, yardX)
					minY, maxY = math.min(minY or yardY, yardY), math.max(maxY or yardY, yardY)
				end

				local x0, x1 = math.max(0, math.floor(32 - maxY / MinimapLayer.tile)), math.min(63, math.floor(32 - minY / MinimapLayer.tile))
				local y0, y1 = math.max(0, math.floor(32 - maxX / MinimapLayer.tile)), math.min(63, math.floor(32 - minX / MinimapLayer.tile))
				local count = (x1 - x0 + 1) * (y1 - y0 + 1)
				local lod = terrain and count > MinimapLayer.terrainMaxTiles and MinimapLayer.GetLOD(MinimapLayer.instances[continentID])
				if x1 >= x0 and y1 >= y0 and (count <= (terrain and MinimapLayer.terrainMaxTiles or MinimapLayer.maxTiles) or lod) then
					alpha = math.max(alpha, MinimapLayer.maxAlpha * math.min(1, share))
					local mask = MinimapLayer.GetMask(continentID)
					if lod then
						local group = lod.group
						for col = math.floor(x0 / group), math.floor(x1 / group) do
							for row = math.floor(y0 / group), math.floor(y1 / group) do
								local name = lod.pieces[col * 64 + row]
								if name ~= nil then
									local key = -(continentID * 4096 + col * 64 + row)
									wanted[key] = true
									if MinimapLayer.active[key] == nil then
										local northX, westY = (32 - row * group) * MinimapLayer.tile, (32 - col * group) * MinimapLayer.tile
										MinimapLayer.Place(MinimapLayer.Acquire(continentID, mask), transform, northX, westY, group * MinimapLayer.tile, MinimapLayer.lodPath .. name)
										MinimapLayer.active[key] = MinimapLayer.lastPlaced
									end
								end
							end
						end
					else
						for tileX = x0, x1 do
							for tileY = y0, y1 do
								local fileID = tiles[tileX * 64 + tileY]
								if fileID ~= nil then
									local key = continentID * 4096 + tileX * 64 + tileY
									wanted[key] = true
									if MinimapLayer.active[key] == nil then
										MinimapLayer.Place(MinimapLayer.Acquire(continentID, MinimapLayer.GetWaterMask(continentID, tileX, tileY, transform) or mask), transform, (32 - tileY) * MinimapLayer.tile, (32 - tileX) * MinimapLayer.tile, MinimapLayer.tile, fileID)
										MinimapLayer.active[key] = MinimapLayer.lastPlaced
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
end

local function Install()
	if hooked then return true end
	if WorldMapFrame == nil or WorldMapFrame.ScrollContainer == nil or WorldMapFrame.ScrollContainer.Child == nil then return false end
	hooked = true
	local child = WorldMapFrame.ScrollContainer.Child
	container = CreateFrame("FRAME", nil, child)
	container:EnableMouse(false)
	container:Hide()
	hooksecurefunc(
		WorldMapFrame,
		"OnMapChanged",
		function()
			Update(false)
			SyncBlizzardArt()
		end
	)
	WorldMapFrame:HookScript("OnShow", function() Update(false) end)
	child:HookScript("OnSizeChanged", function() Update(false) end)
	WorldMapFrame.ScrollContainer:HookScript(
		"OnUpdate",
		function()
			SyncBlizzardArt()
			UpdateCityAlpha()
			MinimapLayer.Update()
		end
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
				if WorldMapFrame:IsShown() then Update(true) end
			end

			return
		end

		Install()
	end
)
