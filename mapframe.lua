local _, MapUtils = ...
local MIN_SCALE = 0.5
local MAX_SCALE = 2
local SCALE_EPSILON = 0.001
local GRIP_SIZE = 26
local frame = WorldMapFrame
local ready = false
local foreign = false
local foreignMove = false
local applying = false
local dragging = false
local wasClamped = false
local sizing = nil
local lastScale = 1
local blizzardPoint = nil
local grip = nil
local scrollBarsShifted = false
local fader = nil
local dragRegions = {"BorderFrame", "TitleCanvasSpacerFrame", "MiniBorderFrame"}
function MapUtils:GetCursorUi()
	local x, y = GetCursorPosition()
	local s = UIParent:GetEffectiveScale()

	return x / s, y / s
end
local function IsEnabled(key)
	return type(MAUTTAB) ~= "table" or MAUTTAB[key] ~= false
end

local function MoveEnabled()
	return not foreignMove and IsEnabled("WORLDMAPMOVE")
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
		foreignMove = true
	end

	if math.abs(frame:GetScale() - lastScale) > SCALE_EPSILON then
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

local function GetScrollBars()
	local bars = {}
	local frames = {QuestScrollFrame, QuestMapDetailsScrollFrame}
	if QuestMapFrame ~= nil and QuestMapFrame.MapLegend ~= nil then tinsert(frames, QuestMapFrame.MapLegend.ScrollFrame) end
	for _, scrollFrame in ipairs(frames) do
		if scrollFrame ~= nil and scrollFrame.ScrollBar ~= nil then tinsert(bars, scrollFrame.ScrollBar) end
	end

	return bars
end

local function ShiftScrollBars(shifted)
	if shifted == scrollBarsShifted then return end
	if IsLocked() then return end
	scrollBarsShifted = shifted
	local offset = shifted and GRIP_SIZE or -GRIP_SIZE
	for _, bar in ipairs(GetScrollBars()) do
		for i = 1, bar:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = bar:GetPoint(i)
			if point ~= nil and string.find(point, "BOTTOM", 1, true) then
				bar:SetPoint(point, relativeTo, relativePoint, x, y + offset)
			end
		end
	end
end

local function UpdateGrip()
	if grip == nil then return end
	if foreign or not ScaleEnabled() or IsMaximized() then
		grip:Hide()
		ShiftScrollBars(false)

		return
	end

	MapUtils:RaiseSizeGrip(grip, frame)
	grip:Show()
	ShiftScrollBars(true)
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
		local foreignLeft, foreignTop
		if foreignMove then foreignLeft, foreignTop = GetPos() end
		SetScale(scale)
		local pos = MAUTTAB["WORLDMAPPOS"]
		if foreignMove then
			if foreignLeft ~= nil then SetPos(foreignLeft, foreignTop) end
		elseif MoveEnabled() and type(pos) == "table" and pos.x ~= nil and pos.y ~= nil then
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
	if not ready or IsMaximized() or IsLocked() or CheckForeign() or not MoveEnabled() then return end
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
	return MapUtils:GetCursorUi()
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
	grip = MapUtils:CreateSizeGrip(frame, GRIP_SIZE)
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

function MapUtils:PrintFadeDebug()
	if fader ~= nil then fader:Debug("WorldMap") end
	if MapUtils.PrintBattlefieldFadeDebug ~= nil then MapUtils:PrintBattlefieldFadeDebug() end
end

function MapUtils:RefreshWorldMapFrame()
	Apply()
	if fader ~= nil then fader:Reset() end
end

if frame ~= nil then
	CreateGrip()
	hooksecurefunc(frame, "SetPoint", OnBlizzardPoint)
	if frame.SynchronizeDisplayState ~= nil then hooksecurefunc(frame, "SynchronizeDisplayState", Apply) end
	frame:HookScript("OnShow", Apply)
	fader = MapUtils:CreateMoveFader(
		frame,
		{
			["isEnabled"] = function() return type(MAUTTAB) == "table" and MAUTTAB["WORLDMAPFADE"] == true end,
			["getOpacity"] = function() return MAUTTAB["WORLDMAPFADEOPACITY"] end,
			["hookSetAlpha"] = true,
			["isBusy"] = function() return dragging or sizing ~= nil end
		}
	)
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

function MapUtils:QuestCategoriesSearching()
	return QuestScrollFrame and QuestScrollFrame.SearchBox and QuestScrollFrame.SearchBox:GetText() ~= ""
end

function MapUtils:SaveQuestCategories()
	if not self.questCategoriesReady or self.restoringQuestCategories or self:QuestCategoriesSearching() then return end
	if not self:GetConfig("REMEMBERQUESTCATEGORIES", true) then return end
	MAUTTABPC = MAUTTABPC or {}
	MAUTTABPC.QUESTCATEGORIES = MAUTTABPC.QUESTCATEGORIES or {}
	for index = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(index)
		if info and info.isHeader then
			MAUTTABPC.QUESTCATEGORIES[info.headerSortKey or info.title] = info.isCollapsed == true
		end
	end
end

function MapUtils:RestoreQuestCategories()
	if self.restoringQuestCategories or self:QuestCategoriesSearching() then return end
	if not self:GetConfig("REMEMBERQUESTCATEGORIES", true) then return end
	local states = MAUTTABPC and MAUTTABPC.QUESTCATEGORIES
	self.restoringQuestCategories = true
	if states then
		for index = C_QuestLog.GetNumQuestLogEntries(), 1, -1 do
			local info = C_QuestLog.GetInfo(index)
			if info and info.isHeader then
				local collapsed = states[info.headerSortKey or info.title]
				if collapsed == true and not info.isCollapsed then
					CollapseQuestHeader(index)
				elseif collapsed == false and info.isCollapsed then
					ExpandQuestHeader(index)
				end
			end
		end
	end
	self.restoringQuestCategories = nil
	self.questCategoriesReady = true
	self:SaveQuestCategories()
end

if MapUtils:IsForever() and C_QuestLog and CollapseQuestHeader and ExpandQuestHeader then
	hooksecurefunc("CollapseQuestHeader", function() MapUtils:SaveQuestCategories() end)
	hooksecurefunc("ExpandQuestHeader", function() MapUtils:SaveQuestCategories() end)
	WorldMapFrame:HookScript("OnShow", function() MapUtils:RestoreQuestCategories() end)
	MapUtils.questCategoriesLoader = CreateFrame("Frame")
	MapUtils.questCategoriesLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
	MapUtils.questCategoriesLoader:SetScript("OnEvent", function()
		MapUtils.questCategoriesReady = nil
		C_Timer.After(0, function() MapUtils:RestoreQuestCategories() end)
	end)
end
