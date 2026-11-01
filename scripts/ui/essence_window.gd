class_name EssenceWindow
extends PanelContainer
## Okno esencji legend (Essences) w trzech odsłonach:
## - "watra" (przycisk "Esencje" w oknie Watry): legenda z plecaka wrzucona w płomienie za żar przepada,
##   a w jej miejsce w plecaku pojawia się esencja (40-80% siły legendy);
## - "altar" (Ołtarz Welesa w lochu): to samo za darmo i mocniej (60-100%), raz na ołtarz;
## - "smith" (kowal Bronisław, "Esencje"): gniazdo esencji w rzadkim przedmiocie albo legendzie (Serca Kryształu
##   i złoto), osadzenie esencji tego samego rodzaju, wyjęcie za złoto albo zniszczenie esencji.
## Po lewej lista przedmiotów, po prawej szczegóły zaznaczonego i przyciski.

## Ołtarz Welesa został użyty (dungeon gasi ołtarz).
signal altar_used

const LIST_SIZE := Vector2(210, 190)
const DETAILS_WIDTH := 210.0
const TITLES := {"watra": "Watra - esencje legend", "altar": "Ołtarz Welesa", "smith": "Kowal Bronisław - gniazda esencji"}

var mode := "watra"
var _player: Player
## Zaznaczony przedmiot: {"equip": miejsce} albo {"inv": indeks w plecaku}.
var _selected := {}
var _title: Label
var _hint: Label
var _list: VBoxContainer
var _details: RichTextLabel
var _actions: VBoxContainer
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_title = UiStyle.title("")
	box.add_child(_title)
	_hint = UiStyle.label("", 7, UiStyle.DIM_COLOR)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = LIST_SIZE.x + DETAILS_WIDTH + 4.0
	box.add_child(_hint)
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
	var bottom := HBoxContainer.new()
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_status)
	bottom.add_child(_button(Lang.t("Zamknij"), func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	for source: Signal in [player.inventory.changed, player.equipment.changed, player.stats.gold_changed]:
		source.connect(func(_a = null) -> void:
			if visible:
				_refresh())


func open(window_mode := "watra") -> void:
	mode = window_mode
	visible = true
	_selected = {}
	_status.text = ""
	_title.text = Lang.t(TITLES[mode])
	match mode:
		"watra":
			_hint.text = Lang.t("Legenda wrzucona w płomienie przepada, a Watra oddaje jej efekt jako esencję - losowo 40-80% siły legendy (z jej zaklęciem). Kosztuje żar.")
		"altar":
			_hint.text = Lang.t("Weles przyjmie jedną legendę za darmo i odda mocniejszą esencję - 60-100% jej siły. Potem ołtarz gaśnie.")
		"smith":
			_hint.text = Lang.t("Gniazdo esencji w rzadkim przedmiocie albo (drożej) w legendzie - wtedy legenda ma dwa efekty. Esencja pasuje do przedmiotu tego samego rodzaju (broń, zbroja, biżuteria). Wyjęcie za złoto, inaczej esencja przepada.")
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	return button


## Przedmioty dla tej odsłony: legendy z plecaka (Watra, ołtarz) albo przedmioty z gniazdem esencji lub takie,
## którym kowal może je dorobić (założone i z plecaka).
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if mode == "smith":
		for slot: String in Equipment.SLOTS:
			var id := _player.equipment.get_item(slot)
			if id != "" and (Essences.can_socket(id) or Essences.has_socket(id)):
				result.append({"equip": slot})
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if slot.is_empty():
			continue
		var id: String = slot["id"]
		if (mode == "smith" and (Essences.can_socket(id) or Essences.has_socket(id))) or (mode != "smith" and Essences.is_legend(id)):
			result.append({"inv": i})
	return result


func item_of(entry: Dictionary) -> String:
	if entry.has("equip"):
		return _player.equipment.get_item(entry["equip"])
	var slot: Dictionary = _player.inventory.slots[entry["inv"]] if entry["inv"] < _player.inventory.slots.size() else {}
	return slot.get("id", "")


func enchant_of(entry: Dictionary) -> int:
	if entry.has("equip"):
		return _player.equipment.get_enchant(entry["equip"])
	return int(_player.inventory.slots[entry["inv"]].get("enchant", 0))


## Przedmiot zmienił przepis (to samo id) - odświeżenie statystyk i okien.
func _touch(entry: Dictionary) -> void:
	if entry.has("equip"):
		_player.equipment.changed.emit()
	else:
		_player.inventory.changed.emit()


func _refresh() -> void:
	if _player == null:
		return
	for child in _list.get_children() + _actions.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var list := entries()
	if _selected.is_empty() or not list.has(_selected):
		_selected = list[0] if not list.is_empty() else {}
	for entry in list:
		_list.add_child(_row(entry))
	if mode == "smith":
		_show_smith()
	else:
		_show_extract()


func _row(entry: Dictionary) -> Button:
	var id := item_of(entry)
	var mark := ""
	if Essences.has_socket(id):
		mark = " [%s]" % ("•" if not (Essences.socket_of(id) as Dictionary).is_empty() else " ")
	var button := _button((Lang.t("Założone: ") if entry.has("equip") else "") + Items.display_name(id, enchant_of(entry)) + mark, _select.bind(entry))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = Items.get_data(id).get("icon")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 14)
	button.add_theme_color_override("font_color", Items.rarity_color(id))
	button.toggle_mode = true
	button.set_pressed_no_signal(entry == _selected)
	button.tooltip_text = Items.describe(id, enchant_of(entry))
	UiStyle.rich_tooltip(button)
	return button


func _select(entry: Dictionary) -> void:
	_selected = entry
	Sfx.play("ui_click")
	_refresh()


# ---------------------------------------------------------------- Watra i Ołtarz Welesa
func _show_extract() -> void:
	if mode == "spent":
		_details.text = Lang.t("Ołtarz Welesa zgasł - przyjął już ofiarę.")
		return
	if _selected.is_empty():
		_details.text = Lang.t("Nie masz w plecaku legendarnych przedmiotów.")
		return
	var id := item_of(_selected)
	var enchant := enchant_of(_selected)
	var effect: Dictionary = Items.get_data(id)["effect"]
	var span := Essences.POWER_ALTAR if mode == "altar" else Essences.POWER_WATRA
	var lines: Array[String] = ["[color=#%s]%s[/color]" % [Items.rarity_color(id).to_html(false), Items.display_name(id, enchant)]]
	lines.append(Lang.t("Efekt legendy: ") + Essences.effect_text({"kind": effect["kind"], "value": Items.effect_chance(id, enchant)}))
	lines.append(Lang.t("Esencja: %d-%d%% tej siły, rodzaj: %s.") % [roundi(span.x * 100.0), roundi(span.y * 100.0),
			Lang.t(Essences.GROUP_NAMES[Essences.group_of(id)])])
	if mode == "watra":
		var cost := Essences.ember_cost(id, enchant)
		lines.append(Lang.t("Koszt: %d żaru (masz %d).") % [cost, _player.boons.available_ember()])
		var burn := _button(Lang.t("Wrzuć w płomienie (%d żaru)") % cost, _extract)
		burn.disabled = _player.boons.available_ember() < cost
		_actions.add_child(burn)
	else:
		_actions.add_child(_button(Lang.t("Złóż na ołtarzu (za darmo)"), _extract))
	_details.text = "\n".join(lines)


## Wyciąga esencję z zaznaczonej legendy: legenda znika z plecaka, esencja trafia na jej miejsce.
func _extract() -> void:
	var id := item_of(_selected)
	var enchant := enchant_of(_selected)
	if mode == "watra" and not _player.boons.spend_ember(Essences.ember_cost(id, enchant)):
		_status.text = Lang.t("Za mało żaru.")
		Sfx.play("ui_error")
		return
	var index: int = _selected["inv"]
	_player.inventory.take_one(index)
	var essence := Essences.extract(id, enchant, mode == "altar")
	Items.generated.erase(id)
	_player.inventory.put(index, essence)
	Sfx.play("magic")
	_status.text = Lang.t("%s (%d%% siły legendy)") % [Items.display_name(essence), roundi(Items.get_data(essence)["essence"]["power"] * 100.0)]
	if mode == "altar":
		altar_used.emit()
		_refresh()
		_actions.add_child(UiStyle.label(Lang.t("Ołtarz gaśnie."), 8, UiStyle.DIM_COLOR))
		for child in _actions.get_children():
			if child is Button:
				child.disabled = true
		mode = "spent"
		return
	_refresh()


# ---------------------------------------------------------------- kowal
func _show_smith() -> void:
	if _selected.is_empty():
		_details.text = Lang.t("Nie masz rzadkich ani legendarnych przedmiotów, w których mogę wykuć gniazdo esencji.")
		return
	var id := item_of(_selected)
	var lines: Array[String] = ["[color=#%s]%s[/color]" % [Items.rarity_color(id).to_html(false), Items.display_name(id, enchant_of(_selected))]]
	if not Essences.has_socket(id):
		var hearts := Essences.socket_hearts(id)
		var gold := Essences.socket_gold(id)
		var have := _player.count_owned(Essences.HEART)
		lines.append(Lang.t("Brak gniazda esencji."))
		lines.append(Lang.t("Koszt: Serce Kryształu %d/%d, złoto %d.") % [mini(have, hearts), hearts, gold])
		var add := _button(Lang.t("Wykuj gniazdo esencji"), _add_socket.bind(hearts, gold))
		add.disabled = have < hearts or _player.stats.gold < gold
		_actions.add_child(add)
		_details.text = "\n".join(lines)
		return
	var essence: Dictionary = Essences.socket_of(id)
	lines.append(Essences.socket_text(essence))
	if not essence.is_empty():
		var price := Essences.save_gold(_player.stats.level)
		var take := _button(Lang.t("Wyjmij esencję (%d zł)") % price, _remove.bind(true, price))
		take.disabled = _player.stats.gold < price
		_actions.add_child(take)
		_actions.add_child(_button(Lang.t("Zniszcz esencję"), _remove.bind(false, 0)))
		_details.text = "\n".join(lines)
		return
	var fitting: Array[int] = []
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if not slot.is_empty() and Essences.fits(slot["id"], id):
			fitting.append(i)
	if fitting.is_empty():
		lines.append(Lang.t("[color=#a6abbf]Nie masz esencji tego rodzaju (%s). Wyciągniesz je z legend w Watrze.[/color]")
				% Lang.t(Essences.GROUP_NAMES[Essences.group_of(id)]))
	else:
		lines.append(Lang.t("[color=#a6abbf]Kliknij esencję, żeby ją osadzić:[/color]"))
		var grid := GridContainer.new()
		grid.columns = 8
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		_actions.add_child(grid)
		for index in fitting:
			var essence_id: String = _player.inventory.slots[index]["id"]
			var put := Button.new()
			put.focus_mode = Control.FOCUS_NONE
			put.custom_minimum_size = Vector2(20, 20)
			put.icon = Items.get_data(essence_id)["icon"]
			put.expand_icon = true
			put.tooltip_text = Lang.t("Osadź: ") + Items.describe(essence_id)
			UiStyle.rich_tooltip(put)
			put.pressed.connect(_insert.bind(index))
			grid.add_child(put)
	_details.text = "\n".join(lines)


func _add_socket(hearts: int, gold: int) -> void:
	var id := item_of(_selected)
	if not Essences.can_socket(id) or _player.count_owned(Essences.HEART) < hearts or _player.stats.gold < gold:
		Sfx.play("ui_error")
		return
	_player.take_owned(Essences.HEART, hearts)
	_player.stats.add_gold(-gold)
	Essences.add_socket(id)
	_touch(_selected)
	Sfx.play("anvil")
	_status.text = Lang.t("Kowal wykuł gniazdo esencji.")
	_refresh()


func _insert(index: int) -> void:
	var id := item_of(_selected)
	var essence_id: String = _player.inventory.slots[index]["id"]
	if not Essences.fits(essence_id, id):
		Sfx.play("ui_error")
		return
	_player.inventory.take_one(index)
	Essences.insert(id, essence_id)
	_touch(_selected)
	Sfx.play("pickup")
	_status.text = Lang.t("Esencja osadzona.")
	_refresh()


func _remove(keep: bool, price: int) -> void:
	var id := item_of(_selected)
	if keep and (_player.stats.gold < price or not _player.inventory.slots.any(func(s: Dictionary) -> bool: return s.is_empty())):
		_status.text = Lang.t("Plecak jest pełny albo brakuje złota.")
		Sfx.play("ui_error")
		return
	if keep:
		_player.stats.add_gold(-price)
	var essence_id := Essences.remove(id, keep)
	_touch(_selected)
	if essence_id != "":
		_player.inventory.add_item(essence_id, 1)
	Sfx.play("pickup" if keep else "ui_click")
	_status.text = Lang.t("Esencja wróciła do plecaka.") if keep else Lang.t("Esencja rozwiała się.")
	_refresh()
