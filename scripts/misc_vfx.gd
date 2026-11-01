class_name MiscVfx
## Drobne efekty z kreatora efektów PixelLab (tools/vfx_art.py, wpisy misc_*, meteor_*, crystal_*, traveler_*
## w pixellab_src/vfx/ids.json) zamiast dawnych cząsteczek (CPUParticles2D, SkillEffects.spark / shockwave):
## iskry, kłąb dymu, odłamki i fala po ziemi są narysowane w szarościach i barwione w grze kolorem źródła
## (modulate), a krąg przyzwania, meteoryt, rozprysk Kryształu Watry i płomień podróżnika mają własne barwy.

const SPARK := preload("res://assets/effects/misc_spark.png")
const PUFF := preload("res://assets/effects/misc_puff.png")
const DEBRIS := preload("res://assets/effects/misc_debris.png")
const RING := preload("res://assets/effects/misc_ring.png")
const SUMMON := preload("res://assets/effects/misc_summon.png")
const SMOKE_RING := preload("res://assets/effects/misc_smoke_ring.png")
const CRACKLE := preload("res://assets/effects/misc_crackle.png")
const METEOR_TRAIL := preload("res://assets/effects/meteor_trail.png")
const METEOR_IMPACT := preload("res://assets/effects/meteor_impact.png")
const CRYSTAL_SHATTER := preload("res://assets/effects/crystal_shatter.png")
const TRAVELER_FLAME := preload("res://assets/effects/traveler_flame.png")

## Promień fali w klatce misc_ring (px) i kręgu misc_smoke_ring.
const RING_RADIUS := 54.0
const SMOKE_RING_RADIUS := 50.0
## Wysokość w klatce misc_debris, na której odłamki spadają na ziemię.
const DEBRIS_FLOOR := 54.0
## Czas trwania kręgu przyzwania (16 klatek, 8 na sekundę) i chwila błysku (klatka 10).
const SUMMON_FPS := 8.0
const SUMMON_FLASH := 9.0 / SUMMON_FPS


## Jednorazowy efekt z arkusza klatek (jeden rząd), barwiony `tint`; zwraca sprite (już w drzewie).
static func once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		size := 1.0, tint := Color.WHITE, angle := 0.0) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = 25
	fx.modulate = tint
	fx.rotation = angle
	fx.scale = Vector2.ONE * size
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)
	return fx


## Rozmiar efektu z dawnej liczby cząsteczek (4 - mały błysk, 24 - duży wybuch).
static func amount_size(amount: int) -> float:
	return clampf(0.45 + amount / 16.0, 0.5, 2.0)


## Iskry trafienia w kolorze źródła (zamiast SkillEffects.spark).
static func spark(parent: Node, at: Vector2, tint: Color, size := 1.0) -> void:
	once(parent, SPARK, 6, 16.0, at, Vector2(33, 22), size * 1.25, tint)


## Kłąb dymu albo magii w kolorze źródła (pojawienie się, zniknięcie, rozsypanie).
static func puff(parent: Node, at: Vector2, tint: Color, size := 1.0) -> void:
	once(parent, PUFF, 10, 12.0, at, Vector2(38, 34), size, tint)


## Odłamki skał, ziemi albo kości podrzucone uderzeniem z punktu na ziemi `ground` (spadają i zostają tam chwilę).
static func debris(parent: Node, ground: Vector2, tint: Color, size := 1.0) -> void:
	once(parent, DEBRIS, 12, 14.0, ground, Vector2(46, DEBRIS_FLOOR), size, tint)


## Fala po ziemi o promieniu `radius` w kolorze źródła (zamiast SkillEffects.shockwave).
static func ring(parent: Node, at: Vector2, radius: float, tint: Color) -> void:
	once(parent, RING, 9, 16.0, at, Vector2(60, 32), maxf(radius / RING_RADIUS, 0.3), tint)


## Płomień Watry, w którym podróżnik przybywa albo odchodzi.
static func traveler_flame(parent: Node, at: Vector2, size := 1.0) -> void:
	once(parent, TRAVELER_FLAME, 12, 14.0, at, Vector2(36, 74), size)


## Uderzenie meteorytu: rozbłysk, ogień, odłamki i pył (promień pyłu w klatce około 38 px).
static func meteor_impact(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, METEOR_IMPACT, 10, 12.0, at, Vector2(41, 35), maxf(radius / 38.0, 0.6))


## Rozprysk Kryształu Watry: rozbłysk, odłamki kryształu i fala (promień fali w klatce około 54 px).
static func crystal_shatter(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, CRYSTAL_SHATTER, 12, 14.0, at, Vector2(67, 53), maxf(radius / 54.0, 0.4))


## Krąg przyzwania bossa: krąg run, słup światła, błysk po SUMMON_FLASH s, dogasanie (2 s).
static func summon(parent: Node, at: Vector2, size := 1.0) -> Sprite2D:
	var fx := once(parent, SUMMON, 16, SUMMON_FPS, at, Vector2(56, 104), size)
	fx.z_index = 1
	return fx


## Zapętlony efekt (węzeł do dodania jako dziecko): `which` - "smoke_ring", "crackle" albo "meteor_trail".
static func looping(which: String) -> FxLoop:
	match which:
		"smoke_ring":
			return FxLoop.make(SMOKE_RING, 12, 8.0, Vector2(56, 34))
		"crackle":
			return FxLoop.make(CRACKLE, 12, 12.0, Vector2(21, 26))
		_:
			return FxLoop.make(METEOR_TRAIL, 8, 12.0, Vector2(78, 16))
