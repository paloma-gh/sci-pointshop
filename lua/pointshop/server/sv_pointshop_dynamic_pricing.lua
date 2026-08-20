-- Handles dynamic pricing (read config file).

PS = PS or {}
PS.DynamicPricing = PS.DynamicPricing or {}

local DP = PS.DynamicPricing

DP.PurchaseCounts = DP.PurchaseCounts or {}

DP.MarkupStreaks = DP.MarkupStreaks or {}

DP.PriceState = DP.PriceState or {}

DP.PeriodStartTime = DP.PeriodStartTime or 0

util.AddNetworkString("PS_Shop_SyncPricing")

local TIMER_NAME = "PS_DynamicPricing_Refresh"


-- Purchase tracking

function PS.DynamicPricing.RecordPurchase(buyable_class)
	DP.PurchaseCounts[buyable_class] =
		(DP.PurchaseCounts[buyable_class] or 0) + 1
end

hook.Add("PS_ItemPurchased", "PS_DynamicPricing_RecordPurchase", function(ply, buyable_class, item)
	PS.DynamicPricing.RecordPurchase(buyable_class)
end)


-- Price computation

function PS.DynamicPricing.GetEffectivePrice(buyable_class)
	local item = PS.Items[buyable_class]
	if not item then return 0 end

	local base_price = tonumber(item.BasePrice) or 0
	local state = DP.PriceState[buyable_class]

	if not state then
		return base_price
	end

	if state.state == "markup" then
		local price = base_price * (1 + state.percent)
		local max_price = base_price * PS.Config.ShopMarkupMaxMultiplier

		return math.min(price, max_price)

	elseif state.state == "discount" then
		return base_price * (1 - state.percent)
	end

	return base_price
end

-- Refresh shop

local function GetPurchasedItemsForType(item_type)
	local results = {}

	for class, count in pairs(DP.PurchaseCounts) do
		if count > 0 then
			local item = PS.Items[class]

			if item and item.Type == item_type then
				table.insert(results, {
					class = class,
					count = count
				})
			end
		end
	end

	table.sort(results, function(a, b)
		return a.count > b.count
	end)

	return results
end

local function ShuffledCopy(list)
	local copy = {}

	for i, v in ipairs(list) do
		copy[i] = v
	end

	for i = #copy, 2, -1 do
		local j = math.random(i)
		copy[i], copy[j] = copy[j], copy[i]
	end

	return copy
end

function PS.DynamicPricing.RunRefresh()
	local new_state = {}

	local marked_up = {}

	local currently_marked_up = {}

	local tab_types = {
		PS.ITEM_TYPE_ENTITY,
		PS.ITEM_TYPE_WEAPON,
		PS.ITEM_TYPE_BONUS
	}

	for _, item_type in ipairs(tab_types) do
		local purchased = GetPurchasedItemsForType(item_type)

		for i = 1, math.min(
			PS.Config.ShopMarkupPerItemCount,
			#purchased
		) do

			local class = purchased[i].class

			currently_marked_up[class] = true

			DP.MarkupStreaks[class] =
				(DP.MarkupStreaks[class] or 0) + 1

			local markup_percent =
				DP.MarkupStreaks[class] *
				PS.Config.ShopMarkupPercent

			local max_markup_percent =
				math.max(
					0,
					PS.Config.ShopMarkupMaxMultiplier - 1
				)

			markup_percent = math.min(
				markup_percent,
				max_markup_percent
			)

			new_state[class] = {
				state = "markup",
				percent = markup_percent
			}

			marked_up[class] = true
		end
	end

	for class, _ in pairs(DP.MarkupStreaks) do
		if not currently_marked_up[class] then
			DP.MarkupStreaks[class] = nil
		end
	end

	for _, item_type in ipairs(tab_types) do
		local eligible = {}

		for class, item in pairs(PS.Items) do
			if item.Type == item_type and not marked_up[class] then
				table.insert(eligible, class)
			end
		end

		local shuffled = ShuffledCopy(eligible)

		for i = 1, math.min(
			PS.Config.ShopDiscountPerTabCount,
			#shuffled
		) do

			local class = shuffled[i]

			new_state[class] = {
				state = "discount",
				percent = PS.Config.ShopDiscountPercent
			}
		end
	end

	DP.PriceState = new_state

	DP.PurchaseCounts = {}
	DP.PeriodStartTime = CurTime()

	PS.DynamicPricing.SyncPricingToAll()

	local markup_count, discount_count = 0, 0

	for _, state in pairs(new_state) do
		if state.state == "markup" then
			markup_count = markup_count + 1
		elseif state.state == "discount" then
			discount_count = discount_count + 1
		end
	end

	print(string.format(
		"[Pointshop] Dynamic pricing refreshed: %d item(s) marked up, %d item(s) discounted.",
		markup_count,
		discount_count
	))
end

local function BuildPricingPayload()
	local payload = {}

	for class, state in pairs(DP.PriceState) do
		table.insert(payload, {
			class = class,
			state = state.state,
			percent = state.percent
		})
	end

	return payload
end


local function WritePricingPayload(payload)
	net.WriteUInt(#payload, 16)

	for _, entry in ipairs(payload) do
		net.WriteString(entry.class)
		net.WriteString(entry.state)

		net.WriteUInt(
			math.floor(entry.percent * 1000 + 0.5),
			16
		)
	end
end

function PS.DynamicPricing.SyncPricingTo(ply)
	if not IsValid(ply) then return end

	local payload = BuildPricingPayload()

	net.Start("PS_Shop_SyncPricing")
		WritePricingPayload(payload)
	net.Send(ply)
end

function PS.DynamicPricing.SyncPricingToAll()
	local payload = BuildPricingPayload()

	net.Start("PS_Shop_SyncPricing")
		WritePricingPayload(payload)
	net.Broadcast()
end

hook.Add("PlayerInitialSpawn", "PS_DynamicPricing_SyncOnJoin", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			PS.DynamicPricing.SyncPricingTo(ply)
		end
	end)
end)

local function StartRefreshTimer()
	if not PS.Config.ShopRefreshInterval
		or PS.Config.ShopRefreshInterval <= 0 then

		ErrorNoHalt(
			"[Pointshop] PS.Config.ShopRefreshInterval is missing or invalid -- dynamic pricing timer NOT started.\n"
		)

		return
	end

	timer.Create(
		TIMER_NAME,
		PS.Config.ShopRefreshInterval,
		0,
		PS.DynamicPricing.RunRefresh
	)

	DP.PeriodStartTime = CurTime()

	print(string.format(
		"[Pointshop] Dynamic pricing refresh timer started (every %d seconds).",
		PS.Config.ShopRefreshInterval
	))
end


hook.Add("Initialize", "PS_DynamicPricing_StartTimer", function()
	StartRefreshTimer()
end)


timer.Simple(0, function()
	if not timer.Exists(TIMER_NAME) then
		StartRefreshTimer()
	end
end)


if not timer.Exists(TIMER_NAME) then
	StartRefreshTimer()
end