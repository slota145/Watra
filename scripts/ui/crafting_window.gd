class_name CraftingWindow
extends PanelContainer
## Okno rzemiosła (przycisk pod "Zaklinaniem" w ekwipunku): lista receptur, przy każdej
## składniki z liczbą posiadanych / potrzebnych i przycisk "Wytwórz". Składniki z plecaka.

const SLOT_SIZE := Vector2(22, 22)
const OK_COLOR := Color(0.6, 1.0, 0.55)
const MISSING_COLOR := Color(1.0, 0.45, 0.45)

var _player: Player
var _list: VBoxContainer
var _status: Label
## indeks receptury -> {"button": Button, "counts": {id: Label}}
var _rows := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Rzemiosło"))
	var hint := UiStyle.label("Składniki bierzesz z plecaka.", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	box.add_child(_list)
	for i in Crafting.RECIPES.size():
		_list.add_child(_make_row(i))
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)


func setup(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh)
	_refresh()


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()


func _make_row(index: int) -> PanelContainer:
	var recipe: Dictionary = Crafting.RECIPES[index]
	var result: String = recipe["result"]
	var row := PanelContainer.new()
	UiStyle.rich_tooltip(row)
	row.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	row.tooltip_text = Items.describe(result)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 5)
	row.add_child(line)

	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.2, 0.15, 0.26), Color(0.62, 0.4, 0.9), 0))
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon := TextureRect.new()
	icon.texture = Items.get_data(result)["icon"]
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyle.center_icon(icon)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	line.add_child(slot)

	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 1)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_PASS
	line.add_child(middle)
	var name_label := UiStyle.label(Items.get_data(result)["name"], 8, Color(0.85, 0.65, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	middle.add_child(name_label)
	var parts := HBoxContainer.new()
	parts.add_theme_constant_override("separation", 2)
	parts.mouse_filter = Control.MOUSE_FILTER_PASS
	middle.add_child(parts)
	var counts := {}
	for id: String in recipe["ingredients"]:
		var part_icon := TextureRect.new()
		part_icon.texture = Items.get_data(id)["icon"]
		UiStyle.fit_icon(part_icon)
		part_icon.tooltip_text = Items.get_data(id)["name"]
		parts.add_child(part_icon)
		var count := UiStyle.label("", 7)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		count.custom_minimum_size.x = 40
		parts.add_child(count)
		counts[id] = count

	var button := Button.new()
	button.text = "Wytwórz"
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(_craft.bind(index))
	line.add_child(button)
	_rows[index] = {"button": button, "counts": counts}
	return row


func _refresh() -> void:
	if _player == null:
		return
	for index: int in _rows:
		var recipe: Dictionary = Crafting.RECIPES[index]
		var parts: Dictionary = _rows[index]
		for id: String in recipe["ingredients"]:
			var have := _player.inventory.count_of(id)
			var need := int(recipe["ingredients"][id])
			var label: Label = parts["counts"][id]
			label.text = "%d/%d" % [have, need]
			label.add_theme_color_override("font_color", OK_COLOR if have >= need else MISSING_COLOR)
		parts["button"].disabled = not Crafting.can_craft(recipe, _player.inventory)


func _craft(index: int) -> void:
	var recipe: Dictionary = Crafting.RECIPES[index]
	var name: String = Items.get_data(recipe["result"])["name"]
	if Crafting.craft(recipe, _player.inventory):
		Sfx.play("craft")
		_status.text = "Wytworzono: %s" % name
		_status.add_theme_color_override("font_color", OK_COLOR)
		_player.item_picked.emit(recipe["result"], int(recipe["amount"]))
	else:
		Sfx.play("ui_error")
		_status.text = "Brak składników albo miejsca w plecaku"
		_status.add_theme_color_override("font_color", MISSING_COLOR)
