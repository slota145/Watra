class_name Skarbnik
extends Harvestable
## Skarbnik w lochu (mechanika "skarbnik", stałe SKA_* w Dungeons) - jak Ultimatum w Path of Exile. Duch starego
## górnika z lampą przy kupce skarbów (krasnoludzki górnik z Kryształu Watry jako złocista zjawa - shaders/ghost).
## F otwiera ofertę (okno SkarbnikWindow): oferta czekająca u gracza (wygrana u innego Skarbnika - Player.skarbnik_offer)
## albo nowa (SkarbnikOffer.roll). Weź - nagroda do plecaka, Skarbnik znika. Wzmocnij / Przelosuj - oferta zmienia się
## od razu i trafia do księgi jako zagrożona (SkarbnikOffer.persist), a z kilku stron (bramy) nadciągają fale potworów
## klimatu lochu. Po ostatniej fali oferta jest zabezpieczona i czeka u następnego Skarbnika (Skarbnik znika, zostają
## Kości Skarbnika). Śmierć gracza albo wyjście z lochu w trakcie fal - oferta przepada.
## Drzewko Watry (Dungeon.tree_value): "ska_reroll" - darmowe przelosowania w lochu (bez Kości), "ska_again" - po
## wygranych falach szansa na kolejnego Skarbnika w wolnej komnacie, "ska_bones" - Kości wypadają częściej.
## Budowane w kodzie (Skarbnik.create), bez sceny.

const TEXTURE := preload("res://assets/crystal/miner_down.png")
const TREASURE := preload("res://assets/dungeons/mine/treasure.png")
const SHADER := preload("res://shaders/ghost.gdshader")
const TOUCH_TIME := 0.5
const COLOR := Color(1.0, 0.82, 0.35)
const GHOST := Color(1.0, 0.85, 0.5)

var dungeon: Node
## "idle" - czeka na gracza, "waves" - trwają fale, "gone" - po wszystkim.
var state := "idle"
## Oferta w ręku tego Skarbnika ({} - jeszcze nie wylosowana).
var offer := {}
## Fale: która (od 1), ile razem, siła (wzmocnienie dla poziomu potworów), zabici i wypuszczeni w tej fali.
var wave := 0
var waves := 0
var step := 0
var kills := 0
var spawned := 0
## Żywi wrogowie fal: [Goblin, id miejsca].
var attackers: Array = []
## Bramy bieżącej fali (punkty, z których wychodzą wrogowie).
var gates: Array[Vector2] = []
## Poświata z lochu (Dungeon._glow) - gaśnie, gdy Skarbnik znika.
var glow: Sprite2D
## Pomiary (tests/bench_skarbnik.gd): stała liczba żywych naraz i wrogów w fali zamiast SKA_ALIVE / SKA_WAVE_KILLS.
var alive_override := 0
var quota_override := 0
var _spawn_timer := 0.0
var _pause := 0.0
var _label: Label
var _rng := RandomNumberGenerator.new()


static func create(owner_dungeon: Node) -> Skarbnik:
	var spirit := Skarbnik.new()
	spirit.dungeon = owner_dungeon
	var treasure := Sprite2D.new()
	treasure.name = "Treasure"
	treasure.texture = TREASURE
	treasure.scale = Vector2.ONE * 0.6
	treasure.position = Vector2(20, -12)
	spirit.add_child(treasure)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 4.0)
	sprite.position = Vector2(-10, 0)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("ghost", GHOST)
	sprite.material = material
	spirit.add_child(sprite)
	return spirit


func _init() -> void:
	action_name = Lang.t("Porozmawiaj ze Skarbnikiem")
	harvest_time = TOUCH_TIME
	chip_color = COLOR
	hit_sound = ""
	break_sound = ""
	bar_height = 64.0
	bar_color = COLOR
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_rng.randomize()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", COLOR.lightened(0.4))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.02))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(190, 30)
	_label.position = Vector2(-95, -bar_height - 12.0 - _label.size.y)
	_label.z_index = 30
	if dungeon != null:
		_label.modulate = dungeon.label_boost()
	add_child(_label)
	_update_label()


func can_harvest() -> bool:
	return state == "idle"


func harvest(_from: Vector2) -> void:
	set_progress(0.0)
	if state != "idle":
		return
	show_offer()


func _player() -> Node:
	return dungeon.w.player if dungeon != null and dungeon.w != null else null


## Oferta tego Skarbnika: czekająca u gracza (po wygranej u innego) albo nowa.
func current_offer() -> Dictionary:
	if offer.is_empty():
		var player := _player()
		if player != null and not player.skarbnik_offer.is_empty():
			offer = player.skarbnik_offer
		else:
			var tier := Dungeons.config_tier(dungeon.config) if dungeon != null else 1
			offer = SkarbnikOffer.roll(dungeon.level if dungeon != null else 1, tier, _rng)
	return offer


func show_offer() -> void:
	current_offer()
	if dungeon == null or dungeon.w == null or dungeon.w.hud.get("skarbnik_window") == null:
		return
	dungeon.w.hud.skarbnik_window.open(self)


## Weź: nagroda do plecaka, oferta znika (także z księgi), Skarbnik odchodzi.
func take(index: int) -> void:
	if state != "idle" or index < 0 or index >= (offer.get("rewards", []) as Array).size():
		return
	var given := SkarbnikOffer.give(offer["rewards"][index], int(offer["step"]))
	SkarbnikOffer.forget(str(offer["uid"]))
	var player := _player()
	if player != null:
		if player.skarbnik_uid == str(offer["uid"]):
			player.skarbnik_uid = ""
			player.skarbnik_offer = {}
		player._gain_item(given[0], given[1])
	Sfx.play("pickup_rare")
	_vanish(Lang.t("Skarbnik dotrzymał słowa"))


## Wzmocnij: oferta rośnie od razu, ale jest zagrożona, dopóki gracz nie wygra fal.
func strengthen() -> void:
	if state != "idle" or not SkarbnikOffer.can_strengthen(current_offer()):
		return
	var count := SkarbnikOffer.waves_for(offer)
	SkarbnikOffer.strengthen(offer, _rng)
	_start_waves(count, int(offer["step"]))


## Darmowe przelosowania z drzewka Watry, które zostały w tym lochu (wspólne dla wszystkich Skarbników lochu).
func free_rerolls() -> int:
	if dungeon == null:
		return 0
	return int(dungeon.get_meta("ska_free_rerolls", roundi(dungeon.tree_value("ska_reroll"))))


## Przelosuj: za Kości Skarbnika (albo darmowe przelosowanie z drzewka Watry) - nowe rodzaje premii, kamieni i run;
## fale bez wzrostu siły.
func reroll() -> bool:
	var player := _player()
	if state != "idle" or player == null:
		return false
	if free_rerolls() > 0:
		dungeon.set_meta("ska_free_rerolls", free_rerolls() - 1)
	elif not player.inventory.remove_item(Dungeons.SKA_BONES, 1):
		return false
	var count := SkarbnikOffer.waves_for(current_offer(), true)
	SkarbnikOffer.reroll(offer, _rng)
	_start_waves(count, maxi(1, int(offer["step"])))
	return true


func _start_waves(count: int, strength: int) -> void:
	state = "waves"
	waves = count
	step = strength
	wave = 0
	SkarbnikOffer.persist(offer, true)
	if dungeon != null and dungeon.w != null and not dungeon.w.goblin_died.is_connected(_on_goblin_died):
		dungeon.w.goblin_died.connect(_on_goblin_died)
	var player := _player()
	if player != null and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player != null:
		player.skarbnik_uid = str(offer["uid"])
		player.skarbnik_offer = {}
	MiscVfx.summon(get_parent(), global_position, 1.2)
	Sfx.play_at("summon", global_position)
	_next_wave()
	set_process(true)


func _next_wave() -> void:
	wave += 1
	kills = 0
	spawned = 0
	_pause = 0.0
	_pick_gates()
	if dungeon != null and dungeon.w != null:
		dungeon.w.hud.show_banner(Lang.t("Fala %d/%d\nPokonaj wrogów Skarbnika") % [wave, waves], COLOR)
	_update_label()


## Wrogowie w jednej fali i żywi naraz (na bieżącej sile).
func quota() -> int:
	if quota_override > 0:
		return quota_override
	return Dungeons.SKA_WAVE_KILLS[clampi(step, 1, Dungeons.SKA_WAVE_KILLS.size()) - 1]


func alive_cap() -> int:
	if alive_override > 0:
		return alive_override
	return Dungeons.SKA_ALIVE[clampi(step, 1, Dungeons.SKA_ALIVE.size()) - 1]


## Bramy fali: kilka punktów z dala od Skarbnika, w różnych kierunkach (podłoga lochu).
func _pick_gates() -> void:
	gates.clear()
	var start := _rng.randf() * TAU
	for g in Dungeons.SKA_GATES:
		for attempt in 30:
			var angle := start + TAU * g / Dungeons.SKA_GATES + _rng.randf_range(-0.6, 0.6)
			var at := global_position + Vector2.from_angle(angle) * _rng.randf_range(Dungeons.SKA_GATE_DISTANCE.x, Dungeons.SKA_GATE_DISTANCE.y) \
					* (1.0 if attempt < 20 else 0.5)
			if _free(at):
				gates.append(at)
				break
	if gates.is_empty():
		gates.append(global_position)


func _free(at: Vector2) -> bool:
	return dungeon != null and dungeon._walkable(Vector2i((at / Dungeon.CELL).round())) and not dungeon._blocked(at, 8.0)


func _process(delta: float) -> void:
	if state != "waves":
		return
	attackers = attackers.filter(func(entry: Array) -> bool: return is_instance_valid(entry[0]) and entry[0].state != Goblin.State.DEAD)
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0:
			_next_wave()
		return
	if spawned >= quota() and attackers.is_empty():
		if wave >= waves:
			_win()
		else:
			_pause = Dungeons.SKA_WAVE_PAUSE
			if dungeon != null and dungeon.w != null:
				dungeon.w.hud.show_banner(Lang.t("Fala odparta!"), COLOR)
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = Dungeons.SKA_SPAWN_EVERY
	# po kilku naraz - setki wrogów w fali, a uzupełnianie do sufitu żywych ma być szybkie
	for i in maxi(3, alive_cap() / 10):
		if attackers.size() >= alive_cap() or spawned >= quota():
			break
		if spawn_attacker() != null:
			spawned += 1


## Nowy wróg fali przy losowej bramie - od razu rusza na gracza; null, gdy nie ma miejsca.
func spawn_attacker() -> Goblin:
	if dungeon == null or dungeon.w == null:
		return null
	var spot := Vector2.INF
	for attempt in 8:
		var at: Vector2 = gates[_rng.randi_range(0, gates.size() - 1)] + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30))
		if _free(at):
			spot = at
			break
	if spot == Vector2.INF:
		return null
	var kind: String = dungeon._pick(dungeon.climate["monsters"])
	var spawn: Dictionary = dungeon._spawn(kind, spot, global_position, dungeon.level + step * Dungeons.SKA_LEVEL_PER_STEP)
	var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if goblin == null:
		return null
	if goblin.speed <= 0.0:
		# nieruchome potwory (kokony) nie przyjdą walczyć
		goblin.state = Goblin.State.DEAD
		goblin.remove_from_group("enemies")
		dungeon.w._live_goblins.erase(spawn["id"])
		goblin.queue_free()
		return null
	goblin.xp_reward = roundi(goblin.xp_reward * Dungeons.SKA_XP)
	goblin.equipment_drop_chance *= Dungeons.SKA_ITEMS
	goblin.heart_drop_chance = 0.0
	goblin.set_meta("skarbnik", true)
	goblin.sitting = false
	if step >= Dungeons.SKA_ELITE_FROM and _rng.randf() < Dungeons.SKA_ELITE_CHANCE * (step - Dungeons.SKA_ELITE_FROM + 1):
		dungeon.elites.append(DungeonElite.promote(goblin, Dungeons.roll_elite_traits(_rng), dungeon, kind))
	goblin.appear()
	goblin.aggro()
	attackers.append([goblin, spawn["id"]])
	return goblin


func _on_goblin_died(goblin: Goblin) -> void:
	if state != "waves" or not goblin.has_meta("skarbnik"):
		return
	kills += 1
	if _rng.randf() < Dungeons.SKA_BONES_CHANCE * (1.0 + dungeon.tree_value("ska_bones")):
		dungeon._drop(goblin.global_position, Dungeons.SKA_BONES, 1)
	_update_label()


## Ostatnia fala odparta: oferta zabezpieczona w księdze, czeka u gracza na następnego Skarbnika.
func _win() -> void:
	SkarbnikOffer.persist(offer, false)
	var player := _player()
	if player != null:
		player.skarbnik_uid = str(offer["uid"])
		player.skarbnik_offer = offer
	if dungeon != null:
		dungeon._drop(global_position + Vector2(0, 18), Dungeons.SKA_BONES, 1)
		# drzewko Watry („Chciwość Skarbnika”): kolejny Skarbnik w wolnej komnacie
		if dungeon.tree_value("ska_again") > 0.0 and _rng.randf() < dungeon.tree_value("ska_again"):
			if dungeon.add_extra_skarbnik() != null:
				dungeon.w.hud.show_banner.call_deferred(Lang.t("W lochu czeka kolejny Skarbnik!"), COLOR)
	Sfx.play("quest_ready")
	_vanish(Lang.t("Fale odparte!\nOferta czeka u następnego Skarbnika"))


## Śmierć gracza w trakcie fal: oferta przepada, wrogowie fal rozwiewają się.
func _on_player_died() -> void:
	if state == "waves":
		lose()


func lose() -> void:
	if state != "waves":
		return
	SkarbnikOffer.forget(str(offer["uid"]))
	var player := _player()
	if player != null and player.skarbnik_uid == str(offer["uid"]):
		player.skarbnik_uid = ""
		player.skarbnik_offer = {}
	for entry: Array in attackers:
		var goblin: Goblin = entry[0]
		if is_instance_valid(goblin) and goblin.state != Goblin.State.DEAD:
			MiscVfx.puff(get_parent(), goblin.global_position + Vector2(0, -6), COLOR, 0.6)
			goblin.state = Goblin.State.DEAD
			goblin.remove_from_group("enemies")
			dungeon.w._live_goblins.erase(entry[1])
			goblin.queue_free()
	attackers.clear()
	_vanish(Lang.t("Skarbnik zabrał swoją ofertę"))


## Wyjście z lochu w trakcie fal liczy się jak śmierć (oferta i tak jest w księdze jako zagrożona).
func _exit_tree() -> void:
	if state == "waves":
		SkarbnikOffer.forget(str(offer["uid"]))


func _vanish(message: String) -> void:
	state = "gone"
	set_process(false)
	if dungeon != null and dungeon.w != null:
		dungeon.w.hud.show_banner(message, COLOR)
		if dungeon.w.hud.get("skarbnik_window") != null:
			dungeon.w.hud.skarbnik_window.visible = false
	if glow != null:
		glow.visible = false
	MiscVfx.puff(get_parent(), global_position + Vector2(0, -20), COLOR, 1.2)
	_update_label()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func() -> void: visible = false)


func _update_label() -> void:
	if _label == null:
		return
	match state:
		"idle":
			_label.text = Lang.t("Skarbnik")
		"waves":
			_label.text = "%s\n%s" % [Lang.t("Skarbnik - fala %d/%d") % [wave, waves],
					Lang.t("Pokonani: %d/%d") % [kills, quota()]]
		_:
			_label.visible = false


func _draw() -> void:
	super()
	if state == "gone":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 34.0, Color(COLOR, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
