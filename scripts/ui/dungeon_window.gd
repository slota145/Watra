class_name DungeonWindow
extends PanelContainer
## Lochy w płomieniach Watry (przycisk "Lochy" w oknie Watry): wybór klimatu, stopnia trudności (najwyżej poziom
## Watry) i modyfikatorów kupowanych za żar (Dungeons.MODIFIERS - kolejne odblokowuje poziom Watry). "Wkrocz
## w płomienie" wydaje żar i przenosi gracza do nowo wygenerowanego lochu (World.enter_dungeon).

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


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.07, 0.05, 0.98), Color(0.85, 0.45, 0.18), 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(Lang.t("Lochy w płomieniach Watry")))
	box.add_child(_wrapped(Lang.t("Wkrocz w płomienie i zejdź do lochu. W najdalszej komnacie czeka strażnik ze skarbcem; płomienie wyprowadzą cię z powrotem do Ostoi. W co czwartym lochu rośnie Kryształ Watry - obroń go przed falami potworów, a da kamienie zaklinające (wbija je kowal)."), UiStyle.DIM_COLOR))

	var climates := HBoxContainer.new()
	climates.alignment = BoxContainer.ALIGNMENT_CENTER
	climates.add_theme_constant_override("separation", 3)
	box.add_child(climates)
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
	tiers.add_child(_button("<", _change_tier.bind(-1)))
	_tier_label = UiStyle.label("", 8, FIRE)
	_tier_label.custom_minimum_size.x = 140
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tiers.add_child(_tier_label)
	tiers.add_child(_button(">", _change_tier.bind(1)))
	box.add_child(tiers)
	_tier_hint = _wrapped("", UiStyle.DIM_COLOR)
	box.add_child(_tier_hint)

	box.add_child(HSeparator.new())
	box.add_child(_header(Lang.t("Ofiara z żaru (modyfikatory)")))
	for id in Dungeons.MODIFIER_ORDER:
		var check := CheckBox.new()
		check.focus_mode = Control.FOCUS_NONE
		check.add_theme_font_size_override("font_size", 7)
		check.add_theme_icon_override("unchecked", _empty_box(Color(0.85, 0.7, 0.55)))
		check.add_theme_icon_override("unchecked_disabled", _empty_box(Color(0.45, 0.4, 0.38)))
		check.toggled.connect(_toggle_mod.bind(id))
		box.add_child(check)
		_mod_boxes[id] = check

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
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.boons.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	visible = true
	_tier = clampi(_tier, 1, _max_tier())
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


func _max_tier() -> int:
	return mini(_player.boons.watra_level(), Dungeons.TIER_LEVELS.size()) if _player != null else 1


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


func _refresh() -> void:
	if _player == null:
		return
	var watra := _player.boons.watra_level()
	for id: String in _climate_buttons:
		_climate_buttons[id].set_pressed_no_signal(id == _climate)
	_climate_text.text = Lang.t(Dungeons.CLIMATES[_climate]["description"])
	_tier_label.text = Lang.t("Stopień %d  (potwory poz. %d)") % [_tier, Dungeons.tier_level(_tier)]
	_tier_hint.text = Lang.t("Najwyższy stopień: %d. Kolejne odblokowuje wyższy poziom Watry.") % _max_tier() \
			if _max_tier() < Dungeons.TIER_LEVELS.size() else Lang.t("Wszystkie stopnie odblokowane.")
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
	var cost := Dungeons.mods_cost(_mods)
	var available := _player.boons.available_ember()
	_ember_label.text = Lang.t("Żar: %d  •  koszt: %d") % [available, cost]
	_ember_label.add_theme_color_override("font_color", FIRE if cost <= available else Color(1, 0.4, 0.4))
	_enter.disabled = cost > available


func _on_enter() -> void:
	var cost := Dungeons.mods_cost(_mods)
	if not _player.boons.spend_ember(cost):
		return
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	visible = false
	world.enter_dungeon(Dungeons.config(_climate, _tier, _mods, randi()))


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
