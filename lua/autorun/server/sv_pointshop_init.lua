AddCSLuaFile("pointshop/sh_pointshop.lua")

include("pointshop/sh_pointshop.lua")
include("pointshop/server/sv_data.lua")
include("pointshop/server/sv_core.lua")
include("pointshop/server/sv_joinbonus.lua")
include("pointshop/server/sv_killtracker.lua")
include("pointshop/server/sv_playreward.lua")

AddCSLuaFile("pointshop/client/cl_hud.lua")
AddCSLuaFile("pointshop/client/cl_killfeed.lua")

print("[Pointshop] Server-side loaded successfully.")
