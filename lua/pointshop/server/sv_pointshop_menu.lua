-- Handler for shop purchases
PS = PS or {}
PS.Shop = PS.Shop or {}

if not PS.Items then
	ErrorNoHalt("[Pointshop] sv_pointshop_menu.lua loaded before PS.Items was defined -- check load order.\n")
end

util.AddNetworkString("PS_Shop_Purchase")
util.AddNetworkString("PS_Shop_PurchaseResult") -- server -> client: success/failure + message
util.AddNetworkString("PS_Shop_SyncActiveBonuses") -- server -> client: list of the player's currently-active bonus buyable_classes
util.AddNetworkString("PS_Shop_RequestSync") -- client -> server

-- antispam just in case
local PURCHASE_COOLDOWN = 0.25
local last_purchase_time = {}

local function SendResult(ply, success, message)
	net.Start("PS_Shop_PurchaseResult")
		net.WriteBool(success)
		net.WriteString(message or "")
	net.Send(ply)
end


function PS.Shop.SyncActiveBonuses(ply)
	if not IsValid(ply) then return end

	local active_classes = {}
	local active = EntActivePassives and EntActivePassives[ply]
	if active then
		for passive_name, _ in pairs(active) do
			local item = PS.Items[passive_name]
			if item and item.Type == PS.ITEM_TYPE_BONUS then
				table.insert(active_classes, passive_name)
			end
		end
	end

	net.Start("PS_Shop_SyncActiveBonuses")
		net.WriteUInt(#active_classes, 8)
		for _, class in ipairs(active_classes) do
			net.WriteString(class)
		end
	net.Send(ply)
end

-- Delivery
-- Spawns entity on the ground in front of the player, using a trace so it doesn't spawn inside geometry. Returns the spawned entity, or nil if it failed to create.
local function SpawnEntityInFront(ply, class)
	local eye_pos = ply:EyePos()
	local eye_dir = ply:EyeAngles():Forward()

	local trace = util.TraceLine({
		start = eye_pos,
		endpos = eye_pos + eye_dir * 100,
		filter = ply,
		mask = MASK_SOLID,
	})

	local spawn_pos = trace.HitPos
	spawn_pos = spawn_pos + trace.HitNormal * 8

	local ent = ents.Create(class)
	if not IsValid(ent) then return nil end

	ent:SetPos(spawn_pos)
	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:Spawn()
	ent:Activate()

	if ent.SetCreator then
		ent:SetCreator(ply)
	end

	if undo then
		undo.Create(PS.GetItemDisplayName and PS.GetItemDisplayName(class) or class)
		undo.SetPlayer(ply)
		undo.AddEntity(ent)
		undo.Finish()
	end

	if ply.AddCleanup then
		ply:AddCleanup("props", ent)
	end

	return ent
end

local function GetActiveBonusInCategory(ply, bonus_type)
	local active = EntActivePassives and EntActivePassives[ply]
	if not active then return nil end

	for passive_name, _ in pairs(active) do
		local item = PS.Items[passive_name]
		if item and item.Type == PS.ITEM_TYPE_BONUS and PS.GetItemBonusType(item) == bonus_type then
			return passive_name
		end
	end
	return nil
end

function PS.Shop.DeliverItem(ply, buyable_class, item)
	if item.Type == PS.ITEM_TYPE_ENTITY then
		local ent = SpawnEntityInFront(ply, buyable_class)
		if not IsValid(ent) then
			return false, "Failed to spawn entity."
		end
		return true

	elseif item.Type == PS.ITEM_TYPE_WEAPON then
		local given = ply:Give(buyable_class)
		if not IsValid(given) then
			return false, "Failed to give weapon."
		end
		return true

	elseif item.Type == PS.ITEM_TYPE_BONUS then
		if not ply.ApplyPassive then
			return false, "Failed to give bonus."
		end

		local bonus_type = PS.GetItemBonusType(item)

		-- A player may only have one active passive per category at a time. If they already have a different passive in this same category, swap it out for the newly purchased one.
		local existing = GetActiveBonusInCategory(ply, bonus_type)
		if existing and existing ~= buyable_class and ply.RemovePassive then
			ply:RemovePassive(existing)
		end

		ply:ApplyPassive(buyable_class)

		if RefreshPlayerStats then
			RefreshPlayerStats(ply)
		end

		return true
	end

	return false, "Unknown item type."
end

net.Receive("PS_Shop_Purchase", function(len, ply)
	if not IsValid(ply) then return end

	local buyable_class = net.ReadString()

	if not PS.Items or not PS.Core or not PS.Core.GetPoints or not PS.Core.TakePoints then
		SendResult(ply, false, "Shop is not fully initialized on the server. Contact an admin.")
		return
	end

	local now = CurTime()
	local last = last_purchase_time[ply] or 0
	if now - last < PURCHASE_COOLDOWN then
		return
	end
	last_purchase_time[ply] = now

	local item = PS.Items[buyable_class]
	if not item then
		SendResult(ply, false, "That item doesn't exist.")
		return
	end

	if not PS.IsValidItemType(item.Type) then
		SendResult(ply, false, "This item is misconfigured (invalid type).")
		return
	end

	local price
	if PS.DynamicPricing and PS.DynamicPricing.GetEffectivePrice then
		price = PS.DynamicPricing.GetEffectivePrice(buyable_class)
	else
		price = tonumber(item.BasePrice)
	end
	price = math.floor(tonumber(price) or -1)
	if not price or price < 0 then
		SendResult(ply, false, "This item is misconfigured (invalid price).")
		return
	end

	local current_points = PS.Core.GetPoints(ply)
	if current_points < price then
		SendResult(ply, false, "You don't have enough points for that.")
		return
	end

	if item.Type == PS.ITEM_TYPE_BONUS and EntActivePassives and EntActivePassives[ply] then
		if EntActivePassives[ply][buyable_class] then
			SendResult(ply, false, "You already have that bonus active.")
			return
		end
	end


	local removed = PS.Core.TakePoints(ply, price, "shop_purchase")

	local delivered, err = PS.Shop.DeliverItem(ply, buyable_class, item)

	if not delivered then
		if PS.Core.AddPoints then
			PS.Core.AddPoints(ply, removed, "shop_refund")
		end
		SendResult(ply, false, err or "Purchase failed.")
		return
	end

	local display_name = PS.GetItemDisplayName and PS.GetItemDisplayName(buyable_class) or buyable_class
	local formatted_price = PS.FormatNumber and PS.FormatNumber(price) or tostring(price)
	SendResult(ply, true, string.format("Purchased %s for %s points.", display_name, formatted_price))

	hook.Run("PS_ItemPurchased", ply, buyable_class, item)

	if item.Type == PS.ITEM_TYPE_BONUS then
		PS.Shop.SyncActiveBonuses(ply)
	end
end)

hook.Add("PlayerDisconnected", "PS_Shop_CleanupRateLimit", function(ply)
	last_purchase_time[ply] = nil
end)

hook.Add("PlayerSpawn", "PS_Shop_SyncActiveBonusesOnSpawn", function(ply)
	timer.Simple(0.5, function()
		if IsValid(ply) then
			PS.Shop.SyncActiveBonuses(ply)
		end
	end)
end)

net.Receive("PS_Shop_RequestSync", function(len, ply)
	if IsValid(ply) then
		PS.Shop.SyncActiveBonuses(ply)
	end
end)