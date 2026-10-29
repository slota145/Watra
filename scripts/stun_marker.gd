class_name StunMarker
extends Node2D
## Znacznik ogłuszenia nad głową wroga: krążące żółte gwiazdki na płaskiej orbicie.

const STAR_COLOR := Color(1.0, 0.9, 0.3)
const STAR_SHINE := Color(1.0, 1.0, 0.85)
const STARS := 3

var radius := 8.0
var _time := 0.0


func _ready() -> void:
	z_index = 5
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# tylna połowa orbity jest ciemniejsza i mniejsza - złudzenie głębi
	for i in STARS:
		var angle := _time * 5.0 + TAU * i / STARS
		var depth := sin(angle)  # -1 z tyłu, 1 z przodu
		var p := Vector2(cos(angle) * radius, depth * radius * 0.35)
		var s := 2.8 + depth * 0.7
		var color := STAR_COLOR.darkened(0.35 * (1.0 - depth) / 2.0)
		_star(p, s, color)


func _star(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 10:
		var r := size * (1.0 if k % 2 == 0 else 0.45)
		points.append(center + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * r)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_colored_polygon(points, color)
	draw_polyline(outline, Color(0.35, 0.22, 0.05, 0.9), 1.0)
	draw_rect(Rect2(center - Vector2(0.5, 0.5), Vector2(1, 1)), STAR_SHINE)
