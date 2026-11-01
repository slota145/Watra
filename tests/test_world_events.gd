extends SceneTree
## Wydarzenia w świecie (WorldEvents, EventSite) w Rozlewiskach: czempion (cecha, wkład gracza i podróżników,
## przybywający podróżnicy, sukces - ranking, Znaki Zwycięstwa, sława, skrzynia), deszcz meteorytów (meteoryt rani
## i zostawia skałę, rozbicie daje punkty), najazd na kapliczkę (fale idą na kapliczkę, porażka gasi kapliczkę -
## bez teleportu), polowanie na Hydrę (wzmocniony boss), czempion po czasie odchodzi, wydarzenie w innej krainie
## rozstrzyga się samo, zapis, wymiana znaków u pisarza gildii, harmonogram.

var _world: Node
var _frame := 0
var _fails := 0
var _site = null
var _champion = null
var _gold := 0
var _fame := 0
var _marks := 0
var _boss_health := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "swamp", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _away(p, from: Vector2) -> void:
	p.global_position = from + Vector2(700, 0)
	p.reset_physics_interpolation()


## Świat stawia wydarzenie od razu (bez czekania na sprawdzenie co pół sekundy).
func _build() -> void:
	_world._event_check = 0.0
	_world._process_events(0.01)


func _event_travelers() -> Array:
	return _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "event")


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var ev = p.events
	match _frame:
		5:
			p.travelers.ensure_roster()
			p.quests.states["village_help"] = "done"
			p.travelers.guild_rank = 3
			for r: Dictionary in p.travelers.roster:
				r["level"] = 20
			p.stats.add_xp(400000)
			ev.next_in = 9999.0
			check("typy wydarzeń w Rozlewiskach", ev.types_for("swamp").size() == 6 and not "raid" in ev.types_for("forest"))
			check("czempion zaczyna się", ev.start("champion", "swamp") and ev.active["trait"] != "" and ev.active["title"].begins_with("Czempion"))
			check("komunikat", _world.hud.event_tracker._message.text != "")
			_build()
		8:
			_site = _world.event_site
			check("świat stawia wydarzenie", _site != null and is_instance_valid(_site) and ev.active.get("built", false))
			_champion = _site.champion
			check("czempion wzmocniony", _champion != null and _champion.has_meta("elite") and _champion.max_health > 1000
					and _champion.scale.x > 1.5, str(_champion.max_health if _champion else 0))
			_away(p, _champion.global_position)
		400:
			var travelers := _event_travelers()
			check("podróżnicy przybywają", travelers.size() >= 2, str(travelers.size()))
			check("panel wydarzenia", _world.hud.event_tracker.visible and _world.hud.event_tracker._goal.text.contains("Czempion"))
			check("znacznik na minimapie", _world.hud.minimap.event_point != Vector2.INF)
			# podróżnik bije czempiona - słabo, a punkty trafiają do rankingu
			var t = travelers[0]
			t._target = _champion
			var before: int = _champion.health
			t._attack("melee")
			check("podróżnik w rankingu", ev.active["contrib"].has(t.data["name"]) and _champion.event_damage > 0
					and before - _champion.health < _champion.max_health * 0.05)
			# gracz zadaje obrażenia
			_champion.take_damage(500, _champion.global_position)
			_site._sample = 0.0
		402:
			check("wkład gracza", float(ev.active["contrib"].get("Ty", 0.0)) >= 400.0, str(ev.active["contrib"].get("Ty", 0.0)))
			_gold = p.count_owned("victory_mark")
			_fame = p.travelers.guild_fame
			var pickups: int = _world.get_tree().get_nodes_in_group("pickups").size()
			_champion.take_damage(_champion.health + 10, _champion.global_position)
			check("pokonany czempion kończy wydarzenie", ev.active.is_empty() and ev.last_result["success"])
			var result: Dictionary = ev.last_result
			check("ranking i miejsce", result["place"] >= 1 and result["ranking"].size() >= 2, str(result["ranking"]))
			check("znaki i sława", p.count_owned("victory_mark") > _gold and p.travelers.guild_fame > _fame)
			check("wynik na ekranie", _world.hud.event_result.visible)
		404:
			check("skrzynia z łupem", _world.get_tree().get_nodes_in_group("pickups").size() >= 3,
					str(_world.get_tree().get_nodes_in_group("pickups").size()))
			# deszcz meteorytów
			check("meteoryty zaczynają się", ev.start("meteors", "swamp"))
			_build()
		408:
			_site = _world.event_site
			check("miejsce meteorytów", _site != null and _site._type == "meteors" and not _site.done)
			# przed uderzeniem zdejmujemy chwilową nietykalność (potwory z Rozlewisk mogły właśnie trafić gracza);
			# unik z przedmiotów jest losowy, więc kolejne meteoryty (już bez miejsca wydarzenia) próbują ponownie
			var hp: float = p.health
			for attempt in 5:
				var meteor = load("res://scripts/meteor.gd").new()
				meteor.site = _site if attempt == 0 else null
				meteor.level = 16
				meteor.position = p.global_position
				_world.entities.add_child(meteor)
				p._invulnerable_timer = 0.0
				hp = p.health
				meteor._land()
				if p.health < hp:
					break
			check("meteoryt rani gracza", p.health < hp)
		410:
			var rock = null
			for node in _world.get_tree().get_nodes_in_group("harvestables"):
				if node.get_script() == load("res://scripts/meteor_rock.gd"):
					rock = node
			check("skała meteorytu", rock != null)
			var before := float(ev.active["contrib"].get("Ty", 0.0))
			var loot: Array = rock.roll_loot()
			rock.harvest(p.global_position)
			check("rozbita skała - punkty i ruda", float(ev.active["contrib"].get("Ty", 0.0)) > before
					and loot.any(func(e: Array) -> bool: return e[0] == "iron_ore"))
			ev.active["left"] = 0.0
		412:
			check("meteoryty kończą się sukcesem", ev.active.is_empty() and ev.last_result["success"] and ev.last_result["type"] == "meteors")
			# najazd na kapliczkę
			check("najazd zaczyna się", ev.start("raid", "swamp") and ev.active["shrine"] == "swamp_ford")
			_build()
		415:
			_site = _world.event_site
			check("kapliczka do obrony", _site != null and _site.is_alive() and _site.center.distance_to(_world._zone_shrines["swamp_ford"]) < 1.0)
			_away(p, _site.center)
			_site._wave_timer = 0.0
		417:
			var raiders: Array = _site.mobs.filter(func(m) -> bool: return is_instance_valid(m) and m.objective == _site)
			check("fala idzie na kapliczkę", raiders.size() >= 5 and raiders.all(func(m) -> bool: return m.state == 1), str(raiders.size()))
			_site.take_hit(_site.max_health + 1.0)
			check("kapliczka zgasła", ev.active.is_empty() and not ev.last_result["success"] and ev.is_shrine_down("swamp_ford"))
			_world.shrines["swamp_ford"] = [0, 0]
			var pos: Vector2 = p.global_position
			_world.teleport_to("swamp_ford")
			check("zgaszona kapliczka bez teleportu", p.global_position == pos)
			ev.shrine_down.clear()
			# polowanie na Hydrę
			check("polowanie zaczyna się", ev.start("hunt", "swamp") and ev.active["boss"] == "hydra")
			_build()
		420:
			_site = _world.event_site
			check("wzmocniona Hydra", _site != null and _site.boss != null and _site.boss.has_meta("elite")
					and _site.boss.max_health >= _site._boss_base["max_health"] * 2)
			_away(p, _site.center)
			# czas minął - boss się uspokaja
			ev.active["left"] = 0.0
		422:
			check("polowanie bez sukcesu po czasie", ev.active.is_empty() and not ev.last_result["success"]
					and is_instance_valid(_site.boss) and not _site.boss.has_meta("elite") and _site.boss.max_health == _site._boss_base["max_health"])
			# wydarzenie w innej krainie rozstrzyga się samo
			check("wydarzenie w innej krainie", ev.start("champion", "forest"))
			ev.active["left"] = 0.0
		424:
			check("rozstrzygnięte bez gracza", ev.active.is_empty() and ev.last_result["place"] == 0 and ev.last_result["ranking"].size() >= 3
					and not ev.last_result["here"])
			# zapis
			ev.start("champion", "fields")
			ev.shrine_down["old_mill"] = 100.0
			var saved: Dictionary = JSON.parse_string(JSON.stringify(ev.get_save_data()))
			var copy = load("res://scripts/world_events.gd").new()
			copy.load_save_data(saved)
			check("zapis wydarzeń", copy.active["type"] == "champion" and copy.active["zone"] == "fields" and copy.is_shrine_down("old_mill")
					and not copy.active.has("built"))
			copy.free()
			ev.finish(false)
			# wymiana znaków
			p.inventory.add_item("victory_mark", 30)
			var talker := GDScript.new()
			talker.source_code = "extends Node\nfunc say(_text):\n\tpass\n"
			talker.reload()
			var npc = talker.new()
			var offers: Dictionary = load("res://scripts/village_services.gd").offers("marks", p, npc)
			var row: Dictionary = {}
			for r: Dictionary in offers["rows"]:
				if r["name"] == "Runa Zmiany":
					row = r
			var marks: int = p.count_owned("victory_mark")
			var runes: int = p.count_owned("rune_chaos")
			check("wymiana znaków", row.get("enabled", false) and row["action"].call() != "" and p.count_owned("victory_mark") == marks - 12
					and p.count_owned("rune_chaos") == runes + 1)
			npc.free()
			# harmonogram: wydarzenie w odkrytej krainie
			ev.next_in = 0.0
			ev.known_zones = ["swamp"]
		426:
			# bez gildii w Ostoi wydarzeń nie ma (sława gildii i Znaki Zwycięstwa dopiero po jej zbudowaniu)
			check("bez gildii brak wydarzeń", ev.active.is_empty() and ev.next_in <= 60.0)
			_world._zone_states["forest"] = {"settlement": {"projects": {"guild": ["built"]}}}
			ev.guild_ready = _world.village_built("guild")
			ev.next_in = 0.0
		440:
			check("harmonogram zaczyna wydarzenie", not ev.active.is_empty() and ev.active["zone"] == "swamp" and ev.next_in > 500.0)
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
