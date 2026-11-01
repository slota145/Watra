class_name Telegraph
extends Node2D
## Czerwona poświata na ziemi zapowiadająca atak bossa. Kształt wypełnia się od środka,
## a w chwili pełnego wypełnienia atak uderza. Leży na warstwie podłóg (pod postaciami).
## W środku biegną znaki ruchu (coraz szybciej): w kole kręgi zbiegające się do środka, na pasie strzałki
## w kierunku ataku, w stożku łuki rozchodzące się na zewnątrz; tuż przed uderzeniem kształt jasno błyska.

enum Shape { CIRCLE, LINE, CONE }

const FILL := Color(1.0, 0.12, 0.06, 0.18)
const CHARGE := Color(1.0, 0.18, 0.08, 0.38)
const EDGE := Color(1.0, 0.25, 0.12, 0.85)
const MARK := Color(1.0, 0.55, 0.3, 0.7)
const FLASH := Color(1.0, 0.85, 0.7, 0.45)
## Od jakiego postępu kształt błyska przed uderzeniem.
const FLASH_FROM := 0.88
## Bezpiecznik: po tylu sekundach od pełnego wypełnienia poświata sama znika (gdy potwór, który miał ją
## sprzątnąć, zniknął wcześniej - np. zabity przez podróżników albo usunięty z krainy).
const LINGER := 3.0

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
	if _time > duration + LINGER:
		queue_free()


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
	# znaki ruchu: faza 0..1 przesuwa się coraz szybciej, im bliżej uderzenia
	var phase := fposmod(_time * lerpf(1.2, 3.5, progress), 1.0)
	var flash := progress >= FLASH_FROM and int(_time * 20.0) % 2 == 0
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, FILL)
			draw_circle(Vector2.ZERO, radius * progress, CHARGE)
			for k in 2:
				var r := radius * (1.0 - fposmod(phase + k * 0.5, 1.0))
				if r > 2.0:
					draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, MARK, 1.0)
			if flash:
				draw_circle(Vector2.ZERO, radius, FLASH)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, edge, 1.5)
		Shape.LINE:
			draw_rect(Rect2(0, -width / 2.0, length, width), FILL)
			draw_rect(Rect2(0, -width / 2.0, length * progress, width), CHARGE)
			var gap := clampf(width * 1.2, 14.0, 30.0)
			var x := fposmod(phase * gap, gap)
			while x < length - 4.0:
				var half := width * 0.32
				draw_polyline(PackedVector2Array([Vector2(x - half * 0.6, -half), Vector2(x, 0.0), Vector2(x - half * 0.6, half)]), MARK, 1.0)
				x += gap
			if flash:
				draw_rect(Rect2(0, -width / 2.0, length, width), FLASH)
			draw_rect(Rect2(0, -width / 2.0, length, width), edge, false, 1.5)
		Shape.CONE:
			draw_colored_polygon(_cone(radius), FILL)
			if progress > 0.02:
				draw_colored_polygon(_cone(radius * progress), CHARGE)
			for k in 2:
				var r := radius * fposmod(phase + k * 0.5, 1.0)
				if r > 4.0:
					draw_arc(Vector2.ZERO, r, -half_arc, half_arc, 20, MARK, 1.0)
			if flash:
				draw_colored_polygon(_cone(radius), FLASH)
			var outline := _cone(radius)
			outline.append(outline[0])
			draw_polyline(outline, edge, 1.5)


func _cone(r: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 16
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(-half_arc, half_arc, float(i) / steps)) * r)
	return points
