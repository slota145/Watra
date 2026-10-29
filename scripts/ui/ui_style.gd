class_name UiStyle
## Wspólny wygląd okien interfejsu (panele, sloty, napisy).

const BG := Color(0.1, 0.11, 0.17, 0.94)
const BORDER := Color(0.62, 0.5, 0.32)
const SLOT_BG := Color(0.17, 0.18, 0.26)
const SLOT_BORDER := Color(0.3, 0.31, 0.42)
const OUTLINE := Color(0.1, 0.11, 0.17)
const TITLE_COLOR := Color(1.0, 0.85, 0.45)
const TEXT_COLOR := Color(0.92, 0.92, 0.95)
const DIM_COLOR := Color(0.65, 0.67, 0.75)


static func panel(bg := BG, border := BORDER, padding := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	return style


## Dymek podpowiedzi z kolorami (opisy przedmiotów używają BBCode) - wołać zaraz po utworzeniu węzła.
static func rich_tooltip(node: Control) -> void:
	node.set_script(RichTooltip)


## Ikony przedmiotów, umiejętności i interfejsu mają 64x64 px (PixelLab) i są pokazywane w polu `size`
## pikseli interfejsu (zwykle 16): przy skali okna x4 piksel w piksel, przy mniejszej płynnie pomniejszone
## (filtr liniowy zamiast gubienia co drugiego piksela).
static func fit_icon(rect: TextureRect, size := 16.0) -> TextureRect:
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.custom_minimum_size = Vector2(size, size)
	return rect


## Ikona na środku kratki (zamiast rozciągania na całą kratkę) - kwadrat `size` px.
static func center_icon(rect: TextureRect, size := 16.0) -> TextureRect:
	fit_icon(rect, size)
	rect.anchor_left = 0.5
	rect.anchor_top = 0.5
	rect.anchor_right = 0.5
	rect.anchor_bottom = 0.5
	rect.offset_left = -size / 2.0
	rect.offset_top = -size / 2.0
	rect.offset_right = size / 2.0
	rect.offset_bottom = size / 2.0
	return rect


## Ikona 64 px na przycisku w polu `size` px.
static func fit_button_icon(button: Button, size := 16) -> void:
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", size)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## Ramka jakości na kratce z przedmiotem: niebieska (magiczny), żółta (rzadki) albo
## migocząca pomarańczowo-złota (legendarny); zwykłe przedmioty jej nie mają.
static func set_item_frame(slot: Control, id: String) -> void:
	var frame := slot.get_node_or_null("ItemFrame") as LegendaryFrame
	var rarity := Items.rarity_of(id) if id != "" else "common"
	var wanted := rarity != "common"
	if frame != null and (not wanted or frame.rarity != rarity):
		slot.remove_child(frame)
		frame.queue_free()
		frame = null
	if wanted and frame == null:
		frame = LegendaryFrame.new()
		frame.rarity = rarity
		frame.name = "ItemFrame"
		slot.add_child(frame)


static func label(text: String, font_size := 8, color := TEXT_COLOR) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 3)
	return l


static func title(text: String) -> Label:
	var l := label(text, 10, TITLE_COLOR)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Motyw z małą czcionką, także dla dymków podpowiedzi.
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 8
	theme.set_font_size("font_size", "TooltipLabel", 8)
	theme.set_stylebox("panel", "TooltipPanel", panel(Color(0.08, 0.09, 0.13, 0.97), BORDER, 4))
	return theme


## Motyw menu (startowego i pauzy) z dużymi przyciskami.
static func make_menu_theme() -> Theme:
	var theme := make_theme()
	theme.set_font_size("font_size", "Button", 12)
	theme.set_stylebox("normal", "Button", panel(SLOT_BG, BORDER, 4))
	theme.set_stylebox("hover", "Button", panel(Color(0.25, 0.26, 0.36), TITLE_COLOR, 4))
	theme.set_stylebox("pressed", "Button", panel(Color(0.12, 0.13, 0.2), TITLE_COLOR, 4))
	theme.set_stylebox("disabled", "Button", panel(Color(0.12, 0.12, 0.16), SLOT_BORDER, 4))
	theme.set_stylebox("focus", "Button", panel(Color(0, 0, 0, 0), TITLE_COLOR, 4))
	theme.set_color("font_color", "Button", TEXT_COLOR)
	theme.set_color("font_hover_color", "Button", TITLE_COLOR)
	theme.set_color("font_focus_color", "Button", TITLE_COLOR)
	theme.set_color("font_pressed_color", "Button", TITLE_COLOR)
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.45, 0.5))
	theme.set_color("font_outline_color", "Button", OUTLINE)
	theme.set_constant("outline_size", "Button", 3)
	return theme


static func menu_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 22)
	button.pressed.connect(on_pressed)
	return button
