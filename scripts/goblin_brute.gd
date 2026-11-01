class_name GoblinBrute
extends Goblin
## Goblin osiłek: wielki, powolny i wytrzymały. Bierze długi zamach maczugą i wali nią w ziemię -
## rani i odrzuca wszystko w promieniu, nie tylko w zasięgu ręki. Kryje łuczników w obozie.

@export var slam_radius := 30.0


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.3
	_cooldown = attack_cooldown
	state = State.CHASE
	Sfx.play_at("hit_heavy", global_position)
	BossFx.slam(get_parent(), global_position, slam_radius)
	if _player_alive() and global_position.distance_to(_player.global_position) <= slam_radius + 6.0:
		_player.take_damage(damage, global_position)
		_player.add_shake(3.0)
