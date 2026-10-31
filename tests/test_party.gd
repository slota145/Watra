extends SceneTree
## Drużyny z podróżnikami: zaproszenie przy spocie łowców (zgoda - idą z graczem, odmowa - przenoszą się), zabójstwa
## drużyny dają graczowi łup i doświadczenie z premią +10% za członka, członkowie dobiegają do gracza, prośba o pomoc
## (zadanie z drużyną wypłaca nagrodę sama), pozdrowienia i wskazówki łowców, ramki drużyny, zapis,
## powrót do Ostoi kończy wspólne łowy.

var _world: Node
var _frame := 0
var _fails := 0
var _member = null


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


func _hunters() -> Array:
	return _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "hunt" and n.is_alive())


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var hud = _world.find_child("HUD", true, false)
	match _frame:
		6:
			p.quests.states["village_help"] = "done"
			_world._settlement.set_project("guild", "built")
			_world._sync_travelers()
			for r: Dictionary in p.travelers.active().slice(0, 3):
				r["state"] = "hunt"
				r["zone"] = "forest"
				r["level"] = 30
			_world._sync_travelers()
			var hunters := _hunters()
			check("łowcy na spocie", hunters.size() == 3)
			# pozdrowienie albo wskazówka
			var h = hunters[0]
			p.global_position = h.global_position + Vector2(30, 0)
			h._greet = 0.0
			h._process_greeting(0.1)
			check("łowca zagaduje gracza", h._bubble.visible and h._bubble.text != "")
			# zaproszenie: odmowa
			_world._party_cooldown = 0.0
			_world._party_check = 0.0
			_world._process_party_offers(0.1)
			check("zaproszenie do drużyny", hud.party_offer.is_open())
			hud.party_offer._answer(false)
			check("odmowa - bez drużyny", p.travelers.party.is_empty())
			# zaproszenie: zgoda
			_world._party_cooldown = 0.0
			_world._party_check = 0.0
			p.global_position = h.global_position + Vector2(30, 0)
			_world._process_party_offers(0.1)
			hud.party_offer._answer(true)
			check("drużyna utworzona", p.travelers.party.size() >= 1 and is_equal_approx(p.travelers.party_xp_factor(), 1.0 + 0.1 * p.travelers.party.size()))
			var members: Array = _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "party")
			_member = members[0] if not members.is_empty() else null
			check("członkowie w drużynie", _member != null and p.travelers.find(_member.data["name"])["state"] == "party")
			check("ramki drużyny", hud.party_frames.visible and hud.party_frames.get_child_count() == 1 + p.travelers.party.size())
			# zabójstwo drużyny liczy się graczowi (z premią)
			var enemy = null
			for e in _world.get_tree().get_nodes_in_group("enemies"):
				if not e.is_in_group("bosses") and e.quest_kind not in ["animal", "dummy"]:
					enemy = e
					break
			var xp: int = p.stats.xp
			_member._target = enemy
			var hits := 0
			while is_instance_valid(enemy) and enemy.state != 4 and hits < 60:
				_member._attack("melee")
				hits += 1
			check("zabójstwo drużyny daje graczowi doświadczenie", enemy.state == 4 and not enemy.slain_by_travelers() and p.stats.xp > xp)
			# członek zostaje daleko - dobiega
			var s = _world._settlement
			for offset in [Vector2(600, 0), Vector2(-600, 0), Vector2(0, 600), Vector2(0, -600)]:
				var spot: Vector2 = p.global_position + offset
				if not s.is_inside_palisade(Vector2i((spot / 16.0).floor())):
					p.global_position = spot
					break
			p.reset_physics_interpolation()
		12:
			check("członek dobiega do gracza", _member != null and _member.global_position.distance_to(p.global_position) < 80.0,
					"%.0f" % _member.global_position.distance_to(p.global_position))
			# prośba o pomoc: zadanie z drużyną
			var task: Dictionary = _world._help_task(_member.data["name"])
			check("prośba o pomoc", task["count"] >= 1 and task["gold"] > 0 and task.has("poster"))
			var kill: Dictionary = load("res://scripts/bounties.gd").make("kill", "forest", 0, _member.data["name"])
			kill["count"] = 10
			# zaproszenie mogło już przynieść losową prośbę - test sprawdza własną
			if p.quests.active_help() != "":
				p.quests.abandon_bounty(p.quests.active_help())
			var id: String = p.quests.take_help(kill)
			check("zadanie drużyny poza tablicą", p.quests.active_help() == id and p.quests.active_bounties().is_empty())
			_gold = p.stats.gold
			for i in 10:
				p.quests.on_enemy_killed(kill["target"])
		14:
			check("nagroda od drużyny", p.quests.active_help() == "" and p.stats.gold > _gold)
			# zapis drużyny
			var saved: Dictionary = JSON.parse_string(JSON.stringify(p.travelers.get_save_data()))
			var t2 = load("res://scripts/travelers.gd").new()
			t2.load_save_data(saved)
			check("zapis drużyny", t2.party == p.travelers.party and t2.party_ticks > 0)
			t2.free()
			# powrót do Ostoi kończy wspólne łowy
			var s = _world._settlement
			p.global_position = s._px(s.WATRA_POS + Vector2(0, 4))
			p.reset_physics_interpolation()
		16:
			check("powrót do Ostoi kończy drużynę", p.travelers.party.is_empty() and not hud.party_frames.visible)
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


var _gold := 0
