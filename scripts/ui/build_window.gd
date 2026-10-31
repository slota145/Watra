class_name BuildWindow
extends PanelContainer
## Okno budowy u sołtysa: lista budowli osady z opisem, kosztem w surowcach (liczy się plecak
## i magazyn - posiadane / potrzebne) i stanem: przycisk "Zbuduj", pasek postępu budowy albo
## "Zbudowano". Budowa rusza od razu w wyznaczonym miejscu (Settlement.start_project).

const CARD_WIDTH := 250.0
## Wysokość przewijanej listy budowli.
const LIST_HEIGHT := 262.0
const OK_COLOR := Color(0.6, 1.0, 0.55)
const MISSING_COLOR := Color(1.0, 0.45, 0.45)

var _player: Player
var _status: Label
## budowla -> {"counts": {id: Label}, "button": Button, "bar": ProgressBar, "state": Label}
var _rows := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Budowa osady"))
	var hint := UiStyle.label("Surowce bierzemy z plecaka, a resztę z magazynu.", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	# karty budowli w przewijanej liście - z każdą nową budowlą okno nie rośnie poza ekran
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 4)
	for project: String in Settlement.PROJECTS:
		cards.add_child(_make_card(project))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(CARD_WIDTH + 20.0, LIST_HEIGHT)
	scroll.add_child(cards)
	box.add_child(scroll)
	var bottom := HBoxContainer.new()
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	var close_button := Button.new()
	close_button.text = "Zamknij"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.pressed.connect(func() -> void:
		visible = false
		Sfx.play("ui_close"))
	bottom.add_child(close_button)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()
	Sfx.play("ui_open")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _settlement() -> Settlement:
	return get_tree().get_first_node_in_group("settlement") as Settlement


func _make_card(project: String) -> PanelContainer:
	var data: Dictionary = Settlement.PROJECTS[project]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 4))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var name_label := UiStyle.label(Settlement.BUILDING_NAMES[project], 9, UiStyle.TITLE_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var state := UiStyle.label("", 7, UiStyle.DIM_COLOR)
	header.add_child(state)

	var description := UiStyle.label(data["description"], 7, UiStyle.DIM_COLOR)
	description.custom_minimum_size.x = CARD_WIDTH
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	content.add_child(line)
	line.add_child(UiStyle.label("Koszt:", 7, UiStyle.TEXT_COLOR))
	var counts := {}
	for id: String in data["cost"]:
		var icon := TextureRect.new()
		icon.texture = Items.get_data(id)["icon"]
		UiStyle.fit_icon(icon)
		icon.tooltip_text = Items.get_data(id)["name"]
		line.add_child(icon)
		var count := UiStyle.label("", 7)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		count.custom_minimum_size.x = 50
		line.add_child(count)
		counts[id] = count
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(spacer)
	var button := Button.new()
	button.text = "Zbuduj"
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(_build.bind(project))
	line.add_child(button)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(CARD_WIDTH, 6)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.add_theme_stylebox_override("background", UiStyle.panel(Color(0.08, 0.08, 0.12), UiStyle.SLOT_BORDER, 0))
	var fill := UiStyle.panel(Color(0.85, 0.65, 0.3), Color(0.85, 0.65, 0.3), 0)
	bar.add_theme_stylebox_override("fill", fill)
	content.add_child(bar)

	_rows[project] = {"counts": counts, "button": button, "bar": bar, "state": state, "cost_line": line}
	return card


func _refresh() -> void:
	var settlement := _settlement()
	if _player == null or settlement == null:
		return
	for project: String in _rows:
		var parts: Dictionary = _rows[project]
		var cost: Dictionary = Settlement.PROJECTS[project]["cost"]
		var state := settlement.project_state(project)
		for id: String in cost:
			var have := _player.count_owned(id)
			var label: Label = parts["counts"][id]
			if state != "none":  # już zapłacone - sam koszt
				label.text = str(cost[id])
				label.add_theme_color_override("font_color", UiStyle.DIM_COLOR)
				continue
			label.text = "%d/%d" % [mini(have, cost[id]), cost[id]]
			label.add_theme_color_override("font_color", OK_COLOR if have >= cost[id] else MISSING_COLOR)
		var button: Button = parts["button"]
		var bar: ProgressBar = parts["bar"]
		var state_label: Label = parts["state"]
		var locked := settlement.project_locked(project, _player)
		button.visible = state == "none"
		button.disabled = not settlement.can_afford(project, _player) or locked != ""
		bar.visible = state == "building"
		bar.value = settlement.project_progress(project)
		match state:
			"building":
				state_label.text = "W budowie: %d%%" % roundi(bar.value * 100.0)
				state_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			"built":
				state_label.text = "Zbudowano"
				state_label.add_theme_color_override("font_color", OK_COLOR)
			_:
				state_label.text = locked if locked != "" else "Do zbudowania"
				state_label.add_theme_color_override("font_color", MISSING_COLOR if locked != "" else UiStyle.DIM_COLOR)


func _build(project: String) -> void:
	if _settlement().start_project(project, _player):
		Sfx.play("coins")
		Sfx.play("hammer")
		_status.text = "Rusza budowa: %s!" % Settlement.BUILDING_NAMES[project]
		_status.add_theme_color_override("font_color", OK_COLOR)
	else:
		Sfx.play("ui_error")
		_status.text = "Za mało surowców"
		_status.add_theme_color_override("font_color", MISSING_COLOR)
	_refresh()
