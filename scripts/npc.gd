class_name Npc
extends Node2D
## Mieszkaniec osady. Role:
## - IDLE: stoi, rozgląda się i zagaduje przechodzącego gracza,
## - WORKER: pracuje narzędziem w miejscu (kowal przy kowadle, myśliwy przy skórach, cieśla),
## - CARRIER: nosi towar tam i z powrotem po ścieżce (deski, beczki),
## - MERCHANT: stoi za ladą i handluje,
## - PATRON: gość karczmy - wychodzi po ścieżce do stolika, siada z kufelkiem, pije i wraca.
## Stojący mogą też maszerować na komendę (musztra - march_to).
## Każdy, kto ma towar (shop_sells), handluje po naciśnięciu E - także kowal czy myśliwy przy pracy.
## NPC z zadaniem (quest_id albo łańcuch quest_chain - kolejne zadania po wykonaniu poprzednich) ma nad głową znacznik: złote "!" (do przyjęcia),
## szare "?" (w toku) albo złote "?" (do odebrania nagrody), a E otwiera rozmowę.

enum Role { IDLE, WORKER, CARRIER, MERCHANT, PATRON }

const WALK_FPS := 7.0
const SPEED := 30.0
const TALK_DISTANCE := 130.0
const INTERACT_DISTANCE := 34.0
const BUBBLE_TIME := 3.5
## Wiersze w arkuszu postaci.
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_SIDE := 2
const ROW_WORK := 3

var role := Role.IDLE
var display_name := ""
var lines: Array[String] = []
## Kierunek patrzenia (dla stojących i pracujących).
var facing := Vector2.DOWN
## Czy stojący mieszkaniec rozgląda się na boki.
var looks_around := true

## CARRIER: ścieżka od źródła do celu, noszony przedmiot i co się dzieje po dostarczeniu.
var path: Array[Vector2] = []
var carried_texture: Texture2D
## Jeśli niepuste - przy każdym kursie tragarz bierze losową rzecz z tej listy.
var carried_textures: Array[Texture2D] = []
var carried_offset := Vector2(0, -20)
var wait_time := 1.5
var on_delivered := Callable()
## PATRON: w którą stronę patrzy, siedząc przy stoliku.
var seat_facing := Vector2.RIGHT

## WORKER: efekt przy uderzeniu ("sparks", "dust" albo "") i jego pozycja.
var work_effect := ""
var work_effect_offset := Vector2(12, -6)
var work_period := 0.7
## Spokojna praca (oprawianie skór) zamiast uderzeń.
var work_gentle := false
## Wołane w chwili uderzenia (np. kukła treningowa się odchyla).
var on_work_hit := Callable()
## Dźwięk uderzenia przy pracy (nazwa z Sfx.SOUNDS, słychać go tylko w pobliżu).
var work_sound := ""

## Towary na sprzedaż (id przedmiotów). Handlarz skupuje wszystko, co ma wartość.
var shop_sells: Array[String] = []
var trade_greeting := "Czego potrzebujesz, wędrowcze?"
## Zadanie, które daje ten NPC ("" = brak).
var quest_id := ""
## Kolejne zadania tego NPC - aktualne jest pierwsze niewykonane (wtedy quest_id ustawia się sam).
var quest_chain: Array[String] = []
## Usługi dostępne w rozmowie: "rest" (odpoczynek w karczmie), "storage" (magazyn).
var services: Array[String] = []
## Powitanie w oknie rozmowy (dla NPC bez zadania).
var dialog_greeting := ""

const QUEST_GOLD := Color(1.0, 0.82, 0.25)
const QUEST_GRAY := Color(0.7, 0.72, 0.78)

var _player: Player
var _path_index := 1
var _direction := 1
var _carrying := true
var _wait := 0.0
var _anim := 0.0
var _talk_timer := 0.0
var _look_timer := 0.0
var _work_time := 0.0
var _last_work_frame := 0
var _effect: CPUParticles2D
var _bubble_tween: Tween
var _quest_marker: Label
var _marker_time := 0.0
var _sitting := false
var _drink_time := 0.0
var _sprite_y := 0.0
var _march_from := Vector2.ZERO
var _march_to := Vector2.ZERO
var _march_time := 0.0
var _march_duration := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var carried: Sprite2D = $Carried
@onready var bubble: Label = $Bubble
@onready var prompt: Label = $Prompt


func _ready() -> void:
	add_to_group("npcs")
	_player = get_tree().get_first_node_in_group("player")
	_talk_timer = randf_range(2.0, 10.0)
	_look_timer = randf_range(3.0, 8.0)
	_work_time = randf() * work_period
	bubble.visible = false
	prompt.visible = false
	bubble.add_theme_stylebox_override("normal", UiStyle.panel(Color(0.98, 0.96, 0.9, 0.95), Color(0.1, 0.11, 0.17), 3))
	carried.visible = false
	_sprite_y = sprite.position.y
	if not quest_chain.is_empty():
		quest_id = quest_chain[0]
		_update_quest_chain()

	if has_dialog() or is_trader():
		add_to_group("interactables")
	if has_dialog():
		prompt.text = "[E] Rozmowa"
	if quest_id != "":
		_quest_marker = _make_quest_marker()
		add_child(_quest_marker)
	match role:
		Role.CARRIER:
			position = path[0]
			carried.texture = carried_texture
			carried.position = carried_offset
			carried.visible = true
			_wait = randf_range(0.0, 4.0)  # żeby tragarze nie chodzili w równym rytmie
			_pick_cargo()
		Role.PATRON:
			position = path[0]
			carried.texture = carried_texture
			_carrying = false
			_wait = randf_range(0.0, 12.0)
		Role.WORKER:
			if work_effect != "":
				_effect = _make_effect(work_effect)
				add_child(_effect)


func _process(delta: float) -> void:
	match role:
		Role.CARRIER, Role.PATRON:
			_process_carrier(delta)
		Role.WORKER:
			_process_worker(delta)
		_:
			_process_idle(delta)
	_process_talk(delta)
	if has_dialog() or is_trader():
		prompt.visible = _player_distance() < INTERACT_DISTANCE
	if _quest_marker != null:
		_update_quest_chain()
		_update_quest_marker(delta)


func is_trader() -> bool:
	return not shop_sells.is_empty()


## Czy E otwiera rozmowę (zadanie albo usługi), a nie od razu sklep.
func has_dialog() -> bool:
	return quest_id != "" or not services.is_empty()


func interact(player: Player) -> void:
	if has_dialog():
		player.dialog_requested.emit(self)
	elif is_trader():
		say(trade_greeting)
		player.shop_requested.emit(self)


## Otwiera handel (np. z okna rozmowy).
func open_trade(player: Player) -> void:
	say(trade_greeting)
	player.shop_requested.emit(self)


func _make_quest_marker() -> Label:
	var marker := Label.new()
	marker.z_index = 41
	marker.add_theme_font_size_override("font_size", 16)
	marker.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.02))
	marker.add_theme_constant_override("outline_size", 5)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.size = Vector2(20, 20)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return marker


## Przy łańcuchu zadań aktualne jest pierwsze niewykonane (albo ostatnie, gdy wszystkie zrobione).
func _update_quest_chain() -> void:
	if quest_chain.is_empty() or _player == null:
		return
	for id in quest_chain:
		if _player.quests.state_of(id) != Quests.STATE_DONE:
			quest_id = id
			return
	quest_id = quest_chain[-1]


## Musztra: przejście do punktu w zadanym czasie, patrząc ciągle w tę samą stronę.
func march_to(target: Vector2, duration: float) -> void:
	_march_from = position
	_march_to = target
	_march_time = 0.0
	_march_duration = duration


## Znacznik zadania nad głową, lekko podskakujący.
func _update_quest_marker(delta: float) -> void:
	var state := _player.quests.state_of(quest_id) if _player != null else Quests.STATE_AVAILABLE
	_quest_marker.visible = state != Quests.STATE_DONE
	match state:
		Quests.STATE_AVAILABLE:
			_quest_marker.text = "!"
			_quest_marker.add_theme_color_override("font_color", QUEST_GOLD)
		Quests.STATE_ACTIVE:
			_quest_marker.text = "?"
			_quest_marker.add_theme_color_override("font_color", QUEST_GRAY)
		Quests.STATE_READY:
			_quest_marker.text = "?"
			_quest_marker.add_theme_color_override("font_color", QUEST_GOLD)
	_marker_time += delta
	# dymek z mową przesuwa znacznik wyżej, żeby się nie nakładały
	var top := -52.0 if bubble.visible else -42.0
	_quest_marker.position = Vector2(-10, top + sin(_marker_time * 3.0) * 1.5).round()


func say(text: String) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.reset_size()
	bubble.position = Vector2(-bubble.size.x / 2.0, -38.0 - bubble.size.y + 12.0).round()
	bubble.modulate.a = 1.0
	if _bubble_tween:
		_bubble_tween.kill()
	_bubble_tween = create_tween()
	_bubble_tween.tween_interval(BUBBLE_TIME)
	_bubble_tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	_bubble_tween.tween_callback(func() -> void: bubble.visible = false)


# ---------------------------------------------------------------- zachowania
func _process_idle(delta: float) -> void:
	if _march_duration > 0.0:
		_march_time += delta
		var t := minf(_march_time / _march_duration, 1.0)
		position = _march_from.lerp(_march_to, t)
		_anim += delta * WALK_FPS
		_set_frame(_row_for(facing), int(_anim) % 4 if t < 1.0 else 0)
		if t >= 1.0:
			_march_duration = 0.0
		return
	_set_frame(_row_for(facing), 0)
	if not looks_around:
		return
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = randf_range(3.0, 8.0)
		var options := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]
		# czasem odwraca się w stronę gracza
		if _player_distance() < 60.0:
			facing = (_player.global_position - global_position).normalized()
		else:
			facing = options.pick_random()


func _process_worker(delta: float) -> void:
	_work_time += delta
	var t := fmod(_work_time, work_period) / work_period
	var frame: int
	if work_gentle:
		frame = 2 if t < 0.5 else 1
	else:
		frame = 0 if t < 0.55 else 1
	# moment uderzenia
	if frame == 1 and _last_work_frame != 1:
		if _effect != null:
			_effect.restart()
		if on_work_hit.is_valid():
			on_work_hit.call()
		if work_sound != "":
			Sfx.play_at(work_sound, global_position)
	_last_work_frame = frame
	sprite.flip_h = facing.x < 0.0
	_set_frame(ROW_WORK, frame)


func _process_carrier(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _sitting:
			_process_sitting(delta)
			if _wait <= 0.0:
				_stand_up()
		else:
			_set_frame(_row_for(facing), 0)
		return
	var target := path[_path_index]
	var to_target := target - position
	var step := SPEED * (0.8 if _carrying else 1.0) * delta
	if to_target.length() <= step:
		position = target
		if _direction == 1 and _path_index == path.size() - 1:
			_direction = -1
			if role == Role.PATRON:
				_sit_down()
			else:
				# dostarczone - odkłada towar
				_carrying = false
				carried.visible = false
				_wait = wait_time
				if on_delivered.is_valid():
					on_delivered.call()
		elif _direction == -1 and _path_index == 0:
			_direction = 1
			if role == Role.PATRON:
				# posiedział w karczmie, za chwilę znów wyjdzie na piwo
				_wait = randf_range(6.0, 15.0)
			else:
				# bierze następną sztukę
				_carrying = true
				carried.visible = true
				_pick_cargo()
				_wait = wait_time
		_path_index += _direction
		return
	position += to_target.normalized() * step
	facing = to_target.normalized()
	_anim += delta * WALK_FPS
	_set_frame(_row_for(facing), int(_anim) % 4)
	# niesiona rzecz za plecami, gdy idzie w górę (kolejność dzieci: Shadow, Sprite, Carried)
	move_child(carried, 1 if _row_for(facing) == ROW_UP else 2)
	carried.position = carried_offset + Vector2(0, -1 if int(_anim) % 2 else 0)


func _process_talk(delta: float) -> void:
	if lines.is_empty():
		return
	_talk_timer -= delta
	if _talk_timer > 0.0:
		return
	_talk_timer = randf_range(9.0, 20.0)
	if _player_distance() < TALK_DISTANCE and not bubble.visible:
		say(lines.pick_random())


func _pick_cargo() -> void:
	if not carried_textures.is_empty():
		carried.texture = carried_textures.pick_random()


## Gość siada przy stoliku z kufelkiem.
func _sit_down() -> void:
	_sitting = true
	_wait = randf_range(12.0, 25.0)
	_drink_time = randf_range(1.0, 3.0)
	facing = seat_facing
	sprite.position.y = _sprite_y + 3.0
	move_child(carried, 2)
	carried.visible = true
	carried.position = Vector2(5.0 * signf(seat_facing.x), -18)


func _stand_up() -> void:
	_sitting = false
	sprite.position.y = _sprite_y
	carried.visible = false


## Siedzi i co jakiś czas unosi kufel do ust.
func _process_sitting(delta: float) -> void:
	_set_frame(_row_for(seat_facing), 0)
	_drink_time -= delta
	if _drink_time <= 0.0:
		_drink_time = randf_range(2.5, 5.0)
		var side := signf(seat_facing.x)
		var tween := create_tween()
		tween.tween_property(carried, "position", Vector2(4.0 * side, -20), 0.25)
		tween.tween_property(carried, "rotation", -0.6 * side, 0.15)
		tween.tween_interval(0.6)
		tween.tween_property(carried, "rotation", 0.0, 0.15)
		tween.tween_property(carried, "position", Vector2(5.0 * side, -18), 0.25)


# ---------------------------------------------------------------- pomocnicze
func _row_for(dir: Vector2) -> int:
	if absf(dir.x) >= absf(dir.y):
		sprite.flip_h = dir.x < 0.0
		return ROW_SIDE
	return ROW_DOWN if dir.y > 0.0 else ROW_UP


func _set_frame(row: int, frame: int) -> void:
	sprite.frame = row * sprite.hframes + frame


func _player_distance() -> float:
	if _player == null:
		return INF
	return _player.global_position.distance_to(global_position)


func _make_effect(kind: String) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(work_effect_offset.x * (-1.0 if facing.x < 0.0 else 1.0), work_effect_offset.y)
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.4
	p.direction = Vector2.UP
	if kind == "straw":
		p.amount = 8
		p.spread = 80.0
		p.initial_velocity_min = 20.0
		p.initial_velocity_max = 45.0
		p.gravity = Vector2(0, 90)
		p.scale_amount_max = 2.0
		p.color = Color(0.88, 0.77, 0.48)
		return p
	if kind == "sparks":
		p.amount = 10
		p.spread = 70.0
		p.initial_velocity_min = 30.0
		p.initial_velocity_max = 70.0
		p.gravity = Vector2(0, 160)
		p.color = Color(1.0, 0.75, 0.3)
	else:
		p.amount = 6
		p.spread = 90.0
		p.initial_velocity_min = 10.0
		p.initial_velocity_max = 25.0
		p.gravity = Vector2(0, 40)
		p.scale_amount_max = 2.0
		p.color = Color(0.75, 0.62, 0.45)
	return p
