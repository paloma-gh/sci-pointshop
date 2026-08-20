PS = PS or {}
PS.Config = PS.Config or {}

-- DO NOT EDIT ANYTHING ABOVE THIS LINE
-- Shared pointshop config. Tweak as you'd like.

PS.Config.MaxPoints            = 100000 -- Max points a player can have.
PS.Config.JoinBonus            = 500    -- points awarded to players on first join
PS.Config.KillReward           = 100    -- base points for a kill
PS.Config.DeathLossPercent     = 0.025  -- % of net worth lost on death. 2.5% by default.
PS.Config.DeathLossMin         = 1      -- minimum points lost on death. minimum is 1 by default
PS.Config.DeathLossMax         = 1500   -- maximum points lost on death. maximum is 1000 by default.

PS.Config.PlayReward           = 200    -- Point reward for playing on the server.
PS.Config.PlayRewardInterval   = 300	-- Seconds between reward for playing on the server.

PS.Config.HeadshotBonus        = 50
PS.Config.PaybackBonus         = 50
PS.Config.AvengerBonus         = 25
PS.Config.AfterlifeBonus       = 100
PS.Config.LongshotUnit         = 1000   -- points per 1000 units beyond the threshold
PS.Config.LongshotPerUnit      = 10     -- points awarded per LongshotUnit
PS.Config.LongshotThreshold    = 5000   -- must be at least this far away to trigger
PS.Config.PointBlankBonus      = 50
PS.Config.PointBlankRange      = 100     -- hammer units
PS.Config.AssistBonus          = 25

PS.Config.DoubleKillBonus      = 50
PS.Config.TripleKillBonus      = 100
PS.Config.MultiKillBonus       = 250
PS.Config.MultiKillWindow      = 3      -- seconds

PS.Config.DoubleDownMultiplier = 2
PS.Config.LuckyFiveChance      = 0.25   -- % chance to trigger Lucky Five. Default is 25%. I don't suggest changing this because it would require you to change scieffects.lua and the pointshop description.
PS.Config.PaydayBonus          = 0.25   -- bonus point % from Payday. Default is 25%. I don't suggest changing this because it would require you to change scieffects.lua and the pointshop description.

PS.Config.RevengeWindow        = 20     -- seconds a death is remembered for Payback/Avenger checks
PS.Config.AssistWindow         = 15     -- seconds a damage instance counts toward an assist

-- Dynamic Pricing Config

PS.Config.ShopRefreshInterval  = 300   	-- SECONDS between dynamic pricing refreshes. default is 5 minutes (300s)
PS.Config.ShopMarkupPerItemCount = 3   	-- top N most bought items per tab get a mark-up each refresh
PS.Config.ShopMarkupPercent    = 0.25 	-- +% per markup application. default is 25%.
PS.Config.ShopMarkupMaxMultiplier = 2.0 -- markup can never push price above (BasePrice * this)
PS.Config.ShopDiscountPerTabCount = 3   -- number of random items per tab to get discounted each refresh
PS.Config.ShopDiscountPercent  = 0.25 	-- when an item is selected for a discount this is the discount %. default is 25% off

-- DO NOT EDIT ANYTHING BELOW THIS LINE

if SERVER then
	util.AddNetworkString("PS_UpdatePoints")
	util.AddNetworkString("PS_KillFeed")
end

function PS.FormatNumber(n)
	n = math.floor(tonumber(n) or 0)
	local formatted = tostring(n)
	local sign = ""
	if formatted:sub(1, 1) == "-" then
		sign = "-"
		formatted = formatted:sub(2)
	end
	local k
	while true do
		formatted, k = formatted:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return sign .. formatted
end
