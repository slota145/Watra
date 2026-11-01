class_name MonsterFx
## Efekty zwykłych potworów z kreatora efektów PixelLab (tools/vfx_art.py, wpisy "mob_*" w pixellab_src/vfx/ids.json):
## obłoczek przy śmierci (barwiony kolorem potwora), rozsypane kości szkieletu, pociski plucia i kuli wody,
## rozpryski trafień, pył kopca robaka, nuty rusałki, wybuch ognika, drzazgi drzewca i plusk utopca.
## Część korzysta z gotowych efektów bossów i umiejętności (piorun, uderzenie w ziemię, kwas, smuga strzały).
## Obłoczek widać przy setkach potworów, więc to jeden krótki Sprite2D bez cząsteczek.

const POOF := preload("res://assets/effects/mob_poof.png")
const BONES := preload("res://assets/effects/mob_bones.png")
const SPIT := preload("res://assets/effects/mob_spit.png")
const WATER_ORB := preload("res://assets/effects/mob_water_orb.png")
const DUST := preload("res://assets/effects/mob_dust.png")
const NOTES := preload("res://assets/effects/mob_notes.png")
const WISP_BURST := preload("res://assets/effects/mob_wisp_burst.png")
const SPLINTERS := preload("res://assets/effects/mob_splinters.png")
const SPLASH := preload("res://assets/effects/mob_splash.png")
const ARROW_TRAIL := preload("res://assets/effects/bow_arrow_trail.png")
const ARROW_HIT := preload("res://assets/effects/bow_arrow_hit.png")
const ZAP := preload("res://assets/effects/spell_zap.png")
const STORM := preload("res://assets/effects/storm_strike.png")

## Domyślny kolor potwora na minimapie (czerwony) - obłoczek goblina zostaje wtedy zielonkawy jak dawniej.
const DEFAULT_MAP_COLOR := Color(0.95, 0.25, 0.2)
const GOBLIN_TINT := Color(0.62, 0.82, 0.48)


## Obłoczek dymu przy śmierci potwora, zabarwiony jego kolorem (`map_color`), losowo odbity.
static func poof(parent: Node, at: Vector2, color: Color) -> void:
	var tint := GOBLIN_TINT if color.is_equal_approx(DEFAULT_MAP_COLOR) else Color.WHITE.lerp(color, 0.5)
	_once(parent, POOF, 7, 16.0, at, Vector2(20, 24), tint, randf() < 0.5)


## Rozsypujące się kości szkieletu.
static func bones(parent: Node, at: Vector2) -> void:
	_once(parent, BONES, 10, 16.0, at, Vector2(22, 11), Color.WHITE, randf() < 0.5)


## Plusk wody (utopiec wynurza się, kula wody rozbija się).
static func splash(parent: Node, at: Vector2) -> void:
	_once(parent, SPLASH, 8, 16.0, at, Vector2(24, 14), Color.WHITE, randf() < 0.5)


## Wybuch błędnego ognika (promień w klatce około 28 px).
static func wisp_burst(parent: Node, at: Vector2) -> void:
	_once(parent, WISP_BURST, 10, 16.0, at, Vector2(36, 34), Color.WHITE, randf() < 0.5)


## Drzazgi i liście (drzewiec wyrasta z ziemi albo pada).
static func splinters(parent: Node, at: Vector2) -> void:
	_once(parent, SPLINTERS, 9, 16.0, at, Vector2(20, 15), Color.WHITE, randf() < 0.5)


## Drobne trafienie pociskiem (strzała, kamień, oszczep, nuta, sieć).
static func hit(parent: Node, at: Vector2) -> void:
	SkillEffects.sheet_once(parent, ARROW_HIT, 5, 18.0, at, Vector2(16, 14), randf() * TAU)


## Iskry wyładowania (naelektryzowane pióro).
static func zap(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, ZAP, 5, 20.0, at, Vector2(22, 22), 0.0, 1.0, size)


## Piorun z nieba w punkt (szaman ptakoludzi).
static func sky_bolt(parent: Node, at: Vector2) -> void:
	SkillEffects.sheet_once(parent, STORM, 7, 20.0, at, Vector2(25, 141), 0.0, 1.0, 1.0, 0.0, randf() < 0.5)
	zap(parent, at)


## Zapętlony lot pocisku (plucie jadem albo kula wody), grot w punkcie węzła; obraca go wywołujący.
static func orb(water: bool) -> AnimatedSprite2D:
	return SkillEffects.looping(WATER_ORB if water else SPIT, 4, 14.0, Vector2(20, 8))


## Zapętlona smuga za pociskiem (grot w punkcie węzła).
static func trail() -> AnimatedSprite2D:
	return SkillEffects.looping(ARROW_TRAIL, 4, 16.0, Vector2(36, 8))


## Zapętlony pył i grudy ziemi nad kopcem robaka.
static func dust() -> AnimatedSprite2D:
	return SkillEffects.looping(DUST, 6, 12.0, Vector2(20, 18))


## Zapętlone nuty wznoszące się nad śpiewającą rusałką.
static func notes() -> AnimatedSprite2D:
	return SkillEffects.looping(NOTES, 12, 10.0, Vector2(20, 30))


## Jednorazowy efekt z arkusza jak SkillEffects.sheet_once, ale z kolorem (modulate) - do obłoczków potworów.
static func _once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		tint: Color, mirror: bool) -> void:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = 25
	fx.modulate = tint
	if mirror:
		fx.scale.x = -1.0
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)
