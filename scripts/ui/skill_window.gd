class_name SkillWindow
extends PanelContainer
## Okno umiejętności (klawisz K) z zakładkami broni: broń biała, łuk i księga magii.
## Każda broń ma aktywną umiejętność pod PPM, uderzenie pod Shift+LPM, dodatkowy cios
## (LPM zaraz po uderzeniu - wymaga uderzenia) i dwie regeneracje. Odblokowanie i ulepszenia
## za złoto. Okno otwiera się na zakładce założonej broni.

const CARD_WIDTH := 150.0
const KEYS := {"active": "PPM", "strike": "Shift+LPM", "combo": "LPM po uderzeniu"}

var _player: Player
## id umiejętności -> {"level": Label, "effect": Label, "button": Button, "card": PanelContainer}
var _cards := {}
## rodzaj broni -> siatka kart / przycisk zakładki
var _pages := {}
var _tabs := {}
var _tab := "melee"
var _gold_label: Label
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Umiejętności"))
	var hint := UiStyle.label("Umiejętności działają tylko z założoną bronią swojego rodzaju. Szybkość ataku przyspiesza też umiejętności.", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	for weapon_type in Skills.WEAPON_TYPES:
		var tab := Button.new()
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_size_override("font_size", 8)
		tab.pressed.connect(_show_tab.bind(weapon_type))
		tabs.add_child(tab)
		_tabs[weapon_type] = tab

		var page := GridContainer.new()
		page.columns = 3
		page.add_theme_constant_override("h_separation", 4)
		page.add_theme_constant_override("v_separation", 4)
		box.add_child(page)
		_pages[weapon_type] = page
		for id in Skills.for_weapon(weapon_type):
			page.add_child(_make_card(id))

	var bottom := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_gold_label)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	bottom.add_child(_status)
	box.add_child(bottom)
	_show_tab("melee")


func setup(player: Player) -> void:
	_player = player
	player.skills.changed.connect(_refresh)
	player.equipment.changed.connect(_refresh)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_status.text = ""
		_show_tab(_player.stats.weapon_type())


func _show_tab(weapon_type: String) -> void:
	_tab = weapon_type
	for other: String in _pages:
		_pages[other].visible = other == weapon_type
		_tabs[other].set_pressed_no_signal(other == weapon_type)
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func _make_card(id: String) -> PanelContainer:
	var data := Skills.get_data(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size.x = CARD_WIDTH

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	content.add_child(header)
	var icon := TextureRect.new()
	icon.texture = data["icon"]
	UiStyle.fit_icon(icon)
	header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	header.add_child(names)
	var title: String = data["name"] + ("  [%s]" % KEYS[data["type"]] if KEYS.has(data["type"]) else "")
	names.add_child(UiStyle.label(title, 8, UiStyle.TEXT_COLOR))
	var level := UiStyle.label("", 7, UiStyle.DIM_COLOR)
	names.add_child(level)

	var effect := UiStyle.label("", 7, UiStyle.DIM_COLOR)
	effect.custom_minimum_size.x = CARD_WIDTH - 8.0
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(effect)

	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(_upgrade.bind(id))
	content.add_child(button)

	_cards[id] = {"level": level, "effect": effect, "button": button, "card": card}
	return card


func _upgrade(id: String) -> void:
	if not _player.skills.can_learn(id):
		_status.text = "Najpierw odblokuj: %s" % Skills.get_data(Skills.get_data(id)["requires"])["name"]
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	elif _player.skills.upgrade(id, _player.stats):
		var level := _player.skills.level_of(id)
		var verb := "Odblokowano" if level == 1 else "Ulepszono"
		_status.text = "%s: %s (poz. %d)" % [verb, Skills.get_data(id)["name"], level]
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))
	else:
		_status.text = "Za mało złota!"
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))


func _refresh() -> void:
	if _player == null:
		return
	var current_type := _player.stats.weapon_type()
	for weapon_type: String in _tabs:
		_tabs[weapon_type].text = Skills.WEAPON_NAMES[weapon_type] + (" (założona)" if weapon_type == current_type else "")

	var gold := _player.stats.gold
	for id: String in _cards:
		var parts: Dictionary = _cards[id]
		var data := Skills.get_data(id)
		var level := _player.skills.level_of(id)
		var cost := _player.skills.next_cost(id)
		var mana := Skills.mana_cost_text(id)
		parts["level"].text = ("Poz. %d/%d" % [level, Skills.MAX_LEVEL]) + ("  •  " + mana if mana != "" else "")

		var effect := "Teraz: " + Skills.effect_text(id, level) if level > 0 else "Nie odblokowano"
		if cost >= 0:
			effect += "\nNastępny: " + Skills.effect_text(id, level + 1)
		parts["effect"].text = effect

		var button: Button = parts["button"]
		var learnable := _player.skills.can_learn(id)
		if cost < 0:
			button.text = "Poziom maksymalny"
			button.disabled = true
		elif not learnable:
			button.text = "Wymaga: " + Skills.get_data(data["requires"])["name"]
			button.disabled = true
		else:
			button.text = "%s - %d zł" % ["Odblokuj" if level == 0 else "Ulepsz", cost]
			button.disabled = gold < cost
		parts["card"].tooltip_text = "%s\n%s" % [data["name"], data["description"]]
		parts["card"].modulate = Color.WHITE if level > 0 else Color(0.85, 0.85, 0.85)
	_gold_label.text = "%d złota" % gold
