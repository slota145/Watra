class_name WatraCrystal
extends Node2D
## Kryształ Watry - losowe zdarzenie w lochu (Dungeon) i jedyne, obok skarbca strażnika, źródło kamieni zaklinających
## (wbija je kowal w Ostoi). Komnata z kryształem jest pusta, dopóki gracz nie podejdzie; wtedy kryształ się budzi
## i z brzegów komnaty nadchodzą fale potworów klimatu lochu (Goblin.objective - idą bić cel, chyba że gracz jest
## blisko). Dwa warianty:
## - "crystal": trzeba obronić sam kryształ; po ostatniej fali rozpada się i wysypuje kamienie, a gdy padnie -
##   tylko garść odłamków,
## - "miners": dwaj krasnoludzcy górnicy kują kryształ kilofami, a potwory polują na nich; im więcej górników
##   przeżyje, tym więcej kamieni wykują.
## Nagroda rośnie ze stopniem lochu (doskonałe kamienie od stopnia 3, kamienie miłosierdzia od stopnia 2).

signal finished(success: bool)

const TEXTURE := preload("res://assets/crystal/crystal.png")
const TEXTURE_DIM := preload("res://assets/crystal/crystal_dim.png")
const RUBBLE := preload("res://assets/crystal/rubble.png")
const MINER_UP := preload("res://assets/crystal/miner_up.png")
const MINER_DOWN := preload("res://assets/crystal/miner_down.png")
const GLOW := Color(1.0, 0.45, 0.2, 0.7)
## Gracz budzi kryształ z tej odległości; fale, odstęp między nimi i jak długo najdłużej czekać na następną.
const WAKE_RADIUS := 90.0
const WAVES := 4
const WAVE_SIZE := 5
const WAVE_GROWTH := 3
const WAVE_DELAY := 2.5
const WAVE_TIMEOUT := 30.0
## Zdrowie kryształu i górnika - w ciosach potworów z poziomu lochu.
const CRYSTAL_HITS := 45.0
const MINER_HITS := 14.0
const MINERS := 2
## Nagroda po porażce (kryształ rozbity przez potwory) i najmniejsza po ocaleniu choćby jednego górnika.
const FAIL_REWARD := 0.35
const NAMES := {"crystal": "Kryształ Watry", "miners": "Górnicy przy Krysztale Watry"}

var dungeon: Node
var variant := "crystal"
var room := Rect2i()
var level := 1
var tier := 1
var count_mult := 1.0
var hit_radius := 14.0
var max_health := 100.0
var health := 100.0
## dormant (czeka na gracza), waves, done
var state := "dormant"
var wave := 0
var miners: Array[Node2D] = []
var _sprite: Sprite2D
var _alive: Array = []
var _wave_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(global_position)
	_sprite = Sprite2D.new()
	_set_texture(TEXTURE)
	_sprite.scale = Vector2.ONE * (0.65 if variant == "crystal" else 0.5)
	add_child(_sprite)
	max_health = Levels.damage(level) * CRYSTAL_HITS
	health = max_health
	if variant == "miners":
		for i in MINERS:
			var miner := Miner.new()
			miner.side = -1.0 if i == 0 else 1.0
			miner.position = Vector2(miner.side * 26.0, 8.0)
			miner.max_health = Levels.damage(level) * MINER_HITS
			miner.health = miner.max_health
			add_child(miner)
			miners.append(miner)


func is_alive() -> bool:
	return state != "done" and health > 0.0


## Grafika stoi podstawą na ziemi (pozycja kryształu) - także gruz, który jest niższy.
func _set_texture(texture: Texture2D) -> void:
	_sprite.texture = texture
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 4.0)


## Cios potwora w kryształ (wariant "crystal").
func take_hit(amount: int) -> void:
	if not is_alive():
		return
	health -= amount
	SkillEffects.spark(get_parent(), global_position + Vector2(0, -20), Color(1.0, 0.6, 0.3), 4)
	Sfx.play_at("hit", global_position, -6.0)
	if health <= 0.0:
		_finish(false)


## Cele, na które polują potwory z fal.
func targets() -> Array:
	if variant == "crystal":
		return [self] if is_alive() else []
	return miners.filter(func(m: Node2D) -> bool: return m.is_alive())


func _process(delta: float) -> void:
	queue_redraw()
	if dungeon == null or state == "done":
		return
	var player: Node2D = dungeon.w.player
	match state:
		"dormant":
			if player.global_position.distance_to(global_position) <= WAKE_RADIUS:
				_wake()
		"waves":
			_alive = _alive.filter(func(g) -> bool: return is_instance_valid(g) and g.state != Goblin.State.DEAD)
			if variant == "miners" and targets().is_empty():
				_finish(false)
				return
			# następna fala chwilę po pokonaniu poprzedniej albo po WAVE_TIMEOUT; po ostatniej - koniec
			_wave_timer -= delta
			if _alive.is_empty():
				if wave >= WAVES:
					_finish(true)
					return
				_wave_timer = minf(_wave_timer, WAVE_DELAY)
			if _wave_timer <= 0.0 and wave < WAVES:
				_spawn_wave()


func _wake() -> void:
	state = "waves"
	_wave_timer = WAVE_DELAY
	Sfx.play("thunder", -4.0, 0.7)
	dungeon.w.hud.show_banner(("Kryształ Watry się budzi! Obroń go przed falami potworów" if variant == "crystal"
			else "Górnicy zaczynają kuć Kryształ Watry! Obroń ich przed falami potworów"), Color(1.0, 0.65, 0.35))
	for miner in miners:
		miner.mining = true


## Kolejna fala: potwory klimatu lochu wychodzą z brzegów komnaty i idą na cel.
func _spawn_wave() -> void:
	wave += 1
	_wave_timer = WAVE_TIMEOUT
	var count := roundi((WAVE_SIZE + WAVE_GROWTH * (wave - 1)) * count_mult)
	for i in count:
		var spawn: Dictionary = dungeon._spawn(dungeon._pick(dungeon.climate["monsters"]), _edge_point(), global_position, level + 1)
		var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
		if goblin == null:
			continue
		var options := targets()
		goblin.objective = options[i % options.size()] if not options.is_empty() else null
		goblin.home = goblin.position
		goblin.state = Goblin.State.CHASE
		goblin.sitting = false
		_alive.append(goblin)
	Sfx.play("telegraph", -2.0)
	dungeon.w.hud.show_banner("Fala %d z %d" % [wave, WAVES], Color(1.0, 0.75, 0.45))


## Punkt przy brzegu komnaty, z dala od kryształu.
func _edge_point() -> Vector2:
	var cell: float = dungeon.CELL
	var from := Vector2(room.position.x, room.position.y + 1) * cell + Vector2(20, 20)
	var to := Vector2(room.end.x - 1, room.end.y - 1) * cell - Vector2(20, 20)
	var best := (from + to) / 2.0
	for attempt in 12:
		var point := Vector2(_rng.randf_range(from.x, to.x), _rng.randf_range(from.y, to.y))
		match _rng.randi() % 4:
			0:
				point.x = from.x
			1:
				point.x = to.x
			2:
				point.y = from.y
			3:
				point.y = to.y
		if point.distance_to(global_position) > 110.0:
			return point
		best = point
	return best


## Koniec zdarzenia: nagroda wg wariantu i wyniku.
func _finish(success: bool) -> void:
	if state == "done":
		return
	state = "done"
	for goblin in _alive:
		if is_instance_valid(goblin):
			goblin.objective = null
	var factor := 1.0
	if variant == "miners":
		var saved := targets().size()
		factor = maxf(float(saved) / MINERS, FAIL_REWARD) if saved > 0 else FAIL_REWARD
		success = saved > 0
		for miner in miners:
			miner.mining = false
	elif not success:
		factor = FAIL_REWARD
	_set_texture(RUBBLE if success and variant == "crystal" else TEXTURE_DIM)
	SkillEffects.shockwave(get_parent(), global_position, 70.0, Color(1.0, 0.55, 0.25))
	SkillEffects.spark(get_parent(), global_position + Vector2(0, -20), Color(1.0, 0.7, 0.35), 24)
	Sfx.play("rock_break", 2.0)
	Sfx.play("quest_ready" if success else "ui_error")
	for entry: Array in reward(tier, factor):
		dungeon._drop(global_position + Vector2(0, 18), entry[0], entry[1])
	var text := ""
	if variant == "crystal":
		text = "Kryształ Watry rozpada się w kamienie!" if success else "Potwory roztrzaskały Kryształ Watry - zostały tylko odłamki"
	else:
		text = "Górnicy wykuli kamienie z Kryształu Watry!" if success else "Górnicy polegli - zostały tylko odłamki"
	dungeon.w.hud.show_banner(text + "\nKowal w Ostoi wbije je w twój oręż", Color(1.0, 0.75, 0.4) if success else Color(1.0, 0.5, 0.4))
	finished.emit(success)


## Kamienie z kryształu: [id, ile]. `factor` - część pełnej nagrody (porażka, polegli górnicy).
static func reward(dungeon_tier: int, factor: float) -> Array:
	var result := []
	for category in ["weapon", "armor", "jewelry"]:
		result.append([Enchanting.stone_id(category, false), maxi(1, roundi(randi_range(2, 4) * factor))])
		if dungeon_tier >= 3 and randf() < (0.25 + 0.08 * dungeon_tier) * factor:
			result.append([Enchanting.stone_id(category, true), 1])
	result.append(["blessed_stone", maxi(1, roundi((6 + 4 * dungeon_tier) * factor))])
	if dungeon_tier >= 2:
		result.append(["mercy_stone", maxi(1, roundi((1 + dungeon_tier) * factor))])
	return result


func _draw() -> void:
	if state == "done":
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 30.0, Color(GLOW, 0.12 + 0.1 * pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "waves" and variant == "crystal":
		_draw_bar(Vector2(0, -56), health / max_health)


func _draw_bar(at: Vector2, fraction: float) -> void:
	var rect := Rect2(at - Vector2(18, 2), Vector2(36, 4))
	draw_rect(rect.grow(1.0), Color(0.05, 0.04, 0.05))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0.0, 1.0), rect.size.y)), Color(1.0, 0.55, 0.25))


## Krasnoludzki górnik kujący kryształ (wariant "miners") - potwory z fal na niego polują.
class Miner:
	extends Node2D

	const SWING := 0.45
	var side := 1.0
	var mining := false
	var max_health := 50.0
	var health := 50.0
	var hit_radius := 8.0
	var _sprite: Sprite2D
	var _time := 0.0

	func _ready() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = WatraCrystal.MINER_UP
		_sprite.scale = Vector2.ONE * 0.45
		_sprite.offset = Vector2(0, -WatraCrystal.MINER_UP.get_height() / 2.0 + 4.0)
		# górnik patrzy na kryształ (grafika patrzy w prawo)
		_sprite.flip_h = side > 0.0
		add_child(_sprite)

	func is_alive() -> bool:
		return health > 0.0

	func take_hit(amount: int) -> void:
		if not is_alive():
			return
		health -= amount
		SkillEffects.spark(get_parent().get_parent(), global_position + Vector2(0, -12), Color(1.0, 0.3, 0.25), 4)
		Sfx.play_at("hurt", global_position, -8.0)
		if health <= 0.0:
			mining = false
			_sprite.texture = WatraCrystal.MINER_DOWN
			_sprite.rotation = side * PI / 2.0
			_sprite.modulate = Color(0.55, 0.5, 0.5, 0.8)

	func _process(delta: float) -> void:
		queue_redraw()
		if not mining:
			return
		var before := _time
		_time += delta
		var up := fmod(_time, SWING * 2.0) < SWING
		_sprite.texture = WatraCrystal.MINER_UP if up else WatraCrystal.MINER_DOWN
		if fmod(before, SWING * 2.0) < SWING and not up:
			SkillEffects.spark(get_parent().get_parent(), global_position + Vector2(-side * 14.0, -10), Color(1.0, 0.6, 0.3), 3)
			Sfx.play_at("mine", global_position, -12.0)

	func _draw() -> void:
		if not is_alive() or not mining:
			return
		var rect := Rect2(Vector2(-10, -34), Vector2(20, 3))
		draw_rect(rect.grow(1.0), Color(0.05, 0.04, 0.05))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * health / max_health, rect.size.y)), Color(0.4, 0.9, 0.4))
