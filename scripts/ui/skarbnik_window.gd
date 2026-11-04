class_name SkarbnikWindow
extends PanelContainer
## Oferta Skarbnika (Skarbnik.show_offer): nagrody obok siebie (ikona, opis, „Weź”), a pod nimi wybór:
## Wzmocnij (fale potworów, oferta rośnie - ostatnie wzmocnienie przemienia przedmioty w legendy), Przelosuj (za Kości
## Skarbnika, fale bez wzrostu siły) i Później (okno zamyka się, Skarbnik czeka - klawisz F).

const COLUMN_WIDTH := 132.0

var _box: VBoxContainer
var _row: HBoxContainer
var _note: Label
var _strengthen: Button
var _reroll: Button
var _spirit: Skarbnik


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.96), Skarbnik.COLOR, 8))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	_box.add_child(UiStyle.title(Lang.t("Skarbnik - oferta")))
	_note = UiStyle.label("", 7, UiStyle.DIM_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_note)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_box.add_child(_row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(buttons)
	_strengthen = _button(buttons, Lang.t("Wzmocnij"), func() -> void:
		visible = false
		if _spirit != null:
			_spirit.strengthen())
	_reroll = _button(buttons, Lang.t("Przelosuj"), func() -> void:
		visible = false
		if _spirit != null:
			_spirit.reroll())
	var later := _button(buttons, Lang.t("Później"), func() -> void:
		visible = false
		Sfx.play("ui_close"))
	later.tooltip_text = Lang.t("Zamknij - Skarbnik poczeka (F)")


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


## Pokazuje ofertę Skarbnika.
func open(spirit: Skarbnik) -> void:
	_spirit = spirit
	var offer := spirit.current_offer()
	var step := int(offer["step"])
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var rewards: Array = offer["rewards"]
	for i in rewards.size():
		_row.add_child(_column(rewards[i], step, i))
	var waves := SkarbnikOffer.waves_for(offer)
	var level: int = spirit.dungeon.level if spirit.dungeon != null else 1
	_note.text = Lang.t("Wzmocnienie %d/%d. Weź jedną nagrodę albo zaryzykuj -\nśmierć w falach odbiera całą ofertę.") \
			% [step, Dungeons.SKA_MAX_STEPS]
	_strengthen.disabled = not SkarbnikOffer.can_strengthen(offer)
	_strengthen.text = Lang.t("Przemień w legendy") if step + 1 == Dungeons.SKA_MAX_STEPS else Lang.t("Wzmocnij")
	_strengthen.tooltip_text = Lang.t("Oferta jest już najsilniejsza") if _strengthen.disabled else \
			Lang.t("Fale: %d, potwory na poziomie %d.\nPremie przedmiotów +%d tierów (do sufitu), więcej run i kamieni, lepszy szlif kamieni szlachetnych.") \
			% [waves, level + (step + 1) * Dungeons.SKA_LEVEL_PER_STEP, Dungeons.SKA_TIER_STEP]
	if step + 1 == Dungeons.SKA_MAX_STEPS:
		_strengthen.tooltip_text = Lang.t("Fale: %d, potwory na poziomie %d.\nWszystkie premie na sufit, przedmioty stają się losowymi legendami tego samego rodzaju.") \
				% [waves, level + (step + 1) * Dungeons.SKA_LEVEL_PER_STEP]
	var bones := 0
	var player: Node = spirit._player()
	if player != null:
		bones = player.inventory.count_of(Dungeons.SKA_BONES)
	var free: int = spirit.free_rerolls()
	_reroll.disabled = bones <= 0 and free <= 0
	_reroll.tooltip_text = Lang.t("Koszt: 1 Kości Skarbnika (masz: %d). Fale: %d, bez wzrostu siły.\nNowe rodzaje premii (te same tiery), kamieni i run.") \
			% [bones, SkarbnikOffer.waves_for(offer, true)]
	if free > 0:
		_reroll.tooltip_text = Lang.t("Darmowe przelosowanie z drzewka Watry (zostało: %d). Fale: %d, bez wzrostu siły.") \
				% [free, SkarbnikOffer.waves_for(offer, true)]
	visible = true
	reset_size()
	var screen := get_viewport_rect().size
	position = ((screen - size) / 2.0).floor()
	Sfx.play("ui_open")


func _column(reward: Dictionary, step: int, index: int) -> Control:
	var shown := SkarbnikOffer.shown(reward, step)
	var id: String = shown[0]
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	column.add_theme_constant_override("separation", 4)
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(40, 40)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0))
	var icon := TextureRect.new()
	icon.texture = Items.get_data(id).get("icon")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)
	UiStyle.set_item_frame(frame, id)
	if int(shown[1]) > 1:
		var amount := UiStyle.label("x%d" % int(shown[1]), 8, Color.WHITE)
		amount.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		amount.position -= Vector2(2, 0)
		frame.add_child(amount)
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
	var description := Items.strip_icon(Items.describe(id))
	if int(shown[1]) > 1:
		description = "%d x %s" % [int(shown[1]), description]
	text.text = description
	column.add_child(text)
	var take := Button.new()
	take.text = Lang.t("Weź")
	take.focus_mode = Control.FOCUS_NONE
	take.pressed.connect(func() -> void:
		visible = false
		if _spirit != null:
			_spirit.take(index))
	column.add_child(take)
	return column
