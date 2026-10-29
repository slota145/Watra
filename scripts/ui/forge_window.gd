class_name ForgeWindow
extends PanelContainer
## Kuźnia: kowal wykuwa magiczny albo rzadki przedmiot na wybranej podstawie (z losowymi
## premiami - Loot, poziom łupu 2, czyli przedmioty poziomu 10-24). Płaci się złotem, rudą żelaza (z Wietrznych Turni), drewnem i trofeum z potworów:
## broń - serca goblinów, zbroje - skóry jeleni, biżuteria - żabie języki. Surowce z plecaka
## i magazynu.

const FORGE_LEVEL := 2
const ROW_WIDTH := 300.0
const LIST_HEIGHT := 230.0
const OK_COLOR := Color(0.6, 1.0, 0.55)
const MISSING_COLOR := Color(1.0, 0.45, 0.45)
const TROPHIES := {"weapon": "goblin_heart", "armor": "deer_hide", "jewelry": "frog_tongue"}

var _player: Player
var _list: VBoxContainer
var _gold_label: Label
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.14, 0.12, 0.12, 0.98), Color(0.85, 0.45, 0.2), 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Kuźnia - wykuwanie"))
	var hint := UiStyle.label("Kowal wykuje przedmiot z losowymi premiami. Magiczny: 1-2 premie, rzadki: 3-4.", 7, UiStyle.DIM_COLOR)
	hint.custom_minimum_size.x = ROW_WIDTH
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(ROW_WIDTH + 14.0, LIST_HEIGHT)
	scroll.add_child(_list)
	box.add_child(scroll)
	var bottom := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	bottom.add_child(_gold_label)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_status)
	var close_button := Button.new()
	close_button.text = "Zamknij"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.pressed.connect(func() -> void:
		visible = false
		Sfx.play("ui_close"))
	bottom.add_child(close_button)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()
	Sfx.play("ui_open")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


## Koszt wykucia: "gold" i surowce (id -> ilość).
static func cost(base: String, quality: String) -> Dictionary:
	var item := Items.get_data(base)
	var price: int = item.get("price", int(item.get("sell_price", 10)) * 3)
	var category := Enchanting.category(base)
	var rare := quality == Loot.RARE
	var result := {"gold": maxi(60, price * (5 if rare else 2)), "iron_ore": 25 if rare else 10}
	if category != "jewelry":
		result["wood"] = 15 if rare else 5
	result[TROPHIES[category]] = 10 if rare else 4
	return result


func _can_pay(price: Dictionary) -> bool:
	for id: String in price:
		var have := _player.stats.gold if id == "gold" else _player.count_owned(id)
		if have < int(price[id]):
			return false
	return true


func _refresh() -> void:
	if _player == null:
		return
	var scroll := _list.get_parent() as ScrollContainer
	var keep := scroll.scroll_vertical
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_gold_label.text = "%d" % _player.stats.gold
	for line: String in ItemBases.LINES:  # po jednej pozycji na linię (podstawa z pierwszego poziomu)
		_list.add_child(_row(ItemBases.LINES[line][0]))
	scroll.set_deferred("scroll_vertical", keep)


func _row(base: String) -> Control:
	var row := PanelContainer.new()
	UiStyle.rich_tooltip(row)
	row.tooltip_text = Items.describe(base)
	row.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	row.custom_minimum_size.x = ROW_WIDTH
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 1)
	row.add_child(content)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	content.add_child(header)
	var icon := TextureRect.new()
	icon.texture = Items.get_data(base)["icon"]
	UiStyle.fit_icon(icon)
	header.add_child(icon)
	header.add_child(UiStyle.label(Items.get_data(base)["name"], 8))
	for quality in [Loot.MAGIC, Loot.RARE]:
		content.add_child(_option(base, quality))
	return row


func _option(base: String, quality: String) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 2)
	var label := UiStyle.label(Items.RARITY_NAMES[quality], 7, Items.RARITY_COLORS[quality])
	label.custom_minimum_size.x = 46
	line.add_child(label)
	var price := cost(base, quality)
	for id: String in price:
		var icon := TextureRect.new()
		icon.texture = Items.GOLD_ICON if id == "gold" else Items.get_data(id)["icon"]
		UiStyle.fit_icon(icon)
		icon.tooltip_text = "Złoto" if id == "gold" else Items.get_data(id)["name"]
		line.add_child(icon)
		var have := _player.stats.gold if id == "gold" else _player.count_owned(id)
		line.add_child(UiStyle.label(str(price[id]), 7, OK_COLOR if have >= int(price[id]) else MISSING_COLOR))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(spacer)
	var button := Button.new()
	button.text = "Wykuj"
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.disabled = not _can_pay(price)
	button.pressed.connect(_forge.bind(base, quality))
	line.add_child(button)
	return line


func _forge(base: String, quality: String) -> void:
	var price := cost(base, quality)
	if not _can_pay(price) or not _player.inventory.can_add(base, 1):
		Sfx.play("ui_error")
		_status.text = "Brak surowców albo miejsca w plecaku"
		_status.add_theme_color_override("font_color", MISSING_COLOR)
		return
	for id: String in price:
		if id == "gold":
			_player.stats.add_gold(-int(price[id]))
		else:
			_player.take_owned(id, int(price[id]))
	var item_level := Loot.roll_item_level(FORGE_LEVEL)
	var item := Loot.generate(Loot.base_for(Items.get_data(base)["line"], item_level), quality, item_level)
	_player.inventory.add_item(item, 1)
	_player.item_picked.emit(item, 1)
	Sfx.play("anvil")
	Sfx.play("enchant_success")
	_status.text = "Wykuto: %s" % Items.get_data(item)["name"]
	_status.add_theme_color_override("font_color", Items.rarity_color(item))
	_refresh()
