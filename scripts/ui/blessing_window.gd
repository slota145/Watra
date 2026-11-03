class_name BlessingWindow
extends PanelContainer
## Okno Błogosławieństwa Watry - F przy kapliczce krainy, której obszar Mapy Nawii ma oczyszczony węzeł.
## Pokazuje postęp obszaru, poziomy potworów z błogosławieństwem i premię do łupu i doświadczenia
## (NawiaMap.blessing_*), a przycisk włącza je albo wyłącza. Zmiana przebudowuje krainę od razu
## (World.toggle_blessing - podróż do tej samej kapliczki).

const FIRE := Color(1.0, 0.72, 0.3)
const WIDTH := 190.0

var _player: Player
var _shrine := ""
var _info: Label
var _toggle: Button


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.07, 0.04, 0.98), Color(0.9, 0.6, 0.3), 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(Lang.t("Błogosławieństwo Watry")))
	box.add_child(_wrapped(Lang.t("Ogień Watry sięga tu z oczyszczonej Nawii. Z błogosławieństwem potwory krainy są tak silne jak najtrudniejszy oczyszczony węzeł jej obszaru, ale dają więcej łupu i doświadczenia."), UiStyle.DIM_COLOR))
	box.add_child(HSeparator.new())
	_info = _wrapped("", UiStyle.TEXT_COLOR)
	box.add_child(_info)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 6)
	_toggle = _button("", _on_toggle)
	bottom.add_child(_toggle)
	bottom.add_child(_button(Lang.t("Zamknij"), close))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player


func open(shrine_id: String) -> void:
	_shrine = shrine_id
	visible = true
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func close() -> void:
	visible = false
	Sfx.play("ui_close")


func _process(_delta: float) -> void:
	# odejście od kapliczki zamyka okno
	if visible and _player != null:
		var world := get_tree().get_first_node_in_group("world")
		if world == null or world.blessing_shrine_near(_player.global_position) != _shrine:
			visible = false


func _refresh() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null or _player == null:
		return
	var zone: String = world.zone
	var nodes := NawiaMap.nodes(int(world._seed))
	var cleared := _player.boons.nawia_cleared
	var progress := NawiaMap.area_progress(nodes, cleared, zone)
	var range := NawiaMap.blessing_range(NawiaMap.blessing_level(nodes, cleared, zone))
	var bonus := roundi(NawiaMap.blessing_bonus(nodes, cleared, zone) * 100.0)
	var on := _player.boons.nawia_blessed.has(zone)
	var text := Lang.t("Kraina: %s\nOczyszczone węzły obszaru: %d / %d") % [Zones.zone_name(zone), progress.x, progress.y]
	text += "\n" + Lang.t("Potwory: poz. %d-%d, bossowie poz. %d") % [range[0], range[1], range[2]]
	text += "\n" + Lang.t("Łup i doświadczenie: +%d%%") % bonus
	text += "\n\n" + (Lang.t("Błogosławieństwo działa.") if on else Lang.t("Błogosławieństwo nie działa - kraina ma zwykłe poziomy."))
	_info.text = text
	_info.add_theme_color_override("font_color", FIRE if on else UiStyle.TEXT_COLOR)
	_toggle.text = Lang.t("Wygaś") if on else Lang.t("Rozpal")


func _on_toggle() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	visible = false
	world.toggle_blessing(_shrine)


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
