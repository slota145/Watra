class_name Animal
extends Goblin
## Zwierzyna łowna (jeleń, sarna, dzik, zając). Nie atakuje - pasie się wokół swojego
## miejsca, a gdy gracz podejdzie za blisko albo ją zrani, ucieka razem z resztą stada.
## Po ucieczce wraca spokojnie na pastwisko. Ma mało życia i zostawia skóry i mięso.
## Dziedziczy po Goblinie, więc działają na nią wszystkie bronie, odradzanie i znaczniki na mapie.

## Kogo gracz płoszy: odległość, z której zwierzę rzuca się do ucieczki.
@export var flee_radius := 70.0
@export var run_speed := 95.0
## Jak daleko od swojego miejsca zwierzę chodzi, pasąc się.
@export var graze_radius := 36.0
## Ile sekund ucieka (potem uspokaja się, gdy gracz jest dość daleko).
@export var flee_time := 2.5
## Zając ucieka zygzakiem.
@export var zigzag := false
## Środek ciała względem stóp i promień trafienia.
@export var body_offset := Vector2(0, -7)
@export var body_radius := 7.0
## Łupy: [id przedmiotu, szansa, ile od, ile do].
@export var loot: Array = []
## Głos w pobliżu gracza (np. pochrząkiwanie) i głos przy ucieczce (szczekanie sarny, kwik dzika).
@export var voice := ""
@export var voice_alarm := ""
## W jakiej odległości od gracza zwierzę bywa słychać.
const VOICE_DISTANCE := 220.0

const ANIMAL_COLOR := Color(0.85, 0.7, 0.45)

var _flee_left := 0.0
var _zig := 1.0
var _zig_timer := 0.0
var _graze_anim := 0.0
var _alert := 0.0
var _voice_timer := 0.0


func _ready() -> void:
	super()
	add_to_group("animals")
	quest_kind = "animal"
	map_color = ANIMAL_COLOR
	hurt_radius = body_radius
	sitting = false
	sprite.flip_h = randf() < 0.5
	_voice_timer = randf_range(3.0, 15.0)


func hurt_center() -> Vector2:
	return global_position + body_offset


## Wywoływane przy trafieniu (i przez zwierzęta ze stada) - zamiast ataku ucieczka.
func aggro() -> void:
	if state == State.DEAD:
		return
	var already := state == State.CHASE
	_flee_left = flee_time
	state = State.CHASE
	if already:
		return
	if voice_alarm != "":
		Sfx.play_at(voice_alarm, global_position)
	# stado ucieka razem
	for other: Animal in get_tree().get_nodes_in_group("animals"):
		if other != self and other.state != State.CHASE and other.global_position.distance_to(global_position) < alert_radius:
			other.aggro()


func _physics_process(delta: float) -> void:
	if state == State.DEAD or _process_stun(delta):
		return
	_process_voice(delta)
	match state:
		State.CHASE:
			_process_flee(delta)
		State.RETURN:
			_process_calm_return()
		_:
			_process_graze(delta)
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	_animate(delta)


## Spokojne zwierzę czasem się odzywa, gdy gracz jest w pobliżu.
func _process_voice(delta: float) -> void:
	if voice == "" or state != State.IDLE:
		return
	_voice_timer -= delta
	if _voice_timer > 0.0:
		return
	_voice_timer = randf_range(8.0, 20.0)
	if _player_near(VOICE_DISTANCE):
		Sfx.play_at(voice, global_position)


func _player_near(radius: float) -> bool:
	return _player_alive() and global_position.distance_to(_player.global_position) < radius


## Pasie się: chodzi powoli w pobliżu swojego miejsca, przystaje i skubie trawę.
func _process_graze(delta: float) -> void:
	velocity = Vector2.ZERO
	if _player_near(flee_radius):
		aggro()
		return
	# gracz w pobliżu - zwierzę unosi łeb i nasłuchuje
	_alert = 1.0 if _player_near(flee_radius * 1.6) else maxf(_alert - delta, 0.0)
	if _alert > 0.0:
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.5, 6.0)
		_wander_target = home + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * graze_radius
	if position.distance_to(_wander_target) > 3.0:
		velocity = position.direction_to(_wander_target) * speed * 0.4 + _separation() * speed * 0.3


func _process_flee(delta: float) -> void:
	_flee_left -= delta
	var away := Vector2.RIGHT.rotated(randf() * TAU)
	if _player_alive():
		away = (global_position - _player.global_position).normalized()
	if zigzag:
		_zig_timer -= delta
		if _zig_timer <= 0.0:
			_zig_timer = randf_range(0.25, 0.5)
			_zig = -_zig
		away = away.rotated(0.7 * _zig)
	velocity = (away + _separation() * 0.6).normalized() * run_speed
	if _flee_left <= 0.0 and not _player_near(flee_radius * 2.2):
		state = State.RETURN


## Uspokojone wraca stępa na pastwisko (chyba że gracz znów podejdzie).
func _process_calm_return() -> void:
	if _player_near(flee_radius):
		aggro()
		return
	if position.distance_to(home) < graze_radius:
		state = State.IDLE
		_wander_timer = randf_range(1.0, 3.0)
		return
	velocity = position.direction_to(home) * speed * 0.6 + _separation() * speed * 0.3


## Klatki: 0-3 bieg, 4-5 pasienie, 6 czujność (łeb w górze), 7 stanie.
func _animate(delta: float) -> void:
	var moving := velocity.length() > 6.0
	if moving:
		var fps := 12.0 if state == State.CHASE else 6.0
		_anim_time += delta * fps
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	elif _alert > 0.0:
		sprite.frame = 6
		if _player_alive():
			sprite.flip_h = _player.global_position.x < global_position.x
	else:
		_graze_anim += delta * 2.0
		# na zmianę skubie trawę i rozgląda się
		sprite.frame = 7 if fmod(_graze_anim, 6.0) > 4.5 else 4 + int(_graze_anim * 1.5) % 2


## Trafione strzałą myśliwego: pada i leży, aż myśliwy zabierze je na plecach
## (bez łupów i expa dla gracza). Na pastwisku pojawi się później nowe zwierzę.
func die_from_hunter() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	remove_from_group("enemies")
	remove_from_group("animals")
	$CollisionShape2D.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	died.emit(self)
	Sfx.play_at("enemy_die", global_position)
	sprite.frame = 7
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", -PI / 2.0 if sprite.flip_h else PI / 2.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:y", 3.0, 0.35)
	# gdyby nikt go nie zabrał - po dłuższym czasie znika
	tween.tween_interval(90.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)


## Skóry, mięso i trofea zamiast złota i kamieni.
func _drop_loot() -> void:
	for entry: Array in loot:
		if randf() < float(entry[1]):
			_spawn_pickup(entry[0], randi_range(int(entry[2]), int(entry[3])))


func _spawn_poof() -> void:
	pass
