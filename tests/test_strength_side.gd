extends SceneTree
## Krok 5 wspólnego drzewka, strona siły: Wilczy Kieł (seria pchnięć, ostatnie ogłusza), Ryk Tura (wrogowie rzucają się
## na postać, premia do pancerza), Skok Niedźwiedzia (lot ponad przeszkodami, nietykalność, lądowanie rani),
## węzły Wciągający wir, Donośny głos, Pełnia Sił, Gniew rannego, Wstrząs i kluczowy Ostatni Bastion.

const S := preload("res://scripts/skills.gd")

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _leap_from := Vector2.ZERO


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
	var ss = p.sword_skills if p != null else null
	match _frame:
		5:
			_unlock(p)
			check("nowe umiejętności w drzewku", ["wolf_fang", "bull_roar", "bear_leap"].all(func(id: String) -> bool:
					return p.skills.level_of(id) > 0 and load("res://scripts/hotbar.gd").can_slot_skill(id)))
			check("nowe węzły do wybrania", ["whirl_pull", "loud_voice", "full_strength", "wounded_wrath", "tremor", "last_bastion"].all(
					func(id: String) -> bool: return p.skills.has_node_id(id)))
			check("Ostatni Bastion jako węzeł kluczowy", p.skills.has_keystone("last_bastion"))
			# Wilczy Kieł: 4 pchnięcia w jednego wroga, ostatnie ogłusza
			_aim_at_enemy(p, 400)
			_full(p)
			ss.press("wolf_fang")
			check("odnowienie Wilczego Kła", p.cooldown_of("wolf_fang").x > 0.0)
		40:
			check("Wilczy Kieł rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("ostatnie pchnięcie ogłusza", not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.is_stunned())
			# Ryk Tura: wróg w strachu przestaje uciekać i goni postać, pancerz rośnie
			_aim_at_enemy(p)
			_full(p)
			_enemy.fear(5.0, p.global_position)
			var armor: int = p.stats.armor()
			ss.press("bull_roar")
			check("Ryk Tura: pancerz", p.stats.armor() > armor or p.stats.temp_bonus.get("armor_percent", 0.0) > 0.0,
					"%d -> %d" % [armor, p.stats.armor()])
			check("Ryk Tura: koniec strachu", _enemy._fear_time <= 0.0)
			check("Ryk Tura w efektach", load("res://scripts/status_effects.gd").list(p).any(
					func(e: Dictionary) -> bool: return e["name"] == "Ryk Tura"))
			# Donośny głos: krótsze odnowienie okrzyków
			check("Donośny głos: odnowienie okrzyku", p.cooldown_of("bull_roar").y < S.ROAR_COOLDOWN * 0.85,
					"%.1f" % p.cooldown_of("bull_roar").y)
			# Skok Niedźwiedzia: lot w stronę celu, nietykalność, lądowanie rani
			_aim_at_enemy(p)
			_full(p)
			p.global_position = _enemy.global_position + Vector2(-110, 0)
			p.reset_physics_interpolation()
			_leap_from = p.global_position
			p.aim_override = _enemy.global_position - p.body_center()
			_hp = _enemy.health
			ss.press("bear_leap")
			check("w locie", p.is_leaping())
			var hp: int = p.health
			p._invulnerable_timer = 0.0
			p.take_damage(50, _enemy.global_position)
			check("w locie nietykalny", p.health == hp)
		80:
			p.aim_override = Vector2.RIGHT
			check("skok przeniósł postać", p.global_position.distance_to(_leap_from) > 80.0 and not p.is_leaping(),
					"%.0f" % p.global_position.distance_to(_leap_from))
			check("lądowanie rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Pełnia Sił, Gniew rannego i Ostatni Bastion
			var max_hp: int = p.stats.max_health()
			p.health = max_hp
			check("Pełnia Sił przy pełnym zdrowiu +10%", is_equal_approx(ss.health_damage_factor(), 1.1), "%.3f" % ss.health_damage_factor())
			p.health = floori(max_hp * 0.5)
			check("pół zdrowia: Gniew rannego +10%", is_equal_approx(ss.health_damage_factor(), 1.1), "%.3f" % ss.health_damage_factor())
			p.health = roundi(max_hp * 0.2)
			check("Ostatni Bastion poniżej 30% zdrowia", ss.bastion_active() and ss.health_damage_factor() > 1.6
					and is_equal_approx(ss.bastion_taken(), 0.5), "%.3f" % ss.health_damage_factor())
			check("Ostatni Bastion w efektach", load("res://scripts/status_effects.gd").list(p).any(
					func(e: Dictionary) -> bool: return e["name"] == "Ostatni Bastion"))
			p._invulnerable_timer = 0.0
			p.stats.set_temp("test", {"dodge_chance": -1.0})
			var before: int = p.health
			p.take_damage(40, p.global_position + Vector2(20, 0))
			var bastion_loss: int = before - p.health
			p.health = max_hp
			p._invulnerable_timer = 0.0
			before = p.health
			p.take_damage(40, p.global_position + Vector2(20, 0))
			var full_loss: int = before - p.health
			p.stats.set_temp("test", {})
			check("Ostatni Bastion: połowa obrażeń", bastion_loss < full_loss, "%d / %d" % [bastion_loss, full_loss])
			_full(p)
			# Wstrząs: umiejętność obszarowa miecza ogłusza, ten sam wróg nie częściej niż co TREMOR_INTERVAL
			_aim_at_enemy(p)
			_enemy._stun_time = 0.0
			ss._tremor_ready.clear()
			ss.tremor(_enemy, S.tags("ground_slam"))
			check("Wstrząs ogłusza", _enemy.is_stunned())
			_enemy._stun_time = 0.0
			ss.tremor(_enemy, S.tags("ground_slam"))
			check("Wstrząs nie co chwilę", not _enemy.is_stunned())
			_enemy._stun_time = 0.0
			ss._tremor_ready.clear()
			ss.tremor(_enemy, S.tags("lunge"))
			check("Wstrząs tylko obszarowe", not _enemy.is_stunned())
			# Wciągający wir: wróg tuż za zasięgiem Młynka jest przyciągany
			_aim_at_enemy(p)
			var radius: float = p.whirl_radius()
			_enemy.global_position = p.body_center() + Vector2(radius * 1.2 + _enemy.hurt_radius, 0) - (_enemy.hurt_center() - _enemy.global_position)
			_enemy._knockback = Vector2.ZERO
			p._start_whirl()
			p._whirl_tick = 0.0
			p._update_whirl(0.016)
			p._stop_whirl()
			check("Wciągający wir przyciąga", _enemy._knockback.x < 0.0, str(_enemy._knockback))
		90:
			print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
			return true
	return false


func _unlock(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in Tree.nodes():
		if Tree.nodes()[id]["region"] != "str" or Tree.is_soon(id) or id in ["blood_sacrifice", "cyclone_eye"]:
			continue
		for step: String in Tree.path_to(id):
			p.skills.take(step)
	p.mana = p.stats.max_mana()


func _full(p) -> void:
	p.mana = p.stats.max_mana()
	p.health = p.stats.max_health()
	p.sword_skills._cooldowns.clear()


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


## Gracz tuż przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego; `min_hp` - wróg z co najmniej tyloma
## punktami zdrowia (dużo zdrowia - zostaje żywy po serii ciosów).
func _aim_at_enemy(p, min_hp := 0) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy") or enemy.health < min_hp:
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
