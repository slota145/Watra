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
## Dawny mnożnik kamieni zaklinających - kamienie wypadają już tylko w lochach (Kryształ Watry, skarbiec),
## a nie z potworów; pole zostaje, bo ustawiają je sceny.
@export_range(0.0, 1.0) var stone_drop_chance := 0.1
## Ekwipunek (zwykły, magiczny albo rzadki - Loot) z poziomem potwora.
@export_range(0.0, 1.0) var equipment_drop_chance := 0.04
## Poziom potwora (Levels) - ustawia świat przed dodaniem do sceny; 0 = domyślny poziom krainy.
var level := 0

## Ładowane przy użyciu, nie przez preload - unika cyklicznych zależności (Wolf dziedziczy po Goblin).
const PICKUP_PATH := "res://scenes/pickup.tscn"

## Obszar osady - gobliny nie gonią gracza, który się w nim schronił.
static var safe_zone := Rect2()
## Modyfikatory lochu Watry (Dungeons.MODIFIERS) dla wszystkich potworów bieżącej krainy - mnożniki "health",
## "damage", "xp", "gold", "loot"; poza lochem puste (świat zeruje je przy budowie krainy).
static var dungeon_mods := {}
## Droga przez loch (Dungeon.steer): goniący potwór idzie po niej zamiast prosto w ścianę; poza lochem null.
static var pathing: Object = null
## Myśliwy z Cienia (BowSkills): do tej chwili (Time.get_ticks_msec) potwory, poza bossami, nie widzą gracza.
static var hidden_until := 0
## Pozycje potworów z bieżącej klatki (wspólne dla wszystkich, do rozpychania się).
## Pozycje potworów w kubełkach siatki (bok SEPARATION_RADIUS) - zbierane raz na klatkę fizyki tylko przez
## potwory, które potrzebują rozpychania; każdy sprawdza potem wyłącznie 9 sąsiednich kubełków.
static var _buckets := {}
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
## Daleko od gracza potwór w spoczynku nie kręci się w miejscu (nikt tego nie widzi) - setki potworów w siedliskach
## kosztują wtedy tylko sprawdzenie odległości co kilka klatek.
const DORMANT_DISTANCE := 640.0
var _dormant_check := 0
var _wander_target := Vector2.ZERO
## Pozostały czas ogłuszenia i gwiazdki nad głową.
var _stun_time := 0.0
## Strach (Róg Biesa): wróg ucieka od źródła, dopóki nie minie.
var _fear_time := 0.0
var _fear_from := Vector2.ZERO
## Nieruchome "potwory" (prastare drzewa, kokony) nie uciekają w strachu.
var fearless := false
var _stun_marker: StunMarker
## Cel do zniszczenia (Kryształ Watry albo górnik w lochu - WatraCrystal): potwór z fali idzie do niego i go bije
## (take_hit), chyba że gracz jest blisko - wtedy walczy z graczem. Cel ma is_alive() i hit_radius.
var objective: Node2D
## Obrażenia od innych podróżników (Traveler) - gdy to oni zadali większość, gracz nie dostaje łupu ani doświadczenia.
var traveler_damage := 0
## Obrażenia od podróżników w wydarzeniu (WorldEvents - ranking wkładu; nie odbierają graczowi łupu).
var event_damage := 0
const OBJECTIVE_PLAYER_RANGE := 60.0
## Spowolnienie lodem (księga magii, SpellSkills): mnożnik prędkości i do kiedy trwa (Time.get_ticks_msec); wróg sinieje.
var _chill_until := 0
var _chill_factor := 1.0
const CHILL_COLOR := Color(0.65, 0.85, 1.25)

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
	max_health = maxi(1, roundi(Levels.health(level) * strength * dungeon_mods.get("health", 1.0)))
	var damage_mod: float = dungeon_mods.get("damage", 1.0)
	for property in get_property_list():
		var key: String = property["name"]
		if key.ends_with("damage") and property["type"] == TYPE_INT and get(key) > 0:
			set(key, maxi(1, roundi(Levels.damage(level) * get(key) / ref[1] * damage_mod)))
	xp_reward = roundi(Levels.xp(level) * xp_reward / ref[2] * dungeon_mods.get("xp", 1.0))
	var gold: float = Levels.gold(level) / ref[3] * dungeon_mods.get("gold", 1.0)
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


## Spowolnienie: przez `seconds` wróg porusza się z prędkością razy `factor` (silniejsze spowolnienie wygrywa).
func chill(factor: float, seconds: float) -> void:
	if state == State.DEAD:
		return
	_chill_factor = minf(_chill_factor, factor) if is_chilled() else factor
	_chill_until = maxi(_chill_until, Time.get_ticks_msec() + roundi(seconds * 1000.0))
	sprite.modulate = CHILL_COLOR
	# koniec sprawdzany zegarem - działa też u potworów z własnym _physics_process
	get_tree().create_timer(seconds + 0.05, false).timeout.connect(_end_chill)


func is_chilled() -> bool:
	return Time.get_ticks_msec() < _chill_until


func _end_chill() -> void:
	if not is_chilled():
		_chill_factor = 1.0
		sprite.modulate = Color.WHITE


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

	if _chill_until > 0 and is_chilled():
		velocity *= _chill_factor
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	# stojący w spoczynku nie ruszają się - bez kosztownego move_and_slide (setki potworów w siedliskach)
	if state != State.IDLE or velocity != Vector2.ZERO:
		move_and_slide()
	_animate(delta)


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if _dormant_check > 0:
		_dormant_check -= 1
		return
	var distance := global_position.distance_to(_player.global_position) if _player != null else INF
	if distance > DORMANT_DISTANCE:
		_dormant_check = 8
		return
	if _player_alive() and distance < aggro_radius:
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
	if _wants_objective():
		_process_objective()
		return
	var to_player := _player.global_position - global_position
	if to_player.length() <= attack_range and _cooldown == 0.0:
		state = State.ATTACK
		_attack_timer = attack_windup
		velocity = Vector2.ZERO
		return
	var desired := _toward_player(to_player) * speed if to_player.length() > attack_range * 0.7 else Vector2.ZERO
	velocity = desired + _separation() * speed


func _wants_objective() -> bool:
	return objective != null and is_instance_valid(objective) and objective.is_alive() \
			and global_position.distance_to(_player.global_position) > OBJECTIVE_PLAYER_RANGE


## Atak na cel (kryształ, górnik): podejście i ciosy co attack_cooldown.
func _process_objective() -> void:
	var to: Vector2 = objective.global_position - global_position
	if to.length() <= attack_range + float(objective.hit_radius):
		velocity = _separation() * speed * 0.5
		if _cooldown == 0.0:
			_cooldown = attack_cooldown
			_strike_anim = 0.2
			objective.take_hit(damage)
		return
	velocity = to.normalized() * speed + _separation() * speed


## Kierunek pogoni za graczem: w lochu po drodze omijającej ściany (gdy gracz jest dalej niż za rogiem), inaczej prosto.
func _toward_player(to_player: Vector2) -> Vector2:
	if pathing != null:
		var step: Vector2 = pathing.steer(global_position)
		if step != Vector2.ZERO:
			return step
	return to_player.normalized()


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
	# pozycje wszystkich potworów zbieramy raz na klatkę fizyki - przy setkach goniących potworów to dużo tańsze
	# niż pobieranie grupy przez każdego z osobna; kubełki siatki ograniczają porównania do najbliższych sąsiadów
	var frame := Engine.get_physics_frames()
	if frame != _positions_frame:
		_positions_frame = frame
		_buckets.clear()
		for other: Node2D in get_tree().get_nodes_in_group("enemies"):
			var key := Vector2i((other.global_position / SEPARATION_RADIUS).floor())
			if not _buckets.has(key):
				_buckets[key] = []
			(_buckets[key] as Array).append(other.global_position)
	var push := Vector2.ZERO
	var here := global_position
	var home_key := Vector2i((here / SEPARATION_RADIUS).floor())
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for pos: Vector2 in _buckets.get(home_key + Vector2i(dx, dy), []):
				var away := here - pos
				var dist_sq := away.length_squared()
				if dist_sq < SEPARATION_RADIUS * SEPARATION_RADIUS and dist_sq > 0.0001:  # 0 = on sam
					var dist := sqrt(dist_sq)
					push += away / dist * (1.0 - dist / SEPARATION_RADIUS)
	return push.limit_length(1.0)


func _player_alive() -> bool:
	return _player != null and not _player.is_dead


func _player_is_safe() -> bool:
	return safe_zone.has_point(_player.global_position) or (Time.get_ticks_msec() < hidden_until and not self is Boss)


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
	if slain_by_travelers():
		var gone := create_tween().set_parallel()
		gone.tween_property(sprite, "scale", Vector2(1.3, 0.6), 0.15)
		gone.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
		gone.chain().tween_callback(queue_free)
		return
	_drop_loot()
	_drop_bag()
	# Kieł Hydry: każdy padający w pobliżu wróg (także od efektów) może wybuchnąć trucizną
	if _player != null and is_instance_valid(_player.legendary):
		_player.legendary.on_enemy_died(self)
	if _player != null:
		# drużyna z podróżnikami: +10% za każdego członka (Travelers.party_xp_factor)
		var xp := roundi(xp_reward * _player.stats.xp_multiplier() * Levels.xp_fraction(_player.stats.level, level)
				* _player.travelers.party_xp_factor())
		_player.stats.add_xp(xp)
		DamageNumber.spawn_text(get_parent(), hurt_center() + Vector2(0, -8), "+%d exp" % xp, XP_COLOR, 8)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.6), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.chain().tween_callback(queue_free)


## Czy pokonali go głównie inni podróżnicy (wtedy bez łupu i doświadczenia dla gracza).
func slain_by_travelers() -> bool:
	return traveler_damage * 2 >= max_health


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
	if randf() < equipment_drop_chance * dungeon_mods.get("loot", 1.0):
		_spawn_pickup(Loot.drop_at_level(level), 1)
	# kamienie szlachetne po zadaniu jubilera (w lochach - lepsze, z szansą na trzecią premię)
	if Gems.unlocked and randf() < Gems.DROP_CHANCE * dungeon_mods.get("loot", 1.0):
		_spawn_pickup(Gems.roll("", Gems.cut_for_level(level), pathing != null), 1)


## Torba z łupu (Bags) - wspólna dla wszystkich potworów (bossowie częściej), zwierzyna jej nie nosi.
func _drop_bag() -> void:
	if quest_kind == "animal" or scene_file_path.contains("dummy"):
		return
	var bag := Bags.roll_drop(level, self is Boss)
	if bag != "":
		_spawn_pickup(bag, 1)


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
