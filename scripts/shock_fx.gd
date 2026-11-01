class_name ShockFx
extends Node2D
## Porażenie prądem na wrogu trafionym Łańcuchem błyskawic: wokół ciała przez chwilę skaczą drobne,
## migoczące łuki elektryczne i iskry. Węzeł jest dzieckiem wroga, więc idzie razem z nim;
## kolejne trafienie tylko odświeża czas.

const TIME := 0.7
const CORE := Color(1.0, 0.97, 0.82)
const GLOW := Color(0.4, 0.62, 1.0, 0.75)
## Migocząca poświata wokół całego wroga.
const AURA := Color(0.45, 0.65, 1.0, 0.16)
const RESHAPE := 0.05

## Promień ciała wroga (łuki skaczą po jego obrzeżu).
var radius := 8.0

var _left := TIME
var _reshape := 0.0
var _arcs: Array[PackedVector2Array] = []
var _sparks := PackedVector2Array()


## Porażenie wroga (`center` - środek ciała w świecie, `body_radius` - jego rozmiar).
static func apply(enemy: Node2D, center: Vector2, body_radius: float) -> void:
	var fx: ShockFx = null
	for child in enemy.get_children():
		if child is ShockFx and not child.is_queued_for_deletion():
			fx = child
	if fx == null:
		fx = ShockFx.new()
		fx.z_index = 25
		enemy.add_child(fx)
	fx.position = enemy.to_local(center)
	fx.radius = clampf(body_radius, 5.0, 24.0)
	fx._left = TIME


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_reshape -= delta
	if _reshape <= 0.0:
		_reshape = RESHAPE
		_build()
	modulate.a = clampf(_left / 0.2, 0.0, 1.0)
	queue_redraw()


## Nowe losowe łuki: każdy zaczyna się przy obrzeżu ciała i biegnie krótkim zygzakiem wzdłuż niego.
func _build() -> void:
	_arcs.clear()
	for k in randi_range(3, 4):
		var angle := randf() * TAU
		var turn := randf_range(0.5, 1.1) * (1.0 if randf() < 0.5 else -1.0)
		var arc := PackedVector2Array()
		var segments := randi_range(3, 4)
		for i in segments + 1:
			var a := angle + turn * i / segments
			var r := radius * randf_range(0.7, 1.25)
			arc.append(Vector2.from_angle(a) * Vector2(r, r * 1.2))
		_arcs.append(arc)
	_sparks.clear()
	for k in randi_range(1, 3):
		_sparks.append(Vector2.from_angle(randf() * TAU) * radius * randf_range(1.1, 1.6))


func _draw() -> void:
	if int(_left * 20.0) % 2 == 0:
		draw_circle(Vector2.ZERO, radius * 1.4, AURA)
	for arc in _arcs:
		draw_polyline(arc, GLOW, 4.0)
	for arc in _arcs:
		draw_polyline(arc, CORE, 1.0)
	for spark in _sparks:
		draw_rect(Rect2(spark - Vector2.ONE * 0.5, Vector2.ONE), CORE)
