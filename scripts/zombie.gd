class_name Zombie
extends Goblin
## Zombie z cmentarnego trupowiska: powolny i wytrzymały, a kto da się złapać, ten grzęźnie w jego uścisku
## (trafienie spowalnia). Zombie i trupojady ściągają się nawzajem na hałas walki z daleka.

const ZOMBIE_COLOR := Color(0.55, 0.7, 0.6)

@export var grab_slow := 0.55


func _ready() -> void:
	super()
	hurt_radius = 8.0
	heart_drop_chance = 0.0
	equipment_drop_chance = 0.05
	map_color = ZOMBIE_COLOR
	quest_kind = "ghoul"
	fearless = true
	alert_radius = 110.0


func _process_attack(delta: float) -> void:
	var before: int = _player.health if _player_alive() else 0
	super(delta)
	if _attack_timer <= 0.0 and _player_alive() and _player.health < before:
		_player.apply_slow(grab_slow, 1.5)


func _drop_loot() -> void:
	super()
	if randf() < 0.25:
		_spawn_pickup("ghoul_claw", 1)
