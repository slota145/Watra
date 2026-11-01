class_name BossFx
## Efekty ataków bossów Goblińskiego Lasu i Pól Zbożowych z kreatora efektów PixelLab (tools/vfx_art.py,
## wpisy w pixellab_src/vfx/ids.json): uderzenie w ziemię, pazury, szerokie cięcie pazurami, dym i ryk Biesa,
## wybuch bomby, rozprysk kwasu, fontanna ziemi Pożeracza Pól. Pył spod nóg i kolce ziemi korzystają z efektów
## umiejętności miecza (lunge_start, ground_slam). Wszystkie skalują się do promienia ataku.

const SLAM := preload("res://assets/effects/boss_slam.png")
const CLAW := preload("res://assets/effects/boss_claw.png")
const CLEAVE := preload("res://assets/effects/boss_cleave.png")
const SMOKE := preload("res://assets/effects/bies_smoke.png")
const ROAR := preload("res://assets/effects/bies_roar.png")
const BOMB := preload("res://assets/effects/bomb_blast.png")
const ACID := preload("res://assets/effects/acid_splash.png")
const BURROW := preload("res://assets/effects/worm_burrow.png")
const DUST := preload("res://assets/effects/lunge_start.png")
const SPIKES := preload("res://assets/effects/ground_slam.png")


## Uderzenie w ziemię: pierścień, pył i odłamki skał (promień pierścienia w klatce około 34 px).
static func slam(parent: Node, at: Vector2, radius: float) -> void:
	SkillEffects.sheet_once(parent, SLAM, 12, 16.0, at, Vector2(37, 25), 0.0, 1.0, maxf(radius / 34.0, 0.6))


## Trzy krwawe pazury (side < 0 - odbite w drugą stronę).
static func claw(parent: Node, at: Vector2, side: float, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, CLAW, 8, 16.0, at, Vector2(22, 15), 0.0, 1.0, size, 0.0, side < 0.0)


## Szerokie cięcie pazurami w stożku skierowanym pod kątem `angle` (promień łuku w klatce około 34 px).
static func cleave(parent: Node, origin: Vector2, angle: float, radius: float) -> void:
	SkillEffects.sheet_once(parent, CLEAVE, 8, 18.0, origin, Vector2(-13, 33), angle, 1.0, maxf(radius / 34.0, 0.6))


## Pył spod nóg (start szarży, lądowanie).
static func dust(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, DUST, 7, 14.0, at, Vector2(21, 12), 0.0, 1.0, size)


## Cienisty dym Biesa z żarem oczu (znikanie, pojawianie się, śmierć).
static func smoke(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, SMOKE, 12, 16.0, at, Vector2(35, 40), 0.0, 1.0, size)


## Ryk Biesa: fala cienia z mackami (promień fali w klatce około 64 px).
static func roar(parent: Node, at: Vector2, radius: float) -> void:
	SkillEffects.sheet_once(parent, ROAR, 10, 16.0, at, Vector2(73, 42), 0.0, 1.0, maxf(radius / 64.0, 0.5))


## Wybuch prochu: poszarpany rozbłysk, iskry, ogień i dym (promień ognia w klatce około 16 px).
static func bomb(parent: Node, at: Vector2, radius: float) -> void:
	SkillEffects.sheet_once(parent, BOMB, 12, 16.0, at, Vector2(34, 22), 0.0, 1.0, clampf(radius / 16.0, 0.8, 4.0))


## Rozprysk kwasu: korona kropel i kręgi na kałuży (promień w klatce około 18 px).
static func acid(parent: Node, at: Vector2, radius: float) -> void:
	SkillEffects.sheet_once(parent, ACID, 10, 14.0, at, Vector2(23, 19), 0.0, 1.0, clampf(radius / 18.0, 0.8, 3.0))


## Fontanna ziemi: robak zakopuje się albo wynurza.
static func burrow(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, BURROW, 12, 16.0, at, Vector2(48, 49), 0.0, 1.0, size)


## Kamienne kolce wystrzeliwujące z ziemi (efekt Rozłupania Ziemi).
static func spikes(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, SPIKES, 10, 15.0, at, Vector2(26, 35), 0.0, 1.0, size)
