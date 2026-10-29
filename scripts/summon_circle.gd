class_name SummonCircle
extends Node2D
## Magiczny krąg przyzwania bossa: na ziemi rozbłyska i obraca się krąg run, z kręgu bije
## słup fioletowego światła, wokół wirują iskry, a na koniec błysk - wtedy pojawia się boss
## (sygnał `summoned`). Krąg dogasa jeszcze chwilę po przyzwaniu.

signal summoned

const CHARGE_TIME := 1.1
const FADE_TIME := 0.9
const COLOR := Color(0.72, 0.4, 1.0)
const SHINE := Color(0.95, 0.85, 1.0)

var radius := 34.0
var _t := 0.0
var _done := false
var _runes: Array[float] = []


func _ready() -> void:
	z_index = 1
	var glow := CanvasItemMaterial.new()  # krąg i słup świecą (mieszanie addytywne)
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow
	for i in 12:
		_runes.append(randf())
	var sparks := CPUParticles2D.new()
	sparks.amount = 40
	sparks.lifetime = 1.0
	# iskry wylatują z obwodu kręgu (spłaszczonego jak na ziemi)
	var ring := PackedVector2Array()
	for k in 32:
		ring.append(Vector2.from_angle(TAU * k / 32.0) * Vector2(radius, radius * 0.55))
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	sparks.emission_points = ring
	sparks.direction = Vector2.UP
	sparks.spread = 10.0
	sparks.gravity = Vector2(0, -40)
	sparks.initial_velocity_min = 10.0
	sparks.initial_velocity_max = 30.0
	sparks.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([SHINE, COLOR, Color(COLOR, 0.0)])
	sparks.color_ramp = fade
	sparks.z_index = 30
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = additive
	sparks.use_parent_material = false
	add_child(sparks)
	get_tree().create_timer(CHARGE_TIME + 0.3).timeout.connect(func() -> void: sparks.emitting = false)


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= CHARGE_TIME:
		_done = true
		summoned.emit()
	if _t >= CHARGE_TIME + FADE_TIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var grow := minf(_t / 0.35, 1.0)
	var fade := 1.0 if _t < CHARGE_TIME else 1.0 - (_t - CHARGE_TIME) / FADE_TIME
	var r := radius * grow
	var spin := _t * 1.6
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))  # płasko na ziemi
	draw_circle(Vector2.ZERO, r, Color(COLOR, 0.14 * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(COLOR, 0.95 * fade), 2.0)
	draw_arc(Vector2.ZERO, r * 0.78, 0.0, TAU, 48, Color(SHINE, 0.7 * fade), 1.0)
	draw_arc(Vector2.ZERO, r * 0.4, 0.0, TAU, 32, Color(COLOR, 0.8 * fade), 1.5)
	# pentagram obracający się wewnątrz kręgu
	var star := PackedVector2Array()
	for k in 6:
		star.append(Vector2.from_angle(spin + k * TAU * 2.0 / 5.0) * r * 0.78)
	draw_polyline(star, Color(COLOR, 0.85 * fade), 1.0)
	# runy między okręgami, krążące w przeciwną stronę
	for i in _runes.size():
		var a := -spin * 0.7 + TAU * i / _runes.size()
		var p := Vector2.from_angle(a) * r * 0.89
		var flicker := 0.6 + 0.4 * sin(_t * 9.0 + _runes[i] * 20.0)
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(SHINE, flicker * fade))
	draw_set_transform(Vector2.ZERO)
	# słup światła rosnący z kręgu, najjaśniejszy w chwili przyzwania
	var beam := clampf(_t / CHARGE_TIME, 0.0, 1.0)
	var height := 90.0 * beam
	var width := r * (0.35 + 0.35 * beam) * fade
	if width > 0.5:
		draw_rect(Rect2(-width, -height, width * 2.0, height), Color(COLOR, 0.22 * fade))
		draw_rect(Rect2(-width * 0.45, -height, width * 0.9, height), Color(SHINE, 0.35 * fade))
	# błysk w chwili przyzwania
	if _t >= CHARGE_TIME and _t < CHARGE_TIME + 0.35:
		var flash := 1.0 - (_t - CHARGE_TIME) / 0.35
		draw_circle(Vector2(0, -12), radius * (1.0 + (1.0 - flash)), Color(SHINE, 0.6 * flash))
