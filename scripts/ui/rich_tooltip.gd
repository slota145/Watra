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
const IMAGE := "\\[img[^\\]]*\\][^\\[]*\\[/img\\]"
const IMAGE_WIDTH := 9.0


func _make_custom_tooltip(for_text: String) -> Object:
	return build(self, for_text)


## Dymek z BBCode dla dowolnej kontrolki (np. kratki paska, drzewka umiejętności, które mają już własny skrypt):
## w jej _make_custom_tooltip wystarczy `return RichTooltip.build(self, for_text)`.
static func build(owner: Control, for_text: String) -> Control:
	var font := owner.get_theme_default_font()
	var parts := for_text.split(Items.COMPARE_SPLIT)
	if parts.size() == 1:
		return _panel(for_text, font)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in parts.size():
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(_panel(parts[i], font))
	return row


## Opis z ikoną przedmiotu (znacznik Items.ICON_MARK) po lewej stronie u góry.
static func _panel(text: String, font: Font) -> Control:
	var found := RegEx.create_from_string(Items.ICON_MARK + "([^" + Items.ICON_MARK + "]*)" + Items.ICON_MARK).search(text)
	if found == null:
		return _label(text, font)
	text = Items.strip_icon(text)
	var icon: Texture2D = Items.get_data(found.get_string(1)).get("icon")
	if icon == null:
		return _label(text, font)
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
	box.add_child(_label(text, font))
	return box


static func _label(text: String, font: Font) -> RichTextLabel:
	var label := RichTextLabel.new()
	# tekst dymka jest już przetłumaczony (Lang.t przy składaniu) - etykieta nie tłumaczy go drugi raz
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	# szerokość dymka dopasowana do najdłuższej linii (bez znaczników kolorów; obrazek [img] liczy się jako IMAGE_WIDTH)
	var image := RegEx.create_from_string(IMAGE)
	var tags := RegEx.create_from_string(TAGS)
	var widest := 0.0
	for line in text.split("\n"):
		var images := image.search_all(line).size()
		var plain := tags.sub(image.sub(line, "", true), "", true)
		widest = maxf(widest, font.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + images * IMAGE_WIDTH)
	label.custom_minimum_size.x = minf(widest + 6.0, MAX_WIDTH)
	label.text = text
	return label
