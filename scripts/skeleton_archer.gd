class_name SkeletonArcher
extends Skeleton
## Szkielet łucznik: trzyma się z tyłu i strzela z próchniejącego łuku (strzały lecą prosto).

@export var arrow_damage := 16


func _process_chase() -> void:
	super()
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
	var arrow := EnemySpit.new()
	arrow.style = "arrow"
	arrow.position = global_position + Vector2(0, -hurt_height)
	arrow.direction = (_player.body_center() - arrow.position).normalized()
	arrow.damage = arrow_damage
	get_parent().add_child(arrow)
	Sfx.play_at("bow", global_position, -6.0)
