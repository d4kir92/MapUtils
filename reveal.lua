local _, MapUtils = ...
local PIN_TEMPLATE = "MapExplorationPinTemplate"
local ZONE_MAP_TYPE = 3
local DEFAULT_TINT = "BLUE"
local TINT_ORDER = {"BLUE", "GRAY", "DARK", "FADED", "GOLD", "GREEN", "RED", "PURPLE", "NONE"}
local TINTS = {
	["BLUE"] = {0.6, 0.6, 1, 1},
	["GRAY"] = {0.85, 0.85, 0.85, 1, true},
	["DARK"] = {0.45, 0.45, 0.45, 1},
	["FADED"] = {1, 1, 1, 0.45},
	["GOLD"] = {1, 0.85, 0.45, 1},
	["GREEN"] = {0.55, 1, 0.55, 1},
	["RED"] = {1, 0.5, 0.5, 1},
	["PURPLE"] = {0.8, 0.55, 1, 1},
	["NONE"] = {1, 1, 1, 1}
}

local flavor = nil
local revealData = {}
local overlayCache = {}
local states = {}
do
	local toc = select(4, GetBuildInfo()) or 0
	if toc >= 20000 and toc < 30000 then
		flavor = "tbc"
	elseif toc >= 16000 and toc < 20000 then
		flavor = "forever"
	elseif toc >= 11000 and toc < 16000 then
		flavor = "era"
	end
end

function MapUtils:AddRevealData(dataFlavor, artID, data)
	if dataFlavor ~= flavor then return end
	revealData[artID] = data
end

function MapUtils:HasRevealData()
	return next(revealData) ~= nil
end

function MapUtils:IsAddOnActive(name)
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) == true end
	if IsAddOnLoaded then return IsAddOnLoaded(name) == true end

	return false
end

function MapUtils:IsRevealedByLeatrix()
	if not MapUtils:IsAddOnActive("Leatrix_Maps") then return false end

	return not (type(LeaMapsDB) == "table" and LeaMapsDB["RevealMap"] == "Off")
end

local function IsEnabled()
	if type(MAUTTAB) == "table" and MAUTTAB["REVEALMAP"] == false then return false end

	return not MapUtils:IsRevealedByLeatrix()
end

local function GetTint(mapID)
	local info = C_Map.GetMapInfo(mapID)
	if info == nil or info.mapType ~= ZONE_MAP_TYPE then return TINTS["NONE"] end
	local key = type(MAUTTAB) == "table" and MAUTTAB["REVEALTINT"] or DEFAULT_TINT

	return TINTS[key] or TINTS[DEFAULT_TINT]
end

function MapUtils:GetRevealTintChoices()
	local choices = {}
	for _, key in ipairs(TINT_ORDER) do
		local tint = TINTS[key]
		local color = format("%02x%02x%02x", math.floor(tint[1] * 255 + 0.5), math.floor(tint[2] * 255 + 0.5), math.floor(tint[3] * 255 + 0.5))
		tinsert(
			choices,
			{
				["value"] = key,
				["label"] = "|cff" .. color .. MapUtils:Trans("LID_TINT" .. key) .. "|r"
			}
		)
	end

	return choices
end

local function GetOverlays(artID)
	if overlayCache[artID] ~= nil then return overlayCache[artID] end
	local data = revealData[artID]
	if data == nil then return nil end
	local overlays = {}
	for entry in string.gmatch(data, "[^;]+") do
		local width, height, offsetX, offsetY, files = string.match(entry, "^(%d+):(%d+):(%d+):(%d+)=(.+)$")
		if width ~= nil then
			local fileIDs = {}
			for fileID in string.gmatch(files, "%d+") do
				tinsert(fileIDs, tonumber(fileID))
			end

			tinsert(
				overlays,
				{
					["width"] = tonumber(width),
					["height"] = tonumber(height),
					["offsetX"] = tonumber(offsetX),
					["offsetY"] = tonumber(offsetY),
					["files"] = fileIDs
				}
			)
		end
	end

	overlayCache[artID] = overlays

	return overlays
end

local function GetState(pin)
	local state = states[pin]
	if state == nil then
		state = {
			["textures"] = {},
			["count"] = 0
		}

		states[pin] = state
	end

	return state
end

local function ClearPin(pin)
	local state = GetState(pin)
	for i = 1, state.count do
		state.textures[i]:Hide()
	end

	state.count = 0
end

local function AcquireTexture(pin, state)
	state.count = state.count + 1
	local texture = state.textures[state.count]
	if texture == nil then
		texture = pin:CreateTexture(nil, "ARTWORK")
		state.textures[state.count] = texture
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

local function DrawOverlay(pin, state, overlay, layer, drawLayer, subLevel, tint)
	local tileWidth = layer.tileWidth
	local tileHeight = layer.tileHeight
	local wide = math.ceil(overlay.width / tileWidth)
	local tall = math.ceil(overlay.height / tileHeight)
	for row = 1, tall do
		local pixelHeight, fileHeight = GetTileSize(overlay.height, tileHeight, row, tall)
		for col = 1, wide do
			local fileID = overlay.files[(row - 1) * wide + col]
			if fileID ~= nil then
				local pixelWidth, fileWidth = GetTileSize(overlay.width, tileWidth, col, wide)
				local texture = AcquireTexture(pin, state)
				texture:SetDrawLayer(drawLayer, subLevel)
				texture:SetSize(pixelWidth, pixelHeight)
				texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", pin, "TOPLEFT", overlay.offsetX + tileWidth * (col - 1), -(overlay.offsetY + tileHeight * (row - 1)))
				texture:SetTexture(fileID, nil, nil, "TRILINEAR")
				texture:SetDesaturated(tint[5] == true)
				texture:SetVertexColor(tint[1], tint[2], tint[3], tint[4])
				texture:Show()
			end
		end
	end
end

local function GetDrawLayer(pin)
	local drawLayer, subLevel = "ARTWORK", 0
	if pin.dataProvider ~= nil and pin.dataProvider.GetDrawLayer ~= nil then drawLayer, subLevel = pin.dataProvider:GetDrawLayer() end

	return drawLayer, max(-8, (subLevel or 0) - 1)
end

local function GetLayerIndex(map)
	local container = map:GetCanvasContainer()
	if container == nil or type(container.zoomLevels) ~= "table" or container.zoomLevels[1] == nil then return nil end

	return container:GetCurrentLayerIndex()
end

local function RefreshPin(pin)
	ClearPin(pin)
	if not IsEnabled() then return end
	local state = GetState(pin)
	local map = pin:GetMap()
	local mapID = map and map:GetMapID()
	if mapID == nil then return end
	local artID = C_Map.GetMapArtID(mapID)
	local overlays = artID and GetOverlays(artID)
	if overlays == nil then return end
	local layerIndex = GetLayerIndex(map)
	if layerIndex == nil then return end
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[layerIndex]
	if layer == nil then return end
	local explored = {}
	local exploredTextures = C_MapExplorationInfo.GetExploredMapTextures(mapID)
	if exploredTextures ~= nil then
		for _, info in ipairs(exploredTextures) do
			explored[info.offsetX .. ":" .. info.offsetY] = true
		end
	end

	local drawLayer, subLevel = GetDrawLayer(pin)
	local tint = GetTint(mapID)
	for _, overlay in ipairs(overlays) do
		if not explored[overlay.offsetX .. ":" .. overlay.offsetY] then DrawOverlay(pin, state, overlay, layer, drawLayer, subLevel, tint) end
	end
end

local function HookMap(map)
	if map == nil or map.EnumeratePinsByTemplate == nil then return false end
	for pin in map:EnumeratePinsByTemplate(PIN_TEMPLATE) do
		if states[pin] == nil then
			GetState(pin)
			hooksecurefunc(pin, "RefreshOverlays", RefreshPin)
			hooksecurefunc(pin, "RemoveAllData", ClearPin)
			RefreshPin(pin)
		end
	end

	return true
end

function MapUtils:RefreshReveal()
	for pin in pairs(states) do
		RefreshPin(pin)
	end
end

local loader = CreateFrame("FRAME")
MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
MapUtils:RegisterEvent(loader, "ADDON_LOADED")
loader:SetScript(
	"OnEvent",
	function(self)
		if flavor == nil or not MapUtils:HasRevealData() then
			self:UnregisterAllEvents()

			return
		end

		HookMap(WorldMapFrame)
		if HookMap(BattlefieldMapFrame) then self:UnregisterAllEvents() end
	end
)
