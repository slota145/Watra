class_name SeekerArrow
extends Node2D
## Strzała tropiąca: leci ze stałą prędkością i zachowuje pęd - nie hamuje i nie zawraca
## w miejscu, tylko skręca łagodnie (nawraca po łuku) w stronę celu. Przebija wrogów na wylot;
## po trafieniu wybiera kolejny cel - innego wroga niż ostatnio trafiony, jeśli jest w pobliżu,
## a gdy wróg jest tylko jeden, nawraca do niego. Znika po ustalonej liczbie trafień.

const TEXTURE := preload("res://assets/projectiles/arrow.png")
const SPEED := 280.0
## Jak szybko strzała skręca (rad/s); bez trafienia skręca coraz ciaśniej, żeby nie krążyć w kółko.
const TURN := 5.0
const TURN_MAX := 16.0
const SEARCH_RADIUS := 300.0
const HEIGHT := 9.0
## Przez chwilę po trafieniu strzała nie może trafić tego samego wroga (przelatuje na wylot).
const PASS_THROUGH := 0.35
const LIFETIME := 7.0

var velocity := Vector2.RIGHT * SPEED
var hits_left := 4
var damage_min := 1
var damage_max := 1

var _target: Goblin
var _last_hit: Goblin
var _since_hit := 0.0
var _life := LIFETIME
var _sprite: Sprite2D
var _done := false



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.position.y = -HEIGHT
	_sprite.modulate = Color(1.2, 1.3, 0.9)
	add_child(_sprite)
	var trail := CPUParticles2D.new()
	trail.position = Vector2(0, -HEIGHT)
	trail.amount = 24
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_max = 6.0
	trail.gravity = Vector2.ZERO
	trail.scale_amount_max = 2.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.85, 1.0, 0.5, 0.9), Color(0.4, 0.9, 0.3, 0.0)])
	trail.color_ramp = fade
	add_child(trail)
	_target = _find_target(null)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_life -= delta
	_since_hit += delta
	if not _is_alive(_target):
		_target = _find_target(_last_hit)
	if _target != null:
		var to_target := _target.hurt_center() - (global_position + Vector2(0, -HEIGHT))
		var turn := minf(TURN + _since_hit * 8.0, TURN_MAX) * delta
		var heading := velocity.angle()
		velocity = Vector2.from_angle(heading + clampf(angle_difference(heading, to_target.angle()), -turn, turn)) * SPEED
	# w lochu strzała nie przelatuje przez ściany (w świecie omija drzewa i głazy)
	if Goblin.pathing != null:
		var query := PhysicsRayQueryParameters2D.create(global_position, global_position + velocity * delta, 1)
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			_finish()
			return
	global_position += velocity * delta
	_sprite.rotation = velocity.angle()

	var tip := global_position + Vector2(0, -HEIGHT)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy == _last_hit and _since_hit < PASS_THROUGH:
			continue
		if enemy.hurt_center().distance_to(tip) <= enemy.hurt_radius + 4.0:
			_hit_enemy(enemy, randi_range(damage_min, damage_max), global_position - velocity.normalized() * 10.0, 40.0)
			SkillEffects.spark(get_parent(), tip, Color(0.85, 1.0, 0.5), 6)
			_last_hit = enemy
			_since_hit = 0.0
			hits_left -= 1
			if hits_left <= 0:
				_finish()
				return
			_target = _find_target(enemy)
			break
	if _life <= 0.0:
		_finish()


func _is_alive(enemy: Goblin) -> bool:
	return is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD and enemy.is_in_group("enemies")


## Najbliższy wróg w zasięgu - najlepiej inny niż `exclude` (ostatnio trafiony).
func _find_target(exclude: Goblin) -> Goblin:
	var best: Goblin = null
	var best_distance := SEARCH_RADIUS
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy == exclude:
			continue
		var d := enemy.global_position.distance_to(global_position)
		if d < best_distance:
			best_distance = d
			best = enemy
	if best == null and _is_alive(exclude) and exclude.global_position.distance_to(global_position) < SEARCH_RADIUS * 1.5:
		return exclude
	return best


func _finish() -> void:
	_done = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


## Trafienie przez gracza (efekty legendarnych pierścieni); bez gracza - zwykłe obrażenia.
func _hit_enemy(enemy: Goblin, amount: int, from_position: Vector2, push: float) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hit_enemy(enemy, amount, from_position, push)
	else:
		enemy.take_damage(amount, from_position, push)
