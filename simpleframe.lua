local _, MapUtils = ...
local BAR_HEIGHT = 25
local NAV_HEIGHT = 15
local BUTTON_SIZE = 18
local SEARCH_HEIGHT = 16
local BACKGROUND = "Interface\\FrameGeneral\\UI-Background-Rock"
local BORDER_LAYOUT = "ButtonFrameTemplateNoPortrait"
local BORDER_OUTSET = 5
local GAP = {
	["left"] = 5,
	["right"] = 3,
	["bottom"] = 1,
	["questTop"] = 2
}

local NAV_RAISE = 1.5
local CONTENT_RAISE = 1.5
local map = WorldMapFrame
local saved = {}
local hidden = {}
local sizes = {}
local hitInsets = {}
local active = false
local bar, back, questCount
local originalScrollTop
local function CanChange(frame)
	return frame ~= nil and (not InCombatLockdown() or not frame:IsProtected())
end

function MapUtils:IsSimpleMapFrameAvailable()
	return map ~= nil and map.NavBar ~= nil and map.BorderFrame ~= nil and map.ScrollContainer ~= nil and QuestMapFrame ~= nil
end

function MapUtils:IsSimpleMapFrameByLeatrix()
	return MapUtils:IsAddOnActive("Leatrix_Maps") and type(LeaMapsDB) == "table" and LeaMapsDB["SimpleMapFrame"] == "On"
end

local function IsWanted()
	return MapUtils:IsSimpleMapFrameAvailable() and not MapUtils:IsSimpleMapFrameByLeatrix() and type(MAUTTAB) == "table" and MAUTTAB["WORLDMAPSIMPLE"] == true
end

local function Save(frame)
	if frame == nil or saved[frame] ~= nil then return end
	local entry = {
		["points"] = {},
		["width"] = frame:GetWidth(),
		["height"] = frame:GetHeight(),
		["scale"] = frame.GetScale and frame:GetScale() or nil,
		["level"] = frame.GetFrameLevel and frame:GetFrameLevel() or nil
	}

	for i = 1, frame:GetNumPoints() do
		tinsert(entry["points"], {frame:GetPoint(i)})
	end

	saved[frame] = entry
end

local function Restore(frame, entry)
	if not CanChange(frame) then return false end
	frame:ClearAllPoints()
	for _, point in ipairs(entry["points"]) do
		frame:SetPoint(unpack(point))
	end

	frame:SetSize(entry["width"], entry["height"])
	if entry["scale"] ~= nil then frame:SetScale(entry["scale"]) end
	if entry["level"] ~= nil then frame:SetFrameLevel(entry["level"]) end

	return true
end

local function Place(frame, level, ...)
	if not CanChange(frame) then return false end
	Save(frame)
	frame:ClearAllPoints()
	local anchors = {...}
	for _, anchor in ipairs(anchors) do
		frame:SetPoint(unpack(anchor))
	end

	if level ~= nil then frame:SetFrameLevel(level) end

	return true
end

local function HideObject(object)
	if object == nil or hidden[object] ~= nil then return end
	local isFrame = object:IsObjectType("Frame")
	hidden[object] = {
		["alpha"] = object:GetAlpha(),
		["shown"] = object:IsShown(),
		["mouse"] = isFrame and object:IsMouseEnabled() or nil
	}

	object:SetAlpha(0)
	if isFrame then
		if CanChange(object) then
			object:Hide()
			object:EnableMouse(false)
		end

		if not hidden[object]["hooked"] then
			hidden[object]["hooked"] = true
			object:HookScript(
				"OnShow",
				function(sel)
					if not active or hidden[sel] == nil then return end
					sel:SetAlpha(0)
					if CanChange(sel) then sel:Hide() end
				end
			)
		end
	end
end

local function ShowObjects()
	for object, entry in pairs(hidden) do
		object:SetAlpha(entry["alpha"])
		if object:IsObjectType("Frame") and CanChange(object) then
			if entry["mouse"] ~= nil then object:EnableMouse(entry["mouse"]) end
			if entry["shown"] then object:Show() end
		end

		hidden[object] = nil
	end
end

local function Shrink(object, factor, keepWidth)
	if object == nil or sizes[object] ~= nil then return end
	if object:GetNumPoints() >= 2 then return end
	local width, height = object:GetWidth(), object:GetHeight()
	if height == nil or height <= NAV_HEIGHT then return end
	sizes[object] = {width, height}
	object:SetHeight(height * factor)
	if not keepWidth then object:SetWidth(width * factor) end
end

local function ShrinkChildren(frame, factor, keepWidth, depth)
	for _, region in ipairs({frame:GetRegions()}) do
		if region:IsObjectType("Texture") then Shrink(region, factor, false) end
	end

	if depth <= 0 then return end
	for _, child in ipairs({frame:GetChildren()}) do
		Shrink(child, factor, keepWidth)
		ShrinkChildren(child, factor, false, depth - 1)
	end
end

local function HorizontalPart(point)
	if point:find("LEFT", 1, true) then return "LEFT" end
	if point:find("RIGHT", 1, true) then return "RIGHT" end

	return "CENTER"
end

local function CenterVertically(frame, parent)
	if frame:GetNumPoints() ~= 1 or not CanChange(frame) then return end
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	if point == nil then return end
	relativeTo = relativeTo or parent
	local h, rh = HorizontalPart(point), HorizontalPart(relativePoint or point)
	if point == h and relativePoint == rh and y == 0 then return end
	Save(frame)
	frame:ClearAllPoints()
	frame:SetPoint(h, relativeTo, rh, x or 0, 0)
end

local function ShrinkNavBar()
	if not active then return end
	local nav = map.NavBar
	if not CanChange(nav) then return end
	local entry = saved[nav]
	local height = entry and entry["height"] or nav:GetHeight()
	if height == nil or height <= 0 then return end
	local factor = NAV_HEIGHT / height
	for _, region in ipairs({nav:GetRegions()}) do
		if region:IsObjectType("Texture") then Shrink(region, factor, true) end
	end

	for _, child in ipairs({nav:GetChildren()}) do
		for _, inner in ipairs({child:GetChildren()}) do
			CenterVertically(inner, child)
		end

		Shrink(child, factor, true)
		ShrinkChildren(child, factor, false, 1)
	end

	local function HideTextures(frame)
		for _, region in ipairs({frame:GetRegions()}) do
			if region:IsObjectType("Texture") then HideObject(region) end
		end

		for _, child in ipairs({frame:GetChildren()}) do
			if frame.MenuArrowButton ~= child then HideTextures(child) end
		end
	end

	HideTextures(nav)
end

local function RestoreSizes()
	for object, size in pairs(sizes) do
		if not object:IsObjectType("Frame") or CanChange(object) then
			object:SetSize(size[1], size[2])
			sizes[object] = nil
		end
	end
end

local function GetQuestCounts()
	local numQuests
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		numQuests = select(2, C_QuestLog.GetNumQuestLogEntries())
	elseif GetNumQuestLogEntries then
		numQuests = select(2, GetNumQuestLogEntries())
	end

	local maxQuests
	if Constants and Constants.QuestLogConsts then maxQuests = Constants.QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT end
	if maxQuests == nil and C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept() end
	if maxQuests == nil then maxQuests = MAX_QUESTS end

	return numQuests, maxQuests
end

local function UpdateQuestCount()
	if questCount == nil then return end
	local numQuests, maxQuests = GetQuestCounts()
	if numQuests == nil or maxQuests == nil then
		questCount:SetText("")

		return
	end

	local color = numQuests > maxQuests and RED_FONT_COLOR_CODE or "|cffffffff"
	questCount:SetFormattedText("%s%d|r/%d", color, numQuests, maxQuests)
end

local function SetBackground(texture)
	texture:SetAllPoints()
	texture:SetTexture(BACKGROUND, "REPEAT", "REPEAT")
	texture:SetHorizTile(true)
	texture:SetVertTile(true)
end

local function CreateBorder()
	if NineSliceUtil == nil or NineSliceUtil.ApplyLayoutByName == nil then return end
	if NineSliceUtil.GetLayout ~= nil and NineSliceUtil.GetLayout(BORDER_LAYOUT) == nil then return end
	local pieces = {}
	local border = CreateFrame("Frame", "MapUtilsSimpleMapFrameBorder", back)
	border:SetPoint("TOPLEFT", back, "TOPLEFT", -BORDER_OUTSET - GAP["left"], 0)
	border:SetPoint("BOTTOMRIGHT", back, "BOTTOMRIGHT", BORDER_OUTSET + GAP["right"], -BORDER_OUTSET - GAP["bottom"])
	border:EnableMouse(false)
	border.GetNineSlicePiece = function(_, name)
		if pieces[name] == nil then pieces[name] = back:CreateTexture(nil, "BORDER") end

		return pieces[name]
	end

	if not pcall(NineSliceUtil.ApplyLayoutByName, border, BORDER_LAYOUT) then
		for _, piece in pairs(pieces) do
			piece:Hide()
		end

		return
	end

	if pieces.Center ~= nil then pieces.Center:Hide() end
	back.border = border
end

local function CreateBar()
	if bar ~= nil then return end
	back = CreateFrame("Frame", "MapUtilsSimpleMapFrame", map)
	back:SetFrameLevel(map:GetFrameLevel())
	back:EnableMouse(false)
	back.bg = back:CreateTexture(nil, "BACKGROUND", nil, -7)
	SetBackground(back.bg)
	back.bg:ClearAllPoints()
	back.bg:SetPoint("TOPLEFT", back, "TOPLEFT", -GAP["left"] - 2, 0)
	back.bg:SetPoint("BOTTOMRIGHT", back, "BOTTOMRIGHT", GAP["right"] + 2, -GAP["bottom"] - 2)
	CreateBorder()
	bar = CreateFrame("Frame", nil, map)
	bar:SetHeight(BAR_HEIGHT)
	bar:SetFrameLevel(map:GetFrameLevel() + 1)
	bar:EnableMouse(false)
	bar.text = CreateFrame("Frame", nil, bar)
	bar.text:SetAllPoints()
	bar.text:EnableMouse(false)
	questCount = bar.text:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
end

local function GetQuestWidth()
	if not QuestMapFrame:IsShown() then return 0 end

	return map.questLogWidth or QuestMapFrame:GetWidth() or 0
end

function MapUtils:GetSimpleMapTopGap()
	if not active or bar == nil then return 0 end
	local mapTop, barTop = map:GetTop(), bar:GetTop()
	if mapTop == nil or barTop == nil then return 0 end

	return max(0, mapTop - barTop * bar:GetEffectiveScale() / map:GetEffectiveScale())
end

local function LayoutFullscreenScroll(scroll, fullscreen)
	if not CanChange(scroll) then return end
	if fullscreen then
		if originalScrollTop ~= nil then return end
		for i = 1, scroll:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = scroll:GetPoint(i)
			if point == "TOPLEFT" and relativeTo == map.TitleCanvasSpacerFrame then
				originalScrollTop = {point, relativeTo, relativePoint, x, y}
				scroll:SetPoint(point, relativeTo, "TOPLEFT", x, -BAR_HEIGHT)
				return
			end
		end
	elseif originalScrollTop ~= nil then
		scroll:SetPoint(unpack(originalScrollTop))
		originalScrollTop = nil
	end
end

local function Layout()
	if not active or bar == nil then return end
	if InCombatLockdown() and map:IsProtected() then return end
	local scroll = map.ScrollContainer
	LayoutFullscreenScroll(scroll, MapUtils:IsWorldMapFullscreen())
	local questWidth = GetQuestWidth()
	local level = bar:GetFrameLevel() + 5
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", scroll, "TOPRIGHT", questWidth, 0)
	back:ClearAllPoints()
	back:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	back:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", questWidth, 0)
	bar.text:SetFrameLevel(level)
	local closeButton = map.BorderFrame.CloseButton
	local maxButton = map.BorderFrame.MaximizeMinimizeFrame
	local rightMost = bar
	local rightPoint = "RIGHT"
	local rightOffset = -2
	if Place(closeButton, level, {"RIGHT", bar, "RIGHT", GAP["right"] - 2, CONTENT_RAISE}) then
		closeButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
		rightMost, rightPoint, rightOffset = closeButton, "LEFT", -2
	end

	if Place(maxButton, level, {"RIGHT", rightMost, rightPoint, rightOffset, 0}) then
		maxButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
		for _, child in ipairs({maxButton:GetChildren()}) do
			if CanChange(child) then
				if child == maxButton.MapUtilsFullscreenButton then
					Save(child)
					child:SetSize(BUTTON_SIZE, BUTTON_SIZE)
				end
				child:SetFrameLevel(level + 1)
			end
		end

		rightMost, rightPoint, rightOffset = maxButton.MapUtilsFullscreenButton or maxButton, "LEFT", -2
	end

	local settingsButton = QuestScrollFrame and QuestScrollFrame.SettingsDropdown
	local searchBox = QuestScrollFrame and QuestScrollFrame.SearchBox
	local questShown = questWidth > 0
	if questShown and Place(settingsButton, level, {"RIGHT", rightMost, rightPoint, rightOffset, 0}) then rightMost, rightPoint, rightOffset = settingsButton, "LEFT", -2 end
	questCount:ClearAllPoints()
	questCount:SetPoint("RIGHT", rightMost, rightPoint, rightOffset - 4, 0)
	if questShown and searchBox ~= nil and Place(searchBox, level, {"LEFT", bar, "RIGHT", -questWidth + 10, CONTENT_RAISE}, {"RIGHT", questCount, "LEFT", -8, 0}) then searchBox:SetHeight(SEARCH_HEIGHT) end
	local filterButton = map.WorldMapTrackingOptionsButton
	local navRight = bar
	local navPoint = "RIGHT"
	local navOffset = -questWidth - 4
	if not questShown then
		navRight, navPoint, navOffset = questCount, "LEFT", -8
	end

	if filterButton ~= nil and CanChange(filterButton) then
		Save(filterButton)
		local height = saved[filterButton]["height"]
		if height ~= nil and height > 0 then filterButton:SetScale(saved[filterButton]["scale"] * (BUTTON_SIZE + 2) / height) end
		filterButton:ClearAllPoints()
		filterButton:SetPoint("RIGHT", navRight, navPoint, navOffset / filterButton:GetScale(), navRight == bar and CONTENT_RAISE / filterButton:GetScale() or 0)
		filterButton:SetFrameLevel(level)
		navRight, navPoint, navOffset = filterButton, "LEFT", -4
	end

	local menuButton = MapUtils.MapMenuButton
	if menuButton ~= nil then
		menuButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
		menuButton:ClearAllPoints()
		menuButton:SetPoint("RIGHT", navRight, navPoint, navRight == filterButton and 0 or navOffset, navRight == bar and CONTENT_RAISE or 0)
		menuButton:SetFrameLevel(level)
		navRight, navPoint, navOffset = menuButton, "LEFT", -4
	end

	if Place(map.NavBar, level, {"LEFT", bar, "LEFT", 2 - GAP["left"], NAV_RAISE}, {"RIGHT", navRight, navPoint, navOffset, NAV_RAISE}) then
		map.NavBar:SetHeight(NAV_HEIGHT)
		ShrinkNavBar()
	end

	local topGap = MapUtils:GetSimpleMapTopGap()
	if MapUtils:IsSecret(topGap) then topGap = 0 end
	for _, frame in ipairs({map, map.BorderFrame}) do
		if CanChange(frame) then
			if hitInsets[frame] == nil then hitInsets[frame] = {frame:GetHitRectInsets()} end
			local l, r, t, b = unpack(hitInsets[frame])
			frame:SetHitRectInsets(l, r, max(t, topGap), b)
		end
	end

	if questShown and CanChange(QuestScrollFrame) then
		local parent = QuestScrollFrame:GetParent()
		local top, bottom = -50, 0
		local parentTop, parentBottom, barBottom, backBottom = parent:GetTop(), parent:GetBottom(), bar:GetBottom(), back:GetBottom()
		if parentTop ~= nil and parentBottom ~= nil and barBottom ~= nil and backBottom ~= nil and not MapUtils:IsSecret(parentTop) and not MapUtils:IsSecret(barBottom) then
			top = barBottom - GAP["questTop"] - parentTop
			bottom = backBottom - GAP["bottom"] + 1 - parentBottom
		end

		Place(QuestScrollFrame, nil, {"TOPLEFT", parent, "TOPLEFT", 0, top}, {"BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, bottom})
		local details = QuestMapFrame.DetailsFrame
		if details ~= nil and details.ScrollFrame ~= nil and CanChange(details) and CanChange(details.ScrollFrame) then
			Save(details)
			Save(details.ScrollFrame)
			details:ClearAllPoints()
			details:SetPoint("TOPRIGHT", details:GetParent(), "TOPRIGHT", 0, -47)
			details:SetHeight(saved[details]["height"] - 46)
			details.ScrollFrame:SetHeight(saved[details.ScrollFrame]["height"] - 46)
			if details.Bg ~= nil then
				Save(details.Bg)
				details.Bg:SetPoint("BOTTOMLEFT", details, "BOTTOMLEFT", 0, 0)
				details.Bg:SetPoint("BOTTOMRIGHT", details, "BOTTOMRIGHT", 0, 0)
			end
		end
	end
end

local function Apply()
	CreateBar()
	active = true
	for _, region in ipairs({map.BorderFrame:GetRegions()}) do
		HideObject(region)
	end

	for _, child in ipairs({map.BorderFrame:GetChildren()}) do
		if child ~= map.BorderFrame.CloseButton and child ~= map.BorderFrame.MaximizeMinimizeFrame then HideObject(child) end
	end

	HideObject(map.BorderFrame.Bg)
	HideObject(QuestLogCount)
	bar:Show()
	back:Show()
	UpdateQuestCount()
	Layout()
end

local function Remove()
	active = false
	LayoutFullscreenScroll(map.ScrollContainer, false)
	if bar ~= nil then
		bar:Hide()
		back:Hide()
	end

	ShowObjects()
	RestoreSizes()
	for frame, insets in pairs(hitInsets) do
		if CanChange(frame) then
			frame:SetHitRectInsets(unpack(insets))
			hitInsets[frame] = nil
		end
	end
	for frame in pairs(saved) do
		if CanChange(frame) then frame:ClearAllPoints() end
	end

	if MapUtils.MapMenuButton ~= nil then MapUtils.MapMenuButton:ClearAllPoints() end
	for frame, entry in pairs(saved) do
		if Restore(frame, entry) then saved[frame] = nil end
	end

	if MapUtils.LayoutMapMenuButton ~= nil then MapUtils:LayoutMapMenuButton() end
end

function MapUtils:RefreshSimpleMapFrame()
	if not MapUtils:IsSimpleMapFrameAvailable() then return end
	if IsWanted() then
		Apply()
	elseif active then
		Remove()
	end
end

if MapUtils:IsSimpleMapFrameAvailable() then
	map:HookScript(
		"OnShow",
		function()
			if not active then return end
			UpdateQuestCount()
			Layout()
		end
	)

	if map.OnFrameSizeChanged ~= nil then hooksecurefunc(map, "OnFrameSizeChanged", MapUtils.Profile("simpleframe Layout", Layout)) end
	if map.SynchronizeDisplayState ~= nil then hooksecurefunc(map, "SynchronizeDisplayState", MapUtils.Profile("simpleframe Layout", Layout)) end
	if map.OnMapChanged ~= nil then hooksecurefunc(map, "OnMapChanged", function() C_Timer.After(0, ShrinkNavBar) end) end
	if NavBar_AddButton ~= nil then hooksecurefunc("NavBar_AddButton", function(nav) if nav == map.NavBar then ShrinkNavBar() end end) end
	QuestMapFrame:HookScript("OnShow", Layout)
	QuestMapFrame:HookScript("OnHide", Layout)
	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_LOGIN")
	events:RegisterEvent("QUEST_LOG_UPDATE")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript(
		"OnEvent",
		function(_, event)
			if event == "PLAYER_LOGIN" then
				MapUtils:RefreshSimpleMapFrame()
			elseif event == "QUEST_LOG_UPDATE" then
				UpdateQuestCount()
			elseif active and map:IsShown() then
				Layout()
			end
		end
	)
end
