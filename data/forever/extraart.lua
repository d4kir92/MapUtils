local _, MapUtils = ...
if MapUtils:GetFlavor() ~= "forever" then return end
MapUtils.WORLDARTEDITS = {
	[8025435] = "world_5",
	[8025436] = "world_6",
	[8025437] = "world_7",
	[8025438] = "world_8"
}

MapUtils:AddExtraZoneArt("forever", 1415, {-2631.25, -533.333, 293.75, 3439.58}, 1002, 668, {308492, 308496, 308497, 308498, 308499, 308500, 308501, 308502, 308503, 308493, 308494, 308495})
MapUtils:AddExtraMapArt("forever", 1414, {194, 100, 192, 96}, "gap_kalimdor_north")
MapUtils:AddExtraMapArt("forever", 1414, {108, 474, 112, 112}, "gap_kalimdor_southwest")
MapUtils:AddExtraMapArt("forever", 1415, {828, 44, 96, 96}, "gap_eastern_north")
