class_name Kobold
extends Goblin
## Kobold z Pól Zbożowych: drobny, łuskowaty i szybki, z włócznią. Koboldy zajęły opuszczone gospodarstwa
## i kryją się w zbożu - często widać je dopiero, gdy wyskoczą z łanu. Atakują zgrają, a ranne
## (poniżej FLEE_HEALTH zdrowia) na chwilę uciekają, piszcząc, żeby po paru sekundach wrócić do walki.

const KOBOLD_COLOR := Color(0.95, 0.55, 0.25)
const FLEE_HEALTH := 0.25
const FLEE_TIME := 2.2

var _fled := false


func _ready() -> void:
	super()
	hurt_radius = 7.0
	heart_drop_chance = 0.0
	equipment_drop_chance = 0.05
	map_color = KOBOLD_COLOR
	quest_kind = "kobold"


func _drop_loot() -> void:
	super()
	if randf() < 0.25:
		_spawn_pickup("kobold_fuse", 1)


func take_damage(amount: int, from_position: Vector2, knockback := 120.0) -> void:
	super(amount, from_position, knockback)
	if state != State.DEAD and not _fled and health < max_health * FLEE_HEALTH:
		_fled = true
		fear(FLEE_TIME, from_position)
		Sfx.play_at("goat_bleat", global_position, -10.0)
