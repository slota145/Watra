class_name HotbarSlot
extends Panel
## Jeden slot paska szybkiego wyboru (przedmiot albo umiejętność): ikona, klawisz w rogu, licznik sztuk,
## odnowienie jako ciemna "wskazówka zegara" z liczbą sekund i błysk, gdy umiejętność znów jest gotowa.
## Przeciąganie obsługuje właściciel (ActionBars) przez wywołania: drag_data, can_drop, drop, dragged_away
## (przeciągnięto poza pasek - slot się opróżnia), cleared (PPM), clicked (LPM bez przeciągania).

var drag_data: Callable
var can_drop: Callable
var drop: Callable
var dragged_away: Callable
var cleared: Callable
var clicked: Callable

var icon: TextureRect
var key_label: Label
var count_label: Label
var cooldown_label: Label
## 0..1 - jaka część odnowienia jeszcze została (0 - gotowa).
var cooldown := 0.0
## Podświetlenie (np. slot, którego atak teraz wyprowadzi dodatkowy cios) i ile okna combo zostało (0..1 -
## kurczący się pierścień wokół slotu).
var highlight := false
var combo_fraction := 0.0
var _dragging := false
var _flash := 0.0
var _normal_style: StyleBox
var _highlight_style: StyleBox


func _init(slot_size: float, key: String) -> void:
	custom_minimum_size = Vector2(slot_size, slot_size)
	theme = UiStyle.make_theme()
	_normal_style = UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0)
	_highlight_style = UiStyle.panel(Color(0.3, 0.24, 0.1), UiStyle.TITLE_COLOR, 0)
	add_theme_stylebox_override("panel", _normal_style)
	icon = TextureRect.new()
	UiStyle.fit_icon(icon, slot_size - 4.0)
	icon.position = Vector2(2, 2)
	icon.size = Vector2(slot_size - 4.0, slot_size - 4.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	key_label = UiStyle.label(key, 6, UiStyle.TITLE_COLOR)
	key_label.position = Vector2(1, -2)
	key_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	key_label.add_theme_constant_override("outline_size", 3)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(key_label)
	count_label = UiStyle.label("", 7)
	count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.offset_right = -1
	count_label.offset_bottom = 2
	count_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	count_label.add_theme_constant_override("outline_size", 3)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_label)
	cooldown_label = UiStyle.label("", 8, Color(1.0, 0.95, 0.8))
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	cooldown_label.add_theme_constant_override("outline_size", 4)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cooldown_label)


## Odnowienie: `left` sekund z `total`; po zejściu do zera slot krótko błyska.
func set_cooldown(left: float, total: float) -> void:
	var fraction := clampf(left / total, 0.0, 1.0) if total > 0.0 and left > 0.0 else 0.0
	if cooldown > 0.0 and fraction == 0.0:
		_flash = 1.0
	if fraction != cooldown:
		cooldown = fraction
		queue_redraw()
	cooldown_label.text = ("%.1f" % left).replace(".", ",") if left > 0.0 and left < 1.0 \
			else str(ceili(left)) if left > 0.0 else ""


func set_highlight(on: bool) -> void:
	if on != highlight:
		highlight = on
		add_theme_stylebox_override("panel", _highlight_style if on else _normal_style)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 3.0, 0.0)
		queue_redraw()
	if highlight:
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	if cooldown > 0.0:
		_draw_sweep(rect, cooldown, Color(0.0, 0.0, 0.0, 0.62))
	if _flash > 0.0:
		draw_rect(rect, Color(1.0, 0.95, 0.7, 0.55 * _flash))
	if highlight:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
		draw_rect(rect.grow(-0.5), Color(1.0, 0.85, 0.35, 0.5 + 0.5 * pulse), false, 1.0)
		if combo_fraction > 0.0:
			var radius := size.x * 0.62
			draw_arc(size / 2.0, radius, -PI / 2.0, -PI / 2.0 + TAU * combo_fraction, 32, Color(1.0, 0.85, 0.35), 1.5)


## Ciemny wycinek "zegara" przycięty do kwadratu: od godziny 12, zgodnie z ruchem wskazówek, `fraction` całości.
func _draw_sweep(rect: Rect2, fraction: float, color: Color) -> void:
	var center := rect.get_center()
	var half := rect.size / 2.0
	var points := PackedVector2Array([center])
	var start := -PI / 2.0 + TAU * (1.0 - fraction)
	var steps := maxi(2, ceili(fraction * 48.0))
	for i in steps + 1:
		var angle := lerpf(start, -PI / 2.0 + TAU, float(i) / steps)
		var dir := Vector2(cos(angle), sin(angle))
		# promień do brzegu kwadratu w tym kierunku
		var reach := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		points.append(center + dir * reach)
	draw_colored_polygon(points, color)


func _get_drag_data(_at: Vector2) -> Variant:
	if not drag_data.is_valid():
		return null
	var data: Variant = drag_data.call()
	if data != null:
		_dragging = true
		set_drag_preview(UiStyle.drag_preview(icon.texture))
	return data


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return can_drop.is_valid() and can_drop.call(data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	drop.call(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		if not get_viewport().gui_is_drag_successful() and dragged_away.is_valid():
			dragged_away.call()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null:
		return
	if mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed and cleared.is_valid():
		cleared.call()
		accept_event()
	elif mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed and clicked.is_valid():
		clicked.call()
		accept_event()
