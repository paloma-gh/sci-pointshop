-- Registers the pointshop tab in the Q menu.
PS = PS or {}
PS.ShopUI = PS.ShopUI or {}

PS.ShopUI.ActiveBonuses = PS.ShopUI.ActiveBonuses or {}

PS.ShopUI.PriceState = PS.ShopUI.PriceState or {}

surface.CreateFont("PS_Shop_ItemName", {
	font = "Roboto Bold",
	size = 16,
	weight = 700,
	antialias = true,
})

surface.CreateFont("PS_Shop_ItemPrice", {
	font = "Roboto Bold",
	size = 15,
	weight = 700,
	antialias = true,
})

surface.CreateFont("PS_Shop_ItemDesc", {
	font = "Roboto",
	size = 13,
	weight = 400,
	antialias = true,
})

surface.CreateFont("PS_Shop_Balance", {
	font = "Roboto Bold",
	size = 18,
	weight = 700,
	antialias = true,
})

surface.CreateFont("PS_Shop_ColumnHeader", {
	font = "Roboto Bold",
	size = 15,
	weight = 700,
	antialias = true,
})

surface.CreateFont("PS_Shop_ActiveBadge", {
	font = "Roboto Bold",
	size = 11,
	weight = 700,
	antialias = true,
})

surface.CreateFont("PS_Shop_PriceBadge", {
	font = "Roboto Bold",
	size = 11,
	weight = 800,
	antialias = true,
})

local COLOR_GOLD          = Color(255, 205, 45, 255)
local COLOR_AFFORDABLE    = Color(120, 230, 130, 255)
local COLOR_TOO_EXPENSIVE = Color(230, 90, 90, 255)
local COLOR_CARD_BG       = Color(35, 35, 40, 255)
local COLOR_CARD_HOVER    = Color(48, 48, 55, 255)
local COLOR_CARD_ACTIVE   = Color(45, 60, 40, 255)
local COLOR_ACTIVE_BADGE  = Color(120, 230, 130, 255)
local COLOR_COLUMN_HEADER = Color(220, 220, 225, 255)
local COLOR_MARKUP_BADGE  = Color(200, 40, 40, 255)
local COLOR_DISCOUNT_BADGE = Color(40, 170, 60, 255)
local COLOR_ORIGINAL_PRICE_STRIKE = Color(150, 150, 150, 255)

-- Networking

-- Send a purchase request to the server for the given buyable_class
function PS.ShopUI.RequestPurchase(buyable_class)
	net.Start("PS_Shop_Purchase")
		net.WriteString(buyable_class)
	net.SendToServer()
end

net.Receive("PS_Shop_PurchaseResult", function()
	local success = net.ReadBool()
	local message = net.ReadString()

	if success then
		notification.AddLegacy(message, NOTIFY_GENERIC, 4)
		surface.PlaySound("buttons/button14.wav")
	else
		notification.AddLegacy(message, NOTIFY_ERROR, 4)
		surface.PlaySound("buttons/button10.wav")
	end
end)

net.Receive("PS_Shop_SyncActiveBonuses", function()
	local count = net.ReadUInt(8)

	local new_active = {}
	for i = 1, count do
		local class = net.ReadString()
		new_active[class] = true
	end

	PS.ShopUI.ActiveBonuses = new_active
end)

net.Receive("PS_Shop_SyncPricing", function()
	local count = net.ReadUInt(16)

	local new_state = {}
	for i = 1, count do
		local class = net.ReadString()
		local state = net.ReadString()
		local percent_fixed = net.ReadUInt(16)
		new_state[class] = { state = state, percent = percent_fixed / 1000 }
	end

	PS.ShopUI.PriceState = new_state

	if PS.ShopUI.RefreshAllCards then
		PS.ShopUI.RefreshAllCards()
	end
end)

function PS.ShopUI.GetEffectivePrice(buyable_class, item)
	local base_price = item.BasePrice or 0
	local state = PS.ShopUI.PriceState[buyable_class]
	if not state then return base_price end

	if state.state == "markup" then
		local price = base_price * (1 + state.percent)
		local max_price = base_price * (PS.Config and PS.Config.ShopMarkupMaxMultiplier or 2)
		return math.min(price, max_price)
	elseif state.state == "discount" then
		return base_price * (1 - state.percent)
	end

	return base_price
end

-- Buyables

local PANEL = {}

function PANEL:Init()
	self:SetTall(84)
	self:Dock(TOP)
	self:DockMargin(6, 6, 6, 0)
	self:SetCursor("hand")

	self.Icon = vgui.Create("DImage", self)
	self.Icon:SetSize(48, 48)
	self.Icon:SetPos(10, 10)

	self.NameLabel = vgui.Create("DLabel", self)
	self.NameLabel:SetFont("PS_Shop_ItemName")
	self.NameLabel:SetTextColor(color_white)
	self.NameLabel:SetPos(68, 10)

	self.DescLabel = vgui.Create("DLabel", self)
	self.DescLabel:SetFont("PS_Shop_ItemDesc")
	self.DescLabel:SetTextColor(Color(190, 190, 190))
	self.DescLabel:SetPos(68, 32)
	self.DescLabel:SetWrap(true)

	self.PriceLabel = vgui.Create("DLabel", self)
	self.PriceLabel:SetFont("PS_Shop_ItemPrice")
	self.PriceLabel:SetTextColor(COLOR_GOLD)

	self.BuyButton = vgui.Create("DButton", self)
	self.BuyButton:SetText("BUY")
	self.BuyButton:SetTall(28)
	self.BuyButton:SetWide(70)
end

function PANEL:Setup(buyable_class, item)
	self.buyable_class = buyable_class
	self.item = item
	self.is_bonus = item.Type == PS.ITEM_TYPE_BONUS

	self.NameLabel:SetText(item.Name or buyable_class)
	self.NameLabel:SizeToContents()

	self.DescLabel:SetText(item.Description or "")

	if item.Icon then
		self.Icon:SetImage(item.Icon)
	else
		self.Icon:SetImage("icon16/box.png")
	end

	self.PriceLabel:SetFont("PS_Shop_ItemPrice")

	self.BuyButton.DoClick = function()
		PS.ShopUI.RequestPurchase(buyable_class)
	end

	self:Refresh()
end

function PANEL:Refresh()
	local is_active = self.is_bonus and PS.ShopUI.ActiveBonuses[self.buyable_class] == true

	local effective_price = PS.ShopUI.GetEffectivePrice(self.buyable_class, self.item)
	self.effective_price = effective_price

	local pricing = PS.ShopUI.PriceState[self.buyable_class]
	self.price_badge_state = pricing and pricing.state or nil
	self.price_badge_percent = pricing and pricing.percent or nil

	local points = (PS.Client and PS.Client.Points) or 0
	local affordable = points >= effective_price

	self.PriceLabel:SetText(PS.FormatNumber(math.floor(effective_price)) .. " pts")
	self.PriceLabel:SizeToContents()

	if is_active then
		self.PriceLabel:SetTextColor(COLOR_ACTIVE_BADGE)
		self.BuyButton:SetEnabled(false)
		self.BuyButton:SetText("OWNED")
	else
		self.PriceLabel:SetTextColor(affordable and COLOR_AFFORDABLE or COLOR_TOO_EXPENSIVE)
		self.BuyButton:SetEnabled(affordable)
		self.BuyButton:SetText("BUY")
	end

	self.is_active = is_active
end

function PANEL:UpdateAffordability()
	self:Refresh()
end

function PANEL:PerformLayout(w, h)
	self.DescLabel:SetPos(68, 32)
	self.DescLabel:SetSize(math.max(w - 170, 10), 40)

	self.PriceLabel:SetPos(w - 170, 16)
	self.BuyButton:SetPos(w - 90, h / 2 - 14)
end

function PANEL:Paint(w, h)
	local col = COLOR_CARD_BG
	if self.is_active then
		col = COLOR_CARD_ACTIVE
	elseif self:IsHovered() then
		col = COLOR_CARD_HOVER
	end
	draw.RoundedBox(6, 0, 0, w, h, col)

	if self.is_active then
		local badge_text = "ACTIVE"
		surface.SetFont("PS_Shop_ActiveBadge")
		local bw = surface.GetTextSize(badge_text)
		draw.RoundedBox(3, 8, h - 20, bw + 12, 14, COLOR_ACTIVE_BADGE)
		draw.SimpleText(badge_text, "PS_Shop_ActiveBadge", 14, h - 18, Color(20, 20, 20), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	-- Dynamic pricing badge
	-- a small squared box in the top-right corner of the card.
	-- Red + markup % if this item was among the most bought last period; green "25% OFF!" if it was randomly chosen to be discounted this period.
	-- The two are mutually exclusive (see sv_pointshop_dynamic_pricing.lua)
	if self.price_badge_state == "markup" or self.price_badge_state == "discount" then
		local is_markup = self.price_badge_state == "markup"
		local badge_color = is_markup and COLOR_MARKUP_BADGE or COLOR_DISCOUNT_BADGE
		local pct = math.floor((self.price_badge_percent or 0) * 100 + 0.5)
		local pct_text = is_markup and string.format("+%d%%", pct) or string.format("%d%% OFF!", pct)

		surface.SetFont("PS_Shop_PriceBadge")
		local bw = surface.GetTextSize(pct_text)
		local box_w = math.max(bw + 14, 20)
		draw.RoundedBox(3, w - box_w - 8, 8, box_w, 16, badge_color)
		draw.SimpleText(pct_text, "PS_Shop_PriceBadge", w - box_w/2 - 8, 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		if self.item and self.item.BasePrice then
			local orig_text = PS.FormatNumber(self.item.BasePrice) .. " pts"
			surface.SetFont("PS_Shop_ItemDesc")
			local ow = surface.GetTextSize(orig_text)
			local ox, oy = w - 170, 2
			draw.SimpleText(orig_text, "PS_Shop_ItemDesc", ox, oy, COLOR_ORIGINAL_PRICE_STRIKE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			surface.SetDrawColor(COLOR_ORIGINAL_PRICE_STRIKE)
			surface.DrawLine(ox, oy + 7, ox + ow, oy + 7)
		end
	end
end

vgui.Register("PS_ShopItemCard", PANEL, "DPanel")

local function BuildCardList(parent, items, empty_message)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	local sorted = {}
	for _, entry in ipairs(items) do table.insert(sorted, entry) end
	table.sort(sorted, function(a, b) return (a.data.BasePrice or 0) < (b.data.BasePrice or 0) end)

	if #sorted == 0 then
		local empty = vgui.Create("DLabel", scroll)
		empty:SetText(empty_message or "No items available.")
		empty:SetFont("PS_Shop_ItemDesc")
		empty:SetTextColor(Color(150, 150, 150))
		empty:Dock(TOP)
		empty:DockMargin(6, 12, 6, 0)
		empty:SetContentAlignment(5)
		empty:SizeToContents()
	end

	local cards = {}
	for _, entry in ipairs(sorted) do
		local card = vgui.Create("PS_ShopItemCard", scroll)
		card:Setup(entry.class, entry.data)
		table.insert(cards, card)
	end

	local function RefreshCards()
		for _, card in ipairs(cards) do
			if IsValid(card) then
				card:Refresh()
			end
		end
	end

	return scroll, RefreshCards
end

-- Entities / Weapons tabs

local function BuildCategoryPanel(item_type, empty_message)
	local base = vgui.Create("DPanel")
	base:Dock(FILL)
	base.Paint = function() end

	local items = PS.GetItemsByType(item_type)
	local _, RefreshCards = BuildCardList(base, items, empty_message)

	base.RefreshAffordability = RefreshCards

	return base
end

-- Bonuses tab

local function BuildBonusesPanel()
	local base = vgui.Create("DPanel")
	base:Dock(FILL)
	base.Paint = function() end

	local grouped = PS.GetBonusItemsByCategory()
	local column_count = #PS.BONUS_TYPE_ORDER
	local refresh_fns = {}

	for i, bonus_type in ipairs(PS.BONUS_TYPE_ORDER) do
		local column = vgui.Create("DPanel", base)
		column:Dock(LEFT)
		column:DockMargin(i == 1 and 0 or 4, 0, 0, 0)
		column:SetWide(1)
		column.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(28, 28, 32, 255))
		end

		local header = vgui.Create("DLabel", column)
		header:SetText(bonus_type)
		header:SetFont("PS_Shop_ColumnHeader")
		header:SetTextColor(COLOR_COLUMN_HEADER)
		header:Dock(TOP)
		header:DockMargin(8, 8, 8, 4)
		header:SetContentAlignment(4)
		header:SizeToContents()

		local _, RefreshCards = BuildCardList(column, grouped[bonus_type], "No bonuses in this category.")
		table.insert(refresh_fns, RefreshCards)
	end

	base.PerformLayout = function(self, w, h)
		local children = self:GetChildren()
		local col_w = math.floor(w / column_count)
		for _, child in ipairs(children) do
			if child.SetWide then
				child:SetWide(col_w)
			end
		end
	end

	base.RefreshAffordability = function()
		for _, fn in ipairs(refresh_fns) do
			fn()
		end
	end

	return base
end

function PS.ShopUI.CreatePanel()
	net.Start("PS_Shop_RequestSync")
	net.SendToServer()

	local root = vgui.Create("DPanel")
	root:SetSize(650, 500)
	root.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(24, 24, 28, 255))
	end

	local header = vgui.Create("DPanel", root)
	header:Dock(TOP)
	header:SetTall(40)
	header.Paint = function(self, w, h)
		draw.RoundedBoxEx(6, 0, 0, w, h, Color(30, 30, 35, 255), true, true, false, false)
	end

	local balance_label = vgui.Create("DLabel", header)
	balance_label:SetFont("PS_Shop_Balance")
	balance_label:Dock(FILL)
	balance_label:DockMargin(12, 0, 12, 0)
	balance_label:SetContentAlignment(4)
	balance_label:SetTextColor(COLOR_GOLD)

	local function RefreshBalance()
		local points = (PS.Client and PS.Client.Points) or 0
		balance_label:SetText("Balance: " .. PS.FormatNumber(points) .. " pts")
	end
	RefreshBalance()

	local sheet = vgui.Create("DPropertySheet", root)
	sheet:Dock(FILL)
	sheet:DockMargin(4, 4, 4, 4)

	local entities_panel = BuildCategoryPanel(PS.ITEM_TYPE_ENTITY, "No entities available.")
	local weapons_panel  = BuildCategoryPanel(PS.ITEM_TYPE_WEAPON, "No weapons available.")
	local bonuses_panel  = BuildBonusesPanel()

	sheet:AddSheet("Entities", entities_panel, "icon16/bricks.png")
	sheet:AddSheet("Weapons", weapons_panel, "icon16/gun.png")
	sheet:AddSheet("Bonuses", bonuses_panel, "icon16/star.png")

	local function RefreshAllCards()
		RefreshBalance()
		entities_panel.RefreshAffordability()
		weapons_panel.RefreshAffordability()
		bonuses_panel.RefreshAffordability()
	end

	PS.ShopUI.RefreshAllCards = RefreshAllCards

	local think_id = "PS_ShopUI_Refresh_" .. tostring(root)
	hook.Add("Think", think_id, function()
		if not IsValid(root) then
			hook.Remove("Think", think_id)
			if PS.ShopUI.RefreshAllCards == RefreshAllCards then
				PS.ShopUI.RefreshAllCards = nil
			end
			return
		end
		RefreshAllCards()
	end)

	root.OnRemove = function()
		hook.Remove("Think", think_id)
		if PS.ShopUI.RefreshAllCards == RefreshAllCards then
			PS.ShopUI.RefreshAllCards = nil
		end
	end

	return root
end

spawnmenu.AddCreationTab("Pointshop", PS.ShopUI.CreatePanel, "icon16/cart.png", 950, "Spend your points")