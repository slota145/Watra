class_name BigMap
extends PanelContainer
## Duża mapa (klawisz M) z dwiema zakładkami: "Kraina" (bieżąca mapa, domyślnie) i "Świat"
## (mozaika wszystkich krain). Kliknięcie odkrytej kapliczki teleportuje do niej.

signal teleport_requested(shrine_id: String)

## Największa skala mapy; przy dużym świecie zmniejszana, żeby mapa zmieściła się na ekranie.
const MAX_PIXELS_PER_TILE := 3.0

var _view: WorldMapView
var _title: Label
var _tabs: Array[Button] = []
var _seed := 0
var _zone := "forest"
var _texture: Texture2D
var _player: Player
var _markers: Array[Dictionary] = []
var _shrines := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel())
	mouse_filter = Control.MOUSE_FILTER_STOP

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	_title = UiStyle.title("Mapa")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(_title)
	for tab: Array in [["Kraina", "zone"], ["Świat", "world"]]:
		var button := Button.new()
		button.text = tab[0]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(set_mode.bind(tab[1]))
		header.add_child(button)
		_tabs.append(button)

	_view = WorldMapView.new()
	_view.teleport_requested.connect(_on_teleport)
	box.add_child(_view)

	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 10)
	for entry: Array in [
		["Ty", MapView.PLAYER_COLOR],
		["Gobliny", MapView.GOBLIN_COLOR],
		["Wilki", Wolf.WOLF_COLOR],
		["Zwierzyna", Animal.ANIMAL_COLOR],
		["Żaboludzie", Frogman.FROG_COLOR],
		["Boss", Color("c040ff")],
		["Ogniska", Color("ff9a3c")],
	]:
		legend.add_child(UiStyle.label("■ " + entry[0], 8, entry[1]))
	box.add_child(legend)
	var hint := UiStyle.label("Kapliczka - kliknij, by się do niej przenieść", 7, Color(0.6, 0.9, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


## Mapa bieżącej krainy i jej znaczniki (wołane przez HUD).
func setup(texture: Texture2D, _map_size: Vector2i, _tile_size: float, player: Player, markers: Array[Dictionary]) -> void:
	_texture = texture
	_player = player
	_markers = markers


## Dane całego świata: ziarno (do zapamiętanych map innych krain), bieżąca kraina i odkryte kapliczki.
func setup_world(world_seed: int, zone: String, texture: Texture2D, shrines: Dictionary) -> void:
	_seed = world_seed
	_zone = zone
	_texture = texture
	_shrines = shrines
	refresh()


func refresh() -> void:
	var room := get_viewport_rect().size - Vector2(30, 84)
	_view.setup(_seed, _zone, _texture, _player, _markers, _shrines)
	var tiles := _view.view_tiles()
	_view.pixels_per_tile = clampf(minf(room.x / tiles.x, room.y / tiles.y), 0.5, MAX_PIXELS_PER_TILE)
	_view.setup(_seed, _zone, _texture, _player, _markers, _shrines)
	_title.text = "Mapa - " + (Zones.zone_name(_zone) if _view.mode == "zone" else "Świat")
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(["zone", "world"][i] == _view.mode)


## Przełącza zakładkę: "zone" (bieżąca kraina) albo "world" (wszystkie krainy).
func set_mode(mode: String) -> void:
	_view.mode = mode
	refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


## Otwiera mapę z podświetlonym obszarem (w kafelkach lasu), np. miejscem zadania.
func show_area(area: Rect2, label: String) -> void:
	visible = false
	toggle()
	# zadania są w lesie - jeśli jesteśmy gdzie indziej, pokazujemy cały świat
	if _zone != "forest":
		set_mode("world")
	_view.highlight = area
	_view.highlight_label = label


## Trwające wydarzenie w świecie (WorldEvents) na mapie: kraina, miejsce w niej (INF - środek krainy), tytuł.
func set_event(zone: String, point: Vector2, title: String, color: Color) -> void:
	if _view != null:
		_view.event_zone = zone
		_view.event_point = point
		_view.event_title = title
		_view.event_color = color


func toggle() -> void:
	visible = not visible
	_view.highlight = Rect2()
	if visible:
		# domyślnie bieżąca kraina
		_view.mode = "zone"
		refresh()
		reset_size()
		position = ((get_viewport_rect().size - size) / 2.0).floor()


func _on_teleport(shrine_id: String) -> void:
	visible = false
	teleport_requested.emit(shrine_id)
