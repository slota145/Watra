class_name KoboldBomber
extends Kobold
## Kobold saper: z torby pełnej bomb rzuca je łukiem tam, gdzie gracz właśnie stoi - miejsce upadku
## świeci czerwonym kołem, więc wystarczy z niego zejść. Trzyma dystans od gracza.

@export var bomb_damage := 22
@export var bomb_radius := 26.0


func _process_chase() -> void:
	super()
	if state == State.CHASE and _player_alive() and global_position.distance_to(_player.global_position) < attack_range * 0.5:
		velocity = (global_position - _player.global_position).normalized() * speed + _separation() * speed


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.3
	_cooldown = attack_cooldown
	state = State.CHASE
	if not _player_alive():
		return
	var bomb := KoboldBomb.new()
	bomb.position = global_position + Vector2(0, -hurt_height)
	# celuje trochę przed gracza, w stronę, w którą biegnie
	bomb.target = _player.global_position + _player.velocity * 0.35
	bomb.damage = bomb_damage
	bomb.radius = bomb_radius
	bomb.flight = 0.9
	get_parent().add_child(bomb)
	Sfx.play_at("swing", global_position, -6.0)
