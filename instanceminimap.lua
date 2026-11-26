local _, MapUtils = ...
local WATCH_INTERVAL = 0.05
local IM = {
	["plan"] = nil,
	["planOverlay"] = nil,
	["btn"] = nil,
	["btnOverlay"] = nil,
	["tiles"] = {},
	["builtKey"] = nil,
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
	if MAUTTAB ~= nil and MapUtils.SV ~= nil then
		MapUtils:SV(MAUTTAB, "INSTANCEPLANMINIMAP", enabled == true)
	elseif MapUtils.SetConfig ~= nil then
		MapUtils:SetConfig("INSTANCEPLANMINIMAP", enabled == true)
	end
end

local function MatchOverlayData(artTex)
	local store = MapUtils.INSTANCEMINIMAP
	if store == nil or artTex == nil then return nil, nil end
	local tex = artTex:GetTexture()
	if type(tex) == "string" then
		local lower = strlower(tex)
		for artKey, entry in pairs(store) do
			local key = strlower(artKey)
			if strfind(lower, "[\\/]" .. key .. "$") ~= nil or strfind(lower, "[\\/]" .. key .. "%.") ~= nil then
				return artKey, entry
			end
		end
		return nil, nil
	end
	local inInstance = IsInInstance()
	if inInstance then
		local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
		if not IsSecret(instanceMapID) and instanceMapID ~= nil then
			for artKey, entry in pairs(store) do
				if entry.instanceID == instanceMapID then
					return artKey, entry
				end
			end
		end
	end
	return nil, nil
end

local function FindActiveOverlay()
	if WorldMapFrame == nil or not WorldMapFrame:IsShown() then return nil, nil, nil end
	local container = WorldMapFrame.ScrollContainer
	if container == nil then return nil, nil, nil end
	local children = {container:GetChildren()}
	for i = 1, #children do
		local child = children[i]
		if child ~= nil and child:IsShown() and child.art ~= nil and child.bg ~= nil and child.credit ~= nil then
			local artKey, entry = MatchOverlayData(child.art)
			if entry ~= nil then return child, artKey, entry end
		end
	end
	return nil, nil, nil
end

local function GetCursorOffset()
	if IM.plan == nil then return nil end
	local scale = IM.plan:GetEffectiveScale()
	local cx, cy = IM.plan:GetCenter()
	if scale == nil or scale <= 0 or cx == nil then return nil end
	local mx, my = GetCursorPosition()
	return mx / scale - cx, my / scale - cy
end

local function ApplyView(entry)
	local plan = IM.plan
	if plan == nil or entry == nil or IM.baseW <= 0 or IM.baseH <= 0 then return end
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
	local tileScale = cw / entry.w
	for i = 1, #IM.tiles do
		local t = IM.tiles[i]
		local tex = plan.textures[i]
		if tex ~= nil then
			tex:SetSize(t[5] * tileScale, t[4] * tileScale)
			tex:ClearAllPoints()
			tex:SetPoint("TOPLEFT", plan.canvas, "TOPLEFT", t[2] * tileScale, -t[3] * tileScale)
		end
	end
end

local function LayoutPlan(overlay, entry)
	if IM.plan == nil or entry == nil then return end
	local ow = overlay:GetWidth() or 0
	local oh = overlay:GetHeight() or 0
	if ow <= 0 or oh <= 0 then return end
	if ow == IM.lastW and oh == IM.lastH and IM.baseW > 0 then return end
	IM.lastW = ow
	IM.lastH = oh
	local ratio = entry.h / entry.w
	local bw = ow
	local bh = ow * ratio
	if bh > oh then
		bh = oh
		bw = oh / ratio
	end
	IM.baseW = bw
	IM.baseH = bh
	ApplyView(entry)
end

local function BuildTiles(plan, artKey, entry)
	wipe(IM.tiles)
	local idx = 0
	for item in string.gmatch(entry.tiles, "[^,]+") do
		local fid, col, row, tw, th = strsplit(":", item)
		fid = tonumber(fid)
		col = tonumber(col)
		row = tonumber(row)
		tw = tonumber(tw)
		th = tonumber(th)
		if fid ~= nil and col ~= nil and row ~= nil and tw ~= nil and th ~= nil then
			idx = idx + 1
			IM.tiles[idx] = {fid, col, row, tw, th}
			local tex = plan.textures[idx]
			if tex == nil then
				tex = plan.canvas:CreateTexture(nil, "ARTWORK")
				plan.textures[idx] = tex
			end
			tex:SetTexture(fid)
			tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
			tex:Show()
		end
	end
	for i = idx + 1, #plan.textures do
		plan.textures[i]:Hide()
	end
	IM.builtKey = artKey
	IM.zoom = 1
	IM.panX = 0
	IM.panY = 0
	IM.drag = nil
	IM.lastW = 0
	IM.lastH = 0
end

local function EnsurePlan(overlay, artKey, entry)
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
			local cur = IM.activeKey and MapUtils.INSTANCEMINIMAP and MapUtils.INSTANCEMINIMAP[IM.activeKey] or nil
			if cur == nil then return end
			local z = math.min(4, math.max(1, IM.zoom * (1.25 ^ delta)))
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
			local cur = IM.activeKey and MapUtils.INSTANCEMINIMAP and MapUtils.INSTANCEMINIMAP[IM.activeKey] or nil
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
	if IM.builtKey ~= artKey then
		BuildTiles(IM.plan, artKey, entry)
	end
	return IM.plan
end

local function UpdateButtonText(btn)
	local on = IsMinimapViewOn()
	local key = on and "LID_MAPVIEW" or "LID_MINIMAPVIEW"
	local fallback = on and "Map view" or "Minimap view"
	local label = MapUtils.Trans ~= nil and MapUtils:Trans(key) or fallback
	btn:SetText(label)
	local tw = btn.GetTextWidth ~= nil and btn:GetTextWidth() or 90
	btn:SetWidth(math.max(96, tw + 24))
end

local function HideVisuals()
	if IM.plan ~= nil then IM.plan:Hide() end
	if IM.btn ~= nil then IM.btn:Hide() end
	IM.activeKey = nil
	IM.drag = nil
end

local function Refresh()
	local overlay, artKey, entry = FindActiveOverlay()
	if overlay == nil or entry == nil then
		HideVisuals()
		return
	end
	IM.activeKey = artKey
	if IM.btn == nil then
		local btn = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
		btn:SetHeight(22)
		btn:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -10)
		btn:SetScript("OnClick", function()
			SetMinimapViewOn(not IsMinimapViewOn())
			UpdateButtonText(btn)
			Refresh()
		end)
		IM.btn = btn
		IM.btnOverlay = overlay
	elseif IM.btnOverlay ~= overlay then
		IM.btn:SetParent(overlay)
		IM.btn:ClearAllPoints()
		IM.btn:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -10)
		IM.btnOverlay = overlay
	end
	IM.btn:SetFrameLevel(overlay:GetFrameLevel() + 1000)
	UpdateButtonText(IM.btn)
	IM.btn:Show()
	if IsMinimapViewOn() then
		local plan = EnsurePlan(overlay, artKey, entry)
		plan:Show()
		LayoutPlan(overlay, entry)
	elseif IM.plan ~= nil then
		IM.plan:Hide()
		IM.drag = nil
	end
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
ev:SetScript("OnEvent", function()
	InstallWatcher()
	Refresh()
end)
