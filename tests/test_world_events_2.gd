extends SceneTree
## Wydarzenia w świecie, etap 2 (Gobliński Las): losowanie z wagami (world boss rzadko), world boss Wij - zapowiedź,
## pojawienie się z ogromnym zdrowiem, podróżnicy (słabe ciosy), fazy walki, wezwanie upiorów, pokonanie (podwójne
## znaki, encyklopedia); Żmij Gorynycz - scena i animacja skrzydeł; karawana - wóz czeka na gracza i jedzie z nim, fale
## idą na wóz, zniszczenie wozu, dojazd (premia „Towar z karawany”, zniżka u kupców); święto w Ostoi - ozdoby,
## podróżnicy przy Watrze, premia „Święto”, zniżki łączone z limitem, koniec bez okna wyniku.

var _world: Node
var _frame := 0
var _fails := 0
var _site = null
var _boss = null
var _marks := 0
var _progress := 0.0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _build() -> void:
	_world._event_check = 0.0
	_world._process_events(0.01)
	_site = _world.event_site


func _away(p, from: Vector2, distance := 700.0) -> void:
	p.global_position = from + Vector2(distance, 0)
	p.reset_physics_interpolation()


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var ev = p.events
	match _frame:
		5:
			p.travelers.ensure_roster()
			p.travelers.guild_rank = 6
			for r: Dictionary in p.travelers.roster:
				r["level"] = 15
			p.stats.add_xp(40000)
			ev.next_in = 9999.0
			var types: Array[String] = ev.types_for("forest")
			check("typy w Goblińskim Lesie", "festival" in types and "caravan" in types and "world_boss" in types and not "raid" in types)
			var count := {}
			for i in 4000:
				var t: String = ev.pick_type(types)
				count[t] = int(count.get(t, 0)) + 1
			check("world boss rzadziej", int(count.get("world_boss", 0)) < int(count.get("champion", 0)) / 2, str(count))
			check("boss wg krainy", ev.world_boss_for("forest") == "wij" and ev.world_boss_for("cemetery") == "zmij")
			# world boss
			check("world boss - zapowiedź", ev.start("world_boss", "forest") and ev.active["boss"] == "wij" and float(ev.active["warn"]) > 50.0)
			_build()
			check("przed pojawieniem bez bossa", _site != null and _site.boss == null and _site.objective_text().contains("Pojawi się"))
			_away(p, _site.center)
			ev.active["warn"] = 0.0
		8:
			_boss = _site.boss
			check("world boss pojawia się", _boss != null and _boss.has_meta("world_boss") and _boss.kind == "wij"
					and _boss.max_health > 20000, str(_boss.max_health if _boss else 0))
		300:
			var travelers: Array = _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "event")
			check("gromada podróżników", travelers.size() >= 4, str(travelers.size()))
			if not travelers.is_empty():
				var t = travelers[0]
				t._target = _boss
				var before: int = _boss.health
				t._attack("melee")
				check("podróżnik bije słabo", before - _boss.health < _boss.max_health * 0.005)
			# fazy
			var phases: Array = []
			_boss.phase_changed.connect(func(phase: int) -> void: phases.append(phase))
			_boss.take_damage(roundi(_boss.max_health * 0.4), _boss.global_position)
			check("faza 2", _boss.phase == 2 and phases == [2])
			var mobs: int = _site.mobs.size()
			_site.summon_minions(_boss.global_position, 4)
			check("wezwanie upiorów", _site.mobs.size() == mobs + 4)
			_marks = p.count_owned("victory_mark")
			_site._sample = 0.0
		302:
			_boss.take_damage(_boss.health + 10, _boss.global_position)
			check("pokonany world boss", ev.active.is_empty() and ev.last_result["success"] and ev.last_result["type"] == "world_boss")
			check("podwójne znaki", p.count_owned("victory_mark") - _marks >= 6, str(p.count_owned("victory_mark") - _marks))
			check("w encyklopedii", p.codex.kills.get("world_boss_wij", 0) >= 1 if "kills" in p.codex else true)
			# Żmij - scena i animacja
			var zmij = load("res://scenes/world_boss_zmij.tscn").instantiate()
			zmij.position = p.global_position + Vector2(400, 0)
			_world.entities.add_child(zmij)
			var frames := {}
			for i in 30:
				zmij._animate(0.05)
				frames[zmij.sprite.frame] = true
			check("Żmij macha skrzydłami", zmij.kind == "zmij" and zmij.sprite.hframes == 8 and frames.size() >= 4)
			zmij.queue_free()
			# karawana
			check("karawana", ev.start("caravan", "forest"))
			_build()
			check("wóz na drodze", _site.caravan != null and _site.max_health > 0.0)
			_away(p, _site.center, 900.0)
		320:
			_site._process_caravan(0.1)
			check("wóz czeka na gracza", _site.caravan.waiting)
			_progress = _site.caravan.progress()
			p.global_position = _site.center + Vector2(40, 0)
			p.reset_physics_interpolation()
		400:
			check("wóz jedzie z graczem", _site.caravan.progress() > _progress and not _site.caravan.waiting)
			_site._wave_timer = 0.0
			_site._process_caravan(0.1)
			var raiders: Array = _site.mobs.filter(func(m) -> bool: return is_instance_valid(m) and m.objective == _site)
			check("fala idzie na wóz", raiders.size() >= 3)
			_site.take_hit(_site.max_health + 1.0)
			check("zniszczony wóz", ev.active.is_empty() and not ev.last_result["success"])
			# dojazd
			ev.start("caravan", "forest")
			_build()
			p.global_position = _site.center + Vector2(30, 0)
			p.reset_physics_interpolation()
			ev.add_points("Ty", 50.0)
			_site.caravan._distance = _site.caravan._length + 100.0
		403:
			check("dojazd karawany", ev.last_result.get("type", "") == "caravan" and ev.last_result["success"])
			check("premia z karawany", p.boons.has_group("trade") and p.boons.discounted(100) == 85)
			# święto
			for e in _world.get_tree().get_nodes_in_group("enemies"):
				if e.has_meta("event"):
					e.queue_free()
			check("święto", ev.start("festival", "forest"))
			_build()
			var s = _world._settlement
			check("ozdoby i święto w Ostoi", s.is_festival() and s._festival.size() >= 10)
			check("podróżnicy przy Watrze", s.traveler_points().all(func(pt: Vector2) -> bool:
				return pt.distance_to(s._px(s.WATRA_POS)) < 120.0))
			check("premia święta", p.boons.has_group("festival") and p.stats.xp_multiplier() >= 1.2)
			check("zniżki łączone z limitem", p.boons.discounted(100) == 65)
			check("panel święta", _site.objective_text().contains("Watrze"))
			_world.hud.event_result.visible = false
			ev.active["left"] = 0.0
		405:
			check("koniec święta bez okna wyniku", ev.active.is_empty() and not _world._settlement.is_festival()
					and not _world.hud.event_result.visible)
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
