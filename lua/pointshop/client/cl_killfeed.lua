-- Kill notif handler.

PS = PS or {}
PS.Client = PS.Client or {}
PS.Client.KillToasts = PS.Client.KillToasts or {}

local TOAST_LIFETIME = 3.5
local TOAST_FADE_IN  = 0.15
local TOAST_FADE_OUT = 0.6
local LINE_H          = 26   -- vertical spacing between lines within one notif or "toast".
local TOAST_GAP       = 16   -- vertical gap between separate notif
local TOTAL_LINE_GAP  = 8    -- extra breathing room under the "+total" line

surface.CreateFont("PS_Toast_Total", {
	font = "Roboto Bold",
	size = 34,
	weight = 900,
	antialias = true,
})

surface.CreateFont("PS_Toast_Modifier", {
	font = "Roboto Bold",
	size = 20,
	weight = 700,
	antialias = true,
})

-- Networking

net.Receive("PS_KillFeed", function()
	local total = net.ReadInt(32)
	local victim_name = net.ReadString()
	local count = net.ReadUInt(8)

	local breakdown = {}
	for i = 1, count do
		local label = net.ReadString()
		local amount = net.ReadInt(32)
		table.insert(breakdown, { label = label, amount = amount })
	end

	local modifiers = {}
	for _, entry in ipairs(breakdown) do
		if entry.label ~= "Kill" and entry.label ~= "Assist" then
			table.insert(modifiers, entry.label)
		end
	end

	table.insert(PS.Client.KillToasts, {
		total = total,
		victim = victim_name,
		modifiers = modifiers,
		start_time = CurTime(),
	})

	if #PS.Client.KillToasts > 6 then
		table.remove(PS.Client.KillToasts, 1)
	end

end)

-- Drawing

local COLOR_GOLD = Color(255, 205, 45, 255)

local function GetToastHeight(toast)
	return LINE_H + TOTAL_LINE_GAP + (#toast.modifiers * LINE_H)
end

hook.Add("HUDPaint", "PS_DrawKillToasts", function()
	local toasts = PS.Client.KillToasts
	if #toasts == 0 then return end

	local sw, sh = ScrW(), ScrH()

	local anchor_x = sw * 0.55
	local anchor_y = sh * 0.5

	local stack_offset = 0

	for i = #toasts, 1, -1 do
		local toast = toasts[i]
		local age = CurTime() - toast.start_time

		if age > TOAST_LIFETIME then
			table.remove(toasts, i)
		else

			local alpha = 1
			if age < TOAST_FADE_IN then
				alpha = age / TOAST_FADE_IN
			elseif age > TOAST_LIFETIME - TOAST_FADE_OUT then
				alpha = (TOAST_LIFETIME - age) / TOAST_FADE_OUT
			end
			alpha = math.Clamp(alpha, 0, 1)
			local a = alpha * 255

			local y = anchor_y + stack_offset

			draw.SimpleText("+" .. PS.FormatNumber(toast.total), "PS_Toast_Total", anchor_x, y, ColorAlpha(COLOR_GOLD, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			local line_y = y + LINE_H + TOTAL_LINE_GAP
			for _, label in ipairs(toast.modifiers) do
				draw.SimpleText(label, "PS_Toast_Modifier", anchor_x, line_y, ColorAlpha(COLOR_GOLD, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				line_y = line_y + LINE_H
			end

			stack_offset = stack_offset + GetToastHeight(toast) + TOAST_GAP
		end
	end
end)
