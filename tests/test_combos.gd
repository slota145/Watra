extends SceneTree
## Nowe combo (krok 4 wspólnego drzewka): Riposta po Mgnieniu (kontra na trafionych Mgnieniem), Widmowe Ostrza po
## Rozpłataniu (ostrza rozpłatują cele), Młynek po Widmowych Ostrzach (burza ostrzy), Szarża po Rozłupaniu Ziemi
## (kolce wybuchają), Deszcz Strzał po Sidłach, Grot Swaroga po Odskoku (od razu napięty), Strzała Wichru po Sokole
## (podmuch z miejsca sokoła), Kula ognia po Zamieci (pękają spowolnieni lodem), Łańcuch błyskawic po Kamieniu
## Runicznym (przeskok przez kamień), Spadająca Gwiazda po Kroku przez Mgłę (spada tam, skąd zniknęła postać)
## oraz Półksiężyc, Szybka salwa i Fala piorunów jako zwykłe umiejętności (po swoim uderzeniu darmowe i mocniejsze).

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _x := 0.0
var _at := Vector2.ZERO


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	if p == null:
		return false
	var ss = p.sword_skills
	var bs = p.bow_skills
	var sp = p.spell_skills
	var S = load("res://scripts/skills.gd")
	match _frame:
		5:
			_unlock_all(p)
			check("dawne dodatkowe ciosy to umiejętności drzewka", ["crescent", "rapid_volley", "thunder_wave"].all(
					func(id: String) -> bool: return S.get_data(id)["type"] == "skill" and load("res://scripts/hotbar.gd").can_slot_skill(id)))
			# Riposta po Mgnieniu: kontra wybucha na trafionych Mgnieniem
			_aim_at_enemy(p)
			_full(p)
			check("Mgnienie skacze", ss._jump(S.FLICKER_RANGE, p.skills.level_of("flicker"), false))
			check("Mgnienie znaczy trafionych", ss._flicker_marks.size() >= 1)
			p.note_skill("flicker")
			_hp = _enemy.health if is_instance_valid(_enemy) else 0
			check("po Mgnieniu Riposta jako combo", p.combo_after("riposte") == "flicker")
			ss.press("riposte")
			check("znaczniki zużyte", ss._flicker_marks.is_empty())
		20:
			check("kontra na trafionych Mgnieniem rani", _hurt(), "%d -> %d" % [_hp, _now()])
			ss._parry_time = 0.0
			# Widmowe Ostrza po Rozpłataniu
			_aim_at_enemy(p)
			_full(p)
			p.note_skill("rend")
			ss.press("spectral_blades")
			check("ostrza po Rozpłataniu wylatują i rozpłatują", is_instance_valid(ss._blades) and ss._blades._launched
					and ss._blades.on_hit.is_valid())
		60:
			check("rozpłatane przez ostrza", _hurt(), "%d -> %d" % [_hp, _now()])
			# Młynek po Widmowych Ostrzach: burza ostrzy
			_full(p)
			p.note_skill("spectral_blades")
			p._start_whirl()
			var blades = ss._blades
			check("burza ostrzy", is_instance_valid(blades) and blades.count >= S.BLADES_COUNT * S.BLADE_STORM_COUNT
					and blades.spin_speed > load("res://scripts/spectral_blades.gd").SPIN_SPEED)
			p._stop_whirl()
			ss._cooldowns.clear()
			# Szarża po Rozłupaniu Ziemi: kolce wybuchają
			_aim_at_enemy(p)
			_full(p)
			ss.press("ground_slam")
			check("Rozłupanie zostawia kolce", ss._spikes.size() > 0)
		80:
			_hp = _now()
			_full(p)
			p._strike_cooldown = 0.0
			check("po Rozłupaniu Szarża jako combo (nie darmowa)", p.combo_after("lunge") == "ground_slam")
			var mana: float = p.mana
			p._use_strike()
			check("kolce wybuchły", ss._spikes.is_empty() and p.mana < mana)
		100:
			check("wybuch kolców rani", _hurt(), "%d -> %d" % [_hp, _now()])
			p._lunge_time = 0.0
			# Półksiężyc bez Szarży kosztuje manę, po Szarży nie
			_full(p)
			var mana: float = p.mana
			ss._cooldowns.clear()
			p._chain_time = 0.0
			ss.press("crescent")
			check("Półksiężyc bez combo kosztuje manę", p.mana < mana and is_equal_approx(p._attack_multiplier, S.CRESCENT_DAMAGE))
		110:
			p._attack_timer = 0.0
			ss._cooldowns.clear()
			_full(p)
			p.note_skill("lunge")
			ss.press("crescent")
			check("Półksiężyc po Szarży darmowy i mocniejszy", is_equal_approx(p.mana, p.stats.max_mana())
					and p._attack_multiplier > S.CRESCENT_DAMAGE)
			# łuk
			p._attack_timer = 0.0
			p.equipment.equip("short_bow")
		115:
			# Deszcz Strzał po Sidłach: spada też na unieruchomionych wrogów
			_aim_at_enemy(p)
			_full(p)
			_enemy.set_meta("snared_until", Time.get_ticks_msec() + 5000)
			p.note_skill("snare")
			bs.press("arrow_rain")
			var rain = _find(func(n: Node) -> bool: return n.has_method("_wave"))
			check("Deszcz po Sidłach skupia się na unieruchomionych", rain != null and rain.focus)
			if rain != null:
				# krąg obok - unieruchomiony wróg poza nim, ale w zasięgu skupienia
				rain.global_position = _enemy.global_position + Vector2(rain.radius * 1.6, 0)
		150:
			check("strzały spadają na unieruchomionego", _hurt(), "%d -> %d" % [_hp, _now()])
			if is_instance_valid(_enemy):
				_enemy.remove_meta("snared_until")
			# Grot Swaroga po Odskoku: od razu w pełni napięty
			bs._cooldowns.clear()
			_full(p)
			p.note_skill("vault")
			p._held_ids["power_shot"] = true
			bs.press("power_shot")
			check("po Odskoku grot od razu napięty", is_equal_approx(bs.power_charge(), 1.0), "%.2f" % bs.power_charge())
			p._held_ids.erase("power_shot")
		155:
			check("napięty grot wylatuje", bs.power_charge() < 0.0)
			# Strzała Wichru po Sokole: podmuch też z miejsca sokoła
			bs._cooldowns.clear()
			_aim_at_enemy(p)
			_full(p)
			bs.press("falcon")
			bs._falcon.global_position = _enemy.global_position + Vector2(40, 0)
			_hp = _now()
			p.aim_override = Vector2.LEFT
			bs.press("wind_arrow")
			check("podmuch z miejsca sokoła rani (postać celuje w drugą stronę)", _hurt(), "%d -> %d" % [_hp, _now()])
			# Szybka salwa po Strzale tropiącej
			bs._cooldowns.clear()
			_full(p)
			p.note_skill("seeker")
			bs.press("rapid_volley")
			check("Szybka salwa po Strzale tropiącej darmowa", is_equal_approx(p.mana, p.stats.max_mana()) and p.cooldown_of("rapid_volley").x > 0.0)
			# księga
			p.equipment.equip("spellbook")
		165:
			# Kula ognia po Zamieci: spowolnieni lodem pękają
			_aim_at_enemy(p)
			_full(p)
			_enemy.chill(0.5, 3.0)
			_hp = _now()
			sp.fire_shatter(_enemy.global_position, 30.0, 1.0)
			check("spowolniony lodem pęka w wybuchu", _hurt(), "%d -> %d" % [_hp, _now()])
			p.note_skill("blizzard")
			check("po Zamieci Kula ognia jako combo", p.combo_after("fireball") == "blizzard")
			# Łańcuch błyskawic po Kamieniu Runicznym
			_aim_at_enemy(p)
			_full(p)
			sp._cooldowns.clear()
			sp.press("rune_stone")
			check("Kamień Runiczny stoi", sp.rune_at().is_finite())
			check("po Kamieniu Łańcuch jako combo", p.combo_after("chain_lightning") == "rune_stone")
			_hp = _now()
			p._strike_cooldown = 0.0
			p._use_strike()
		185:
			check("łańcuch przez kamień rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Fala piorunów po Łańcuchu: darmowa
			_full(p)
			sp._cooldowns.clear()
			p.note_skill("chain_lightning")
			sp.press("thunder_wave")
			check("Fala piorunów po Łańcuchu darmowa", is_equal_approx(p.mana, p.stats.max_mana()) and p.cooldown_of("thunder_wave").x > 0.0)
			# Spadająca Gwiazda po Kroku przez Mgłę: spada tam, skąd zniknęła postać
			_full(p)
			sp._cooldowns.clear()
			_at = p.global_position
			p.aim_override = Vector2(-90, 0)
			sp.press("blink")
			p.aim_override = Vector2(90, 0)
			sp.press("meteor")
			var star = _find(func(n: Node) -> bool: return n.get("skills") == sp and n.get("radius") != null and n.position.distance_to(_at) < 1.0)
			check("Gwiazda spada w miejscu zniknięcia", star != null, "%s" % _at)
		200:
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


## Wszystkie węzły drzewka (bez pustych miejsc), mnóstwo punktów.
func _unlock_all(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in Tree.nodes():
		if Tree.is_soon(id) or id == "blood_sacrifice":
			continue
		for step: String in Tree.path_to(id):
			p.skills.take(step)


func _full(p) -> void:
	p.mana = p.stats.max_mana()
	p.health = p.stats.max_health()


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


func _find(test: Callable) -> Node:
	for n in _world.player.get_parent().get_children():
		if test.call(n):
			return n
	return null


## Gracz tuż przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego.
func _aim_at_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		var spot: Vector2 = enemy.global_position + Vector2(-26, 0)
		var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -13), enemy.hurt_center(), 1)
		if space.intersect_ray(ray).is_empty():
			p.global_position = spot
			p.reset_physics_interpolation()
			p.aim_override = Vector2.RIGHT
			_enemy = enemy
			_enemy.set_physics_process(false)
			_hp = enemy.health
			return
