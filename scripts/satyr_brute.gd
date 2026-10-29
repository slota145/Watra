class_name SatyrBrute
extends Satyr
## Satyr osiłek z wioski satyrów w Wietrznych Turniach: wielki, kudłaty, z ogromnymi rogami.
## Z daleka pochyla łeb i szarżuje prosto przed siebie - trafiony gracz zostaje odrzucony.
## Szarżę widać zawczasu (zamach), więc da się przed nią uskoczyć.

@export var charge_speed := 250.0
@export var charge_time := 0.45

var _charging := 0.0
var _charge_dir := Vector2.ZERO
var _charge_hit := false


func _process_chase() -> void:
	super()
	# szarżuje także z dalszej odległości (do 5 razy zasięgu ciosu)
	if state == State.CHASE and _cooldown == 0.0 and _player_alive() \
			and global_position.distance_to(_player.global_position) <= attack_range * 5.0:
		state = State.ATTACK
		_attack_timer = attack_windup
		velocity = Vector2.ZERO


func _process_attack(delta: float) -> void:
	if _charging > 0.0:
		_charging -= delta
		velocity = _charge_dir * charge_speed
		if not _charge_hit and _player_alive() and global_position.distance_to(_player.global_position) <= attack_range + 4.0:
			_charge_hit = true
			_player.take_damage(damage, global_position)
			_player.add_shake(4.0)
			Sfx.play_at("hit_heavy", global_position)
		if _charging <= 0.0:
			_cooldown = attack_cooldown
			state = State.CHASE
		return
	velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	# rusza z kopyta w stronę, w którą stał gracz w chwili końca zamachu
	_charge_dir = global_position.direction_to(_player.global_position) if _player_alive() else Vector2.RIGHT
	_charging = charge_time
	_charge_hit = false
	_strike_anim = charge_time
	Sfx.play_at("goat_bleat", global_position)
