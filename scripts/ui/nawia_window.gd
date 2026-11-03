class_name NawiaWindow
extends PanelContainer
## Okno Mapy Nawii (przycisk „Nawia” w oknie Watry, od NawiaMap.UNLOCK_LEVEL poziomu postaci): koło zaświatów z Watrą
## w środku, 6 obszarów (krainy) i węzły-lochy (NawiaMap). Odsłonięte węzły świecą, oczyszczone są jasne,
## nieodkryte to tylko blade punkty we mgle. Kliknięcie wybiera węzeł, „Wyrusz” otwiera okno lochów w trybie węzła
## (DungeonWindow.open_node - modyfikatory i bożki jak zwykle, wejście bez kosztów).
## Rysowane w kodzie; ładna grafika mapy przyjdzie, gdy system będzie dopracowany.

signal node_requested(node: Dictionary)
signal tree_requested

const FIRE := Color(1.0, 0.6, 0.25)
const NAWIA := Color(0.62, 0.55, 1.0)
const MAP_SIZE := 260.0
## Szerokość kolumny z opisem po prawej stronie mapy.
const SIDE := 130.0

var _player: Player
var _view: NawiaMapView
var _info: Label
var _progress: Label
var _go: Button
var _nodes: Array[Dictionary] = []
var _selected := -1


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.07, 0.05, 0.12, 0.98), Color(0.55, 0.45, 0.9), 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_view = NawiaMapView.new()
	_view.window = self
	_view.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	row.add_child(_view)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	row.add_child(box)
	box.add_child(UiStyle.title(Lang.t("Mapa Nawii")))
	box.add_child(_wrapped(Lang.t("Horda wylała zaświaty na świat. Oczyszczaj węzły - każdy pokonany strażnik odsłania kolejne i daje punkt Watry."), UiStyle.DIM_COLOR))
	box.add_child(_wrapped(Lang.t("Oczyszczony węzeł pozwala rozpalić Błogosławieństwo Watry przy kapliczce krainy jego obszaru (F)."), FIRE))
	box.add_child(HSeparator.new())
	_progress = _wrapped("", NAWIA)
	box.add_child(_progress)
	box.add_child(HSeparator.new())
	_info = _wrapped("", UiStyle.TEXT_COLOR)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_info)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 6)
	_go = _button(Lang.t("Wyrusz"), _on_go)
	bottom.add_child(_go)
	bottom.add_child(_button(Lang.t("Drzewko"), func() -> void:
		visible = false
		tree_requested.emit()))
	bottom.add_child(_button(Lang.t("Zamknij"), func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.boons.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	var world := get_tree().get_first_node_in_group("world")
	_nodes = NawiaMap.nodes(int(world._seed) if world != null else 0)
	visible = true
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func cleared() -> Array[int]:
	return _player.boons.nawia_cleared if _player != null else [] as Array[int]


func select(id: int) -> void:
	_selected = id
	Sfx.play("ui_click")
	_refresh()


func _refresh() -> void:
	if _player == null:
		return
	var done := cleared()
	_progress.text = Lang.t("Oczyszczone węzły: %d / %d\nPunkty Watry: %d") % [done.size(), _nodes.size(), _player.boons.watra_points()]
	var open_ids := NawiaMap.revealed(_nodes, done)
	if _selected < 0 or _selected >= _nodes.size() or not open_ids.has(_selected):
		_selected = -1
	_go.disabled = _selected < 0
	if _selected < 0:
		_info.text = Lang.t("Wybierz świecący węzeł na mapie.")
	else:
		var node := _nodes[_selected]
		var area: String = node["area"]
		var progress := NawiaMap.area_progress(_nodes, done, area)
		_info.text = "%s\n\n%s" % [Dungeons.title({"climate": node["climate"], "tier": node["tier"]}),
				Lang.t("Obszar: %s (oczyszczono %d / %d)") % [Lang.t(Zones.DATA[area]["name"]), progress.x, progress.y]]
		if done.has(_selected):
			_info.text += "\n\n" + Lang.t("Węzeł oczyszczony - można wrócić po łup.")
	_view.queue_redraw()


func _on_go() -> void:
	if _selected < 0:
		return
	visible = false
	node_requested.emit(_nodes[_selected])


func _wrapped(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 7, color)
	label.custom_minimum_size.x = SIDE
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


## Rysunek mapy: obszary jak kawałki tortu, pierścienie stopni, drogi i węzły; najechany węzeł podpowiada stopień.
class NawiaMapView extends Control:
	var window: NawiaWindow
	var _hover := -1

	func _center() -> Vector2:
		return size / 2.0

	func _radius() -> float:
		return minf(size.x, size.y) / 2.0 - 14.0

	func _point(node: Dictionary) -> Vector2:
		return _center() + (node["pos"] as Vector2) * _radius()

	func _node_at(at: Vector2, open_ids: Dictionary) -> int:
		var best := -1
		var best_d := 9.0 * 9.0
		for node in window._nodes:
			if not open_ids.has(node["id"]):
				continue
			var d := _point(node).distance_squared_to(at)
			if d < best_d:
				best_d = d
				best = node["id"]
		return best

	func _gui_input(event: InputEvent) -> void:
		var open_ids := NawiaMap.revealed(window._nodes, window.cleared())
		if event is InputEventMouseMotion:
			var hover := _node_at(event.position, open_ids)
			if hover != _hover:
				_hover = hover
				tooltip_text = Dungeons.title({"climate": window._nodes[hover]["climate"], "tier": window._nodes[hover]["tier"]}) if hover >= 0 else ""
				queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var id := _node_at(event.position, open_ids)
			if id >= 0:
				window.select(id)
				accept_event()

	func _draw() -> void:
		var center := _center()
		var radius := _radius()
		var areas := NawiaMap.AREAS.size()
		var sector := TAU / areas
		var font := get_theme_default_font()
		var done := window.cleared()
		draw_circle(center, radius + 8.0, Color(0.04, 0.03, 0.08))
		# obszary: przyciemnione kawałki koła w kolorze krainy, oczyszczony obszar jaśniejszy
		for a in areas:
			var area := NawiaMap.AREAS[a]
			var start := -PI / 2.0 + (a - 0.5) * sector
			var points := PackedVector2Array([center])
			for i in 17:
				points.append(center + Vector2.from_angle(start + sector * i / 16.0) * (radius + 6.0))
			var tint: Color = NawiaMap.AREA_COLORS[area]
			var cleansed := NawiaMap.area_cleared(window._nodes, done, area)
			draw_colored_polygon(points, Color(tint, 0.3 if cleansed else 0.12))
			draw_line(center, center + Vector2.from_angle(start) * (radius + 6.0), Color(0.5, 0.45, 0.8, 0.35), 1.0)
			var label := Lang.t(Zones.DATA[area]["name"])
			var at := center + Vector2.from_angle(start + sector / 2.0) * (radius + 2.0)
			var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
			draw_string(font, at - Vector2(width / 2.0, -2.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(tint.lightened(0.4), 0.85))
		# pierścienie stopni
		for ring in NawiaMap.ring_count():
			draw_arc(center, NawiaMap.ring_radius(ring) * radius, 0, TAU, 64, Color(0.5, 0.45, 0.8, 0.12), 1.0)
		var open_ids := NawiaMap.revealed(window._nodes, done)
		# drogi między odsłoniętymi węzłami i od pierwszego pierścienia do Watry
		for node in window._nodes:
			var id: int = node["id"]
			if not open_ids.has(id):
				continue
			if int(node["ring"]) == 0:
				draw_line(center, _point(node), Color(NawiaWindow.FIRE, 0.45), 1.0)
			for other: int in node["links"]:
				if other > id and open_ids.has(other):
					var both := done.has(id) and done.has(other)
					draw_line(_point(node), _point(window._nodes[other]), Color(NawiaWindow.NAWIA, 0.7 if both else 0.3), 1.0)
		# węzły: mgła, odsłonięte, oczyszczone
		var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 300.0)
		for node in window._nodes:
			var id: int = node["id"]
			var at := _point(node)
			if not open_ids.has(id):
				draw_circle(at, 1.2, Color(0.4, 0.38, 0.55, 0.35))
				continue
			var floor_color: Color = Dungeons.CLIMATES[node["climate"]]["map_floor"]
			if done.has(id):
				draw_circle(at, 4.0, floor_color.lightened(0.35))
				draw_circle(at, 1.6, Color(1.0, 0.95, 0.8))
			else:
				draw_circle(at, 4.5, Color(NawiaWindow.FIRE, 0.35 * pulse))
				draw_circle(at, 3.5, floor_color.lightened(0.1))
				draw_arc(at, 3.8, 0, TAU, 16, Color(NawiaWindow.FIRE, pulse), 1.0)
			if id == window._selected:
				draw_arc(at, 6.5, 0, TAU, 20, Color.WHITE, 1.0)
			elif id == _hover:
				draw_arc(at, 6.0, 0, TAU, 20, Color(1, 1, 1, 0.5), 1.0)
		# Watra w środku
		draw_circle(center, 7.0, Color(NawiaWindow.FIRE, 0.4 * pulse))
		draw_circle(center, 4.5, NawiaWindow.FIRE)
		draw_circle(center, 2.0, Color(1.0, 0.95, 0.7))

	func _process(_delta: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
