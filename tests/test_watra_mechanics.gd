extends SceneTree
## Węzły drzewka Watry zmieniające mechaniki lochów (scripts/watra_tree.gd, MECHANIC_NOTABLES) w prawdziwym lochu:
## podwójne mechaniki (dwa Uroczyska, dwa Kręgi Żertwy, drugi Skarbnik), skrzynie (mimik, Skrzynie Bogów), kapliczki
## (dar do końca lochu, kilka darów naraz, silniejsze), elity (Czempion, Bożkowe Piętno), Kryształ Watry (dodatkowa
## fala, zdrowie, leczenie), Uroczysko (elitarne zjawy, Strażnik Kręgu, Upiorny Książę), Krąg Żertwy (4 talizmany,
## podwójna danina z elit, talizman z dwoma efektami), Skarbnik (darmowe przelosowanie).

var _world: Node
var _frame := 0
var _fails := 0
var _D

const TREE := {
	"dup:uroczysko": 1.0, "dup:zertwa": 1.0, "dup:skarbnik": 1.0, "chest_special": 1.0, "chest_mimic": 1.0,
	"shrine_long": 1.0, "shrine_stack": 1.0, "shrine_power": 0.5, "elite_champion": 1.0, "elite_idol": 1.0,
	"crystal_waves": 1.0, "crystal_health": 0.5, "crystal_heal": 1.0, "uro_hold": 1.0, "uro_prince": 1.0,
	"uro_elites": 1.0, "zer_offer": 1.0, "zer_elite": 1.0, "ska_reroll": 1.0,
}


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	_D = load("res://scripts/dungeons.gd")
	var config: Dictionary = _D.config("catacombs", 5, [], 4242)
	config["mechanics"] = ["chests", "shrine", "crystal", "elites", "uroczysko", "zertwa", "skarbnik"]
	config["tree"] = TREE.duplicate()
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _kill(goblin) -> void:
	goblin.take_damage(999999999, goblin.global_position + Vector2(10, 0))


func _check_counts(d) -> void:
	check("dwa Uroczyska i dwa Kręgi Żertwy", d.uroczyska.size() == 2 and d.zertwy.size() == 2,
			"%d, %d" % [d.uroczyska.size(), d.zertwy.size()])
	check("drugi Skarbnik", d.skarbniki.size() >= 2, str(d.skarbniki.size()))


func _check_chests(d) -> void:
	var C = load("res://scripts/dungeon_chest.gd")
	for kind in ["idols", "runes", "talismans"]:
		check("Skrzynia Bogów: %s ma łup" % kind, not C.roll_contents(kind, [], d.level, 5).is_empty())
	check("wszystkie skrzynie to mimiki", not d.chests.is_empty() and d.chests.all(func(c) -> bool: return c.traits.has("mimic")))
	var chest = d.chests[0]
	chest.traits.assign(["mimic"])
	var elites_before: int = d.elites.size()
	chest.harvest(chest.global_position)
	check("mimik ożywa jako elita", chest.state == "guarded" and chest._guards.size() == 1 and d.elites.size() == elites_before + 1
			and not chest.sprite.visible)
	_kill(chest._guards[0])
	chest._process(0.0)
	check("po mimiku skrzynia się otwiera", chest.state == "open" and chest.sprite.visible)


func _check_shrines(d) -> void:
	var boons = _world.player.boons
	check("co najmniej dwie kapliczki", d.shrines.size() >= 2, str(d.shrines.size()))
	if d.shrines.size() < 2:
		return
	d.shrines[0].harvest(Vector2.ZERO)
	d.shrines[1].harvest(Vector2.ZERO)
	var gifts: Array = boons.active.keys().filter(func(g: String) -> bool: return g.begins_with("shrine"))
	check("dwa dary naraz", gifts.size() == 2, str(gifts))
	var entry: Dictionary = boons.active["shrine"]
	check("dar do końca lochu i silniejszy", entry.get("dungeon", false) and is_equal_approx(float(entry.get("power", 1.0)), 1.5)
			and float(entry["left"]) > 1000.0)
	var stat: String = load("res://scripts/boons.gd").DEFS[entry["id"]]["stats"].keys()[0]
	var base: float = float(load("res://scripts/boons.gd").DEFS[entry["id"]]["stats"][stat])
	check("premia daru razy moc", boons.bonus(stat) >= base * 1.5 - 0.001, "%s %.2f" % [stat, boons.bonus(stat)])
	var copy = load("res://scripts/boons.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(boons.get_save_data())))
	check("zapis darów z mocą", copy.active.size() == boons.active.size() and copy.active["shrine"].get("dungeon", false))
	copy.free()
	boons.end_dungeon_gifts()
	check("po wyjściu z lochu dary gasną", not boons.active.keys().any(func(g: String) -> bool: return g.begins_with("shrine")))


func _check_elites(d) -> void:
	var champions: Array = d.elites.filter(func(e) -> bool: return e.champion)
	check("jeden Czempion ze wszystkimi grupami cech", champions.size() == 1 and champions[0].traits.size() == 4,
			str(champions.map(func(e): return e.traits)))
	check("elity z Bożkowym Piętnem", d.elites.any(func(e) -> bool: return e.idol and not e.champion and e.traits.size() >= 2))


func _check_crystal(d) -> void:
	var crystal = d.crystal
	check("Kryształ Watry w lochu", crystal != null)
	if crystal == null:
		return
	check("dodatkowa fala i więcej zdrowia", crystal.waves == crystal.WAVES + 1
			and crystal.max_health > load("res://scripts/levels.gd").damage(crystal.level) * crystal.CRYSTAL_HITS * 1.4)
	var player = _world.player
	player.global_position = crystal.global_position + Vector2(30, 0)
	player.health = 10
	crystal.state = "waves"
	for i in 30:
		crystal._process(0.5)
	check("kryształ leczy gracza w pobliżu", player.health > 10, str(player.health))
	player.health = player.stats.max_health()


func _check_uroczysko(d) -> void:
	var stone = d.uroczyska[0]
	var player = _world.player
	stone.harvest(stone.global_position)
	for i in 10:
		stone._spawn_timer = 0.0
		stone._process(0.0)
	check("elitarne zjawy", not stone.ghosts.is_empty() and stone.ghosts.all(func(e: Array) -> bool: return e[0].elite != null))
	player.global_position = stone.global_position + Vector2(20, 0)
	stone._elapsed = _D.URO_GRACE + 5.0
	var before: float = stone.radius
	stone._process(1.0)
	check("Strażnik Kręgu: krąg nie maleje przy menhirze", is_equal_approx(stone.radius, before))
	player.global_position = stone.global_position + Vector2(400, 0)
	stone._process(1.0)
	check("z dala od menhiru krąg maleje", stone.radius < before)
	stone.radius = _D.URO_END - 1.0
	stone._process(0.1)
	check("Upiorny Książę zamiast zgaśnięcia", stone.state == "open" and stone._prince != null)
	if stone._prince == null:
		return
	stone._elapsed = _D.URO_GRACE + 100.0
	before = stone.radius
	stone._process(1.0)
	check("krąg trwa, póki Książę żyje", stone.radius >= before)
	_kill(stone._prince)
	check("śmierć Księcia gasi krąg", stone.state == "closed")


func _check_zertwa(d) -> void:
	var altar = d.zertwy[0]
	altar.harvest(altar.global_position)
	var elite = d.elites[0].goblin
	elite.global_position = altar.global_position + Vector2(10, 0)
	var before: int = altar.tribute
	_kill(elite)
	check("elita daje podwójną daninę", altar.tribute - before == 2 * _D.ZER_ELITE_TRIBUTE, str(altar.tribute - before))
	altar.add_tribute(_D.ZER_GOAL)
	altar.claim()
	check("4 talizmany do wyboru", altar.offer.size() == _D.ZER_OFFER + 1, str(altar.offer.size()))
	var T = load("res://scripts/talismans.gd")
	var id: String = T.roll(60, "rare", "large", null, true)
	var data: Dictionary = load("res://scripts/items.gd").get_data(id)
	check("talizman z dwoma efektami", data.has("effect2") and data["effect2"]["kind"] != data["effect"]["kind"])
	var copy: String = T.register(data["recipe"].duplicate(true))
	check("drugi efekt zostaje po wczytaniu", load("res://scripts/items.gd").get_data(copy).has("effect2"))
	var equipment = _world.player.equipment
	equipment.talismans.append({"id": id, "cell": Vector2i.ZERO})
	equipment._power_frame = -1
	check("drugi efekt działa", equipment.effect_power(data["effect2"]["kind"]) > 0.0)
	equipment.talismans.clear()


func _check_skarbnik(d) -> void:
	var spirit = d.skarbniki[0]
	spirit.current_offer()
	check("darmowe przelosowanie", spirit.free_rerolls() == 1 and spirit.reroll() and spirit.free_rerolls() == 0
			and spirit.state == "waves")
	spirit.lose()


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 6:
		var d = _world._dungeon
		_check_counts(d)
		_check_chests(d)
		_check_shrines(d)
		_check_elites(d)
		_check_crystal(d)
		load("res://scripts/goblin.gd")._near_frame = -1
		_check_uroczysko(d)
		_check_zertwa(d)
		_check_skarbnik(d)
	if _frame == 8:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
