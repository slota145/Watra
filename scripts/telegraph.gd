class_name Telegraph
extends Node2D
## Czerwona poświata na ziemi zapowiadająca atak bossa. Kształt wypełnia się od środka,
## a w chwili pełnego wypełnienia atak uderza. Leży na warstwie podłóg (pod postaciami).

enum Shape { CIRCLE, LINE, CONE }

const FILL := Color(1.0, 0.12, 0.06, 0.18)
const CHARGE := Color(1.0, 0.18, 0.08, 0.38)
const EDGE := Color(1.0, 0.25, 0.12, 0.85)

var shape := Shape.CIRCLE
var radius := 40.0
## LINE: długość i szerokość pasa (od pozycji węzła w kierunku `rotation`).
var length := 120.0
var width := 26.0
## CONE: połowa kąta stożka (w radianach), skierowanego wzdłuż `rotation`.
var half_arc := deg_to_rad(45.0)
var duration := 1.0
var progress := 0.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	progress = minf(1.0, progress + delta / duration)
	queue_redraw()


## Czy punkt świata leży w obszarze ataku.
func contains(point: Vector2) -> bool:
	var local := (point - global_position).rotated(-rotation)
	match shape:
		Shape.CIRCLE:
			return local.length() <= radius
		Shape.LINE:
			return local.x >= -width / 2.0 and local.x <= length and absf(local.y) <= width / 2.0
		Shape.CONE:
			return local.length() <= radius and absf(local.angle()) <= half_arc
	return false


func _draw() -> void:
	# krawędź pulsuje coraz szybciej, im bliżej uderzenia
	var pulse := 0.75 + 0.25 * sin(_time * lerpf(8.0, 22.0, progress))
	var edge := Color(EDGE, EDGE.a * pulse)
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, FILL)
			draw_circle(Vector2.ZERO, radius * progress, CHARGE)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, edge, 1.5)
		Shape.LINE:
			draw_rect(Rect2(0, -width / 2.0, length, width), FILL)
			draw_rect(Rect2(0, -width / 2.0, length * progress, width), CHARGE)
			draw_rect(Rect2(0, -width / 2.0, length, width), edge, false, 1.5)
		Shape.CONE:
			draw_colored_polygon(_cone(radius), FILL)
			if progress > 0.02:
				draw_colored_polygon(_cone(radius * progress), CHARGE)
			var outline := _cone(radius)
			outline.append(outline[0])
			draw_polyline(outline, edge, 1.5)


func _cone(r: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 16
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(-half_arc, half_arc, float(i) / steps)) * r)
	return points
