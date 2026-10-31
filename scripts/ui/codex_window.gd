class_name CodexWindow
extends PanelContainer
## Encyklopedia (klawisz L): zakładki Legendy, Bossowie, Potwory, Zioła i mikstury, Przedmioty. Po lewej siatka ikon,
## po prawej szczegóły zaznaczonego wpisu. Nieodkryte wpisy (Codex) to ciemne sylwetki z "???"; licznik pokazuje,
## ile odkryto. W trybie deweloperskim widać wszystko, a kliknięcie przedmiotu daje jedną sztukę (legendy - z poziomem
## postaci).

const TABS := [
	["legends", "Legendy"], ["bosses", "Bossowie"], ["monsters", "Potwory"], ["herbs", "Zioła i mikstury"], ["items", "Przedmioty"],
]
const SLOT := 24.0
const GRID_SIZE := Vector2(232, 196)
const DETAILS_WIDTH := 190.0
## Kolumny siatki: przedmioty po 5 (jedna linia - tiery 1-5 w rzędzie), reszta po 8.
const COLUMNS := {"items": 5}
const UNKNOWN_COLOR := Color(0.0, 0.0, 0.0, 0.8)
const BOSS_COLOR := Color(1.0, 0.55, 0.25)

var _player: Player
var _tab := "legends"
var _selected := ""
var _tabs := {}
var _grid: GridContainer
var _counter: Label
var _icon: TextureRect
var _name: Label
var _body: RichTextLabel
var _slots := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Encyklopedia"))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	for entry: Array in TABS:
		var tab := Button.new()
		tab.text = entry[1]
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_size_override("font_size", 8)
		tab.pressed.connect(_show_tab.bind(entry[0]))
		tabs.add_child(tab)
		_tabs[entry[0]] = tab
	_counter = UiStyle.label("", 8, UiStyle.TITLE_COLOR)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_counter)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = GRID_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 3)
	scroll.add_child(_grid)

	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 4))
	details.custom_minimum_size = Vector2(DETAILS_WIDTH, GRID_SIZE.y)
	row.add_child(details)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	details.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	column.add_child(head)
	_icon = UiStyle.fit_icon(TextureRect.new(), 32)
	head.add_child(_icon)
	_name = UiStyle.label("", 9, UiStyle.TITLE_COLOR)
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.custom_minimum_size.x = DETAILS_WIDTH - 50.0
	head.add_child(_name)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 8)
	_body.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	column.add_child(_body)
	box.add_child(UiStyle.label("Kliknij wpis, by zobaczyć szczegóły. Nieznane wpisy odsłaniają się po zdobyciu przedmiotu albo pokonaniu potwora.", 7, UiStyle.DIM_COLOR))


func setup(player: Player) -> void:
	_player = player
	player.codex.changed.connect(func() -> void:
		if visible:
			_refresh())


func toggle() -> void:
	visible = not visible
	if visible:
		_show_tab(_tab)
		reset_size()
		var screen := get_viewport_rect().size
		position = ((screen - size) / 2.0).floor()
		position.y = maxf(2.0, position.y - 20.0)


func _dev_mode() -> bool:
	var hud := get_tree().get_first_node_in_group("hud")
	return hud != null and hud.dev_mode


func _show_tab(tab: String) -> void:
	_tab = tab
	_selected = ""
	for other: String in _tabs:
		_tabs[other].set_pressed_no_signal(other == tab)
	_refresh()


## Wpisy bieżącej zakładki (id przedmiotów albo potworów).
func entries(tab := _tab) -> Array[String]:
	match tab:
		"legends":
			return Codex.legends()
		"bosses":
			return Codex.bosses()
		"monsters":
			return Codex.monsters()
		"herbs":
			return Codex.herbs()
	return Codex.items()


func _is_monster_tab() -> bool:
	return _tab == "bosses" or _tab == "monsters"


func is_known(id: String) -> bool:
	if _dev_mode():
		return true
	return _player.codex.kills_of(id) > 0 if _is_monster_tab() else _player.codex.is_item_known(id)


func _icon_of(id: String) -> Texture2D:
	if _is_monster_tab():
		return Codex.monster_info(id).get("texture", null)
	return Items.get_data(id).get("icon", null)


func _name_of(id: String) -> String:
	return Codex.monster_name(id) if _is_monster_tab() else str(Items.get_data(id).get("name", id))


func _refresh() -> void:
	if _player == null:
		return
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_slots.clear()
	_grid.columns = COLUMNS.get(_tab, 8)
	var list := entries()
	var known := 0
	for id in list:
		var found := is_known(id)
		if found:
			known += 1
		var slot := _make_slot(id, found)
		_grid.add_child(slot)
		_slots[id] = slot
	_counter.text = "Odkryto: %d / %d" % [known, list.size()] + ("   (tryb deweloperski: kliknij przedmiot, by go dostać)" if _dev_mode() and not _is_monster_tab() else "")
	if _selected == "" and not list.is_empty():
		_selected = list[0]
	_show_details(_selected)


func _make_slot(id: String, found: bool) -> Button:
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(SLOT, SLOT)
	slot.focus_mode = Control.FOCUS_NONE
	slot.toggle_mode = true
	slot.set_pressed_no_signal(id == _selected)
	slot.tooltip_text = _name_of(id) if found else "???"
	var normal := UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 1)
	var chosen := UiStyle.panel(Color(0.3, 0.25, 0.15), UiStyle.TITLE_COLOR, 1)
	slot.add_theme_stylebox_override("normal", normal)
	slot.add_theme_stylebox_override("hover", UiStyle.panel(Color(0.25, 0.26, 0.36), UiStyle.TITLE_COLOR, 1))
	slot.add_theme_stylebox_override("pressed", chosen)
	slot.add_theme_stylebox_override("hover_pressed", chosen)
	var icon := UiStyle.center_icon(TextureRect.new(), SLOT - 4.0)
	icon.texture = _icon_of(id)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not found:
		icon.modulate = UNKNOWN_COLOR
	slot.add_child(icon)
	if found and not _is_monster_tab():
		UiStyle.set_item_frame(slot, id)
	elif found and _tab == "bosses":
		var frame := LegendaryFrame.new()
		frame.rarity = "legendary"
		slot.add_child(frame)
	slot.pressed.connect(_on_slot.bind(id))
	return slot


func _on_slot(id: String) -> void:
	_selected = id
	for other: String in _slots:
		_slots[other].set_pressed_no_signal(other == id)
	_show_details(id)
	Sfx.play("ui_click")
	if _dev_mode() and not _is_monster_tab():
		give(id)


## Tryb deweloperski: jedna sztuka przedmiotu do plecaka (legenda z poziomem postaci).
func give(id: String) -> String:
	var item := Loot.legendary_at_level(id, _player.stats.level) if _tab == "legends" else id
	_player._gain_item(item, 1)
	return item


func _show_details(id: String) -> void:
	if id == "":
		_icon.texture = null
		_name.text = ""
		_body.text = ""
		return
	var found := is_known(id)
	_icon.texture = _icon_of(id)
	_icon.modulate = Color.WHITE if found else UNKNOWN_COLOR
	if not found:
		_name.text = "???"
		_name.add_theme_color_override("font_color", UiStyle.DIM_COLOR)
		_body.text = "[color=#a6abbf]%s[/color]" % ("Pokonaj tego potwora, by poznać szczegóły." if _is_monster_tab()
				else "Zdobądź ten przedmiot, by poznać szczegóły.")
		if _tab == "legends":
			_body.text += "\n\nŹródło: " + Codex.legend_source(id)
		return
	_name.text = _name_of(id)
	if _is_monster_tab():
		_name.add_theme_color_override("font_color", BOSS_COLOR if _tab == "bosses" else UiStyle.TITLE_COLOR)
		_body.text = monster_text(id)
		return
	_name.add_theme_color_override("font_color", Items.rarity_color(id))
	# opis przedmiotu bez nazwy (jest w nagłówku)
	var lines := Items.describe(id).split("\n")
	var text := "\n".join(lines.slice(1))
	if _tab == "legends":
		text += "\n\n[color=#ffd773]Źródło:[/color] " + Codex.legend_source(id)
	elif _tab == "herbs":
		text += herb_text(id)
	_body.text = text


## Szczegóły potwora: kraina i poziomy, pokonani, bestiariusz, łup i opis.
func monster_text(id: String) -> String:
	var data: Dictionary = Codex.MONSTERS[id]
	var info := Codex.monster_info(id)
	var lines: Array[String] = []
	var zone: String = data["zone"]
	if zone != "":
		lines.append("[color=#ffd773]Kraina:[/color] %s (%s)" % [Zones.zone_name(zone), Codex.level_text(id)])
	else:
		lines.append("[color=#ffd773]Kraina:[/color] zwierzyna w wielu krainach")
	lines.append("[color=#ffd773]Pokonano:[/color] %d" % _player.codex.kills_of(id))
	var kind: String = info.get("kind", "")
	if Boons.BESTIARY.has(kind):
		var entry: Dictionary = Boons.BESTIARY[kind]
		var rank := _player.boons.rank(kind)
		lines.append("[color=#ffd773]Bestiariusz:[/color] %s, stopień %d/%d (+%d%% obrażeń)" % [entry["name"], rank,
				Boons.BESTIARY_COSTS.size(), roundi(rank * Boons.BESTIARY_STEP * 100.0)])
		lines.append("[color=#ffd773]Trofeum:[/color] %s" % Items.get_data(entry["trophy"]).get("name", entry["trophy"]))
	var legends: Array = info.get("legends", [])
	if not legends.is_empty():
		var names: Array[String] = []
		for legend: String in legends:
			var known := _dev_mode() or _player.codex.is_item_known(legend)
			names.append("[color=#ff9d33]%s[/color]" % Items.get_data(legend)["name"] if known else "???")
		lines.append("[color=#ffd773]Legendy:[/color] " + ", ".join(names))
	lines.append("")
	lines.append(data["note"])
	return "\n".join(lines)


## Zioło: gdzie rośnie; mikstura: z jakiego zioła.
func herb_text(id: String) -> String:
	for kind: String in Herbs.KINDS:
		var herb: Dictionary = Herbs.KINDS[kind]
		if herb["item"] == id:
			return "\n\n[color=#ffd773]Rośnie:[/color] %s" % Zones.zone_name(herb["zone"])
		if herb["elixir"] == id:
			return "\n\n[color=#ffd773]Warzy zielarka[/color] z %d ziół: %s" % [Herbs.HERBS_PER_ELIXIR, herb["name"]]
	return ""
