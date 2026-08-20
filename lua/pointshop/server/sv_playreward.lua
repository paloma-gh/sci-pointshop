-- Give X points to players every Y seconds.
PS = PS or {}
PS.PlayReward = PS.PlayReward or {}

local TIMER_NAME = "PS_GlobalPlayReward"

function PS.PlayReward.PayAllPlayers()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			PS.Core.AddPoints(ply, PS.Config.PlayReward, "playtime")

			if ply.ChatPrint then
				ply:ChatPrint(string.format(
					"[Pointshop] You've earned %s points for playing on the server!",
					PS.FormatNumber(PS.Config.PlayReward)
				))
			end

			hook.Run("PS_PlayRewardGiven", ply, PS.Config.PlayReward)
		end
	end
end

function PS.PlayReward.StartGlobalTimer()
	timer.Create(TIMER_NAME, PS.Config.PlayRewardInterval, 0, PS.PlayReward.PayAllPlayers)
end

hook.Add("Initialize", "PS_PlayReward_StartGlobalTimer", function()
	PS.PlayReward.StartGlobalTimer()
end)

if not timer.Exists(TIMER_NAME) then
	PS.PlayReward.StartGlobalTimer()
end
