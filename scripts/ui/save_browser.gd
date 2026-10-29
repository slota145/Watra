class_name SaveBrowser
extends Control
## Lista zapisów gry (menu główne i menu pauzy). Każdy zapis ma miniaturkę ekranu z chwili
## zapisu, nazwę, poziom postaci, krainę i datę. Dwa tryby:
## - "save": nowy zapis z własną nazwą albo nadpisanie istniejącego,
## - "load": wczytanie wybranego zapisu.
## W obu trybach zapis można usunąć (drugie kliknięcie potwierdza).

signal closed

const THUMB := Vector2(96, 54)

var mode := "load"
## Dane gry i zrzut ekranu do zapisu (tryb "save").
var save_data: Dictionary = {}
var snapshot: Image

var _name_edit: LineEdit
var _list: VBoxContainer
var _status: Label
## Przycisk czekający na potwierdzenie (nadpisanie / usunięcie) - drugie kliknięcie wykonuje.
var _armed: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.make_menu_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.1, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0), UiStyle.BORDER, 8))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := UiStyle.title("Zapisz grę" if mode == "save" else "Wczytaj grę")
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	if mode == "save":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		_name_edit = LineEdit.new()
		_name_edit.custom_minimum_size = Vector2(250, 22)
		_name_edit.placeholder_text = "Nazwa zapisu"
		_name_edit.text = Game.default_save_name(save_data)
		_name_edit.max_length = 48
		_name_edit.add_theme_font_size_override("font_size", 10)
		_name_edit.text_submitted.connect(func(_text: String) -> void: _save_new())
		row.add_child(_name_edit)
		var save_button := UiStyle.menu_button("Nowy zapis", _save_new)
		save_button.custom_minimum_size = Vector2(90, 22)
		row.add_child(save_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	var back := UiStyle.menu_button("Wróć", close)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	_refresh()
	if _name_edit != null:
		_name_edit.grab_focus()
		_name_edit.select_all()
	else:
		back.grab_focus()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_armed = null
	for child in _list.get_children():
		child.queue_free()
	var saves := Game.list_saves()
	if saves.is_empty():
		var empty := UiStyle.label("Brak zapisów", 10, UiStyle.DIM_COLOR)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for meta in saves:
		_list.add_child(_make_row(meta))


func _make_row(meta: Dictionary) -> Control:
	var slot: String = meta["id"]
	var card := PanelContainer.new()
	var current := slot == Game.current_slot
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.TITLE_COLOR if current else UiStyle.SLOT_BORDER, 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = THUMB
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.texture = Game.save_thumbnail(slot)
	row.add_child(thumb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var name_label := UiStyle.label(str(meta.get("name", slot)), 10, UiStyle.TITLE_COLOR if current else UiStyle.TEXT_COLOR)
	name_label.clip_text = true
	name_label.custom_minimum_size.x = 150
	info.add_child(name_label)
	info.add_child(UiStyle.label(Game.describe_save(meta), 8, UiStyle.DIM_COLOR))
	var hero_name: String = HeroRig.NAMES.get(str(meta.get("hero", "")), "")
	if hero_name != "":
		info.add_child(UiStyle.label("Postać: " + hero_name, 8, UiStyle.DIM_COLOR))

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(buttons)
	var main := _small_button("Nadpisz" if mode == "save" else "Wczytaj")
	main.pressed.connect(_on_main.bind(main, slot))
	buttons.add_child(main)
	var delete := _small_button("Usuń")
	delete.pressed.connect(_on_delete.bind(delete, slot))
	buttons.add_child(delete)
	return card


func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(70, 18)
	button.add_theme_font_size_override("font_size", 9)
	return button


func _save_new() -> void:
	_write(_name_edit.text.strip_edges(), "")


func _on_main(button: Button, slot: String) -> void:
	if mode == "load":
		Game.load_game(slot)
		return
	if _confirm(button, "Na pewno?"):
		var meta_name := ""
		for meta in Game.list_saves():
			if meta["id"] == slot:
				meta_name = str(meta.get("name", ""))
		# nadpisanie zostawia nazwę zapisu (pole nazwy służy nowym zapisom)
		_write(meta_name, slot)


func _on_delete(button: Button, slot: String) -> void:
	if _confirm(button, "Usunąć?"):
		Game.delete_save(slot)
		_status.text = "Zapis usunięty"
		_refresh()


## Pierwsze kliknięcie uzbraja przycisk (zmienia napis), drugie potwierdza.
func _confirm(button: Button, question: String) -> bool:
	if _armed == button:
		return true
	if _armed != null and is_instance_valid(_armed):
		_armed.text = _armed.get_meta("label")
	button.set_meta("label", button.text)
	button.text = question
	_armed = button
	return false


func _write(save_name: String, slot: String) -> void:
	var id := Game.save_game(save_data.duplicate(true), save_name, slot, snapshot)
	if id == "":
		_status.text = "Nie udało się zapisać gry"
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		return
	_status.text = "Gra zapisana!"
	_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))
	Sfx.play("quest_ready")
	_refresh()
