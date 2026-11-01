class_name LootFeed
extends VBoxContainer
## Powiadomienia o podniesionych lepszych przedmiotach (kamienie, ekwipunek) w prawym
## dolnym rogu ekranu. Okienko wjeżdża z prawej, ikona wyskakuje z poświatą w kolorze
## przedmiotu, a po chwili wszystko płynnie znika. Ten sam przedmiot podniesiony
## kilka razy pod rząd sumuje się w jednym okienku. Doskonałe kamienie mają złotą ramkę i iskry.

const LIFETIME := 2.8
const MAX_TOASTS := 6
const SLIDE := 120.0
const ICON_BOX := Vector2(16, 16)
const GLOW_SIZE := Vector2(24, 24)
const GOLD := Color(1.0, 0.82, 0.3)
const CATEGORY_COLORS := {
	"weapon": Color(1.0, 0.42, 0.45),
	"armor": Color(0.5, 0.72, 1.0),
	"jewelry": Color(0.8, 0.55, 1.0),
}

## id przedmiotu -> {"wrapper", "panel", "icon", "count", "amount", "tween"}
var _toasts := {}
var _glow_texture: GradientTexture2D


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
	_glow_texture = GradientTexture2D.new()
	_glow_texture.gradient = gradient
	_glow_texture.width = 32
	_glow_texture.height = 32
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(1.0, 0.5)


## Czy przedmiot zasługuje na powiadomienie.
static func is_notable(id: String) -> bool:
	var item := Items.get_data(id)
	return item.has("stone") or item.has("enchant_aid") or item.has("slot") or item.get("notable", false)


func show_item(id: String, amount: int) -> void:
	if not is_notable(id):
		return
	if _toasts.has(id):
		var toast: Dictionary = _toasts[id]
		toast["amount"] += amount
		toast["label"].text = _caption(id, toast["amount"])
		_bump(toast)
		_schedule_fade(id)
		return
	if _toasts.size() >= MAX_TOASTS:
		_remove(_oldest_to_drop())
	_create(id, amount)


## Przy nadmiarze okienek znika najstarsze zwykłe - rzadkie (złote) zostają na ekranie.
func _oldest_to_drop() -> String:
	for id: String in _toasts:
		if not _is_epic(id):
			return id
	return _toasts.keys()[0]


# ---------------------------------------------------------------- okienko
func _create(id: String, amount: int) -> void:
	var item := Items.get_data(id)
	var color := _accent(id)
	var epic := _is_epic(id)
	var legendary := Items.is_legendary(id)
	var frame_color := Items.LEGENDARY_COLOR if legendary else GOLD

	# wrapper trzyma miejsce w kolumnie, a panel w środku może swobodnie wjeżdżać z boku
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_END  # okienka wyrównane do prawej
	add_child(wrapper)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel(Color(UiStyle.BG, 0.92), frame_color if epic else color, 2)
	style.set_border_width_all(2 if epic else 1)
	panel.add_theme_stylebox_override("panel", style)
	wrapper.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	panel.add_child(row)

	# ikona z poświatą
	var icon_box := Control.new()
	icon_box.custom_minimum_size = ICON_BOX
	row.add_child(icon_box)
	var glow := TextureRect.new()
	glow.texture = _glow_texture
	glow.modulate = Color(frame_color if epic else color, 0.85)
	glow.size = GLOW_SIZE
	glow.position = (ICON_BOX - glow.size) / 2.0
	glow.pivot_offset = glow.size / 2.0
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	icon_box.add_child(glow)
	var icon := TextureRect.new()
	icon.texture = item["icon"]
	UiStyle.fit_icon(icon)
	icon.size = Vector2(16, 16)
	icon.position = (ICON_BOX - icon.size) / 2.0
	icon.pivot_offset = icon.size / 2.0
	icon_box.add_child(icon)
	if epic:
		icon_box.add_child(_sparkles(id))
	if legendary:
		icon.add_child(LegendaryFrame.new())

	var label := UiStyle.label(_caption(id, amount), 7, frame_color if epic else color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	# rozmiar panelu znany jest dopiero po przeliczeniu układu
	panel.minimum_size_changed.connect(func() -> void: wrapper.custom_minimum_size = panel.get_combined_minimum_size())
	wrapper.custom_minimum_size = panel.get_combined_minimum_size()
	panel.position.x = SLIDE
	panel.modulate.a = 0.0

	# wjazd z prawej i wyskoczenie ikony
	var tween := panel.create_tween().set_parallel()
	tween.tween_property(panel, "position:x", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	icon.scale = Vector2.ONE * 0.2
	tween.tween_property(icon, "scale", Vector2.ONE, 0.45).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# poświata pulsuje przez cały czas życia okienka
	var pulse := glow.create_tween().set_loops()
	pulse.tween_property(glow, "scale", Vector2.ONE * 1.25, 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "scale", Vector2.ONE * 0.85, 0.5).set_trans(Tween.TRANS_SINE)

	_toasts[id] = {"wrapper": wrapper, "panel": panel, "icon": icon, "label": label, "amount": amount, "tween": null}
	_schedule_fade(id)


## Kolejna sztuka tego samego przedmiotu - ikona podskakuje.
func _bump(toast: Dictionary) -> void:
	var icon: TextureRect = toast["icon"]
	var panel: PanelContainer = toast["panel"]
	panel.modulate.a = 1.0
	panel.position.x = 0.0
	icon.scale = Vector2.ONE * 1.5
	icon.create_tween().tween_property(icon, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _schedule_fade(id: String) -> void:
	var toast: Dictionary = _toasts[id]
	if toast["tween"] != null:
		toast["tween"].kill()
	var panel: PanelContainer = toast["panel"]
	var tween := panel.create_tween()
	tween.tween_interval(LIFETIME * (2.5 if Items.is_legendary(id) else 1.0))
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(panel, "position:x", SLIDE * 0.5, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(_remove.bind(id))
	toast["tween"] = tween


func _remove(id: String) -> void:
	if not _toasts.has(id):
		return
	var toast: Dictionary = _toasts[id]
	_toasts.erase(id)
	toast["wrapper"].queue_free()


# ---------------------------------------------------------------- wygląd
func _caption(id: String, amount: int) -> String:
	return "%s  ×%d" % [Items.short_name(id), amount]


func _accent(id: String) -> Color:
	var item := Items.get_data(id)
	if item.has("stone"):
		return CATEGORY_COLORS[item["stone"]["category"]]
	if Items.rarity_of(id) != "common":
		return Items.rarity_color(id)
	if id == "wood":
		return Color(0.85, 0.65, 0.4)
	if id == "stone":
		return Color(0.72, 0.75, 0.82)
	match item.get("enchant_aid", ""):
		"blessed":
			return GOLD
		"mercy":
			return Color(0.45, 0.85, 1.0)
	return UiStyle.TEXT_COLOR


## Rzadkie przedmioty dostają złotą ramkę i iskry (legendarne - pomarańczowo-złotą).
func _is_epic(id: String) -> bool:
	return Items.is_legendary(id) or Items.get_data(id).get("stone", {}).get("perfect", false)


## Zapętlone iskry z kreatora efektów PixelLab wokół ikony: legendarny łup - iskry legendy, reszta - złoty błysk.
func _sparkles(id: String) -> AnimatedSprite2D:
	var fx := WorldVfx.loot_legendary() if Items.is_legendary(id) else WorldVfx.loot_glint("rare")
	fx.position = ICON_BOX / 2.0 + Vector2(0, 2 if Items.is_legendary(id) else 0)
	fx.scale = Vector2.ONE * 0.75
	return fx
