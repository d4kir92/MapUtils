local _, MapUtils = ...
if MapUtils:GetFlavor() ~= "era" then return end
MapUtils:AddMinimapCoarse("era", 0, "coarse_era_0")
MapUtils:AddMinimapCoarse("era", 1, "coarse_era_1")
