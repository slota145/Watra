class_name GoblinArcher
extends Goblin
## Goblin łucznik z obozów: trzyma się z tyłu za kompanami i strzela z krótkiego łuku.
## Strzała leci prosto (da się jej uniknąć). Słabszy w zwarciu niż zwykły goblin.

@export var arrow_damage := 10


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.25
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive():
		_shoot()


func _shoot() -> void:
	var side := -1.0 if _player.global_position.x < global_position.x else 1.0
	var arrow := EnemySpit.new()
	arrow.style = "arrow"
	arrow.position = global_position + Vector2(6.0 * side, -hurt_height)
	arrow.direction = (_player.body_center() - arrow.position).normalized()
	arrow.damage = arrow_damage
	get_parent().add_child(arrow)
	Sfx.play_at("bow", global_position, -6.0)
