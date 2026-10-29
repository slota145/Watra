class_name SatyrPiper
extends Satyr
## Satyr grajek: gra na fletni Pana przy ognisku, a w walce trzyma się z tyłu i posyła w gracza
## zaczarowane nuty - trafiony zwalnia na chwilę (melodia plącze nogi).

@export var note_damage := 9
@export var note_slow := 0.6


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.3
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive():
		_play_note()


func _play_note() -> void:
	var side := -1.0 if _player.global_position.x < global_position.x else 1.0
	var note := EnemySpit.new()
	note.style = "note"
	note.position = global_position + Vector2(5.0 * side, -hurt_height)
	note.direction = (_player.body_center() - note.position).normalized()
	note.damage = note_damage
	note.slow = note_slow
	get_parent().add_child(note)
	Sfx.play_at("magic", global_position, -6.0)
