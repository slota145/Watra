class_name WorkshopWindow
extends PanelContainer
## Warsztat kowala Bronisława (ItemCraft): po lewej przedmioty gracza (założone i z plecaka), po prawej zaznaczony
## przedmiot - jego premie (kliknięcie zaznacza premię) i działania z kosztem w złocie i trofeach potworów
## (przerzut wartości, przekucie, usunięcie, dodanie premii, ulepszenie rzadkości, Runa Zmiany, Pieczęć).

const LIST_SIZE := Vector2(200, 210)
const SIDE_WIDTH := 230.0

var _player: Player
## Zaznaczony przedmiot: {"equip": miejsce} albo {"inv": indeks w plecaku}; zaznaczona premia.
var _selected := {}
var _stat := ""
var _list: VBoxContainer
var _side: VBoxContainer
var _status: Label
var _gold: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Warsztat - rzemiosło premii"))
	var hint := UiStyle.label("Koszt: złoto i trofea potworów z krainy pasującej do poziomu przedmiotu. Legendy - 3 razy drożej. Runy wypadają w lochach.", 7, UiStyle.DIM_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = LIST_SIZE.x + SIDE_WIDTH + 4.0
	box.add_child(hint)
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
	var bottom := HBoxContainer.new()
	_gold = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	bottom.add_child(_gold)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_status)
	var close := Button.new()
	close.text = "Zamknij"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(func() -> void:
		visible = false
		Sfx.play("ui_close"))
	bottom.add_child(close)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	for source: Signal in [player.inventory.changed, player.equipment.changed, player.stats.gold_changed, player.storage.changed]:
		source.connect(func(_a = null) -> void:
			if visible:
				_refresh())


func open() -> void:
	visible = true
	_selected = {}
	_stat = ""
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: String in Equipment.SLOTS:
		if ItemCraft.can_craft(_player.equipment.get_item(slot)):
			result.append({"equip": slot})
	for i in _player.inventory.slots.size():
		if not _player.inventory.slots[i].is_empty() and ItemCraft.can_craft(_player.inventory.slots[i]["id"]):
			result.append({"inv": i})
	return result


func item_of(entry: Dictionary) -> String:
	if entry.has("equip"):
		return _player.equipment.get_item(entry["equip"])
	return _player.inventory.slots[entry["inv"]].get("id", "") if entry["inv"] < _player.inventory.slots.size() else ""


func enchant_of(entry: Dictionary) -> int:
	if entry.has("equip"):
		return _player.equipment.get_enchant(entry["equip"])
	return int(_player.inventory.slots[entry["inv"]].get("enchant", 0))


## Przedmiot dostał nowe id (zwykły przedmiot po pierwszym działaniu) albo zmienił przepis - podmiana i odświeżenie.
func _replace(entry: Dictionary, id: String) -> void:
	if entry.has("equip"):
		_player.equipment.items[entry["equip"]]["id"] = id
		_player.equipment.changed.emit()
	else:
		_player.inventory.slots[entry["inv"]]["id"] = id
		_player.inventory.changed.emit()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	return button


func _refresh() -> void:
	if _player == null:
		return
	for container: Control in [_list, _side]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	_gold.text = "%d zł" % _player.stats.gold
	var list := entries()
	if _selected.is_empty() or not list.has(_selected):
		_selected = list[0] if not list.is_empty() else {}
	for entry in list:
		var id := item_of(entry)
		var button := _button(("Założone: " if entry.has("equip") else "") + Items.display_name(id, enchant_of(entry)), func() -> void:
			_selected = entry
			_stat = ""
			Sfx.play("ui_click")
			_refresh())
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = Items.get_data(id).get("icon")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 14)
		button.add_theme_color_override("font_color", Items.rarity_color(id))
		button.toggle_mode = true
		button.set_pressed_no_signal(entry == _selected)
		button.clip_text = true
		button.custom_minimum_size.x = LIST_SIZE.x - 12.0
		button.tooltip_text = Items.describe(id, enchant_of(entry))
		UiStyle.rich_tooltip(button)
		_list.add_child(button)
	if _selected.is_empty():
		_side.add_child(UiStyle.label("Nie masz broni, zbroi ani biżuterii.", 7, UiStyle.DIM_COLOR))
		return
	_build_side(item_of(_selected))


func _build_side(id: String) -> void:
	var data := Items.get_data(id)
	var quality := ItemCraft.quality_of(id)
	_side.add_child(UiStyle.label(data["name"], 9, Items.rarity_color(id)))
	var affixes: Dictionary = data.get("recipe", {}).get("affixes", {})
	_side.add_child(UiStyle.label("%s, poz. %d - premie %d/%d (kliknij premię; tier 1 - najlepszy)" % [Items.RARITY_NAMES[quality],
			Items.item_level(id), affixes.size(), Loot.AFFIX_COUNTS[quality][1]], 7, UiStyle.DIM_COLOR))
	var tiers: Dictionary = data.get("recipe", {}).get("tiers", {})
	for stat: String in affixes:
		var tier := int(tiers.get(stat, 0))
		var span := Loot.tier_range(stat, maxi(tier, 1))
		var pick := _button("%s  (tier %d: %s-%s)" % [Items._stat_text(stat, affixes[stat]), tier,
				_num(stat, span[0]), _num(stat, span[1])], func() -> void:
			_stat = stat
			Sfx.play("ui_click")
			_refresh())
		pick.toggle_mode = true
		pick.set_pressed_no_signal(stat == _stat)
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_side.add_child(pick)
	_side.add_child(HSeparator.new())
	for action: String in ItemCraft.ORDER:
		var info: Dictionary = ItemCraft.ACTIONS[action]
		var price := ItemCraft.cost(id, action)
		var parts: Array[String] = ["%d zł" % price["gold"]]
		for item: String in price["items"]:
			parts.append("%s %d/%d" % [Items.get_data(item)["name"], mini(_player.count_owned(item), price["items"][item]), price["items"][item]])
		var reason := ItemCraft.check(id, action, _stat)
		var button := _button("%s - %s" % [info["name"], ", ".join(parts)], _do.bind(action))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.custom_minimum_size.x = SIDE_WIDTH - 14.0
		button.disabled = reason != "" or not ItemCraft.afford(_player, id, action)
		button.tooltip_text = info["description"] + ("\n" + reason if reason != "" else "")
		_side.add_child(button)


func _num(stat: String, value: float) -> String:
	if stat in Items.PERCENT_STATS:
		return "%d%%" % roundi(value * 100.0)
	return str(snappedf(value, 0.1)) if Loot._step(stat) > 0.0 else str(roundi(value))


func _do(action: String) -> void:
	var entry := _selected
	var id := item_of(entry)
	var reason := ItemCraft.check(id, action, _stat)
	if reason != "" or not ItemCraft.afford(_player, id, action):
		_status.text = reason if reason != "" else "Brakuje złota albo materiałów."
		Sfx.play("ui_error")
		return
	var price := ItemCraft.cost(id, action)
	var result := ItemCraft.apply(id, action, _stat)
	if result.is_empty():
		Sfx.play("ui_error")
		return
	_player.stats.add_gold(-int(price["gold"]))
	for item: String in price["items"]:
		_player.take_owned(item, int(price["items"][item]))
	if action == "remove":
		_stat = ""
	_replace(entry, result["id"])
	Sfx.play("anvil")
	_status.text = result["text"]
	_refresh()
