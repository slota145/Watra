class_name FeedbackWindow
extends Control
## Zgłoszenie uwagi (menu główne, menu gry, ekran dla testerów): rodzaj, tytuł i opis. „Wyślij na GitHub” otwiera
## w przeglądarce gotowe zgłoszenie (issue) w repozytorium gry z dopisanymi danymi gry (wersja, kraina, poziom,
## system) - wystarczy kliknąć „Submit” (potrzebne konto GitHub). Bez konta: „Kopiuj” wkłada całość do schowka,
## żeby wysłać ją autorowi w wiadomości. Gra nie trzyma żadnego klucza do GitHuba.

signal closed

const ISSUES_URL := "https://github.com/slota145/Watra/issues/new"
## Rodzaje zgłoszeń: [nazwa w oknie, etykieta na GitHubie].
const KINDS := [["Błąd", "bug"], ["Pomysł", "enhancement"], ["Balans", "balans"], ["Inne", ""]]
## Najdłuższy opis w adresie (przeglądarki i GitHub nie przyjmują bardzo długich adresów).
const MAX_BODY := 4000

var _kind: OptionButton
var _title: LineEdit
var _body: TextEdit
var _info: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	theme = UiStyle.make_theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
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
	box.custom_minimum_size = Vector2(300, 0)
	panel.add_child(box)
	box.add_child(UiStyle.title(Lang.t("Zgłoś uwagę")))
	var hint := UiStyle.label(Lang.t("Opisz, co się stało albo co warto zmienić. Przycisk „Wyślij na GitHub” otworzy przeglądarkę z gotowym zgłoszeniem - wystarczy je zatwierdzić (potrzebne konto GitHub). Bez konta skopiuj zgłoszenie i wyślij je autorowi."), 7, UiStyle.DIM_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 300
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	_kind = OptionButton.new()
	_kind.focus_mode = Control.FOCUS_NONE
	_kind.add_theme_font_size_override("font_size", 8)
	for kind: Array in KINDS:
		_kind.add_item(Lang.t(kind[0]))
	row.add_child(_kind)
	_title = LineEdit.new()
	_title.placeholder_text = Lang.t("Krótki tytuł")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 8)
	row.add_child(_title)
	_body = TextEdit.new()
	_body.placeholder_text = Lang.t("Co się stało? Gdzie? Co działo się tuż przed tym? (po polsku albo po angielsku)")
	_body.custom_minimum_size = Vector2(300, 120)
	_body.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_body.add_theme_font_size_override("font_size", 8)
	box.add_child(_body)
	_info = UiStyle.label("", 7, UiStyle.TITLE_COLOR)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size.x = 300
	box.add_child(_info)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	buttons.add_child(UiStyle.menu_button(Lang.t("Wyślij na GitHub"), _send))
	buttons.add_child(UiStyle.menu_button(Lang.t("Kopiuj"), _copy))
	buttons.add_child(UiStyle.menu_button(Lang.t("Zamknij"), close))
	_title.grab_focus.call_deferred()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Treść zgłoszenia: opis gracza i dane gry, które pomagają odtworzyć błąd.
func report_body() -> String:
	var lines := [_body.text.strip_edges(), "", "---", Lang.t("Dane gry (dopisane same):")]
	lines.append("- " + Lang.t("Wersja: %s") % str(ProjectSettings.get_setting("application/config/version", "?")))
	lines.append("- " + Lang.t("System: %s") % OS.get_name())
	lines.append("- " + Lang.t("Język: %s") % Game.language)
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		var zone: String = world.zone
		if zone == Zones.DUNGEON and world._dungeon != null:
			zone += " (%s, %s %d)" % [world._dungeon_config.get("climate", "?"), Lang.t("stopień"), int(world._dungeon_config.get("tier", 0))]
		lines.append("- " + Lang.t("Kraina: %s") % zone)
		lines.append("- " + Lang.t("Poziom postaci: %d") % world.player.stats.level)
	lines.append("- " + Lang.t("Tryb deweloperski: %s") % (Lang.t("tak") if Game.dev_mode else Lang.t("nie")))
	return "\n".join(lines)


func _report_title() -> String:
	var title := _title.text.strip_edges()
	return title if title != "" else Lang.t("Uwaga z gry")


func _send() -> void:
	if _body.text.strip_edges() == "" and _title.text.strip_edges() == "":
		_info.text = Lang.t("Najpierw wpisz tytuł albo opis.")
		return
	var body := report_body().left(MAX_BODY)
	var url := "%s?title=%s&body=%s" % [ISSUES_URL, _report_title().uri_encode(), body.uri_encode()]
	var label: String = KINDS[_kind.selected][1]
	if label != "":
		url += "&labels=" + label.uri_encode()
	OS.shell_open(url)
	_info.text = Lang.t("Otwarto przeglądarkę - zatwierdź zgłoszenie przyciskiem „Submit new issue”. Dziękujemy!")


func _copy() -> void:
	DisplayServer.clipboard_set("%s: %s\n\n%s" % [Lang.t(KINDS[_kind.selected][0]), _report_title(), report_body()])
	_info.text = Lang.t("Skopiowano do schowka - wklej i wyślij autorowi. Dziękujemy!")
