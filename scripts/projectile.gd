class_name Projectile
extends Node2D
## Pocisk (strzała, magiczny pocisk, kula ognia) lecący w linii prostej w kierunku kursora.
## Kula ognia (explosion_radius > 0) wybucha przy pierwszym trafieniu albo na przeszkodzie
## i rani wszystkich wrogów w promieniu wybuchu - z błyskiem, ogniem rozchodzącym się
## na wszystkie strony, iskrami, dymem i wstrząsem kamery w pobliżu gracza.
## Pozycja węzła to punkt na ziemi pod pociskiem (dla sortowania i cienia),
## sam obrazek leci nieco wyżej. Zatrzymują go drzewa, budynki i palisada.

const HEIGHT := 9.0
const HIT_MARGIN := 3.0
const EXPLOSION := preload("res://assets/projectiles/explosion.png")

var direction := Vector2.RIGHT
var speed := 300.0
var max_range := 300.0
## Ilu wrogów pocisk przebija, zanim zniknie (0 = trafia tylko pierwszego).
var pierce := 0
var damage_min := 1
var damage_max := 1
var knockback := 60.0
var magic := false
var fire := false
var texture: Texture2D
## Wybuch obszarowy (0 = brak).
var explosion_radius := 0.0
## Wielkość obrazka pocisku (naładowana kula ognia jest większa).
var size := 1.0
var explosion_min := 0
var explosion_max := 0
## Księga Gryfiego Płomienia: zamiast wybuchnąć, kula zawisa jako wieżyczka strzelająca płomieniami
## (obrażenia jednego płomienia; 0 = zwykły wybuch).
var turret_damage := 0

## Trafienie wroga (bez wybuchu) - np. combo Grotu Swaroga dokłada wtedy wybuch ognia (BowSkills).
signal enemy_hit(enemy: Goblin)

static var _flash_cache: ImageTexture

var _travelled := 0.0
var _hit: Dictionary[Node, bool] = {}
var _done := false

@onready var sprite: Sprite2D = $Sprite



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	sprite.texture = texture
	sprite.position.y = -HEIGHT
	sprite.scale = Vector2.ONE * size
	if magic or fire:
		add_child(_make_trail())
	else:
		sprite.rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step := direction * speed * delta
	# przeszkody (warstwa świata)
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit["position"]
		_finish()
		return
	global_position += step
	_travelled += step.length()

	var flying_at := global_position + Vector2(0, -HEIGHT)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if _hit.has(enemy):
			continue
		if flying_at.distance_to(enemy.hurt_center()) <= enemy.hurt_radius + HIT_MARGIN:
			if explosion_radius > 0.0:
				_explode()
				return
			_hit[enemy] = true
			_hit_enemy(enemy, randi_range(damage_min, damage_max), global_position - direction * 10.0, knockback)
			enemy_hit.emit(enemy)
			if _hit.size() > pierce:
				_impact()
				return

	if _travelled >= max_range:
		if explosion_radius > 0.0:
			_explode()
			return
		_done = true
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_callback(queue_free)


## Kula zawisa w miejscu jako wieżyczka ognia; jej wybuch odpala się na końcu (kopia tej kuli bez wieżyczki).
func _become_turret() -> void:
	_done = true
	var turret := LegendFx.FireTurret.new()
	turret.shot_damage = turret_damage
	var blast: Projectile = load("res://scenes/projectile.tscn").instantiate()
	blast.texture = texture
	blast.fire = true
	blast.explosion_radius = explosion_radius
	blast.explosion_min = explosion_min
	blast.explosion_max = explosion_max
	turret.explosion = blast
	get_parent().add_child(turret)
	turret.global_position = global_position
	queue_free()


## Koniec lotu na przeszkodzie.
func _finish() -> void:
	if explosion_radius > 0.0:
		_explode()
	else:
		_impact()


func _explode() -> void:
	if turret_damage > 0:
		_become_turret()
		return
	# im większy wybuch, tym głośniej i mocniej trzęsie
	var power := clampf(explosion_radius / 40.0, 0.6, 2.0)
	Sfx.play_at("explosion", global_position, (power - 1.0) * 4.0)
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null and player.global_position.distance_to(global_position) < 260.0:
		player.add_shake(2.0 + 3.0 * power)
	_done = true
	sprite.visible = false
	for trail: CPUParticles2D in find_children("", "CPUParticles2D", false, false):
		trail.emitting = false
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) <= explosion_radius + enemy.hurt_radius:
			_hit_enemy(enemy, randi_range(explosion_min, explosion_max), global_position, knockback * 2.0)

	var ring := Sprite2D.new()
	ring.texture = EXPLOSION
	ring.position = Vector2(0, -HEIGHT * 0.5)
	ring.scale = Vector2.ONE * 0.2
	ring.z_index = 2
	add_child(ring)
	var target_scale := explosion_radius / 32.0
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector2(target_scale, target_scale * 0.8), 0.18).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3).set_delay(0.1)

	# błysk
	var flash := Sprite2D.new()
	flash.texture = _flash_texture()
	flash.position = ring.position
	flash.scale = Vector2.ONE * (explosion_radius / 24.0)
	flash.z_index = 3
	add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)

	# ogień rozchodzący się dookoła (bez grawitacji - domyślna ściągała go w dół ekranu)
	var fire_burst := _burst(int(28 * power), 0.55, explosion_radius * 0.6, explosion_radius * 3.0, 2.0, 4.0)
	fire_burst.damping_min = explosion_radius * 2.0
	fire_burst.damping_max = explosion_radius * 3.0
	fire_burst.color_ramp = _ramp([Color(1, 0.95, 0.6), Color(1, 0.5, 0.1, 0.9), Color(0.5, 0.15, 0.05, 0.0)])
	# iskry - szybkie i drobne, lekko opadają
	var sparks := _burst(int(18 * power), 0.7, explosion_radius * 2.0, explosion_radius * 4.5, 1.0, 1.5)
	sparks.gravity = Vector2(0, 90)
	sparks.damping_min = 40.0
	sparks.damping_max = 80.0
	sparks.color_ramp = _ramp([Color(1, 1, 0.7), Color(1, 0.7, 0.2), Color(1, 0.4, 0.1, 0.0)])
	# dym unoszący się powoli w górę
	var smoke := _burst(int(14 * power), 1.3, 10.0, explosion_radius * 1.2, 3.0, 6.0)
	smoke.explosiveness = 0.85
	smoke.gravity = Vector2(0, -25)
	smoke.damping_min = 20.0
	smoke.damping_max = 40.0
	smoke.color_ramp = _ramp([Color(0.35, 0.3, 0.28, 0.0), Color(0.3, 0.27, 0.25, 0.55), Color(0.25, 0.25, 0.25, 0.0)])
	smoke.finished.connect(queue_free)


## Rozbłysk cząsteczek we wszystkich kierunkach.
func _burst(amount: int, lifetime: float, speed_min: float, speed_max: float, size_min: float, size_max: float) -> CPUParticles2D:
	var burst := CPUParticles2D.new()
	burst.position = Vector2(0, -HEIGHT * 0.5)
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = maxi(amount, 4)
	burst.lifetime = lifetime
	burst.direction = Vector2.RIGHT
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = speed_min
	burst.initial_velocity_max = speed_max
	burst.scale_amount_min = size_min
	burst.scale_amount_max = size_max
	burst.z_index = 2
	burst.emitting = true
	add_child(burst)
	return burst


func _ramp(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	return gradient


## Miękka, okrągła poświata błysku (rysowana raz i współdzielona przez wszystkie wybuchy).
static func _flash_texture() -> ImageTexture:
	if _flash_cache != null:
		return _flash_cache
	var image := Image.create(48, 40, false, Image.FORMAT_RGBA8)
	for y in 40:
		for x in 48:
			var d := Vector2((x + 0.5 - 24.0) / 24.0, (y + 0.5 - 20.0) / 20.0).length()
			var a := clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, lerpf(0.45, 0.95, a), lerpf(0.1, 0.6, a), a * a))
	_flash_cache = ImageTexture.create_from_image(image)
	return _flash_cache


func _impact() -> void:
	_done = true
	sprite.visible = false
	var burst := CPUParticles2D.new()
	burst.position = Vector2(0, -HEIGHT)
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 10 if magic else 5
	burst.lifetime = 0.35
	burst.spread = 180.0
	burst.initial_velocity_min = 20.0
	burst.initial_velocity_max = 50.0
	burst.gravity = Vector2.ZERO if magic else Vector2(0, 120)
	burst.color = Color(0.6, 0.5, 1.0) if magic else Color(0.75, 0.6, 0.4)
	burst.emitting = true
	add_child(burst)
	burst.finished.connect(queue_free)


func _make_trail() -> CPUParticles2D:
	var trail := CPUParticles2D.new()
	trail.position = Vector2(0, -HEIGHT)
	trail.amount = 16
	trail.lifetime = 0.3
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_min = 2.0
	trail.initial_velocity_max = 8.0
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 2.0
	var fade := Gradient.new()
	if fire:
		fade.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 0.9), Color(0.9, 0.25, 0.1, 0.0)])
	else:
		fade.colors = PackedColorArray([Color(0.75, 0.85, 1.0, 0.9), Color(0.45, 0.3, 1.0, 0.0)])
	trail.color_ramp = fade
	return trail


## Trafienie przez gracza (efekty legendarnych pierścieni); bez gracza - zwykłe obrażenia.
func _hit_enemy(enemy: Goblin, amount: int, from_position: Vector2, push: float) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hit_enemy(enemy, amount, from_position, push)
	else:
		enemy.take_damage(amount, from_position, push)
