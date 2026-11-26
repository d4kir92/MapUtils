local _, MapUtils = ...
local WATCH_INTERVAL = 0.05
local MAX_ZOOM = 8
local ARROW_SIZE = 24
local POS_MAX_AGE = 3.0
local IM = {
	["plan"] = nil,
	["planOverlay"] = nil,
	["btn"] = nil,
	["btnOverlay"] = nil,
	["arrow"] = nil,
	["arrowParent"] = nil,
	["arrowPx"] = nil,
	["arrowPy"] = nil,
	["arrowMode"] = nil,
	["arrowRot"] = nil,
	["arrowArtX"] = nil,
	["arrowArtY"] = nil,
	["cachedOverlay"] = nil,
	["btnOn"] = nil,
	["tiles"] = {},
	["builtInst"] = nil,
	["activeInst"] = nil,
	["activeFloor"] = nil,
	["activeKey"] = nil,
	["zoom"] = 1,
	["panX"] = 0,
	["panY"] = 0,
	["baseW"] = 0,
	["baseH"] = 0,
	["lastW"] = 0,
	["lastH"] = 0,
	["drag"] = nil,
	["watchFrame"] = nil,
}

local function IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v) == true
end

local function IsMinimapViewOn()
	return MapUtils:GetConfig("INSTANCEPLANMINIMAP", true) ~= false
end

local function SetMinimapViewOn(enabled)
	if MapUtils.SetMapOption ~= nil then
		MapUtils:SetMapOption("INSTANCEPLANMINIMAP", enabled == true)
	elseif MAUTTAB ~= nil and MapUtils.SV ~= nil then
		MapUtils:SV(MAUTTAB, "INSTANCEPLANMINIMAP", enabled == true)
	end
end

local function GetMapData(instID)
	local store = MapUtils.INSTANCEMINIMAP
	if store == nil or store.maps == nil or instID == nil then return nil end
	return store.maps[instID]
end

local Refresh
local function ExtractArtKey(tex)
	if IsSecret(tex) or type(tex) ~= "string" then return nil end
	if strfind(tex, "[\\/]") == nil then return nil end
	local stem = strmatch(tex, "([^\\/]+)$")
	if stem == nil or stem == "" then return nil end
	stem = gsub(stem, "%.[^%.]+$", "")
	return stem
end

local function GetOverlayArtKey(artTex)
	if artTex == nil then return nil end
	local key = ExtractArtKey(artTex._muTexPath)
	if key ~= nil then return key end
	if artTex.GetTextureFilePath ~= nil then
		key = ExtractArtKey(artTex:GetTextureFilePath())
		if key ~= nil then return key end
	end
	key = ExtractArtKey(artTex:GetTexture())
	if key ~= nil then return key end
	if type(MapUtils.activeInstanceArtKey) == "string" and MapUtils.activeInstanceArtKey ~= "" then
		return MapUtils.activeInstanceArtKey
	end
	return nil
end

local function HookArtTexture(artTex)
	if artTex == nil or artTex._muHooked then return end
	artTex._muHooked = true
	hooksecurefunc(artTex, "SetTexture", function(self, tex)
		self._muTexPath = type(tex) == "string" and tex or nil
		if Refresh ~= nil then Refresh() end
	end)
end

local function MatchOverlayData(artKey)
	local store = MapUtils.INSTANCEMINIMAP
	if store == nil or store.maps == nil or store.art == nil or artKey == nil then return nil, nil end
	local ref = store.art[artKey] or store.art[strlower(artKey)]
	if ref == nil then return nil, nil end
	local mapData = store.maps[ref[1]]
	if mapData == nil then return nil, nil end
	return ref[1], ref[2] or 0
end

local function FindRawOverlay()
	if WorldMapFrame == nil or not WorldMapFrame:IsShown() then return nil, nil end
	local cached = IM.cachedOverlay
	if cached ~= nil and cached.art ~= nil and cached:IsShown() then
		local artKey = GetOverlayArtKey(cached.art)
		if artKey ~= nil then return cached, artKey end
	end
	local container = WorldMapFrame.ScrollContainer
	if container == nil then return nil, nil end
	local children = {container:GetChildren()}
	for i = 1, #children do
		local child = children[i]
		if child ~= nil and child.art ~= nil and child.bg ~= nil and child.credit ~= nil then
			HookArtTexture(child.art)
			if child:IsShown() then
				IM.cachedOverlay = child
				local artKey = GetOverlayArtKey(child.art)
				if artKey ~= nil then return child, artKey end
			end
		end
	end
	return nil, nil
end

local function GetCurrentInstanceID()
	if IsInInstance == nil or GetInstanceInfo == nil then return nil end
	local inInst = IsInInstance()
	if not inInst then return nil end
	local instID = select(8, GetInstanceInfo())
	if IsSecret(instID) or type(instID) ~= "number" or instID <= 0 then return nil end
	return instID
end

local function EnsureArrow(parent, level)
	local a = IM.arrow
	if a == nil then
		a = CreateFrame("Frame", nil, parent)
		a:SetSize(ARROW_SIZE, ARROW_SIZE)
		a:EnableMouse(false)
		local tex = a:CreateTexture(nil, "OVERLAY")
		tex:SetAllPoints(a)
		tex:SetTexture("Interface\\Minimap\\MinimapArrow")
		a.tex = tex
		a:Hide()
		IM.arrow = a
		IM.arrowParent = parent
	elseif IM.arrowParent ~= parent then
		a:SetParent(parent)
		IM.arrowParent = parent
	end
	a:SetFrameLevel(level)
	return a
end

local function HideArrow()
	if IM.arrow ~= nil then IM.arrow:Hide() end
	IM.arrowPx = nil
	IM.arrowPy = nil
	IM.arrowMode = nil
	IM.arrowRot = nil
	IM.arrowArtX = nil
	IM.arrowArtY = nil
end

local function PlacePlanArrow(mapData)
	if IM.arrow == nil or IM.arrowMode ~= "plan" or IM.arrowPx == nil or IM.plan == nil or mapData == nil or IM.baseW <= 0 then return end
	local tileScale = (IM.baseW * IM.zoom) / mapData.w
	IM.arrow:ClearAllPoints()
	IM.arrow:SetPoint("CENTER", IM.plan.canvas, "TOPLEFT", IM.arrowPx * tileScale, -IM.arrowPy * tileScale)
end

local function GetCursorOffset()
	if IM.plan == nil then return nil end
	local scale = IM.plan:GetEffectiveScale()
	local cx, cy = IM.plan:GetCenter()
	if scale == nil or scale <= 0 or cx == nil then return nil end
	local mx, my = GetCursorPosition()
	return mx / scale - cx, my / scale - cy
end

local function HasFloorBit(mask, floorIdx)
	if floorIdx == nil or floorIdx <= 0 then return true end
	if mask == nil or mask <= 0 then return false end
	local bitVal = 2 ^ (floorIdx - 1)
	return math.floor(mask / bitVal) % 2 == 1
end

local function ApplyFloorStyling(floorIdx)
	local plan = IM.plan
	if plan == nil then return end
	local showAll = floorIdx == nil or floorIdx <= 0
	for i = 1, #IM.tiles do
		local t = IM.tiles[i]
		local tex = plan.textures[i]
		if tex ~= nil then
			local active = showAll or HasFloorBit(t[6], floorIdx)
			if active then
				tex:SetDrawLayer("ARTWORK", 2)
				tex:SetVertexColor(1, 1, 1, 1)
				tex:SetAlpha(1)
			else
				tex:SetDrawLayer("ARTWORK", 0)
				tex:SetVertexColor(0.6, 0.65, 0.78, 1)
				tex:SetAlpha(0.18)
			end
		end
	end
end

local function ApplyView(mapData)
	local plan = IM.plan
	if plan == nil or mapData == nil or IM.baseW <= 0 or IM.baseH <= 0 then return end
	local cw = IM.baseW * IM.zoom
	local ch = IM.baseH * IM.zoom
	local pw = plan:GetWidth() or 0
	local ph = plan:GetHeight() or 0
	local maxX = math.max(0, (cw - pw) * 0.5)
	local maxY = math.max(0, (ch - ph) * 0.5)
	IM.panX = math.min(maxX, math.max(-maxX, IM.panX))
	IM.panY = math.min(maxY, math.max(-maxY, IM.panY))
	plan.canvas:SetSize(cw, ch)
	plan.canvas:ClearAllPoints()
	plan.canvas:SetPoint("CENTER", plan, "CENTER", IM.panX, IM.panY)
	local tileScale = cw / mapData.w
	local isAdt = mapData.kind == "adt"
	for i = 1, #IM.tiles do
		local t = IM.tiles[i]
		local tex = plan.textures[i]
		if tex ~= nil then
			if isAdt then
				tex:SetSize(t[4] * tileScale, t[5] * tileScale)
			else
				tex:SetSize(t[5] * tileScale, t[4] * tileScale)
			end
			tex:ClearAllPoints()
			tex:SetPoint("TOPLEFT", plan.canvas, "TOPLEFT", t[2] * tileScale, -t[3] * tileScale)
		end
	end
	PlacePlanArrow(mapData)
end

local function FitFloorView(overlay, mapData, floorIdx)
	local ow = overlay:GetWidth() or 0
	local oh = overlay:GetHeight() or 0
	if ow <= 0 or oh <= 0 or IM.baseW <= 0 or IM.baseH <= 0 then return end
	local box = floorIdx ~= nil and floorIdx > 0 and mapData.floors ~= nil and mapData.floors[floorIdx] or nil
	if box == nil then
		IM.zoom = 1
		IM.panX = 0
		IM.panY = 0
		ApplyView(mapData)
		return
	end
	local bw = math.max(64, (box[3] - box[1]) * 1.15)
	local bh = math.max(64, (box[4] - box[2]) * 1.15)
	local baseScale = IM.baseW / mapData.w
	local zx = ow / (bw * baseScale)
	local zy = oh / (bh * baseScale)
	IM.zoom = math.min(MAX_ZOOM, math.max(1, math.min(zx, zy)))
	local tileScale = (IM.baseW * IM.zoom) / mapData.w
	local cx = (box[1] + box[3]) * 0.5
	local cy = (box[2] + box[4]) * 0.5
	IM.panX = -(cx - mapData.w * 0.5) * tileScale
	IM.panY = -(mapData.h * 0.5 - cy) * tileScale
	ApplyView(mapData)
end

local function LayoutPlan(overlay, mapData, floorIdx, forceFit)
	if IM.plan == nil or mapData == nil then return end
	local ow = overlay:GetWidth() or 0
	local oh = overlay:GetHeight() or 0
	if ow <= 0 or oh <= 0 then return end
	local resized = ow ~= IM.lastW or oh ~= IM.lastH or IM.baseW <= 0
	if not resized and not forceFit then return end
	IM.lastW = ow
	IM.lastH = oh
	local ratio = mapData.h / mapData.w
	local bw = ow
	local bh = ow * ratio
	if bh > oh then
		bh = oh
		bw = oh / ratio
	end
	IM.baseW = bw
	IM.baseH = bh
	if forceFit then
		FitFloorView(overlay, mapData, floorIdx)
	else
		ApplyView(mapData)
	end
end

local function BuildTiles(plan, instID, mapData)
	wipe(IM.tiles)
	local isAdt = mapData.kind == "adt"
	local idx = 0
	for item in string.gmatch(mapData.tiles, "[^,]+") do
		local fid, col, row, tw, th, mask = strsplit(":", item)
		fid = tonumber(fid)
		col = tonumber(col)
		row = tonumber(row)
		tw = tonumber(tw)
		th = tonumber(th)
		mask = tonumber(mask) or 0
		if fid ~= nil and col ~= nil and row ~= nil and tw ~= nil and th ~= nil then
			idx = idx + 1
			IM.tiles[idx] = {fid, col, row, tw, th, mask}
			local tex = plan.textures[idx]
			if tex == nil then
				tex = plan.canvas:CreateTexture(nil, "ARTWORK")
				plan.textures[idx] = tex
			end
			tex:SetTexture(fid)
			if isAdt then
				tex:SetTexCoord(0, 1, 0, 1)
			else
				tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
			end
			tex:Show()
		end
	end
	for i = idx + 1, #plan.textures do
		plan.textures[i]:Hide()
	end
	IM.builtInst = instID
	IM.zoom = 1
	IM.panX = 0
	IM.panY = 0
	IM.drag = nil
	IM.lastW = 0
	IM.lastH = 0
end

local function EnsurePlan(overlay, instID, mapData)
	if IM.plan == nil then
		local p = CreateFrame("Frame", nil, overlay)
		p:SetAllPoints(overlay)
		if p.SetClipsChildren ~= nil then p:SetClipsChildren(true) end
		p:EnableMouse(true)
		p:EnableMouseWheel(true)
		p.bg = p:CreateTexture(nil, "BACKGROUND")
		p.bg:SetAllPoints(p)
		p.bg:SetColorTexture(0, 0, 0, 1)
		p.canvas = CreateFrame("Frame", nil, p)
		p.canvas:SetPoint("CENTER", p, "CENTER", 0, 0)
		p.textures = {}
		p:SetScript("OnMouseWheel", function(_, delta)
			local cur = GetMapData(IM.activeInst)
			if cur == nil then return end
			local z = math.min(MAX_ZOOM, math.max(1, IM.zoom * (1.25 ^ delta)))
			if z == IM.zoom then return end
			local dx, dy = GetCursorOffset()
			if dx ~= nil then
				local f = z / IM.zoom
				IM.panX = dx - (dx - IM.panX) * f
				IM.panY = dy - (dy - IM.panY) * f
			end
			IM.zoom = z
			ApplyView(cur)
		end)
		p:SetScript("OnMouseDown", function(_, button)
			if button ~= "LeftButton" or IM.zoom <= 1 then return end
			local dx, dy = GetCursorOffset()
			if dx ~= nil then IM.drag = {dx, dy, IM.panX, IM.panY} end
		end)
		p:SetScript("OnMouseUp", function(_, button)
			if button == "LeftButton" then IM.drag = nil end
			if button == "RightButton" and MapUtils.ToggleInstanceMap ~= nil then
				MapUtils:ToggleInstanceMap()
			end
		end)
		p:SetScript("OnUpdate", function()
			local d = IM.drag
			if d == nil then return end
			if not IsMouseButtonDown("LeftButton") then
				IM.drag = nil
				return
			end
			local cur = GetMapData(IM.activeInst)
			local dx, dy = GetCursorOffset()
			if dx == nil or cur == nil then return end
			IM.panX = d[3] + dx - d[1]
			IM.panY = d[4] + dy - d[2]
			ApplyView(cur)
		end)
		p:Hide()
		IM.plan = p
		IM.planOverlay = overlay
	elseif IM.planOverlay ~= overlay then
		IM.plan:SetParent(overlay)
		IM.plan:ClearAllPoints()
		IM.plan:SetAllPoints(overlay)
		IM.planOverlay = overlay
		IM.lastW = 0
		IM.lastH = 0
	end
	IM.plan:SetFrameLevel(overlay:GetFrameLevel() + 400)
	IM.plan.canvas:SetFrameLevel(overlay:GetFrameLevel() + 410)
	if IM.builtInst ~= instID then
		BuildTiles(IM.plan, instID, mapData)
	end
	return IM.plan
end

local function FindBossSlider()
	if WorldMapFrame == nil or WorldMapFrame.ScrollContainer == nil then return nil end
	local children = {WorldMapFrame.ScrollContainer:GetChildren()}
	for i = 1, #children do
		local child = children[i]
		if child ~= nil and child:IsShown() and child.bossScale ~= nil and child.bossScale:IsShown() then
			return child.bossScale
		end
	end
	return nil
end

local function CreateToggleButton(overlay)
	local btn
	if MapUtils.CreateButton ~= nil then
		btn = MapUtils:CreateButton(nil, overlay)
	elseif DoesTemplateExist ~= nil and DoesTemplateExist("GameMenuButtonTemplate") then
		btn = CreateFrame("Button", nil, overlay, "GameMenuButtonTemplate")
	else
		btn = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
	end
	btn:SetHeight(26)
	return btn
end

local function UpdateButtonText(btn)
	local on = IsMinimapViewOn()
	local key = on and "LID_MAPVIEW" or "LID_MINIMAPVIEW"
	local fallback = on and "Map view" or "Minimap view"
	local label = MapUtils.Trans ~= nil and MapUtils:Trans(key) or fallback
	btn:SetText(label)
	local fs = btn.GetFontString ~= nil and btn:GetFontString() or btn.Text
	local tw = fs ~= nil and fs.GetStringWidth ~= nil and fs:GetStringWidth() or (btn.GetTextWidth ~= nil and btn:GetTextWidth() or 90)
	btn:SetWidth(math.max(108, tw + 30))
end

local function AnchorToggleButton(btn, overlay)
	local slider = FindBossSlider()
	btn:ClearAllPoints()
	if slider ~= nil then
		btn:SetPoint("RIGHT", slider, "LEFT", -14, 0)
	else
		btn:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 14, 10)
	end
end

local function HideVisuals()
	if IM.plan ~= nil then IM.plan:Hide() end
	if IM.btn ~= nil then IM.btn:Hide() end
	HideArrow()
	if MapUtils.StopInstancePosition ~= nil then MapUtils:StopInstancePosition() end
	IM.activeInst = nil
	IM.activeFloor = nil
	IM.activeKey = nil
	IM.drag = nil
end

local function UpdatePlayerArrow(overlay, artKey, mapData, mmInstID)
	local playerInst = GetCurrentInstanceID()
	local artBounds = MapUtils.GetInstanceArtBounds ~= nil and MapUtils:GetInstanceArtBounds(artKey) or nil
	local overlayInst = mmInstID or (artBounds ~= nil and artBounds[1] or nil)
	local enabled = MapUtils.IsInstancePositionEnabled ~= nil and MapUtils:IsInstancePositionEnabled()
	if overlay == nil or playerInst == nil or overlayInst ~= playerInst or not enabled then
		HideArrow()
		if MapUtils.StopInstancePosition ~= nil then MapUtils:StopInstancePosition() end
		return
	end

	local wx, wy, heading, age
	if UnitPosition ~= nil then
		local nx, ny = UnitPosition("player")
		if not IsSecret(nx) and not IsSecret(ny) and type(nx) == "number" and type(ny) == "number" then
			wx, wy, age = nx, ny, 0
			if MapUtils.StopInstancePosition ~= nil then MapUtils:StopInstancePosition() end
		end
	end
	if wx == nil then
		if MapUtils.StartInstancePosition ~= nil then MapUtils:StartInstancePosition(playerInst) end
		if MapUtils.GetInstancePosition ~= nil then
			local fx, fy, _, fhead, fage = MapUtils:GetInstancePosition()
			if fx ~= nil and fage ~= nil and fage <= POS_MAX_AGE then
				wx, wy, heading, age = fx, fy, fhead, fage
			end
		end
	end
	if wx == nil or age == nil then
		HideArrow()
		return
	end

	local facing = nil
	if GetPlayerFacing ~= nil then
		local f = GetPlayerFacing()
		if not IsSecret(f) and type(f) == "number" then facing = f end
	end
	if facing == nil then facing = heading end

	local planShown = IM.plan ~= nil and IM.plan:IsShown() and mapData ~= nil and mapData.wx ~= nil and mapData.wy ~= nil and mapData.ps ~= nil and IM.baseW > 0
	if planShown then
		local px = (mapData.wy - wy) * mapData.ps
		local py = (mapData.wx - wx) * mapData.ps
		if px < -48 or px > mapData.w + 48 or py < -48 or py > mapData.h + 48 then
			HideArrow()
			return
		end
		local a = EnsureArrow(IM.plan, IM.plan.canvas:GetFrameLevel() + 20)
		local moved = IM.arrowMode ~= "plan" or IM.arrowPx == nil or math.abs(px - IM.arrowPx) > 0.05 or math.abs(py - IM.arrowPy) > 0.05
		IM.arrowMode = "plan"
		IM.arrowPx = px
		IM.arrowPy = py
		if facing ~= nil and (IM.arrowRot == nil or math.abs(facing - IM.arrowRot) > 0.005) then
			IM.arrowRot = facing
			a.tex:SetRotation(facing)
		end
		if moved then PlacePlanArrow(mapData) end
		if not a:IsShown() then a:Show() end
		return
	end

	if overlay.art ~= nil and artBounds ~= nil then
		local dx = artBounds[3] - artBounds[2]
		local dy = artBounds[5] - artBounds[4]
		local aw = overlay.art:GetWidth() or 0
		local ah = overlay.art:GetHeight() or 0
		if dx > 0 and dy > 0 and aw > 0 and ah > 0 then
			local u = (artBounds[5] - wy) / dy
			local v = (artBounds[3] - wx) / dx
			if u >= -0.06 and u <= 1.06 and v >= -0.06 and v <= 1.06 then
				local a = EnsureArrow(overlay, overlay:GetFrameLevel() + 700)
				local ax = u * aw
				local ay = -v * ah
				local moved = IM.arrowMode ~= "art" or IM.arrowArtX == nil or math.abs(ax - IM.arrowArtX) > 0.05 or math.abs(ay - IM.arrowArtY) > 0.05
				IM.arrowMode = "art"
				IM.arrowPx = nil
				IM.arrowPy = nil
				IM.arrowArtX = ax
				IM.arrowArtY = ay
				if facing ~= nil and (IM.arrowRot == nil or math.abs(facing - IM.arrowRot) > 0.005) then
					IM.arrowRot = facing
					a.tex:SetRotation(facing)
				end
				if moved then
					a:ClearAllPoints()
					a:SetPoint("CENTER", overlay.art, "TOPLEFT", ax, ay)
				end
				if not a:IsShown() then a:Show() end
				return
			end
		end
	end

	HideArrow()
end

Refresh = function()
	local overlay, artKey = FindRawOverlay()
	if overlay == nil then
		HideVisuals()
		return
	end
	local instID, floorIdx = MatchOverlayData(artKey)
	local mapData = GetMapData(instID)
	if mapData == nil then
		if IM.plan ~= nil then IM.plan:Hide() end
		if IM.btn ~= nil then IM.btn:Hide() end
		IM.activeInst = nil
		IM.activeFloor = nil
		IM.activeKey = artKey
		IM.drag = nil
		UpdatePlayerArrow(overlay, artKey, nil, nil)
		return
	end

	local floorChanged = IM.activeInst ~= instID or IM.activeFloor ~= floorIdx
	IM.activeInst = instID
	IM.activeFloor = floorIdx
	IM.activeKey = artKey
	if IM.btn == nil then
		local btn = CreateToggleButton(overlay)
		btn:SetScript("OnClick", function()
			SetMinimapViewOn(not IsMinimapViewOn())
			UpdateButtonText(btn)
			IM.activeFloor = nil
			Refresh()
		end)
		IM.btn = btn
		IM.btnOverlay = overlay
	elseif IM.btnOverlay ~= overlay then
		IM.btn:SetParent(overlay)
		IM.btnOverlay = overlay
	end
	local btnNeedsLayout = floorChanged or not IM.btn:IsShown() or IM.btnOn ~= IsMinimapViewOn()
	if btnNeedsLayout then
		IM.btnOn = IsMinimapViewOn()
		AnchorToggleButton(IM.btn, overlay)
		IM.btn:SetFrameLevel(overlay:GetFrameLevel() + 1100)
		UpdateButtonText(IM.btn)
		IM.btn:Show()
	end
	if IsMinimapViewOn() then
		local plan = EnsurePlan(overlay, instID, mapData)
		local wasHidden = not plan:IsShown()
		plan:Show()
		if floorChanged or wasHidden then
			ApplyFloorStyling(floorIdx)
		end
		LayoutPlan(overlay, mapData, floorIdx, floorChanged or wasHidden)
	elseif IM.plan ~= nil then
		IM.plan:Hide()
		IM.drag = nil
	end
	UpdatePlayerArrow(overlay, artKey, mapData, instID)
end

function MapUtils:RefreshInstancePosition()
	if MapUtils.IsInstancePositionEnabled == nil or not MapUtils:IsInstancePositionEnabled() then
		HideArrow()
		if MapUtils.StopInstancePosition ~= nil then MapUtils:StopInstancePosition() end
		return
	end
	Refresh()
end

local function InstallWatcher()
	if IM.watchFrame ~= nil or WorldMapFrame == nil then return end
	local f = CreateFrame("Frame", nil, WorldMapFrame)
	f.elapsed = 0
	f:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		if self.elapsed < WATCH_INTERVAL then return end
		self.elapsed = 0
		Refresh()
	end)
	f:SetScript("OnHide", HideVisuals)
	IM.watchFrame = f
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event)
	InstallWatcher()
	if event == "PLAYER_ENTERING_WORLD" and GetCurrentInstanceID() == nil and MapUtils.StopInstancePosition ~= nil then
		MapUtils:StopInstancePosition()
	end
	Refresh()
end)
