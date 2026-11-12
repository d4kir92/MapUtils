local _, MapUtils = ...
if MapUtils:GetFlavor() ~= "tbc" then return end
MapUtils:AddMinimapCoarse("tbc", 0, "coarse_tbc_0")
MapUtils:AddMinimapCoarse("tbc", 1, "coarse_tbc_1")
MapUtils:AddMinimapCoarse("tbc", 530, "coarse_tbc_530")
