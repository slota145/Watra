extends SceneTree
## Krok 5 wspólnego drzewka, przywołania: Wataha (łuk), Błędne Ogniki (księga), Wierny tropiciel (węzeł Strzały
## tropiącej) - stali przywołańcy rezerwujący manę (Summons, SummonData, SkillBook.summons), węzły Przewodnik stada
## i Wierne ogniki, zdrowie przywołańców i cel dla potworów (Goblin.objective), zapis gry.

const S := preload("res://scripts/skills.gd")
const SD := preload("res://scripts/summon_data.gd")

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _full_mana := 0.0


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
	match _frame:
		5:
			var Tree = load("res://scripts/skill_tree.gd")
			check("dane: przywołania", SD.is_summon("wolf_pack") and SD.is_summon("wisps") and SD.is_summon("seeker"))
			check("Wataha z łukiem, Ogniki z księgą", S.works_with("wolf_pack", "bow") and not S.works_with("wolf_pack", "spell")
					and S.works_with("wisps", "spell") and not S.works_with("wisps", "bow"))
			check("tagi przywołań", "summon" in S.tags("wolf_pack") and "summon" in S.tags("wisps") and "fire" in S.tags("wisps"))
			check("gniazda na kamienie wsparcia", load("res://scripts/supports.gd").has_sockets("wolf_pack") and load("res://scripts/supports.gd").has_sockets("wisps"))
			check("węzły już nie są pustymi miejscami", ["wolf_pack", "pack_leader", "wisps", "loyal_wisps", "loyal_seeker"].all(
					func(id: String) -> bool: return not Tree.is_soon(id)))
			check("rezerwacja maleje z poziomem", SD.reserve("wolf_pack", 20) < SD.reserve("wolf_pack", 1))
			check("liczba rośnie z poziomem", SD.count("wolf_pack", 20) == SD.count("wolf_pack", 1) + 2)
			check("siła i zdrowie rosną z poziomem", SD.damage("wisps", 10) > SD.damage("wisps", 1)
					and SD.health_share("wolf_pack", 10) > SD.health_share("wolf_pack", 1))
			_unlock(p)
			check("umiejętności i węzły wybrane", p.skills.level_of("wolf_pack") > 0 and p.skills.level_of("wisps") > 0
					and ["pack_leader", "loyal_wisps", "loyal_seeker"].all(func(id: String) -> bool: return p.skills.has_node_id(id)))
			check("Przewodnik stada: +1 wilk", p.skills.summon_count("wolf_pack") == SD.count("wolf_pack", 1) + 1,
					str(p.skills.summon_count("wolf_pack")))
			# Wataha z łukiem
			p.equipment.equip("short_bow")
			_aim_at_enemy(p)
			_full_mana = p.stats.full_max_mana()
			p.mana = p.stats.max_mana()
			p._press_slot(_put(p, "wolf_pack"))
			check("Wataha przywołana", p.skills.summons.has("wolf_pack"))
			check("rezerwuje manę", absf(p.stats.max_mana() - _full_mana * (1.0 - p.skills.aura_reserve("wolf_pack"))) <= 1.0,
					"%d z %d" % [p.stats.max_mana(), _full_mana])
		8:
			check("wilki się pojawiają", p.summons.alive("wolf_pack").size() == p.skills.summon_count("wolf_pack"),
					str(p.summons.alive("wolf_pack").size()))
		90:
			check("wilki gryzą wroga", _hurt(), "%d -> %d" % [_hp, _now()])
			check("wróg bierze wilka za cel", _taunted(p.summons.alive("wolf_pack")))
			# zabity wilk wraca po czasie
			var wolf = p.summons.alive("wolf_pack")[0]
			wolf.take_hit(wolf.max_health * 10.0)
		92:
			check("zabity wilk znika", p.summons.alive("wolf_pack").size() == p.skills.summon_count("wolf_pack") - 1)
			check("i czeka na powrót", p.summons._respawn["wolf_pack"].size() == 1)
			# zapis gry
			var data: Dictionary = p.skills.get_save_data()
			check("zapis trzyma przywołania", data.get("summons", []).has("wolf_pack"))
			# odesłanie tym samym klawiszem
			p._press_slot(4)
			check("Wataha odesłana", not p.skills.summons.has("wolf_pack"))
			check("mana wraca", absf(p.stats.max_mana() - _full_mana) <= 1.0)
		95:
			check("wilki odeszły", p.summons.alive("wolf_pack").is_empty() and p.summons._respawn["wolf_pack"].is_empty())
			# Wierny tropiciel: klawisz Strzały tropiącej przywołuje widmową strzałę
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p._press_slot(_put(p, "seeker"))
			check("Wierny tropiciel przywołany", p.skills.summons.has("seeker"))
			check("rezerwuje 15% many", absf(SD.reserve("seeker", 20) - 0.15) < 0.001)
		98:
			check("widmowa strzała krąży", p.summons.alive("seeker").size() == 1)
		200:
			check("tropiciel sam strzela", _seekers() > 0 or _hurt(), "%d -> %d" % [_hp, _now()])
			# zmiana broni: przywołania łuku odchodzą
			p.skills.set_summon("wolf_pack", true)
			p.equipment.equip("spellbook")
		203:
			check("po zmianie broni przywołania łuku odchodzą", p.skills.summons.is_empty() and p.summons.alive("seeker").is_empty()
					and p.summons.alive("wolf_pack").is_empty())
			# Błędne Ogniki z księgą
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p._press_slot(_put(p, "wisps"))
			check("Ogniki przywołane", p.skills.summons.has("wisps"))
		206:
			check("Wierne ogniki: +1 ognik", p.summons.alive("wisps").size() == SD.count("wisps", p.skills.level_of("wisps")) + 1,
					str(p.summons.alive("wisps").size()))
		300:
			check("ogniki ranią wroga", _hurt(), "%d -> %d" % [_hp, _now()])
			# za mało many na kolejne przywołanie
			p.skills.set_summon("wisps", false)
			p.mana = 1.0
			p._press_slot(4)
			check("bez many nie przywoła", not p.skills.summons.has("wisps"))
			# wczytanie zapisu z przywołaniem
			var data: Dictionary = p.skills.get_save_data()
			data["summons"] = ["wisps", "nieznane"]
			p.skills.load_save_data(data)
			check("wczytany zapis przywołuje", p.skills.summons == ["wisps"], str(p.skills.summons))
		303:
			check("ogniki z zapisu wracają", p.summons.alive("wisps").size() > 0)
			# refund węzła: przywołanie znika
			p.skills.refund("loyal_seeker")
			check("bez węzła tropiciel niedostępny", not p.skills.can_summon("seeker"))
		305:
			print("WYNIK: %s" % ("OK" if _fails == 0 else "%d FAIL" % _fails))
			quit(1 if _fails > 0 else 0)
	return false


func _unlock(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in ["wolf_pack", "pack_leader", "wisps", "loyal_wisps", "loyal_seeker", "seeker"]:
		for step: String in Tree.path_to(id):
			p.skills.take(step)
	p.mana = p.stats.max_mana()


func _put(p, id: String) -> int:
	p.hotbar.put(p.stats.weapon_type(), 4, id)
	return 4


func _seekers() -> int:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return n.get_script() != null and n.get_script().resource_path.ends_with("seeker_arrow.gd")).size()


## Wrogowie wokół gracza (przywołańcy biorą najbliższego, niekoniecznie tego przed graczem).
var _near: Array = []


## Suma zdrowia wrogów wokół gracza (zabity liczy się jako 0).
func _now() -> int:
	var total := 0
	for enemy in _near:
		if is_instance_valid(enemy) and enemy.state != 4:
			total += enemy.health
	return total


## Czy któryś wróg wokół gracza wziął za cel któregoś z przywołańców.
func _taunted(minions: Array) -> bool:
	for enemy in _near:
		if is_instance_valid(enemy) and enemy.state != 4 and is_instance_valid(enemy.objective) and enemy.objective in minions:
			return true
	return false


func _hurt() -> bool:
	return _now() < _hp


## Gracz przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego.
func _aim_at_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		var spot: Vector2 = enemy.global_position + Vector2(-60, 0)
		var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -9), enemy.hurt_center(), 1)
		if space.intersect_ray(ray).is_empty():
			p.global_position = spot
			p.reset_physics_interpolation()
			p.aim_override = Vector2.RIGHT
			_enemy = enemy
			_near.clear()
			for other in _world.get_tree().get_nodes_in_group("enemies"):
				if other.state != 4 and other.global_position.distance_to(spot) < 260.0:
					other.set_physics_process(false)
					other.health = other.max_health * 20
					_near.append(other)
			_hp = _now()
			return
