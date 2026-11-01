class_name EventResult
extends PanelContainer
## Wynik wydarzenia w świecie (WorldEvents.finished): tytuł, sukces albo porażka, ranking wkładu (pierwsza piątka
## i miejsce gracza) i nagrody gracza (Znaki Zwycięstwa, sława gildii, skrzynia na miejscu). Znika po SHOW_TIME s.

const SHOW_TIME := 14.0
const WIDTH := 220.0

var _box: VBoxContainer
var _left := 0.0


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.95), Color(1.0, 0.8, 0.4), 6))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 1)
	add_child(_box)


func show_result(result: Dictionary) -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	var color: Color = WorldEvents.TYPES[result["type"]]["color"]
	_add(WorldEvents.title_of(result), 9, color)
	_add((tr("Sukces! %s") if result["success"] else tr("Porażka. %s")) % tr(Zones.zone_name(result["zone"])), 8,
			Color(0.6, 1.0, 0.6) if result["success"] else Color(1.0, 0.5, 0.45))
	var list: Array = result["ranking"]
	var place: int = result["place"]
	for i in mini(5, list.size()):
		var mine: bool = list[i][0] == WorldEvents.PLAYER
		_add(tr("%d. %s - %d pkt") % [i + 1, WorldEvents.who(list[i][0]), list[i][1]], 7, Color(1.0, 0.9, 0.5) if mine else UiStyle.TEXT_COLOR)
	if place > 5:
		_add("...", 7, UiStyle.DIM_COLOR)
		_add(tr("%d. Ty - %d pkt") % [place, list[place - 1][1]], 7, Color(1.0, 0.9, 0.5))
	if place == 0:
		_add(tr("Bez twojego udziału - nagrody przypadły innym."), 7, UiStyle.DIM_COLOR)
	else:
		var rewards: Array[String] = [tr("Znaki Zwycięstwa x%d") % result["marks"]]
		if result["fame"] > 0:
			rewards.append(tr("sława gildii +%d") % result["fame"])
		if result["success"] and result.get("here", false):
			rewards.append(tr("skrzynia z łupem na miejscu"))
		var label := _add(tr("Nagroda: %s") % ", ".join(rewards), 7, Color(0.6, 1.0, 0.6))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := Button.new()
	close.text = tr("Zamknij")
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 7)
	close.pressed.connect(func() -> void: visible = false)
	_box.add_child(close)
	visible = true
	_left = SHOW_TIME
	reset_size()
	position = Vector2(((get_viewport_rect().size.x - size.x) / 2.0), 60.0).floor()
	Sfx.play("quest_done" if result["success"] else "ui_error")


func _add(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(text, font_size, color)
	label.custom_minimum_size.x = WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(label)
	return label


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		visible = false
