-- A lot of this was repurposed from a roleplay addon I was working on and so has very messy code. I don't expect you to have to edit anything here but please dm me if needed.
-- This script may or may not interfere with addons that modify player speed. This can be removed easily if needed.

if SERVER then
    AddCSLuaFile()
end

local PLAYER = FindMetaTable("Player")

if SERVER then

	hook.Add("Think", "RPGMovementHandler", function()

		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:IsPlayer() then continue end

			if not ply.SEF_BaseWalk then
				ply.SEF_BaseWalk = ply:GetWalkSpeed()
			end

			if not ply.SEF_BaseRun then
				ply.SEF_BaseRun = ply:GetRunSpeed()
			end

			local baseWalk = ply.SEF_BaseWalk
			local baseRun = ply.SEF_BaseRun

			local mult = 1

			if ply:HavePassive("CounterspellBuff") then
				mult = mult * 1.125
			end

			if ply:HaveEffect("sci_effect_slow") then
				mult = mult * 0.8
			end

			local wep = ply:GetActiveWeapon()

			if IsValid(wep)
			and wep:GetClass() == "faw_longbow"
			and wep.GetLoaded
			and wep:GetLoaded() then

				mult = mult * 0.25
			end

			ply:SetWalkSpeed(baseWalk * mult)
			ply:SetRunSpeed(baseRun * mult)
		end
	end)

	hook.Add("EntityTakeDamage", "PassiveDamageHandler", function(target, dmginfo)
		local attacker = dmginfo:GetAttacker()

		if not IsValid(attacker) or not attacker:IsPlayer() then return end

		local dmg = dmginfo:GetDamage()
		local dmgType = dmginfo:GetDamageType()

		local magicMult = 1.0
		local meleeMult = 1.0

		-- BLAST (DMG_BLAST)

		if attacker:HavePassive("HealbanePassive") then
			magicMult = magicMult * 1.07
		end

		if attacker:HavePassive("MagicLifesteal") then
			magicMult = magicMult * 1.06
		end

		if attacker:HavePassive("CounterspellPassive") then
			magicMult = magicMult * 1.05
		end

		-- WEAPON (DMG_SLASH / DMG_CLUB / DMG_GENERIC / DMG_BULLET)

		if attacker:HavePassive("WeaponLifesteal") then
			meleeMult = meleeMult * 1.06
		end

		if attacker:HavePassive("FuryTrancePassive") then
			meleeMult = meleeMult * 1.06
		end

		if bit.band(dmgType, DMG_BLAST) ~= 0 then
			dmg = dmg * magicMult
		end

		if bit.band(dmgType, DMG_SLASH) ~= 0
		or bit.band(dmgType, DMG_CLUB) ~= 0
		or bit.band(dmgType, DMG_BULLET) ~= 0
		or bit.band(dmgType, DMG_GENERIC) ~= 0 then
			dmg = dmg * meleeMult
		end

		dmginfo:SetDamage(dmg)
	end)

	function RecalculateMaxHealth(ply)
		local maxHP = 100

		for passiveName, passiveData in pairs(PassiveEffects) do
			if ply:HavePassive(passiveName) then
				maxHP = maxHP + (passiveData.MaxHealthBonus or 0)
			end
		end

		ply:SetMaxHealth(maxHP)

		--if ply:Health() > maxHP then
			--ply:SetHealth(maxHP)
		--end
	end

	function RecalculateRegeneration(ply)
		local passiveRegen = 0
		local oocRegen = 0

		for passiveName, passiveData in pairs(PassiveEffects) do
			if ply:HavePassive(passiveName) then
				passiveRegen = passiveRegen + (passiveData.PassiveRegen or 0)
				oocRegen = oocRegen + (passiveData.OutOfCombatRegen or 0)
			end
		end

		ply.PassiveRegenRate = passiveRegen
		ply.OutOfCombatRegenRate = oocRegen
	end

	hook.Add("EntityTakeDamage", "RPGTrackCombatTime", function(target, dmginfo)
		if not IsValid(target) or not target:IsPlayer() then return end

		target.LastDamagedTime = CurTime()
	end)

	timer.Create("RPGHealthRegeneration", 1, 0, function()

		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then continue end
			if not ply:Alive() then continue end

			local healAmount = ply.PassiveRegenRate or 0

			local lastDamaged = ply.LastDamagedTime or 0

			if CurTime() - lastDamaged >= 4 then
				healAmount = healAmount + (ply.OutOfCombatRegenRate or 0)
			end

			if healAmount <= 0 then continue end
			if ply:Health() >= ply:GetMaxHealth() then continue end

			-- Initialize accumulator
			ply.RegenBuffer = (ply.RegenBuffer or 0) + healAmount

			local wholeHeal = math.floor(ply.RegenBuffer)

			if wholeHeal > 0 then
				ply.RegenBuffer = ply.RegenBuffer - wholeHeal

				ply:SetHealth(math.min(
					ply:Health() + wholeHeal,
					ply:GetMaxHealth()
				))
			end
		end

	end)

	function RecalculateMaxArmor(ply)
		local maxArmor = 100

		for passiveName, passiveData in pairs(PassiveEffects) do
			if ply:HavePassive(passiveName) then
				maxArmor = maxArmor + (passiveData.MaxArmorBonus or 0)
			end
		end

		ply:SetMaxArmor(maxArmor)

		--if ply:Armor() > maxArmor then
			--ply:SetArmor(maxArmor)
		--end
	end

	function RecalculateArmorRegeneration(ply)
		local passiveRegen = 0
		local oocRegen = 0

		for passiveName, passiveData in pairs(PassiveEffects) do
			if ply:HavePassive(passiveName) then
				passiveRegen = passiveRegen + (passiveData.PassiveArmorRegen or 0)
				oocRegen = oocRegen + (passiveData.OutOfCombatArmorRegen or 0)
			end
		end

		ply.PassiveArmorRegenRate = passiveRegen
		ply.OutOfCombatArmorRegenRate = oocRegen
	end

	timer.Create("RPGArmorRegeneration", 1, 0, function()

		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then continue end
			if not ply:Alive() then continue end

			local armorRegen = ply.PassiveArmorRegenRate or 0

			local lastDamaged = ply.LastDamagedTime or 0

			if CurTime() - lastDamaged >= 4 then
				armorRegen = armorRegen + (ply.OutOfCombatArmorRegenRate or 0)
			end

			if armorRegen <= 0 then continue end
			if ply:Armor() >= ply:GetMaxArmor() then continue end

			-- Initialize accumulator
			ply.ArmorRegenBuffer = (ply.ArmorRegenBuffer or 0) + armorRegen

			local wholeRegen = math.floor(ply.ArmorRegenBuffer)

			if wholeRegen > 0 then
				ply.ArmorRegenBuffer = ply.ArmorRegenBuffer - wholeRegen

				ply:SetArmor(math.min(
					ply:Armor() + wholeRegen,
					ply:GetMaxArmor()
				))
			end
		end

	end)

	function RefreshPlayerStats(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		RecalculateMaxHealth(ply)
		RecalculateRegeneration(ply)

		RecalculateMaxArmor(ply)
		RecalculateArmorRegeneration(ply)

		ply.LastDamagedTime = CurTime()
		ply.RegenBuffer = 0
		ply.ArmorRegenBuffer = 0
	end

	hook.Add("PlayerSpawn", "RPGRecalculatePlayerStats", function(ply)

		timer.Simple(0, function()
			if not IsValid(ply) then return end

			RefreshPlayerStats(ply)

			ply:SetHealth(ply:GetMaxHealth())
			ply:SetArmor(ply:GetMaxArmor())
		end)

	end)

-- Remove passives on death.

	hook.Add("PlayerDeath", "RPGRemovePassivesOnDeath", function(ply)
		if not IsValid(ply) then return end

		timer.Simple(0.1, function()
			if not IsValid(ply) then return end

			for passiveName, _ in pairs(EntActivePassives[ply] or {}) do
				ply:RemovePassive(passiveName)
			end
		end)
	end)


end

PassiveEffects.Sprintboots = {
    Icon = "hudicons/item_1_vitality_sprintboots.png",
    Desc = "Grants extra movespeed and HP regen.",
    MaxHealthBonus = 5,
    OutOfCombatRegen = 0.2
}

PassiveEffects.sci_passive_lifeinsurance = {
    Name = "Life Insurance",
    Icon = "hudicons/sci_passive_lifeinsurance.png",
    Desc = "Prevents point loss on death.",
}

PassiveEffects.sci_passive_luckyfive = {
    Name = "Lucky Five",
    Icon = "hudicons/sci_passive_luckyfive.png",
    Desc = "25% chance to not lose points on death.",
}

PassiveEffects.sci_passive_payday = {
    Name = "Payday",
    Icon = "hudicons/sci_passive_payday.png",
    Desc = "Point gain increased by 25%.",
}

PassiveEffects.sci_passive_doubledown = {
    Name = "Double Down",
    Icon = "hudicons/sci_passive_doubledown.png",
    Desc = "Point gain and loss is doubled.",
}

PassiveEffects.sci_passive_extrahealth = {
    Name = "Extra Health",
    Icon = "hudicons/sci_passive_extrahealth.png",
    Desc = "+25 max HP.",
    MaxHealthBonus = 25,
}

PassiveEffects.sci_passive_regeneration = {
    Name = "Regeneration",
    Icon = "hudicons/sci_passive_regeneration.png",
    Desc = "Passive HP regeneration.",
    PassiveRegen = 1,
    OutOfCombatRegen = 2.5
}

PassiveEffects.sci_passive_extraarmor = {
    Name = "Extra Armor",
    Icon = "hudicons/sci_passive_extraarmor.png",
    Desc = "+25 max Armor",
    MaxArmorBonus = 25,
}

PassiveEffects.sci_passive_armorregeneration = {
    Name = "Armor Regeneration",
    Icon = "hudicons/sci_passive_armorregeneration.png",
    Desc = "Passive Armor regeneration.",
    PassiveArmorRegen = 1,
    OutOfCombatArmorRegen = 2.5
}

PassiveEffects.sci_passive_lifesteal = {
    Name = "Lifesteal",
    Icon = "hudicons/sci_passive_lifesteal.png",
    Desc = "Dealing bullet damage heals you.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_lifesteal") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_BULLET) then
                    return
                end

                if attacker == target then
                    return
                end

                if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then

                    local heal = math.min(dmginfo:GetDamage() * 0.15, 15)

                    timer.Simple(0, function()

                        if not IsValid(attacker) then return end

                        attacker:SetHealth(math.min(
                            attacker:Health() + heal,
                            attacker:GetMaxHealth()
                        ))

                    end)
                end
            end
        }
    }
}

PassiveEffects.sci_passive_concussion = {
    Name = "Concussion",
    Icon = "hudicons/sci_passive_concussion.png",
    Desc = "Your explosive weapons apply Concussion to targets.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_concussion") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_BLAST) then
                    return
                end

                if not IsValid(target) or not (target:IsPlayer() or target:IsNPC()) then
                    return
                end

                local duration = math.Clamp(dmginfo:GetDamage() / 10, 3, 8)

                target:ApplyEffect("Concussion", duration)
            end
        }
    }
}

PassiveEffects.sci_passive_backstabber = {
    Name = "Backstabber",
    Icon = "hudicons/sci_passive_backstabber.png",
    Desc = "Melee attacks from behind deal lethal damage.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_backstabber") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_SLASH)
                and not dmginfo:IsDamageType(DMG_CLUB) then
                    return
                end

                if not IsValid(target) then
                    return
                end

                local targetForward = target:GetForward()
                local directionToAttacker = (attacker:GetPos() - target:GetPos()):GetNormalized()

                local dot = targetForward:Dot(directionToAttacker)

                if dot < 0 then
                    dmginfo:ScaleDamage(10)
                end
            end
        }
    }
}

PassiveEffects.sci_passive_flashbang = {
    Name = "Flashbang",
    Icon = "hudicons/sci_passive_flashbang.png",
    Desc = "Blast damage blinds targets instead of dealing damage.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_flashbang") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_BLAST) then
                    return
                end

                if not IsValid(target)
                or not (target:IsPlayer() or target:IsNPC()) then
                    return
                end

                local explosionPos = dmginfo:GetDamagePosition()

                if explosionPos == vector_origin then
                    explosionPos = target:WorldSpaceCenter()
                end

                dmginfo:SetDamage(5)

                -- Maximum distance at which the flashbang has an effect.
                local BLINDNESS_MAX_DISTANCE = 500

                local targetPos = target:WorldSpaceCenter()
                local distance = targetPos:Distance(explosionPos)

                local distanceFactor = math.Clamp(
                    1 - (distance / BLINDNESS_MAX_DISTANCE),
                    0,
                    1
                )

                local screenFactor = 1

                if target:IsPlayer() then
                    local eyePos = target:EyePos()
                    local eyeForward = target:EyeAngles():Forward()

                    local directionToExplosion =
                        (explosionPos - eyePos):GetNormalized()

                    local dot = eyeForward:Dot(directionToExplosion)

                    screenFactor = math.Clamp(dot, 0, 1)
                end

                local intensity = distanceFactor * screenFactor

                local duration = math.Clamp(
                    1 + (4 * intensity),
                    1,
                    5
                )

                target:ApplyEffect("Blindness", duration)
            end
        }
    }
}

PassiveEffects.sci_passive_pyromaniac = {
    Name = "Pyromaniac",
    Icon = "hudicons/sci_passive_pyromaniac.png",
    Desc = "+90% Fire damage resistance.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                if not IsValid(target)
                or not target:IsPlayer()
                or not target:HavePassive("sci_passive_pyromaniac") then
                    return
                end

                if dmginfo:IsDamageType(DMG_BURN)
                or dmginfo:IsDamageType(DMG_SLOWBURN) then
                    dmginfo:ScaleDamage(0.1)
                end
            end
        }
    }
}

PassiveEffects.sci_passive_blastshield = {
    Name = "Blast Shield",
    Icon = "hudicons/sci_passive_blastshield.png",
    Desc = "+50% Explosive damage resistance.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                if not IsValid(target)
                or not target:IsPlayer()
                or not target:HavePassive("sci_passive_blastshield") then
                    return
                end

                if dmginfo:IsDamageType(DMG_BLAST) then
                    dmginfo:ScaleDamage(0.5)
                end
            end
        }
    }
}

PassiveEffects.sci_passive_fleetfoot = {
    Name = "Fleetfoot",
    Icon = "hudicons/sci_passive_fleetfoot.png",
    Desc = "Immune to fall damage.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                if not IsValid(target)
                or not target:IsPlayer()
                or not target:HavePassive("sci_passive_fleetfoot") then
                    return
                end

                if dmginfo:IsDamageType(DMG_FALL) then
                    dmginfo:SetDamage(0)
                end
            end
        }
    }
}

PassiveEffects.sci_passive_healingbooster = {
    Name = "Healing Booster",
    Icon = "hudicons/sci_passive_healingbooster.png",
    Desc = "Healing received is increased by 20%.",
    ServerHooks = {
        {
            HookType = "Think",
            HookFunction = function()
                for _, ent in ipairs(player.GetAll()) do
                    if not ent:HavePassive("sci_passive_healingbooster") then continue end

                    local currentHP = ent:Health()
                    local currentArmor = ent:Armor()

                    local lastHP = ent.HealingBoosterLastHP or currentHP
                    local lastArmor = ent.HealingBoosterLastArmor or currentArmor

                    local hpDelta = currentHP - lastHP
                    local armorDelta = currentArmor - lastArmor

                    if hpDelta > 0 then
                        local bonus = math.Round(hpDelta * 0.20)

                        ent:SetHealth(math.min(
                            currentHP + bonus,
                            ent:GetMaxHealth()
                        ))

                        currentHP = ent:Health()
                    end

                    if armorDelta > 0 then
                        local bonus = math.Round(armorDelta * 0.20)

                        ent:SetArmor(math.min(
                            currentArmor + bonus,
                            100
                        ))

                        currentArmor = ent:Armor()
                    end

                    ent.HealingBoosterLastHP = currentHP
                    ent.HealingBoosterLastArmor = currentArmor
                end
            end
        }
    }
}

PassiveEffects.sci_passive_bleed = {
    Name = "Bleed",
    Icon = "hudicons/sci_passive_bleed.png",
    Desc = "Small chance to make target bleed when shot.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_bleed") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_BULLET) then
                    return
                end

                if attacker == target then
                    return
                end

                if not IsValid(target)
                or not (target:IsPlayer() or target:IsNPC()) then
                    return
                end

                -- 10% chance to apply Bleed
                if math.random(1, 100) <= 10 then
					local bleedDamage = target:Health() * 0.02
					target:ApplyEffect("Bleeding", 10, bleedDamage, 1, attacker)
                end
            end
        }
    }
}

StatusEffects.sci_effect_slow = { 
    Name = "Slowed",
    Icon = "sef_icons/hindered.png",
    Desc = "Movement speed reduced.",
    Type = "DEBUFF",
}

PassiveEffects.sci_passive_slowdown = {
    Name = "Slowdown",
    Icon = "hudicons/sci_passive_slowdown.png",
    Desc = "Targets are briefly slowed on hit.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_slowdown") then
                    return
                end

                if not dmginfo:IsDamageType(DMG_BULLET) then
                    return
                end

                if attacker == target then
                    return
                end

                if not IsValid(target)
                or not (target:IsPlayer() or target:IsNPC()) then
                    return
                end

                target:ApplyEffect("sci_effect_slow", 2.5)
            end
        }
    }
}

StatusEffects.sci_effect_vulnerability = {
        Icon = "SEF_Icons/vuln.png",
        Name = "Debuff Vulnerability",
        Desc = "Debuffs last twice as long.",
        Type = "DEBUFF",
        EffectBegin = function(ent)
        end,
        Effect = function(ent, time)
            for effectName, effectData in pairs(EntActiveEffects[ent]) do
                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.DebuffVulnAffected and StatusEffects[effectName].Name ~= "Debuff Vulnerability" then
                    local NewDuration = EntActiveEffects[ent][effectName].Duration * 2
                    ent:ChangeDuration(effectName, NewDuration)
                    effectData.DebuffVulnAffected = true
                end
            end
        end,
        EffectEnd = function(ent)
        end,
}

PassiveEffects.sci_passive_vulnerability = {
    Name = "Vulnerability",
    Icon = "hudicons/sci_passive_vulnerability.png",
    Desc = "Debuffs applied on target last twice as long.",
    ServerHooks = {
        {
            HookType = "EntityTakeDamage",
            HookFunction = function(target, dmginfo)

                local attacker = dmginfo:GetAttacker()

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_vulnerability") then
                    return
                end

                if attacker == target then
                    return
                end

                if not IsValid(target)
                or not (target:IsPlayer() or target:IsNPC()) then
                    return
                end

                target:ApplyEffect("sci_effect_vulnerability", 2)
            end
        }
    }
}

PassiveEffects.sci_passive_unstoppable = {
    Name = "Unstoppable",
    Icon = "hudicons/sci_passive_unstoppable.png",
    Desc = "Immune to debuffs.",
    ServerHooks = {
        {
            HookType = "Think",
            HookFunction = function()
                for _, ent in ipairs(player.GetAll()) do
                    if not ent:HavePassive("sci_passive_unstoppable") then
                        continue
                    end

                    if not EntActiveEffects[ent] then
                        continue
                    end

                    for effectName, _ in pairs(EntActiveEffects[ent]) do
                        local effectData = StatusEffects[effectName]

                        if effectData and effectData.Type == "DEBUFF" then
                            ent:RemoveEffect(effectName)
                        end
                    end
                end
            end
        }
    }
}

PassiveEffects.sci_passive_splitshot = {
    Name = "Splitshot",
    Icon = "hudicons/sci_passive_splitshot.png",
    Desc = "Each bullet deals +2 damage.",
    ServerHooks = {
        {
            HookType = "EntityFireBullets",
            HookFunction = function(attacker, bullet)

                if not IsValid(attacker)
                or not attacker:IsPlayer()
                or not attacker:HavePassive("sci_passive_splitshot") then
                    return
                end

                bullet.Damage = bullet.Damage + 2

                return true
            end
        }
    }
}
