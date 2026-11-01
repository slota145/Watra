class_name OfferWindow
extends PanelContainer
## Okno usług osady z listą ofert (posiłki w karczmie, błogosławieństwa w kaplicy, bestiariusz mędrca):
## karta = nazwa, opis, koszt (z kolorem: stać / nie stać) i przycisk. Zawartość podaje VillageServices
## (słownik {"title", "hint", "rows": [{"name", "text", "cost", "enabled", "button", "action", "state"}]}),
## odświeżana co chwilę - koszty, stan premii i liczniki zmieniają się na bieżąco.
## Zamyka się przyciskiem albo gdy gracz odejdzie od NPC.

const CARD_WIDTH := 240.0
const CLOSE_DISTANCE := 80.0
const OK_COLOR := Color(0.6, 1.0, 0.55)
const MISSING_COLOR := Color(1.0, 0.45, 0.45)

var _player: Player
var _npc: Node2D
var _kind := ""
var _title: Label
var _hint: Label
var _cards: VBoxContainer
var _status: Label
var _refresh_time := 0.0


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_title = UiStyle.title("")
	box.add_child(_title)
	_hint = UiStyle.label("", 7, UiStyle.DIM_COLOR)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.custom_minimum_size.x = CARD_WIDTH
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 4)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(CARD_WIDTH + 20.0, 0)
	scroll.add_child(_cards)
	box.add_child(scroll)
	var bottom := HBoxContainer.new()
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	var close_button := Button.new()
	close_button.text = Lang.t("Zamknij")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.pressed.connect(close)
	bottom.add_child(close_button)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player


func open(kind: String, npc: Node2D) -> void:
	_kind = kind
	_npc = npc
	visible = true
	_status.text = ""
	_rebuild()
	Sfx.play("ui_open")


func close() -> void:
	if visible:
		Sfx.play("ui_close")
	visible = false
	_npc = null


func toggle() -> void:
	close()


func _process(delta: float) -> void:
	if not visible:
		return
	if _npc == null or not is_instance_valid(_npc) or _player.global_position.distance_to(_npc.global_position) > CLOSE_DISTANCE:
		close()
		return
	_refresh_time -= delta
	if _refresh_time <= 0.0:
		_refresh_time = 0.5
		_rebuild()


func _rebuild() -> void:
	var content: Dictionary = VillageServices.offers(_kind, _player, _npc)
	_title.text = content.get("title", "")
	_hint.text = content.get("hint", "")
	_hint.visible = _hint.text != ""
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for row: Dictionary in content.get("rows", []):
		_cards.add_child(_card(row))
	var scroll := _cards.get_parent() as ScrollContainer
	scroll.custom_minimum_size.y = minf(_cards.get_combined_minimum_size().y, 250.0)
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func _card(row: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 4))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	if row.has("icon"):
		var icon := TextureRect.new()
		icon.texture = row["icon"]
		UiStyle.fit_icon(icon)
		header.add_child(icon)
	var name_label := UiStyle.label(row.get("name", ""), 9, UiStyle.TITLE_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	if row.get("state", "") != "":
		header.add_child(UiStyle.label(row["state"], 7, OK_COLOR))
	if row.get("text", "") != "":
		var text := UiStyle.label(row["text"], 7, UiStyle.DIM_COLOR)
		text.custom_minimum_size.x = CARD_WIDTH
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(text)
	var line := HBoxContainer.new()
	content.add_child(line)
	var cost := UiStyle.label(row.get("cost", ""), 7, OK_COLOR if row.get("enabled", false) else MISSING_COLOR)
	cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(cost)
	if row.has("action"):
		var button := Button.new()
		button.text = row.get("button", Lang.t("Wybierz"))
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 8)
		button.disabled = not row.get("enabled", false)
		button.pressed.connect(_choose.bind(row["action"]))
		line.add_child(button)
	return card


func _choose(action: Callable) -> void:
	var message: String = action.call()
	_status.text = message
	_status.add_theme_color_override("font_color", OK_COLOR)
	_rebuild()
