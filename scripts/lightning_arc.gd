class_name LightningArc
extends Node2D
## Błyskawica rysowana w kodzie między dwoma punktami (Łańcuch błyskawic): poszarpana linia z jasnym rdzeniem
## i niebieską poświatą, która co chwilę zmienia kształt i gaśnie. Zwęża się do ostrego końca w celu
## i ma krótkie odnogi. Działa przy każdej długości - nic się nie rozciąga.

const CORE := Color(1.0, 0.97, 0.82)
const MID := Color(0.62, 0.8, 1.0, 0.9)
const GLOW := Color(0.35, 0.55, 1.0, 0.35)
## Co ile sekund błyskawica zmienia kształt (migotanie).
const RESHAPE := 0.05

## Koniec błyskawicy względem jej początku.
var end := Vector2.ZERO
## Grubość rdzenia (piksele).
var width := 1.0
## Ile trwa (s), zanim zgaśnie.
var life := 0.25

var _age := 0.0
var _reshape := RESHAPE
var _points := PackedVector2Array()
var _forks: Array[PackedVector2Array] = []


## Nowa błyskawica od `from` do `to` (punkty świata) w węźle `parent`.
static func spawn(parent: Node, from: Vector2, to: Vector2, core_width := 1.0, time := 0.25) -> LightningArc:
	var arc := LightningArc.new()
	arc.width = core_width
	arc.life = time
	arc.z_index = 25
	parent.add_child(arc)
	arc.global_position = from
	arc.end = to - from
	arc._build()
	return arc


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	_reshape -= delta
	if _reshape <= 0.0:
		_reshape = RESHAPE
		_build()
	modulate.a = 1.0 - pow(_age / life, 2.0)
	queue_redraw()


## Losuje nowy kształt: łamana z odchyleniami największymi w środku (końce trzymają się punktów) i 1-2 odnogi.
func _build() -> void:
	var length := end.length()
	if length < 1.0:
		_points = PackedVector2Array([Vector2.ZERO, end])
		_forks.clear()
		return
	var steps := clampi(int(length / 9.0), 3, 30)
	var amp := clampf(length * 0.08, 2.0, 9.0)
	var normal := end.orthogonal() / length
	_points = PackedVector2Array([Vector2.ZERO])
	for i in range(1, steps):
		var t := float(i) / steps
		_points.append(end * t + normal * randf_range(-amp, amp) * sin(PI * t))
	_points.append(end)
	_forks.clear()
	for k in randi_range(1, 2):
		var at := _points[randi_range(1, _points.size() - 2)]
		var dir := end.normalized().rotated(randf_range(0.5, 1.0) * (1.0 if randf() < 0.5 else -1.0))
		var mid := at + dir * randf_range(3.0, 6.0) + normal * randf_range(-2.0, 2.0)
		_forks.append(PackedVector2Array([at, mid, mid + dir.rotated(randf_range(-0.6, 0.6)) * randf_range(3.0, 6.0)]))


func _draw() -> void:
	var count := _points.size() - 1
	# poświata, środek i rdzeń; ostatnia część zwęża się do ostrego końca
	for layer in 3:
		for i in count:
			var t := float(i) / count
			var taper := 1.0 if t < 0.7 else lerpf(1.0, 0.35, (t - 0.7) / 0.3)
			var w := width * taper
			match layer:
				0:
					draw_line(_points[i], _points[i + 1], GLOW, w * 2.0 + 3.0)
				1:
					draw_line(_points[i], _points[i + 1], MID, w + 1.0)
				2:
					draw_line(_points[i], _points[i + 1], CORE, maxf(w, 1.0))
	for fork in _forks:
		draw_polyline(fork, MID, 1.0)
