class_name ShopWindow
extends PanelContainer
## Okno handlu z kupcem: zakup jego towarów i sprzedaż wszystkiego, co ma wartość
## (łupy, mikstury, ekwipunek z plecaka). Zamyka się samo, gdy gracz odejdzie od kupca.

const CLOSE_DISTANCE := 60.0

var _player: Player
var _merchant: Npc
var _title: Label
var _buy_list: VBoxContainer
var _sell_list: VBoxContainer
var _gold_label: Label
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	custom_minimum_size.x = 240

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_title = UiStyle.title("Handel")
	box.add_child(_title)

	box.add_child(UiStyle.label("Kup", 8, UiStyle.TITLE_COLOR))
	_buy_list = VBoxContainer.new()
	box.add_child(_scroll(_buy_list, 116))
	box.add_child(HSeparator.new())
	box.add_child(UiStyle.label("Sprzedaj", 8, UiStyle.TITLE_COLOR))
	_sell_list = VBoxContainer.new()
	box.add_child(_scroll(_sell_list, 64))
	box.add_child(HSeparator.new())

	var bottom := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_gold_label)
	var close_button := _button("Zamknij", close)
	bottom.add_child(close_button)
	box.add_child(bottom)

	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)


func setup(player: Player) -> void:
	_player = player
	player.shop_requested.connect(open)
	player.inventory.changed.connect(_refresh)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh())


func open(merchant: Npc) -> void:
	_merchant = merchant
	_title.text = merchant.display_name if merchant.display_name != "" else "Handel"
	_status.text = ""
	visible = true
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func close() -> void:
	visible = false
	_merchant = null


func _process(_delta: float) -> void:
	if visible and (_merchant == null or _player.is_dead \
			or _player.global_position.distance_to(_merchant.global_position) > CLOSE_DISTANCE):
		close()


func _refresh() -> void:
	if not visible or _merchant == null:
		return
	for child in _buy_list.get_children() + _sell_list.get_children():
		child.queue_free()

	var gold := _player.stats.gold
	for id in _merchant.shop_sells:
		var item := Items.get_data(id)
		var price: int = _player.boons.discounted(int(item["price"]))
		var row := _item_row(id, "%s - %d zł" % [item["name"], price])
		var buy := _button("Kup", _buy.bind(id))
		buy.disabled = gold < price
		row.add_child(buy)
		_buy_list.add_child(row)

	# przedmioty w stosach grupujemy, a ekwipunek (także zaklęty) pokazujemy sztuka po sztuce
	var sellable: Array[String] = []
	var single_items: Array[int] = []
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if slot.is_empty() or not Items.get_data(slot["id"]).has("sell_price"):
			continue
		if Items.max_stack(slot["id"]) == 1:
			single_items.append(i)
		elif not slot["id"] in sellable:
			sellable.append(slot["id"])
	if sellable.is_empty() and single_items.is_empty():
		_sell_list.add_child(UiStyle.label("Nie masz nic na sprzedaż.", 8, UiStyle.DIM_COLOR))
	for index in single_items:
		var slot: Dictionary = _player.inventory.slots[index]
		var enchant: int = slot.get("enchant", 0)
		var row := _item_row(slot["id"], "%s - %d zł" % [Items.display_name(slot["id"], enchant), _price_of(slot["id"], enchant)], enchant)
		row.add_child(_button("Sprzedaj", _sell_slot.bind(index)))
		_sell_list.add_child(row)
	for id in sellable:
		var item := Items.get_data(id)
		var count := _player.inventory.count_of(id)
		var row := _item_row(id, "%s x%d - %d zł/szt." % [item["name"], count, item["sell_price"]])
		var sell_one := _button("1", _sell.bind(id, 1))
		var sell_all := _button("Wszystkie", _sell.bind(id, -1))
		sell_one.disabled = count == 0
		sell_all.disabled = count == 0
		row.add_child(sell_one)
		row.add_child(sell_all)
		_sell_list.add_child(row)

	_gold_label.text = "%d złota" % gold


func _scroll(content: Control, height: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = height
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


func _item_row(id: String, text: String, enchant := 0) -> HBoxContainer:
	var item := Items.get_data(id)
	var row := HBoxContainer.new()
	UiStyle.rich_tooltip(row)
	row.add_theme_constant_override("separation", 4)
	row.tooltip_text = Items.tooltip(id, enchant)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon := TextureRect.new()
	icon.texture = item["icon"]
	UiStyle.fit_icon(icon)
	icon.custom_minimum_size = Vector2(16, 16)
	row.add_child(icon)
	UiStyle.set_item_frame(icon, id)
	var label := UiStyle.label(text, 8, Items.rarity_color(id))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	UiStyle.rich_tooltip(label)
	label.tooltip_text = Items.tooltip(id, enchant)
	row.add_child(label)
	return row


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.custom_minimum_size = Vector2(18, 14)
	button.pressed.connect(on_pressed)
	return button


func _buy(id: String) -> void:
	var price: int = _player.boons.discounted(int(Items.get_data(id)["price"]))
	if _player.stats.gold < price:
		_set_status("Za mało złota!", Color(1, 0.4, 0.4))
		Sfx.play("ui_error")
		return
	if not _player.inventory.can_add(id, 1):
		_set_status("Ekwipunek pełny!", Color(1, 0.4, 0.4))
		Sfx.play("ui_error")
		return
	_player.stats.add_gold(-price)
	Sfx.play("coins")
	_player.inventory.add_item(id, 1)
	var hint := " - załóż w ekwipunku (I)" if Items.is_equippable(id) else ""
	_set_status("Kupiono: %s%s" % [Items.get_data(id)["name"], hint], Color(0.6, 1, 0.55))


## amount -1 = wszystkie sztuki.
func _sell(id: String, amount: int) -> void:
	var count := _player.inventory.count_of(id)
	if amount < 0:
		amount = count
	if amount == 0 or not _player.inventory.remove_item(id, amount):
		return
	var earned: int = Items.get_data(id)["sell_price"] * amount
	_player.stats.add_gold(earned)
	Sfx.play("coins")
	_set_status("Sprzedano %d szt. za %d zł" % [amount, earned], Color(1.0, 0.85, 0.3))


## Cena skupu - zaklęty przedmiot jest wart więcej.
func _price_of(id: String, enchant: int) -> int:
	return Items.get_data(id)["sell_price"] + Enchanting.bonus(enchant) * 3


func _sell_slot(index: int) -> void:
	var slot: Dictionary = _player.inventory.slots[index]
	if slot.is_empty():
		return
	var price := _price_of(slot["id"], slot.get("enchant", 0))
	var item_name := Items.display_name(slot["id"], slot.get("enchant", 0))
	_player.inventory.take_one(index)
	_player.stats.add_gold(price)
	Sfx.play("coins")
	_set_status("Sprzedano %s za %d zł" % [item_name, price], Color(1.0, 0.85, 0.3))


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
