class_name WatraTreeWindow
extends PanelContainer
## Okno drzewka Watry (WatraTree; przycisk „Drzewko” w oknie Watry i na Mapie Nawii). Po lewej sieć węzłów wokół Watry:
## przeciąganie myszą przesuwa widok, kółko przybliża. Kliknięcie zaznacza węzeł, „Wybierz” wydaje na niego punkt
## Watry, „Cofnij” oddaje punkt za złoto (tylko węzeł, od którego nic dalej nie zależy), a „Wyczyść zakładkę” cofa
## wszystkie węzły zakładki naraz, taniej. Trzy zakładki u góry (Boons.watra_tabs) mają osobne, pełne pule punktów
## i własne nazwy; działa wybrana, a w lochu nie można jej zmienić (loch zapamiętał premie przy wejściu).

const FIRE := Color(1.0, 0.6, 0.25)
const GOLD := Color(1.0, 0.82, 0.35)
const VIEW_SIZE := Vector2(320, 270)
const SIDE := 140.0
## Wysokość pola z opisem węzła (dłuższy opis się przewija).
const INFO_HEIGHT := 70.0

var _player: Player
var _view: WatraTreeView
var _tabs: Array[Button] = []
var _tab_name: LineEdit
var _points: Label
var _info: Label
var _status: Label
var _allocate: Button
var _refund: Button
var _reset: Button
var selected := ""
## Pierwsze kliknięcie „Wyczyść zakładkę” prosi o potwierdzenie, drugie czyści.
var _confirm_reset := false


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.12, 0.06, 0.04, 0.98), Color(0.85, 0.45, 0.18), 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_view = WatraTreeView.new()
	_view.window = self
	_view.custom_minimum_size = VIEW_SIZE
	row.add_child(_view)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	row.add_child(box)
	box.add_child(UiStyle.title(Lang.t("Drzewko Watry")))
	box.add_child(_wrapped(Lang.t("Punkt Watry za każdy oczyszczony węzeł Nawii. Każda zakładka ma własną, pełną pulę - działa wybrana."), UiStyle.DIM_COLOR))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 2)
	box.add_child(tabs)
	for tab in WatraTree.TABS:
		var button := _button("", _on_tab.bind(tab))
		button.toggle_mode = true
		button.clip_text = true
		button.custom_minimum_size.x = SIDE / WatraTree.TABS - 2.0
		tabs.add_child(button)
		_tabs.append(button)
	_tab_name = LineEdit.new()
	_tab_name.placeholder_text = Lang.t("Nazwa zakładki")
	_tab_name.max_length = 16
	_tab_name.add_theme_font_size_override("font_size", 7)
	_tab_name.custom_minimum_size = Vector2(SIDE, 14)
	_tab_name.text_changed.connect(_on_tab_named)
	box.add_child(_tab_name)
	_points = _wrapped("", FIRE)
	box.add_child(_points)
	box.add_child(HSeparator.new())
	# opis węzła albo premie zakładki - w polu z przewijaniem, żeby okno nie zmieniało rozmiaru
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(SIDE, INFO_HEIGHT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_info = _wrapped("", UiStyle.TEXT_COLOR)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info.custom_minimum_size.x = SIDE - 8.0
	scroll.add_child(_info)
	_status = _wrapped("", GOLD)
	box.add_child(_status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 4)
	_allocate = _button(Lang.t("Wybierz"), _on_allocate)
	actions.add_child(_allocate)
	_refund = _button("", _on_refund)
	actions.add_child(_refund)
	box.add_child(actions)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 4)
	_reset = _button("", _on_reset)
	bottom.add_child(_reset)
	bottom.add_child(_button(Lang.t("Zamknij"), func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.boons.changed.connect(_refresh_if_open)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh_if_open())


func open() -> void:
	visible = true
	_status.text = ""
	_confirm_reset = false
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func chosen() -> Array:
	return _player.boons.tree_nodes() if _player != null else []


func select(id: String) -> void:
	selected = id
	_status.text = ""
	_confirm_reset = false
	Sfx.play("ui_click")
	_refresh()


## Czy gracz jest w lochu (wtedy zakładki nie da się zmienić).
func _in_dungeon() -> bool:
	var world := get_tree().get_first_node_in_group("world")
	return world != null and str(world.zone) == "dungeon"


func _refresh_if_open() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if _player == null:
		return
	var boons := _player.boons
	var in_dungeon := _in_dungeon()
	for tab in _tabs.size():
		_tabs[tab].text = boons.tree_tab_name(tab)
		_tabs[tab].set_pressed_no_signal(tab == boons.watra_tab)
		_tabs[tab].disabled = in_dungeon and tab != boons.watra_tab
		_tabs[tab].tooltip_text = Lang.t("W lochu działa zakładka z chwili wejścia.") if in_dungeon \
				else Lang.t("Wydane: %d punktów") % boons.tree_nodes(tab).size()
	if not _tab_name.has_focus():
		_tab_name.text = str(boons.watra_tab_names[boons.watra_tab])
	_points.text = Lang.t("Wolne punkty: %d z %d") % [boons.tree_free(), boons.watra_points()]
	var level := _player.stats.level
	var nodes := boons.tree_nodes()
	if selected == "" or not WatraTree.has_node(selected):
		selected = ""
		var lines := WatraTree.effect_lines(boons.tree_effects())
		_info.text = Lang.t("Wybierz węzeł na drzewku.") + "\n\n" + (Lang.t("Premie zakładki:") + "\n" + "\n".join(lines) \
				if not lines.is_empty() else Lang.t("Zakładka nie ma jeszcze wybranych węzłów."))
	else:
		var text := WatraTree.node_name(selected)
		var branch: String = WatraTree.nodes()[selected]["branch"]
		if branch != "":
			text += "\n" + Lang.t("Gałąź: %s") % WatraTree.branch_name(branch)
		_info.text = text + "\n\n" + "\n".join(WatraTree.node_lines(selected))
	var can_take := boons.tree_can_allocate(selected)
	_allocate.disabled = not can_take
	_allocate.tooltip_text = "" if can_take else (Lang.t("Brak wolnych punktów Watry.") if boons.tree_free() <= 0 \
			else Lang.t("Wybierz węzeł połączony z już wybranym."))
	var refund_cost := WatraTree.refund_cost(level)
	_refund.text = Lang.t("Cofnij (%d zł)") % refund_cost
	_refund.disabled = not WatraTree.can_refund(nodes, selected) or _player.stats.gold < refund_cost
	_refund.tooltip_text = Lang.t("Cofnąć można tylko węzeł, od którego nic dalej nie zależy.")
	var reset_cost := WatraTree.reset_cost(level, nodes.size())
	_reset.text = (Lang.t("Na pewno? (%d zł)") if _confirm_reset else Lang.t("Wyczyść zakładkę (%d zł)")) % reset_cost
	_reset.disabled = nodes.is_empty() or _player.stats.gold < reset_cost
	_view.queue_redraw()


func _on_tab(tab: int) -> void:
	if _in_dungeon():
		_refresh()
		return
	_player.boons.set_tree_tab(tab)
	_tab_name.release_focus()
	_status.text = Lang.t("Działa zakładka: %s") % _player.boons.tree_tab_name(tab)
	_confirm_reset = false
	Sfx.play("ui_click")
	_refresh()


func _on_tab_named(text: String) -> void:
	_player.boons.watra_tab_names[_player.boons.watra_tab] = text.strip_edges()
	_tabs[_player.boons.watra_tab].text = _player.boons.tree_tab_name(_player.boons.watra_tab)


func _on_allocate() -> void:
	if _player.boons.tree_allocate(selected):
		_status.text = Lang.t("Wybrano: %s") % WatraTree.node_name(selected)
		Sfx.play("magic")


func _on_refund() -> void:
	var cost := WatraTree.refund_cost(_player.stats.level)
	if _player.stats.gold < cost or not WatraTree.can_refund(chosen(), selected):
		return
	_player.stats.add_gold(-cost)
	_player.boons.tree_refund(selected)
	_status.text = Lang.t("Cofnięto: %s") % WatraTree.node_name(selected)
	Sfx.play("coins")


func _on_reset() -> void:
	var cost := WatraTree.reset_cost(_player.stats.level, chosen().size())
	if chosen().is_empty() or _player.stats.gold < cost:
		return
	if not _confirm_reset:
		_confirm_reset = true
		_refresh()
		return
	_confirm_reset = false
	_player.stats.add_gold(-cost)
	_player.boons.tree_reset()
	_status.text = Lang.t("Zakładka wyczyszczona.")
	Sfx.play("coins")


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
	button.add_theme_font_size_override("font_size", 7)
	button.custom_minimum_size = Vector2(18, 14)
	button.pressed.connect(on_pressed)
	return button


## Rysunek drzewka: Watra w środku, 12 gałęzi z nazwami, połączenia i węzły (małe koła, znaczące - większe, kluczowe -
## romby). Wybrane mają złotą obwódkę i złote połączenia, możliwe do wybrania teraz - pulsującą jasną.
class WatraTreeView extends Control:
	const UNIT := 12.0
	## Szerokość nazwy gałęzi przed złamaniem linii.
	const LABEL_WIDTH := 52.0
	const ZOOM_RANGE := Vector2(0.8, 2.2)
	const RADIUS := {"start": 6.0, "small": 3.2, "notable": 4.6, "keystone": 5.6}
	const LINK := Color(0.4, 0.3, 0.25)
	var window: WatraTreeWindow
	var _hover := ""
	var _offset := Vector2.ZERO
	var _zoom := 1.0
	var _press := Vector2.ZERO
	var _dragged := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true

	func _point(id: String) -> Vector2:
		return size / 2.0 + _offset + (WatraTree.nodes()[id]["pos"] as Vector2) * UNIT * _zoom

	func _node_at(at: Vector2) -> String:
		var best := ""
		var best_d := INF
		for id: String in WatraTree.nodes():
			var reach: float = RADIUS[WatraTree.nodes()[id]["kind"]] * _zoom + 2.0
			var d := _point(id).distance_to(at)
			if d <= reach and d < best_d:
				best_d = d
				best = id
		return best

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and not event.ctrl_pressed:
					var before := _zoom
					_zoom = clampf(_zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), ZOOM_RANGE.x, ZOOM_RANGE.y)
					# przybliżanie wokół kursora
					var anchor: Vector2 = event.position - size / 2.0
					_offset = anchor - (anchor - _offset) * (_zoom / before)
					queue_redraw()
					accept_event()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_press = event.position
					_dragged = false
				elif not _dragged:
					var id := _node_at(event.position)
					if id != "":
						window.select(id)
				accept_event()
		elif event is InputEventMouseMotion:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				if _dragged or event.position.distance_to(_press) > 3.0:
					_dragged = true
					_offset += event.relative
					queue_redraw()
				return
			var hover := _node_at(event.position)
			if hover != _hover:
				_hover = hover
				tooltip_text = "" if hover == "" else "%s\n%s" % [WatraTree.node_name(hover), "\n".join(WatraTree.node_lines(hover))]
				queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.03, 0.02))
		var nodes := WatraTree.nodes()
		var chosen := window.chosen()
		var font := get_theme_default_font()
		var center := _point(WatraTree.START)
		draw_circle(center, 9.0 * UNIT * _zoom, Color(0.12, 0.06, 0.03))
		# nazwy gałęzi za końcami ścieżek, odsunięte na zewnątrz (z prawej od punktu, z lewej przed nim)
		var sector := TAU / WatraTree.BRANCH_ORDER.size()
		for i in WatraTree.BRANCH_ORDER.size():
			var branch := WatraTree.BRANCH_ORDER[i]
			var direction := Vector2.from_angle(-PI / 2.0 + i * sector)
			var at := center + direction * (8.6 * UNIT * _zoom + 4.0)
			var lines := _wrap(font, WatraTree.branch_name(branch))
			var top := at.y - 7.0 * lines.size() * (0.5 - 0.5 * direction.y) + 5.0
			for line in lines:
				var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
				draw_string(font, Vector2(at.x - width * (0.5 - 0.5 * direction.x), top), line, HORIZONTAL_ALIGNMENT_LEFT,
						-1, 6, Color(WatraTree.BRANCH_COLORS[branch], 0.85))
				top += 7.0
		# połączenia
		for id: String in nodes:
			for other: String in nodes[id]["links"]:
				if other < id:
					continue
				var lit := (id == WatraTree.START or chosen.has(id)) and (other == WatraTree.START or chosen.has(other))
				draw_line(_point(id), _point(other), WatraTreeWindow.GOLD if lit else LINK, 1.5 if lit else 1.0)
		# węzły
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)
		var free := window._player.boons.tree_free() > 0 if window._player != null else false
		for id: String in nodes:
			var node: Dictionary = nodes[id]
			var at := _point(id)
			var radius: float = RADIUS[node["kind"]] * _zoom
			var taken: bool = id == WatraTree.START or chosen.has(id)
			var tint: Color = WatraTreeWindow.FIRE if id == WatraTree.START else WatraTree.BRANCH_COLORS[node["branch"]]
			var fill := tint if taken else tint.darkened(0.65)
			if node["kind"] == "keystone":
				var diamond := PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, 0), at + Vector2(0, radius), at + Vector2(-radius, 0)])
				draw_colored_polygon(diamond, fill)
				diamond.append(diamond[0])
				draw_polyline(diamond, WatraTreeWindow.GOLD if taken else Color(tint, 0.6), 1.0)
			else:
				draw_circle(at, radius, fill)
				draw_arc(at, radius, 0, TAU, 16, WatraTreeWindow.GOLD if taken else Color(tint, 0.5), 1.0)
			if not taken and free and WatraTree.can_allocate(chosen, id):
				draw_arc(at, radius + 1.5, 0, TAU, 16, Color(1, 1, 1, pulse), 1.0)
			if id == window.selected:
				draw_arc(at, radius + 3.0, 0, TAU, 20, Color.WHITE, 1.0)
			elif id == _hover:
				draw_arc(at, radius + 2.5, 0, TAU, 20, Color(1, 1, 1, 0.5), 1.0)
		# Watra w środku
		draw_circle(center, 3.0 * _zoom, Color(1.0, 0.95, 0.7))

	## Dzieli nazwę na linie nie szersze niż LABEL_WIDTH.
	func _wrap(font: Font, text: String) -> Array[String]:
		var lines: Array[String] = []
		for word in text.split(" "):
			if not lines.is_empty() and font.get_string_size(lines.back() + " " + word, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x <= LABEL_WIDTH:
				lines[-1] += " " + word
			else:
				lines.append(word)
		return lines

	func _process(_delta: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
