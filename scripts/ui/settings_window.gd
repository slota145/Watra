class_name SettingsWindow
extends Control
## Okno ustawień (z menu głównego i z pauzy): głośność ogólna, muzyki, efektów i otoczenia, pełny ekran,
## synchronizacja pionowa, siła trzęsienia ekranu i łup niezidentyfikowany (Unidentified). Zmiany działają od razu i zapisują się w
## user://settings.cfg (Sfx - dźwięk, Game - obraz i trzęsienie). Zamyka się przyciskiem albo Esc.

signal closed

var _fullscreen: CheckBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.make_menu_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.BG, UiStyle.BORDER, 10))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	var title := UiStyle.title("Ustawienia")
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	box.add_child(_header("Dźwięk"))
	box.add_child(_slider_row("Ogólna", Sfx.master_volume, Sfx.set_master_volume))
	box.add_child(_slider_row("Muzyka", Sfx.music_volume, Sfx.set_music_volume))
	box.add_child(_slider_row("Efekty", Sfx.sfx_volume, func(v: float) -> void:
		Sfx.set_sfx_volume(v)
		Sfx.play("ui_click")))
	box.add_child(_slider_row("Otoczenie", Sfx.ambient_volume, Sfx.set_ambient_volume))
	box.add_child(_header("Obraz"))
	_fullscreen = _check_row("Pełny ekran", Game.fullscreen, Game.set_fullscreen)
	box.add_child(_fullscreen)
	box.add_child(_check_row("Synchronizacja pionowa (V-Sync)", Game.vsync, Game.set_vsync))
	box.add_child(_slider_row("Trzęsienie ekranu", Game.screen_shake, Game.set_screen_shake))
	box.add_child(_header("Rozgrywka"))
	var unidentified := _check_row("Łup niezidentyfikowany (stosy, PPM identyfikuje)", Game.unidentified_loot, Game.set_unidentified_loot)
	unidentified.tooltip_text = "Magiczna i rzadka broń, zbroja i biżuteria wypada zawinięta w płótno: układa się w stosy\n(rodzaj, rzadkość i poziom), a PPM w plecaku ją identyfikuje (Shift+PPM - cały stos)."
	box.add_child(unidentified)
	box.add_child(HSeparator.new())
	var back := UiStyle.menu_button("Wróć", close)
	box.add_child(back)
	back.grab_focus()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	# F11 / Alt+Enter mogły przełączyć pełny ekran poza oknem - pole zgadza się ze stanem gry
	if _fullscreen.button_pressed != Game.fullscreen:
		_fullscreen.set_pressed_no_signal(Game.fullscreen)


func _header(text: String) -> Label:
	var label := UiStyle.label(text, 9, UiStyle.TITLE_COLOR)
	return label


func _slider_row(text: String, value: float, on_changed: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := UiStyle.label(text, 8, UiStyle.TEXT_COLOR)
	label.custom_minimum_size.x = 84
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(110, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(on_changed)
	row.add_child(slider)
	var percent := UiStyle.label("%d%%" % roundi(value * 100.0), 8, UiStyle.DIM_COLOR)
	percent.custom_minimum_size.x = 28
	slider.value_changed.connect(func(v: float) -> void: percent.text = "%d%%" % roundi(v * 100.0))
	row.add_child(percent)
	return row


func _check_row(text: String, value: bool, on_toggled: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", 8)
	check.toggled.connect(on_toggled)
	return check
