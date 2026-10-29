class_name Spider
extends Goblin
## Pająki z leża na północnym zachodzie Prastarego Lasu. Odmiany:
## - biter: szybki, jego ukąszenie zatruwa (obrażenia w czasie),
## - spitter (sieciarz): trzyma dystans i pluje kłębkami sieci, które spowalniają,
## - spiderling: mały pajęczak z kokonów i jaj - słaby, ale przychodzi chmarą.
## Zostawiają pajęczy jedwab i gruczoły jadowe.

@export_enum("biter", "spitter", "spiderling") var kind := "biter"
@export var poison_dps := 8.0
@export var web_damage := 12
@export_range(0.0, 1.0) var silk_drop_chance := 0.45
@export_range(0.0, 1.0) var venom_drop_chance := 0.15

const SPIDER_COLOR := Color(0.65, 0.3, 0.75)
## Grafika pająka (widok z góry) ma głowę u dołu - obracamy ją wokół środka ciała,
## żeby pająk zawsze patrzył tam, dokąd idzie, a w walce - na gracza.
const TURN_SPEED := 10.0


func _ready() -> void:
	super()
	equipment_drop_chance = 0.0 if kind == "spiderling" else 0.06
	loot_level = 3
	hurt_radius = 4.0 if kind == "spiderling" else 7.0
	map_color = SPIDER_COLOR
	quest_kind = "spider"
	sprite.position.y = sprite.offset.y
	sprite.offset.y = 0.0
	sprite.rotation = randf() * TAU


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -6 if kind == "spiderling" else -16)


func aggro() -> void:
	var was_calm := state != State.CHASE and state != State.ATTACK
	super()
	if was_calm and state == State.CHASE and randf() < 0.35:
		Sfx.play_at("spider_hiss", global_position)


func _process_attack(delta: float) -> void:
	if kind != "spitter":
		var before := _attack_timer
		super(delta)
		# ukąszenie: jeśli trafiło - trucizna
		if before > 0.0 and _attack_timer <= 0.0 and _player_alive() \
				and global_position.distance_to(_player.global_position) <= attack_range + 6.0:
			_player.apply_poison(poison_dps, 3.0)
		return
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.25
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive():
		var ball := EnemySpit.new()
		ball.style = "web"
		ball.position = global_position + Vector2(0, -8)
		ball.direction = (_player.body_center() - ball.position).normalized()
		ball.damage = web_damage
		ball.slow = 0.5
		get_parent().add_child(ball)
		Sfx.play_at("spit", global_position, -4.0)


func _animate(delta: float) -> void:
	super(delta)
	sprite.flip_h = false
	var facing := Vector2.ZERO
	if (state == State.CHASE or state == State.ATTACK) and _player != null:
		facing = _player.global_position - global_position
	elif velocity.length() > 8.0:
		facing = velocity
	if facing.length() > 1.0:
		# głowa grafiki jest skierowana w dół (kąt PI/2)
		sprite.rotation = lerp_angle(sprite.rotation, facing.angle() - PI / 2.0, minf(delta * TURN_SPEED, 1.0))


func _die() -> void:
	super()
	Sfx.play_at("spider_death", global_position, -4.0 if kind == "spiderling" else 0.0)


func _drop_loot() -> void:
	super()
	if randf() < silk_drop_chance:
		_spawn_pickup("spider_silk", 1)
	if randf() < venom_drop_chance:
		_spawn_pickup("spider_venom", 1)
