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

	var title := UiStyle.title(Lang.t("Ustawienia"))
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	box.add_child(_header(Lang.t("Dźwięk")))
	box.add_child(_slider_row(Lang.t("Ogólna"), Sfx.master_volume, Sfx.set_master_volume))
	box.add_child(_slider_row(Lang.t("Muzyka"), Sfx.music_volume, Sfx.set_music_volume))
	box.add_child(_slider_row(Lang.t("Efekty"), Sfx.sfx_volume, func(v: float) -> void:
		Sfx.set_sfx_volume(v)
		Sfx.play("ui_click")))
	box.add_child(_slider_row(Lang.t("Otoczenie"), Sfx.ambient_volume, Sfx.set_ambient_volume))
	box.add_child(_header(Lang.t("Obraz")))
	_fullscreen = _check_row(Lang.t("Pełny ekran"), Game.fullscreen, Game.set_fullscreen)
	box.add_child(_fullscreen)
	box.add_child(_check_row(Lang.t("Synchronizacja pionowa (V-Sync)"), Game.vsync, Game.set_vsync))
	box.add_child(_slider_row(Lang.t("Trzęsienie ekranu"), Game.screen_shake, Game.set_screen_shake))
	box.add_child(_ui_scale_row())
	var reset_windows := Button.new()
	reset_windows.text = Lang.t("Przywróć położenie okien")
	reset_windows.tooltip_text = Lang.t("Okna przesuwa się, chwytając za tło, a Ctrl + kółko myszy zmienia ich wielkość.")
	reset_windows.focus_mode = Control.FOCUS_NONE
	reset_windows.pressed.connect(func() -> void:
		Game.reset_window_layouts()
		Sfx.play("ui_click"))
	box.add_child(reset_windows)
	box.add_child(_header(Lang.t("Rozgrywka")))
	box.add_child(_language_row())
	var unidentified := _check_row(Lang.t("Łup niezidentyfikowany (stosy, PPM identyfikuje)"), Game.unidentified_loot, Game.set_unidentified_loot)
	unidentified.tooltip_text = Lang.t("Magiczna i rzadka broń, zbroja i biżuteria wypada zawinięta w płótno: układa się w stosy\n(rodzaj, rzadkość i poziom), a PPM w plecaku ją identyfikuje (Shift+PPM - cały stos).")
	box.add_child(unidentified)
	box.add_child(HSeparator.new())
	var back := UiStyle.menu_button(Lang.t("Wróć"), close)
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


## Wybór języka (Lang.LANGUAGES); okno ustawień otwiera się od nowa w nowym języku.
## Skalowanie interfejsu (75-150%): wartość zmienia się po puszczeniu suwaka, żeby okno nie skakało pod kursorem.
func _ui_scale_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := UiStyle.label(Lang.t("Skalowanie interfejsu"), 8, UiStyle.TEXT_COLOR)
	label.custom_minimum_size.x = 84
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = Game.UI_SCALE_RANGE.x
	slider.max_value = Game.UI_SCALE_RANGE.y
	slider.step = 0.05
	slider.value = Game.ui_scale
	slider.custom_minimum_size = Vector2(110, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value := UiStyle.label("%d%%" % roundi(Game.ui_scale * 100.0), 8, UiStyle.DIM_COLOR)
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void: value.text = "%d%%" % roundi(v * 100.0))
	slider.drag_ended.connect(func(_changed: bool) -> void: Game.set_ui_scale(slider.value))
	return row


func _language_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := UiStyle.label(Lang.t("Język"), 8, UiStyle.TEXT_COLOR)
	label.custom_minimum_size.x = 84
	row.add_child(label)
	var pick := OptionButton.new()
	pick.focus_mode = Control.FOCUS_NONE
	# nazwy języków zawsze w ich własnym języku
	pick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	pick.tooltip_text = tr("Część napisów w trwającej grze zmieni się dopiero po jej wczytaniu.")
	pick.add_theme_font_size_override("font_size", 8)
	var codes: Array = Lang.LANGUAGES.keys()
	for code: String in codes:
		pick.add_item(Lang.LANGUAGES[code])
	pick.selected = maxi(codes.find(Game.language), 0)
	pick.item_selected.connect(func(index: int) -> void:
		Game.set_language(codes[index])
		_reopen())
	row.add_child(pick)
	return row


func _reopen() -> void:
	var fresh := SettingsWindow.new()
	# nowe okno przejmuje odbiorców sygnału closed (np. menu główne, które po zmianie języka buduje się od nowa)
	for connection: Dictionary in closed.get_connections():
		fresh.closed.connect(connection["callable"])
	get_parent().add_child(fresh)
	queue_free()


func _check_row(text: String, value: bool, on_toggled: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", 8)
	check.toggled.connect(on_toggled)
	return check
