local _, MapUtils = ...
local DEFAULT_ART_WIDTH = 1024
local DEFAULT_ART_HEIGHT = 1024
local UPDATE_INTERVAL = 0.05
local OVERLAY_LEVEL = 3000
local art = {}
art[2999] = {
	["file"] = "Interface\\AddOns\\MapUtils\\media\\2999",
	["width"] = 1024,
	["height"] = 1024,
	["zoom"] = 1,
}

local overlay = nil
local hiddenFor = nil
local forced = nil
local forcedMapID = nil
local lastKey = nil
local Refresh = nil
local function GetChild()
	if WorldMapFrame == nil then return nil end
	if WorldMapFrame.ScrollContainer == nil then return nil end

	return WorldMapFrame.ScrollContainer.Child
end

local function GetInstanceArt()
	local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	if instanceMapID == nil then return nil end

	return art[instanceMapID], instanceMapID
end

local function GetPlayerMapID()
	if MapUtil ~= nil and MapUtil.GetDisplayableMapForPlayer ~= nil then return MapUtil.GetDisplayableMapForPlayer() end
	if C_Map ~= nil and C_Map.GetBestMapForUnit ~= nil then return C_Map.GetBestMapForUnit("player") end

	return nil
end

local function ClearForced()
	forced = nil
	forcedMapID = nil
end

local function ToggleOverlay()
	if forced ~= nil then
		ClearForced()
		Refresh()

		return
	end

	local info, instanceMapID = GetInstanceArt()
	if info == nil then return end
	if hiddenFor == instanceMapID then
		hiddenFor = nil
	else
		hiddenFor = instanceMapID
	end

	Refresh()
end

local function OnCanvasMouseUp(_, button)
	if button ~= "RightButton" then return end
	ToggleOverlay()
end

local function CreateOverlay()
	if overlay ~= nil then return overlay end
	local child = GetChild()
	if child == nil then return nil end
	overlay = CreateFrame("FRAME", nil, child)
	overlay:SetFrameLevel(child:GetFrameLevel() + OVERLAY_LEVEL)
	overlay:EnableMouse(false)
	overlay:SetAllPoints(child)
	overlay.bg = overlay:CreateTexture(nil, "BACKGROUND")
	overlay.bg:SetAllPoints(overlay)
	overlay.bg:SetColorTexture(0, 0, 0, 1)
	overlay.art = overlay:CreateTexture(nil, "ARTWORK")
	overlay.art:SetPoint("CENTER", overlay, "CENTER", 0, 0)
	overlay:Hide()
	WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", OnCanvasMouseUp)
	WorldMapFrame:HookScript(
		"OnShow",
		function()
			hiddenFor = nil
			ClearForced()
		end
	)

	return overlay
end

local function Layout(info)
	local child = GetChild()
	if child == nil then return end
	local w = child:GetWidth()
	local h = child:GetHeight()
	if w == nil or h == nil or w <= 0 or h <= 0 then return end
	local ratio = (info.height or DEFAULT_ART_HEIGHT) / (info.width or DEFAULT_ART_WIDTH)
	local width = w
	local height = w * ratio
	if height > h then
		height = h
		width = h / ratio
	end

	local zoom = info.zoom or 1
	overlay.art:SetSize(width * zoom, height * zoom)
end

local function GetVisibleArt()
	if MapUtils:GetConfig("INSTANCEMAP", true) ~= true then return nil end
	if WorldMapFrame == nil or WorldMapFrame.GetMapID == nil then return nil end
	if forced ~= nil then
		if WorldMapFrame:GetMapID() == forcedMapID then return forced end
		ClearForced()
	end

	local info, instanceMapID = GetInstanceArt()
	if info == nil then return nil end
	if hiddenFor == instanceMapID then return nil end
	local playerMapID = GetPlayerMapID()
	if playerMapID ~= nil and WorldMapFrame:GetMapID() ~= playerMapID then return nil end

	return info
end

Refresh = function()
	local info = GetVisibleArt()
	if info == nil then
		lastKey = nil
		if overlay ~= nil then overlay:Hide() end

		return
	end

	if CreateOverlay() == nil then return end
	local child = GetChild()
	local key = format("%s|%.1f|%.1f", info.file, child:GetWidth() or 0, child:GetHeight() or 0)
	if key ~= lastKey then
		lastKey = key
		overlay.art:SetTexture(info.file)
		Layout(info)
	end

	if not overlay:IsShown() then overlay:Show() end
end

function MapUtils:ShowInstanceMap(instanceMapID)
	if instanceMapID == nil then return false end
	local info = art[instanceMapID]
	if info == nil then return false end
	if WorldMapFrame == nil or WorldMapFrame.GetMapID == nil then return false end
	if WorldMapFrame:IsShown() ~= true then return false end
	forced = info
	forcedMapID = WorldMapFrame:GetMapID()
	hiddenFor = nil
	Refresh()

	return true
end

function MapUtils:ToggleInstanceMap()
	if forced == nil and GetInstanceArt() == nil then
		MapUtils:INFO("No own map for this instance")

		return
	end

	ToggleOverlay()
end

if WorldMapFrame ~= nil then
	local updater = CreateFrame("FRAME", nil, WorldMapFrame)
	updater.elapsed = 0
	updater:SetScript(
		"OnUpdate",
		function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < UPDATE_INTERVAL then return end
			self.elapsed = 0
			Refresh()
		end
	)
end
