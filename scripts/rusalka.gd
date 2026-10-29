class_name Rusalka
extends Goblin
## Topielica (rusałka) z Topielczego Uroczyska: blada dziewczyna w postrzępionej sukni,
## z zielonymi włosami i wiankiem. Unosi się nad ziemią i śpiewa - gracz w zasięgu pieśni
## zwalnia (sinieje). Trzyma dystans i ciska kulami wody. Zostawia wodorosty i perły.

@export var song_radius := 130.0
@export var song_slow := 0.65
@export var orb_damage := 22
@export_range(0.0, 1.0) var pearl_drop_chance := 0.15

const RUSALKA_COLOR := Color(0.75, 0.95, 0.9)

var _notes: CPUParticles2D
var _song_timer := 0.0


func _ready() -> void:
	super()
	equipment_drop_chance = 0.08
	hurt_radius = 8.0
	map_color = RUSALKA_COLOR
	quest_kind = "rusalka"
	_notes = CPUParticles2D.new()
	_notes.position = Vector2(0, -26)
	_notes.amount = 6
	_notes.lifetime = 1.4
	_notes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_notes.emission_sphere_radius = 6.0
	_notes.direction = Vector2.UP
	_notes.spread = 60.0
	_notes.gravity = Vector2(0, -10)
	_notes.initial_velocity_min = 6.0
	_notes.initial_velocity_max = 14.0
	_notes.scale_amount_min = 1.5
	_notes.scale_amount_max = 2.5
	_notes.color = Color(0.7, 1.0, 0.95, 0.8)
	_notes.emitting = false
	add_child(_notes)


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func _physics_process(delta: float) -> void:
	super(delta)
	if state == State.DEAD:
		_notes.emitting = false
		return
	# pieśń: w walce spowalnia gracza w zasięgu
	var singing := (state == State.CHASE or state == State.ATTACK) and _player_alive() and not is_stunned()
	_notes.emitting = singing
	if singing and global_position.distance_to(_player.global_position) < song_radius:
		_player.apply_slow(song_slow, 0.25)
		_song_timer -= delta
		if _song_timer <= 0.0:
			_song_timer = 6.0
			Sfx.play_at("rusalka_song", global_position)


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.3
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive():
		var orb := EnemySpit.new()
		orb.style = "water"
		orb.position = global_position + Vector2(0, -18)
		orb.direction = (_player.body_center() - orb.position).normalized()
		orb.damage = orb_damage
		get_parent().add_child(orb)
		Sfx.play_at("spit", global_position, -2.0)


func _die() -> void:
	super()
	Sfx.play_at("rusalka_death", global_position)


func _drop_loot() -> void:
	super()
	_spawn_pickup("drowned_algae", randi_range(1, 2))
	if randf() < pearl_drop_chance:
		_spawn_pickup("drowned_pearl", 1)
