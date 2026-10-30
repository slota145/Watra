class_name Goblin
extends CharacterBody2D
## Goblin: siedzi przy ognisku albo stoi w grupce, a gdy zauważy gracza (lub oberwie),
## goni go i bije maczugą. Alarmuje pobliskich kompanów. Gdy gracz ucieknie
## za daleko od obozu, wraca na swoje miejsce i leczy rany.

signal died(goblin: Goblin)

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }

@export var max_health := 30
@export var speed := 55.0
@export var damage := 8
## Odległość, z której goblin zauważa gracza.
@export var aggro_radius := 85.0
## Promień, w jakim goblin alarmuje kompanów.
@export var alert_radius := 60.0
## Jak daleko od swojego miejsca goblin może odejść w pościgu.
@export var leash_radius := 260.0
@export var attack_range := 16.0
@export var attack_windup := 0.35
@export var attack_cooldown := 0.9
## Czy goblin siedzi (przy ognisku). Ustawiane przez generator obozu.
@export var sitting := false
## Musztra (plac musztry między obozami): stoi w szyku zwrócony do look_at_point i co DRILL_PERIOD robi
## zamach razem z resztą (wspólny zegar - cały szyk równo), dopóki nie zauważy gracza; potem wraca do szyku.
@export var drilling := false
const DRILL_PERIOD := 1.6
## Wysokość tułowia nad stopami (tu celują ciosy i pociski).
@export var hurt_height := 6.0

@export_group("Nagrody")
@export var xp_reward := 15
@export var gold_min := 1
@export var gold_max := 4
@export_range(0.0, 1.0) var heart_drop_chance := 0.3
## Kamienie zaklinające: szanse wynikają z poziomu potwora (Levels.stone_chances), a to jest ich mnożnik
## względem zwykłego potwora (0,1 = x1; 0 - nie wypadają wcale, np. pajączki).
@export_range(0.0, 1.0) var stone_drop_chance := 0.1
## Ekwipunek (zwykły, magiczny albo rzadki - Loot) z poziomem potwora.
@export_range(0.0, 1.0) var equipment_drop_chance := 0.04
## Poziom potwora (Levels) - ustawia świat przed dodaniem do sceny; 0 = domyślny poziom krainy.
var level := 0

## Ładowane przy użyciu, nie przez preload - unika cyklicznych zależności (Wolf dziedziczy po Goblin).
const PICKUP_PATH := "res://scenes/pickup.tscn"

## Obszar osady - gobliny nie gonią gracza, który się w nim schronił.
static var safe_zone := Rect2()
## Pozycje potworów z bieżącej klatki (wspólne dla wszystkich, do rozpychania się).
static var _positions := PackedVector2Array()
static var _positions_frame := -1
const SEPARATION_RADIUS := 12.0
const XP_COLOR := Color(0.7, 0.55, 1.0)

## Promień trafienia mieczem i środek "ciała" względem pozycji stóp.
var hurt_radius := 6.0
## Kolor kropki na mapie i minimapie.
var map_color := Color(0.95, 0.25, 0.2)
## Rodzaj potwora liczony w zadaniach ("goblin", "wolf").
var quest_kind := "goblin"
var health := max_health
var state := State.IDLE
## Miejsce, do którego goblin wraca (przy ognisku / w grupce).
var home := Vector2.ZERO
## Punkt, w stronę którego goblin patrzy, gdy siedzi (np. ognisko).
var look_at_point := Vector2.ZERO

var _player: Player
var _knockback := Vector2.ZERO
var _attack_timer := 0.0
var _cooldown := 0.0
var _strike_anim := 0.0
var _anim_time := 0.0
var _wander_timer := 0.0
var _wander_target := Vector2.ZERO
## Pozostały czas ogłuszenia i gwiazdki nad głową.
var _stun_time := 0.0
## Strach (Róg Biesa): wróg ucieka od źródła, dopóki nie minie.
var _fear_time := 0.0
var _fear_from := Vector2.ZERO
## Nieruchome "potwory" (prastare drzewa, kokony) nie uciekają w strachu.
var fearless := false
var _stun_marker: StunMarker

@onready var sprite: Sprite2D = $Sprite



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	add_to_group("enemies")
	_apply_level()
	health = max_health
	home = position
	_wander_target = position
	_anim_time = randf() * 10.0
	_wander_timer = randf_range(1.0, 4.0)
	_player = get_tree().get_first_node_in_group("player")
	if sitting:
		sprite.flip_h = look_at_point.x < position.x


## Statystyki z krzywej zwykłego potwora na poziomie tego potwora (Levels) razy siła typu względem zwykłego
## potwora jego krainy: zdrowie, obrażenia (wszystkie liczbowe właściwości "*damage" - także ataków bossów
## i pocisków), doświadczenie i złoto. Bossowie mają zdrowie w granicach Levels.BOSS_HEALTH.
func _apply_level() -> void:
	if level <= 0:
		level = Levels.zone_default
	var ref := Levels.reference_of(scene_file_path)
	var strength: float = max_health / ref[0]
	if self is Boss:
		strength = clampf(strength, Levels.BOSS_HEALTH.x, Levels.BOSS_HEALTH.y)
	max_health = maxi(1, roundi(Levels.health(level) * strength))
	for property in get_property_list():
		var key: String = property["name"]
		if key.ends_with("damage") and property["type"] == TYPE_INT and get(key) > 0:
			set(key, maxi(1, roundi(Levels.damage(level) * get(key) / ref[1])))
	xp_reward = roundi(Levels.xp(level) * xp_reward / ref[2])
	var gold: float = Levels.gold(level) / ref[3]
	gold_min = roundi(gold_min * gold)
	gold_max = maxi(gold_min, roundi(gold_max * gold))


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func take_damage(amount: int, from_position: Vector2, knockback := 120.0) -> void:
	if state == State.DEAD:
		return
	Sfx.play_at("hit_heavy" if self is Boss else "hit", global_position)
	health -= amount
	DamageNumber.spawn(get_parent(), hurt_center(), amount)
	_knockback = (global_position - from_position).normalized() * knockback
	_flash()
	if health <= 0:
		_die()
		return
	# trafienie przerywa zamach
	if state == State.ATTACK:
		state = State.CHASE
		_cooldown = 0.3
	aggro()


## Ogłuszenie: wróg stoi w miejscu (przerywa zamach), nad głową krążą gwiazdki.
## Bossowie są odporniejsi - ogłuszenie trwa u nich krócej.
func stun(seconds: float) -> void:
	if state == State.DEAD:
		return
	if self is Boss:
		seconds *= Boss.STUN_RESISTANCE
	_stun_time = maxf(_stun_time, seconds)
	_on_stunned()
	if _stun_marker == null:
		_stun_marker = StunMarker.new()
		var rect := sprite.get_rect()
		_stun_marker.position = sprite.position + Vector2(0, rect.position.y * sprite.scale.y - 3.0)
		_stun_marker.radius = clampf(rect.size.x * sprite.scale.x * 0.3, 5.0, 14.0)
		add_child(_stun_marker)


## Strach: wróg ucieka od `from` przez `seconds` (bossowie są na to odporni).
func fear(seconds: float, from: Vector2) -> void:
	if state == State.DEAD or fearless or self is Boss:
		return
	_fear_time = maxf(_fear_time, seconds)
	_fear_from = from
	_on_stunned()


func is_stunned() -> bool:
	return _stun_time > 0.0


## Wywoływane przy ogłuszeniu - przerywa rozpoczęty atak.
func _on_stunned() -> void:
	if state == State.ATTACK:
		state = State.CHASE
		_cooldown = maxf(_cooldown, 0.3)


## Ogłuszony wróg tylko odlatuje od ciosu; zwraca true, dopóki trwa ogłuszenie.
func _process_stun(delta: float) -> bool:
	if _stun_time <= 0.0 and _fear_time > 0.0:
		_fear_time -= delta
		var away := (global_position - _fear_from).normalized()
		velocity = (away if away != Vector2.ZERO else Vector2.RIGHT) * speed * 1.2 + _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		sprite.flip_h = velocity.x < 0.0
		return true
	if _stun_time <= 0.0:
		return false
	_stun_time -= delta
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	if _stun_time <= 0.0 and _stun_marker != null:
		_stun_marker.queue_free()
		_stun_marker = null
	return true


## Goblin zaczyna gonić gracza i alarmuje kompanów w pobliżu.
func aggro() -> void:
	if state == State.CHASE or state == State.ATTACK or state == State.DEAD:
		return
	if not _player_alive() or _player_is_safe():
		return
	state = State.CHASE
	sitting = false
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other != self and other.global_position.distance_to(global_position) < alert_radius:
			other.aggro()


func _physics_process(delta: float) -> void:
	if state == State.DEAD or _process_stun(delta):
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_strike_anim = maxf(_strike_anim - delta, 0.0)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack(delta)
		State.RETURN:
			_process_return()

	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	_animate(delta)


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if _player_alive() and global_position.distance_to(_player.global_position) < aggro_radius:
		aggro()
		return
	if sitting or drilling:
		return
	# stojące gobliny lekko się kręcą w miejscu
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 5.0)
		_wander_target = home + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	if position.distance_to(_wander_target) > 2.0:
		velocity = position.direction_to(_wander_target) * speed * 0.35


func _process_chase() -> void:
	if not _player_alive() or _player_is_safe() or position.distance_to(home) > leash_radius:
		state = State.RETURN
		return
	var to_player := _player.global_position - global_position
	if to_player.length() <= attack_range and _cooldown == 0.0:
		state = State.ATTACK
		_attack_timer = attack_windup
		velocity = Vector2.ZERO
		return
	var desired := to_player.normalized() * speed if to_player.length() > attack_range * 0.7 else Vector2.ZERO
	velocity = desired + _separation() * speed


func _process_attack(delta: float) -> void:
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	# uderzenie - trafia, jeśli gracz nadal jest w zasięgu
	_strike_anim = 0.2
	_cooldown = attack_cooldown
	state = State.CHASE
	if _player_alive() and global_position.distance_to(_player.global_position) <= attack_range + 6.0:
		_player.take_damage(damage, global_position)


func _process_return() -> void:
	if position.distance_to(home) < 3.0:
		state = State.IDLE
		health = max_health
		return
	velocity = position.direction_to(home) * speed * 0.8 + _separation() * speed * 0.5


## Odpychanie od innych goblinów, żeby nie stały jeden na drugim.
func _separation() -> Vector2:
	# pozycje wszystkich potworów zbieramy raz na klatkę fizyki - przy setkach
	# goniących potworów to dużo tańsze niż pobieranie grupy przez każdego z osobna
	var frame := Engine.get_physics_frames()
	if frame != _positions_frame:
		_positions_frame = frame
		_positions.clear()
		for other: Node2D in get_tree().get_nodes_in_group("enemies"):
			_positions.append(other.global_position)
	var push := Vector2.ZERO
	var here := global_position
	for pos in _positions:
		var away := here - pos
		var dist_sq := away.length_squared()
		if dist_sq < SEPARATION_RADIUS * SEPARATION_RADIUS and dist_sq > 0.0001:  # 0 = on sam
			var dist := sqrt(dist_sq)
			push += away / dist * (1.0 - dist / SEPARATION_RADIUS)
	return push.limit_length(1.0)


func _player_alive() -> bool:
	return _player != null and not _player.is_dead


func _player_is_safe() -> bool:
	return safe_zone.has_point(_player.global_position)


func _animate(delta: float) -> void:
	# klatki: 0-3 chód, 4-5 siedzenie, 6 zamach, 7 uderzenie
	if state == State.ATTACK:
		sprite.frame = 6
		sprite.flip_h = _player.global_position.x < global_position.x
		return
	if _strike_anim > 0.0:
		sprite.frame = 7
		return
	if drilling and state == State.IDLE:
		var beat := fmod(Time.get_ticks_msec() / 1000.0, DRILL_PERIOD)
		sprite.frame = 6 if beat < 0.25 else 7 if beat < 0.45 else 0
		sprite.flip_h = look_at_point.x < global_position.x
		return
	if sitting and state == State.IDLE:
		_anim_time += delta * 1.5
		sprite.frame = 4 + int(_anim_time) % 2
		sprite.flip_h = look_at_point.x < global_position.x
		return
	if velocity.length() > 8.0:
		_anim_time += delta * 8.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 0


func _flash() -> void:
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash", 1.0)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)


func _die() -> void:
	state = State.DEAD
	_stun_time = 0.0
	if _stun_marker != null:
		_stun_marker.queue_free()
		_stun_marker = null
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	died.emit(self)
	# pokonany boss - osada świętuje (od razu albo po powrocie do Goblińskiego Lasu)
	if self is Boss:
		var settlement := get_tree().get_first_node_in_group("settlement")
		if settlement != null:
			settlement.celebrate()
		else:
			Engine.set_meta("celebrate", true)
	Sfx.play_at("enemy_die", global_position)
	_spawn_poof()
	_drop_loot()
	# Kieł Hydry: każdy padający w pobliżu wróg (także od efektów) może wybuchnąć trucizną
	if _player != null and is_instance_valid(_player.legendary):
		_player.legendary.on_enemy_died(self)
	if _player != null:
		var xp := roundi(xp_reward * _player.stats.xp_multiplier() * Levels.xp_fraction(_player.stats.level, level))
		_player.stats.add_xp(xp)
		DamageNumber.spawn_text(get_parent(), hurt_center() + Vector2(0, -8), "+%d exp" % xp, XP_COLOR, 8)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.6), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.chain().tween_callback(queue_free)


## Płynne pojawienie się (np. po odrodzeniu w obozie).
func appear() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _drop_loot() -> void:
	var gold := randi_range(gold_min, gold_max)
	# złoto rozsypuje się na kilka monet
	var coins := mini(gold, randi_range(1, 3))
	for i in coins:
		@warning_ignore("integer_division")
		var share := gold / coins + (1 if i < gold % coins else 0)
		_spawn_pickup("gold", share)
	if randf() < heart_drop_chance:
		_spawn_pickup("goblin_heart", 1)
	# kamienie wg poziomu potwora (Levels); stone_drop_chance sceny to mnożnik (0 - nie wypadają wcale)
	var stone_category: String = ["weapon", "armor", "jewelry"].pick_random()
	var chances := Levels.stone_chances(level)
	var stone_scale := stone_drop_chance / 0.1
	if randf() < chances[1] * stone_scale:
		_spawn_pickup(Enchanting.stone_id(stone_category, true), 1)
	elif randf() < chances[0] * stone_scale:
		_spawn_pickup(Enchanting.stone_id(stone_category, false), 1)
	if randf() < chances[2] * stone_scale:
		_spawn_pickup("blessed_stone", randi_range(1, 3))
	if randf() < chances[3] * stone_scale:
		_spawn_pickup("mercy_stone", randi_range(1, 2))
	if randf() < equipment_drop_chance:
		_spawn_pickup(Loot.drop_at_level(level), 1)


func _spawn_pickup(item_id: String, amount: int) -> void:
	var pickup: Pickup = load(PICKUP_PATH).instantiate()
	pickup.item_id = item_id
	pickup.amount = amount
	pickup.position = position
	get_parent().add_child.call_deferred(pickup)


func _spawn_poof() -> void:
	var particles := CPUParticles2D.new()
	particles.position = position + Vector2(0, -6)
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.45
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 55.0
	particles.gravity = Vector2(0, 60)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.55, 0.75, 0.4)
	get_parent().add_child(particles)
	particles.finished.connect(particles.queue_free)
