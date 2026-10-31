class_name InventoryWindow
extends PanelContainer
## Okno ekwipunku (klawisz I): po lewej sylwetka postaci z miejscami na przedmioty wokół niej (DOLL - hełm przy
## głowie, buty przy stopach; broń i napierśnik w wysokich ramkach, puste miejsce pokazuje zarys pasującego
## przedmiotu, ramka - kolor rzadkości),
## po prawej plecak (siatka slotów, przewijana, gdy torby go powiększą), pod nim 5 miejsc
## na torby (sakwy i plecaki) i sakiewka.
## PPM na przedmiocie w plecaku - użyj albo załóż, PPM na założonym - zdejmij (tak samo torby).
## Przy otwartym oknie zaklinania PPM wkłada przedmiot (albo kamień) do tego okna.
## Poziom zaklęcia widać w rogu kratki; znika po najechaniu myszką, żeby odsłonić ikonę.
## Przedmioty w plecaku można przeciągać między kratkami (zamiana albo łączenie stosów), na postać
## (zakładanie w wybrane miejsce), z postaci do plecaka, do okna magazynu i z powrotem, a upuszczone
## na koszu - wyrzucić (cenne po potwierdzeniu). Przycisk obok kosza sortuje plecak.

signal crafting_requested

const COLUMNS := 8
## Kratki postaci i toreb; plecak ma mniejsze, żeby było ich widać więcej.
const SLOT_SIZE := Vector2(22, 22)
const BAG_SLOT_SIZE := Vector2(18, 18)
## Ile rzędów plecaka widać naraz (resztę się przewija).
const VISIBLE_ROWS := 5
const TRASH_ICON := preload("res://assets/ui/trash.png")
const SORT_ICON := preload("res://assets/ui/sort.png")
## Miejsca wokół sylwetki postaci: pozycja (piksele w polu DOLL_SIZE) i rozmiar ramki (broń i napierśnik - wysokie).
const DOLL_SIZE := Vector2(160, 158)
const GEAR := Vector2(28, 28)
const TALL := Vector2(28, 58)
const DOLL := {
	"helmet": [Vector2(66, 0), GEAR], "earring_1": [Vector2(34, 8), GEAR], "earring_2": [Vector2(98, 8), GEAR],
	"weapon": [Vector2(2, 36), TALL], "chest": [Vector2(66, 32), TALL], "necklace": [Vector2(98, 40), GEAR],
	"gloves": [Vector2(130, 36), GEAR], "ring_1": [Vector2(34, 72), GEAR], "ring_2": [Vector2(98, 72), GEAR],
	"belt": [Vector2(66, 94), GEAR], "boots": [Vector2(66, 128), GEAR],
}
## Zarys przedmiotu w pustym miejscu (assets/ui/slot_<rodzaj>.png - tools/paperdoll_art.py).
const SILHOUETTE := preload("res://assets/ui/paperdoll.png")
const SLOT_TOOLTIPS := {
	"weapon": "Broń", "helmet": "Hełm", "chest": "Napierśnik", "gloves": "Rękawice", "boots": "Buty",
	"earring_1": "Kolczyk", "earring_2": "Kolczyk", "ring_1": "Pierścień", "ring_2": "Pierścień", "necklace": "Naszyjnik",
	"belt": "Pas",
}

## Ustawiane przez HUD - gdy jest otwarte, PPM trafia do niego.
var enchant_window: EnchantWindow

var _player: Player
var _grid: GridContainer
var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []
var _counts: Array[Label] = []
var _levels: Array[Label] = []
## miejsce na postaci -> [panel, ikona, podpis pustego miejsca, poziom zaklęcia]
var _gear := {}
var _gold_label: Label
var _scroll: ScrollContainer
## miejsca na torby: [panel, ikona, podpis]
var _bag_slots: Array[Array] = []
var _trash: Panel
## Przycisk „Zidentyfikuj wszystko” - widoczny, gdy w plecaku są przedmioty niezidentyfikowane.
var _identify_button: Button
var _confirm: ConfirmationDialog
## Przedmiot czekający na potwierdzenie wyrzucenia: {"index", "id"}.
var _pending_discard := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel())

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Ekwipunek"))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	box.add_child(columns)

	var doll := Control.new()
	doll.custom_minimum_size = DOLL_SIZE
	columns.add_child(doll)
	var shade := TextureRect.new()
	shade.texture = SILHOUETTE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shade.position = Vector2(22, 4)
	shade.size = DOLL_SIZE - Vector2(44, 4)
	shade.modulate = Color(1.15, 1.15, 1.2, 0.8)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll.add_child(shade)
	for slot_name: String in DOLL:
		_gear[slot_name] = _make_gear_slot(doll, slot_name)

	columns.add_child(VSeparator.new())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	columns.add_child(right)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(COLUMNS * (BAG_SLOT_SIZE.x + 2) + 8, VISIBLE_ROWS * (BAG_SLOT_SIZE.y + 2) - 2)
	right.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	_scroll.add_child(_grid)
	# miejsca na torby
	var bag_row := HBoxContainer.new()
	bag_row.add_theme_constant_override("separation", 2)
	right.add_child(bag_row)
	for i in Player.BAG_SLOTS:
		var slot := _make_slot_panel(bag_row)
		slot.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.2, 0.17, 0.14), UiStyle.BORDER, 0))
		slot.gui_input.connect(_on_bag_slot_input.bind(i))
		var placeholder := UiStyle.label("Torba", 6, Color(0.55, 0.5, 0.42))
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(placeholder)
		_bag_slots.append([slot, _make_icon(slot), placeholder])
	# na końcu rzędu toreb: sortowanie i kosz
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_row.add_child(spacer)
	var sort_button := Button.new()
	sort_button.icon = SORT_ICON
	UiStyle.fit_button_icon(sort_button)
	sort_button.focus_mode = Control.FOCUS_NONE
	sort_button.custom_minimum_size = SLOT_SIZE
	sort_button.tooltip_text = "Sortuj plecak: wyposażenie (wg miejsca i jakości), torby, mikstury,\nkamienie, reszta - i połącz stosy"
	sort_button.pressed.connect(_on_sort_pressed)
	bag_row.add_child(sort_button)
	# identyfikacja wszystkich niezidentyfikowanych przedmiotów (opcja łupu w Ustawieniach)
	_identify_button = Button.new()
	_identify_button.icon = Unidentified.ICONS["weapon"]
	UiStyle.fit_button_icon(_identify_button)
	_identify_button.focus_mode = Control.FOCUS_NONE
	_identify_button.custom_minimum_size = SLOT_SIZE
	_identify_button.tooltip_text = "Zidentyfikuj wszystko: wszystkie przedmioty niezidentyfikowane w plecaku\n(tyle, ile zmieści się w plecaku)"
	_identify_button.pressed.connect(func() -> void:
		if _player != null and _player.identify_all() == 0:
			Sfx.play("ui_error"))
	bag_row.add_child(_identify_button)
	_trash = Panel.new()
	_trash.custom_minimum_size = SLOT_SIZE
	_trash.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.22, 0.12, 0.1), UiStyle.BORDER, 0))
	_trash.tooltip_text = "Kosz - przeciągnij tu przedmiot z plecaka, żeby go wyrzucić"
	_trash.set_drag_forwarding(Callable(), _can_drop_on_trash, _drop_on_trash)
	var trash_icon := _make_icon(_trash)
	trash_icon.texture = TRASH_ICON
	bag_row.add_child(_trash)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Wyrzucić przedmiot?"
	_confirm.ok_button_text = "Wyrzuć"
	_confirm.cancel_button_text = "Zostaw"
	_confirm.confirmed.connect(_on_discard_confirmed)
	_confirm.canceled.connect(func() -> void: _pending_discard = {})
	add_child(_confirm)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 3)
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("0", 8, Color(1.0, 0.85, 0.3))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_gold_label)
	var craft_button := Button.new()
	craft_button.text = "Rzemiosło"
	craft_button.focus_mode = Control.FOCUS_NONE
	craft_button.add_theme_font_size_override("font_size", 8)
	craft_button.tooltip_text = "Otwiera okno rzemiosła (np. przedmioty przyzywające bossów)"
	craft_button.pressed.connect(crafting_requested.emit)
	# zaklinanie jest u kowala w Ostoi (NpcDialog), tu tylko rzemiosło
	bottom.add_child(craft_button)
	box.add_child(bottom)
	var hint := UiStyle.label("PPM - załóż / użyj / zdejmij / zidentyfikuj   •   przeciągnij - przenieś / do kosza", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(hint)


func setup(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh)
	player.inventory.rearranged.connect(func(old_to_new: Dictionary) -> void:
		if old_to_new.has(_pending_discard.get("index", -1)):
			_pending_discard["index"] = old_to_new[_pending_discard["index"]])
	player.bags_changed.connect(_refresh)
	player.equipment.changed.connect(_refresh)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()
		reset_size()
		var screen := get_viewport_rect().size
		# pod minimapą, ale nad paskami szybkiego wyboru (z plecaka przeciąga się na nie przedmioty)
		position = Vector2(screen.x - size.x - 8, maxf(2.0, minf(124.0, screen.y - size.y - SkillWindow.BOTTOM_RESERVE)))


func _make_slot_panel(parent: Node, slot_size := SLOT_SIZE) -> Panel:
	var slot := Panel.new()
	UiStyle.rich_tooltip(slot)
	slot.custom_minimum_size = slot_size
	slot.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0))
	parent.add_child(slot)
	return slot


func _make_icon(parent: Control) -> TextureRect:
	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiStyle.center_icon(icon)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon


func _make_bag_slot(index: int) -> void:
	var slot := _make_slot_panel(_grid, BAG_SLOT_SIZE)
	slot.gui_input.connect(_on_bag_input.bind(index))
	slot.set_drag_forwarding(_drag_from_bag.bind(index), _can_drop_on_bag, _drop_on_bag.bind(index))
	_icons.append(_make_icon(slot))
	var count_label := UiStyle.label("", 7)
	count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.offset_right = -1
	count_label.offset_bottom = 2
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count_label)
	_slots.append(slot)
	_counts.append(count_label)
	_levels.append(_make_level_label(slot))


func _make_gear_slot(parent: Node, slot_name: String) -> Array:
	var slot := _make_slot_panel(parent, DOLL[slot_name][1])
	slot.position = DOLL[slot_name][0]
	slot.size = DOLL[slot_name][1]
	slot.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.1, 0.09, 0.92), UiStyle.BORDER, 1))
	slot.gui_input.connect(_on_gear_input.bind(slot_name))
	slot.set_drag_forwarding(_drag_from_gear.bind(slot_name), _can_drop_on_gear.bind(slot_name), _drop_on_gear.bind(slot_name))
	# zarys pasującego przedmiotu w pustym miejscu
	var placeholder := TextureRect.new()
	placeholder.texture = load("res://assets/ui/slot_%s.png" % Equipment.SLOT_TYPES[slot_name])
	UiStyle.center_icon(placeholder, 22.0)
	placeholder.modulate = Color(1, 1, 1, 0.45)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(placeholder)
	var icon := TextureRect.new()
	UiStyle.center_icon(icon, 26.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	return [slot, icon, placeholder, _make_level_label(slot)]


## Poziom zaklęcia w lewym górnym rogu kratki, chowany po najechaniu myszką.
func _make_level_label(slot: Panel) -> Label:
	var level := UiStyle.label("", 7, Color(1.0, 0.82, 0.3))
	level.position = Vector2(1, -3)
	level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(level)
	slot.mouse_entered.connect(func() -> void: level.visible = false)
	slot.mouse_exited.connect(func() -> void: level.visible = true)
	return level


func _on_bag_input(event: InputEvent, index: int) -> void:
	if not _is_right_click(event):
		return
	var data: Dictionary = _player.inventory.slots[index]
	if data.is_empty():
		return
	if Unidentified.is_unidentified(data["id"]):
		# przedmiot niezidentyfikowany: PPM - jeden, Shift+PPM - cały stos
		_player.identify(index, (event as InputEventMouseButton).shift_pressed)
	elif enchant_window != null and enchant_window.visible:
		enchant_window.offer_bag_item(index)
	elif Items.is_usable(data["id"]):
		_player.use_item(data["id"])
	elif Items.is_equippable(data["id"]):
		_player.equip_from_inventory(index)
	elif Items.is_bag(data["id"]):
		_player.equip_bag(index)


func _on_bag_slot_input(event: InputEvent, index: int) -> void:
	if _is_right_click(event):
		_player.unequip_bag(index)


func _on_gear_input(event: InputEvent, slot_name: String) -> void:
	if not _is_right_click(event):
		return
	if enchant_window != null and enchant_window.visible:
		enchant_window.offer_equipped(slot_name)
	elif enchant_window != null and enchant_window.is_busy():
		return
	else:
		_player.unequip(slot_name)


func _is_right_click(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	return mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT


# ---------------------------------------------------------------- przeciąganie, kosz i sortowanie
## Plecak można przestawiać, chyba że okno zaklinania właśnie wbija kamień.
func _can_rearrange() -> bool:
	return _player != null and not (enchant_window != null and enchant_window.is_busy())


## Dane przeciągania (wspólne z oknem magazynu): {"inventory": Inventory, "index": int} - kratka plecaka
## albo magazynu; {"gear_slot": String} - miejsce na postaci.
func _drag_from_bag(_at: Vector2, index: int) -> Variant:
	if not _can_rearrange() or _player.inventory.slots[index].is_empty():
		return null
	_slots[index].set_drag_preview(UiStyle.drag_preview(_icons[index].texture))
	Sfx.play("ui_click")
	return {"inventory": _player.inventory, "index": index}


func _drag_from_gear(_at: Vector2, slot_name: String) -> Variant:
	var id := _player.equipment.get_item(slot_name)
	if not _can_rearrange() or id == "":
		return null
	_gear[slot_name][0].set_drag_preview(UiStyle.drag_preview(Items.get_data(id)["icon"]))
	Sfx.play("ui_click")
	return {"gear_slot": slot_name}


func _can_drop_on_bag(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data.has("inventory") or data.has("gear_slot")) and _can_rearrange()


## Na kratkę plecaka: przestawienie w plecaku, przedmiot z magazynu albo zdjęcie z postaci (na wolną
## kratkę; na przedmiot pasujący do tego miejsca - zamiana).
func _drop_on_bag(_at: Vector2, data: Variant, index: int) -> void:
	# kamień albo esencja na przedmiot z gniazdem - osadzenie (Gems.drag_target)
	if data.get("inventory") == _player.inventory and data["index"] != index and not _player.inventory.slots[index].is_empty():
		var target := Gems.drag_target(_player.inventory.slots[data["index"]].get("id", ""), _player.inventory.slots[index]["id"])
		if target != "":
			_socket_by_drag(data["index"], _player.inventory.slots[index]["id"], target, "")
			return
	if data.has("gear_slot"):
		var target: Dictionary = _player.inventory.slots[index]
		if not target.is_empty() and _player.equipment.fits(data["gear_slot"], target["id"]):
			_player.equip_from_inventory(index, data["gear_slot"])
		else:
			_player.unequip(data["gear_slot"], index)
	elif data["inventory"].transfer(data["index"], _player.inventory, index) == 0:
		Sfx.play("ui_error")
		return
	Sfx.play("pickup")


func _can_drop_on_gear(_at: Vector2, data: Variant, slot_name: String) -> bool:
	if not (data is Dictionary and data.get("inventory") == _player.inventory and _can_rearrange()):
		return false
	var item: Dictionary = _player.inventory.slots[data["index"]]
	if item.is_empty():
		return false
	return _player.equipment.fits(slot_name, item["id"]) or Gems.drag_target(item["id"], _player.equipment.get_item(slot_name)) != ""


func _drop_on_gear(_at: Vector2, data: Variant, slot_name: String) -> void:
	var worn := _player.equipment.get_item(slot_name)
	var target := Gems.drag_target(_player.inventory.slots[data["index"]].get("id", ""), worn)
	if target != "":
		_socket_by_drag(data["index"], worn, target, slot_name)
		return
	_player.equip_from_inventory(data["index"], slot_name)
	Sfx.play("pickup")


## Osadzenie przeciągniętego kamienia / esencji w przedmiocie z plecaka albo założonym (`slot_name`) - albo komunikat,
## dlaczego się nie da (zajęte gniazdo, kamień promienia, esencja innego rodzaju).
func _socket_by_drag(index: int, item_id: String, target: String, slot_name: String) -> void:
	if target != "gem" and target != "essence":
		Sfx.play("ui_error")
		DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -16), target, Color(1.0, 0.55, 0.45), 8)
		return
	var source_name: String = Items.get_data(_player.inventory.slots[index]["id"])["name"]
	Gems.drag_insert(_player.inventory, index, item_id, target)
	if slot_name != "":
		_player.equipment.changed.emit()
	_player.inventory.changed.emit()
	Sfx.play("enchant_success")
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -16),
			"Osadzono: %s" % source_name, Color(0.6, 1.0, 0.55), 8)


func _can_drop_on_trash(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("inventory") == _player.inventory and _can_rearrange()


## Zwykłe przedmioty znikają od razu; magiczne i lepsze oraz zaklęte - po potwierdzeniu.
func _drop_on_trash(_at: Vector2, data: Variant) -> void:
	var index: int = data["index"]
	var slot: Dictionary = _player.inventory.slots[index]
	if slot.is_empty():
		return
	var id: String = slot["id"]
	if Items.rarity_of(id) == "common" and slot.get("enchant", 0) == 0:
		_player.inventory.discard(index)
		Sfx.play("ui_close")
		return
	_pending_discard = {"index": index, "id": id}
	var item_name := Items.display_name(id, slot.get("enchant", 0))
	_confirm.dialog_text = "%s%s zniknie na zawsze." % [item_name, " (x%d)" % slot["count"] if slot["count"] > 1 else ""]
	_confirm.popup_centered()


func _on_discard_confirmed() -> void:
	var index: int = _pending_discard.get("index", -1)
	# w międzyczasie przedmiot mógł się przesunąć albo zniknąć
	if index >= 0 and index < _player.inventory.slots.size() \
			and _player.inventory.slots[index].get("id", "") == _pending_discard["id"]:
		_player.inventory.discard(index)
		Sfx.play("ui_close")
	_pending_discard = {}


func _on_sort_pressed() -> void:
	if not _can_rearrange():
		Sfx.play("ui_error")
		return
	_player.inventory.sort()
	Sfx.play("ui_confirm")


func _refresh() -> void:
	if _player == null:
		return
	var inv := _player.inventory
	_identify_button.visible = inv.slots.any(func(s: Dictionary) -> bool:
		return not s.is_empty() and Unidentified.is_unidentified(s["id"]))
	# plecak urósł albo zmalał (torby) - dobudowujemy / usuwamy kratki
	while _slots.size() < inv.slots.size():
		_make_bag_slot(_slots.size())
	while _slots.size() > inv.slots.size():
		var last: Panel = _slots.pop_back()
		_icons.pop_back()
		_counts.pop_back()
		_levels.pop_back()
		last.queue_free()
	for i in _slots.size():
		var data: Dictionary = inv.slots[i] if i < inv.slots.size() else {}
		UiStyle.set_item_frame(_slots[i], data.get("id", ""))
		if data.is_empty():
			_icons[i].texture = null
			_counts[i].text = ""
			_levels[i].text = ""
			_slots[i].tooltip_text = ""
			continue
		var id: String = data["id"]
		var enchant: int = data.get("enchant", 0)
		_icons[i].texture = Items.get_data(id)["icon"]
		_counts[i].text = str(data["count"]) if data["count"] > 1 else ""
		_levels[i].text = Enchanting.level_name(enchant)
		var extra := ""
		if data["count"] > 1:
			extra += "\nIlość: %d" % data["count"]
		if Items.is_usable(id):
			extra += "\nPPM - użyj"
		elif Items.is_equippable(id) or Items.is_bag(id):
			extra += "\nPPM - załóż"
		_slots[i].tooltip_text = Items.tooltip(id, enchant, extra)

	for i in _bag_slots.size():
		var bag_id: String = _player.bags[i]
		_bag_slots[i][1].texture = Items.get_data(bag_id)["icon"] if bag_id != "" else null
		_bag_slots[i][2].visible = bag_id == ""
		_bag_slots[i][0].tooltip_text = (Items.describe(bag_id) + "\nPPM - zdejmij") if bag_id != "" \
				else "Miejsce na torbę (sakwa +10, plecak +20 miejsc)"

	for slot_name: String in _gear:
		var parts: Array = _gear[slot_name]
		var id := _player.equipment.get_item(slot_name)
		var enchant := _player.equipment.get_enchant(slot_name)
		parts[1].texture = Items.get_data(id)["icon"] if id != "" else null
		UiStyle.set_item_frame(parts[0], id)
		parts[2].visible = id == ""
		parts[3].text = Enchanting.level_name(enchant)
		parts[0].tooltip_text = (Items.describe(id, enchant) + "\nPPM - zdejmij") if id != "" else SLOT_TOOLTIPS[slot_name]
	_gold_label.text = "%d złota" % _player.stats.gold
