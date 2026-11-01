class_name MarketWindow
extends PanelContainer
## Rynek gildii (Market) - u pisarza gildii. Zakładki:
## - Towary: lista towarów z ceną i zmianą ceny, a dla zaznaczonego arkusz ofert (sprzedaż nad ceną, kupno pod nią),
##   kupno / sprzedaż od razu i wystawienie własnego zamówienia po swojej cenie (ilość i cena w polach),
## - Przedmioty: oferty podróżników (kup) i przedmioty z plecaka do wystawienia; filtr rodzaju, sortowanie (cena, poziom,
##   okazja), przełącznik „Dla mnie” (rzeczy do założenia: broń obecnego rodzaju, poziom nie wyższy niż postaci),
##   przy ofercie - o ile jest taniej / drożej od uczciwej ceny (okazje szybko znikają),
## - Moje: zamówienia i wystawione przedmioty gracza (postęp, wycofanie, odbiór kupionych rzeczy).

const LIST_SIZE := Vector2(250, 200)
## Filtry rodzaju i sortowanie ofert przedmiotów.
const FILTERS := [["all", "Wszystko"], ["weapon", "Broń"], ["armor", "Zbroja"], ["jewelry", "Biżuteria"], ["gem", "Kamienie"],
		["legendary", "Legendy"]]
const SORTS := [["deal", "Największa okazja"], ["price", "Cena rosnąco"], ["price_desc", "Cena malejąco"], ["level", "Poziom"]]
const ARMOR_SLOTS := ["helmet", "chest", "gloves", "boots", "belt"]
const SIDE_WIDTH := 230.0
const UP := Color(0.55, 1.0, 0.55)
const DOWN := Color(1.0, 0.5, 0.45)

var _player: Player
var _tab := "goods"
var _selected := "wood"
var _bag_index := -1
var _tabs := {}
var _list: VBoxContainer
var _side: VBoxContainer
var _status: Label
var _gold: Label
var _qty: SpinBox
var _price: SpinBox
var _filter := "all"
var _sort := "deal"
var _for_me := false


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(tr("Rynek gildii")))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	box.add_child(tabs)
	for entry: Array in [["goods", tr("Towary")], ["items", tr("Przedmioty")], ["mine", tr("Moje oferty")]]:
		var button := _button(entry[1], _show.bind(entry[0]))
		button.toggle_mode = true
		_tabs[entry[0]] = button
		tabs.add_child(button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = LIST_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 1)
	scroll.add_child(_list)
	var side_panel := PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 4))
	side_panel.custom_minimum_size = Vector2(SIDE_WIDTH, LIST_SIZE.y)
	row.add_child(side_panel)
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(side_scroll)
	_side = VBoxContainer.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.add_theme_constant_override("separation", 2)
	side_scroll.add_child(_side)
	_qty = _spin(1, 9999)
	_price = _spin(1, 999999)
	var bottom := HBoxContainer.new()
	_gold = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	bottom.add_child(_gold)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_status)
	bottom.add_child(_button(tr("Zamknij"), func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.market.changed.connect(func() -> void:
		if visible:
			_refresh())
	player.stats.gold_changed.connect(func(_g: int) -> void:
		if visible:
			_gold.text = tr("%d zł") % _player.stats.gold)


func open() -> void:
	visible = true
	_status.text = ""
	_player.market.ensure()
	if _player.market.listings.filter(func(l: Dictionary) -> bool: return not l.get("mine", false)).is_empty():
		_player.market.refresh_listings(true)
	_show(_tab)
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func _spin(low: int, high: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.custom_minimum_size = Vector2(70, 0)
	spin.add_theme_font_size_override("font_size", 8)
	spin.get_line_edit().add_theme_font_size_override("font_size", 8)
	return spin


## Przycisk; gotowy napis tłumaczy sam (napisy z danymi trzeba przetłumaczyć wcześniej).
func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = tr(text)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	return button


func _show(tab: String) -> void:
	_tab = tab
	for key: String in _tabs:
		_tabs[key].set_pressed_no_signal(key == tab)
	_refresh()


func _clear(container: Control) -> void:
	# pola ilości i ceny przenosimy między odświeżeniami, nie niszczymy
	for spin: SpinBox in [_qty, _price]:
		if spin.get_parent() != null and container.is_ancestor_of(spin):
			spin.get_parent().remove_child(spin)
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _refresh() -> void:
	if _player == null:
		return
	_clear(_list)
	_clear(_side)
	_gold.text = tr("%d zł") % _player.stats.gold
	match _tab:
		"goods":
			_build_goods()
		"items":
			_build_items()
		"mine":
			_build_mine()


func _say(text: String, ok := true) -> void:
	_status.text = tr(text)
	_status.add_theme_color_override("font_color", UP if ok else DOWN)
	Sfx.play("coins" if ok else "ui_error")


func _icon_row(id: String, text: String, color: Color, action: Callable, pressed := false) -> Button:
	var button := _button(text, action)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = Items.get_data(id).get("icon")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 14)
	button.add_theme_color_override("font_color", color)
	button.toggle_mode = true
	button.set_pressed_no_signal(pressed)
	button.clip_text = true
	button.custom_minimum_size.x = LIST_SIZE.x - 12.0
	return button


# ---------------------------------------------------------------- towary
func _build_goods() -> void:
	var market := _player.market
	for category: String in Market.CATEGORIES:
		_list.add_child(UiStyle.label(tr(category), 8, UiStyle.TITLE_COLOR))
		for id: String in Market.CATEGORIES[category]:
			var change := market.trend(id)
			var arrow := "▲" if change > 0.02 else "▼" if change < -0.02 else "•"
			var row := _icon_row(id, tr("%s  %d zł %s%d%%") % [tr(Items.get_data(id)["name"]), market.price_of(id), arrow, roundi(absf(change) * 100.0)],
					UP if change > 0.02 else DOWN if change < -0.02 else UiStyle.TEXT_COLOR, _select_good.bind(id), id == _selected)
			row.tooltip_text = Items.describe(id)
			UiStyle.rich_tooltip(row)
			_list.add_child(row)
	_build_good_side()


func _select_good(id: String) -> void:
	_selected = id
	_price.value = _player.market.price_of(id)
	Sfx.play("ui_click")
	_refresh()


func _build_good_side() -> void:
	var market := _player.market
	var id := _selected
	_side.add_child(UiStyle.label(tr(Items.get_data(id)["name"]), 9, UiStyle.TITLE_COLOR))
	_side.add_child(UiStyle.label(tr("Cena rynkowa: %d zł   Masz: %d") % [market.price_of(id), _player.inventory.count_of(id)], 7, UiStyle.TEXT_COLOR))
	var book := market.book(id)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	_side.add_child(grid)
	var sells: Array = book["sell"].slice(0, 5)
	sells.reverse()
	for level: Array in sells:
		_book_row(grid, level, DOWN)
	for level: Array in book["buy"].slice(0, 5):
		_book_row(grid, level, UP)
	var fields := HBoxContainer.new()
	fields.add_theme_constant_override("separation", 3)
	fields.add_child(UiStyle.label(tr("Ilość"), 7))
	fields.add_child(_qty)
	fields.add_child(UiStyle.label(tr("Cena"), 7))
	fields.add_child(_price)
	_side.add_child(fields)
	if _price.value <= 1:
		_price.value = market.price_of(id)
	var qty := int(_qty.value)
	var cost := market.quote_buy(id, qty)
	var gain := market.quote_sell(id, qty)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 3)
	actions.add_theme_constant_override("v_separation", 2)
	_side.add_child(actions)
	var buy := _button(tr("Kup od razu (%s)") % (tr("%d zł") % cost if cost >= 0 else tr("brak")), func() -> void: _result(market.buy_now(id, int(_qty.value)), tr("Kupiono.")))
	buy.disabled = cost < 0 or _player.stats.gold < cost
	actions.add_child(buy)
	var sell := _button(tr("Sprzedaj od razu (%s)") % (tr("%d zł") % gain if gain >= 0 else tr("brak")), func() -> void: _result(market.sell_now(id, int(_qty.value)), tr("Sprzedano (podatek %d%%).") % roundi(Market.TAX * 100.0)))
	sell.disabled = gain < 0 or _player.inventory.count_of(id) < qty
	actions.add_child(sell)
	actions.add_child(_button("Wystaw sprzedaż", func() -> void: _result(market.place_sell(id, int(_qty.value), int(_price.value)), "Wystawiono - podróżnicy kupią z czasem.")))
	actions.add_child(_button("Zamów kupno", func() -> void: _result(market.place_buy(id, int(_qty.value), int(_price.value)), "Zamówienie złożone - złoto czeka na rynku.")))
	var hint := UiStyle.label(tr("Zamówienie po lepszej cenie niż rynek realizuje się szybciej. Podatek od sprzedaży: %d%%.") % roundi(Market.TAX * 100.0), 7, UiStyle.DIM_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = SIDE_WIDTH - 12.0
	_side.add_child(hint)
	if not _qty.value_changed.is_connected(_on_qty_changed):
		_qty.value_changed.connect(_on_qty_changed)


func _on_qty_changed(_value: float) -> void:
	if visible and _tab == "goods":
		_refresh()


func _book_row(grid: GridContainer, level: Array, color: Color) -> void:
	grid.add_child(UiStyle.label(tr("%d zł") % level[0], 7, color))
	grid.add_child(UiStyle.label("x%d" % level[1], 7, UiStyle.TEXT_COLOR))
	var is_fresh := level.size() > 3
	var who := UiStyle.label((tr("%s - świeże") % level[2]) if is_fresh else WorldEvents.who(str(level[2])), 7,
			Color(0.55, 1.0, 0.6) if level[2] == "Ty" else Color(1.0, 0.8, 0.45) if is_fresh else UiStyle.DIM_COLOR)
	if is_fresh:
		who.tooltip_text = tr("Świeży towar prosto z krainy (zbieracz: %s). Taniej, ale szybko znika.") % level[2]
		who.mouse_filter = Control.MOUSE_FILTER_STOP
	who.clip_text = true
	who.custom_minimum_size.x = 100
	grid.add_child(who)


func _result(message: String, done: String) -> void:
	if message == "":
		_say(done)
	else:
		_say(message, false)
	_refresh()


# ---------------------------------------------------------------- przedmioty
## Czy oferta pasuje do filtra rodzaju i przełącznika „Dla mnie”.
func matches(id: String, filter: String, for_me: bool) -> bool:
	var data := Items.get_data(id)
	var slot: String = data.get("slot", "")
	var ok := true
	match filter:
		"weapon":
			ok = slot == "weapon"
		"armor":
			ok = slot in ARMOR_SLOTS
		"jewelry":
			ok = slot in ["ring", "earring", "necklace"]
		"gem":
			ok = Gems.is_gem(id) or Essences.is_essence(id)
		"legendary":
			ok = data.get("rarity", "") == "legendary"
	if ok and for_me:
		ok = Items.is_equippable(id) and Items.item_level(id) <= _player.stats.level \
				and (slot != "weapon" or data.get("weapon", {}).get("type", "") == _player.stats.weapon_type())
	return ok


## Oferty podróżników po filtrze i sortowaniu.
func shown_listings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for listing: Dictionary in _player.market.listings:
		if not listing.get("mine", false) and matches(listing["id"], _filter, _for_me):
			result.append(listing)
	match _sort:
		"deal":
			result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Market.deal_of(a) > Market.deal_of(b))
		"price":
			result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["price"]) < int(b["price"]))
		"price_desc":
			result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["price"]) > int(b["price"]))
		"level":
			result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Items.item_level(a["id"]) > Items.item_level(b["id"]))
	return result


func _option(entries: Array, current: String, on_pick: Callable) -> OptionButton:
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.add_theme_font_size_override("font_size", 7)
	for i in entries.size():
		option.add_item(tr(entries[i][1]), i)
		if entries[i][0] == current:
			option.select(i)
	option.item_selected.connect(func(index: int) -> void:
		on_pick.call(entries[index][0])
		Sfx.play("ui_click")
		_refresh())
	return option


func _build_items() -> void:
	var market := _player.market
	var all_count := market.listings.filter(func(l: Dictionary) -> bool: return not l.get("mine", false)).size()
	var shown := shown_listings()
	var head := UiStyle.label(tr("Oferty podróżników: %d/%d (podróżników: %d)") % [shown.size(), all_count, market.traveler_count()], 8, UiStyle.TITLE_COLOR)
	head.tooltip_text = tr("Im więcej podróżników w gildii, tym więcej ofert i lepsze przedmioty. Okazje szybko wykupują inni!")
	head.mouse_filter = Control.MOUSE_FILTER_STOP
	_list.add_child(head)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 2)
	controls.add_child(_option(FILTERS, _filter, func(value: String) -> void: _filter = value))
	controls.add_child(_option(SORTS, _sort, func(value: String) -> void: _sort = value))
	var mine := CheckBox.new()
	mine.text = tr("Dla mnie")
	mine.focus_mode = Control.FOCUS_NONE
	mine.add_theme_font_size_override("font_size", 7)
	mine.button_pressed = _for_me
	mine.tooltip_text = tr("Tylko rzeczy, które możesz założyć: broń twojego obecnego rodzaju, poziom nie wyższy niż twój.")
	mine.toggled.connect(func(on: bool) -> void:
		_for_me = on
		Sfx.play("ui_click")
		_refresh())
	controls.add_child(mine)
	_list.add_child(controls)
	if shown.is_empty():
		_list.add_child(UiStyle.label(tr("Brak ofert - zmień filtr albo zajrzyj później."), 7, UiStyle.DIM_COLOR))
	for listing: Dictionary in shown:
		var id: String = listing["id"]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 2)
		var row := _icon_row(id, tr(Items.get_data(id)["name"]), Items.rarity_color(id), func() -> void: pass)
		row.custom_minimum_size.x = LIST_SIZE.x - 120.0
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.clip_text = true
		row.toggle_mode = false
		row.tooltip_text = tr("%s\n\nSprzedaje: %s\nUczciwa cena: ok. %d zł") % [Items.describe(id), WorldEvents.who(listing["seller"]), Market.fair_price(id)]
		UiStyle.rich_tooltip(row)
		line.add_child(row)
		var price := UiStyle.label(tr("%d zł") % listing["price"], 7, Color(1.0, 0.85, 0.3))
		price.custom_minimum_size.x = 40
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(price)
		var deal := Market.deal_of(listing)
		var tag := UiStyle.label("%+d%%" % -roundi(deal * 100.0), 7, UP if deal >= 0.1 else DOWN if deal <= -0.1 else UiStyle.DIM_COLOR)
		tag.custom_minimum_size.x = 26
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag.tooltip_text = tr("Okazja! Taniej o %d%% od uczciwej ceny - szybko zniknie.") % roundi(deal * 100.0) if deal >= 0.1 \
				else tr("Cena względem uczciwej wartości.")
		tag.mouse_filter = Control.MOUSE_FILTER_STOP
		line.add_child(tag)
		var buy := _button(tr("Kup"), func() -> void: _result(market.buy_listing(market.listings.find(listing)), tr("Kupiono: %s") % tr(Items.get_data(id)["name"])))
		buy.disabled = _player.stats.gold < int(listing["price"])
		line.add_child(buy)
		_list.add_child(line)
	_side.add_child(UiStyle.label(tr("Wystaw z plecaka"), 9, UiStyle.TITLE_COLOR))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_side.add_child(grid)
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if slot.is_empty() or not (Items.is_equippable(slot["id"]) or Gems.is_gem(slot["id"]) or Essences.is_essence(slot["id"])):
			continue
		var pick := Button.new()
		pick.focus_mode = Control.FOCUS_NONE
		pick.custom_minimum_size = Vector2(22, 22)
		pick.icon = Items.get_data(slot["id"])["icon"]
		pick.expand_icon = true
		pick.toggle_mode = true
		pick.set_pressed_no_signal(i == _bag_index)
		pick.tooltip_text = Items.describe(slot["id"], int(slot.get("enchant", 0)))
		UiStyle.rich_tooltip(pick)
		pick.pressed.connect(func() -> void:
			_bag_index = i
			_price.value = Market.fair_price(slot["id"])
			_refresh())
		grid.add_child(pick)
	if _bag_index >= 0 and _bag_index < _player.inventory.slots.size() and not _player.inventory.slots[_bag_index].is_empty():
		var id: String = _player.inventory.slots[_bag_index]["id"]
		_side.add_child(UiStyle.label(tr(Items.get_data(id)["name"]), 8, Items.rarity_color(id)))
		_side.add_child(UiStyle.label(tr("Uczciwa cena: ok. %d zł") % Market.fair_price(id), 7, UiStyle.DIM_COLOR))
		var fields := HBoxContainer.new()
		fields.add_child(UiStyle.label(tr("Cena"), 7))
		fields.add_child(_price)
		_side.add_child(fields)
		_side.add_child(_button("Wystaw na rynku", func() -> void:
			var message := market.list_item(_bag_index, int(_price.value))
			_bag_index = -1
			_result(message, "Wystawiono - kupiec znajdzie się z czasem.")))
	else:
		_side.add_child(UiStyle.label(tr("Kliknij przedmiot, żeby ustalić cenę."), 7, UiStyle.DIM_COLOR))


# ---------------------------------------------------------------- moje
func _build_mine() -> void:
	var market := _player.market
	_list.add_child(UiStyle.label(tr("Zamówienia towarów"), 8, UiStyle.TITLE_COLOR))
	if market.orders.is_empty():
		_list.add_child(UiStyle.label(tr("Brak zamówień."), 7, UiStyle.DIM_COLOR))
	for i in market.orders.size():
		var order: Dictionary = market.orders[i]
		var done := int(order["qty"]) - int(order["left"])
		var text := (tr("Sprzedaż: %s %d/%d po %d zł") if order["kind"] == "sell" else tr("Kupno: %s %d/%d po %d zł")) % [tr(Items.get_data(order["id"])["name"]),
				done, order["qty"], order["price"]]
		var line := HBoxContainer.new()
		var label := UiStyle.label(text, 7, UiStyle.TEXT_COLOR)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		line.add_child(label)
		if int(order["ready"]) > 0:
			line.add_child(_button(tr("Odbierz %d") % order["ready"], func() -> void:
				market.collect(i)
				_refresh()))
		line.add_child(_button(tr("Wycofaj"), func() -> void:
			market.cancel(i)
			_say("Zamówienie wycofane.")
			_refresh()))
		_list.add_child(line)
	_side.add_child(UiStyle.label(tr("Moje przedmioty na rynku"), 8, UiStyle.TITLE_COLOR))
	var any := false
	for i in market.listings.size():
		var listing: Dictionary = market.listings[i]
		if not listing.get("mine", false):
			continue
		any = true
		var line := HBoxContainer.new()
		var label := UiStyle.label(tr("%s - %d zł") % [tr(Items.get_data(listing["id"])["name"]), listing["price"]], 7, Items.rarity_color(listing["id"]))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		line.add_child(label)
		line.add_child(_button(tr("Wycofaj"), func() -> void: _result(market.unlist(i), "Przedmiot wrócił do plecaka.")))
		_side.add_child(line)
	if not any:
		_side.add_child(UiStyle.label(tr("Nic nie wystawiono."), 7, UiStyle.DIM_COLOR))
