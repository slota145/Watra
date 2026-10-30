class_name StatusRow
extends HFlowContainer
## Ikony efektów działających na gracza pod paskami zdrowia i many (lista z StatusEffects):
## złota ramka - premia, czerwona - osłabienie, szara - efekt się odnawia. Pod ikoną zostały czas ("18m", "45s"),
## w rogu liczba ładunków; ostatnie 5 sekund ikona mruga. Po najechaniu myszą dymek z nazwą, opisem i czasem.

const ICON_SIZE := 14.0
const REFRESH := 0.2
const BLINK_TIME := 5.0
const BORDERS := {"good": Color(0.95, 0.78, 0.35), "bad": Color(0.95, 0.3, 0.28), "cooldown": Color(0.55, 0.56, 0.62)}

var _player: Player
var _timer := 0.0
## Gotowe ikony (używane ponownie, żeby dymek nie znikał przy każdym odświeżeniu).
var _cells: Array[Control] = []
var _styles := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 1)
	for kind: String in BORDERS:
		_styles[kind] = UiStyle.panel(Color(0.08, 0.08, 0.12, 0.85), BORDERS[kind], 0)


func setup(player: Player) -> void:
	_player = player
	_refresh()


func _process(delta: float) -> void:
	if _player == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH
		_refresh()


func _refresh() -> void:
	var effects := StatusEffects.list(_player)
	while _cells.size() < effects.size():
		var cell := _make_cell()
		add_child(cell)
		_cells.append(cell)
	var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 110.0)
	for i in _cells.size():
		var cell := _cells[i]
		cell.visible = i < effects.size()
		if not cell.visible:
			continue
		var effect: Dictionary = effects[i]
		var frame: Panel = cell.get_child(0)
		var icon: TextureRect = frame.get_child(0)
		var stacks: Label = frame.get_child(1)
		var time: Label = cell.get_child(1)
		var left: float = effect.get("left", -1.0)
		frame.add_theme_stylebox_override("panel", _styles[effect["kind"]])
		icon.texture = effect["icon"]
		stacks.text = str(effect["stacks"]) if effect.get("stacks", 0) > 1 else ""
		time.text = StatusEffects.time_text(left)
		cell.modulate.a = blink if left >= 0.0 and left < BLINK_TIME and effect["kind"] != "cooldown" else 1.0
		cell.tooltip_text = "%s\n%s%s" % [effect["name"], effect["description"],
				("\nZostało: %s" % _long_time(left)) if left >= 0.0 else ""]


func _make_cell() -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 0)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.theme = UiStyle.make_theme()
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(frame)
	var icon := TextureRect.new()
	UiStyle.fit_icon(icon, ICON_SIZE - 2.0)
	icon.position = Vector2(1, 1)
	icon.size = Vector2(ICON_SIZE - 2.0, ICON_SIZE - 2.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)
	var stacks := UiStyle.label("", 6, Color(1.0, 0.95, 0.8))
	stacks.position = Vector2(ICON_SIZE - 6.0, ICON_SIZE - 9.0)
	stacks.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	stacks.add_theme_constant_override("outline_size", 3)
	stacks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(stacks)
	var time := UiStyle.label("", 6, UiStyle.TEXT_COLOR)
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time.custom_minimum_size.x = ICON_SIZE
	time.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	time.add_theme_constant_override("outline_size", 3)
	time.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(time)
	return cell


## Czas w dymku: "14 min 05 s" albo "45 s".
static func _long_time(left: float) -> String:
	var seconds := ceili(left)
	if seconds >= 60:
		return "%d min %02d s" % [seconds / 60, seconds % 60]
	return "%d s" % seconds
