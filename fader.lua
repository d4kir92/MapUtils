local _, MapUtils = ...
local FADE_DEFAULT = 50
local FADE_SPEED = 8
local FADE_SNAP = 0.01
local HOVER_MOVE = 2
local function IsMoving()
	if IsPlayerMoving ~= nil then return IsPlayerMoving() end

	return (GetUnitSpeed("player") or 0) > 0
end

local function IsMouseLook()
	return IsMouseLooking ~= nil and IsMouseLooking() == true
end

function MapUtils:CreateMoveFader(target, options)
	local fader = {}
	local fadeAlpha = 1
	local baseAlpha = 1
	local settingAlpha = false
	local hoverArmed = true
	local openX = nil
	local openY = nil
	local function Enabled()
		return type(MAUTTAB) == "table" and MAUTTAB[options.enabledKey] == true
	end

	local function IsBusy()
		return options.isBusy ~= nil and options.isBusy() == true
	end

	local function IsHovered()
		if IsMouseLook() then
			openX = nil

			return false
		end

		if not hoverArmed then
			local x, y = GetCursorPosition()
			if openX == nil then openX, openY = x, y end
			if math.abs(x - openX) + math.abs(y - openY) <= HOVER_MOVE then return false end
			hoverArmed = true
		end

		return target:IsMouseOver()
	end

	local function GetTarget()
		if not Enabled() or not IsMoving() or IsBusy() or IsHovered() then return 1 end
		local percent = tonumber(MAUTTAB[options.opacityKey]) or FADE_DEFAULT

		return max(0, min(percent, 100)) / 100
	end

	local function SetAlpha()
		settingAlpha = true
		target:SetAlpha(baseAlpha * fadeAlpha)
		settingAlpha = false
	end

	local function OnUpdate(_, elapsed)
		local wanted = GetTarget()
		if wanted ~= fadeAlpha then
			local alpha = fadeAlpha + (wanted - fadeAlpha) * min(1, elapsed * FADE_SPEED)
			if math.abs(wanted - alpha) < FADE_SNAP then alpha = wanted end
			fadeAlpha = alpha
			SetAlpha()
		elseif (Enabled() or fadeAlpha < 1) and math.abs(target:GetAlpha() - baseAlpha * fadeAlpha) > FADE_SNAP then
			SetAlpha()
		end
	end

	function fader:Reset()
		local faded = fadeAlpha < 1
		fadeAlpha = GetTarget()
		if Enabled() or faded then SetAlpha() end
	end

	function fader:OnShow()
		openX = nil
		hoverArmed = false
		self:Reset()
	end

	function fader:Debug(name)
		MapUtils:INFO(format("%s fade enabled=%s moving=%s mouseOver=%s mouseLook=%s armed=%s busy=%s", name, tostring(Enabled()), tostring(IsMoving()), tostring(target:IsMouseOver()), tostring(IsMouseLook()), tostring(hoverArmed), tostring(IsBusy())))
		MapUtils:INFO(format("%s fade target=%.2f fade=%.2f base=%.2f alpha=%.2f", name, GetTarget(), fadeAlpha, baseAlpha, target:GetAlpha()))
	end

	if options.hookSetAlpha then
		hooksecurefunc(
			target,
			"SetAlpha",
			function()
				if settingAlpha then return end
				if PlayerMovementFrameFader == nil then baseAlpha = target:GetAlpha() end
				if Enabled() or fadeAlpha < 1 then SetAlpha() end
			end
		)
	end

	target:HookScript("OnShow", function() fader:OnShow() end)
	local driver = CreateFrame("FRAME", nil, target)
	driver:SetScript("OnUpdate", OnUpdate)

	return fader
end
