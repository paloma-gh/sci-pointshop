if SERVER then
	AddCSLuaFile("pointshop/sh_pointshop_items.lua")

	include("pointshop/sh_pointshop_items.lua")
	include("pointshop/server/sv_pointshop_dynamic_pricing.lua")
	include("pointshop/server/sv_pointshop_menu.lua")

	AddCSLuaFile("pointshop/client/cl_pointshop_menu.lua")
 
	print("[Pointshop] Shop menu (server) loaded successfully.")
elseif CLIENT then
	include("pointshop/sh_pointshop_items.lua")
	include("pointshop/client/cl_pointshop_menu.lua")
 
	print("[Pointshop] Shop menu (client) loaded successfully.")
end
 