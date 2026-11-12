local _, MapUtils = ...
local PREFIX = "!MAU1!"
local window = nil

local function CanEncode()
	return C_EncodingUtil ~= nil and C_EncodingUtil.SerializeCBOR ~= nil and C_EncodingUtil.DeserializeCBOR ~= nil and C_EncodingUtil.CompressString ~= nil and C_EncodingUtil.DecompressString ~= nil and C_EncodingUtil.EncodeBase64 ~= nil and C_EncodingUtil.DecodeBase64 ~= nil
end

function MapUtils:CanImportExport()
	return CanEncode()
end

function MapUtils:EncodeSettingsString()
	if not CanEncode() or type(MAUTTAB) ~= "table" then return nil end
	local ok, result = pcall(function()
		local data = C_EncodingUtil.SerializeCBOR({
			["VERSION"] = MapUtils:GetAddonVersion(),
			["SETTINGS"] = MAUTTAB
		})

		return PREFIX .. C_EncodingUtil.EncodeBase64(C_EncodingUtil.CompressString(data))
	end)

	if ok and type(result) == "string" then return result end
	return nil
end

function MapUtils:DecodeSettingsString(text)
	if type(text) ~= "string" or not CanEncode() then return nil end
	text = string.gsub(text, "%s", "")
	if string.sub(text, 1, #PREFIX) ~= PREFIX then return nil end
	local ok, result = pcall(function()
		local data = C_EncodingUtil.DecompressString(C_EncodingUtil.DecodeBase64(string.sub(text, #PREFIX + 1)))

		return C_EncodingUtil.DeserializeCBOR(data)
	end)

	if not ok or type(result) ~= "table" or type(result["SETTINGS"]) ~= "table" then return nil end
	for key in pairs(result["SETTINGS"]) do
		if type(key) ~= "string" then return nil end
	end

	return result["SETTINGS"]
end

local function CreateWindow()
	local win = MapUtils:CreateUIWindowFrame("MapUtilsImportExport", UIParent, MapUtils:GetWoWBuild() ~= "RETAIL" and "BasicFrameTemplateWithInset" or nil)
	win:SetSize(460, 320)
	win:SetPoint("CENTER")
	win:SetFrameStrata("DIALOG")
	win:SetToplevel(true)
	win:SetMovable(true)
	win:EnableMouse(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", win.StopMovingOrSizing)
	if win.CloseButton then win.CloseButton:SetScript("OnClick", function() win:Hide() end) end
	if win.TitleText then win.TitleText:SetText(MapUtils:Trans("LID_IMPORTEXPORT")) end
	win.SF = CreateFrame("ScrollFrame", "MapUtilsImportExportScroll", win, "UIPanelScrollFrameTemplate")
	win.SF:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -30)
	win.SF:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -34, 40)
	win.SF.bg = win.SF:CreateTexture(nil, "BACKGROUND")
	win.SF.bg:SetAllPoints(win.SF)
	win.SF.bg:SetColorTexture(0.03, 0.03, 0.03, 0.5)
	win.EditBox = CreateFrame("EditBox", "MapUtilsImportExportEditBox", win.SF)
	win.EditBox:SetMultiLine(true)
	win.EditBox:SetAutoFocus(false)
	win.EditBox:SetMaxLetters(0)
	win.EditBox:SetFontObject(ChatFontNormal)
	win.EditBox:SetSize(400, 250)
	win.EditBox:SetScript("OnEscapePressed", function(sel) sel:ClearFocus() end)
	win.SF:SetScrollChild(win.EditBox)
	win.SF:SetScript("OnMouseDown", function() win.EditBox:SetFocus() end)
	win.Export = CreateFrame("Button", "MapUtilsImportExportExport", win, "UIPanelButtonTemplate")
	win.Export:SetSize(140, 24)
	win.Export:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 10)
	win.Export:SetText(MapUtils:Trans("LID_EXPORT"))
	win.Export:SetScript("OnClick", function()
		local text = MapUtils:EncodeSettingsString()
		if text == nil then return end
		win.EditBox:SetText(text)
		win.EditBox:SetFocus()
		win.EditBox:HighlightText()
	end)

	win.Import = CreateFrame("Button", "MapUtilsImportExportImport", win, "UIPanelButtonTemplate")
	win.Import:SetSize(140, 24)
	win.Import:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 10)
	win.Import:SetText(MapUtils:Trans("LID_IMPORT"))
	win.Import:SetScript("OnClick", function()
		local settings = MapUtils:DecodeSettingsString(win.EditBox:GetText())
		if settings == nil then
			MapUtils:MSG(MapUtils:Trans("LID_IMPORTINVALID"))

			return
		end

		MAUTTAB = settings
		ReloadUI()
	end)

	if UISpecialFrames and not tContains(UISpecialFrames, "MapUtilsImportExport") then tinsert(UISpecialFrames, "MapUtilsImportExport") end
	win:Hide()

	return win
end

function MapUtils:ToggleImportExport()
	if window == nil then window = CreateWindow() end
	if window:IsShown() then
		window:Hide()

		return
	end

	window.EditBox:SetText("")
	window:Show()
	window:Raise()
end
