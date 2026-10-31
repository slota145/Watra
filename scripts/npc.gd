class_name Npc
extends Node2D
## Mieszkaniec osady. Role:
## - IDLE: stoi, rozgląda się i zagaduje przechodzącego gracza,
## - WORKER: pracuje narzędziem w miejscu (kowal przy kowadle, myśliwy przy skórach, cieśla),
## - CARRIER: nosi towar tam i z powrotem po ścieżce (deski, beczki),
## - MERCHANT: stoi za ladą i handluje,
## - PATRON: gość karczmy - wychodzi po ścieżce do stolika, siada z kufelkiem, pije i wraca.
## - WANDER: biega po wyznaczonym obszarze (dzieci); z `chase` bawi się w berka - goni drugie dziecko,
##   a po złapaniu role się zamieniają (uciekający ucieka od goniącego).
## - CYCLE: chodzi w kółko między stanowiskami pracy (kowal: piec -> kowadło -> beczka -> skrzynia), na każdym
##   pracuje albo stoi chwilę, z efektem i dźwiękiem, i niesie dalej to, co tam przygotował (rozgrzany pręt, ostrze).
## Stojący mogą też siedzieć (seated - np. uchodźcy przy ognisku).
## Stojący mogą też maszerować na komendę (musztra - march_to).
## Każdy, kto ma towar (shop_sells), handluje po naciśnięciu E - także kowal czy myśliwy przy pracy.
## NPC z zadaniem (quest_id albo łańcuch quest_chain - kolejne zadania po wykonaniu poprzednich) ma nad głową znacznik: złote "!" (do przyjęcia),
## szare "?" (w toku) albo złote "?" (do odebrania nagrody), a E otwiera rozmowę.

enum Role { IDLE, WORKER, CARRIER, MERCHANT, PATRON, WANDER, CYCLE }

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
## IDLE: siedzi (np. przy ognisku) - postać niżej, bez rozglądania się za daleko.
var seated := false

## CYCLE: stanowiska - {"pos": piksele, "facing", "time": s, "work": praca narzędziem (uderzenia),
## "effect": "sparks"/"steam"/"fire" (przy uderzeniu albo po dojściu), "sound", "carry": Texture2D niesiona dalej albo null}.
var stations: Array = []
var _station := 0
var _at_station := false

## Pijak (CARRIER bez towaru): zatacza się po drodze.
var drunk := false
## Czy pozdrawia przechodzącego obok gracza.
var greets := true
const GREETINGS: Array[String] = ["Witaj, wędrowcze!", "Dobrze cię widzieć całego!", "Niech ci się darzy!",
		"Wróciłeś! Chwała niebiosom.", "Dzień dobry!", "Uważaj na siebie za palisadą."]
const GREET_DISTANCE := 40.0
var _greet_cooldown := 0.0
var _drunk_time := 0.0

## WANDER: obszar zabawy (piksele świata), towarzysz zabawy w berka i czy to ten goni.
var wander_area := Rect2()
var chase: Npc
var chasing := false
const WANDER_SPEED := 52.0
const NOTE := preload("res://assets/village/note.png")
const TAG_DISTANCE := 9.0

## WORKER: efekt przy uderzeniu ("sparks", "dust", "straw", "notes" - nutki grajka, albo "") i jego pozycja.
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

## Znaczniki zadań pobocznych (główne są złote - MainQuests.COLOR).
const QUEST_BLUE := Color(0.45, 0.7, 1.0)
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
var _wander_target := Vector2.ZERO
var _tag_cooldown := 0.0

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
		prompt.text = "[F] Rozmowa"
	if quest_id != "" or MainQuests.involves(display_name):
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
			if work_effect != "" and work_effect != "notes":
				_effect = _make_effect(work_effect)
				add_child(_effect)
		Role.WANDER:
			_wander_target = position
			_wait = randf_range(0.0, 2.0)
		Role.CYCLE:
			position = stations[0]["pos"]
			_at_station = true
			_wait = randf_range(0.5, 2.0)


func _process(delta: float) -> void:
	match role:
		Role.CARRIER, Role.PATRON:
			_process_carrier(delta)
		Role.WORKER:
			_process_worker(delta)
		Role.WANDER:
			_process_wander(delta)
		Role.CYCLE:
			_process_cycle(delta)
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
	return quest_id != "" or not services.is_empty() or MainQuests.involves(display_name)


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
	# zadanie główne ma pierwszeństwo - złote znaczniki
	var main := MainQuests.step_for(_player.quests, display_name) if _player != null else ""
	var state := _player.quests.state_of(quest_id) if _player != null and quest_id != "" else Quests.STATE_DONE
	_quest_marker.visible = state != Quests.STATE_DONE or main != ""
	if main != "":
		var main_state := _player.quests.state_of(main)
		var giving := main_state == Quests.STATE_AVAILABLE
		var waiting := main_state == Quests.STATE_ACTIVE or (main_state == Quests.STATE_READY and MainQuests.receiver_of(main) != display_name)
		# krok czeka na zadanie poboczne, które właśnie można tu oddać
		var linked := MainQuests.linked_quest(main)
		if linked != "" and linked == quest_id and _player.quests.state_of(linked) == Quests.STATE_READY:
			waiting = false
		_quest_marker.text = "!" if giving else "?"
		_quest_marker.add_theme_color_override("font_color", MainQuests.COLOR_DIM if waiting and not giving else MainQuests.COLOR)
		state = "main"
	match state:
		Quests.STATE_AVAILABLE:
			_quest_marker.text = "!"
			_quest_marker.add_theme_color_override("font_color", QUEST_BLUE)
		Quests.STATE_ACTIVE:
			_quest_marker.text = "?"
			_quest_marker.add_theme_color_override("font_color", QUEST_GRAY)
		Quests.STATE_READY:
			_quest_marker.text = "?"
			_quest_marker.add_theme_color_override("font_color", QUEST_BLUE)
	_marker_time += delta
	# dymek z mową przesuwa znacznik wyżej, żeby się nie nakładały
	# nad głową, a przy dymku nad dymkiem (znacznik nie wchodzi na postać)
	var top := bubble.position.y - 20.0 if bubble.visible else -54.0
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
	sprite.position.y = _sprite_y + (3.0 if seated else 0.0)
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
		if work_effect == "notes" and randf() < 0.6:
			_note()
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
	var step := SPEED * (0.8 if _carrying else 1.0) * (0.55 if drunk else 1.0) * delta
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
	if drunk:
		# zatacza się powoli: kołysze na boki wokół drogi i lekko przechyla
		_drunk_time += delta
		var sway := to_target.normalized().orthogonal() * sin(_drunk_time * 0.9) * 4.0
		sprite.position.x = sway.x
		sprite.position.y = _sprite_y + sway.y * 0.5
		sprite.rotation = sin(_drunk_time * 0.7 + 0.5) * 0.06
	facing = to_target.normalized()
	_anim += delta * WALK_FPS
	_set_frame(_row_for(facing), int(_anim) % 4)
	# niesiona rzecz za plecami, gdy idzie w górę (kolejność dzieci: Shadow, Sprite, Carried)
	move_child(carried, 1 if _row_for(facing) == ROW_UP else 2)
	carried.position = carried_offset + Vector2(0, -1 if int(_anim) % 2 else 0)


## Dzieci: biegają między losowymi punktami obszaru, a w berku goniący biegnie do uciekającego,
## uciekający od niego; po złapaniu zamieniają się rolami (z krótką przerwą na odbiegnięcie).
func _process_wander(delta: float) -> void:
	_tag_cooldown -= delta
	var speed := WANDER_SPEED
	if chase != null and _tag_cooldown <= 0.0:
		var away := position - chase.position
		if chasing:
			_wander_target = chase.position
			if away.length() < TAG_DISTANCE:
				# berek! - teraz ucieka ten, kto gonił
				chasing = false
				chase.chasing = true
				_tag_cooldown = 1.0
				chase._tag_cooldown = 1.6
				if randf() < 0.4:
					say(["Berek!", "Mam cię!", "Ty gonisz!"].pick_random())
		elif away.length() < 70.0:
			_wander_target = (position + away.normalized() * 40.0).clamp(wander_area.position, wander_area.end)
			speed *= 0.85
	if _wait > 0.0:
		_wait -= delta
		_set_frame(_row_for(facing), 0)
		return
	var to_target := _wander_target - position
	if to_target.length() < 2.0:
		_wander_target = Vector2(randf_range(wander_area.position.x, wander_area.end.x),
				randf_range(wander_area.position.y, wander_area.end.y))
		if chase == null or not chasing:
			_wait = randf_range(0.3, 2.0)
		return
	var step := minf(speed * delta, to_target.length())
	position += to_target.normalized() * step
	facing = to_target.normalized()
	_anim += delta * WALK_FPS * 1.4
	_set_frame(_row_for(facing), int(_anim) % 4)


func _process_cycle(delta: float) -> void:
	var station: Dictionary = stations[_station]
	if _at_station:
		_wait -= delta
		facing = station.get("facing", facing)
		if station.get("work", false):
			_work_time += delta
			var t := fmod(_work_time, work_period) / work_period
			var frame := 0 if t < 0.55 else 1
			if frame == 1 and _last_work_frame != 1:
				_cycle_effect(station)
			_last_work_frame = frame
			sprite.flip_h = facing.x < 0.0
			_set_frame(ROW_WORK, frame)
		else:
			_set_frame(_row_for(facing), 0)
		if _wait <= 0.0:
			_at_station = false
			var carry: Texture2D = station.get("carry")
			carried.texture = carry
			carried.visible = carry != null
			_station = (_station + 1) % stations.size()
		return
	var target: Vector2 = station["pos"]
	var to_target := target - position
	var step := SPEED * delta
	if to_target.length() <= step:
		position = target
		_at_station = true
		_wait = float(station.get("time", 2.0))
		_work_time = 0.0
		if not station.get("work", false):
			_cycle_effect(station)
		return
	position += to_target.normalized() * step
	facing = to_target.normalized()
	_anim += delta * WALK_FPS
	_set_frame(_row_for(facing), int(_anim) % 4)
	move_child(carried, 1 if _row_for(facing) == ROW_UP else 2)
	carried.position = carried_offset + Vector2(4.0 * (-1.0 if sprite.flip_h else 1.0), -1 if int(_anim) % 2 else 0)


## Efekt i dźwięk stanowiska: iskry przy kowadle, para przy beczce, buchnięcie żaru przy piecu.
func _cycle_effect(station: Dictionary) -> void:
	var kind: String = station.get("effect", "")
	if kind != "":
		var p := _make_effect(kind)
		var side := -1.0 if facing.x < 0.0 else 1.0
		# przodem do stanowiska (np. do pieca) - efekt nad nim, za postacią
		p.position = Vector2(0, -26) if absf(facing.x) < 0.5 else Vector2(14.0 * side, -10.0)
		add_child(p)
		p.emitting = true
		get_tree().create_timer(2.0).timeout.connect(p.queue_free)
	if station.get("sound", "") != "":
		Sfx.play_at(station["sound"], global_position, -4.0)


## Nutka unosząca się nad grajkiem (grafika - czcionka nie ma znaku nuty).
func _note() -> void:
	var note := Sprite2D.new()
	note.texture = NOTE
	note.hframes = 2
	note.frame = randi() % 2
	note.z_index = 30
	note.modulate = [Color(1.0, 0.9, 0.5), Color(0.75, 0.9, 1.0), Color(1.0, 0.7, 0.8)].pick_random()
	var side := -1.0 if facing.x < 0.0 else 1.0
	note.position = Vector2(randf_range(4, 12) * side, -34).round()
	add_child(note)
	var tween := note.create_tween().set_parallel()
	tween.tween_property(note, "position", note.position + Vector2(randf_range(-6, 10) * side, -18), 1.8)
	tween.tween_property(note, "modulate:a", 0.0, 1.8).set_delay(0.8)
	tween.chain().tween_callback(note.queue_free)


func _process_talk(delta: float) -> void:
	_greet_cooldown -= delta
	if greets and role != Role.WANDER and not drunk and _greet_cooldown <= 0.0 and not bubble.visible \
			and _player_distance() < GREET_DISTANCE:
		_greet_cooldown = randf_range(60.0, 120.0)
		if randf() < 0.5:
			say(GREETINGS.pick_random())
			return
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
	if kind == "steam":
		p.amount = 14
		p.lifetime = 1.4
		p.explosiveness = 0.6
		p.spread = 30.0
		p.initial_velocity_min = 10.0
		p.initial_velocity_max = 22.0
		p.gravity = Vector2(0, -12)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = Color(1, 1, 1, 0.55)
		return p
	if kind == "fire":
		p.amount = 12
		p.lifetime = 0.7
		p.spread = 40.0
		p.initial_velocity_min = 20.0
		p.initial_velocity_max = 45.0
		p.gravity = Vector2(0, -30)
		p.color = Color(1.0, 0.6, 0.2)
		return p
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
