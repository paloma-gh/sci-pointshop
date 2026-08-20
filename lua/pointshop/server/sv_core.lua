PS = PS or {}
PS.Core = PS.Core or {}

-- Maximum number of points a player can have.
PS.Config.MaxPoints = PS.Config.MaxPoints or 100000

PS.Core.Cache = PS.Core.Cache or {}


local function GetSteamID64Safe(ply)
	if not IsValid(ply) then return nil end
	if not ply:IsPlayer() then return nil end

	local ok, sid = pcall(function()
		return ply:SteamID64()
	end)

	if ok and sid and sid ~= "" then
		return sid
	end

	return nil
end

local function ClampPoints(amount)
	amount = math.floor(tonumber(amount) or 0)

	return math.Clamp(
		amount,
		0,
		PS.Config.MaxPoints
	)
end

function PS.Core.SyncToClient(ply)
	if not IsValid(ply) then return end

	local points = PS.Core.Cache[ply] or 0

	net.Start("PS_UpdatePoints")
		net.WriteInt(points, 32)
	net.Send(ply)
end


-- API

-- Returns the player's current point total (net worth).
-- Safe to call at any time once the player has initially spawned/loaded.
function PS.Core.GetPoints(ply)
	if not IsValid(ply) then return 0 end

	return PS.Core.Cache[ply] or 0
end

-- Sets a player's points to an explicit value.
-- The value is clamped between 0 and PS.Config.MaxPoints, persisted, and synced to the client.
-- Returns the final value.
function PS.Core.SetPoints(ply, amount, reason)
	if not IsValid(ply) then return 0 end

	amount = ClampPoints(amount)

	PS.Core.Cache[ply] = amount

	local steamid64 = GetSteamID64Safe(ply)

	if steamid64 then
		PS.Data.SetPoints(steamid64, amount)
	end

	PS.Core.SyncToClient(ply)

	hook.Run(
		"PS_PointsChanged",
		ply,
		amount,
		reason
	)

	return amount
end


-- Adds (or subtracts, if negative) points to a player's total.
-- Net worth is always clamped between 0 and PS.Config.MaxPoints.
-- Returns the new total.
function PS.Core.AddPoints(ply, amount, reason)
	if not IsValid(ply) then return 0 end

	amount = math.floor(tonumber(amount) or 0)

	local current = PS.Core.GetPoints(ply)

	local new_total = math.Clamp(
		current + amount,
		0,
		PS.Config.MaxPoints
	)

	return PS.Core.SetPoints(
		ply,
		new_total,
		reason
	)
end

-- Removes points from a player, clamped so net worth never goes below 0.
-- Returns the actual amount removed and the new total.
function PS.Core.TakePoints(ply, amount, reason)
	if not IsValid(ply) then return 0, 0 end

	amount = math.floor(
		math.abs(
			tonumber(amount) or 0
		)
	)

	local current = PS.Core.GetPoints(ply)

	local actual_removed = math.min(
		current,
		amount
	)

	local new_total = current - actual_removed

	PS.Core.SetPoints(
		ply,
		new_total,
		reason
	)

	return actual_removed, new_total
end

-- Loads a player's persisted points into the in-memory cache.
-- Creates a fresh DB row (0 points) if this is their first time connecting.
-- Also grants the one-time join bonus if they haven't received it yet.
function PS.Core.LoadPlayer(ply)
	if not IsValid(ply) then return end

	local steamid64 = GetSteamID64Safe(ply)

	if not steamid64 then
		PS.Core.Cache[ply] =
			PS.Core.Cache[ply] or 0

		PS.Core.Cache[ply] =
			ClampPoints(PS.Core.Cache[ply])

		PS.Core.SyncToClient(ply)

		return
	end

	local is_new = PS.Data.EnsureRow(
		steamid64,
		ply:Nick()
	)

	PS.Data.UpdateNick(
		steamid64,
		ply:Nick()
	)

	local row = PS.Data.GetRow(steamid64)

	local points =
		row and tonumber(row.points) or 0

	points = ClampPoints(points)

	PS.Core.Cache[ply] = points

	-- Join bonus: award to brand new players immediately (existing-players-on-server case is handled separately in sv_joinbonus.lua)
	if is_new then
		PS.Core.AddPoints(
			ply,
			PS.Config.JoinBonus,
			"join_bonus"
		)

		PS.Data.SetJoinBonusReceived(steamid64)
	else
		PS.Core.SyncToClient(ply)
	end
end


-- Flushes a player's cached points to the DB and removes them from the in-memory cache. Called on disconnect.
function PS.Core.UnloadPlayer(ply)
	if not IsValid(ply) then return end

	local steamid64 = GetSteamID64Safe(ply)
	local points = PS.Core.Cache[ply]

	if steamid64 and points then
		points = ClampPoints(points)

		PS.Data.SetPoints(
			steamid64,
			points
		)
	end

	PS.Core.Cache[ply] = nil
end


-- Hooks

hook.Add("PlayerInitialSpawn", "PS_Core_LoadPlayer", function(ply)
	timer.Simple(0, function()
		if IsValid(ply) then
			PS.Core.LoadPlayer(ply)
		end
	end)
end)


hook.Add("PlayerDisconnected", "PS_Core_UnloadPlayer", function(ply)
	PS.Core.UnloadPlayer(ply)
end)

-- Safety net: periodically flush all cached points to disk just in case.
timer.Create(
	"PS_Core_PeriodicFlush",
	60,
	0,
	function()
		for ply, points in pairs(PS.Core.Cache) do
			if IsValid(ply) then
				local steamid64 =
					GetSteamID64Safe(ply)

				if steamid64 then
					points = ClampPoints(points)

					PS.Core.Cache[ply] = points

					PS.Data.SetPoints(
						steamid64,
						points
					)
				end
			end
		end
	end
)

-- On a clean server shutdown, flush everything immediately.
hook.Add("ShutDown", "PS_Core_FlushOnShutdown", function()
	for ply, points in pairs(PS.Core.Cache) do
		if IsValid(ply) then
			local steamid64 =
				GetSteamID64Safe(ply)

			if steamid64 then
				points = ClampPoints(points)

				PS.Data.SetPoints(
					steamid64,
					points
				)
			end
		end
	end
end)