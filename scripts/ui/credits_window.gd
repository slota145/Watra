class_name CreditsWindow
extends Control
## Okno „Twórcy” (przycisk w menu głównym): kto robi grę, skąd są grafiki, muzyka i dźwięki (autorzy nagrań CC0
## z assets/sfx/LICENSE_Kenney.txt i sfx_src/hits/ZRODLA.md) oraz informacja o silniku Godot wymagana przez jego
## licencję MIT - pełne licencje silnika i jego składników (Engine.get_license_text, get_copyright_info,
## get_license_info) pod przyciskiem „Licencje silnika”. Nazwiska i nazwy własne nie są tłumaczone.

signal closed

const AUTHOR := "Krzysztof Słota"
const YEAR := "2026"
## Sekcje: [nagłówek do tłumaczenia, [[nazwa (bez tłumaczenia), opis do tłumaczenia], ...]].
const SECTIONS := [
	["Pomysł, projekt i prowadzenie gry", [[AUTHOR, ""]]],
	["Programowanie, narzędzia i pomoc przy projekcie", [
		["Claude (Anthropic)", "asystent AI w Claude Code, pod kierunkiem autora"]]],
	["Grafika", [
		["PixelLab (pixellab.ai)", "postacie, potwory, krainy, przedmioty i efekty pixel-art tworzone z pomocą AI"],
		["", "część grafik, światła i efektów rysowana w kodzie gry"]]],
	["Muzyka i odgłosy otoczenia", [
		["", "utwory, wiatr i głosy ptaków tworzone w kodzie (generatory w folderze tools)"]]],
	["Dźwięki (licencja CC0 - domena publiczna)", [
		["Kenney (kenney.nl)", "RPG Audio, Impact Sounds, Interface Sounds, Music Jingles"],
		["qubodup", "Impact (opengameart.org)"],
		["Ben Jaszczak, Brian Nelson", "Medieval sound effects - Weapon impacts (opengameart.org)"],
		["lentikula", "Basic Spell Impacts (lentikula.itch.io)"],
		["", "pozostałe efekty syntezowane w kodzie gry"]]],
	["Silnik", [
		["Godot Engine (godotengine.org)", "licencja MIT"],
		["", "Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur."]]],
	["Inspiracje", [
		["Path of Exile", "Grinding Gear Games"],
		["Black Desert Online", "Pearl Abyss"]]],
	["Testerzy", [
		["", "dziękujemy wszystkim, którzy grają we wczesne wersje i zgłaszają uwagi!"]]],
]

var _content: VBoxContainer
var _scroll: ScrollContainer
var _licenses_button: Button


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
	box.add_child(UiStyle.title(Lang.t("Twórcy")))

	# treść przewijana - okno mieści się na każdym ekranie, a przyciski zawsze widać
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(392, maxf(get_viewport_rect().size.y - 90.0, 120.0))
	box.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 3)
	_scroll.add_child(_content)
	_show_credits()

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	_licenses_button = UiStyle.menu_button(Lang.t("Licencje silnika"), _toggle_licenses)
	buttons.add_child(_licenses_button)
	var back := UiStyle.menu_button(Lang.t("Zamknij"), close)
	buttons.add_child(back)
	back.grab_focus.call_deferred()


## Lista twórców: tytuł gry, sekcje (SECTIONS) i prawa autorskie.
func _show_credits() -> void:
	_clear()
	var name := UiStyle.label("Watra", 12, UiStyle.TITLE_COLOR)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_content.add_child(name)
	var motto := _text(Lang.t("Dopóki płonie ogień, Ostoja trwa."), UiStyle.DIM_COLOR)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(motto)
	for section: Array in SECTIONS:
		_content.add_child(UiStyle.label(Lang.t(section[0]), 8, UiStyle.TITLE_COLOR))
		for entry: Array in section[1]:
			var line: String = entry[0]
			var about: String = Lang.t(entry[1]) if entry[1] != "" and not str(entry[1]).begins_with("Copyright") else entry[1]
			if line != "" and about != "":
				line += " - " + about
			elif line == "":
				line = about
			var label := _text(line, UiStyle.TEXT_COLOR)
			label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			_content.add_child(label)
	var copyright := _text("© %s %s" % [YEAR, AUTHOR], UiStyle.DIM_COLOR)
	copyright.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copyright.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_content.add_child(copyright)


## Pełne licencje silnika: licencja Godota, jego składniki (pliki, prawa autorskie, licencja) i treści tych licencji.
func _show_licenses() -> void:
	_clear()
	var parts: Array[String] = [Lang.t("Ta gra używa silnika Godot Engine, dostępnego na licencji MIT:"), "", Engine.get_license_text(), "",
			Lang.t("Składniki silnika i ich licencje:")]
	for component: Dictionary in Engine.get_copyright_info():
		parts.append("")
		parts.append("- %s" % component["name"])
		for part: Dictionary in component["parts"]:
			for owner: String in part["copyright"]:
				parts.append("  (c) %s" % owner)
			parts.append("  %s" % part["license"])
	var licenses := Engine.get_license_info()
	for license: String in licenses:
		parts.append("")
		parts.append("----- %s -----" % license)
		parts.append(str(licenses[license]))
	# jeden duży napis zamiast setek etykiet - RichTextLabel bez znaczników przewija się lekko
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.fit_content = true
	text.scroll_active = false
	text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	text.custom_minimum_size.x = 370
	text.add_theme_font_size_override("normal_font_size", 6)
	text.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	text.text = "\n".join(parts)
	_content.add_child(text)


func _toggle_licenses() -> void:
	var showing := _licenses_button.text == Lang.t("Twórcy")
	if showing:
		_show_credits()
	else:
		_show_licenses()
	_licenses_button.text = Lang.t("Licencje silnika") if showing else Lang.t("Twórcy")
	_scroll.scroll_vertical = 0


func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


func _text(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 7, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 370
	return label


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
