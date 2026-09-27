local _, MapUtils = ...
local MIN_SCALE = 0.5
local MAX_SCALE = 2
local SCALE_EPSILON = 0.001
local GRIP_SIZE = 16
local GRIP_LEVEL = 4000
local MAX_FRAME_LEVEL = 9000
local frame = WorldMapFrame
local ready = false
local foreign = false
local applying = false
local dragging = false
local wasClamped = false
local sizing = nil
local lastScale = 1
local blizzardPoint = nil
local grip = nil
local dragRegions = {"BorderFrame", "TitleCanvasSpacerFrame", "MiniBorderFrame"}
local function IsEnabled(key)
	return type(MAUTTAB) ~= "table" or MAUTTAB[key] ~= false
end

local function MoveEnabled()
	return IsEnabled("WORLDMAPMOVE")
end

local function ScaleEnabled()
	return IsEnabled("WORLDMAPSCALE")
end

local function IsMaximized()
	return frame.IsMaximized ~= nil and frame:IsMaximized() == true
end

local function IsLocked()
	return InCombatLockdown() and frame:IsProtected()
end

local function CheckForeign()
	if foreign then return true end
	if not dragging and frame:IsMovable() then
		foreign = true
	elseif math.abs(frame:GetScale() - lastScale) > SCALE_EPSILON then
		foreign = true
	end

	if foreign and grip ~= nil then grip:Hide() end

	return foreign
end

local function ToUi()
	return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

local function GetPos()
	local left = frame:GetLeft()
	local top = frame:GetTop()
	if left == nil or top == nil then return nil end
	local k = ToUi()

	return left * k, top * k
end

local function SetPos(left, top)
	local k = ToUi()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / k, top / k)
end

local function GetUnitSize()
	local k = ToUi() / frame:GetScale()

	return frame:GetWidth() * k, frame:GetHeight() * k
end

local function GetMaxScale()
	local w, h = GetUnitSize()
	if w <= 0 or h <= 0 then return MAX_SCALE end

	return min(MAX_SCALE, UIParent:GetWidth() / w, UIParent:GetHeight() / h)
end

local function ClampScale(value, maxScale)
	maxScale = maxScale or GetMaxScale()

	return max(min(MIN_SCALE, maxScale), min(value or 1, maxScale))
end

local function ClampPos(left, top)
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	w = w * s
	h = h * s
	left = max(0, min(left, UIParent:GetWidth() - w))
	top = min(UIParent:GetHeight(), max(top, h))

	return left, top
end

local function SetScale(value)
	lastScale = value
	if math.abs(frame:GetScale() - value) > SCALE_EPSILON then frame:SetScale(value) end
end

local function NormalizePoint(point, relativeTo, relativePoint, x, y)
	if type(relativeTo) == "number" then return point, frame:GetParent(), point, relativeTo, relativePoint or 0 end

	return point, relativeTo or frame:GetParent(), relativePoint or point, x or 0, y or 0
end

local function UpdateGrip()
	if grip == nil then return end
	if foreign or not ScaleEnabled() or IsMaximized() then
		grip:Hide()

		return
	end

	grip:SetFrameLevel(min(frame:GetFrameLevel() + GRIP_LEVEL, MAX_FRAME_LEVEL))
	grip:Show()
end

local function Apply()
	if not ready or applying or sizing ~= nil or dragging then return end
	if IsLocked() or CheckForeign() then return end
	applying = true
	if IsMaximized() then
		SetScale(1)
	else
		local scale = 1
		if ScaleEnabled() then scale = ClampScale(MAUTTAB["WORLDMAPSCALEVALUE"]) end
		SetScale(scale)
		local pos = MAUTTAB["WORLDMAPPOS"]
		if MoveEnabled() and type(pos) == "table" and pos.x ~= nil and pos.y ~= nil then
			SetPos(ClampPos(pos.x, pos.y))
		elseif blizzardPoint ~= nil then
			local point, relativeTo, relativePoint, x, y = unpack(blizzardPoint)
			frame:ClearAllPoints()
			frame:SetPoint(point, relativeTo, relativePoint, x / scale, y / scale)
			local left, top = GetPos()
			if left ~= nil then
				local cl, ct = ClampPos(left, top)
				if cl ~= left or ct ~= top then SetPos(cl, ct) end
			end
		end
	end

	applying = false
	UpdateGrip()
end

local function OnBlizzardPoint(_, ...)
	if applying or sizing ~= nil or dragging then return end
	blizzardPoint = {NormalizePoint(...)}
	Apply()
end

local function OnDragStart()
	if not ready or not MoveEnabled() or IsMaximized() or IsLocked() or CheckForeign() then return end
	dragging = true
	wasClamped = frame:IsClampedToScreen()
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:StartMoving()
end

local function OnDragStop()
	if not dragging then return end
	frame:StopMovingOrSizing()
	frame:SetUserPlaced(false)
	frame:SetClampedToScreen(wasClamped == true)
	frame:SetMovable(false)
	dragging = false
	local left, top = GetPos()
	if left ~= nil then MapUtils:SV(MAUTTAB, "WORLDMAPPOS", {["x"] = left, ["y"] = top}) end
	Apply()
end

local function GetCursorUi()
	local x, y = GetCursorPosition()
	local s = UIParent:GetEffectiveScale()

	return x / s, y / s
end

local function OnSizing()
	if sizing == nil then return end
	local x, y = GetCursorUi()
	local w = sizing.width + x - sizing.x
	local h = sizing.height + sizing.y - y
	local scale = sizing.scale * max(w / sizing.width, h / sizing.height)
	local unitW, unitH = GetUnitSize()
	local maxScale = min(GetMaxScale(), (UIParent:GetWidth() - sizing.left) / unitW, sizing.top / unitH)
	applying = true
	SetScale(ClampScale(scale, maxScale))
	SetPos(sizing.left, sizing.top)
	applying = false
end

local function StopSizing()
	if sizing == nil then return end
	sizing = nil
	grip:SetScript("OnUpdate", nil)
	grip:SetButtonState("NORMAL")
	MapUtils:SV(MAUTTAB, "WORLDMAPSCALEVALUE", lastScale)
	if MoveEnabled() then
		local left, top = GetPos()
		if left ~= nil then MapUtils:SV(MAUTTAB, "WORLDMAPPOS", {["x"] = left, ["y"] = top}) end
	end

	Apply()
end

local function StartSizing(_, button)
	if button ~= "LeftButton" or IsLocked() or CheckForeign() then return end
	local left, top = GetPos()
	if left == nil then return end
	local x, y = GetCursorUi()
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	sizing = {
		["x"] = x,
		["y"] = y,
		["left"] = left,
		["top"] = top,
		["width"] = w * s,
		["height"] = h * s,
		["scale"] = s
	}

	grip:SetButtonState("PUSHED", true)
	grip:SetScript("OnUpdate", OnSizing)
end

local function CreateGrip()
	grip = CreateFrame("Button", nil, frame)
	grip:SetSize(GRIP_SIZE, GRIP_SIZE)
	grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetScript("OnMouseDown", StartSizing)
	grip:SetScript("OnMouseUp", StopSizing)
	grip:SetScript("OnHide", StopSizing)
	grip:Hide()
end

local function HookDrag(region)
	if region == nil or region.RegisterForDrag == nil or not region:IsMouseEnabled() then return end
	region:RegisterForDrag("LeftButton")
	region:HookScript("OnDragStart", OnDragStart)
	region:HookScript("OnDragStop", OnDragStop)
end

function MapUtils:RefreshWorldMapFrame()
	Apply()
end

if frame ~= nil then
	CreateGrip()
	hooksecurefunc(frame, "SetPoint", OnBlizzardPoint)
	if frame.SynchronizeDisplayState ~= nil then hooksecurefunc(frame, "SynchronizeDisplayState", Apply) end
	frame:HookScript("OnShow", Apply)
	frame:HookScript("OnHide", OnDragStop)
	local loader = CreateFrame("FRAME")
	MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
	loader:SetScript(
		"OnEvent",
		function()
			HookDrag(frame)
			for _, key in ipairs(dragRegions) do
				HookDrag(frame[key])
			end

			if frame.BorderFrame ~= nil then HookDrag(frame.BorderFrame.TitleContainer) end
			HookDrag(WorldMapTitleButton)
			MAUTTAB = MAUTTAB or {}
			ready = true
			if frame:IsShown() then Apply() end
		end
	)
end
