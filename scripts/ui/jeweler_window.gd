class_name JewelerWindow
extends PanelContainer
## Okno jubilera Dobromira (Orla Przełęcz, Gems): po lewej przedmioty gracza (założone i z plecaka) z gniazdami,
## po prawej zaznaczony przedmiot - dorobienie gniazda (za złoto; pierwsze za darmo po zadaniu), osadzenie kamienia
## z plecaka w pustym gnieździe albo wyjęcie kamienia (za darmo - wraca do plecaka). Na dole łączenie: trzy kamienie
## tego samego szlifu -> jeden lepszego szlifu.

const LIST_SIZE := Vector2(210, 190)
const DETAILS_WIDTH := 200.0

var _player: Player
## Zaznaczony przedmiot: {"equip": miejsce} albo {"inv": indeks w plecaku}.
var _selected := {}
var _list: VBoxContainer
var _details: RichTextLabel
var _actions: VBoxContainer
var _combine: HBoxContainer
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Jubiler Dobromir - klejnoty"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = LIST_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 4))
	side.custom_minimum_size = Vector2(DETAILS_WIDTH, LIST_SIZE.y)
	row.add_child(side)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	side.add_child(column)
	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.fit_content = true
	_details.custom_minimum_size.x = DETAILS_WIDTH - 10.0
	_details.add_theme_font_size_override("normal_font_size", 8)
	_details.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	column.add_child(_details)
	var actions_scroll := ScrollContainer.new()
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(actions_scroll)
	_actions = VBoxContainer.new()
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override("separation", 2)
	actions_scroll.add_child(_actions)
	box.add_child(UiStyle.label("Łączenie: trzy kamienie tego samego szlifu dają jeden lepszy (rodzaj jednego z nich)", 7, UiStyle.DIM_COLOR))
	_combine = HBoxContainer.new()
	_combine.add_theme_constant_override("separation", 3)
	box.add_child(_combine)
	var bottom := HBoxContainer.new()
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	bottom.add_child(_button("Zamknij", func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	for source: Signal in [player.inventory.changed, player.equipment.changed, player.stats.gold_changed]:
		source.connect(func(_a = null) -> void:
			if visible:
				_refresh())


func open() -> void:
	visible = true
	_selected = {}
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func toggle() -> void:
	visible = not visible
	if visible:
		open()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	return button


## Przedmioty, które jubiler obsługuje: założone i z plecaka (broń, zbroja, biżuteria bez legend).
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: String in Equipment.SLOTS:
		var id := _player.equipment.get_item(slot)
		if id != "" and (Gems.can_socket(id) or not Gems.sockets_of(id).is_empty()):
			result.append({"equip": slot})
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if not slot.is_empty() and (Gems.can_socket(slot["id"]) or not Gems.sockets_of(slot["id"]).is_empty()):
			result.append({"inv": i})
	return result


func item_of(entry: Dictionary) -> String:
	if entry.has("equip"):
		return _player.equipment.get_item(entry["equip"])
	var slot: Dictionary = _player.inventory.slots[entry["inv"]] if entry["inv"] < _player.inventory.slots.size() else {}
	return slot.get("id", "")


## Podmienia przedmiot (zwykły przedmiot po dorobieniu gniazda dostaje nowe id).
func _replace(entry: Dictionary, id: String) -> void:
	if entry.has("equip"):
		_player.equipment.items[entry["equip"]]["id"] = id
		_player.equipment.changed.emit()
	else:
		_player.inventory.slots[entry["inv"]]["id"] = id
		_player.inventory.changed.emit()


func _refresh() -> void:
	if _player == null:
		return
	for child in _list.get_children() + _actions.get_children() + _combine.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var list := entries()
	if _selected.is_empty() or not list.has(_selected):
		_selected = list[0] if not list.is_empty() else {}
	for entry in list:
		_list.add_child(_row(entry))
	_show_selected()
	_build_combine()


func _row(entry: Dictionary) -> Button:
	var id := item_of(entry)
	var sockets := Gems.sockets_of(id)
	var marks := ""
	for gem: Dictionary in sockets:
		marks += " [%s]" % ("•" if not gem.is_empty() else " ")
	var button := _button(("Założone: " if entry.has("equip") else "") + Items.get_data(id)["name"] + marks, _select.bind(entry))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = Items.get_data(id).get("icon")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 14)
	button.add_theme_color_override("font_color", Items.rarity_color(id))
	button.toggle_mode = true
	button.set_pressed_no_signal(entry == _selected)
	button.tooltip_text = Items.describe(id)
	UiStyle.rich_tooltip(button)
	return button


func _select(entry: Dictionary) -> void:
	_selected = entry
	Sfx.play("ui_click")
	_refresh()


func _show_selected() -> void:
	if _selected.is_empty():
		_details.text = "Nie masz przedmiotów, w których mogę wydrążyć gniazdo albo osadzić kamień."
		return
	var id := item_of(_selected)
	var lines: Array[String] = ["[color=#%s]%s[/color]" % [Items.rarity_color(id).to_html(false), Items.get_data(id)["name"]]]
	var sockets := Gems.sockets_of(id)
	if sockets.is_empty():
		lines.append("Brak gniazda.")
		var price := 0 if _player.free_sockets > 0 else Gems.socket_price(id)
		var add := _button("Wydrąż gniazdo (%s)" % ("za darmo" if price == 0 else "%d zł" % price), _add_socket.bind(price))
		add.disabled = _player.stats.gold < price
		_actions.add_child(add)
	for i in sockets.size():
		var gem: Dictionary = sockets[i]
		lines.append(Gems.socket_text(gem))
		if not gem.is_empty():
			_actions.add_child(_button("Wyjmij kamień", _remove.bind(i)))
			continue
		var gems := _gems_in_bag()
		if gems.is_empty():
			lines.append("[color=#a6abbf]Nie masz kamieni szlachetnych do osadzenia.[/color]")
			continue
		lines.append("[color=#a6abbf]Kliknij kamień z plecaka, żeby go osadzić:[/color]")
		var grid := GridContainer.new()
		grid.columns = 8
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		_actions.add_child(grid)
		for index: int in gems:
			var gem_id: String = _player.inventory.slots[index]["id"]
			var put := Button.new()
			put.focus_mode = Control.FOCUS_NONE
			put.custom_minimum_size = Vector2(20, 20)
			put.icon = Items.get_data(gem_id)["icon"]
			put.expand_icon = true
			put.tooltip_text = "Osadź: " + Items.describe(gem_id)
			UiStyle.rich_tooltip(put)
			put.pressed.connect(_insert.bind(i, index))
			grid.add_child(put)
	_details.text = "\n".join(lines)


func _gems_in_bag() -> Array[int]:
	var result: Array[int] = []
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if not slot.is_empty() and Gems.is_gem(slot["id"]) and not Gems.is_radius(slot["id"]):
			result.append(i)
	return result


func _add_socket(price: int) -> void:
	var id := item_of(_selected)
	if not Gems.can_socket(id) or _player.stats.gold < price:
		Sfx.play("ui_error")
		return
	if price > 0:
		_player.stats.add_gold(-price)
	else:
		_player.free_sockets -= 1
	_replace(_selected, Gems.add_socket(id))
	Sfx.play("anvil", -4.0, 1.4)
	_status.text = "Gniazdo gotowe!"
	_refresh()


func _insert(socket: int, bag_index: int) -> void:
	var id := item_of(_selected)
	var gem_id: String = _player.inventory.slots[bag_index]["id"]
	_player.inventory.slots[bag_index] = {}
	Gems.insert(id, socket, gem_id)
	_replace(_selected, id)
	_player.inventory.changed.emit()
	Sfx.play("enchant_success")
	_status.text = "Kamień osadzony."
	_refresh()


func _remove(socket: int) -> void:
	var id := item_of(_selected)
	if not _player.inventory.slots.any(func(s: Dictionary) -> bool: return s.is_empty()):
		_status.text = "Plecak jest pełny."
		Sfx.play("ui_error")
		return
	var gem_id := Gems.remove(id, socket)
	_replace(_selected, id)
	_player.inventory.add_item(gem_id, 1)
	Sfx.play("pickup")
	_status.text = "Kamień wrócił do plecaka."
	_refresh()


## Przyciski łączenia dla szlifów, których gracz ma co najmniej 3 kamienie.
func _build_combine() -> void:
	var by_cut := {}
	for index in _gems_in_bag():
		var cut: int = Items.get_data(_player.inventory.slots[index]["id"])["gem"]["cut"]
		if cut < Gems.CUTS.size() - 1:
			by_cut[cut] = by_cut.get(cut, []) + [index]
	if by_cut.is_empty():
		_combine.add_child(UiStyle.label("Brak trzech kamieni tego samego szlifu.", 7, UiStyle.DIM_COLOR))
		return
	if not by_cut.values().any(func(list: Array) -> bool: return list.size() >= 3):
		_combine.add_child(UiStyle.label("Brak trzech kamieni tego samego szlifu.", 7, UiStyle.DIM_COLOR))
		return
	for cut: int in by_cut:
		if by_cut[cut].size() < 3:
			continue
		var price: int = Gems.COMBINE_GOLD[cut]
		var button := _button("3 × %s -> %s (%d zł)" % [Gems.CUTS[cut].to_lower(), Gems.CUTS[cut + 1].to_lower(), price],
				_combine_cut.bind(by_cut[cut].slice(0, 3), price))
		button.disabled = _player.stats.gold < price
		_combine.add_child(button)


func _combine_cut(indices: Array, price: int) -> void:
	if _player.stats.gold < price:
		return
	_player.stats.add_gold(-price)
	var ids: Array = indices.map(func(i: int) -> String: return _player.inventory.slots[i]["id"])
	for i: int in indices:
		_player.inventory.slots[i] = {}
	var result := Gems.combine(ids)
	_player.inventory.add_item(result, 1)
	Sfx.play("enchant_success")
	_status.text = "Powstał: %s" % Items.get_data(result)["name"]
	_refresh()
