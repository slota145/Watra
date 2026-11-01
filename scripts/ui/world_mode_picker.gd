class_name WorldModePicker
extends VBoxContainer
## Wybór trybu świata (WorldModes) - w menu nowej gry i u żercy Wszebora: trzy karty z nazwą, krótkim hasłem
## i pełnym wyjaśnieniem, co tryb zmienia (dla kogoś, kto gra pierwszy raz). Kliknięcie karty - sygnał `chosen`.

signal chosen(mode: String)

const CARD_WIDTH := 150.0

var current := ""


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var title := UiStyle.title(tr("Tryb świata"))
	add_child(title)
	var intro := UiStyle.label(tr("Jak zachowują się inni podróżnicy (symulowani gracze) wobec ciebie? Tryb możesz później zmienić u żercy Wszebora przy Watrze w Ostoi."), 7, UiStyle.DIM_COLOR)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = CARD_WIDTH * 3 + 12.0
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(intro)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for id: String in WorldModes.ORDER:
		row.add_child(_card(id))


func _card(id: String) -> Button:
	var data: Dictionary = WorldModes.MODES[id]
	var card := Button.new()
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = Vector2(CARD_WIDTH, 150)
	card.toggle_mode = true
	card.set_pressed_no_signal(id == current)
	card.pressed.connect(func() -> void: chosen.emit(id))
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 6
	inner.offset_right = -6
	inner.offset_top = 6
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 3)
	card.add_child(inner)
	var name := UiStyle.label(tr(data["name"]) + (tr("  (obecny)") if id == current else ""), 9, data["color"])
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name)
	var short := UiStyle.label(tr(data["short"]), 7, UiStyle.TITLE_COLOR)
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	short.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(short)
	var text := UiStyle.label(tr(data["description"]), 6, UiStyle.TEXT_COLOR)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = CARD_WIDTH - 12.0
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text)
	return card
