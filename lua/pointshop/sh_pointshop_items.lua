--[[
Config file for the shop.

!!!!!!!!!!!!!HEAD DOWN to the Item Catalog section to edit the buyable items.

	Format:
		PS.Items = {
			buyable_class = {
				Name      = "Display Name",       -- optional, defaults to buyable_class
				BasePrice = 1000,                 -- cost in points
				Type      = "entity"/"weapon"/"bonus",
				BonusType = "Survivability"/"Offensive"/"Special", -- only used when Type = "bonus"; defaults to "Survivability" if omitted
				Icon      = "icon16/something.png", -- optional, shown on the shop button
				Description = "text here",       -- optional, shown as a tooltip
			},
			...
		}

	Type determines both which tab the item appears under and what happens when it's purchased.
		"entity" -> spawned in front of the player
		"weapon" -> given directly to the player
		"bonus"  -> applied via player:ApplyPassive(buyable_class)

	BonusType (bonus items only) determines which of the 3 side-by-side categories a passive appears under on the Bonuses tab.
	A player may only have one active passive per BonusType at a time.
]]

PS = PS or {}
PS.Items = PS.Items or {}

PS.ITEM_TYPE_ENTITY = "entity"
PS.ITEM_TYPE_WEAPON = "weapon"
PS.ITEM_TYPE_BONUS  = "bonus"

local VALID_TYPES = {
	[PS.ITEM_TYPE_ENTITY] = true,
	[PS.ITEM_TYPE_WEAPON] = true,
	[PS.ITEM_TYPE_BONUS]  = true,
}

function PS.IsValidItemType(t)
	return VALID_TYPES[t] == true
end

PS.Config = PS.Config or {}

PS.BONUS_TYPE_SURVIVABILITY = "Survivability"
PS.BONUS_TYPE_OFFENSIVE     = "Offensive"
PS.BONUS_TYPE_SPECIAL       = "Special"

PS.BONUS_TYPE_DEFAULT = PS.BONUS_TYPE_SURVIVABILITY

PS.BONUS_TYPE_ORDER = {
	PS.BONUS_TYPE_SURVIVABILITY,
	PS.BONUS_TYPE_OFFENSIVE,
	PS.BONUS_TYPE_SPECIAL,
}

local VALID_BONUS_TYPES = {
	[PS.BONUS_TYPE_SURVIVABILITY] = true,
	[PS.BONUS_TYPE_OFFENSIVE]     = true,
	[PS.BONUS_TYPE_SPECIAL]       = true,
}

function PS.IsValidBonusType(t)
	return VALID_BONUS_TYPES[t] == true
end

function PS.GetItemBonusType(item)
	if item and PS.IsValidBonusType(item.BonusType) then
		return item.BonusType
	end
	return PS.BONUS_TYPE_DEFAULT
end

------------------------------------------------- Item Catalog -------------------------------------------------

PS.Items = {

	---------------- Entities ----------------
	["sci_pointshop_beacon"] = {
		Name = "Beacon",
		BasePrice = 7500,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "sef_icons/fallimmune.png",
		Description = "Grants positive status effects to players in proximity. Can be customized.",
	},
	["gb5_proj_howitzer_shell_in"] = {
		Name = "Howitzer Shell (Incendiary)",
		BasePrice = 1250,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "icon16/bomb.png",
		Description = "Incendiary shell, sets things on fire.",
	},
	["gb5_proj_howitzer_shell_cl"] = {
		Name = "Chlorine Shell",
		BasePrice = 1750,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "icon16/bomb.png",
		Description = "Chlorine gas shell, leaves a cloud of gas that blinds and damages players inside. Ignores armor.",
	},
	["gb5_nuclear_davycrockett"] = {
		Name = "Davy Crockett",
		BasePrice = 10000,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "icon16/bomb.png",
		Description = "Miniature nuclear artillery shell with a devastating blast.",
	},
	---------------- Weapons ----------------
	["m9k_minigun"] = {
		Name = "M134 Minigun",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_minigun.png",
		Description = "Handheld minigun with extremely fast firerate and high ammo capacity.",
	},
	["m9k_usas"] = {
		Name = "USAS",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_usas.png",
		Description = "Full auto shotgun with a 20 round drum mag. Has mediocre firerate but a fast reload.",
	},
	["m9k_striker12"] = {
		Name = "Striker 12",
		BasePrice = 450,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_striker12.png",
		Description = "Full auto shotgun with a 12 round drum mag. Has a fast firerate but a slow reload.",
	},
	["m9k_davy_crockett"] = {
		Name = "Davy Crockett",
		BasePrice = 100000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_davy_crockett.png",
		Description = "Recoilless tactical nuke launcher.",
	},
	["m9k_ex41"] = {
		Name = "EX41",
		BasePrice = 1200,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_ex41.png",
		Description = "Pump-action grenade launcher. Has a 3-round tubular magazine.",
	},
	["m9k_m202"] = {
		Name = "M202",
		BasePrice = 5000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_m202.png",
		Description = "Multishot explosive rocket launcher.",
	},
	["m9k_matador"] = {
		Name = "Matador",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_matador.png",
		Description = "Single shot rocket launcher.",
	},
	["m9k_milkormgl"] = {
		Name = "Milkor Mk1",
		BasePrice = 1750,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_milkormgl.png",
		Description = "Six-shot revolver-type grenade launcher.",
	},
	["m9k_nerve_gas"] = {
		Name = "Nerve Gas",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_nerve_gas.png",
		Description = "Hand thrown capsule that releases a powerful nerve agent upon breaking.",
	},
	["m9k_orbital_strike"] = {
		Name = "Orbital Strike Marker",
		BasePrice = 10000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_orbital_strike.png",
		Description = "Mark a location on the map to be bombed by an orbtal strike system.",
	},
	["m9k_proxy_mine"] = {
		Name = "Proximity Mine",
		BasePrice = 125,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_proxy_mine.png",
		Description = "Can be attached to surfaces. Explodes when a valid target comes into proximity.",
	},
	---------------- Bonuses (passive effects) ----------------
	["sci_passive_lifeinsurance"] = {
		Name = "Life Insurance",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_lifeinsurance.png",
		Description = "Negates point loss on death.",
	},
	["sci_passive_luckyfive"] = {
		Name = "Lucky Five",
		BasePrice = 200,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_luckyfive.png",
		Description = "25% chance to negate point loss on death.",
	},
	["sci_passive_payday"] = {
		Name = "Payday",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_payday.png",
		Description = "Point gain increased by 25%.",
	},
	["sci_passive_doubledown"] = {
		Name = "Double Down",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_doubledown.png",
		Description = "Earn 2x points, but lose 2x points on death.",
	},
	["sci_passive_vulnerability"] = {
		Name = "Vulnerability",
		BasePrice = 475,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_vulnerability.png",
		Description = "Debuffs applied on target last twice as long.",
	},
	["sci_passive_extrahealth"] = {
		Name = "Extra Health",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_extrahealth.png",
		Description = "+25 max HP.",
	},
	["sci_passive_regeneration"] = {
		Name = "Regeneration",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_regeneration.png",
		Description = "Passive HP regeneration.",
	},
	["sci_passive_extraarmor"] = {
		Name = "Extra Armor",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_extraarmor.png",
		Description = "+25 max Armor",
	},
	["sci_passive_armorregeneration"] = {
		Name = "Armor Regeneration",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_armorregeneration.png",
		Description = "Passive Armor regeneration.",
	},
	["sci_passive_lifesteal"] = {
		Name = "Lifesteal",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_lifesteal.png",
		Description = "Dealing bullet damage heals you.",
	},
	["sci_passive_pyromaniac"] = {
		Name = "Pyromaniac",
		BasePrice = 300,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_pyromaniac.png",
		Description = "+90% Fire damage resistance.",
	},
	["sci_passive_blastshield"] = {
		Name = "Blast Shield",
		BasePrice = 425,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_blastshield.png",
		Description = "+50% Explosive damage resistance.",
	},
	["sci_passive_fleetfoot"] = {
		Name = "Fleetfoot",
		BasePrice = 225,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_fleetfoot.png",
		Description = "Immune to fall damage.",
	},
	["sci_passive_healingbooster"] = {
		Name = "Healing Booster",
		BasePrice = 450,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_healingbooster.png",
		Description = "Healing received is increased by 20%.",
	},
	["sci_passive_unstoppable"] = {
		Name = "Unstoppable",
		BasePrice = 275,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_unstoppable.png",
		Description = "Immune to debuffs.",
	},
	["sci_passive_concussion"] = {
		Name = "Concussion",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_concussion.png",
		Description = "Your explosive weapons apply Concussion to targets.",
	},
	["sci_passive_backstabber"] = {
		Name = "Backstabber",
		BasePrice = 450,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_backstabber.png",
		Description = "Melee attacks from behind deal lethal damage.",
	},
	["sci_passive_flashbang"] = {
		Name = "Flashbang",
		BasePrice = 800,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_flashbang.png",
		Description = "Blast damage blinds targets instead of dealing damage.",
	},
	["sci_passive_bleed"] = {
		Name = "Bleed",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_bleed.png",
		Description = "Small chance to make target bleed when shot.",
	},
}


--[[
BONUS_TYPE_SURVIVABILITY
BONUS_TYPE_OFFENSIVE
BONUS_TYPE_SPECIAL

Surv: sci_passive_extrahealth, sci_passive_regeneration, sci_passive_extraarmor, sci_passive_armorregeneration, sci_passive_lifesteal, sci_passive_pyromaniac, sci_passive_blastshield, sci_passive_fleetfoot, sci_passive_healingbooster, sci_passive_unstoppable

Off: sci_passive_concussion, sci_passive_backstabber, sci_passive_flashbang, sci_passive_bleed, sci_passive_slowdown, sci_passive_vulnerability, 

Special: sci_passive_lifeinsurance, sci_passive_luckyfive, sci_passive_payday, sci_passive_doubledown,
]]--

-- Helpers

function PS.GetItemDisplayName(buyable_class)
	local item = PS.Items[buyable_class]
	if not item then return buyable_class end
	return item.Name or buyable_class
end

function PS.GetItemsByType(item_type)
	local results = {}
	for class, data in pairs(PS.Items) do
		if data.Type == item_type then
			table.insert(results, { class = class, data = data })
		end
	end
	return results
end

function PS.GetBonusItemsByCategory()
	local grouped = {}
	for _, bonus_type in ipairs(PS.BONUS_TYPE_ORDER) do
		grouped[bonus_type] = {}
	end

	for class, data in pairs(PS.Items) do
		if data.Type == PS.ITEM_TYPE_BONUS then
			local bonus_type = PS.GetItemBonusType(data)
			table.insert(grouped[bonus_type], { class = class, data = data })
		end
	end

	return grouped
end
