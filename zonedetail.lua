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

local function ShowBase()
	for _, entry in pairs(base.continents) do
		for _, texture in pairs(entry.pool) do
			texture:SetShown(entry.drawn and texture.used == true)
		end
	end

	for _, texture in pairs(base.world) do
		texture:SetShown(texture.used == true)
	end
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
	if left == nil or container.refWidth == nil then return false end
	local scale = (right - left) * width / container.refWidth
	if scale <= 0 then return false end
	container:SetScale(scale)
	container:ClearAllPoints()
	container:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", left * width / scale, -top * height / scale)

	return true
end

local function SyncBlizzardArt()
	local hide = container ~= nil and container:IsShown()
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

	if GetSpaceRect(mapID) == nil then
		container.signature = nil
		container:Hide()

		return
	end

	ShowBase()

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

	for _, city in pairs(cities) do
		city.frame:SetFrameLevel(level + 3)
	end

	container:Show()
	container.cityScale = nil
	UpdateCityAlpha()
end

function MapUtils:RefreshZoneDetail()
	Update(true)
	SyncBlizzardArt()
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
