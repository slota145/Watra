class_name SeekerArrow
extends Node2D
## Strzała tropiąca: leci ze stałą prędkością i zachowuje pęd - nie hamuje i nie zawraca
## w miejscu, tylko skręca łagodnie (nawraca po łuku) w stronę celu. Przebija wrogów na wylot;
## po trafieniu wybiera kolejny cel - innego wroga niż ostatnio trafiony, jeśli jest w pobliżu,
## a gdy wróg jest tylko jeden, nawraca do niego. Znika po ustalonej liczbie trafień.
## Łuk Swaroga (split): przy pierwszym trafieniu strzała rozszczepia się na kolejne strzały tropiące.

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
## Na ile nowych strzał rozszczepi się przy pierwszym trafieniu (0 - wcale).
var split := 0

var _target: Goblin
var _last_hit: Goblin
var _since_hit := 0.0
var _life := LIFETIME
var _sprite: Sprite2D
var _trail: AnimatedSprite2D
var _done := false
## Wiek strzały liczony w _process - zapas na wypadek, gdyby lot (w _physics_process) stanął i strzała zostałaby na ziemi.
var _age := 0.0



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
	# złoto-zielona smuga z migoczącymi drobinkami (BowSkills, kreator efektów PixelLab), skręca razem ze strzałą
	_trail = BowSkills.arrow_trail(BowSkills.SEEKER_TRAIL_FX, velocity)
	add_child(_trail)
	_target = _find_target(_last_hit)


func _process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME + 1.0:
		queue_free()


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
	_trail.rotation = velocity.angle()

	var tip := global_position + Vector2(0, -HEIGHT)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy == _last_hit and _since_hit < PASS_THROUGH:
			continue
		if enemy.hurt_center().distance_to(tip) <= enemy.hurt_radius + 4.0:
			_hit_enemy(enemy, randi_range(damage_min, damage_max), global_position - velocity.normalized() * 10.0, 40.0)
			BowSkills.arrow_hit(get_parent(), enemy.hurt_center(), velocity.angle())
			_last_hit = enemy
			_since_hit = 0.0
			hits_left -= 1
			if split > 0:
				_split(enemy)
			if hits_left <= 0:
				_finish()
				return
			_target = _find_target(enemy)
			break
	if _life <= 0.0:
		_finish()


## Rozszczepienie: nowe strzały rozchodzą się wachlarzem i nie trafiają od razu tego samego wroga.
func _split(enemy: Goblin) -> void:
	for i in split:
		var side := (i / 2 + 1) * (1 if i % 2 == 0 else -1)
		var child := SeekerArrow.new()
		child.position = position
		child.velocity = velocity.rotated(side * 0.6)
		child.hits_left = maxi(hits_left, 1)
		child.damage_min = damage_min
		child.damage_max = damage_max
		child._last_hit = enemy
		get_parent().add_child.call_deferred(child)
	split = 0
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -HEIGHT), Color(1.0, 0.8, 0.3), 1.0)


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
	if _done:
		return
	_done = true
	_age = maxf(_age, LIFETIME + 0.5)
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
