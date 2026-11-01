class_name LegendVfx
## Efekty legendarnych przedmiotów z kreatora efektów PixelLab (tools/vfx_art.py, wpisy "legend_*"
## w pixellab_src/vfx/ids.json) dla LegendaryEffects i LegendFx. Własne grafiki legend: złota fala uderzeniowa,
## fala wody i fala dźwięku (stożki), trująca chmura, półksiężyc wiatru, wachlarz piór, sieć, leczenie (krew,
## liście), krążące kości i pękająca tarcza kości. Pozostałe legendy korzystają z efektów bossów, od których
## pochodzą (pazury Szarokła, wir Wodnika, korzenie Leszego, dym i ryk Biesa, kwas Hydry, fontanna Czerwia,
## krąg dusz Mortana, uderzenie Gnilca, pnącza i fletnia Fauna, trąba Gryfa) i z efektów umiejętności
## (piorun z nieba, łańcuch błyskawic, kula ognia, krwawa rana). Echo legendy (Kieł Alfy) barwi efekt na niebiesko.

const SHOCKWAVE := preload("res://assets/effects/legend_shockwave.png")
const TIDE := preload("res://assets/effects/legend_tide.png")
const SOUND := preload("res://assets/effects/legend_sound_cone.png")
const TOXIC := preload("res://assets/effects/legend_toxic_aura.png")
const WIND := preload("res://assets/effects/legend_wind_crescent.png")
const FEATHERS := preload("res://assets/effects/legend_feathers.png")
const WEB := preload("res://assets/effects/legend_web.png")
const HEAL_BLOOD := preload("res://assets/effects/legend_heal_blood.png")
const HEAL_LEAF := preload("res://assets/effects/legend_heal_leaf.png")
const BONE_ORBIT := preload("res://assets/effects/legend_bone_orbit.png")
const BONE_BURST := preload("res://assets/effects/legend_bone_burst.png")
const STORM := preload("res://assets/effects/storm_strike.png")
const WHIRL := preload("res://assets/effects/wodnik_whirl.png")
const ROOTS := preload("res://assets/effects/leshy_roots.png")
const VINES := preload("res://assets/effects/satyr_vines.png")
const FLUTE := preload("res://assets/effects/satyr_flute.png")
const STOMP := preload("res://assets/effects/satyr_stomp.png")
const SOULS := preload("res://assets/effects/mortan_raise.png")
const GHOUL_SLAM := preload("res://assets/effects/ghoul_slam.png")
const WOUND := preload("res://assets/effects/rend_wound.png")
const VENOM := preload("res://assets/effects/bow_venom_tick.png")
const TORNADO := preload("res://assets/effects/gryf_tornado.png")
const FIREBALL := preload("res://assets/effects/fireball.png")
const FIRE_TRAIL := preload("res://assets/effects/bow_power_trail.png")
const FIRE_BLAST := preload("res://assets/effects/fire_blast.png")
const IMPACT := preload("res://assets/effects/lunge_hit.png")
const SPLASH := preload("res://assets/effects/bulgor_splash.png")

## Promienie efektów w ich klatkach (do skalowania na promień działania legendy).
const SHOCKWAVE_RADIUS := 44.0
const CONE_RADIUS := 86.0
const FEATHERS_RADIUS := 58.0
const WEB_RADIUS := 38.0
const WHIRL_RADIUS := 62.0
const FLUTE_RADIUS := 104.0
const STOMP_RADIUS := 48.0
const SOULS_RADIUS := 58.0
const GHOUL_SLAM_RADIUS := 50.0
const FIRE_TRAIL_LENGTH := 36.0
## Kolor echa (Kieł Alfy) - ten sam co LegendaryEffects.ECHO_COLOR.
const ECHO := Color(0.7, 0.85, 1.0)


## Jednorazowa animacja jak SkillEffects.sheet_once, ale zwraca węzeł (barwa `tint`, np. echo).
static func once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		angle := 0.0, size := 1.0, tint := Color.WHITE, stretch := 1.0) -> Sprite2D:
	var flipped := absf(wrapf(angle, -PI, PI)) > PI / 2.0
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = 25
	fx.rotation = angle
	fx.scale = Vector2(stretch, -1.0 if flipped else 1.0) * size
	fx.modulate = tint
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)
	return fx


static func _tint(echo: bool) -> Color:
	return ECHO if echo else Color.WHITE


# ---------------------------------------------------------------- własne efekty legend
## Złota fala uderzeniowa (Sygnet Gruzłoga): rozbłysk, pęknięcia, pierścień rozchodzący się po ziemi.
static func shockwave(parent: Node, at: Vector2, radius: float, echo := false) -> void:
	once(parent, SHOCKWAVE, 9, 18.0, at, Vector2(52, 40), 0.0, maxf(radius / SHOCKWAVE_RADIUS, 0.6), _tint(echo))


## Fala wody stożkiem w kierunku `angle` (Oko Przypływu, Płaszcz Topielca).
static func tide(parent: Node, origin: Vector2, angle: float, radius: float, echo := false) -> void:
	once(parent, TIDE, 9, 18.0, origin, Vector2(6, 50), angle, maxf(radius / CONE_RADIUS, 0.5), _tint(echo))


## Złota fala dźwięku z nutami stożkiem w kierunku `angle` (Berło Króla Satyrów).
static func sound_cone(parent: Node, origin: Vector2, angle: float, radius: float, echo := false) -> void:
	once(parent, SOUND, 9, 18.0, origin, Vector2(6, 50), angle, maxf(radius / CONE_RADIUS, 0.5), _tint(echo))


## Wachlarz złotych piór z wiatrem (Grzebień Gryfa).
static func feathers(parent: Node, at: Vector2, radius: float, echo := false) -> void:
	once(parent, FEATHERS, 9, 18.0, at, Vector2(70, 56), 0.0, maxf(radius / FEATHERS_RADIUS, 0.5), _tint(echo))


## Sieć rozpinająca się wokół trafionego (Żądło Królowej).
static func web(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, WEB, 9, 16.0, at, Vector2(50, 40), 0.0, maxf(radius / WEB_RADIUS, 0.5))


## Leczenie: krąg, unoszące się iskry i krzyżyki (krew - Szczęka Pożeracza) albo listki (Kostur Leszego,
## Korona Odrastających Głów). `at` - stopy postaci.
static func heal(parent: Node, at: Vector2, leaf := false) -> void:
	once(parent, HEAL_LEAF if leaf else HEAL_BLOOD, 10, 14.0, at, Vector2(24, 46))


## Kości tarczy pękają i rozsypują się (Kościana Korona).
static func bone_burst(parent: Node, at: Vector2) -> void:
	once(parent, BONE_BURST, 8, 16.0, at, Vector2(32, 30))


## Krążące kości tarczy (zapętlone, środek w pozycji węzła).
static func bone_orbit() -> AnimatedSprite2D:
	return SkillEffects.looping(BONE_ORBIT, 8, 12.0, Vector2(24, 18))


## Trująca chmura wokół gracza (zapętlona, w promieniu `radius`; półprzezroczysta, żeby nie zasłaniała ziemi).
static func toxic_aura(radius: float) -> AnimatedSprite2D:
	var fx := SkillEffects.looping(TOXIC, 8, 10.0, Vector2(62, 40))
	fx.scale = Vector2.ONE * (radius / 52.0)
	fx.modulate.a = 0.8
	return fx


## Półksiężyc wiatru (zapętlony, rysowany w prawo - obracany z węzłem pocisku).
static func wind_crescent() -> AnimatedSprite2D:
	return SkillEffects.looping(WIND, 4, 16.0, Vector2(30, 22))


# ---------------------------------------------------------------- efekty bossów i umiejętności
## Piorun z nieba w trafionego z trzaskiem (Pierścień Gromu, Łuk Gromowładnego).
static func thunder(parent: Node, at: Vector2, echo := false) -> void:
	once(parent, STORM, 7, 20.0, at, Vector2(25, 141), 0.0, 1.0, _tint(echo))
	SpellSkills.zap_flash(parent, at)


## Błyskawica przeskakująca między punktami (łańcuch piorunów, ślad Lotki Burzy).
static func chain(parent: Node, from: Vector2, to: Vector2) -> void:
	SpellSkills.lightning(parent, from, to)


## Wir wody pod trafionym (Pierścień Topieli): zapętlony, znika po `life` s.
static func whirlpool(parent: Node, at: Vector2, radius: float, life: float, echo := false) -> void:
	var fx := SkillEffects.looping(WHIRL, 8, 12.0, Vector2(68, 44))
	fx.scale = Vector2.ONE * (radius / WHIRL_RADIUS)
	fx.z_index = 1
	fx.modulate = Color(_tint(echo), 0.0)
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "modulate:a", 1.0, 0.25)
	tween.tween_interval(maxf(life - 0.6, 0.0))
	tween.tween_property(fx, "modulate:a", 0.0, 0.35)
	tween.tween_callback(fx.queue_free)


## Korzenie spod ziemi w kilku miejscach w promieniu (Obręcz Leszego); `ring` - równo na obwodzie
## (Żołądź Leszego - ciernie wokół gracza).
static func roots(parent: Node, at: Vector2, radius: float, count: int, ring := false, echo := false) -> void:
	for i in count:
		var spot := at
		if ring:
			spot += Vector2.from_angle(TAU * i / count) * radius * Vector2(1.0, 0.6)
		elif i > 0:
			spot += Vector2.from_angle(TAU * i / (count - 1) + randf()) * randf_range(radius * 0.35, radius) * Vector2(1.0, 0.6)
		once(parent, ROOTS, 10, 16.0, spot, Vector2(24, 39), 0.0, randf_range(0.6, 0.8), _tint(echo))


## Pnącza wyrastające wokół gracza (Kopyta Fauna).
static func vines(parent: Node, at: Vector2, radius: float) -> void:
	for i in 6:
		var spot := at + Vector2.from_angle(TAU * i / 6.0 + 0.3) * radius * 0.7 * Vector2(1.0, 0.6)
		once(parent, VINES, 14, 12.0, spot, Vector2(21, 26))


## Złote fale melodii z nutami wokół trafionego (Fletnia Fauna).
static func melody(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, FLUTE, 12, 16.0, at, Vector2(110, 70), 0.0, maxf(radius / FLUTE_RADIUS, 0.3))


## Tupnięcie: pęknięcia i pył w promieniu (Serce Głębin).
static func stomp(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, STOMP, 10, 12.0, at, Vector2(53, 23), 0.0, maxf(radius / STOMP_RADIUS, 0.6))


## Krąg dusz rozchodzący się wokół gracza (Całun Nekromanty, Filakteria Mortana).
static func soul_nova(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, SOULS, 12, 16.0, at, Vector2(64, 61), 0.0, maxf(radius / SOULS_RADIUS, 0.6))


## Miażdżące uderzenie w ziemię (Nagolenice Trupojada).
static func ghoul_slam(parent: Node, at: Vector2, radius: float) -> void:
	once(parent, GHOUL_SLAM, 11, 16.0, at, Vector2(62, 33), 0.0, maxf(radius / GHOUL_SLAM_RADIUS, 0.6))


## Rozprysk krwi na zranionym (Szpony Gnilca).
static func wound(parent: Node, at: Vector2, size := 1.0) -> void:
	once(parent, WOUND, 9, 15.0, at, Vector2(9, 12), 0.0, size)


## Zielony opar trucizny nad zatrutym wrogiem (zapętlony).
static func venom_fumes() -> AnimatedSprite2D:
	return SkillEffects.looping(VENOM, 6, 14.0, Vector2(8, 17))


## Trąba powietrzna (zapętlona; dół trąby w pozycji węzła).
static func tornado() -> AnimatedSprite2D:
	return SkillEffects.looping(TORNADO, 8, 14.0, Vector2(23, 64))


## Płonąca kula ognia (zapętlona; środek w pozycji węzła).
static func fireball() -> AnimatedSprite2D:
	return SkillEffects.looping(FIREBALL, 8, 16.0, Vector2(18, 18))


## Płomień wystrzelony z kuli ognia w cel: płonąca smuga i mały wybuch ognia.
static func fire_shot(parent: Node, from: Vector2, to: Vector2) -> void:
	var path := to - from
	once(parent, FIRE_TRAIL, 4, 20.0, to, Vector2(36, 8), path.angle(), 1.0, Color.WHITE,
			maxf(path.length(), 8.0) / FIRE_TRAIL_LENGTH)
	once(parent, FIRE_BLAST, 11, 22.0, to, Vector2(42, 33), 0.0, 0.3)


## Błysk przebicia na wrogu (Rogi Króla).
static func impact(parent: Node, at: Vector2, angle: float) -> void:
	once(parent, IMPACT, 5, 18.0, at, Vector2(14, 11), angle)


## Plusk przy przyciągniętym językiem wrogu (Płetwy Bulgora).
static func splash(parent: Node, at: Vector2) -> void:
	once(parent, SPLASH, 12, 14.0, at, Vector2(46, 35), 0.0, 0.4)
