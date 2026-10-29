class_name PauseMenu
extends Control
## Menu pauzy (Esc w trakcie gry): wznowienie, zapis i wczytanie (lista zapisów z miniaturkami),
## ustawienia (dźwięk, obraz), powrót do menu i wyjście.
## Zatrzymuje grę, dopóki jest otwarte.

var _load_button: Button
var _resume_button: Button
var _status: Label
## Zrzut ekranu gry sprzed otwarcia menu - miniaturka zapisu.
var _snapshot: Image
var _browser: SaveBrowser


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.make_menu_theme()

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.BG, UiStyle.BORDER, 10))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	var title := UiStyle.title("Pauza")
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	_resume_button = UiStyle.menu_button("Wznów grę", close)
	box.add_child(_resume_button)
	box.add_child(UiStyle.menu_button("Zapisz grę", _on_save))
	_load_button = UiStyle.menu_button("Wczytaj grę", _on_load)
	box.add_child(_load_button)
	box.add_child(UiStyle.menu_button("Ustawienia", _on_settings))
	box.add_child(UiStyle.menu_button("Menu główne", Game.go_to_menu))
	box.add_child(UiStyle.menu_button("Wyjdź z gry", Game.quit_game))

	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)


func open() -> void:
	# ostatnia narysowana klatka to jeszcze sama gra, bez menu
	_snapshot = get_viewport().get_texture().get_image()
	visible = true
	get_tree().paused = true
	_status.text = ""
	_refresh_load_button()
	_resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and _browser == null and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_save() -> void:
	var world := get_tree().current_scene
	if world == null or not world.has_method("get_save_data"):
		return
	_open_browser("save", world.get_save_data())


func _open_browser(mode: String, data := {}) -> void:
	_browser = SaveBrowser.new()
	_browser.mode = mode
	_browser.save_data = data
	_browser.snapshot = _snapshot
	_browser.closed.connect(_on_browser_closed)
	add_child(_browser)


func _on_browser_closed() -> void:
	_browser = null
	_refresh_load_button()
	_resume_button.grab_focus()


func _on_settings() -> void:
	var settings := SettingsWindow.new()
	settings.closed.connect(func() -> void: _resume_button.grab_focus())
	add_child(settings)


func _on_load() -> void:
	_open_browser("load")


func _refresh_load_button() -> void:
	_load_button.disabled = not Game.has_save()
