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
## Wybuch ognia z kreatora efektów PixelLab (tools/vfx_art.py) - promień kłębów w klatce FIRE_BLAST_RADIUS.
const FIRE_BLAST := preload("res://assets/effects/fire_blast.png")
const FIRE_BLAST_RADIUS := 38.0
## Animowane pociski księgi (z kreatora efektów): rodzaj -> [arkusz, klatki, fps, punkt zaczepienia, obrót w kierunku
## lotu, trafienie: arkusz, klatki, fps, punkt zaczepienia, rozmiar, skala pocisku]. "missile" - zwykły pocisk księgi (magic bez rodzaju).
const FX := {
	"missile": [preload("res://assets/effects/spell_missile.png"), 6, 16.0, Vector2(20, 11), true,
			preload("res://assets/effects/spell_hit.png"), 6, 18.0, Vector2(20, 20), 0.8, 1.0],
	"fire": [preload("res://assets/effects/fireball.png"), 8, 16.0, Vector2(18, 18), false, null, 0, 0.0, Vector2.ZERO, 0.0, 0.5],
	"ice": [preload("res://assets/effects/frost_lance.png"), 6, 16.0, Vector2(35, 8), true,
			preload("res://assets/effects/ice_shatter.png"), 8, 16.0, Vector2(27, 19), 0.6, 0.85],
}

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
## Animowany wygląd z kreatora efektów (klucz FX: "fire", "ice"); pusty - magiczny pocisk dostaje "missile",
## strzała zostaje obrazkiem.
var fx_kind := ""
var explosion_min := 0
var explosion_max := 0
## Księga Gryfiego Płomienia: zamiast wybuchnąć, kula zawisa jako wieżyczka strzelająca płomieniami
## (obrażenia jednego płomienia; 0 = zwykły wybuch).
var turret_damage := 0

## Trafienie wroga (bez wybuchu) - np. combo Grotu Swaroga dokłada wtedy wybuch ognia (BowSkills).
signal enemy_hit(enemy: Goblin)

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
	if fx_kind == "" and magic:
		fx_kind = "missile"
	if FX.has(fx_kind):
		_make_fx()
	elif not (magic or fire):
		sprite.rotation = direction.angle()
	if fire:
		# płonąca smuga (ta sama co za Grotem Swaroga) - węzeł "Trail" znika przy trafieniu
		var trail := BowSkills.arrow_trail(BowSkills.POWER_TRAIL_FX, direction)
		trail.scale = Vector2.ONE * size
		add_child(trail)


## Animowany pocisk (FxLoop) zamiast obrazka - obrócony w kierunku lotu, jeśli rodzaj tego chce.
func _make_fx() -> void:
	var data: Array = FX[fx_kind]
	var loop := FxLoop.make(data[0], data[1], data[2], data[3])
	loop.position = sprite.position
	loop.scale = sprite.scale * data[10]
	if data[4]:
		loop.rotation = direction.angle()
		loop.flip_v = absf(direction.angle()) > PI / 2.0
	sprite.visible = false
	sprite.add_sibling(loop)
	loop.name = "Fx"


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
	var trail := get_node_or_null("Trail") as CanvasItem
	if trail != null:
		trail.visible = false
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) <= explosion_radius + enemy.hurt_radius:
			_hit_enemy(enemy, randi_range(explosion_min, explosion_max), global_position, knockback * 2.0)

	var fx := get_node_or_null("Fx")
	if fx != null:
		fx.visible = false
	SkillEffects.sheet_once(get_parent(), FIRE_BLAST, 11, 16.0, global_position + Vector2(0, -HEIGHT * 0.5), Vector2(42, 33),
			0.0, 1.0, explosion_radius / FIRE_BLAST_RADIUS)
	get_tree().create_timer(0.8, false).timeout.connect(queue_free)


func _impact() -> void:
	_done = true
	sprite.visible = false
	# zapętlona smuga strzały (BowSkills.arrow_trail) znika razem ze strzałą
	var trail := get_node_or_null("Trail") as CanvasItem
	if trail != null:
		trail.visible = false
	var fx := get_node_or_null("Fx")
	if fx != null:
		fx.visible = false
	if FX.has(fx_kind) and FX[fx_kind][5] != null:
		var data: Array = FX[fx_kind]
		SkillEffects.sheet_once(get_parent(), data[5], data[6], data[7], global_position + Vector2(0, -HEIGHT), data[8], direction.angle(),
				1.0, data[9])
		queue_free()
		return
	# koniec lotu bez własnego efektu trafienia: strzała wzbija pył, inne pociski sypią iskrami (MiscVfx)
	if magic or fire:
		MiscVfx.spark(get_parent(), global_position + Vector2(0, -HEIGHT), Color(1.0, 0.6, 0.3) if fire else Color(0.6, 0.5, 1.0), 0.6)
	else:
		MiscVfx.puff(get_parent(), global_position + Vector2(0, -HEIGHT * 0.5), Color(0.75, 0.6, 0.4), 0.3)
	queue_free()


## Trafienie przez gracza (efekty legendarnych pierścieni); bez gracza - zwykłe obrażenia.
func _hit_enemy(enemy: Goblin, amount: int, from_position: Vector2, push: float) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hit_enemy(enemy, amount, from_position, push)
	else:
		enemy.take_damage(amount, from_position, push)
