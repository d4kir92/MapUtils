local _, MapUtils = ...
do
	local toc = select(4, GetBuildInfo()) or 0
	if toc >= 50000 and toc < 60000 then
		MapUtils.flavor = "mists"
	elseif toc >= 40000 and toc < 50000 then
		MapUtils.flavor = "cata"
	elseif toc >= 30000 and toc < 40000 then
		MapUtils.flavor = "wrath"
	elseif toc >= 20000 and toc < 30000 then
		MapUtils.flavor = "tbc"
	elseif toc >= 16000 and toc < 20000 then
		MapUtils.flavor = "forever"
	elseif toc >= 11000 and toc < 16000 then
		MapUtils.flavor = "era"
	end
end

function MapUtils:GetFlavor()
	return MapUtils.flavor
end
