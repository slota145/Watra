class_name Hunter
extends Npc
## Myśliwy z chatki myśliwych. Przy chatce struga strzały, oprawia skóry i ćwiczy strzelanie
## do tarczy. Co jakiś czas idzie drogą na polowanie do wolnego łowiska (w każdym rogu mapy
## poluje najwyżej jeden myśliwy): wybiera zwierzę, podkrada się do niego przykucnięty,
## kładzie je jedną strzałą z łuku, zarzuca na plecy i niesie do chatki. Tam oprawia
## zwierzynę na stelażu, obrabia skórę, wiesza mięso w wędzarni, a skóry i mięso
## zanosi do magazynu osady.

enum Task { CHORE, GO_HUNT, STALK, AIM, SHOT, FETCH, CARRY_HOME, BUTCHER, SCRAPE, SMOKE, DELIVER, BACK }

const WALK_SPEED := 36.0
const STALK_SPEED := 13.0
## Od tej odległości myśliwy skrada się, a z tej strzela.
const STALK_RANGE := 150.0
const SHOT_RANGE := 76.0
const AIM_TIME := 0.9
const ARROW_SPEED := 280.0
## Po tylu sekundach bezowocnego polowania wraca do chatki.
const HUNT_TIMEOUT := 160.0
const ARROW := preload("res://assets/projectiles/arrow.png")
const BOW := preload("res://assets/weapons/short_bow.png")

## Osada z chatką (miejsca pracy, szlaki do łowisk, magazyn) - bez typu, żeby uniknąć zależności cyklicznej.
var lodge: Node
var task := Task.CHORE

var _corner := -1
var _route: Array[Vector2] = []
var _waypoints: Array[Vector2] = []
var _on_arrive := Callable()
var _speed := WALK_SPEED
var _timer := 0.0
var _hunt_cooldown := 0.0
var _hunt_time := 0.0
var _prey: Animal
var _goods := {}
var _chore := ""
var _shot_timer := 0.0
var _crouching := false

@onready var bow: Sprite2D = $Bow


func _ready() -> void:
	super()
	_hunt_cooldown = randf_range(3.0, 30.0)
	bow.texture = BOW
	bow.visible = false
	_start_chore.call_deferred()


func _process(delta: float) -> void:
	_hunt_cooldown -= delta
	if task in [Task.GO_HUNT, Task.STALK, Task.AIM]:
		_hunt_time += delta
		if _hunt_time > HUNT_TIMEOUT:
			_go_home(false)
	if not _waypoints.is_empty():
		_walk(delta)
	else:
		match task:
			Task.CHORE:
				_process_chore(delta)
			Task.STALK:
				_process_stalk(delta)
			Task.AIM:
				_process_aim(delta)
			Task.BUTCHER, Task.SCRAPE, Task.SMOKE:
				_process_job(delta)
			_:
				_set_frame(_row_for(facing), 0)
	_process_talk(delta)


# ---------------------------------------------------------------- chodzenie
func _go(points: Array[Vector2], then: Callable, speed := WALK_SPEED) -> void:
	_waypoints = points.duplicate()
	_on_arrive = then
	_speed = speed


func _walk(delta: float) -> void:
	var to := _waypoints[0] - position
	var step := _speed * delta
	if to.length() <= step:
		position = _waypoints[0]
		_waypoints.pop_front()
		if _waypoints.is_empty():
			var then := _on_arrive
			_on_arrive = Callable()
			if then.is_valid():
				then.call()
		return
	position += to.normalized() * step
	facing = to.normalized()
	_anim += delta * WALK_FPS * (_speed / WALK_SPEED)
	_set_frame(_row_for(facing), int(_anim) % 4)
	if carried.visible:
		# niesiona zwierzyna za plecami, gdy idzie w górę
		move_child(carried, 1 if _row_for(facing) == ROW_UP else 2)
		carried.position = carried_offset + Vector2(0, -1 if int(_anim) % 2 else 0)


# ---------------------------------------------------------------- obowiązki przy chatce
func _start_chore() -> void:
	task = Task.CHORE
	_set_crouch(false)
	bow.visible = false
	if _hunt_cooldown <= 0.0 and _try_hunt():
		return
	_chore = ["arrows", "hides", "archery", "archery"].pick_random()
	var spot: String = {"arrows": "bench", "hides": "hide", "archery": "shoot"}[_chore]
	_go([lodge.lodge_spot(spot)], _begin_chore)


func _begin_chore() -> void:
	_timer = randf_range(8.0, 16.0)
	work_sound = ""
	match _chore:
		"arrows":  # struga strzały przy stole
			facing = Vector2.RIGHT
			work_gentle = true
			work_period = 1.0
		"hides":  # oprawia skóry na ramie
			facing = Vector2.LEFT
			work_gentle = true
			work_period = 1.3
		"archery":
			facing = Vector2.RIGHT
			_shot_timer = 1.0


func _process_chore(delta: float) -> void:
	_timer -= delta
	if _chore == "archery":
		_hold_bow(Vector2.RIGHT)
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			_shot_timer = randf_range(1.6, 2.8)
			var target: Vector2 = lodge.lodge_spot("target") + Vector2(randf_range(-2, 2), -11 + randf_range(-3, 3))
			_shoot_arrow(target, lodge.hit_target)
	else:
		_process_worker(delta)
	if _timer <= 0.0:
		_start_chore()


# ---------------------------------------------------------------- polowanie
func _try_hunt() -> bool:
	var corner: int = lodge.reserve_corner()
	if corner < 0:
		return false
	_route.assign(lodge.hunting_routes[corner])
	_prey = _find_prey(corner, lodge.hunting_areas[corner].get_center(), INF)
	if _prey == null:
		lodge.release_corner(corner)
		_hunt_cooldown = 20.0
		return false
	_corner = corner
	_hunt_time = 0.0
	task = Task.GO_HUNT
	if randf() < 0.5:
		say(["Idę na łowy!", "Dziś przyniosę jelenia.", "Wiatr sprzyja, czas na polowanie."].pick_random())
	# drogą do punktu szlaku najbliżej zwierzyny, dalej przez las
	var leave := _nearest_route_index(_prey.global_position)
	var path: Array[Vector2] = lodge.town_route(corner)
	path.append_array(_route.slice(0, leave + 1))
	_go(path, _begin_stalk)
	return true


## Najbliższe żywe zwierzę w łowisku (w zasięgu `max_distance` od punktu `near`).
func _find_prey(corner: int, near: Vector2, max_distance: float) -> Animal:
	var area: Rect2 = lodge.hunting_areas[corner]
	var best: Animal = null
	var best_distance := max_distance
	for animal: Animal in get_tree().get_nodes_in_group("animals"):
		if animal.state == Goblin.State.DEAD or not area.has_point(animal.global_position):
			continue
		var d := animal.global_position.distance_to(near)
		if d < best_distance:
			best_distance = d
			best = animal
	return best


func _prey_alive() -> bool:
	return is_instance_valid(_prey) and _prey.state != Goblin.State.DEAD


func _begin_stalk() -> void:
	task = Task.STALK


## Podchodzi do zwierzęcia; z bliska przykucnięty i powoli, żeby go nie spłoszyć.
func _process_stalk(delta: float) -> void:
	if not _prey_alive():
		_prey = _find_prey(_corner, position, 500.0)
		if _prey == null:
			_go_home(false)
		return
	var to := _prey.global_position - position
	var distance := to.length()
	if distance <= SHOT_RANGE:
		task = Task.AIM
		_timer = AIM_TIME
		return
	_set_crouch(distance < STALK_RANGE)
	var speed := STALK_SPEED if _crouching else WALK_SPEED
	position += to.normalized() * speed * delta
	facing = to.normalized()
	_anim += delta * WALK_FPS * (0.45 if _crouching else 1.0)
	_set_frame(_row_for(facing), int(_anim) % 4)


func _process_aim(delta: float) -> void:
	if not _prey_alive():
		bow.visible = false
		task = Task.STALK
		return
	_hold_bow(_prey.global_position - position)
	_timer -= delta
	if _timer <= 0.0:
		task = Task.SHOT
		_shoot_arrow(_prey.hurt_center(), _on_prey_hit.bind(_prey))


## Jedna strzała wystarcza - zwierzę pada, a myśliwy idzie je zabrać.
func _on_prey_hit(prey: Animal) -> void:
	if task != Task.SHOT:
		return
	if not is_instance_valid(prey) or prey.state == Goblin.State.DEAD:
		task = Task.STALK
		return
	prey.die_from_hunter()
	_set_crouch(false)
	bow.visible = false
	task = Task.FETCH
	_go([prey.global_position + Vector2(-8.0 if prey.global_position.x > position.x else 8.0, 2)], _pick_up)


func _pick_up() -> void:
	if not is_instance_valid(_prey):
		_go_home(false)
		return
	# zwierzę na plecach: klatka "stanie" obrócona do góry nogami
	var sheet: Texture2D = _prey.sprite.texture
	var body := AtlasTexture.new()
	body.atlas = sheet
	body.region = Rect2(sheet.get_width() * 0.75, sheet.get_height() * 0.5, sheet.get_width() * 0.25, sheet.get_height() * 0.5)
	carried.texture = body
	carried.scale = Vector2.ONE
	carried.flip_v = true
	carried.flip_h = false
	carried_offset = Vector2(0, -17 - body.region.size.y * 0.3)
	carried.position = carried_offset
	carried.visible = true
	_goods.clear()
	for entry: Array in _prey.loot:
		# myśliwy oprawia porządnie - skóra i mięso zawsze, trofea jak się trafi
		var chance := 1.0 if str(entry[0]).ends_with("hide") or str(entry[0]).ends_with("pelt") or entry[0] == "meat" else float(entry[1])
		if randf() < chance:
			_goods[entry[0]] = int(_goods.get(entry[0], 0)) + int(entry[3])
	_prey.queue_free()
	_prey = null
	if randf() < 0.6:
		say(["Mam go!", "Piękna sztuka!", "Będzie uczta w karczmie!"].pick_random())
	_go_home(true)


## Powrót drogą do chatki - z upolowaną zwierzyną albo z pustymi rękami.
func _go_home(loaded: bool) -> void:
	task = Task.CARRY_HOME if loaded else Task.BACK
	_set_crouch(false)
	bow.visible = false
	var path: Array[Vector2] = []
	for i in range(_nearest_route_index(position), -1, -1):
		path.append(_route[i])
	var town: Array[Vector2] = lodge.town_route(_corner)
	town.reverse()
	path.append_array(town)
	if loaded:
		path.append(lodge.lodge_spot("butcher"))
		_go(path, _begin_butcher, WALK_SPEED * 0.8)
	else:
		_go(path, _end_hunt)


func _end_hunt() -> void:
	lodge.release_corner(_corner)
	_corner = -1
	_hunt_cooldown = randf_range(15.0, 30.0)
	_start_chore()


func _nearest_route_index(point: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in _route.size():
		var d := _route[i].distance_squared_to(point)
		if d < best_distance:
			best_distance = d
			best = i
	return best


# ---------------------------------------------------------------- oprawianie i magazyn
func _begin_butcher() -> void:
	lodge.release_corner(_corner)
	_corner = -1
	carried.visible = false
	carried.flip_v = false
	lodge.show_carcass(true)
	task = Task.BUTCHER
	_timer = 7.0
	facing = Vector2.RIGHT
	work_gentle = false
	work_period = 0.6
	work_sound = "dummy"


func _process_job(delta: float) -> void:
	_process_worker(delta)
	_timer -= delta
	if _timer > 0.0:
		return
	work_sound = ""
	match task:
		Task.BUTCHER:
			lodge.show_carcass(false)
			task = Task.SCRAPE
			_carry(_hide_id())
			_go([lodge.lodge_spot("hide")], _begin_job.bind(5.0, Vector2.LEFT))
		Task.SCRAPE:
			if _goods.has("meat"):
				task = Task.SMOKE
				_carry("meat")
				_go([lodge.lodge_spot("smoke")], _begin_job.bind(3.0, Vector2.LEFT))
			else:
				_deliver()
		Task.SMOKE:
			_deliver()


func _begin_job(time: float, face: Vector2) -> void:
	carried.visible = false
	_timer = time
	facing = face
	work_gentle = true
	work_period = 1.1


## Zanosi skóry i mięso do magazynu osady.
func _deliver() -> void:
	task = Task.DELIVER
	_carry(_hide_id())
	var path: Array[Vector2] = lodge.town_route(0)
	path.pop_back()
	path.append_array([lodge.lodge_spot("warehouse") + Vector2(96, 120), lodge.lodge_spot("warehouse") + Vector2(0, 40),
			lodge.lodge_spot("warehouse")])
	_go(path, _on_delivered.bind(path))


func _on_delivered(path: Array[Vector2]) -> void:
	lodge.deliver_goods(_goods)
	_goods.clear()
	carried.visible = false
	Sfx.play_at("deposit", global_position)
	task = Task.BACK
	var back := path.duplicate()
	back.reverse()
	_hunt_cooldown = randf_range(20.0, 45.0)
	_go(back, _start_chore)


func _hide_id() -> String:
	for id: String in _goods:
		if id != "meat":
			return id
	return "meat"


func _carry(item_id: String) -> void:
	if not Items.get_data(item_id).has("icon"):
		carried.visible = false
		return
	carried.texture = Items.get_data(item_id)["icon"]
	carried.scale = Vector2.ONE * 16.0 / carried.texture.get_width()  # ikony mają 64 px, w świecie 16
	carried.flip_v = false
	carried_offset = Vector2(0, -22)
	carried.position = carried_offset
	carried.visible = true


# ---------------------------------------------------------------- łuk i strzały
func _hold_bow(direction: Vector2) -> void:
	facing = direction.normalized()
	_set_frame(ROW_SIDE, 0)
	sprite.flip_h = facing.x < 0.0
	bow.visible = true
	bow.flip_h = sprite.flip_h
	bow.position = Vector2(-6.0 if sprite.flip_h else 6.0, -11)


func _shoot_arrow(to: Vector2, on_hit: Callable) -> void:
	var from := global_position + bow.position
	var arrow := Sprite2D.new()
	arrow.texture = ARROW
	arrow.position = from
	arrow.rotation = (to - from).angle()
	arrow.z_index = 5
	get_parent().add_child(arrow)
	Sfx.play_at("bow", global_position, -4.0)
	var tween := arrow.create_tween()
	tween.tween_property(arrow, "position", to, from.distance_to(to) / ARROW_SPEED)
	tween.tween_callback(on_hit)
	tween.tween_interval(1.2)
	tween.tween_property(arrow, "modulate:a", 0.0, 0.3)
	tween.tween_callback(arrow.queue_free)


func _set_crouch(on: bool) -> void:
	_crouching = on
	sprite.position.y = _sprite_y + (2.0 if on else 0.0)
