class_name DungeonWindow
extends PanelContainer
## Lochy w płomieniach Watry (przycisk "Lochy" w oknie Watry): wybór klimatu, stopnia trudności (najwyżej poziom
## Watry) i modyfikatorów kupowanych za żar (Dungeons.MODIFIERS - kolejne odblokowuje poziom Watry). "Wkrocz
## w płomienie" wydaje żar i przenosi gracza do nowo wygenerowanego lochu (World.enter_dungeon).
## Sloty na bożki (Idols): wybór bożka z plecaka (bożki potworów i łupu mogą być w kilku slotach, reszta raz - Idols.fits);
## bożki zużywają się przy wejściu.
## Węzeł Mapy Nawii (open_node): klimat i stopień są z góry ustalone (wybór ukryty), reszta jak zwykle.

const WIDTH := 300.0
const FIRE := Color(1.0, 0.6, 0.25)

var _player: Player
var _climate := "catacombs"
var _tier := 1
var _mods: Array[String] = []
var _climate_buttons := {}
var _climate_text: Label
var _tier_label: Label
var _tier_hint: Label
var _mod_boxes := {}
var _ember_label: Label
var _enter: Button
## Bożki w slotach (identyfikatory, "" - pusty slot) i listy wyboru.
var _idols: Array[String] = []
var _idol_pickers: Array[OptionButton] = []
var _idol_text: Label
var _title: Label
var _climate_row: HBoxContainer
var _tier_arrows: Array[Button] = []
## Węzeł Mapy Nawii, do którego prowadzi wyprawa (-1 - zwykły loch).
var _nawia_node := -1
## Przewijana środkowa część okna i jej treść (_fit_scroll).
var _scroll: ScrollContainer
var _content: VBoxContainer


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.07, 0.05, 0.98), Color(0.85, 0.45, 0.18), 6))
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	add_child(outer)
	_title = UiStyle.title(Lang.t("Lochy w płomieniach Watry"))
	outer.add_child(_title)
	# treść przewijana, gdy okno nie mieści się na ekranie - tytuł i przyciski wejścia zawsze widać
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(box)
	_content = box
	box.add_child(_wrapped(Lang.t("Wkrocz w płomienie i zejdź do lochu. W najdalszej komnacie czeka strażnik ze skarbcem; płomienie wyprowadzą cię z powrotem do Ostoi."), UiStyle.DIM_COLOR))

	var climates := HBoxContainer.new()
	climates.alignment = BoxContainer.ALIGNMENT_CENTER
	climates.add_theme_constant_override("separation", 3)
	box.add_child(climates)
	_climate_row = climates
	for id in Dungeons.CLIMATE_ORDER:
		var button := _button(Lang.t(Dungeons.CLIMATES[id]["name"]), _choose_climate.bind(id))
		button.toggle_mode = true
		climates.add_child(button)
		_climate_buttons[id] = button
	_climate_text = _wrapped("", UiStyle.TEXT_COLOR)
	box.add_child(_climate_text)

	box.add_child(HSeparator.new())
	var tiers := HBoxContainer.new()
	tiers.alignment = BoxContainer.ALIGNMENT_CENTER
	tiers.add_theme_constant_override("separation", 6)
	_tier_arrows.append(_button("<", _change_tier.bind(-1)))
	tiers.add_child(_tier_arrows[0])
	_tier_label = UiStyle.label("", 8, FIRE)
	_tier_label.custom_minimum_size.x = 140
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tiers.add_child(_tier_label)
	_tier_arrows.append(_button(">", _change_tier.bind(1)))
	tiers.add_child(_tier_arrows[1])
	box.add_child(tiers)
	_tier_hint = _wrapped("", UiStyle.DIM_COLOR)
	box.add_child(_tier_hint)

	box.add_child(HSeparator.new())
	box.add_child(_header(Lang.t("Ofiara z żaru (modyfikatory)")))
	# modyfikatory w dwóch kolumnach (opisy zawijane) - lista mieści się w oknie także po dodaniu żywiołów
	var mods_grid := GridContainer.new()
	mods_grid.columns = 2
	mods_grid.add_theme_constant_override("h_separation", 8)
	mods_grid.add_theme_constant_override("v_separation", 0)
	box.add_child(mods_grid)
	for id in Dungeons.MODIFIER_ORDER:
		var check := CheckBox.new()
		check.focus_mode = Control.FOCUS_NONE
		check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		check.custom_minimum_size.x = 210
		check.add_theme_font_size_override("font_size", 7)
		check.add_theme_icon_override("unchecked", _empty_box(Color(0.85, 0.7, 0.55)))
		check.add_theme_icon_override("unchecked_disabled", _empty_box(Color(0.45, 0.4, 0.38)))
		check.toggled.connect(_toggle_mod.bind(id))
		mods_grid.add_child(check)
		_mod_boxes[id] = check

	box.add_child(HSeparator.new())
	box.add_child(_header(Lang.t("Bożki (zużywają się przy wejściu)")))
	var pickers := GridContainer.new()
	pickers.columns = 2
	pickers.add_theme_constant_override("h_separation", 4)
	pickers.add_theme_constant_override("v_separation", 3)
	box.add_child(pickers)
	# zapasowe pola na sloty z drzewka Watry (WatraTree.idol_slots) - widoczne dopiero po ich wybraniu
	for i in Idols.SLOT_LEVELS.size() + WatraTree.MAX_IDOL_SLOTS:
		var picker := OptionButton.new()
		picker.focus_mode = Control.FOCUS_NONE
		picker.add_theme_font_size_override("font_size", 7)
		picker.add_theme_constant_override("icon_max_width", 12)
		picker.custom_minimum_size = Vector2(WIDTH / 2.0 - 2.0, 16)
		picker.clip_text = true
		picker.item_selected.connect(_choose_idol.bind(i))
		pickers.add_child(picker)
		_idol_pickers.append(picker)
		_idols.append("")
	_idol_text = _wrapped("", Color(0.75, 0.85, 1.0))
	box.add_child(_idol_text)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	_ember_label = UiStyle.label("", 8, FIRE)
	_ember_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_ember_label)
	_enter = _button(Lang.t("Wkrocz w płomienie"), _on_enter)
	bottom.add_child(_enter)
	bottom.add_child(_button(Lang.t("Wróć"), func() -> void:
		visible = false
		Sfx.play("ui_close")))
	outer.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.boons.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	if _nawia_node >= 0:
		_nawia_node = -1
		_tier = 1
	_set_node_mode(false)
	visible = true
	_tier = clampi(_tier, 1, _max_tier())
	_refresh()
	_center()


## Wyprawa do węzła Mapy Nawii (NawiaMap): klimat i stopień węzła, modyfikatory i bożki do wyboru.
func open_node(node: Dictionary) -> void:
	_nawia_node = int(node["id"])
	_climate = str(node["climate"])
	_tier = int(node["tier"])
	_set_node_mode(true)
	visible = true
	_refresh()
	_center()


func _set_node_mode(on: bool) -> void:
	_title.text = Lang.t("Węzeł Mapy Nawii") if on else Lang.t("Lochy w płomieniach Watry")
	_climate_row.visible = not on
	for arrow in _tier_arrows:
		arrow.visible = not on


func _center() -> void:
	# przewijana część: cała treść, ale nie wyżej, niż zmieści się na ekranie nad paskiem ikon (z tytułem i przyciskami)
	var content := _content.get_combined_minimum_size()
	_scroll.custom_minimum_size = Vector2(content.x + 8.0, minf(content.y, get_viewport_rect().size.y - 110.0))
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


func _max_tier() -> int:
	return mini(_player.boons.watra_level(), Dungeons.BASE_TIERS) if _player != null else 1


func _choose_climate(id: String) -> void:
	_climate = id
	Sfx.play("ui_click")
	_refresh()


func _change_tier(step: int) -> void:
	_tier = clampi(_tier + step, 1, _max_tier())
	Sfx.play("ui_click")
	_refresh()


func _toggle_mod(on: bool, id: String) -> void:
	if on and not id in _mods:
		_mods.append(id)
	elif not on:
		_mods.erase(id)
	_refresh()


func _choose_idol(index: int, slot: int) -> void:
	_idols[slot] = str(_idol_pickers[slot].get_item_metadata(index))
	Sfx.play("ui_click")
	_refresh()


## Bożki w slotach, bez pustych.
func chosen_idols() -> Array[String]:
	var result: Array[String] = []
	for id in _idols:
		if id != "":
			result.append(id)
	return result


## Czy slot `i` działa: pierwsze sloty odblokowuje poziom Watry (Idols.SLOT_LEVELS), kolejne - drzewko Watry.
static func _slot_open(i: int, watra: int, extra: int) -> bool:
	if i < Idols.SLOT_LEVELS.size():
		return watra >= Idols.SLOT_LEVELS[i]
	return i < Idols.SLOT_LEVELS.size() + extra


## Listy bożków w slotach: w każdej bożki z plecaka, które pasują do bożków z innych slotów (Idols.fits) i których
## zostały jeszcze sztuki.
func _refresh_idols(watra: int) -> void:
	var extra := WatraTree.idol_slots(_player.boons.tree_effects())
	var owned := {}
	for slot: Dictionary in _player.inventory.slots:
		if not slot.is_empty() and Idols.is_idol(slot["id"]):
			owned[slot["id"]] = int(owned.get(slot["id"], 0)) + int(slot.get("count", 1))
	var ids: Array = owned.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa := Idols.parse(a)
		var pb := Idols.parse(b)
		var ka := Idols.KIND_ORDER.find(pa[0])
		var kb := Idols.KIND_ORDER.find(pb[0])
		return ka < kb if ka != kb else Idols.RARITIES.find(pa[1]) > Idols.RARITIES.find(pb[1]))
	var used := {}
	for i in _idol_pickers.size():
		if not _slot_open(i, watra, extra) or int(used.get(_idols[i], 0)) >= int(owned.get(_idols[i], 0)):
			_idols[i] = ""
		if _idols[i] != "":
			used[_idols[i]] = int(used.get(_idols[i], 0)) + 1
	var lines: Array[String] = []
	for i in _idol_pickers.size():
		var picker := _idol_pickers[i]
		picker.visible = i < Idols.SLOT_LEVELS.size() + extra
		picker.clear()
		if not _slot_open(i, watra, extra):
			picker.add_item(Lang.t("Slot od %d. poziomu Watry") % Idols.slot_unlock(i))
			picker.set_item_metadata(0, "")
			picker.disabled = true
			picker.tooltip_text = ""
			continue
		picker.disabled = false
		picker.add_item(Lang.t("Pusty slot"))
		picker.set_item_metadata(0, "")
		var others: Array[String] = []
		for j in _idols.size():
			if j != i and _idols[j] != "":
				others.append(_idols[j])
		for id: String in ids:
			var left: int = owned[id] - others.count(id)
			if id != _idols[i] and (left <= 0 or not Idols.fits(others, id)):
				continue
			picker.add_icon_item(Items.get_data(id)["icon"], "%s (%d)" % [Items.display_name(id), left])
			var index := picker.item_count - 1
			picker.set_item_metadata(index, id)
			picker.get_popup().set_item_icon_max_width(index, 12)
			if id == _idols[i]:
				picker.select(index)
		if _idols[i] == "":
			picker.select(0)
			picker.tooltip_text = Lang.t("Bożki wypadają rzadko z potworów.") if ids.is_empty() else ""
		else:
			var effect := Idols.effect_lines(_idols[i])
			picker.tooltip_text = "%s\n%s" % [Items.display_name(_idols[i]), "\n".join(effect)]
			var skip := [Lang.t("Można włożyć w kilka slotów - działanie się sumuje."),
					Lang.t("Włóż w slot w oknie lochów Watry - zużywa się przy wejściu.")]
			lines.append_array(effect.slice(1).filter(func(line: String) -> bool: return not skip.has(line)))
	_idol_text.text = ", ".join(lines) if not lines.is_empty() \
			else (Lang.t("Nie masz bożków - wypadają rzadko z potworów.") if ids.is_empty() else "")


func _refresh() -> void:
	if _player == null:
		return
	var watra := _player.boons.watra_level()
	_refresh_idols(watra)
	for id: String in _climate_buttons:
		_climate_buttons[id].set_pressed_no_signal(id == _climate)
	_climate_text.text = Lang.t(Dungeons.CLIMATES[_climate]["description"])
	_tier_label.text = Lang.t("Stopień %d  (potwory poz. %d)") % [_tier, Dungeons.tier_level(_tier)]
	if _nawia_node >= 0:
		_tier_hint.text = Lang.t("Pokonaj strażnika, żeby oczyścić węzeł i odsłonić sąsiednie.")
	else:
		_tier_hint.text = Lang.t("Najwyższy stopień: %d. Kolejne odblokowuje wyższy poziom Watry.") % _max_tier() \
				if _max_tier() < Dungeons.BASE_TIERS else Lang.t("Wszystkie stopnie odblokowane.")
	for id: String in _mod_boxes:
		var data: Dictionary = Dungeons.MODIFIERS[id]
		var check: CheckBox = _mod_boxes[id]
		var locked := int(data["unlock"]) > watra
		if locked:
			_mods.erase(id)
		check.disabled = locked
		check.set_pressed_no_signal(id in _mods)
		check.text = Lang.t("%s (%d żaru): %s") % [Lang.t(data["name"]), data["cost"], Lang.t(data["description"])] if not locked \
				else Lang.t("%s - od %d. poziomu Watry") % [Lang.t(data["name"]), data["unlock"]]
	var cost := Dungeons.mods_cost(_mods, chosen_idols())
	var available := _player.boons.available_ember()
	_ember_label.text = Lang.t("Żar: %d  •  koszt: %d") % [available, cost]
	_ember_label.add_theme_color_override("font_color", FIRE if cost <= available else Color(1, 0.4, 0.4))
	_enter.disabled = cost > available


func _on_enter() -> void:
	var cost := Dungeons.mods_cost(_mods, chosen_idols())
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	var idols := chosen_idols()
	if not Idols.can_combine(idols) or idols.any(func(id: String) -> bool: return _player.inventory.count_of(id) < idols.count(id)):
		_refresh()
		return
	if not _player.boons.spend_ember(cost):
		return
	# drzewko Watry („Wieczny Bożek”): bożek może się nie zużyć - zostaje w slocie na następną wyprawę
	var keep := WatraTree.value(_player.boons.tree_effects(), "idol_keep")
	for i in _idols.size():
		if _idols[i] == "":
			continue
		if keep > 0.0 and randf() < keep:
			continue
		_player.inventory.remove_item(_idols[i], 1)
		_idols[i] = ""
	visible = false
	var settings := Dungeons.config(_climate, _tier, _mods, randi(), idols)
	if _nawia_node >= 0:
		settings["nawia_node"] = _nawia_node
	# premie drzewka Watry z chwili wejścia - zmiana zakładki w lochu już ich nie rusza
	settings["tree"] = _player.boons.tree_effects()
	world.enter_dungeon(settings)


## Puste pole wyboru: jasna ramka (domyślna jest prawie niewidoczna na ciemnym tle okna).
static func _empty_box(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for i in range(2, 14):
		for edge in [2, 13]:
			image.set_pixel(i, edge, color)
			image.set_pixel(edge, i, color)
	return ImageTexture.create_from_image(image)


func _header(text: String) -> Label:
	var label := UiStyle.label(text, 8, FIRE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _wrapped(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 7, color)
	label.custom_minimum_size.x = WIDTH
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.custom_minimum_size = Vector2(18, 14)
	button.pressed.connect(on_pressed)
	return button
