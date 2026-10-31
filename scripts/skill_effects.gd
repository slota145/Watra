class_name SkillEffects
## Efekty wizualne umiejętności dodatkowych: poszarpane błyskawice, rozbłysk stożka fali
## piorunów i rozchodząca się fala szerokiego cięcia (półksiężyc), a także efekty
## legendarnych pierścieni: fala uderzeniowa i fala wody.


## Błyskawica od `from` do `to`: poszarpana linia z poświatą, gasnąca po chwili.
static func bolt(parent: Node, from: Vector2, to: Vector2, life := 0.28, jag := 6.0) -> void:
	var points := PackedVector2Array([from])
	var steps := maxi(3, int(from.distance_to(to) / 14.0))
	var normal := (to - from).normalized().orthogonal()
	for i in range(1, steps):
		points.append(from.lerp(to, float(i) / steps) + normal * randf_range(-jag, jag))
	points.append(to)
	var holder := Node2D.new()
	holder.z_index = 25
	for layer: Array in [[6.0, Color(0.45, 0.65, 1.0, 0.35)], [2.0, Color(0.85, 0.95, 1.0)], [1.0, Color.WHITE]]:
		var line := Line2D.new()
		line.points = points
		line.width = layer[0]
		line.default_color = layer[1]
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		holder.add_child(line)
	parent.add_child(holder)
	var tween := holder.create_tween()
	tween.tween_property(holder, "modulate:a", 0.0, life).set_ease(Tween.EASE_IN)
	tween.tween_callback(holder.queue_free)
	spark(parent, to, Color(0.75, 0.9, 1.0), 6)


## Iskry w miejscu trafienia.
static func spark(parent: Node, at: Vector2, color: Color, amount := 8) -> void:
	var p := CPUParticles2D.new()
	p.global_position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.3
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2.ZERO
	p.scale_amount_max = 2.0
	p.color = color
	p.z_index = 26
	p.emitting = true
	parent.add_child(p)
	p.finished.connect(p.queue_free)


## Jednorazowa animacja z arkusza klatek (jeden rząd, np. efekty z kreatora PixelLab - tools/vfx_art.py):
## punkt zaczepienia `anchor` (piksel klatki) staje w `at`, efekt obrócony o `angle` (rysowany w prawo, +x);
## `stretch` rozciąga go wzdłuż kierunku, `size` powiększa całość. W lewo efekt odbija się w pionie, żeby nie stał
## do góry nogami. `lean` (rad) koryguje rysunek pochylony pod górę: obraca go w dół (po odbiciu - w drugą stronę).
## `mirror` odbija efekt w pionie (np. zamach w drugą stronę).
static func sheet_once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		angle := 0.0, stretch := 1.0, size := 1.0, lean := 0.0, mirror := false) -> void:
	var flipped := (absf(wrapf(angle, -PI, PI)) > PI / 2.0) != mirror
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = 25
	fx.rotation = angle + (-lean if flipped else lean)
	fx.scale = Vector2(stretch, -1.0 if flipped else 1.0) * size
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)


## Rozbłysk w kształcie stożka (fala piorunów).
static func cone(parent: Node, origin: Vector2, angle: float, half_arc: float, radius: float) -> void:
	var flash := ConeFlash.new()
	flash.global_position = origin
	flash.rotation = angle
	flash.half_arc = half_arc
	flash.radius = radius
	parent.add_child(flash)


## Fala szerokiego cięcia rozchodząca się po łuku (półksiężyc).
static func crescent(parent: Node, origin: Vector2, angle: float, half_arc: float, radius: float) -> void:
	var wave := CrescentWave.new()
	wave.global_position = origin
	wave.rotation = angle
	wave.half_arc = half_arc
	wave.radius = radius
	parent.add_child(wave)


## Fala uderzeniowa: rozchodzący się pierścień, pęknięcia ziemi i kurz.
static func shockwave(parent: Node, origin: Vector2, radius: float, color: Color) -> void:
	var ring := ShockRing.new()
	ring.global_position = origin
	ring.radius = radius
	ring.color = color
	parent.add_child(ring)
	var dust := CPUParticles2D.new()
	dust.global_position = origin
	dust.one_shot = true
	dust.explosiveness = 0.9
	dust.amount = 26
	dust.lifetime = 0.6
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 6.0
	dust.spread = 180.0
	dust.initial_velocity_min = 50.0
	dust.initial_velocity_max = 110.0
	dust.damping_min = 120.0
	dust.damping_max = 160.0
	dust.gravity = Vector2.ZERO
	dust.scale_amount_min = 1.5
	dust.scale_amount_max = 3.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.75, 0.65, 0.5, 0.8), Color(0.55, 0.48, 0.38, 0.0)])
	dust.color_ramp = fade
	dust.z_index = 2
	dust.emitting = true
	parent.add_child(dust)
	dust.finished.connect(dust.queue_free)
	spark(parent, origin + Vector2(0, -6), color, 12)


## Pęknięcia ziemi po potężnym uderzeniu: rozgałęzione szczeliny od środka, płasko na ziemi,
## widoczne `life` sekund (ostatnia trzecia - gasną).
static func ground_crack(parent: Node, origin: Vector2, radius: float, life := 3.0) -> void:
	var crack := GroundCrack.new()
	crack.radius = radius
	crack.life = life
	parent.add_child(crack)
	crack.global_position = origin


class GroundCrack:
	extends Node2D
	var radius := 40.0
	var life := 3.0
	var _t := 0.0
	var _lines: Array[PackedVector2Array] = []

	func _ready() -> void:
		var count := 9
		for i in count:
			var a := TAU * i / count + randf_range(-0.25, 0.25)
			var p := Vector2.ZERO
			var line := PackedVector2Array([p])
			var length := radius * randf_range(0.55, 1.0)
			var steps := 5
			for k in steps:
				p += Vector2.from_angle(a + randf_range(-0.45, 0.45)) * length / steps
				line.append(Vector2(p.x, p.y * 0.55))
				# odgałęzienie
				if k == 2 and randf() < 0.6:
					var b := p + Vector2.from_angle(a + randf_range(0.6, 1.1) * (1 if randf() < 0.5 else -1)) * length * 0.3
					_lines.append(PackedVector2Array([Vector2(p.x, p.y * 0.55), Vector2(b.x, b.y * 0.55)]))
			_lines.append(line)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var alpha := clampf((life - _t) / (life / 3.0), 0.0, 1.0)
		for line in _lines:
			draw_polyline(line, Color(0.12, 0.08, 0.05, 0.75 * alpha), 2.0)
			draw_polyline(line, Color(0.55, 0.42, 0.3, 0.35 * alpha), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius * 0.25, Color(0.1, 0.07, 0.04, 0.35 * alpha))


## Fala wody: stożek przetaczającej się wody z pianą na czole i rozbryzgiem kropel.
static func tide(parent: Node, origin: Vector2, angle: float, half_arc: float, radius: float, echo := false) -> void:
	var wave := TideWave.new()
	wave.global_position = origin
	wave.rotation = angle
	wave.half_arc = half_arc
	wave.radius = radius
	wave.tint = Color(0.7, 0.85, 1.0) if echo else Color.WHITE
	parent.add_child(wave)


## Zamaszyste cięcie pazurami: trzy równoległe smugi po łuku, czarno-szaro-białe, rozdzierane
## od początku do końca i gasnące. side -1 tnie z lewej góry w prawy dół, 1 z prawej góry w lewy dół.
static func claw(parent: Node, at: Vector2, side: float, size: float, color: Color) -> void:
	var slash := ClawSlash.new()
	slash.global_position = at
	slash.side = side
	slash.size = size
	slash.color = color
	parent.add_child(slash)
	spark(parent, at, Color(0.85, 0.85, 0.88), 8)


class ClawSlash:
	extends Node2D
	var side := -1.0
	var size := 34.0
	var color := Color.WHITE
	var _t := 0.0

	func _ready() -> void:
		z_index = 26

	func _process(delta: float) -> void:
		_t += delta / 0.32
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	## Punkt na łuku (u 0..1): od górnego rogu do dolnego, wybrzuszony na zewnątrz krzyża.
	func _point(u: float, offset: float) -> Vector2:
		var start := Vector2(side * size * 0.75, -size * 0.6)
		var end := Vector2(-side * size * 0.75, size * 0.6)
		var dir := (end - start).normalized()
		var normal := Vector2(dir.y, -dir.x) * side  # wybrzuszenie łuku
		# środek łuku przechodzi tuż obok trafionego, końce zawijają się do środka
		var p := start.lerp(end, u) + normal * (sin(u * PI) - 0.65) * size * 0.45
		return p + normal * offset

	func _draw() -> void:
		var reach := minf(_t / 0.3, 1.0)  # łuk rozdziera się, potem gaśnie od początku
		var tail := maxf(0.0, (_t - 0.3) / 0.7)
		var alpha := 1.0 - tail * tail
		for k in 3:
			var offset := (k - 1) * 6.0
			var points := PackedVector2Array()
			var steps := 14
			for i in steps + 1:
				var u := lerpf(tail * 0.8, reach, float(i) / steps)
				points.append(_point(u, offset))
			if points.size() < 2:
				continue
			draw_polyline(points, Color(0.04, 0.04, 0.05, 0.75 * alpha), 4.5, true)
			draw_polyline(points, Color(0.55, 0.55, 0.6, 0.9 * alpha), 2.5, true)
			draw_polyline(points, Color(color, alpha), 1.0, true)
			draw_circle(points[-1], 1.4, Color(1, 1, 1, alpha))


class ShockRing:
	extends Node2D
	var radius := 40.0
	var color := Color(1.0, 0.62, 0.15)
	var _t := 0.0
	var _cracks: Array[PackedVector2Array] = []

	func _ready() -> void:
		z_index = 1
		for i in 7:  # pęknięcia ziemi rozchodzące się od środka
			var a := TAU * i / 7.0 + randf_range(-0.3, 0.3)
			var line := PackedVector2Array([Vector2.ZERO])
			var p := Vector2.ZERO
			for k in 4:
				p += Vector2.from_angle(a + randf_range(-0.5, 0.5)) * radius * randf_range(0.15, 0.25)
				line.append(Vector2(p.x, p.y * 0.55))
			_cracks.append(line)

	func _process(delta: float) -> void:
		_t += delta / 0.5
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var e := 1.0 - pow(1.0 - _t, 3.0)
		var alpha := 1.0 - _t
		for line in _cracks:
			draw_polyline(line, Color(0.2, 0.14, 0.1, 0.7 * alpha), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))  # płasko na ziemi
		draw_circle(Vector2.ZERO, radius * e, Color(color, 0.18 * alpha))
		draw_arc(Vector2.ZERO, radius * e, 0.0, TAU, 48, Color(color, 0.9 * alpha), 3.0)
		draw_arc(Vector2.ZERO, radius * e - 3.0, 0.0, TAU, 48, Color(1.0, 0.95, 0.75, 0.8 * alpha), 1.5)
		draw_arc(Vector2.ZERO, radius * e * 0.6, 0.0, TAU, 40, Color(color, 0.5 * alpha), 2.0)


class TideWave:
	extends Node2D
	var half_arc := 0.6
	var radius := 80.0
	var tint := Color.WHITE
	var _t := 0.0
	var _drops: Array = []

	func _ready() -> void:
		z_index = 2
		for i in 22:
			var a := randf_range(-half_arc, half_arc)
			_drops.append([a, randf_range(0.5, 1.05), randf_range(0.0, 0.35), randf_range(1.0, 2.0)])

	func _process(delta: float) -> void:
		_t += delta / 0.55
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var e := 1.0 - pow(1.0 - _t, 2.0)
		var front := radius * e
		var back := maxf(0.0, front - 26.0)
		var alpha := 1.0 - _t * _t
		# korpus fali: pas wody między tyłem a czołem
		var body := PackedVector2Array()
		for i in 17:
			body.append(Vector2.from_angle(lerpf(-half_arc, half_arc, i / 16.0)) * front)
		for i in 17:
			body.append(Vector2.from_angle(lerpf(half_arc, -half_arc, i / 16.0)) * back)
		draw_colored_polygon(body, Color(0.15, 0.55, 0.75, 0.55 * alpha) * tint)
		# grzbiet i piana
		draw_arc(Vector2.ZERO, front - 6.0, -half_arc, half_arc, 24, Color(0.3, 0.8, 0.9, 0.8 * alpha) * tint, 4.0)
		draw_arc(Vector2.ZERO, front - 1.5, -half_arc, half_arc, 24, Color(0.92, 1.0, 1.0, 0.95 * alpha), 2.0)
		# krople lecące przed falą
		for d: Array in _drops:
			var r: float = front * d[1] + d[2] * 30.0 * _t
			var p := Vector2.from_angle(d[0]) * r + Vector2(0, -sin(_t * PI) * 6.0 * d[1])
			draw_rect(Rect2(p, Vector2(d[3], d[3])), Color(0.8, 0.95, 1.0, 0.9 * alpha))


class ConeFlash:
	extends Node2D
	var half_arc := 0.6
	var radius := 120.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta / 0.45
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := radius * minf(1.0, _t * 3.0)
		var points := PackedVector2Array([Vector2.ZERO])
		for i in 17:
			points.append(Vector2.from_angle(lerpf(-half_arc, half_arc, i / 16.0)) * r)
		draw_colored_polygon(points, Color(0.55, 0.75, 1.0, 0.35 * (1.0 - _t)))
		points.append(Vector2.ZERO)
		draw_polyline(points, Color(0.85, 0.95, 1.0, 0.8 * (1.0 - _t)), 1.5)


class CrescentWave:
	extends Node2D
	var half_arc := 2.6
	var radius := 50.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta / 0.3
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := radius * (0.55 + 0.45 * _t)
		var alpha := 1.0 - _t
		draw_arc(Vector2.ZERO, r, -half_arc, half_arc, 40, Color(1.0, 0.95, 0.85, 0.9 * alpha), 4.0)
		draw_arc(Vector2.ZERO, r - 4.0, -half_arc, half_arc, 40, Color(1.0, 0.7, 0.45, 0.5 * alpha), 3.0)
