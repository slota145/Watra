class_name TesterWindow
extends Control
## Ekran dla testerów (tymczasowy, na czas testów u znajomych autora): pokazuje się po uruchomieniu gry w menu
## głównym (do odznaczenia „Pokazuj przy starcie” - Game.tester_info) i spod przycisku „Dla testerów”. Wita,
## mówi, co sprawdzać, jak włączyć tryb deweloperski i co robią jego klawisze, a przyciskiem „Zgłoś uwagę”
## otwiera FeedbackWindow. Wybór języka na górze (gra jest po polsku i po angielsku).

signal closed

const DEV_KEYS := [
	["Ctrl + Shift + C", "włącza i wyłącza tryb deweloperski (napis w rogu ekranu)"],
	["F1", "+1000 złota"],
	["F2", "awans o poziom"],
	["F3", "kamienie zaklinające, uświęcone i miłosierdzia"],
	["F4", "drewno i kamień na budowy"],
	["F5", "wydarzenie w świecie w tej krainie"],
	["F6", "kamienie wsparcia i krzesiwa na gniazda umiejętności"],
	["L", "encyklopedia - w trybie deweloperskim drugie kliknięcie przedmiotu daje go do plecaka"],
	["", "w trybie deweloperskim lochy mają wszystkie mechaniki, a bossowie dają lepszy łup"],
]
const CONTROLS := [
	["WASD", "ruch"], ["LPM / PPM / Q E R Z X", "umiejętności z paska"], ["1 - 0", "mikstury i przedmioty"],
	["Spacja", "zryw"], ["F", "rozmowa, handel, zbieranie"], ["B", "portal do miasta w lochu"],
	["I / C / K / J / L / M", "ekwipunek / postać / umiejętności / zadania / encyklopedia / mapa"],
	["?", "pomoc z pełną listą klawiszy"],
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	theme = UiStyle.make_theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size.x = 380
	panel.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiStyle.title(Lang.t("Witaj w Watrze!"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(title)
	for code: String in Lang.LANGUAGES:
		var button := Button.new()
		button.text = Lang.LANGUAGES[code]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = code == Game.language
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_set_language.bind(code))
		head.add_child(button)

	# treść przewijana - okno mieści się na każdym ekranie, a przyciski zawsze widać
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(392, maxf(get_viewport_rect().size.y - 90.0, 120.0))
	box.add_child(scroll)
	var footer := box
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)
	box.add_child(_text(Lang.t("Dziękujemy, że testujesz grę! To wczesna wersja, więc błędy się zdarzają. Najbardziej przydadzą się uwagi o tym, co jest niejasne, za trudne albo za łatwe, nudne albo zepsute. Każdą uwagę zgłosisz przyciskiem „Zgłoś uwagę” (jest też w menu gry pod Esc)."), UiStyle.TEXT_COLOR))
	box.add_child(UiStyle.label(Lang.t("Sterowanie"), 8, UiStyle.TITLE_COLOR))
	box.add_child(_grid(CONTROLS))
	box.add_child(UiStyle.label(Lang.t("Tryb deweloperski (do szybkiego sprawdzania późniejszych części gry)"), 8, UiStyle.TITLE_COLOR))
	box.add_child(_grid(DEV_KEYS))
	box.add_child(_text(Lang.t("Postęp zdobyty w trybie deweloperskim zostaje w zapisie - do uczciwego testu zacznij osobną grę."), UiStyle.DIM_COLOR))

	box = footer
	var show := CheckBox.new()
	show.text = Lang.t("Pokazuj przy starcie")
	show.button_pressed = Game.tester_info
	show.focus_mode = Control.FOCUS_NONE
	show.add_theme_font_size_override("font_size", 8)
	show.toggled.connect(Game.set_tester_info)
	box.add_child(show)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	buttons.add_child(UiStyle.menu_button(Lang.t("Zgłoś uwagę"), _feedback))
	var start := UiStyle.menu_button(Lang.t("Zaczynamy"), close)
	buttons.add_child(start)
	start.grab_focus.call_deferred()


func _text(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 7, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 370
	return label


func _grid(rows: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 0)
	for entry: Array in rows:
		grid.add_child(UiStyle.label(Lang.t(entry[0]) if entry[0] != "" else "", 7, UiStyle.TITLE_COLOR))
		var label := UiStyle.label(Lang.t(entry[1]), 7, UiStyle.TEXT_COLOR)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 250
		grid.add_child(label)
	return grid


func _set_language(code: String) -> void:
	Game.set_language(code)
	var fresh := TesterWindow.new()
	for connection: Dictionary in closed.get_connections():
		fresh.closed.connect(connection["callable"])
	get_parent().add_child(fresh)
	queue_free()


func _feedback() -> void:
	add_child(FeedbackWindow.new())


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
