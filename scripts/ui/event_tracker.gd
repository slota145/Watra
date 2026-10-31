class_name EventTracker
extends PanelContainer
## Panel trwającego wydarzenia w świecie (WorldEvents) po lewej, pod ramkami drużyny: tytuł, kraina i pozostały czas, cel
## (zdrowie kapliczki i fala, zdrowie czempiona albo bossa - EventSite.objective_text) oraz miejsce gracza
## w rankingu wkładu. W innej krainie podpowiada, gdzie iść. Przez chwilę po początku pokazuje opis wydarzenia.

const WIDTH := 160.0

var site: EventSite
var _player: Player
var _title: Label
var _where: Label
var _goal: Label
var _place: Label
var _message: Label
var _message_left := 0.0
var _tick := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.82), Color(1.0, 0.75, 0.35, 0.8), 4))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_title = _line(box, 8, UiStyle.TITLE_COLOR)
	_where = _line(box, 7, UiStyle.DIM_COLOR)
	_goal = _line(box, 7, UiStyle.TEXT_COLOR)
	_place = _line(box, 7, Color(0.6, 1.0, 0.6))
	_message = _line(box, 7, Color(1.0, 0.9, 0.7))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _line(box: Control, font_size: int, color: Color) -> Label:
	var label := UiStyle.label("", font_size, color)
	label.custom_minimum_size.x = WIDTH
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label


func setup(player: Player) -> void:
	_player = player


func show_message(text: String) -> void:
	_message.text = text
	_message_left = 12.0
	_refresh()


func _process(delta: float) -> void:
	_message_left = maxf(_message_left - delta, 0.0)
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	_refresh()


func _refresh() -> void:
	if _player == null:
		return
	var events := _player.events
	visible = not events.active.is_empty()
	if not visible:
		return
	var event := events.active
	var color: Color = WorldEvents.TYPES[event["type"]]["color"]
	_title.text = event["title"]
	_title.add_theme_color_override("font_color", color)
	var left := maxi(0, ceili(float(event["left"])))
	_where.text = "%s  -  %d:%02d" % [Zones.zone_name(event["zone"]), left / 60, left % 60]
	var here := site != null and is_instance_valid(site) and not site.done
	_goal.text = site.objective_text() if here else "Wydarzenie w innej krainie - idź tam albo teleportuj się (M)"
	var place := events.player_place()
	var count := events.ranking().size()
	_place.visible = here
	_place.text = ("Twoje miejsce: %d/%d" % [place, count]) if place > 0 else "Walcz, żeby trafić do rankingu"
	_message.visible = _message_left > 0.0
	reset_size()
