class_name SageWindow
extends PanelContainer
## Mędrzec odczarowuje przedmioty za złoto: zaklęcie wraca do +0, a gracz odzyskuje kamienie,
## które dały kolejne poziomy - po jednym zwykłym kamieniu za poziomy +1..+15 i po jednym
## doskonałym za poziomy I..V (kategoria kamienia jak przedmiotu). Kamienie uświęcone,
## miłosierdzia i te stracone na nieudanych próbach nie wracają.
## Lista obejmuje zaklęte przedmioty z plecaka i założone na postać.

const COST_PER_NORMAL := 30
const COST_PER_PERFECT := 150
const LIST_HEIGHT := 220.0
const ROW_WIDTH := 290.0

var _player: Player
var _list: VBoxContainer
var _gold_label: Label
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.1, 0.2, 0.98), Color(0.54, 0.4, 0.78), 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Odczarowanie"))
	var hint := UiStyle.label("Mędrzec zdejmuje zaklęcie i oddaje kamienie, które dały kolejne poziomy.", 7, UiStyle.DIM_COLOR)
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
	player.inventory.changed.connect(_refresh_if_open)
	player.equipment.changed.connect(_refresh_if_open)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh_if_open())


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()
	Sfx.play("ui_book")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


## Kamienie odzyskane z przedmiotu na danym poziomie: [zwykłe, doskonałe].
static func refund(level: int) -> Array[int]:
	return [mini(level, Enchanting.MAX_NORMAL), maxi(0, level - Enchanting.MAX_NORMAL)]


static func cost(level: int) -> int:
	var stones := refund(level)
	return stones[0] * COST_PER_NORMAL + stones[1] * COST_PER_PERFECT


func _refresh_if_open() -> void:
	if visible:
		_refresh()


## Zaklęte przedmioty: [opis miejsca, id, poziom, Callable zerujący zaklęcie].
func _enchanted() -> Array:
	var result := []
	for slot: String in Equipment.SLOTS:
		var id := _player.equipment.get_item(slot)
		var level := _player.equipment.get_enchant(slot)
		if id != "" and level > 0:
			result.append(["założony", id, level, _player.equipment.set_enchant.bind(slot, 0)])
	for i in _player.inventory.slots.size():
		var data: Dictionary = _player.inventory.slots[i]
		if not data.is_empty() and int(data.get("enchant", 0)) > 0:
			result.append(["w plecaku", data["id"], int(data["enchant"]), _clear_bag_slot.bind(i)])
	return result


func _clear_bag_slot(index: int) -> void:
	_player.inventory.slots[index]["enchant"] = 0
	_player.inventory.changed.emit()


func _refresh() -> void:
	if _player == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_gold_label.text = "%d" % _player.stats.gold
	var items := _enchanted()
	if items.is_empty():
		var empty := UiStyle.label("Nie masz żadnych zaklętych przedmiotów.", 8, UiStyle.DIM_COLOR)
		empty.custom_minimum_size.x = ROW_WIDTH
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for entry: Array in items:
		_list.add_child(_row(entry))


func _row(entry: Array) -> Control:
	var id: String = entry[1]
	var level: int = entry[2]
	var row := PanelContainer.new()
	UiStyle.rich_tooltip(row)
	row.tooltip_text = Items.describe(id, level)
	row.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	row.custom_minimum_size.x = ROW_WIDTH
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	row.add_child(line)
	var icon := TextureRect.new()
	icon.texture = Items.get_data(id)["icon"]
	UiStyle.fit_icon(icon)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(icon)
	UiStyle.set_item_frame(icon, id)

	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 0)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(middle)
	var name_color := Items.rarity_color(id)
	middle.add_child(UiStyle.label("%s  (%s)" % [Items.display_name(id, level), entry[0]], 8, name_color))
	var back := HBoxContainer.new()
	back.add_theme_constant_override("separation", 2)
	back.add_child(UiStyle.label("Zwrot:", 7, UiStyle.DIM_COLOR))
	var stones := refund(level)
	var category := Enchanting.category(id)
	for perfect in [false, true]:
		var amount: int = stones[1 if perfect else 0]
		if amount == 0:
			continue
		var stone_icon := TextureRect.new()
		stone_icon.texture = Items.get_data(Enchanting.stone_id(category, perfect))["icon"]
		UiStyle.fit_icon(stone_icon)
		stone_icon.tooltip_text = Items.get_data(Enchanting.stone_id(category, perfect))["name"]
		back.add_child(stone_icon)
		back.add_child(UiStyle.label("x%d" % amount, 7, Color(0.6, 1.0, 0.55)))
	middle.add_child(back)

	var price := cost(level)
	var button := Button.new()
	button.text = "Odczaruj - %d zł" % price
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 8)
	button.disabled = _player.stats.gold < price
	button.pressed.connect(_disenchant.bind(entry))
	line.add_child(button)
	return row


func _disenchant(entry: Array) -> void:
	var id: String = entry[1]
	var level: int = entry[2]
	var price := cost(level)
	if _player.stats.gold < price:
		Sfx.play("ui_error")
		return
	_player.stats.add_gold(-price)
	var stones := refund(level)
	var category := Enchanting.category(id)
	for perfect in [false, true]:
		var amount: int = stones[1 if perfect else 0]
		if amount == 0:
			continue
		var stone := Enchanting.stone_id(category, perfect)
		var left := _player.inventory.add_item(stone, amount)
		if left > 0:  # plecak pełny - reszta trafia do magazynu
			_player.storage.add_item(stone, left)
		_player.item_picked.emit(stone, amount)
	(entry[3] as Callable).call()
	Sfx.play("coins")
	Sfx.play("enchant_drop")
	_status.text = "Odczarowano: %s" % Items.get_data(id)["name"]
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
	_refresh()
