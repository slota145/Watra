class_name SkillWindow
extends PanelContainer
## Okno umiejętności (klawisz K) z zakładkami broni: broń biała, łuk i księga magii.
## Każda broń ma zwykły atak, aktywną umiejętność, uderzenie, dodatkowy cios (atak zaraz po uderzeniu -
## wymaga uderzenia) i dwie regeneracje. Odblokowanie i ulepszenia za złoto. Atak, umiejętność aktywną
## i uderzenie przeciąga się na pasek umiejętności na dole ekranu (Hotbar); przy nazwie widać, pod jakim są klawiszem.
## Broń z drzewkiem (SkillTree, na razie miecz) zamiast kart pokazuje sieć węzłów (SkillTreeView): punkty umiejętności,
## szczegóły zaznaczonego węzła z przyciskami "Wybierz" (1 punkt) i "Ulepsz" (złoto, umiejętności z wybranym węzłem).
## Okno otwiera się na zakładce założonej broni.

const CARD_WIDTH := 150.0
## Miejsce na paski szybkiego wyboru na dole ekranu, którego okno nie zasłania.
const BOTTOM_RESERVE := 52.0
## Wielkość widoku drzewka i szerokość kolumny szczegółów obok.
const TREE_SIZE := Vector2(400, 204)
const DETAILS_WIDTH := 150.0

var _player: Player
## id umiejętności -> {"title": Label, "level": Label, "effect": Label, "button": Button, "card": PanelContainer}
var _cards := {}
## rodzaj broni -> nazwa na karcie zwykłego ataku (z klawiszem z paska)
var _attack_titles := {}
## rodzaj broni -> siatka kart / przycisk zakładki
var _pages := {}
var _tabs := {}
var _tab := "melee"
var _gold_label: Label
var _status: Label
## rodzaj broni -> {"view": SkillTreeView, "points": Label, "info": Label, "take": Button, "upgrade": Button}
var _trees := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Umiejętności"))
	var hint := UiStyle.label("Działają tylko z bronią swojego rodzaju. Przeciągnij umiejętność (start drzewka - zwykły atak) na pasek. Combo: umiejętność zaraz po innej działa mocniej.", 7, UiStyle.DIM_COLOR)
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

		if SkillTree.has_tree(weapon_type):
			var tree_page := _make_tree_page(weapon_type)
			box.add_child(tree_page)
			_pages[weapon_type] = tree_page
			continue
		var page := GridContainer.new()
		page.columns = 3
		page.add_theme_constant_override("h_separation", 4)
		page.add_theme_constant_override("v_separation", 4)
		box.add_child(page)
		_pages[weapon_type] = page
		page.add_child(_make_attack_card(weapon_type))
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
	for weapon_type: String in _trees:
		_trees[weapon_type]["view"].setup(player, weapon_type)
	player.hotbar.changed.connect(_refresh)
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
	_place()


## Na środku ekranu, ale nad paskami szybkiego wyboru - żeby dało się na nie przeciągać umiejętności.
func _place() -> void:
	reset_size()
	var screen := get_viewport_rect().size
	position = ((screen - size) / 2.0).floor()
	position.y = maxf(2.0, minf(position.y, screen.y - size.y - BOTTOM_RESERVE))


## Strona drzewka: punkty, a pod nimi sieć węzłów i obok kolumna ze szczegółami zaznaczonego węzła i przyciskami.
func _make_tree_page(weapon_type: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 3)
	var points := UiStyle.label("", 8, UiStyle.TITLE_COLOR)
	points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(points)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	page.add_child(row)
	var view := SkillTreeView.new()
	view.custom_minimum_size = TREE_SIZE
	view.theme = UiStyle.make_theme()
	row.add_child(view)
	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	details.custom_minimum_size = Vector2(DETAILS_WIDTH, TREE_SIZE.y)
	row.add_child(details)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	details.add_child(column)
	var info := UiStyle.label("Kliknij węzeł, żeby zobaczyć szczegóły. Przeciągaj puste miejsce, żeby przesunąć drzewko; kółko myszy przybliża.", 7, UiStyle.TEXT_COLOR)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = DETAILS_WIDTH - 8.0
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(info)
	var take := Button.new()
	take.focus_mode = Control.FOCUS_NONE
	take.add_theme_font_size_override("font_size", 8)
	take.pressed.connect(_take_node.bind(weapon_type))
	column.add_child(take)
	var upgrade := Button.new()
	upgrade.focus_mode = Control.FOCUS_NONE
	upgrade.add_theme_font_size_override("font_size", 8)
	upgrade.pressed.connect(_upgrade_node.bind(weapon_type))
	column.add_child(upgrade)
	view.selected.connect(func(_id: String) -> void: _refresh())
	_trees[weapon_type] = {"view": view, "points": points, "info": info, "take": take, "upgrade": upgrade}
	return page


func _take_node(weapon_type: String) -> void:
	var view: SkillTreeView = _trees[weapon_type]["view"]
	if _player.skills.take(weapon_type, view.selected_id):
		Sfx.play("ui_confirm")
		_status.text = "Wybrano: %s" % SkillTree.node_name(weapon_type, view.selected_id)
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))


func _upgrade_node(weapon_type: String) -> void:
	var view: SkillTreeView = _trees[weapon_type]["view"]
	var node: Dictionary = SkillTree.nodes(weapon_type).get(view.selected_id, {})
	if node.get("kind", "") == "skill":
		_upgrade(node["skill"])


func _refresh_tree(weapon_type: String) -> void:
	var parts: Dictionary = _trees[weapon_type]
	var view: SkillTreeView = parts["view"]
	var book := _player.skills
	parts["points"].text = "Punkty umiejętności: %d   (1 za poziom postaci; zapomnieć drzewko można u mędrca)" % book.points_left()
	view.queue_redraw()
	var take: Button = parts["take"]
	var upgrade: Button = parts["upgrade"]
	var id := view.selected_id
	if id == "":
		take.visible = false
		upgrade.visible = false
		return
	var text := view.describe(id)
	var node: Dictionary = SkillTree.nodes(weapon_type)[id]
	take.visible = not book.has_node_id(weapon_type, id)
	take.text = "Wybierz (1 pkt)"
	take.disabled = not book.can_take(weapon_type, id)
	upgrade.visible = node["kind"] == "skill" and book.has_node_id(weapon_type, id)
	if upgrade.visible:
		var skill: String = node["skill"]
		var level := book.level_of(skill)
		var cost := book.next_cost(skill)
		text += "\nPoz. %d/%d: %s" % [level, Skills.MAX_LEVEL, Skills.effect_text(skill, level)]
		if cost >= 0:
			upgrade.tooltip_text = "Następny poziom: " + Skills.effect_text(skill, level + 1)
		upgrade.text = "Poziom maksymalny" if cost < 0 else "Ulepsz - %d zł" % cost
		upgrade.disabled = cost < 0 or _player.stats.gold < cost
		var key := _key_of(skill, weapon_type) if Hotbar.can_slot_skill(skill) else ""
		if key != "":
			text += "\nNa pasku:" + key
	parts["info"].text = text


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
	var title := UiStyle.label(data["name"], 8, UiStyle.TEXT_COLOR)
	names.add_child(title)
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

	_cards[id] = {"title": title, "level": level, "effect": effect, "button": button, "card": card}
	if Hotbar.can_slot_skill(id):
		card.set_drag_forwarding(_drag_skill.bind(id, card), Callable(), Callable())
	return card


## Karta zwykłego ataku bronią - zawsze dostępny, da się go przełożyć na dowolny slot paska.
func _make_attack_card(weapon_type: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size.x = CARD_WIDTH
	card.tooltip_text = "%s\nZwykły atak założoną bronią w stronę kursora. Przeciągnij na pasek umiejętności." % Hotbar.ATTACK_NAME
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	content.add_child(header)
	var icon := TextureRect.new()
	icon.texture = Hotbar.ATTACK_ICON
	UiStyle.fit_icon(icon)
	header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	header.add_child(names)
	var title := UiStyle.label(Hotbar.ATTACK_NAME, 8, UiStyle.TEXT_COLOR)
	names.add_child(title)
	names.add_child(UiStyle.label("Zawsze dostępny", 7, UiStyle.DIM_COLOR))
	var effect := UiStyle.label("Zwykły atak bronią. Zaraz po uderzeniu wyprowadza dodatkowy cios (combo).", 7, UiStyle.DIM_COLOR)
	effect.custom_minimum_size.x = CARD_WIDTH - 8.0
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(effect)
	_attack_titles[weapon_type] = title
	card.set_drag_forwarding(_drag_skill.bind(Hotbar.ATTACK, card), Callable(), Callable())
	return card


## Przeciąganie karty na pasek umiejętności (dane jak w ActionBars: {"skill": id}).
func _drag_skill(_at: Vector2, id: String, card: Control) -> Variant:
	card.set_drag_preview(UiStyle.drag_preview(Hotbar.skill_icon(id)))
	Sfx.play("ui_click")
	return {"skill": id}


## " [Q]" - pod jakim klawiszem paska leży umiejętność dla danej broni ("" - nie ma jej na pasku).
func _key_of(id: String, weapon_type: String) -> String:
	var index := _player.hotbar.skill_bar(weapon_type).find(id)
	return "  [%s]" % Hotbar.SKILL_KEYS[index] if index >= 0 else ""


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

	for weapon_type: String in _attack_titles:
		_attack_titles[weapon_type].text = Hotbar.ATTACK_NAME + _key_of(Hotbar.ATTACK, weapon_type)
	for weapon_type: String in _trees:
		_refresh_tree(weapon_type)
	var gold := _player.stats.gold
	for id: String in _cards:
		var parts: Dictionary = _cards[id]
		var data := Skills.get_data(id)
		var suffix := "  [po uderzeniu]" if data["type"] == "combo" else _key_of(id, data["weapon"])
		parts["title"].text = data["name"] + suffix
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
