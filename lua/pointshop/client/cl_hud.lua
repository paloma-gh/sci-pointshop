-- Net worth counter. seen in the middle bottom of screen.
PS = PS or {}
PS.Client = PS.Client or {}

PS.Client.Points = PS.Client.Points or 0
PS.Client.DisplayPoints = PS.Client.DisplayPoints or 0
PS.Client.LastChangeTime = PS.Client.LastChangeTime or 0
PS.Client.LastChangeAmount = PS.Client.LastChangeAmount or 0

surface.CreateFont("PS_HUD_Value", {
	font = "Roboto Bold",
	size = 26,
	weight = 800,
	antialias = true,
})

surface.CreateFont("PS_HUD_Label", {
	font = "Roboto",
	size = 14,
	weight = 500,
	antialias = true,
})

-- Networking

net.Receive("PS_UpdatePoints", function()
	local new_points = net.ReadInt(32)

	local diff = new_points - PS.Client.Points
	if diff ~= 0 then
		PS.Client.LastChangeAmount = diff
		PS.Client.LastChangeTime = CurTime()
	end

	PS.Client.Points = new_points
end)

-- Drawing

local PANEL_W = 220
local PANEL_H = 54
local MARGIN_BOTTOM = 40

local COLOR_BG        = Color(20, 20, 24, 210)
local COLOR_BORDER    = Color(255, 200, 40, 255)
local COLOR_TEXT      = Color(255, 255, 255, 255)
local COLOR_LABEL     = Color(190, 190, 190, 255)
local COLOR_POS_FLASH = Color(90, 220, 110, 255)
local COLOR_NEG_FLASH = Color(230, 70, 70, 255)

hook.Add("HUDPaint", "PS_DrawPointsHUD", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	PS.Client.DisplayPoints = Lerp(FrameTime() * 6, PS.Client.DisplayPoints, PS.Client.Points)
	local shown_value = math.floor(PS.Client.DisplayPoints + 0.5)

	if math.abs(PS.Client.DisplayPoints - PS.Client.Points) < 0.5 then
		PS.Client.DisplayPoints = PS.Client.Points
		shown_value = PS.Client.Points
	end

	local sw, sh = ScrW(), ScrH()
	local x = sw / 2 - PANEL_W / 2
	local y = sh - MARGIN_BOTTOM - PANEL_H

	local time_since_change = CurTime() - PS.Client.LastChangeTime
	local border_col = COLOR_BORDER
	if time_since_change < 1 then
		local flash_col = PS.Client.LastChangeAmount >= 0 and COLOR_POS_FLASH or COLOR_NEG_FLASH
		local alpha = 1 - (time_since_change / 1)
		border_col = Color(
			Lerp(alpha, COLOR_BORDER.r, flash_col.r),
			Lerp(alpha, COLOR_BORDER.g, flash_col.g),
			Lerp(alpha, COLOR_BORDER.b, flash_col.b),
			255
		)
	end

	draw.RoundedBox(8, x, y, PANEL_W, PANEL_H, COLOR_BG)

	surface.SetDrawColor(border_col)
	surface.DrawRect(x, y, PANEL_W, 3)

	draw.SimpleText("NET WORTH", "PS_HUD_Label", x + PANEL_W / 2, y + 14, COLOR_LABEL, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	draw.SimpleText(PS.FormatNumber(shown_value) .. " pts", "PS_HUD_Value", x + PANEL_W / 2, y + 30, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)


hook.Add("InitPostEntity", "PS_RequestInitialSync", function()

end)
