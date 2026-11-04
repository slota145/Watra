extends SceneTree
## Pomiar siły postaci z prawdziwego zapisu w lochu Nawii: wczytuje zapis, wchodzi do lochu stopnia T, wypisuje
## statystyki gracza i potworów, a potem bot walczy przez S sekund (wskakuje w najbliższą gromadę, używa
## umiejętności z paska) i mierzy: zadane obrażenia na sekundę, zabójstwa, ilu wrogów trafia naraz,
## otrzymane obrażenia na sekundę i ile razy zszedłby poniżej 25% zdrowia (zdrowie jest wtedy uzupełniane).
## Użycie: -s tests/endgame_probe.gd -- <zapis.json> <stopień> <sekundy> [tryb] [poziom postaci] [poziom ekwipunku]
## Poziom ekwipunku (np. 90): ekwipunek z zapisu zastąpiony rzadkimi przedmiotami tego poziomu (bez zaklęć) -
## porównanie z graczem, który zmienia ekwipunek na bieżąco. Siódmy argument: dodatkowa odporność na żywioły (np. 1.35 -
## gracz zbierający odporności do sufitu mimo kary Nawii; na Nawię 60% tego). Ósmy: klimat lochu (domyślnie catacombs), dziewiąty: modyfikatory za żar po przecinku (np. scorch,curse; "-" - bez), dziesiąty: dodatkowe premie postaci.
## Tryby: whirl (sam Młynek), flicker (samo Mgnienie), full (cały pasek miecza + Dymne Wybuchy pod E), idle (stoi),
## bow / spell (pasek łuku / księgi z zapisu, broń zastąpiona rzadkim łukiem / księgą poziomu ekwipunku albo 51.,
## punkty siły przeniesione do zręczności / inteligencji),
## bow_kite / spell_kite (to samo, ale bot trzyma dystans - odchodzi od gromady i krąży po komnacie), uro (Uroczysko: bot otwiera krąg i walczy jak full, aż krąg zgaśnie - upiory naraz, zabici, runy, czas).

var _world: Node
var _args: PackedStringArray
var _mode := "full"
var _seconds := 40.0
var _frame := 0
var _time := 0.0
var _last_hp := {}
var _dealt := 0.0
var _kills := 0
var _hits_frames := 0
var _hit_enemies := 0
var _taken := 0.0
var _healed := 0.0
var _low := 0
var _player_hp := 0
var _engaged := 0.0
var _cd := {}
var _smoke_hold := 0.0
var Sk
## Łucznik / mag trzyma dystans (tryby bow_kite, spell_kite): ucieka od gromady i krąży po komnacie.
var _kite := false
var _uro := false
var _stone: Node
var _ghost_sum := 0.0
var _ghost_max := 0
var _crowd := 0
var _crowd_frames := 0
var Lv
var _boss


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	seed(1)
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_args[0]))
	var tier := int(_args[1])
	_seconds = float(_args[2])
	if _args.size() > 3:
		_mode = _args[3]
	if _mode.ends_with("_kite"):
		_mode = _mode.trim_suffix("_kite")
		_kite = true
	var p: Dictionary = save["player"]
	p["stats"]["attribute_rules"] = 2
	if _args.size() > 4:
		p["stats"]["level"] = int(_args[4])
	p.erase("position")
	p["health"] = 999999
	p["mana"] = 999999.0
	var uro := _mode == "uro"
	if uro:
		_mode = "full"
		_uro = true
	if _mode in ["bow", "spell"]:
		var attrs: Dictionary = p["stats"]["attributes"]
		attrs["dexterity" if _mode == "bow" else "intelligence"] = int(attrs.get("strength", 0))
		attrs["strength"] = 0
	if _mode == "full":
		p["hotbar"]["skills"]["melee"][3] = "smoke_burst"
	var game := root.get_node("Game")
	game.save_path = "user://test_savegame.json"
	game._pending_load = {"seed": int(save["seed"]), "zone": "dungeon", "player": p,
			"dungeon": {"climate": _args[7] if _args.size() > 7 else "catacombs", "tier": tier, "mods": Array(_args[8].split(",")) if _args.size() > 8 and _args[8] != "-" else [], "seed": 777, "mechanics": ["uroczysko"] if uro else []}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func _load_classes() -> void:
	Sk = load("res://scripts/skills.gd")
	Lv = load("res://scripts/levels.gd")
	_boss = load("res://scripts/boss.gd")


## Linie przedmiotów dla postaci z siłą (wojownik z buławą).
const GEAR_LINES := {"weapon": "mace", "helmet": "helm", "chest": "plate", "gloves": "gauntlets", "boots": "greaves",
		"belt": "girdle", "ring_1": "signet", "ring_2": "signet", "earring_1": "fang", "earring_2": "fang", "necklace": "amulet"}


## Łucznik (zręczność) i mag (inteligencja).
const GEAR_BOW := {"weapon": "bow", "helmet": "hood", "chest": "jerkin", "gloves": "gloves", "boots": "boots",
		"belt": "belt", "ring_1": "band", "ring_2": "band", "earring_1": "stud", "earring_2": "stud", "necklace": "amulet"}
const GEAR_SPELL := {"weapon": "book", "helmet": "hood", "chest": "robe", "gloves": "gloves", "boots": "boots",
		"belt": "belt", "ring_1": "band", "ring_2": "band", "earring_1": "stud", "earring_2": "stud", "necklace": "amulet"}


func _gear_lines() -> Dictionary:
	return GEAR_BOW if _mode == "bow" else (GEAR_SPELL if _mode == "spell" else GEAR_LINES)


func _regear(pl, item_level: int, only_weapon := false) -> void:
	var loot = load("res://scripts/loot.gd")
	var lines := _gear_lines()
	for slot: String in lines:
		if only_weapon and slot != "weapon":
			continue
		var id: String = loot.generate(loot.base_for(lines[slot], item_level), "rare", item_level)
		pl.equipment.equip_to(slot, id)


func _avg_hit(pl, mult: float, tags: Array) -> float:
	var s = pl.stats
	return (s.damage_min() + s.damage_max()) / 2.0 * mult * s.kind_multiplier(tags) * pl.legendary.damage_multiplier() \
			* s.damage_multiplier() * (1.0 + s.crit_chance() * (s.crit_multiplier() - 1.0))


func _report_static(pl) -> void:
	var s = pl.stats
	print("POSTAC poziom %d  zdrowie %d  mana %d  pancerz %d  redukcja %.0f%% (pancerz %.0f%%, siła %.0f%%)  unik %.0f%%" % [
			s.level, s.max_health(), s.max_mana(), s.armor(), s.damage_reduction() * 100, s.armor_reduction() * 100,
			s.strength_reduction() * 100, s.dodge_chance() * 100])
	print("  broń %d-%d  kryt %.0f%% x%.2f  szybkość ataku %.2f  rzucania %.2f  broni %.2f  życie za trafienie %d  regen zdr %.1f/s many %.1f/s" % [
			s.damage_min(), s.damage_max(), s.crit_chance() * 100, s.crit_multiplier(), s.attack_speed(), s.cast_speed(),
			s.weapon_speed(), s.life_on_hit(), s.health_regen() + pl.skills.regen("health_regen", "melee", s.max_health()),
			s.mana_regen() + pl.skills.regen("mana_regen", "melee", s.max_mana())])
	print("  mnożniki: rodzaj (młynek) %.2f  legendy %.2f  zwiększone obr. %.2f  siła %d  zręczność %d  inteligencja %d" % [
			s.kind_multiplier(Sk.tags("whirlwind")), pl.legendary.damage_multiplier(), s.damage_multiplier(),
			s.attribute("strength"), s.attribute("dexterity"), s.attribute("intelligence")])
	var wl: int = pl.skills.level_of("whirlwind")
	var whirl: float = Sk.whirlwind_damage(wl) * (1.0 + pl.skills.tree_bonus("melee", "whirl_damage"))
	print("  młynek poz. %d: cios %.0f (średnio z krytem) co %.2f s, promień %.0f" % [wl, _avg_hit(pl, whirl, Sk.tags("whirlwind")),
			Sk.WHIRLWIND_TICK / pl._skill_speed(), pl.whirl_radius()])
	var fl: int = pl.skills.level_of("flicker")
	print("  mgnienie poz. %d: cios %.0f" % [fl, _avg_hit(pl, Sk.flicker_damage(fl), Sk.tags("flicker"))])
	print("  odporności: ogień %d%%  lód %d%%  pioruny %d%%  Nawia %d%%  (kara %d%%)" % [pl.stats.resistance("fire") * 100,
			pl.stats.resistance("cold") * 100, pl.stats.resistance("lightning") * 100, pl.stats.resistance("nawia") * 100,
			load("res://scripts/elements.gd").penalty * 100])
	print("  legendy/efekty: ", pl.equipment.effects() if pl.equipment.has_method("effects") else "")
	var enemies := get_nodes_in_group("enemies")
	var hp := 0.0
	var dmg := 0.0
	var lv := 0.0
	var n := 0
	for e in enemies:
		if is_instance_of(e, _boss):
			continue
		hp += e.max_health
		dmg += e.damage
		lv += e.level
		n += 1
	if n > 0:
		print("POTWORY w lochu: %d  poziom %.1f  zdrowie %.0f  obrażenia ciosu %.0f (po redukcji %.0f)" % [n, lv / n, hp / n, dmg / n,
				dmg / n * (1.0 - s.damage_reduction())])
	print("  Levels: zdrowie(L) %.0f  obrażenia(L) %.0f" % [Lv.health(roundi(lv / maxi(n, 1))), Lv.damage(roundi(lv / maxi(n, 1)))])


func _nearest(pl) -> Node2D:
	var best: Node2D = null
	var bd := INF
	for e in get_nodes_in_group("enemies"):
		if e.state == e.State.DEAD:
			continue
		var d: float = e.global_position.distance_squared_to(pl.global_position)
		if d < bd:
			bd = d
			best = e
	return best


## Gromada: co 0,5 s dociąga żywych wrogów, aż w promieniu 90 px stoi PACK wrogów (jak zebrana grupa w lochu).
const PACK := 8
var _pack_timer := 0.0
var _arena := Vector2.ZERO
var _frame_us := 0
var _frame_sum := 0.0
var _frame_max := 0.0
var _frames := 0
var _probe_t0 := 0
var _probe_us := 0.0


## Uroczysko: postać przy kamieniu, krąg otwarty od razu; koniec pomiaru, gdy krąg zgaśnie.
func _keep_uro(pl) -> void:
	if _stone == null:
		_stone = _world._dungeon.uroczyska[0]
		_arena = _stone.global_position + Vector2(0, 30)
		pl.global_position = _arena
		pl.reset_physics_interpolation()
		for e in get_nodes_in_group("enemies"):
			if e.global_position.distance_to(_arena) < 500.0 and not is_instance_of(e, _boss):
				e.queue_free()
		_stone.open()
	if pl.global_position.distance_to(_arena) > 120.0:
		pl.global_position = _arena
		pl.reset_physics_interpolation()
	_ghost_sum += _stone.ghosts.size()
	_ghost_max = maxi(_ghost_max, _stone.ghosts.size())
	if _stone.state == "closed":
		_seconds = _time


func _keep_pack(pl) -> void:
	_pack_timer -= get_root().get_process_delta_time()
	if _pack_timer > 0.0:
		return
	_pack_timer = 0.5
	# walka w środku największej komnaty - gdy postać odskoczy (Mgnienie, zryw), wraca na środek
	if _arena == Vector2.ZERO:
		var best: Rect2i = _world._dungeon.rooms[0]
		for room: Rect2i in _world._dungeon.rooms:
			if room.get_area() > best.get_area():
				best = room
		_arena = (Vector2(best.position) + Vector2(best.size) / 2.0) * 64.0
		pl.global_position = _arena
		pl.reset_physics_interpolation()
	if pl.global_position.distance_to(_arena) > (320.0 if _kite else 120.0):
		pl.global_position = _arena
		pl.reset_physics_interpolation()
	var near := 0
	var far: Array = []
	for e in get_nodes_in_group("enemies"):
		if e.state == e.State.DEAD or is_instance_of(e, _boss):
			continue
		if e.global_position.distance_to(pl.global_position) < (260.0 if _kite else 90.0):
			near += 1
		else:
			far.append(e)
	far.shuffle()
	for e in far.slice(0, maxi(PACK - near, 0)):
		e.global_position = (pl.global_position + Vector2.from_angle(randf() * TAU) * randf_range(170.0, 230.0)) if _kite \
				else _arena + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 80.0)
		e.reset_physics_interpolation()
		e.home = e.global_position
		e.leash_radius = 100000.0
		e.aggro()


func _press(pl, i: int) -> void:
	pl._press_slot(i)


func _release(pl, i: int) -> void:
	pl._held_slots[i] = false
	pl._update_held_slots()


func _process(delta: float) -> bool:
	if _world == null or not _world.is_inside_tree() or _world._dungeon == null:
		return false
	var pl = _world.player
	_frame += 1
	if _frame == 5:
		_load_classes()
		if _args.size() > 5 and int(_args[5]) > 0:
			_regear(pl, int(_args[5]))
		elif _mode in ["bow", "spell"]:
			_regear(pl, 51, true)
		# dziesiąty argument: dodatkowe premie postaci "premia=wartość,..." (np. shock_chance=0.3,freeze_chance=0.3)
		if _args.size() > 9:
			var extra := {}
			for pair in _args[9].split(","):
				var kv := pair.split("=")
				if kv.size() == 2:
					extra[kv[0]] = float(kv[1])
			pl.stats.set_temp("probe_extra", extra)
		if _args.size() > 6 and float(_args[6]) > 0.0:
			pl.stats.set_temp("probe_res", {"all_resistances": float(_args[6]), "nawia_resistance": float(_args[6]) * 0.6})
		_report_static(pl)
		pl.health = pl.stats.max_health()
		pl.mana = pl.stats.max_mana()
		_player_hp = pl.health
		_kills = _world.hud.kills
	if _frame < 5:
		return false
	_time += delta
	var now := Time.get_ticks_usec()
	if _frame_us > 0:
		var ms := (now - _frame_us) / 1000.0
		_frame_sum += ms
		_frame_max = maxf(_frame_max, ms)
		_frames += 1
	_frame_us = now
	_probe_t0 = Time.get_ticks_usec()
	# obrażenia zadane: spadek zdrowia wrogów od poprzedniej klatki
	var hit_now := 0
	var alive := {}
	for e in get_nodes_in_group("enemies"):
		alive[e] = true
		var h: float = maxf(e.health, 0)
		if _last_hp.has(e):
			var d: float = _last_hp[e] - h
			if d > 0:
				_dealt += d
				hit_now += 1
		_last_hp[e] = h
	for e in _last_hp.keys():
		if not alive.has(e):
			_last_hp.erase(e)
	var close := 0
	for e in alive:
		if e.state != e.State.DEAD and e.global_position.distance_to(pl.global_position) < 50.0:
			close += 1
	_crowd += close
	_crowd_frames += 1
	if hit_now > 0:
		_hits_frames += 1
		_hit_enemies += hit_now
	# zdrowie gracza
	var diff: int = pl.health - _player_hp
	if diff < 0:
		_taken -= diff
	else:
		_healed += diff
	if pl.is_dead or pl.health < pl.stats.max_health() * 0.25:
		_low += 1
		pl.is_dead = false
		pl.health = pl.stats.max_health()
	_player_hp = pl.health
	# łup sprząta się co sekundę (gracz go zbiera) - inaczej setki leżących przedmiotów zawyżałyby czas klatki
	if _frame % 60 == 0:
		for pickup in get_nodes_in_group("pickups"):
			pickup.queue_free()
	if _uro:
		_keep_uro(pl)
	else:
		_keep_pack(pl)
	# bot: do najbliższego wroga, a gdy daleko - skok w jego pobliże
	var target := _nearest(pl)
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	if target != null:
		var to: Vector2 = target.global_position - pl.global_position
		if to.length() > 400.0:
			pl.global_position = target.global_position + Vector2(randf_range(-30, 30), 40)
			pl.reset_physics_interpolation()
		elif _kite:
			_kite_move(pl)
		elif to.length() > 20.0:
			if to.x < -8: Input.action_press("move_left")
			if to.x > 8: Input.action_press("move_right")
			if to.y < -8: Input.action_press("move_up")
			if to.y > 8: Input.action_press("move_down")
		if to.length() < 120.0:
			_engaged += delta
		pl.aim_override = to if to != Vector2.ZERO else Vector2.RIGHT
		_bot(pl, delta, to.length())
	_probe_us += Time.get_ticks_usec() - _probe_t0
	if _time >= _seconds:
		_finish(pl)
	return false


func _bot(pl, delta: float, dist: float) -> void:
	if _mode == "idle":
		return
	for k in _cd:
		_cd[k] -= delta
	if _mode in ["bow", "spell"]:
		_bot_ranged(pl, dist)
		return
	var near := dist < 140.0
	if _mode in ["whirl", "full"]:
		if near and not pl._held_slots[1]:
			_press(pl, 1)
		elif not near and pl._held_slots[1]:
			_release(pl, 1)
	if _mode in ["flicker", "full"] and near and _cd.get("flicker", 0.0) <= 0.0:
		_cd["flicker"] = 0.35
		_press(pl, 0)
		_release(pl, 0)
	if _mode == "full" and near:
		for i in [2, 4, 5, 6]:
			if _cd.get(i, 0.0) <= 0.0 and pl.cooldown_of(pl.hotbar.entry("melee", i)).x <= 0.0:
				_cd[i] = 1.0
				_press(pl, i)
				_release(pl, i)
		# Dymne Wybuchy: trzymane 1,35 s (pełne ładowanie), potem puszczone
		if _smoke_hold <= 0.0 and _cd.get("smoke", 0.0) <= 0.0:
			_smoke_hold = 1.4
			_press(pl, 3)
		elif _smoke_hold > 0.0:
			_smoke_hold -= delta
			if _smoke_hold <= 0.0:
				_release(pl, 3)
				_cd["smoke"] = 3.0


## Ucieczka od gromady: od środka wrogów bliżej niż 130 px, z ruchem po okręgu (żeby nie utknąć w rogu) i powrotem
## ku środkowi komnaty, gdy postać od niego odejdzie; nikogo blisko - stoi i strzela.
func _kite_move(pl) -> void:
	var center := Vector2.ZERO
	var close := 0
	for e in get_nodes_in_group("enemies"):
		if e.state != e.State.DEAD and e.global_position.distance_to(pl.global_position) < 130.0:
			center += e.global_position
			close += 1
	if close == 0:
		return
	var away: Vector2 = (pl.global_position - center / close).normalized()
	var dir := away + away.orthogonal() * 0.8
	var home: Vector2 = _arena - pl.global_position
	if home.length() > 150.0:
		dir += home.normalized() * 1.2
	if dir.x < -0.35: Input.action_press("move_left")
	if dir.x > 0.35: Input.action_press("move_right")
	if dir.y < -0.35: Input.action_press("move_up")
	if dir.y > 0.35: Input.action_press("move_down")


## Łuk i księga: zwykły atak trzymany, reszta paska po kolei, gdy gotowa (trzymana chwilę - ładowane strzały).
func _bot_ranged(pl, dist: float) -> void:
	var near := dist < 260.0
	if near and not pl._held_slots[0]:
		_press(pl, 0)
	elif not near and pl._held_slots[0]:
		_release(pl, 0)
	if not near:
		return
	for i in range(1, 7):
		var id: String = pl.hotbar.entry(pl.stats.weapon_type(), i)
		if id == "":
			continue
		if pl._held_slots[i]:
			if _cd.get(i, 0.0) <= 0.7:
				_release(pl, i)
			continue
		if _cd.get(i, 0.0) <= 0.0 and pl.cooldown_of(id).x <= 0.0:
			_cd[i] = 1.0
			_press(pl, i)


func _finish(pl) -> void:
	if _uro:
		print("UROCZYSKO: trwało %.0f s, zabitych %d, upiorów naraz średnio %.1f (najwięcej %d), runy %d, największy krąg %.0f" % [
				_time, _stone.kills, _ghost_sum / maxi(_frames, 1), _ghost_max, _stone.reward_runes(_stone.kills), _stone.best_radius])
	var t := _time
	_kills = _world.hud.kills - _kills
	print("WALKA tryb %s, %.0f s (w zwarciu %.0f s): obrażenia/s %.0f  zabójstw %d (%.1f/s)  trafionych naraz %.1f  wrogów przy graczu (<50 px) %.1f" % [
			_mode, t, _engaged, _dealt / t, _kills, _kills / t, float(_hit_enemies) / maxi(_hits_frames, 1), float(_crowd) / maxi(_crowd_frames, 1)])
	print("  otrzymane/s %.0f  leczenie/s %.0f  zdrowie %d  -> bez leczenia pada po %.1f s, zejść poniżej 25%%: %d" % [
			_taken / t, _healed / t, pl.stats.max_health(), pl.stats.max_health() / maxf(_taken / t, 0.01), _low])
	print("  klatka średnio %.1f ms, najdłuższa %.1f ms (z tego pomiar %.1f ms), łupu na ziemi %d, węzłów %d, wrogów w lochu %d" % [_frame_sum / maxi(_frames, 1), _frame_max, _probe_us / 1000.0 / maxi(_frames, 1), get_nodes_in_group("pickups").size(), get_node_count(), get_nodes_in_group("enemies").size()])
	quit()
