-- Stores player points in a local SQLite database by SteamID64. This ensures points persist across disconnects, map changes, and full server restarts.

PS = PS or {}
PS.Data = PS.Data or {}

local TABLE_NAME = "pointshop_players"

local function CreateTableIfMissing()
	local query = string.format([[
		CREATE TABLE IF NOT EXISTS %s (
			steamid TEXT PRIMARY KEY,
			nick TEXT,
			points INTEGER DEFAULT 0,
			has_received_join_bonus INTEGER DEFAULT 0
		)
	]], TABLE_NAME)

	local result = sql.Query(query)
	if result == false then
		ErrorNoHalt("[Pointshop] Failed to create/verify database table: " .. tostring(sql.LastError()) .. "\n")
	end
end
CreateTableIfMissing()

local function SQLStr(s)
	return sql.SQLStr(tostring(s))
end

function PS.Data.GetRow(steamid64)
	local query = string.format("SELECT * FROM %s WHERE steamid = %s", TABLE_NAME, SQLStr(steamid64))
	local result = sql.Query(query)
	if result and result[1] then
		return result[1]
	end
	return nil
end

function PS.Data.EnsureRow(steamid64, nick)
	local existing = PS.Data.GetRow(steamid64)
	if existing then return false end

	local query = string.format(
		"INSERT INTO %s (steamid, nick, points, has_received_join_bonus) VALUES (%s, %s, 0, 0)",
		TABLE_NAME, SQLStr(steamid64), SQLStr(nick or "Unknown")
	)
	local ok = sql.Query(query)
	if ok == false then
		ErrorNoHalt("[Pointshop] Failed to insert new player row: " .. tostring(sql.LastError()) .. "\n")
	end
	return true
end

function PS.Data.SetPoints(steamid64, points)
	points = math.max(0, math.floor(points))
	local query = string.format(
		"UPDATE %s SET points = %d WHERE steamid = %s",
		TABLE_NAME, points, SQLStr(steamid64)
	)
	local ok = sql.Query(query)
	if ok == false then
		ErrorNoHalt("[Pointshop] Failed to update points: " .. tostring(sql.LastError()) .. "\n")
	end
	return points
end

function PS.Data.SetJoinBonusReceived(steamid64)
	local query = string.format(
		"UPDATE %s SET has_received_join_bonus = 1 WHERE steamid = %s",
		TABLE_NAME, SQLStr(steamid64)
	)
	sql.Query(query)
end

function PS.Data.UpdateNick(steamid64, nick)
	local query = string.format(
		"UPDATE %s SET nick = %s WHERE steamid = %s",
		TABLE_NAME, SQLStr(nick or "Unknown"), SQLStr(steamid64)
	)
	sql.Query(query)
end
