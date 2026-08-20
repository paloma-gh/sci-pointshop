-- Gives 500 points as a first time bonus
PS = PS or {}

local FLAG_FILE = "pointshop/rollout_bonus_given.txt"

local function HasRolloutBonusBeenGiven()
	return file.Exists(FLAG_FILE, "DATA")
end

local function MarkRolloutBonusGiven()
	file.CreateDir("pointshop")
	file.Write(FLAG_FILE, tostring(os.time()))
end

local function AwardRolloutBonusToCurrentPlayers()
	if HasRolloutBonusBeenGiven() then return end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			local already_had_wallet = PS.Core.Cache[ply] ~= nil
			if not already_had_wallet then
				PS.Core.LoadPlayer(ply)
			end

			local steamid64 = ply:IsBot() and nil or ply:SteamID64()
			local row = steamid64 and PS.Data.GetRow(steamid64) or nil
			local already_flagged = row and tonumber(row.has_received_join_bonus) == 1

			if not already_flagged then
				PS.Core.AddPoints(ply, PS.Config.JoinBonus, "rollout_bonus")
				if steamid64 then
					PS.Data.SetJoinBonusReceived(steamid64)
				end

				if ply.ChatPrint then
					ply:ChatPrint(string.format(
						"[Pointshop] You've been awarded %s points!",
						PS.FormatNumber(PS.Config.JoinBonus)
					))
				end
			end
		end
	end

	MarkRolloutBonusGiven()

	print("[Pointshop] Rollout bonus of " .. PS.Config.JoinBonus .. " points awarded to all currently connected players.")
end

hook.Add("Initialize", "PS_AwardRolloutBonus", function()
	timer.Simple(1, AwardRolloutBonusToCurrentPlayers)
end)

if game.IsDedicated() or true then
	timer.Simple(2, AwardRolloutBonusToCurrentPlayers)
end
