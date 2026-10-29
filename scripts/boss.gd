class_name Boss
extends Goblin
## Wspólna logika bossów: czeka w swoim leżu, a gdy gracz podejdzie, walczy -
## goni go i co chwilę wykonuje atak specjalny. Każdy atak najpierw pokazuje
## czerwoną poświatę na ziemi (Telegraph) i animację zamachu, dopiero potem uderza.
## Bossa nie da się przerwać ani odepchnąć ciosem. Po ucieczce gracza wraca i się leczy.
## Podklasy wybierają atak (_choose_attack) i prowadzą go etapami (_update_attack).

@export var boss_name := ""
## Przerwa między atakami specjalnymi (s).
@export var attack_interval := 1.6
## Na ile monet rozsypuje się złoto (każda warta gold_min-gold_max).
@export var gold_coins := 8
## Unikalne, legendarne przedmioty bossa - każdy losowany osobno i naprawdę rzadko
## (w trybie deweloperskim wypadają zawsze, razem z całą resztą łupu).
@export var legendary_drops: PackedStringArray = []
@export_range(0.0, 1.0) var legendary_drop_chance := 0.02

## Bieżący atak specjalny ("" = brak) i jego etap: telegraph / act / recover.
var _attack := ""
var _attack_stage := ""
var _stage_timer := 0.0
var _special_cooldown := 1.2
var _telegraph: Telegraph
## Gracz obrywa tylko raz na jeden atak.
var _hit_player := false
## Jak długo boss wraca do leża - po RETURN_TIMEOUT s (np. zablokowany o drzewo) przenosi się do niego.
var _return_time := 0.0

const RETURN_TIMEOUT := 6.0
## Ogłuszenie trwa u bossa tylko tyle (część pełnego czasu).
const STUN_RESISTANCE := 0.4


func _ready() -> void:
	super()
	add_to_group("bosses")
	hurt_radius = 13.0


func is_engaged() -> bool:
	return state == State.CHASE


## Bossa nie odpycha cios i nie przerywa jego ataku.
func take_damage(amount: int, _from_position: Vector2, _knockback := 0.0) -> void:
	if state == State.DEAD:
		return
	health -= amount
	DamageNumber.spawn(get_parent(), hurt_center(), amount)
	_flash()
	if health <= 0:
		_cancel_attack()
		_die()
		return
	aggro()


func _physics_process(delta: float) -> void:
	if state == State.DEAD or _process_stun(delta):
		return
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if _player_alive() and not _player_is_safe() and global_position.distance_to(_player.global_position) < aggro_radius:
				aggro()
		State.RETURN:
			_cancel_attack()
			_return_time += delta
			if position.distance_to(home) < 4.0 or _return_time > RETURN_TIMEOUT:
				if position.distance_to(home) >= 4.0:
					position = home
					appear()
				state = State.IDLE
				health = max_health
				velocity = Vector2.ZERO
				_return_time = 0.0
			else:
				velocity = position.direction_to(home) * speed
		_:
			_process_fight(delta)
	move_and_slide()
	_animate(delta)


func _process_fight(delta: float) -> void:
	if not _player_alive() or _player_is_safe() or position.distance_to(home) > leash_radius:
		_cancel_attack()
		state = State.RETURN
		return
	if _attack != "":
		_stage_timer -= delta
		_update_attack(delta)
		return
	_special_cooldown -= delta
	var to_player := _player.global_position - global_position
	if _special_cooldown <= 0.0 and _choose_attack(to_player):
		return
	velocity = to_player.normalized() * speed if to_player.length() > 28.0 else Vector2.ZERO


# ---------------------------------------------------------------- do nadpisania
## Wybiera i zaczyna atak specjalny; false, jeśli żaden nie pasuje do odległości.
func _choose_attack(_to_player: Vector2) -> bool:
	return false


func _update_attack(_delta: float) -> void:
	pass


# ---------------------------------------------------------------- pomocnicze dla ataków
func _start_attack(attack: String, telegraph_time: float) -> void:
	_attack = attack
	_hit_player = false
	velocity = Vector2.ZERO
	_set_stage("telegraph", telegraph_time)


func _set_stage(stage: String, time: float) -> void:
	_attack_stage = stage
	_stage_timer = time


func _end_attack() -> void:
	_attack = ""
	_attack_stage = ""
	_special_cooldown = attack_interval
	_remove_telegraph()


## Ogłuszenie przerywa atak specjalny (znika poświata ostrzegawcza).
func _on_stunned() -> void:
	_cancel_attack()
	_special_cooldown = maxf(_special_cooldown, 0.6)


func _cancel_attack() -> void:
	_attack = ""
	_attack_stage = ""
	sprite.position = Vector2.ZERO
	_remove_telegraph()


## Czerwona poświata na ziemi (pod postaciami) w kształcie ataku.
func _show_telegraph(shape: Telegraph.Shape, pos: Vector2, angle: float, duration: float) -> Telegraph:
	Sfx.play_at("telegraph", pos)
	_remove_telegraph()
	var telegraph := Telegraph.new()
	telegraph.shape = shape
	telegraph.duration = duration
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = pos
	telegraph.rotation = angle
	_telegraph = telegraph
	return telegraph


func _remove_telegraph() -> void:
	if is_instance_valid(_telegraph):
		var fading := _telegraph
		fading.set_process(false)
		var tween := fading.create_tween()
		tween.tween_property(fading, "modulate:a", 0.0, 0.15)
		tween.tween_callback(fading.queue_free)
	_telegraph = null


## Czy gracz stoi w obszarze bieżącej poświaty.
func _player_in_telegraph() -> bool:
	return is_instance_valid(_telegraph) and _player_alive() and _telegraph.contains(_player.global_position)


func _hurt_player(amount: int, push := 0.0) -> void:
	if _hit_player or not _player_alive():
		return
	_hit_player = true
	_player.take_damage(amount, global_position)
	if push > 0.0:
		_player._knockback = (_player.global_position - global_position).normalized() * push


func _shake_camera(strength: float) -> void:
	if _player != null and _player.global_position.distance_to(global_position) < 320.0:
		_player._shake = maxf(_player._shake, strength)


## Kurz / odłamki rozbryzgujące się po uderzeniu.
func _burst(pos: Vector2, color: Color, amount: int, power: float) -> void:
	var p := CPUParticles2D.new()
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.6
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = power * 0.4
	p.initial_velocity_max = power
	p.gravity = Vector2(0, 120)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	p.emitting = true
	get_parent().add_child(p)
	p.finished.connect(p.queue_free)


func _face(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x


# ---------------------------------------------------------------- łup
## Dużo więcej wszystkiego: złoto w wielu monetach, kamienie zaklinające i wspierające.
func _drop_loot() -> void:
	for i in gold_coins:
		_spawn_pickup("gold", randi_range(gold_min, gold_max))
	for i in 3:
		_spawn_pickup(Enchanting.stone_id(["weapon", "armor", "jewelry"].pick_random(), false), 1)
	_spawn_pickup(Enchanting.stone_id(["weapon", "armor", "jewelry"].pick_random(), true), 1)
	_spawn_pickup("blessed_stone", randi_range(15, 25))
	_spawn_pickup("mercy_stone", randi_range(4, 8))
	_drop_trophies()
	# dwa przedmioty: pierwszy co najmniej magiczny, drugi z dużą szansą na rzadki
	# (w trybie deweloperskim oba rzadkie)
	_spawn_pickup(Loot.random_drop(3, 0.1, Loot.RARE if _dev_mode() else Loot.MAGIC, Loot.BOSS_LEVEL_BONUS), 1)
	_spawn_pickup(Loot.random_drop(3, 0.2, Loot.RARE if _dev_mode() else "", Loot.BOSS_LEVEL_BONUS), 1)
	for id in legendary_drops:
		if _dev_mode() or randf() < legendary_drop_chance:
			_spawn_pickup(Loot.legendary(id, 3), 1)


## Tryb deweloperski gwarantuje cały możliwy łup bossa.
func _dev_mode() -> bool:
	var hud := get_tree().get_first_node_in_group("hud")
	return hud != null and hud.dev_mode


## Łup typowy dla gatunku bossa (serca, skóry...).
func _drop_trophies() -> void:
	pass
