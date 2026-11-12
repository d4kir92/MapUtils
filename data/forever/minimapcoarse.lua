local _, MapUtils = ...
if MapUtils:GetFlavor() ~= "forever" then return end
MapUtils:AddMinimapCoarse("forever", 0, "coarse_forever_0")
MapUtils:AddMinimapCoarse("forever", 1, "coarse_forever_1")
