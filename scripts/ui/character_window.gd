class_name CharacterWindow
extends PanelContainer
## Okno postaci (klawisz C): poziom, exp, atrybuty z przyciskami "+", reset atrybutów
## i statystyki wynikowe.

const RESET_TEXT := "Resetuj atrybuty"
const RESET_CONFIRM_TEXT := "Na pewno? Kliknij ponownie"
## Ile sekund czeka na potwierdzenie resetu.
const RESET_CONFIRM_TIME := 3.0

var _player: Player
var _level_label: Label
var _xp_label: Label
var _points_label: Label
var _value_labels := {}
var _plus_buttons := {}
var _derived_label: Label
var _reset_button: Button
var _reset_confirm_timer := 0.0


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel())
	custom_minimum_size.x = 260

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	add_child(box)
	box.add_child(UiStyle.title(tr("Postać")))

	_level_label = UiStyle.label("")
	_xp_label = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_points_label = UiStyle.label("", 8, UiStyle.TITLE_COLOR)
	box.add_child(_level_label)
	box.add_child(_xp_label)
	box.add_child(_points_label)
	box.add_child(HSeparator.new())

	# dwie kolumny: atrybuty po lewej, statystyki wynikowe po prawej
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 6)
	box.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	for id: String in CharacterStats.ATTRIBUTES:
		var info: Dictionary = CharacterStats.ATTRIBUTES[id]
		var row := HBoxContainer.new()
		var description := Lang.t(info["description"]) + "\n" + tr("Prawy przycisk myszy - cofnij punkt.")
		row.tooltip_text = description
		row.mouse_filter = Control.MOUSE_FILTER_PASS

		var name_label := UiStyle.label(Lang.t(info["name"]))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.tooltip_text = description
		row.add_child(name_label)

		var value_label := UiStyle.label("0")
		value_label.custom_minimum_size.x = 20
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_value_labels[id] = value_label

		var plus := Button.new()
		plus.text = "+"
		plus.focus_mode = Control.FOCUS_NONE
		plus.custom_minimum_size = Vector2(14, 12)
		plus.add_theme_font_size_override("font_size", 8)
		plus.tooltip_text = description
		plus.pressed.connect(func() -> void: _player.stats.spend_point(id))
		# prawy przycisk na wierszu albo na plusie cofa punkt
		var refund := func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
				_player.stats.refund_point(id)
		plus.gui_input.connect(refund)
		row.gui_input.connect(refund)
		row.add_child(plus)
		_plus_buttons[id] = plus

		left.add_child(row)

	_reset_button = Button.new()
	_reset_button.text = tr(RESET_TEXT)
	_reset_button.focus_mode = Control.FOCUS_NONE
	_reset_button.add_theme_font_size_override("font_size", 8)
	_reset_button.tooltip_text = tr("Zwraca wszystkie rozdane punkty atrybutów")
	_reset_button.pressed.connect(_on_reset_pressed)
	left.add_child(_reset_button)

	columns.add_child(VSeparator.new())
	_derived_label = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_derived_label.custom_minimum_size.x = 110
	columns.add_child(_derived_label)


func _process(delta: float) -> void:
	if _reset_confirm_timer > 0.0:
		_reset_confirm_timer -= delta
		if _reset_confirm_timer <= 0.0:
			_reset_button.text = tr(RESET_TEXT)


## Pierwsze kliknięcie pyta o potwierdzenie, drugie (w ciągu kilku sekund) resetuje.
func _on_reset_pressed() -> void:
	if _reset_confirm_timer > 0.0:
		_reset_confirm_timer = 0.0
		_reset_button.text = tr(RESET_TEXT)
		_player.stats.reset_attributes()
	else:
		_reset_confirm_timer = RESET_CONFIRM_TIME
		_reset_button.text = tr(RESET_CONFIRM_TEXT)


func setup(player: Player) -> void:
	_player = player
	player.stats.changed.connect(_refresh)
	player.stats.xp_changed.connect(func(_xp: int, _needed: int, _level: int) -> void: _refresh())
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()
		reset_size()
		position = Vector2(8, 76)  # pod szybkimi slotami mikstur


func _refresh() -> void:
	if _player == null:
		return
	var s := _player.stats
	_level_label.text = tr("Poziom %d") % s.level
	_xp_label.text = tr("Exp: %d / %d") % [s.xp, s.xp_to_next_level()]
	_points_label.text = tr("Punkty do rozdania: %d") % s.unspent_points
	_points_label.visible = s.unspent_points > 0
	for id: String in _value_labels:
		var from_items := s.attribute(id) - int(s.attributes[id])
		_value_labels[id].text = str(s.attributes[id]) + (" (+%d)" % from_items if from_items > 0 else "")
		_plus_buttons[id].disabled = s.unspent_points <= 0
	var weapon_id := _player.equipment.get_item("weapon")
	var weapon_speed: float = _player.equipment.weapon().get("speed", 1.0)
	_reset_button.disabled = s.spent_points() == 0
	_derived_label.text = tr("Broń: %s\nZdrowie: %d\nMana: %d\nObrażenia: %d-%d\nSzybkość ataku: %d%%\nPancerz: %d\nRedukcja obrażeń: %d%%\nZłoto: %d") % [
		Items.display_name(weapon_id, _player.equipment.get_enchant("weapon")) if weapon_id != "" else tr("pięści"),
		s.max_health(), s.max_mana(), s.damage_min(), s.damage_max(),
		roundi(s.attack_speed() * weapon_speed * 100.0), s.armor(), roundi(s.damage_reduction() * 100.0), s.gold,
	]
	# premie z przedmiotów - tylko te, które postać ma
	var extras: Array[String] = []
	if s.damage_multiplier() > 1.0:
		extras.append(tr("Zwiększone obrażenia: +%d%%") % roundi((s.damage_multiplier() - 1.0) * 100.0))
	if s.cast_speed() > 1.0:
		extras.append(tr("Szybkość rzucania czarów: %d%%") % roundi(s.cast_speed() * 100.0))
	var physical := s.kind_multiplier(["attack"]) - 1.0
	var magic := s.kind_multiplier(["spell"]) - 1.0
	if physical > 0.0:
		extras.append(tr("Obrażenia fizyczne (ataki): +%d%%") % roundi(physical * 100.0))
	if magic > 0.0:
		extras.append(tr("Obrażenia magiczne (czary): +%d%%") % roundi(magic * 100.0))
	if s.crit_chance() > 0.0:
		extras.append(tr("Cios krytyczny: %d%% szans, %d%% obrażeń") % [roundi(s.crit_chance() * 100.0), roundi(s.crit_multiplier() * 100.0)])
	if s.life_on_hit() > 0:
		extras.append(tr("Zdrowie za trafienie: %d") % s.life_on_hit())
	if s.health_regen() > 0.0:
		extras.append(tr("Regeneracja zdrowia: %s/s") % Skills.decimal(s.health_regen(), 1))
	if s.mana_regen() > 0.0:
		extras.append(tr("Regeneracja many: %s/s") % Skills.decimal(s.mana_regen(), 1))
	if s.dodge_chance() > 0.0:
		extras.append(tr("Szansa na unik: %d%%") % roundi(s.dodge_chance() * 100.0))
	if s.cooldown_multiplier() < 1.0:
		extras.append(tr("Skrócenie odnowienia: %d%%") % roundi((1.0 - s.cooldown_multiplier()) * 100.0))
	if s.gold_multiplier() > 1.0:
		extras.append(tr("Więcej złota: +%d%%") % roundi((s.gold_multiplier() - 1.0) * 100.0))
	if s.xp_multiplier() > 1.0:
		extras.append(tr("Więcej doświadczenia: +%d%%") % roundi((s.xp_multiplier() - 1.0) * 100.0))
	if not extras.is_empty():
		_derived_label.text += "\n" + "\n".join(extras)
