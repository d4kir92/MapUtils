local _, MapUtils = ...
local GatherNodes = {
	optionKey = "GATHERNODEMINIMAPICONS",
	learnedKey = "GATHERNODENAMES",
	herbItems = {765, 785, 2447, 2449, 2450, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819, 3820, 3821, 4625, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468},
	oreNames = {
		{"dark iron deposit", 11370},
		{"truesilver deposit", 7911},
		{"mithril deposit", 3858},
		{"thorium vein", 10620},
		{"iron deposit", 2772},
		{"copper vein", 2770},
		{"tin vein", 2771},
		{"silver vein", 2775},
		{"gold vein", 2776},
	},
	finderSpells = {
		[2383] = true,
		[2580] = true
	},
	gatherSpells = {2366, 2575},
	tradeGoods = 7,
	herbSubclass = 9,
	metalSubclass = 7,
	step = 5,
	perFrame = 80,
	scanInterval = 1,
	noFinderInterval = 5,
	learnSeconds = 10,
	iconSize = 14,
	edge = 4,
	maxIcons = 40,
	mask = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
	knownItems = {},
	herbNames = {},
	herbNamesMissing = true,
	resolved = {},
	resolvedCount = 0,
	lines = {},
	linesCount = 0,
	nodes = {},
	icons = {},
	scan = nil,
	nextScan = 0,
	castTarget = nil,
	castTime = 0
}

for _, itemID in ipairs(GatherNodes.herbItems) do
	GatherNodes.knownItems[itemID] = true
end

for _, entry in ipairs(GatherNodes.oreNames) do
	GatherNodes.knownItems[entry[2]] = true
end

function GatherNodes.IsSecret(...)
	if issecretvalue == nil then return false end
	for i = 1, select("#", ...) do
		if issecretvalue(select(i, ...)) then return true end
	end

	return false
end

function GatherNodes.CanScan()
	return Minimap ~= nil and Minimap.SetUsingSoftCursor ~= nil and Minimap.UpdateMouseoverAtPoint ~= nil and C_TooltipInfo ~= nil and C_TooltipInfo.GetMinimapMouseover ~= nil and UnitPosition ~= nil
end

function MapUtils:CanShowGatherNodes()
	return GatherNodes.CanScan() or GatherNodes.UsesBlips ~= nil and GatherNodes.UsesBlips()
end

function GatherNodes.IsEnabled()
	return GatherNodes.CanScan() and MapUtils:GetConfig(GatherNodes.optionKey, true) == true
end

function GatherNodes.IsController()
	if InputUtil ~= nil and InputUtil.IsGamepadUIEnabled ~= nil and InputUtil.IsGamepadUIEnabled() then return true end

	return SoftCursor ~= nil and SoftCursor.IsShown ~= nil and SoftCursor:IsShown()
end

function GatherNodes.IsBlocked()
	return InCombatLockdown() or not Minimap:IsVisible() or Minimap:IsMouseOver() or GatherNodes.IsController() or IsInInstance()
end

function GatherNodes.GetLearned()
	if type(MAUTTAB) ~= "table" then return nil end
	if type(MAUTTAB[GatherNodes.learnedKey]) ~= "table" then MAUTTAB[GatherNodes.learnedKey] = {} end

	return MAUTTAB[GatherNodes.learnedKey]
end

function GatherNodes.GetItemName(itemID)
	if C_Item ~= nil and C_Item.GetItemNameByID ~= nil then return C_Item.GetItemNameByID(itemID) end
	if GetItemInfo ~= nil then return (GetItemInfo(itemID)) end

	return nil
end

function GatherNodes.GetItemIcon(itemID)
	if C_Item ~= nil and C_Item.GetItemIconByID ~= nil then return C_Item.GetItemIconByID(itemID) end
	if GetItemIcon ~= nil then return GetItemIcon(itemID) end

	return nil
end

function GatherNodes.LoadHerbNames()
	if not GatherNodes.herbNamesMissing then return end
	local missing = false
	for _, itemID in ipairs(GatherNodes.herbItems) do
		local name = GatherNodes.GetItemName(itemID)
		if type(name) == "string" and not GatherNodes.IsSecret(name) and name ~= "" then
			GatherNodes.herbNames[strlower(name)] = itemID
		else
			missing = true
			if C_Item ~= nil and C_Item.RequestLoadItemDataByID ~= nil then C_Item.RequestLoadItemDataByID(itemID) end
		end
	end

	GatherNodes.herbNamesMissing = missing
	GatherNodes.ResetResolved()
end

function GatherNodes.ResetResolved()
	GatherNodes.resolved = {}
	GatherNodes.resolvedCount = 0
end

function GatherNodes.Resolve(name)
	local cached = GatherNodes.resolved[name]
	if cached ~= nil then return cached or nil end
	local itemID = nil
	local learned = GatherNodes.GetLearned()
	if learned ~= nil and type(learned[name]) == "number" then itemID = learned[name] end
	if itemID == nil then itemID = GatherNodes.herbNames[name] end
	if itemID == nil and not name:find("[%d:/]") then
		for _, entry in ipairs(GatherNodes.oreNames) do
			if name:find(entry[1], 1, true) ~= nil then
				itemID = entry[2]
				break
			end
		end
	end

	if GatherNodes.resolvedCount >= 500 then GatherNodes.ResetResolved() end
	GatherNodes.resolved[name] = itemID or false
	GatherNodes.resolvedCount = GatherNodes.resolvedCount + 1

	return itemID
end

function GatherNodes.Clean(text)
	text = text:gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("\226\128\153", "'")

	return strlower(text:match("^%s*(.-)%s*$"))
end

function GatherNodes.ItemsIn(text)
	local list = GatherNodes.lines[text]
	if list ~= nil then return list end
	list = {}
	for part in text:gmatch("[^\n]+") do
		local itemID = GatherNodes.Resolve(GatherNodes.Clean(part))
		if itemID ~= nil then tinsert(list, itemID) end
	end

	if GatherNodes.linesCount >= 300 then
		GatherNodes.lines = {}
		GatherNodes.linesCount = 0
	end

	GatherNodes.lines[text] = list
	GatherNodes.linesCount = GatherNodes.linesCount + 1

	return list
end

function GatherNodes.ResetLines()
	GatherNodes.lines = {}
	GatherNodes.linesCount = 0
	GatherNodes.ResetResolved()
end

function GatherNodes.GetViewRadius()
	if C_Minimap ~= nil and C_Minimap.GetViewRadius ~= nil then
		local radius = C_Minimap.GetViewRadius()
		if type(radius) == "number" and not GatherNodes.IsSecret(radius) and radius > 0 then return radius end
	end

	if MapUtils.GetMinimapYards ~= nil then
		local yards = MapUtils.GetMinimapYards()
		if type(yards) == "number" and yards > 0 then return yards / 2 end
	end

	return nil
end

function GatherNodes.GetFacing()
	if MapUtils:GetCVar("rotateMinimap") ~= "1" then return 0 end
	local facing = GetPlayerFacing ~= nil and GetPlayerFacing() or nil
	if facing == nil or GatherNodes.IsSecret(facing) then return nil end

	return facing
end

function GatherNodes.GetPlayer()
	local wx, wy, _, instanceID = UnitPosition("player")
	if wx == nil or wy == nil or GatherNodes.IsSecret(wx, wy, instanceID) then return nil end

	return wx, wy, instanceID
end

function GatherNodes.FinderActive()
	if C_Minimap == nil or C_Minimap.GetNumTrackingTypes == nil or C_Minimap.GetTrackingInfo == nil then return true end
	for index = 1, C_Minimap.GetNumTrackingTypes() do
		local info = C_Minimap.GetTrackingInfo(index)
		if type(info) ~= "table" or GatherNodes.IsSecret(info, info.active, info.spellID) then return true end
		if info.active and GatherNodes.finderSpells[info.spellID] then return true end
	end

	return false
end

function GatherNodes.StartScan()
	local width, height = Minimap:GetSize()
	local centerX, centerY = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	local radius = GatherNodes.GetViewRadius()
	local wx, _, instanceID = GatherNodes.GetPlayer()
	if width == nil or height == nil or centerX == nil or centerY == nil or scale == nil or scale <= 0 or radius == nil or wx == nil then return end
	local half = math.min(width, height) / 2
	local count = math.floor(half / GatherNodes.step)
	GatherNodes.LoadHerbNames()
	GatherNodes.scan = {
		centerX = centerX,
		centerY = centerY,
		scale = scale,
		half = half,
		yardsPerUnit = radius / (width / 2),
		zoom = Minimap:GetZoom(),
		instanceID = instanceID,
		count = count,
		side = count * 2 + 1,
		square = GetMinimapShape ~= nil and GetMinimapShape() == "SQUARE",
		index = 0,
		hits = {}
	}
end

function GatherNodes.Probe(scan, i, j)
	local offsetX = i * GatherNodes.step
	local offsetY = j * GatherNodes.step
	Minimap:UpdateMouseoverAtPoint((scan.centerX + offsetX) * scan.scale, (scan.centerY + offsetY) * scan.scale)
	local data = C_TooltipInfo.GetMinimapMouseover()
	if type(data) ~= "table" or GatherNodes.IsSecret(data) or type(data.lines) ~= "table" then return end
	for _, line in ipairs(data.lines) do
		local text = line.leftText
		if type(text) == "string" and not GatherNodes.IsSecret(text) then
			for _, itemID in ipairs(GatherNodes.ItemsIn(text)) do
				local a = offsetX * scan.yardsPerUnit
				local b = offsetY * scan.yardsPerUnit
				local s = math.sin(scan.facing)
				local c = math.cos(scan.facing)
				tinsert(
					scan.hits,
					{
						i = i,
						j = j,
						item = itemID,
						x = scan.wx + s * a + c * b,
						y = scan.wy + s * b - c * a
					}
				)
			end
		end
	end
end

function GatherNodes.ScanStep(scan)
	local last = math.min(scan.index + GatherNodes.perFrame, scan.side * scan.side) - 1
	local limit = scan.half * scan.half
	for index = scan.index, last do
		local i = index % scan.side - scan.count
		local j = math.floor(index / scan.side) - scan.count
		local dx = i * GatherNodes.step
		local dy = j * GatherNodes.step
		if scan.square or dx * dx + dy * dy <= limit then GatherNodes.Probe(scan, i, j) end
	end

	scan.index = last + 1
end

function GatherNodes.GroupHits(hits)
	local byKey = {}
	for _, hit in ipairs(hits) do
		byKey[hit.item .. ":" .. hit.i .. ":" .. hit.j] = hit
	end

	local nodes = {}
	for _, hit in ipairs(hits) do
		if not hit.seen then
			hit.seen = true
			local sx, sy, n = 0, 0, 0
			local stack = {hit}
			while #stack > 0 do
				local current = tremove(stack)
				sx = sx + current.x
				sy = sy + current.y
				n = n + 1
				for di = -1, 1 do
					for dj = -1, 1 do
						local near = byKey[hit.item .. ":" .. (current.i + di) .. ":" .. (current.j + dj)]
						if near ~= nil and not near.seen then
							near.seen = true
							tinsert(stack, near)
						end
					end
				end
			end

			tinsert(
				nodes,
				{
					item = hit.item,
					x = sx / n,
					y = sy / n
				}
			)

			if #nodes >= GatherNodes.maxIcons then break end
		end
	end

	return nodes
end

function GatherNodes.FinishScan(scan)
	GatherNodes.scan = nil
	GatherNodes.nodes = GatherNodes.GroupHits(scan.hits)
	GatherNodes.instanceID = scan.instanceID
	GatherNodes.nextScan = GetTime() + GatherNodes.scanInterval
end

function GatherNodes.StopScan()
	GatherNodes.scan = nil
	GatherNodes.nextScan = GetTime() + GatherNodes.scanInterval
end

function GatherNodes.Clear()
	GatherNodes.scan = nil
	GatherNodes.nodes = {}
	for _, icon in ipairs(GatherNodes.icons) do
		icon:Hide()
	end
end

function GatherNodes.UpdateScan()
	local scan = GatherNodes.scan
	if scan == nil then
		if GetTime() < GatherNodes.nextScan or GatherNodes.IsBlocked() then return end
		if not GatherNodes.FinderActive() then
			GatherNodes.nodes = {}
			GatherNodes.nextScan = GetTime() + GatherNodes.noFinderInterval

			return
		end

		GatherNodes.StartScan()
		scan = GatherNodes.scan
		if scan == nil then
			GatherNodes.nextScan = GetTime() + GatherNodes.scanInterval

			return
		end
	end

	if GatherNodes.IsBlocked() or Minimap:GetZoom() ~= scan.zoom then
		GatherNodes.StopScan()

		return
	end

	local wx, wy, instanceID = GatherNodes.GetPlayer()
	local facing = GatherNodes.GetFacing()
	if wx == nil or facing == nil or instanceID ~= scan.instanceID then
		GatherNodes.StopScan()

		return
	end

	scan.wx, scan.wy, scan.facing = wx, wy, facing
	Minimap:SetUsingSoftCursor(true)
	local ok = pcall(GatherNodes.ScanStep, scan)
	Minimap:SetUsingSoftCursor(false)
	if not ok then
		GatherNodes.StopScan()

		return
	end

	if scan.index >= scan.side * scan.side then GatherNodes.FinishScan(scan) end
end

function GatherNodes.GetIcon(index)
	local icon = GatherNodes.icons[index]
	if icon ~= nil then return icon end
	local size = GatherNodes.iconSize
	icon = CreateFrame("Frame", nil, GatherNodes.overlay)
	icon:SetSize(size, size)
	icon:EnableMouse(false)
	icon.back = icon:CreateTexture(nil, "BACKGROUND")
	icon.back:SetPoint("CENTER")
	icon.back:SetSize(size + 2, size + 2)
	icon.back:SetColorTexture(0, 0, 0, 0.9)
	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints()
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	if icon.CreateMaskTexture ~= nil then
		icon.backMask = icon:CreateMaskTexture()
		icon.backMask:SetTexture(GatherNodes.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		icon.backMask:SetAllPoints(icon.back)
		icon.back:AddMaskTexture(icon.backMask)
		icon.mask = icon:CreateMaskTexture()
		icon.mask:SetTexture(GatherNodes.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		icon.mask:SetAllPoints(icon.texture)
		icon.texture:AddMaskTexture(icon.mask)
	end

	GatherNodes.icons[index] = icon

	return icon
end

function GatherNodes.UpdateIcons()
	local shown = 0
	local wx, wy, instanceID = GatherNodes.GetPlayer()
	local facing = GatherNodes.GetFacing()
	local radius = GatherNodes.GetViewRadius()
	local width, height = Minimap:GetSize()
	if wx ~= nil and facing ~= nil and radius ~= nil and width ~= nil and height ~= nil and width > 0 and instanceID == GatherNodes.instanceID then
		local unitsPerYard = (width / 2) / radius
		local half = math.min(width, height) / 2 - GatherNodes.edge
		local square = GetMinimapShape ~= nil and GetMinimapShape() == "SQUARE"
		local s = math.sin(facing)
		local c = math.cos(facing)
		for _, node in ipairs(GatherNodes.nodes) do
			local dx = node.x - wx
			local dy = node.y - wy
			local a = (s * dx - c * dy) * unitsPerYard
			local b = (c * dx + s * dy) * unitsPerYard
			local inside = square and math.abs(a) <= half and math.abs(b) <= half or not square and a * a + b * b <= half * half
			if inside then
				shown = shown + 1
				local icon = GatherNodes.GetIcon(shown)
				if icon.item ~= node.item then
					icon.item = node.item
					icon.texture:SetTexture(GatherNodes.GetItemIcon(node.item) or 134400)
				end

				icon:ClearAllPoints()
				icon:SetPoint("CENTER", GatherNodes.overlay, "CENTER", a, b)
				icon:Show()
			end
		end
	end

	for index = shown + 1, #GatherNodes.icons do
		GatherNodes.icons[index]:Hide()
	end
end

function GatherNodes.OnUpdate()
	if not GatherNodes.IsEnabled() then
		GatherNodes.Clear()
		GatherNodes.overlay:Hide()

		return
	end

	GatherNodes.UpdateScan()
	GatherNodes.UpdateIcons()
end

function GatherNodes.Refresh()
	if GatherNodes.overlay == nil then return end
	GatherNodes.Clear()
	GatherNodes.nextScan = 0
	if GatherNodes.IsEnabled() then
		GatherNodes.overlay:Show()
	else
		GatherNodes.overlay:Hide()
	end
end

function MapUtils:RefreshGatherNodes()
	GatherNodes.Refresh()
	GatherNodes.UpdateBlips()
end

function GatherNodes.IsGatherSpell(spellID)
	if type(spellID) ~= "number" or GatherNodes.IsSecret(spellID) then return false end
	local getName = C_Spell ~= nil and C_Spell.GetSpellName or GetSpellInfo
	if getName == nil then return false end
	local name = getName(spellID)
	if name == nil or GatherNodes.IsSecret(name) then return false end
	for _, gatherID in ipairs(GatherNodes.gatherSpells) do
		if getName(gatherID) == name then return true end
	end

	return false
end

function GatherNodes.GetLootItem()
	local fallback = nil
	for slot = 1, GetNumLootItems() do
		local link = GetLootSlotLink(slot)
		if type(link) == "string" and not GatherNodes.IsSecret(link) then
			local itemID = tonumber(link:match("item:(%d+)"))
			if itemID ~= nil then
				if GatherNodes.knownItems[itemID] then return itemID end
				if fallback == nil and C_Item ~= nil and C_Item.GetItemInfoInstant ~= nil then
					local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
					if classID == GatherNodes.tradeGoods and (subclassID == GatherNodes.herbSubclass or subclassID == GatherNodes.metalSubclass) then fallback = itemID end
				end
			end
		end
	end

	return fallback
end

function GatherNodes.Learn()
	local target = GatherNodes.castTarget
	GatherNodes.castTarget = nil
	if target == nil or GetTime() - GatherNodes.castTime > GatherNodes.learnSeconds then return end
	local name = GatherNodes.Clean(target)
	if name == "" then return end
	GatherNodes.LoadHerbNames()
	local itemID = GatherNodes.GetLootItem()
	if itemID == nil or GatherNodes.Resolve(name) == itemID then return end
	local learned = GatherNodes.GetLearned()
	if learned == nil then return end
	learned[name] = itemID
	GatherNodes.ResetLines()
end

function GatherNodes.OnEvent(_, event, ...)
	if event == "UNIT_SPELLCAST_SENT" then
		local unit, target, _, spellID = ...
		if unit ~= "player" or type(target) ~= "string" or GatherNodes.IsSecret(target) or target == "" then return end
		if not GatherNodes.IsGatherSpell(spellID) then return end
		GatherNodes.castTarget = target
		GatherNodes.castTime = GetTime()
	elseif event == "LOOT_OPENED" then
		GatherNodes.Learn()
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		local itemID = ...
		if GatherNodes.herbNamesMissing and GatherNodes.knownItems[itemID] then
			GatherNodes.LoadHerbNames()
			GatherNodes.ResetLines()
		end
	elseif event == "PLAYER_LOGIN" then
		GatherNodes.LoadHerbNames()
		GatherNodes.Refresh()
	elseif event == "PLAYER_ENTERING_WORLD" then
		GatherNodes.Refresh()
	end
end

if GatherNodes.CanScan() then
	GatherNodes.overlay = CreateFrame("Frame", nil, Minimap)
	GatherNodes.overlay:SetAllPoints(Minimap)
	GatherNodes.overlay:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	GatherNodes.overlay:EnableMouse(false)
	GatherNodes.overlay:SetScript("OnUpdate", GatherNodes.OnUpdate)
	GatherNodes.overlay:Hide()
	GatherNodes.eventFrame = CreateFrame("Frame")
	GatherNodes.eventFrame:RegisterEvent("PLAYER_LOGIN")
	GatherNodes.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GatherNodes.eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
	GatherNodes.eventFrame:RegisterEvent("LOOT_OPENED")
	GatherNodes.eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	GatherNodes.eventFrame:SetScript("OnEvent", GatherNodes.OnEvent)
end

GatherNodes.blipFiles = {
	herbs = "Interface\\AddOns\\MapUtils\\media\\blipherbs",
	ore = "Interface\\AddOns\\MapUtils\\media\\blipore",
	default = "Interface\\Minimap\\ObjectIconsAtlas"
}

GatherNodes.blipSpells = {
	herbs = 2383,
	ore = 2580
}

function GatherNodes.UsesBlips()
	return not GatherNodes.CanScan() and Minimap ~= nil and Minimap.SetBlipTexture ~= nil and WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function GatherNodes.GetSpellTexture(spellID)
	if C_Spell ~= nil and C_Spell.GetSpellTexture ~= nil then return C_Spell.GetSpellTexture(spellID) end
	if GetSpellTexture ~= nil then return GetSpellTexture(spellID) end

	return nil
end

function GatherNodes.GetTrackedKind()
	if C_Minimap ~= nil and C_Minimap.GetNumTrackingTypes ~= nil and C_Minimap.GetTrackingInfo ~= nil then
		for index = 1, C_Minimap.GetNumTrackingTypes() do
			local info = C_Minimap.GetTrackingInfo(index)
			if type(info) == "table" and info.active then
				for kind, spellID in pairs(GatherNodes.blipSpells) do
					if info.spellID == spellID then return kind end
				end
			end
		end
	end

	local texture = GetTrackingTexture ~= nil and GetTrackingTexture() or nil
	if texture == nil then return nil end
	for kind, spellID in pairs(GatherNodes.blipSpells) do
		if GatherNodes.GetSpellTexture(spellID) == texture then return kind end
	end

	return nil
end

function GatherNodes.UpdateBlips()
	if not GatherNodes.UsesBlips() then return end
	local kind = nil
	if MapUtils:GetConfig(GatherNodes.optionKey, true) == true then kind = GatherNodes.GetTrackedKind() end
	local file = GatherNodes.blipFiles[kind or "default"]
	if file == GatherNodes.blipCurrent or kind == nil and GatherNodes.blipCurrent == nil then return end
	GatherNodes.blipCurrent = file
	Minimap:SetBlipTexture(file)
	if Minimap.UpdateBlips ~= nil then Minimap:UpdateBlips() end
end

if GatherNodes.UsesBlips() then
	GatherNodes.blipFrame = CreateFrame("Frame")
	GatherNodes.blipFrame:RegisterEvent("PLAYER_LOGIN")
	GatherNodes.blipFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GatherNodes.blipFrame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
	GatherNodes.blipFrame:SetScript("OnEvent", GatherNodes.UpdateBlips)
end
