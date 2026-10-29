class_name StorageWindow
extends PanelContainer
## Magazyn osady: po lewej plecak gracza, po prawej magazyn (40 miejsc).
## Kliknięcie przedmiotu przenosi cały stos na drugą stronę. Zamyka się,
## gdy gracz odejdzie od magazyniera. Magazynier może dobudować regały (rozbudowa za złoto).

## Rozbudowa: ile miejsc ma magazyn na start, ile dochodzi z jednym regałem i ile najwięcej.
const BASE_SLOTS := 40
const SLOTS_PER_UPGRADE := 8
const MAX_SLOTS := 160
const VISIBLE_ROWS := 5

const CLOSE_DISTANCE := 60.0
const SLOT_SIZE := Vector2(20, 20)

var _player: Player
var _npc: Npc
var _bag_grid: GridContainer
var _store_grid: GridContainer
var _store_label: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Magazyn osady"))
	var hint := UiStyle.label("Kliknij przedmiot, aby przenieść cały stos na drugą stronę.", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	box.add_child(columns)
	var bag := VBoxContainer.new()
	columns.add_child(bag)
	bag.add_child(UiStyle.label("Plecak", 8, UiStyle.TITLE_COLOR))
	_bag_grid = _grid(5)
	bag.add_child(_scrolled(_bag_grid, 5))
	columns.add_child(VSeparator.new())
	var store := VBoxContainer.new()
	columns.add_child(store)
	_store_label = UiStyle.label("Magazyn", 8, UiStyle.TITLE_COLOR)
	store.add_child(_store_label)
	_store_grid = _grid(8)
	store.add_child(_scrolled(_store_grid, 8))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 6)
	box.add_child(bottom)
	bottom.add_child(_button("Złóż drewno i kamień", _deposit_wood))
	bottom.add_child(_button("Zamknij", close))


func setup(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh)
	player.storage.changed.connect(_refresh)


func open(npc: Npc) -> void:
	_npc = npc
	visible = true
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func close() -> void:
	visible = false
	_npc = null


func toggle() -> void:
	close()


func _process(_delta: float) -> void:
	if visible and (_npc == null or _player.is_dead
			or _player.global_position.distance_to(_npc.global_position) > CLOSE_DISTANCE):
		close()


func _refresh() -> void:
	if not visible or _player == null:
		return
	_fill(_bag_grid, _player.inventory, _player.storage)
	_fill(_store_grid, _player.storage, _player.inventory)
	var used := _player.storage.slots.filter(func(s: Dictionary) -> bool: return not s.is_empty()).size()
	_store_label.text = "Magazyn (%d/%d)   •   drewno: %d   •   kamień: %d" % [used, _player.storage.slots.size(),
			_player.storage.count_of("wood"), _player.storage.count_of("stone")]


func _fill(grid: GridContainer, from: Inventory, to: Inventory) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for i in from.slots.size():
		var data: Dictionary = from.slots[i]
		var slot := Panel.new()
		UiStyle.rich_tooltip(slot)
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0))
		grid.add_child(slot)
		if data.is_empty():
			continue
		var enchant: int = data.get("enchant", 0)
		slot.tooltip_text = Items.tooltip(data["id"], enchant, "\nKliknij - przenieś")
		slot.gui_input.connect(_on_slot_input.bind(from, i, to))
		var icon := TextureRect.new()
		icon.texture = Items.get_data(data["id"])["icon"]
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		UiStyle.center_icon(icon)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		UiStyle.set_item_frame(slot, data["id"])
		var corner := UiStyle.label(str(data["count"]) if data["count"] > 1 else Enchanting.level_name(enchant), 7,
				UiStyle.TEXT_COLOR if data["count"] > 1 else Color(1.0, 0.82, 0.3))
		corner.set_anchors_preset(Control.PRESET_FULL_RECT)
		corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		corner.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		corner.offset_bottom = 2
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(corner)


func _on_slot_input(event: InputEvent, from: Inventory, index: int, to: Inventory) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if from.move_slot_to(index, to) > 0:
			Sfx.play("deposit")
		else:
			Sfx.play("ui_error")
			DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -10), "Brak miejsca!", Color(1, 0.4, 0.4), 8)


func _deposit_wood() -> void:
	Sfx.play("deposit")
	for i in _player.inventory.slots.size():
		if _player.inventory.slots[i].get("id") in ["wood", "stone"]:
			_player.inventory.move_slot_to(i, _player.storage)


## Ile kosztuje następny regał (`done` - ile już dobudowano). Rośnie łagodnie: 150 zł na start,
## około 4500 zł za ostatni.
static func upgrade_cost(done: int) -> int:
	return 150 + 100 * done + 15 * done * done


## Ile regałów już dobudowano i czy można jeszcze więcej.
static func upgrades_done(storage: Inventory) -> int:
	@warning_ignore("integer_division")
	return (storage.slots.size() - BASE_SLOTS) / SLOTS_PER_UPGRADE


static func can_upgrade(storage: Inventory) -> bool:
	return storage.slots.size() + SLOTS_PER_UPGRADE <= MAX_SLOTS


func _scrolled(grid: GridContainer, columns: int) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(columns * (SLOT_SIZE.x + 2) + 8, VISIBLE_ROWS * (SLOT_SIZE.y + 2) - 2)
	scroll.add_child(grid)
	return scroll


func _grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	return grid


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(on_pressed)
	return button
