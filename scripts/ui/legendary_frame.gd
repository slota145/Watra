class_name LegendaryFrame
extends Control
## Pomarańczowo-złota ramka kratki z legendarnym przedmiotem: podwójny obrys, ciepła poświata
## w środku, migoczące rogi i błysk przesuwający się po obwodzie - od razu widać, że to coś
## wyjątkowego. Dla przedmiotów magicznych i rzadkich - prosta ramka w kolorze jakości.
## Dodawana i zdejmowana przez UiStyle.set_item_frame().

const OUTER := Color(1.0, 0.55, 0.1)
const INNER := Color(1.0, 0.85, 0.35)
const SHINE := Color(1.0, 0.97, 0.75)

var _time := randf() * 10.0
var rarity := "legendary"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(rarity == "legendary")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if rarity != "legendary":
		var color: Color = Items.RARITY_COLORS[rarity]
		draw_rect(r, Color(color, 0.08), true)
		draw_rect(r.grow(-0.5), color, false, 1.0)
		draw_rect(r.grow(-1.5), Color(color, 0.35), false, 1.0)
		return
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	# ciepła poświata od brzegów do środka
	for i in 3:
		var glow := Color(OUTER, (0.16 - i * 0.05) * (0.7 + 0.3 * pulse))
		draw_rect(r.grow(-1.0 - i), glow, false, 1.0)
	draw_rect(r, Color(OUTER, 0.06 + 0.04 * pulse), true)
	# podwójny obrys
	draw_rect(r.grow(-0.5), OUTER, false, 1.0)
	draw_rect(r.grow(-1.5), Color(INNER, 0.55 + 0.35 * pulse), false, 1.0)
	# złote narożniki
	for corner in [Vector2(0, 0), Vector2(size.x - 3, 0), Vector2(0, size.y - 3), Vector2(size.x - 3, size.y - 3)]:
		draw_rect(Rect2(corner, Vector2(3, 3)), INNER, true)
		draw_rect(Rect2(corner + Vector2(1, 1), Vector2(1, 1)), SHINE, true)
	# błysk biegnący po obwodzie
	var perimeter := 2.0 * (size.x + size.y)
	var t := fmod(_time * 30.0, perimeter)
	for k in 4:
		var p := _point_on_border(fmod(t - k * 1.5 + perimeter, perimeter))
		draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(SHINE, 1.0 - k * 0.25), true)


func _point_on_border(d: float) -> Vector2:
	var w := size.x - 1.0
	var h := size.y - 1.0
	if d < w:
		return Vector2(d, 0)
	d -= w
	if d < h:
		return Vector2(w, d)
	d -= h
	if d < w:
		return Vector2(w - d, h)
	return Vector2(0, h - (d - w))
