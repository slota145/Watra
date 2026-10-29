class_name Frogman
extends Goblin
## Żaboczłek z rozlewisk - groźniejszy od wilka. Przysiada przy ognisku w wiosce i rechocze,
## a gdy zauważy gracza, rusza z całą gromadą. Odmiany:
## - wojownik z oszczepem (walczy wręcz),
## - plujący (spitter) - trzyma dystans i pluje jadem, który leci w stronę gracza (można go uniknąć).
## Żaboludzie dobrze pływają - głęboka woda ich nie zatrzymuje.
## Zostawiają żabie języki, czasem rybę.

@export var spitter := false
@export var spit_damage := 14
@export_range(0.0, 1.0) var tongue_drop_chance := 0.45
@export_range(0.0, 1.0) var fish_drop_chance := 0.18

const FROG_COLOR := Color(0.45, 0.85, 0.35)


func _ready() -> void:
	super()
	equipment_drop_chance = 0.07
	loot_level = 2
	hurt_radius = 8.0
	map_color = FROG_COLOR
	quest_kind = "frogman"


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


## Zauważony gracz - część gromady rechocze na alarm.
func aggro() -> void:
	var was_calm := state != State.CHASE and state != State.ATTACK
	super()
	if was_calm and state == State.CHASE and randf() < 0.5:
		Sfx.play_at("frogman_croak", global_position)


func _process_attack(delta: float) -> void:
	if not spitter:
		var before := _attack_timer
		super(delta)
		if before > 0.0 and _attack_timer <= 0.0:
			Sfx.play_at("frog_attack", global_position)
		return
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.25
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive():
		_spit()


## Kula jadu leci w stronę gracza.
func _spit() -> void:
	var side := -1.0 if _player.global_position.x < global_position.x else 1.0
	var spit := EnemySpit.new()
	spit.position = global_position + Vector2(8.0 * side, -10.0)
	spit.direction = (_player.body_center() - spit.position).normalized()
	spit.damage = spit_damage
	get_parent().add_child(spit)
	Sfx.play_at("spit", global_position)


func _die() -> void:
	super()
	Sfx.play_at("frog_death", global_position)


func _drop_loot() -> void:
	super()
	if randf() < tongue_drop_chance:
		_spawn_pickup("frog_tongue", 1)
	if randf() < fish_drop_chance:
		_spawn_pickup("fish", 1)
