class_name TalismanWindow
extends PanelContainer
## Okno talizmanów (przycisk „Talizmany” w ekwipunku): siatka Talismans.GRID kratek, w którą wkłada się talizmany
## z Kręgu Żertwy (Equipment.talismans). Talizman zajmuje tyle kratek, ile ma jego kształt (1x1, 1x2, 2x1, 2x2).
## Przeciągnij talizman z plecaka na siatkę (środek talizmanu pod kursorem), przesuń go w siatce albo przeciągnij
## z powrotem do plecaka; PPM na talizmanie w siatce - wyjmij, PPM na talizmanie w plecaku - włóż w wolne miejsce.
## Pod siatką suma premii ze wszystkich talizmanów.

## Bok kratki siatki (piksele interfejsu).
const CELL := 24.0
const GAP := 2.0

var _player: Player
var _grid: Control
var _pieces: Array[Panel] = []
var _summary: RichTextLabel


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(Lang.t("Talizmany")))
	_grid = Control.new()
	_grid.custom_minimum_size = Vector2(Talismans.GRID) * (CELL + GAP) - Vector2(GAP, GAP)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.draw.connect(_draw_grid)
	_grid.set_drag_forwarding(Callable(), _can_drop.bind(null), _drop.bind(null))
	box.add_child(_grid)
	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.custom_minimum_size = Vector2(150, 0)
	_summary.add_theme_font_size_override("normal_font_size", 7)
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_summary)
	var hint := UiStyle.label(Lang.t("Przeciągnij talizman z plecaka   •   PPM - wyjmij"), 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


func setup(player: Player) -> void:
	_player = player
	player.equipment.changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()
		reset_size()


## Kratka siatki pod punktem (w układzie siatki).
static func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / (CELL + GAP)), floori(point.y / (CELL + GAP)))


## Lewy górny róg talizmanu `id` upuszczonego tak, że jego środek leży w `point` (układ siatki).
static func drop_cell(id: String, point: Vector2) -> Vector2i:
	var size := Vector2(Talismans.size_of(id))
	var corner := point / (CELL + GAP) - size / 2.0 + Vector2(0.5, 0.5)
	return Vector2i(floori(corner.x), floori(corner.y))


func _draw_grid() -> void:
	for y in Talismans.GRID.y:
		for x in Talismans.GRID.x:
			var rect := Rect2(Vector2(x, y) * (CELL + GAP), Vector2(CELL, CELL))
			_grid.draw_rect(rect, UiStyle.SLOT_BG)
			_grid.draw_rect(rect, UiStyle.SLOT_BORDER, false, 1.0)


func _refresh() -> void:
	if _player == null or not is_visible_in_tree():
		return
	for piece in _pieces:
		_grid.remove_child(piece)
		piece.queue_free()
	_pieces.clear()
	var talismans := _player.equipment.talismans
	for i in talismans.size():
		var id: String = talismans[i]["id"]
		var size := Vector2(Talismans.size_of(id))
		var piece := Panel.new()
		UiStyle.rich_tooltip(piece)
		piece.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.2, 0.16, 0.13, 0.95), UiStyle.BORDER, 0))
		piece.position = Vector2(talismans[i]["cell"]) * (CELL + GAP)
		piece.size = size * (CELL + GAP) - Vector2(GAP, GAP)
		var icon := TextureRect.new()
		icon.texture = Items.get_data(id).get("icon")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 2
		icon.offset_top = 2
		icon.offset_right = -2
		icon.offset_bottom = -2
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.add_child(icon)
		UiStyle.set_item_frame(piece, id)
		piece.tooltip_text = Items.describe(id) + "\n" + Lang.t("PPM - wyjmij")
		piece.gui_input.connect(_on_piece_input.bind(i))
		piece.set_drag_forwarding(_drag_from.bind(i), _can_drop.bind(piece), _drop.bind(piece))
		_grid.add_child(piece)
		_pieces.append(piece)
	_summary.text = summary_text(talismans)


## Suma premii i efektów wszystkich talizmanów w siatce (BBCode).
static func summary_text(talismans: Array[Dictionary]) -> String:
	if talismans.is_empty():
		return "[center][color=#%s]%s[/color][/center]" % [UiStyle.DIM_COLOR.to_html(false), Lang.t("Talizmany zdobywa się w Kręgu Żertwy (lochy Watry)")]
	var totals := {}
	var effects: Array[String] = []
	for entry: Dictionary in talismans:
		var data := Items.get_data(entry["id"])
		for stat: String in data.get("stats", {}):
			totals[stat] = float(totals.get(stat, 0.0)) + float(data["stats"][stat])
		if data.has("effect"):
			effects.append(Items.effect_text(data["effect"]["kind"], "%d%%" % roundi(float(data["effect"]["chance"]) * 100.0)
					if not data["effect"]["kind"] in Items.COUNT_EFFECTS else str(roundi(data["effect"]["chance"]))))
	var lines: Array[String] = []
	for stat: String in Talismans.POOL:
		if totals.has(stat):
			lines.append("[color=%s]%s[/color]" % [Items.AFFIX_COLOR, Items._stat_text(stat, totals[stat])])
	for text in effects:
		lines.append("[color=#%s]%s[/color]" % [Items.LEGENDARY_COLOR.to_html(false), text])
	return "\n".join(lines)


func _on_piece_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		if _player.remove_talisman(index):
			Sfx.play("pickup")
		else:
			Sfx.play("ui_error")


func _drag_from(_at: Vector2, index: int) -> Variant:
	if _player == null or index >= _player.equipment.talismans.size():
		return null
	var id: String = _player.equipment.talismans[index]["id"]
	_pieces[index].set_drag_preview(UiStyle.drag_preview(Items.get_data(id)["icon"]))
	Sfx.play("ui_click")
	return {"talisman": index}


## Id przeciąganego talizmanu i indeks w siatce (-1 - z plecaka); "" - to nie talizman.
func _dragged(data: Variant) -> Array:
	if not data is Dictionary or _player == null:
		return ["", -1]
	if data.has("talisman"):
		var index: int = data["talisman"]
		return [_player.equipment.talismans[index]["id"] if index < _player.equipment.talismans.size() else "", index]
	if data.get("inventory") == _player.inventory:
		var id: String = _player.inventory.slots[data["index"]].get("id", "")
		return [id if Talismans.is_talisman(id) else "", -1]
	return ["", -1]


func _point(at: Vector2, over: Control) -> Vector2:
	return at + (over.position if over != null else Vector2.ZERO)


func _can_drop(at: Vector2, data: Variant, over: Control) -> bool:
	var dragged := _dragged(data)
	if dragged[0] == "":
		return false
	return _player.equipment.can_place_talisman(dragged[0], drop_cell(dragged[0], _point(at, over)), dragged[1])


func _drop(at: Vector2, data: Variant, over: Control) -> void:
	var dragged := _dragged(data)
	var cell := drop_cell(dragged[0], _point(at, over))
	var ok := _player.equipment.move_talisman(dragged[1], cell) if dragged[1] >= 0 \
			else _player.place_talisman(data["index"], cell)
	Sfx.play("pickup" if ok else "ui_error")
