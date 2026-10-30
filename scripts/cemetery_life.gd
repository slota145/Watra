class_name CemeteryLife
extends Node2D
## Życie Leśnego Cmentarza (bez walki): stada kruków i zjawy.
## - Stada kruków krążą nad wybranymi miejscami (mauzoleum, trupowisko, kurhany, zagajniki): kilka ptaków
##   na jednym okręgu, każdy na nieco innej wysokości i odległości, z cieniem na ziemi. Co jakiś czas stado
##   zmienia miejsce - przelatuje nad cmentarzem do innego.
## - Kruki siedzą też na ziemi przy grobach małymi grupkami i dziobią; gdy gracz podejdzie, zrywają się
##   z krakaniem, krążą chwilę nad miejscem i siadają z powrotem, kiedy gracz odejdzie.
## - Zjawy: co jakiś czas w pobliżu gracza (ale poza zasięgiem ręki) wyłania się duch, przepływa krótki odcinek
##   nad grobami i rozwiewa się. Nikogo nie atakuje.
## Arkusze z PixelLab (tools/cemetery_creatures.py): crow_fly.png (lot z góry, głową w prawo), crow_perch.png
## (siedzi bokiem, głową w prawo), ghost.png (unoszenie się).

const FLY := preload("res://assets/cemetery/crow_fly.png")
const PERCH := preload("res://assets/cemetery/crow_perch.png")
const GHOST := preload("res://assets/cemetery/ghost.png")
const SHADOW := preload("res://assets/shadow.png")
const FLY_FPS := 12.0
const PERCH_FPS := 6.0
const GHOST_FPS := 7.0
const FLOCK_SPEED := 46.0
const FLOCK_HEIGHT := 70.0
const SPOOK := 64.0
const RETURN_DISTANCE := 150.0
## Zjawy: co ile sekund próba, ile naraz, odległość od gracza, czas życia i długość przelotu (piksele).
const GHOST_INTERVAL := Vector2(6.0, 14.0)
const GHOST_MAX := 2
const GHOST_DISTANCE := Vector2(110.0, 220.0)
const GHOST_LIFE := Vector2(4.0, 7.0)
const GHOST_TRAVEL := Vector2(60.0, 140.0)
const GHOST_ALPHA := 0.75

var _player: Node2D
var _entities: Node2D
var _bounds := Rect2()
var _spots: Array[Vector2] = []
## Stada: {center, radius, angle, birds: [{sprite, shadow, offset, height, phase}], timer, from, to, travel}
var _flocks: Array = []
## Grupki na ziemi: {home, birds: [{sprite, shadow, pos, frame_time}], state, timer, angle}
var _perched: Array = []
var _ghosts: Array = []
var _ghost_timer := 4.0
var _ghost_spots: Array[Vector2] = []


## spots - miejsca, nad którymi krążą stada; ground - miejsca grupek na ziemi; ghost_spots - groby (zjawy pojawiają
## się tylko nad nimi); bounds - obszar lotu (piksele).
func setup(player: Node2D, entities: Node2D, bounds: Rect2, spots: Array[Vector2], ground: Array[Vector2], ghost_spots: Array[Vector2],
		flocks: int, rng: RandomNumberGenerator) -> void:
	_player = player
	_entities = entities
	_bounds = bounds
	_spots = spots
	_ghost_spots = ghost_spots
	z_index = 20  # ptaki w powietrzu i zjawy nad wszystkim
	for i in flocks:
		_flocks.append(_new_flock(rng, spots[i % spots.size()]))
	for home in ground:
		_perched.append(_new_group(rng, home))


func _new_flock(rng: RandomNumberGenerator, center: Vector2) -> Dictionary:
	var flock := {"center": center, "radius": rng.randf_range(50.0, 90.0), "angle": rng.randf() * TAU,
			"birds": [], "timer": rng.randf_range(20.0, 50.0), "from": center, "to": center, "travel": -1.0}
	for k in rng.randi_range(4, 7):
		flock["birds"].append(_bird(rng, {"offset": rng.randf_range(-22.0, 22.0), "angle": TAU * k / 7.0 + rng.randf_range(-0.3, 0.3),
				"height": FLOCK_HEIGHT + rng.randf_range(-15.0, 20.0)}))
	return flock


func _bird(rng: RandomNumberGenerator, data: Dictionary) -> Dictionary:
	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.scale = Vector2(0.8, 0.4)
	shadow.modulate = Color(1, 1, 1, 0.4)
	shadow.z_as_relative = false
	shadow.z_index = 0
	add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = FLY
	sprite.hframes = FLY.get_width() / FLY.get_height()
	add_child(sprite)
	data["sprite"] = sprite
	data["shadow"] = shadow
	data["phase"] = rng.randf() * 10.0
	return data


## Grupka 2-4 kruków na ziemi przy grobach. Każdy kruk ma postać na ziemi (w Entities - sortuje się z grobami
## i postaciami) i postać w locie (tu, nad wszystkim); widać jedną z nich.
func _new_group(rng: RandomNumberGenerator, home: Vector2) -> Dictionary:
	var group := {"home": home, "birds": [], "state": "ground", "timer": 0.0, "angle": 0.0}
	for k in rng.randi_range(2, 4):
		var standing := Sprite2D.new()
		standing.texture = PERCH
		standing.hframes = PERCH.get_width() / PERCH.get_height()
		standing.flip_h = rng.randf() < 0.5
		standing.offset = Vector2(0, -PERCH.get_height() / 2.0 + 6.0)
		var pos := home + Vector2(rng.randf_range(-20, 20), rng.randf_range(-10, 10))
		standing.position = pos.round()
		_entities.add_child(standing)
		var bird := _bird(rng, {"offset": rng.randf_range(-14.0, 14.0), "height": 0.0, "angle": TAU * k / 4.0})
		bird["standing"] = standing
		bird["pos"] = pos
		group["birds"].append(bird)
	_place_ground(group)
	return group


func _process(delta: float) -> void:
	for flock: Dictionary in _flocks:
		_update_flock(flock, delta)
	for group: Dictionary in _perched:
		_update_group(group, delta)
	_update_ghosts(delta)


# ---------------------------------------------------------------- stada w powietrzu
func _update_flock(flock: Dictionary, delta: float) -> void:
	flock["timer"] -= delta
	if flock["travel"] < 0.0 and flock["timer"] <= 0.0 and _spots.size() > 1:
		flock["from"] = flock["center"]
		flock["to"] = _spots.pick_random()
		flock["travel"] = 0.0
	if flock["travel"] >= 0.0:
		var length: float = maxf(1.0, (flock["from"] as Vector2).distance_to(flock["to"]))
		flock["travel"] += FLOCK_SPEED * 1.4 * delta / length
		flock["center"] = (flock["from"] as Vector2).lerp(flock["to"], smoothstep(0.0, 1.0, minf(flock["travel"], 1.0)))
		if flock["travel"] >= 1.0:
			flock["travel"] = -1.0
			flock["timer"] = randf_range(25.0, 60.0)
	flock["angle"] += FLOCK_SPEED / flock["radius"] * delta
	flock["caw"] = flock.get("caw", randf_range(3.0, 12.0)) - delta
	if flock["caw"] <= 0.0:
		flock["caw"] = randf_range(6.0, 16.0)
		Sfx.play_at("crow_caw", flock["center"], -4.0)
	for bird: Dictionary in flock["birds"]:
		var angle: float = flock["angle"] + bird["angle"]
		var radius: float = flock["radius"] + bird["offset"]
		var ground: Vector2 = flock["center"] + Vector2(cos(angle), sin(angle) * 0.6) * radius
		var heading := Vector2(-sin(angle), cos(angle) * 0.6)
		_fly_bird(bird, ground, bird["height"] + sin(Time.get_ticks_msec() / 900.0 + bird["phase"]) * 6.0, heading, delta)


## Ptak w locie: cień na ziemi, sprite wyżej o wysokość, obrócony w stronę lotu (arkusz patrzy w prawo).
func _fly_bird(bird: Dictionary, ground: Vector2, height: float, heading: Vector2, delta: float) -> void:
	var sprite: Sprite2D = bird["sprite"]
	bird["phase"] += delta * FLY_FPS
	sprite.texture = FLY
	sprite.hframes = FLY.get_width() / FLY.get_height()
	sprite.frame = int(bird["phase"]) % sprite.hframes
	sprite.flip_h = false
	sprite.position = ground - Vector2(0, height)
	sprite.rotation = heading.angle()
	(bird["shadow"] as Sprite2D).position = ground


# ---------------------------------------------------------------- kruki na ziemi
func _place_ground(group: Dictionary) -> void:
	for bird: Dictionary in group["birds"]:
		(bird["standing"] as Sprite2D).visible = true
		(bird["sprite"] as Sprite2D).visible = false
		(bird["shadow"] as Sprite2D).visible = false


func _update_group(group: Dictionary, delta: float) -> void:
	var player_near := _player != null and _player.global_position.distance_to(group["home"]) < SPOOK
	match group["state"]:
		"ground":
			for bird: Dictionary in group["birds"]:
				bird["phase"] += delta * PERCH_FPS
				var standing: Sprite2D = bird["standing"]
				standing.frame = int(bird["phase"]) % standing.hframes
			if player_near:
				group["state"] = "air"
				group["timer"] = randf_range(5.0, 9.0)
				Sfx.play_at("wing_flap", group["home"])
				Sfx.play_at("crow_caw", group["home"])
				for bird: Dictionary in group["birds"]:
					(bird["standing"] as Sprite2D).visible = false
					(bird["sprite"] as Sprite2D).visible = true
					(bird["shadow"] as Sprite2D).visible = true
					bird["height"] = 0.0
		"air":
			group["angle"] += FLOCK_SPEED / 40.0 * delta
			group["timer"] -= delta
			for bird: Dictionary in group["birds"]:
				bird["height"] = minf(bird["height"] + 60.0 * delta, 50.0 + bird["offset"])
				var angle: float = group["angle"] + bird["angle"]
				var radius: float = 34.0 + bird["offset"]
				var ground: Vector2 = group["home"] + Vector2(cos(angle), sin(angle) * 0.6) * radius
				_fly_bird(bird, ground, bird["height"], Vector2(-sin(angle), cos(angle) * 0.6), delta)
			if group["timer"] <= 0.0 and _player != null and _player.global_position.distance_to(group["home"]) > RETURN_DISTANCE:
				group["state"] = "ground"
				_place_ground(group)


# ---------------------------------------------------------------- zjawy
func _update_ghosts(delta: float) -> void:
	_ghost_timer -= delta
	if _ghost_timer <= 0.0 and _player != null and _ghosts.size() < GHOST_MAX:
		_ghost_timer = randf_range(GHOST_INTERVAL.x, GHOST_INTERVAL.y)
		_spawn_ghost()
	for i in range(_ghosts.size() - 1, -1, -1):
		var ghost: Dictionary = _ghosts[i]
		ghost["age"] += delta
		var t: float = ghost["age"] / ghost["life"]
		var sprite: Sprite2D = ghost["sprite"]
		if t >= 1.0:
			sprite.queue_free()
			_ghosts.remove_at(i)
			continue
		sprite.frame = int(ghost["age"] * GHOST_FPS) % sprite.hframes
		var base: Vector2 = (ghost["from"] as Vector2).lerp(ghost["to"], t)
		sprite.position = base + Vector2(sin(ghost["age"] * 2.3) * 3.0, -18.0 + sin(ghost["age"] * 1.7) * 4.0)
		# pojawia się i rozwiewa łagodnie
		sprite.modulate.a = GHOST_ALPHA * clampf(minf(t / 0.2, (1.0 - t) / 0.3), 0.0, 1.0)


## Duch wyłania się nad grobem w pewnej odległości od gracza i przepływa krótki odcinek w losową stronę.
func _spawn_ghost() -> void:
	var feet := _player.global_position
	var candidates := _ghost_spots.filter(func(p: Vector2) -> bool:
		var d := p.distance_to(feet)
		return d > GHOST_DISTANCE.x and d < GHOST_DISTANCE.y)
	if candidates.is_empty():
		return
	var from: Vector2 = candidates.pick_random()
	var dir := Vector2.from_angle(randf() * TAU)
	var sprite := Sprite2D.new()
	sprite.texture = GHOST
	sprite.hframes = GHOST.get_width() / GHOST.get_height()
	sprite.flip_h = dir.x < 0.0
	sprite.modulate = Color(1, 1, 1, 0.0)
	add_child(sprite)
	_ghosts.append({"sprite": sprite, "from": from, "to": from + dir * randf_range(GHOST_TRAVEL.x, GHOST_TRAVEL.y),
			"age": 0.0, "life": randf_range(GHOST_LIFE.x, GHOST_LIFE.y)})
	Sfx.play_at("ghost_wail", from, -6.0)
