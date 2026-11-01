class_name Drowner
extends Goblin
## Utopiec z Topielczego Uroczyska. Czai się pod wodą sadzawki - widać tylko czubek głowy,
## świecące oczy i kręgi na wodzie; nie da się go wtedy trafić. Gdy gracz podejdzie,
## wynurza się z pluskiem (razem z resztą sadzawki) i rusza do ataku. Jego cios ciągnie
## gracza ku sobie - w stronę wody. Gdy gracz ucieknie, wraca do sadzawki i znów się zanurza.
## Zostawia wodorosty, rzadko perłę topieli.

@export var lurk := true
@export var emerge_radius := 70.0
@export var pull := 200.0
@export_range(0.0, 1.0) var algae_drop_chance := 0.5
@export_range(0.0, 1.0) var pearl_drop_chance := 0.08

const DROWNED_COLOR := Color(0.55, 0.85, 0.5)
const EMERGE_TIME := 0.5
## Ile sekund spokoju w domu, zanim znów się zanurzy.
const SUBMERGE_AFTER := 4.0

var submerged := false
var _emerging := 0.0
var _calm := 0.0


func _ready() -> void:
	super()
	equipment_drop_chance = 0.07
	hurt_radius = 8.0
	map_color = DROWNED_COLOR
	quest_kind = "drowner"
	if lurk:
		_submerge()


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


## Zanurzony: nietykalny i niewidoczny poza oczami i kręgami na wodzie.
func _submerge() -> void:
	submerged = true
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	$Shadow.visible = false
	sprite.frame = 4
	state = State.IDLE


func emerge() -> void:
	if not submerged or state == State.DEAD:
		return
	submerged = false
	_emerging = EMERGE_TIME
	add_to_group("enemies")
	$CollisionShape2D.set_deferred("disabled", false)
	$Shadow.visible = true
	Sfx.play_at("drowner_emerge", global_position)
	MonsterFx.splash(get_parent(), global_position)


## Wezwany przez Wodnika z kałuży - od razu się wynurza i rusza do ataku.
func emerge_now() -> void:
	submerged = true
	emerge()


## Zauważony gracz (albo alarm od sąsiada) - utopiec się wynurza.
func aggro() -> void:
	if submerged:
		emerge()
		return
	super()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if submerged:
		_anim_time += delta * 2.0
		sprite.frame = 4
		sprite.position.y = sin(_anim_time) * 0.6
		if _player_alive() and not _player_is_safe() and global_position.distance_to(_player.global_position) < emerge_radius:
			aggro()
			# cała sadzawka wychodzi razem z nim
			for other: Node in get_tree().get_nodes_in_group("drowners"):
				if other != self and other.global_position.distance_to(global_position) < alert_radius:
					other.aggro()
		return
	if _emerging > 0.0:
		_emerging -= delta
		sprite.frame = 5
		sprite.position.y = 0.0
		velocity = Vector2.ZERO
		if _emerging <= 0.0:
			state = State.IDLE
			super.aggro()
		return
	super(delta)
	# wrócił do sadzawki i jest spokój - znów się zanurza
	if lurk and state == State.IDLE and position.distance_to(home) < 4.0:
		_calm += delta
		if _calm > SUBMERGE_AFTER:
			_calm = 0.0
			_submerge()
	else:
		_calm = 0.0


func _process_attack(delta: float) -> void:
	var before := _attack_timer
	super(delta)
	# w chwili ciosu: jeśli trafił, ciągnie gracza ku sobie
	if before > 0.0 and _attack_timer <= 0.0 and _player_alive() \
			and global_position.distance_to(_player.global_position) <= attack_range + 6.0:
		_player._knockback = (global_position - _player.global_position).normalized() * pull
		Sfx.play_at("drowner_groan", global_position)


func _enter_tree() -> void:
	add_to_group("drowners")


func _die() -> void:
	super()
	Sfx.play_at("drowner_groan", global_position, 2.0)


func _drop_loot() -> void:
	super()
	if randf() < algae_drop_chance:
		_spawn_pickup("drowned_algae", randi_range(1, 2))
	if randf() < pearl_drop_chance:
		_spawn_pickup("drowned_pearl", 1)
