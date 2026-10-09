local _, MapUtils = ...
if WorldMapFrame == nil or C_Map == nil or C_QuestLog == nil then return end
if C_Map.GetMapChildrenInfo == nil or C_Map.GetMapRectOnMap == nil or C_QuestLog.GetQuestsOnMap == nil or C_QuestLog.ReadyForTurnIn == nil then return end
local updater = CreateFrame("Frame", nil, WorldMapFrame)
local pins = {}
local entries = {}
local seen = {}
local mapTypes = {}
local zoneChildren = {}
local dirty = true
local lastMapID
local elapsedTime = 0
local function HidePins()
	for _, pin in ipairs(pins) do
		pin:Hide()
	end
end

local function ProjectPosition(sourceID, targetID, x, y)
	local visited = {}
	while sourceID ~= targetID do
		if visited[sourceID] then return end
		visited[sourceID] = true
		local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(sourceID, targetID)
		if minX ~= nil and maxX ~= nil and minY ~= nil and maxY ~= nil and minX < maxX and minY < maxY then return minX + x * (maxX - minX), minY + y * (maxY - minY) end
		local info = C_Map.GetMapInfo(sourceID)
		local parentID = info and info.parentMapID
		if parentID == nil or parentID == 0 then return end
		minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(sourceID, parentID)
		if minX == nil or maxX == nil or minY == nil or maxY == nil or minX >= maxX or minY >= maxY then return end
		x, y = minX + x * (maxX - minX), minY + y * (maxY - minY)
		sourceID = parentID
	end
	return x, y
end

local function GetMapType(mapID)
	if mapID == nil then return nil end
	if mapTypes[mapID] == nil then
		local info = C_Map.GetMapInfo(mapID)
		if info == nil then return nil end
		mapTypes[mapID] = info.mapType or false
	end

	return mapTypes[mapID] or nil
end

local function GetZoneChildren(mapID)
	if zoneChildren[mapID] ~= nil then return zoneChildren[mapID] end
	local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
	if children == nil then return {} end
	table.sort(children, function(a, b)
		if a.mapType ~= b.mapType then return a.mapType > b.mapType end
		return a.mapID < b.mapID
	end)

	local list = {}
	for _, source in ipairs(children) do
		if source.mapType >= Enum.UIMapType.Zone then table.insert(list, source) end
	end

	zoneChildren[mapID] = list

	return list
end

local function CollectEntries(mapID)
	wipe(entries)
	wipe(seen)
	if WorldMapFrame.EnumeratePinsByTemplate then
		for pin in WorldMapFrame:EnumeratePinsByTemplate("QuestPinTemplate") do
			local questID = pin.GetQuestID and pin:GetQuestID()
			if pin:IsShown() and questID then seen[questID] = true end
		end
	end

	for _, source in ipairs(GetZoneChildren(mapID)) do
		for _, poi in ipairs(C_QuestLog.GetQuestsOnMap(source.mapID) or {}) do
			local questID = poi.questID
			if questID and not seen[questID] and C_QuestLog.ReadyForTurnIn(questID) and type(poi.x) == "number" and type(poi.y) == "number" and poi.x >= 0 and poi.x <= 1 and poi.y >= 0 and poi.y <= 1 then
				local x, y = ProjectPosition(source.mapID, mapID, poi.x, poi.y)
				if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
					seen[questID] = true
					table.insert(entries, {
						questID = questID,
						mapID = source.mapID,
						name = source.name,
						x = x,
						y = y
					})
				end
			end
		end
	end
end

local function SetPinAtlas(texture, atlas, fallback)
	local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
	texture:SetPoint("CENTER")
	if info then
		texture:SetAtlas(atlas)
		texture.pixelWidth, texture.pixelHeight = info.width, info.height
	elseif fallback then
		texture:SetTexture(fallback)
		texture.pixelWidth, texture.pixelHeight = 24, 24
	else
		texture:Hide()
	end
end

local function CreatePin(canvas)
	local pin = CreateFrame("Button", nil, canvas)
	pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	pin.normal = pin:CreateTexture(nil, "ARTWORK")
	pin.pushed = pin:CreateTexture(nil, "ARTWORK")
	pin.highlight = pin:CreateTexture(nil, "OVERLAY")
	pin.icon = pin:CreateTexture(nil, "ARTWORK", nil, 1)
	pin.textures = {pin.normal, pin.pushed, pin.highlight, pin.icon}
	SetPinAtlas(pin.normal, "UI-QuestPoi-QuestNumber")
	SetPinAtlas(pin.pushed, "UI-QuestPoi-QuestNumber-Pressed")
	SetPinAtlas(pin.highlight, "UI-QuestPoi-InnerGlow")
	SetPinAtlas(pin.icon, "UI-QuestIcon-TurnIn-Normal", "Interface\\GossipFrame\\ActiveQuestIcon")
	pin:SetNormalTexture(pin.normal)
	pin:SetPushedTexture(pin.pushed)
	pin:SetHighlightTexture(pin.highlight, "ADD")
	pin:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(C_QuestLog.GetTitleForQuestID(self.entry.questID) or QUESTS_LABEL, 1, 0.82, 0)
		GameTooltip:AddLine(self.entry.name or "", 1, 1, 1)
		GameTooltip:Show()
	end)

	pin:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	pin:SetScript("OnHide", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
	pin:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			local info = C_Map.GetMapInfo(WorldMapFrame:GetMapID())
			if info and info.parentMapID and info.parentMapID > 0 then WorldMapFrame:SetMapID(info.parentMapID) end
		else
			local entry = self.entry
			if C_QuestLog.AddQuestWatch and (QuestUtils_IsQuestWatched == nil or not QuestUtils_IsQuestWatched(entry.questID)) then C_QuestLog.AddQuestWatch(entry.questID) end
			if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then C_SuperTrack.SetSuperTrackedQuestID(entry.questID) end
			if QuestMapFrame_ShowQuestDetails then
				QuestMapFrame_ShowQuestDetails(entry.questID)
			elseif C_QuestLog.SetSelectedQuest then
				C_QuestLog.SetSelectedQuest(entry.questID)
			end

			WorldMapFrame:SetMapID(entry.mapID)
		end
	end)
	return pin
end

local function UpdatePins()
	local mapID = WorldMapFrame:GetMapID()
	local mapType = GetMapType(mapID)
	local getter = C_CVar and C_CVar.GetCVarBool or GetCVarBool
	if mapType == nil or Enum == nil or Enum.UIMapType == nil or (mapType ~= Enum.UIMapType.World and mapType ~= Enum.UIMapType.Continent) or not MapUtils:GetConfig("QUESTTURNINWORLDMAPPINS", true) or (getter and not getter("questPOI")) then
		HidePins()
		lastMapID = nil
		return
	end

	local canvas = WorldMapFrame:GetCanvas()
	if canvas == nil then return end
	local scale = canvas:GetScale()
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if scale == nil or scale <= 0 or width <= 0 or height <= 0 then
		HidePins()
		return
	end

	if dirty or mapID ~= lastMapID then
		CollectEntries(mapID)
		dirty = false
		lastMapID = mapID
	end

	for index, entry in ipairs(entries) do
		local pin = pins[index]
		if pin == nil then
			pin = CreatePin(canvas)
			pins[index] = pin
		end

		pin.entry = entry
		local selected = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID() == entry.questID or false
		if pin.selected ~= selected then
			pin.selected = selected
			SetPinAtlas(pin.normal, selected and "UI-QuestPoi-QuestNumber-SuperTracked" or "UI-QuestPoi-QuestNumber")
			SetPinAtlas(pin.pushed, selected and "UI-QuestPoi-QuestNumber-Pressed-SuperTracked" or "UI-QuestPoi-QuestNumber-Pressed")
		end

		pin:SetSize(20 / scale, 20 / scale)
		for _, texture in ipairs(pin.textures) do
			if texture.pixelWidth then texture:SetSize(texture.pixelWidth / scale, texture.pixelHeight / scale) end
		end

		pin:SetFrameLevel(canvas:GetFrameLevel() + 30)
		pin:ClearAllPoints()
		pin:SetPoint("CENTER", canvas, "TOPLEFT", width * entry.x, -height * entry.y)
		pin:Show()
	end

	for index = #entries + 1, #pins do
		pins[index]:Hide()
	end
end

function MapUtils:RefreshQuestTurnIns()
	dirty = true
	HidePins()
end

updater:RegisterEvent("QUEST_LOG_UPDATE")
updater:RegisterEvent("QUEST_POI_UPDATE")
updater:RegisterEvent("CVAR_UPDATE")
updater:SetScript("OnEvent", function() dirty = true end)
updater:SetScript("OnUpdate", function(_, elapsed)
	elapsedTime = elapsedTime + elapsed
	if elapsedTime < 0.1 then return end
	elapsedTime = 0
	UpdatePins()
end)

WorldMapFrame:HookScript("OnShow", function()
	dirty = true
	elapsedTime = 0
end)

WorldMapFrame:HookScript("OnHide", HidePins)
