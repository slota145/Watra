class_name RichTooltip
extends Control
## Skrypt doklejany (UiStyle.rich_tooltip) do kratek i wierszy z przedmiotami: dymek
## podpowiedzi rozumie kolory BBCode - np. wartości zmienione przez inny przedmiot są zielone.
## Tekst z Items.COMPARE_SPLIT to kilka opisów: przedmiot i założone przedmioty do porównania - obok siebie.
## Znacznik Items.ICON_MARK w opisie rysuje obok niego ikonę przedmiotu.

const FONT_SIZE := 8
const MAX_WIDTH := 230.0
const ICON_SIZE := Vector2(28, 28)
const TAGS := "\\[/?[a-z]+(=[^\\]]*)?\\]"


func _make_custom_tooltip(for_text: String) -> Object:
	var parts := for_text.split(Items.COMPARE_SPLIT)
	if parts.size() == 1:
		return _panel(for_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in parts.size():
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(_panel(parts[i]))
	return row


## Opis z ikoną przedmiotu (znacznik Items.ICON_MARK) po lewej stronie u góry.
func _panel(text: String) -> Control:
	var found := RegEx.create_from_string(Items.ICON_MARK + "([^" + Items.ICON_MARK + "]*)" + Items.ICON_MARK).search(text)
	if found == null:
		return _label(text)
	text = Items.strip_icon(text)
	var icon: Texture2D = Items.get_data(found.get_string(1)).get("icon")
	if icon == null:
		return _label(text)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var frame := TextureRect.new()
	frame.texture = icon
	frame.custom_minimum_size = ICON_SIZE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(frame)
	box.add_child(_label(text))
	return box


func _label(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	# szerokość dymka dopasowana do najdłuższej linii (bez znaczników kolorów)
	var plain := RegEx.create_from_string(TAGS).sub(text, "", true)
	var font := get_theme_default_font()
	var widest := 0.0
	for line in plain.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	label.custom_minimum_size.x = minf(widest + 6.0, MAX_WIDTH)
	label.text = text
	return label
