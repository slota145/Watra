class_name KoboldSlinger
extends Kobold
## Kobold procarz: trzyma się z tyłu zgrai i ciska kamieniami z procy (lecą prosto - da się uskoczyć).

@export var stone_damage := 10


func _process_chase() -> void:
	super()
	# za blisko - odskakuje do tyłu, zamiast pchać się w zwarcie
	if state == State.CHASE and _player_alive() and global_position.distance_to(_player.global_position) < attack_range * 0.45:
		velocity = (global_position - _player.global_position).normalized() * speed + _separation() * speed


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.25
	_cooldown = attack_cooldown
	state = State.CHASE
	if not _player_alive():
		return
	var stone := EnemySpit.new()
	stone.style = "stone"
	stone.position = global_position + Vector2(0, -hurt_height)
	stone.direction = (_player.body_center() - stone.position).normalized()
	stone.damage = stone_damage
	get_parent().add_child(stone)
	Sfx.play_at("swing", global_position, -4.0)
