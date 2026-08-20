-- this is just the beacon craftable from Erythurgy but turned into a standalone entity.
-- excuse the very ghetto code as i had to remove a lot of functionality that relied on the erythurgy API.

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Beacon"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "sef_icons/fallimmune.png"
ENT.IconOffset = Vector(0, 0, 60)

ENT.BaseModel = "models/props_combine/combine_mine01.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 7500
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

if SERVER then
    util.AddNetworkString("ery_beacon_open")
    util.AddNetworkString("ery_beacon_set")
    util.AddNetworkString("ery_beacon_toggle")
end

-- Beacon effects

local BeaconEffects = {
    Healing = {
        display = "Health Regeneration",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Healing", multiplier, 1 * level, 1)
            end
        end
    },

    Endurance = {
        display = "Damage Resistance",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Endurance", multiplier, 10 * level)
            end
        end
    },

    Energized = {
        display = "Armor Regeneration",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Energized", multiplier, 1 * level, 1)
            end
        end
    },

    Tenacity = {
        display = "Debuff Resistance",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Tenacity", multiplier, 33 * level + 1)
            end
        end
    },

    DamageUp = {
        display = "Damage Boost",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("DamageUp", multiplier, 15 * level + 1)
            end
        end
    },
}

local BeaconEffectNames = {}

for effectName, _ in pairs(BeaconEffects) do
    table.insert(BeaconEffectNames, effectName)
end

table.sort(BeaconEffectNames)

ENT.BeaconEffect = "Healing"
ENT.BeaconIntensity = 1
ENT.Active = false
ENT.MaxHealth = 500

ENT.CollideSounds = {
    "physics/metal/metal_barrel_impact_hard1.wav",
    "physics/metal/metal_barrel_impact_hard2.wav",
    "physics/metal/metal_barrel_impact_hard3.wav",
    "physics/metal/metal_barrel_impact_hard5.wav",
    "physics/metal/metal_barrel_impact_hard6.wav",
    "physics/metal/metal_barrel_impact_hard7.wav"
}

-- Server

if SERVER then

    local PulseInterval = 5

    local EffectMultiplier = 7

    local IntensitySettings = {
        [1] = {
            range = 2000,
            mult = 1
        },

        [2] = {
            range = 1000,
            mult = 2
        },

        [3] = {
            range = 500,
            mult = 3
        }
    }

    function ENT:Initialize()

        self:SetModel(
            self.BaseModel
            or "models/hunter/blocks/cube025x025x025.mdl"
        )

        self:SetMaterial(
            self.BaseMaterial
            or "hunter/myplastic"
        )

        self:SetColor(
            self.BaseColor
            or Color(255, 255, 255, 255)
        )

        self:ManipulateBoneScale(
            0,
            self.BoneScale or Vector(1, 1, 1)
        )

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()

        timer.Simple(0.01, function()
            if not IsValid(self) then return end
            if not IsValid(phys) then return end

            phys:SetMass(self.CustomMass or 5)
            phys:Wake()
        end)

        self.CollideSounds = self.CollideSounds or {}

        self:SetNW2String(
            "BeaconEffect",
            self.BeaconEffect
        )

        self:SetNW2Int(
            "BeaconIntensity",
            self.BeaconIntensity
        )

        self:SetNW2Bool(
            "Active",
            self.Active
        )

		self:SetHealth(self.MaxHealth)
		self:SetNW2Int("BeaconHealth", self.MaxHealth)

        self.NextPulse = CurTime() + PulseInterval
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        net.Start("ery_beacon_open")
            net.WriteEntity(self)
            net.WriteString(
                self.BeaconEffect
                or BeaconEffectNames[1]
            )
            net.WriteUInt(
                self.BeaconIntensity or 1,
                4
            )
            net.WriteBool(
                self.Active or false
            )
        net.Send(ply)
    end

    function ENT:PhysicsCollide(data, phys)

        if data.DeltaTime <= 0.2 then return end
        if data.Speed <= 50 then return end

        local sounds = self.CollideSounds or {
            "player/footsteps/gravel1.wav",
            "player/footsteps/gravel2.wav",
            "player/footsteps/gravel3.wav",
            "player/footsteps/gravel4.wav"
        }

        self:EmitSound(
            sounds[math.random(#sounds)],
            90,
            math.random(90, 110)
        )
    end

	function ENT:OnTakeDamage(dmgInfo)

		if not IsValid(self) then return end

		local damage = dmgInfo:GetDamage()

		if damage <= 0 then return end

		local currentHealth = self:Health()
		local newHealth = math.max(currentHealth - damage, 0)

		self:SetHealth(newHealth)
		self:SetNW2Int("BeaconHealth", newHealth)

		if newHealth <= 0 then

			local effectData = EffectData()
			effectData:SetOrigin(self:GetPos())

			util.Effect(
				"ManhackSparks",
				effectData,
				true,
				true
			)

			self:Remove()
		end
	end

    function ENT:ToggleActive()

        self.Active = not self.Active

        self:SetNW2Bool(
            "Active",
            self.Active
        )

        if self.Active then

            self:EmitSound(
                "ambient/machines/air_conditioner_cycle.wav",
                80,
                100
            )

            local timerName =
                "BeaconLoop_" .. self:EntIndex()

            timer.Create(
                timerName,
                2.7,
                0,
                function()

                    if not IsValid(self) or not self.Active then
                        timer.Remove(timerName)
                        return
                    end

                    self:EmitSound(
                        "ery_sound/erymachines/machinerydrone02.wav",
                        60,
                        100
                    )
                end
            )

        else

            self:EmitSound(
                "ambient/machines/spindown.wav",
                80,
                100
            )

            timer.Remove(
                "BeaconLoop_" .. self:EntIndex()
            )
        end
    end

    function ENT:SetConfig(effectName, intensity)

        if not BeaconEffects[effectName] then
            return
        end

        intensity = math.Clamp(
            math.floor(intensity or 1),
            1,
            3
        )

        self.BeaconEffect = effectName
        self.BeaconIntensity = intensity

        self:SetNW2String(
            "BeaconEffect",
            self.BeaconEffect
        )

        self:SetNW2Int(
            "BeaconIntensity",
            self.BeaconIntensity
        )
    end

    net.Receive("ery_beacon_set", function(_, ply)

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_beacon" then return end
        if not IsValid(ply) then return end

        local effectName = net.ReadString()
        local intensity = net.ReadUInt(4)

        beacon:SetConfig(
            effectName,
            intensity
        )

        ply:ChatPrint(
            "[Beacon] Settings updated."
        )
    end)

    net.Receive("ery_beacon_toggle", function(_, ply)

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_beacon" then return end

        beacon:ToggleActive()
    end)

    function ENT:Think()

        local currentTime = CurTime()

        if self.Active
            and currentTime >= (self.NextPulse or 0) then

            self.NextPulse =
                currentTime + PulseInterval

            local intensityData =
                IntensitySettings[self.BeaconIntensity]
                or IntensitySettings[1]

            local range =
                intensityData.range or 600

            local multiplier =
                intensityData.mult or 1

            local effect =
                BeaconEffects[self.BeaconEffect]

            if effect and effect.apply then

                local nearbyPlayers =
                    ents.FindInSphere(
                        self:GetPos(),
                        range
                    )

                for _, target in ipairs(nearbyPlayers) do

                    if IsValid(target)
                        and target:IsPlayer()
                        and target:Alive() then

                        effect.apply(
                            target,
                            EffectMultiplier,
                            multiplier
                        )
                    end
                end
            end
        end

        self:NextThink(
            currentTime + 0.25
        )

        return true
    end

    function ENT:OnRemove()

        self.Active = false

        self:SetNW2Bool(
            "Active",
            false
        )

        timer.Remove(
            "BeaconLoop_" .. self:EntIndex()
        )
    end
end

-- Client

if CLIENT then

    surface.CreateFont("EryMatWorld", {
        font = "Tahoma",
        size = 36,
        weight = 500
    })

    net.Receive("ery_beacon_open", function()

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end

        local currentEffect =
            net.ReadString()
            or BeaconEffectNames[1]

        local currentIntensity =
            net.ReadUInt(4)
            or 1

        local isActive =
            net.ReadBool()

        local frame = vgui.Create("DFrame")

        frame:SetTitle(
            beacon.PrintName or "Beacon"
        )

        frame:SetSize(320, 180)
        frame:Center()
        frame:MakePopup()

        -- Effect label

        local effectLabel =
            vgui.Create("DLabel", frame)

        effectLabel:SetText(
            "Select effect:"
        )

        effectLabel:SetPos(8, 32)
        effectLabel:SizeToContents()

        -- Effect selector

        local effectCombo =
            vgui.Create("DComboBox", frame)

        effectCombo:SetPos(8, 54)

        effectCombo:SetSize(
            frame:GetWide() - 16,
            22
        )

        for _, effectName in ipairs(BeaconEffectNames) do

            local effect =
                BeaconEffects[effectName]

            if effect then
                effectCombo:AddChoice(
                    effect.display,
                    effectName
                )
            end
        end

        for index, effectName in ipairs(BeaconEffectNames) do

            if effectName == currentEffect then
                effectCombo:ChooseOptionID(index)
                break
            end
        end

        -- Intensity label

        local intensityLabel =
            vgui.Create("DLabel", frame)

        intensityLabel:SetText(
            "Intensity (1 = far/weak, 3 = near/strong):"
        )

        intensityLabel:SetPos(8, 84)
        intensityLabel:SizeToContents()

        -- Intensity slider

        local intensitySlider =
            vgui.Create("DNumSlider", frame)

        intensitySlider:SetPos(8, 110)

        intensitySlider:SetSize(
            frame:GetWide() - 16,
            24
        )

        intensitySlider:SetMin(1)
        intensitySlider:SetMax(3)
        intensitySlider:SetDecimals(0)
        intensitySlider:SetValue(currentIntensity)

        -- Apply button

        local applyButton =
            vgui.Create("DButton", frame)

        applyButton:SetPos(8, 140)

        applyButton:SetSize(
            (frame:GetWide() - 24) / 2,
            28
        )

        applyButton:SetText(
            "Apply Settings"
        )

        applyButton.DoClick = function()

            local _, selectedEffect =
                effectCombo:GetSelected()

            selectedEffect =
                selectedEffect
                or BeaconEffectNames[1]

            local intensity =
                math.Clamp(
                    math.floor(
                        intensitySlider:GetValue()
                    ),
                    1,
                    3
                )

            net.Start("ery_beacon_set")
                net.WriteEntity(beacon)
                net.WriteString(selectedEffect)
                net.WriteUInt(intensity, 4)
            net.SendToServer()

            frame:Close()
        end

        -- Toggle button

        local toggleButton =
            vgui.Create("DButton", frame)

        toggleButton:SetPos(
            16 + (frame:GetWide() - 24) / 2,
            140
        )

        toggleButton:SetSize(
            (frame:GetWide() - 24) / 2,
            28
        )

        toggleButton:SetText(
            isActive
            and "Turn OFF"
            or "Turn ON"
        )

        toggleButton.DoClick = function()

            net.Start("ery_beacon_toggle")
                net.WriteEntity(beacon)
            net.SendToServer()

            frame:Close()
        end
    end)

    function ENT:Draw()

        self:DrawModel()

        local ply = LocalPlayer()

        if not IsValid(ply) then return end

        local pos =
            self:GetPos()
            + (
                self.IconOffset
                or Vector(0, 0, 60)
            )

        if pos:DistToSqr(ply:GetPos()) > 250000 then
            return
        end

        local ang = ply:EyeAngles()

        ang:RotateAroundAxis(
            ang:Right(),
            90
        )

        ang:RotateAroundAxis(
            ang:Up(),
            -90
        )

        cam.Start3D2D(
            pos,
            ang,
            0.12
        )

            local icon =
                self.IconPath
                or "entities/ery_mat_mechanism_advanced.png"

            surface.SetDrawColor(
                self.IconColor
                or Color(255, 255, 255, 255)
            )

            surface.SetMaterial(
                Material(icon, "smooth")
            )

            surface.DrawTexturedRect(
                -64,
                -64,
                128,
                128
            )

            draw.SimpleText(
                self.PrintName or "Beacon",
                "EryMatWorld",
                0,
                25,
                color_white,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_TOP
            )

			local effect =
				self:GetNW2String(
					"BeaconEffect",
					"Healing"
				)

			local intensity =
				self:GetNW2Int(
					"BeaconIntensity",
					1
				)

			local active =
				self:GetNW2Bool(
					"Active",
					false
				)

			local health =
				self:GetNW2Int(
					"BeaconHealth",
					500
				)

			local maxHealth = 500

			draw.SimpleText(
				"Effect: " .. effect,
				"EryMatWorld",
				0,
				75,
				Color(200, 200, 255),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

			draw.SimpleText(
				"Intensity: " .. tostring(intensity),
				"EryMatWorld",
				0,
				105,
				Color(200, 255, 200),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

			draw.SimpleText(
				"Active: " .. (
					active
					and "Yes"
					or "No"
				),
				"EryMatWorld",
				0,
				135,
				active
					and Color(100, 255, 100)
					or Color(255, 100, 100),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

			local healthFraction =
				math.Clamp(
					health / maxHealth,
					0,
					1
				)

			local barWidth = 180
			local barHeight = 10
			local barX = -barWidth / 2
			local barY = 205

			draw.RoundedBox(
				4,
				barX,
				barY,
				barWidth,
				barHeight,
				Color(40, 40, 40, 220)
			)

			draw.RoundedBox(
				4,
				barX,
				barY,
				barWidth * healthFraction,
				barHeight,
				Color(100, 220, 100, 255)
			)

			draw.SimpleText(
				health .. " / " .. maxHealth,
				"EryMatWorld",
				0,
				220,
				color_white,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

        cam.End3D2D()
    end
end