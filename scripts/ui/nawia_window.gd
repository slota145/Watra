class_name NawiaWindow
extends PanelContainer
## Okno Mapy Nawii (przycisk „Nawia” w oknie Watry, od NawiaMap.UNLOCK_LEVEL poziomu postaci): koło zaświatów z Watrą
## w środku, 6 obszarów (krainy) i węzły-lochy (NawiaMap). Odsłonięte węzły świecą, oczyszczone są jasne,
## nieodkryte to tylko blade punkty we mgle. Kliknięcie wybiera węzeł, „Wyrusz” otwiera okno lochów w trybie węzła
## (DungeonWindow.open_node - modyfikatory i bożki jak zwykle, wejście bez kosztów).
## Kolumna „Bogowie” (Pinnacles): fragmenty kluczy i serca każdego boga; „Wyzwij” zużywa fragmenty i przenosi na arenę,
## „Legenda” i „Pas” wymieniają serca na przedmioty boga. Pod bogami Władca Hordy (wejście za serce każdego boga)
## i - po jego pokonaniu - wybór stopnia Pomroku dla wszystkich aren.
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
## Bóg -> {"info": Label, "fight": Button, "legend": Button, "belt": Button (albo brak)}.
var _gods := {}
var _pomrok_row: HBoxContainer
var _pomrok_label: Label
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
	row.add_child(VSeparator.new())
	row.add_child(_build_gods())


## Kolumna bogów - bossów szczytowych (Pinnacles).
func _build_gods() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.add_child(UiStyle.title(Lang.t("Bogowie")))
	column.add_child(_wrapped(Lang.t("Strażnicy węzłów czasem zostawiają fragmenty kluczy bogów. %d fragmenty otwierają arenę.") % Pinnacles.FRAGMENTS, UiStyle.DIM_COLOR))
	for god: String in Pinnacles.ORDER:
		column.add_child(HSeparator.new())
		var info := _wrapped("", Pinnacles.GODS[god]["color"])
		column.add_child(info)
		var buttons := HBoxContainer.new()
		buttons.alignment = BoxContainer.ALIGNMENT_CENTER
		buttons.add_theme_constant_override("separation", 2)
		column.add_child(buttons)
		var entry := {"info": info}
		entry["fight"] = _button(Lang.t("Wyzwij"), _challenge.bind(god))
		buttons.add_child(entry["fight"])
		entry["legend"] = _button(Lang.t("Legenda"), _exchange.bind(god, "legend"))
		buttons.add_child(entry["legend"])
		if Pinnacles.GODS[god].has("belt"):
			entry["belt"] = _button(Lang.t("Pas"), _exchange.bind(god, "belt"))
			buttons.add_child(entry["belt"])
		_gods[god] = entry
	# Władca Hordy - ostateczny boss
	column.add_child(HSeparator.new())
	var lord := Pinnacles.LORD
	var lord_info := _wrapped("", Pinnacles.GODS[lord]["color"])
	column.add_child(lord_info)
	var lord_buttons := HBoxContainer.new()
	lord_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	lord_buttons.add_theme_constant_override("separation", 2)
	column.add_child(lord_buttons)
	var lord_entry := {"info": lord_info, "fight": _button(Lang.t("Wyzwij"), _challenge.bind(lord)),
			"legend": _button(Lang.t("Legenda"), _exchange.bind(lord, "legend"))}
	lord_buttons.add_child(lord_entry["fight"])
	lord_buttons.add_child(lord_entry["legend"])
	_gods[lord] = lord_entry
	# Pomrok - stopień trudności aren po pokonaniu Władcy
	_pomrok_row = HBoxContainer.new()
	_pomrok_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pomrok_row.add_theme_constant_override("separation", 4)
	_pomrok_row.add_child(_button("<", func() -> void: _player.boons.set_pomrok(_player.boons.pomrok - 1)))
	_pomrok_label = UiStyle.label("", 8, Color(1.0, 0.5, 0.4))
	_pomrok_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_pomrok_row.add_child(_pomrok_label)
	_pomrok_row.add_child(_button(">", func() -> void: _player.boons.set_pomrok(_player.boons.pomrok + 1)))
	column.add_child(_pomrok_row)
	return column


func _refresh_gods() -> void:
	var inventory := _player.inventory
	var pomrok := _player.boons.pomrok
	_pomrok_row.visible = _player.boons.pomrok_unlocked > 0
	_pomrok_label.text = Lang.t("Pomrok: %s") % (Pinnacles.roman(pomrok) if pomrok > 0 else Lang.t("brak"))
	_pomrok_label.tooltip_text = Lang.t("Stopień Pomroku dla wszystkich aren: poziom +%d, zdrowie +%d%%, obrażenia +%d%%, skarbiec +%d%%, legendy i pasy +%d%%. Kolejny stopień odblokowuje zwycięstwo nad Władcą na najwyższym.") % [
			Pinnacles.POMROK_LEVEL * pomrok, roundi((Pinnacles.pomrok_mult("health", pomrok) - 1.0) * 100.0),
			roundi((Pinnacles.pomrok_mult("damage", pomrok) - 1.0) * 100.0), roundi((Pinnacles.pomrok_mult("loot", pomrok) - 1.0) * 100.0),
			roundi((Pinnacles.pomrok_mult("drop", pomrok) - 1.0) * 100.0)]
	for god: String in _gods:
		var entry: Dictionary = _gods[god]
		if Pinnacles.is_lord(god):
			_refresh_lord(entry, pomrok)
			continue
		var fragments := inventory.count_of(Pinnacles.fragment(god))
		var hearts := inventory.count_of(Pinnacles.heart(god))
		var wins := int(_player.boons.pinnacle_kills.get(god, 0))
		(entry["info"] as Label).text = "%s\n%s" % [Pinnacles.god_name(god),
				Lang.t("Fragmenty: %d / %d   Serca: %d   Zwycięstwa: %d") % [fragments, Pinnacles.FRAGMENTS, hearts, wins]]
		var fight: Button = entry["fight"]
		fight.disabled = fragments < Pinnacles.FRAGMENTS
		fight.tooltip_text = Lang.t("Arena boga - poziom %d. Zużywa %d fragmenty.") % [Pinnacles.arena_level(god, pomrok), Pinnacles.FRAGMENTS]
		var legend: Button = entry["legend"]
		legend.disabled = hearts < Pinnacles.HEART_COST
		legend.tooltip_text = Lang.t("%d serca: jedna z legend boga (%s)") % [Pinnacles.HEART_COST,
				", ".join((Pinnacles.GODS[god]["legends"] as Array).map(func(id: String) -> String: return Lang.t(Legends.DATA[id]["name"])))]
		if entry.has("belt"):
			var belt: Button = entry["belt"]
			belt.disabled = hearts < Pinnacles.BELT_COST
			belt.tooltip_text = Lang.t("%d serc: %s") % [Pinnacles.BELT_COST, Lang.t(Legends.DATA[Pinnacles.GODS[god]["belt"]]["name"])]


func _refresh_lord(entry: Dictionary, pomrok: int) -> void:
	var lord := Pinnacles.LORD
	var hearts := _player.inventory.count_of(Pinnacles.heart(lord))
	var wins := int(_player.boons.pinnacle_kills.get(lord, 0))
	(entry["info"] as Label).text = "%s\n%s" % [Pinnacles.god_name(lord),
			Lang.t("Wejście: serce każdego boga   Serca Władcy: %d   Zwycięstwa: %d") % [hearts, wins]]
	var fight: Button = entry["fight"]
	fight.disabled = not Pinnacles.can_challenge_lord(_player.inventory)
	fight.tooltip_text = Lang.t("Ostateczny boss - poziom %d. Zużywa po %d sercu Welesa, Marzanny i Czarnoboga.") % [
			Pinnacles.arena_level(lord, pomrok), Pinnacles.LORD_COST]
	var legend: Button = entry["legend"]
	legend.disabled = hearts < Pinnacles.HEART_COST
	legend.tooltip_text = Lang.t("%d serca: jedna z legend boga (%s)") % [Pinnacles.HEART_COST,
			", ".join((Pinnacles.GODS[lord]["legends"] as Array).map(func(id: String) -> String: return Lang.t(Legends.DATA[id]["name"])))]


## Wyzwanie boga: zużywa fragmenty (Władca - serca bogów) i przenosi na arenę na wybranym stopniu Pomroku
## (premie drzewka Watry jak w zwykłym lochu).
func _challenge(god: String) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	if Pinnacles.is_lord(god):
		if not Pinnacles.pay_lord(_player.inventory):
			return
	elif not _player.inventory.remove_item(Pinnacles.fragment(god), Pinnacles.FRAGMENTS):
		return
	visible = false
	world.enter_dungeon(Pinnacles.config(god, randi(), _player.boons.tree_effects(), _player.boons.pomrok))


## Wymiana serc na legendę albo pas boga (do plecaka, a gdy pełny - do magazynu).
func _exchange(god: String, what: String) -> void:
	var item := Pinnacles.exchange_item(god, what)
	if item == "" or not _player.inventory.remove_item(Pinnacles.heart(god), Pinnacles.exchange_cost(what)):
		return
	var id := Loot.legendary_at_level(item, mini(int(Pinnacles.GODS[god]["level"]), Loot.MAX_ITEM_LEVEL))
	if _player.inventory.add_item(id, 1) > 0:
		_player.storage.add_item(id, 1)
	Sfx.play("magic")
	_info.text = Lang.t("Otrzymano: %s") % Items.display_name(id)
	_refresh_gods()


func setup(player: Player) -> void:
	_player = player
	player.boons.changed.connect(func() -> void:
		if visible:
			_refresh())
	player.inventory.changed.connect(func() -> void:
		if visible:
			_refresh_gods())


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
	_refresh_gods()
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
