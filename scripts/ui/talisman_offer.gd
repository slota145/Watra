class_name TalismanOffer
extends PanelContainer
## Nagroda Kręgu Żertwy (Zertwa.claim): wybór jednego z kilku talizmanów - obok siebie ikona, opis i przycisk „Weź”.
## „Później” zamyka okno bez wyboru (otwiera się znów przy pniu ofiarnym, klawisz F).

const COLUMN_WIDTH := 132.0

var _box: VBoxContainer
var _row: HBoxContainer
var _note: Label
var _on_choose: Callable


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.96), Zertwa.COLOR, 8))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	_box.add_child(UiStyle.title(Lang.t("Krąg Żertwy - wybierz talizman")))
	_note = UiStyle.label("", 7, UiStyle.DIM_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_note)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_box.add_child(_row)
	var later := Button.new()
	later.text = Lang.t("Później")
	later.focus_mode = Control.FOCUS_NONE
	later.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	later.tooltip_text = Lang.t("Zamknij - wybór poczeka przy pniu ofiarnym (F)")
	later.pressed.connect(func() -> void:
		visible = false
		Sfx.play("ui_close"))
	_box.add_child(later)


## Pokazuje ofertę; `on_choose(id)` - wołane po wybraniu talizmanu, `bonus` 0..1 - nadwyżka daniny (do napisu).
func open(offer: Array[String], on_choose: Callable, bonus := 0.0) -> void:
	_on_choose = on_choose
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for id in offer:
		_row.add_child(_column(id))
	_note.text = Lang.t("Nadwyżka daniny: +%d%% - lepsza oferta") % roundi(bonus * 100.0) if bonus > 0.0 \
			else Lang.t("Weź jeden - pozostałe przepadną")
	visible = true
	reset_size()
	var screen := get_viewport_rect().size
	position = ((screen - size) / 2.0).floor()
	Sfx.play("ui_open")


func _column(id: String) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	column.add_theme_constant_override("separation", 4)
	var frame := Panel.new()
	var size := Vector2(Talismans.size_of(id)) * 22.0
	frame.custom_minimum_size = size + Vector2(4, 4)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0))
	var icon := TextureRect.new()
	icon.texture = Items.get_data(id).get("icon")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)
	UiStyle.set_item_frame(frame, id)
	# stała wysokość ramki - przyciski w jednym rzędzie
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 48)
	holder.add_child(frame)
	column.add_child(holder)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", 7)
	text.text = Items.strip_icon(Items.describe(id))
	column.add_child(text)
	var take := Button.new()
	take.text = Lang.t("Weź")
	take.focus_mode = Control.FOCUS_NONE
	take.pressed.connect(_choose.bind(id))
	column.add_child(take)
	return column


func _choose(id: String) -> void:
	visible = false
	if _on_choose.is_valid():
		_on_choose.call(id)
