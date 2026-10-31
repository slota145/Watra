class_name PartyOffer
extends PanelContainer
## Okienko zaproszenia do drużyny albo prośby o pomoc od napotkanych podróżników (World._process_party_offers):
## tekst i przyciski "Dołącz" / "Odmów"; bez odpowiedzi znika po TIMEOUT sekundach jak odmowa.

const TIMEOUT := 20.0

var _text: Label
var _accept: Callable
var _decline: Callable
var _left := 0.0
var _time: Label
var _yes: Button


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.95), Traveler.PARTY_COLOR, 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_text = UiStyle.label("", 8, UiStyle.TEXT_COLOR)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 230
	box.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	for entry: Array in [["Dołącz", true], ["Odmów", false]]:
		var button := Button.new()
		button.text = entry[0]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_answer.bind(entry[1]))
		buttons.add_child(button)
		if entry[1]:
			_yes = button
	_time = UiStyle.label("", 6, UiStyle.DIM_COLOR)
	buttons.add_child(_time)


func ask(text: String, on_accept: Callable, on_decline: Callable, accept_label := "Dołącz") -> void:
	_text.text = text
	_yes.text = accept_label
	_accept = on_accept
	_decline = on_decline
	_left = TIMEOUT
	visible = true
	reset_size()
	position = Vector2(((get_viewport_rect().size.x - size.x) / 2.0), 60).floor()
	Sfx.play("quest_ready")


func is_open() -> bool:
	return visible


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	_time.text = "%d s" % ceili(_left)
	if _left <= 0.0:
		_answer(false)


func _answer(yes: bool) -> void:
	if not visible:
		return
	visible = false
	Sfx.play("ui_confirm" if yes else "ui_close")
	var action := _accept if yes else _decline
	if action.is_valid():
		action.call()
