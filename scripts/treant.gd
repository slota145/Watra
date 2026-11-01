class_name Treant
extends Goblin
## Drzewiec z Prastarego Lasu: chodzący, omszały pień z twarzą i ramionami z gałęzi.
## Powolny, ale wytrzymały i bije ciężko. Budzą go prastare drzewa (AncientTree) i Leszy.
## Zostawia prastarą korę.

@export_range(0.0, 1.0) var bark_drop_chance := 0.5

const TREANT_COLOR := Color(0.45, 0.7, 0.35)


func _ready() -> void:
	super()
	equipment_drop_chance = 0.06
	hurt_radius = 10.0
	map_color = TREANT_COLOR
	quest_kind = "treant"


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -26)


func aggro() -> void:
	var was_calm := state != State.CHASE and state != State.ATTACK
	super()
	if was_calm and state == State.CHASE and randf() < 0.4:
		Sfx.play_at("treant_groan", global_position)


func _process_attack(delta: float) -> void:
	var before := _attack_timer
	super(delta)
	if before > 0.0 and _attack_timer <= 0.0:
		Sfx.play_at("hit_heavy", global_position, -4.0)


func _die() -> void:
	super()
	Sfx.play_at("tree_fall", global_position, -4.0)


## Pada w drzazgach i liściach zamiast obłoczka.
func _spawn_poof() -> void:
	MonsterFx.splinters(get_parent(), global_position)


func _drop_loot() -> void:
	super()
	if randf() < bark_drop_chance:
		_spawn_pickup("ancient_bark", 1)
