local _, MapUtils = ...
local MIN_SCALE = 0.5
local MAX_SCALE = 3
local SCALE_EPSILON = 0.001
local GRIP_SIZE = 20
local CHECK_INTERVAL = 0.25
local frame = nil
local grip = nil
local fader = nil
local foreign = false
local lastScale = 1
local sizing = nil
local function Enabled()
	return type(MAUTTAB) ~= "table" or MAUTTAB["BATTLEFIELDMAPSCALE"] ~= false
end

local function IsLocked()
	return type(BattlefieldMapOptions) == "table" and BattlefieldMapOptions.locked == true
end

local function CheckForeign()
	if not foreign and math.abs(frame:GetScale() - lastScale) > SCALE_EPSILON then foreign = true end
	if foreign then grip:Hide() end

	return foreign
end

local function ToUi()
	return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

local function GetUnitSize()
	local k = ToUi() / frame:GetScale()

	return frame:GetWidth() * k, frame:GetHeight() * k
end

local function GetMaxScale()
	local left = frame:GetLeft()
	local top = frame:GetTop()
	local w, h = GetUnitSize()
	if left == nil or top == nil or w <= 0 or h <= 0 then return MAX_SCALE end
	local k = ToUi()

	return min(MAX_SCALE, (UIParent:GetWidth() - left * k) / w, top * k / h)
end

local function ClampScale(value)
	local maxScale = GetMaxScale()

	return max(min(MIN_SCALE, maxScale), min(value or 1, maxScale))
end

local function SetScale(value)
	lastScale = value
	if math.abs(frame:GetScale() - value) > SCALE_EPSILON then frame:SetScale(value) end
end

local function UpdateGrip()
	if foreign or not Enabled() or IsLocked() then
		grip:Hide()

		return
	end

	if not grip:IsShown() then
		MapUtils:RaiseSizeGrip(grip, frame)
		grip:Show()
	end
end

local function Apply()
	if frame == nil or sizing ~= nil or CheckForeign() then return end
	local scale = 1
	if Enabled() then scale = ClampScale(type(MAUTTAB) == "table" and MAUTTAB["BATTLEFIELDMAPSCALEVALUE"] or 1) end
	SetScale(scale)
	UpdateGrip()
end

local function OnSizing()
	if sizing == nil then return end
	local x, y = MapUtils:GetCursorUi()
	local w = sizing.width + x - sizing.x
	local h = sizing.height + sizing.y - y
	SetScale(ClampScale(sizing.scale * max(w / sizing.width, h / sizing.height)))
end

local function StopSizing()
	if sizing == nil then return end
	sizing = nil
	grip:SetScript("OnUpdate", nil)
	grip:SetButtonState("NORMAL")
	MAUTTAB = MAUTTAB or {}
	MapUtils:SV(MAUTTAB, "BATTLEFIELDMAPSCALEVALUE", lastScale)
	Apply()
end

local function StartSizing(_, button)
	if button ~= "LeftButton" or CheckForeign() then return end
	local x, y = MapUtils:GetCursorUi()
	local w, h = GetUnitSize()
	local s = frame:GetScale()
	sizing = {
		["x"] = x,
		["y"] = y,
		["width"] = w * s,
		["height"] = h * s,
		["scale"] = s
	}

	grip:SetButtonState("PUSHED", true)
	grip:SetScript("OnUpdate", OnSizing)
end

local function Init()
	if frame ~= nil then return true end
	if BattlefieldMapFrame == nil then return false end
	frame = BattlefieldMapFrame
	grip = MapUtils:CreateSizeGrip(frame, GRIP_SIZE)
	grip:SetScript("OnMouseDown", StartSizing)
	grip:SetScript("OnMouseUp", StopSizing)
	grip:SetScript("OnHide", StopSizing)
	frame:HookScript("OnShow", Apply)
	fader = MapUtils:CreateMoveFader(
		frame,
		{
			["enabledKey"] = "BATTLEFIELDMAPFADE",
			["opacityKey"] = "BATTLEFIELDMAPFADEOPACITY",
			["isBusy"] = function() return sizing ~= nil end
		}
	)

	local watcher = CreateFrame("FRAME", nil, frame)
	watcher.elapsed = 0
	watcher:SetScript(
		"OnUpdate",
		function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < CHECK_INTERVAL then return end
			self.elapsed = 0
			if not foreign and sizing == nil then UpdateGrip() end
		end
	)

	if frame:IsShown() then Apply() end

	return true
end

function MapUtils:RefreshBattlefieldMap()
	if frame == nil then return end
	Apply()
	fader:Reset()
end

function MapUtils:PrintBattlefieldFadeDebug()
	if fader ~= nil then fader:Debug("BattlefieldMap") end
end

local loader = CreateFrame("FRAME")
MapUtils:RegisterEvent(loader, "PLAYER_LOGIN")
MapUtils:RegisterEvent(loader, "ADDON_LOADED")
loader:SetScript(
	"OnEvent",
	function(self)
		if Init() then self:UnregisterAllEvents() end
	end
)
