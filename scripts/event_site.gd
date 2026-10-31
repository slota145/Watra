class_name EventSite
extends Node2D
## Wydarzenie w krainie gracza (WorldEvents.active) - stawia je świat (World._process_events), gdy gracz jest w krainie
## wydarzenia. Rodzaje:
## - "raid": fale potworów krainy idą na kapliczkę (Goblin.objective - ten węzeł ma zdrowie kapliczki); sukces, gdy
##   kapliczka przetrwa wszystkie fale (albo czas), porażka - gdy zgaśnie,
## - "champion": elitarny potwór krainy z cechą (WorldEvents.TRAITS) krąży po krainie; sukces - pokonany, czas - odchodzi,
## - "meteors": w okolicy spadają meteoryty (Meteor): rażą gracza, zostawiają skałę do rozbicia (MeteorRock - ruda,
##   kamienie) i czasem potwory z krateru; sukces na koniec czasu,
## - "hunt": boss polowania (Hydra, Gryf) wraca rozwścieczony (więcej zdrowia i obrażeń); sukces - pokonany.
## Przybywa gromada podróżników (Traveler w trybie "event") - walczą z potworami wydarzenia i rywalizują o wkład.
## Wkład gracza: obrażenia zadane potworom wydarzenia (bez części podróżników - Goblin.event_damage) i rozbite skały.
## Po sukcesie skrzynia z łupem wg miejsca gracza w rankingu.

const TRAVELER_GAP := 3.0
const RAID_WAVES := 5
const RAID_WAVE_GAP := 25.0
const METEOR_GAP := Vector2(2.5, 5.0)
const METEOR_RADIUS := 300.0
const CHAMPION_HEALTH := 12.0
const CHAMPION_DAMAGE := 1.6
const HUNT_HEALTH := 3.0
const HUNT_DAMAGE := 1.3
const ROAM_EVERY := 25.0
const CHEST := preload("res://assets/village/chest.png")
const CHEST_LIFE := 240.0
## Potwory z własnym zachowaniem, które nie pasują do wydarzeń (ognik odlatuje i sam wybucha).
const SKIP_TYPES := ["wisp"]

var w: Node
var events: WorldEvents
var event: Dictionary
var center := Vector2.ZERO
## Kapliczka w najeździe (cel potworów): zdrowie i zasięg ciosów.
var hit_radius := 20.0
var max_health := 1.0
var health := 1.0
var mobs: Array = []
var champion: Goblin
var boss: Goblin
var done := false
var _wave := 0
var _wave_timer := 4.0
var _meteor_timer := 2.0
## Ilu podróżników ma walczyć naraz i ilu jeszcze może przybyć (polegli są zastępowani, dopóki starczy chętnych).
var _travelers_left := 0
var _arrivals_left := 0
var _traveler_timer := 1.0
var _sample := 0.0
var _roam := ROAM_EVERY
var _aura := 0.0
var _summon := 12.0
var _boss_base := {}
var _type := ""
var _level := 1
var _flash := 0.0


func setup(world: Node, world_events: WorldEvents) -> void:
	w = world
	events = world_events
	event = events.active
	event["built"] = true
	_type = event["type"]
	_level = int(event["level"])
	add_to_group("event_site")


func _ready() -> void:
	z_index = 5
	match _type:
		"raid":
			center = w._zone_shrines.get(event["shrine"], w._spawn_point)
			max_health = Levels.damage(_level) * 400.0
			health = max_health
			_travelers_left = randi_range(3, 5)
		"champion":
			center = _far_spawn(500.0)
			var data: Dictionary = WorldEvents.TRAITS[event["trait"]]
			champion = _spawn_mob(_common_types().pick_random(), center, _level + 2, true)
			champion.max_health = roundi(champion.max_health * CHAMPION_HEALTH * (1.6 if event["trait"] == "stone" else 1.0))
			champion.health = champion.max_health
			_scale_damage(champion, CHAMPION_DAMAGE)
			champion.scale = Vector2.ONE * (1.9 if event["trait"] == "stone" else 1.6)
			champion.modulate = data["color"]
			champion.speed *= {"swift": 1.7, "stone": 0.8}.get(event["trait"], 1.0)
			champion.leash_radius = 700.0
			_label(champion, "%s %s [%d]" % [data["name"], _monster_name(champion), _level + 2], WorldEvents.TYPES["champion"]["color"])
			_travelers_left = randi_range(3, 5)
		"meteors":
			center = _far_spawn(0.0)
			_travelers_left = randi_range(3, 5)
		"hunt":
			_build_hunt()
			_travelers_left = randi_range(6, 10)
	position = center


## Rodzaje zwykłych potworów krainy (z miejsc odrodzenia, bez bossów i zwierzyny).
func _common_types() -> Array:
	var kinds := {}
	for spawn: Dictionary in w._goblin_spawns:
		var kind: String = spawn.get("type", "goblin")
		if kind in w.BOSS_TYPES or w.ANIMAL_SCENES.has(kind) or kind in SKIP_TYPES:
			continue
		kinds[kind] = true
	return kinds.keys() if not kinds.is_empty() else ["goblin"]


## Miejsca zwykłych potworów (da się tam dojść) - do pojawiania się potworów i wędrówki czempiona.
func _spots(around: Vector2, min_d: float, max_d: float) -> Array:
	var result := []
	for spawn: Dictionary in w._goblin_spawns:
		var kind: String = spawn.get("type", "goblin")
		if kind in w.BOSS_TYPES or w.ANIMAL_SCENES.has(kind):
			continue
		var pos: Vector2 = spawn["position"]
		var d := pos.distance_to(around)
		if d >= min_d and d <= max_d and not Goblin.safe_zone.has_point(pos):
			result.append(pos)
	return result


## Miejsce w odległości min_d-max_d od celu, z którego droga do celu jest wolna (promień bez przeszkód) -
## potwory idą prosto i nie utykają na drzewach czy płotach.
func _clear_spot(target: Vector2, min_d: float, max_d: float) -> Vector2:
	var space := get_world_2d().direct_space_state
	var fallback := target + Vector2.from_angle(randf() * TAU) * min_d
	for i in 48:
		var spot := target + Vector2.from_angle(randf() * TAU) * randf_range(min_d, max_d)
		if spot.x < 32.0 or spot.y < 32.0 or spot.x > w.map_size.x * w.TILE - 32.0 or spot.y > w.map_size.y * w.TILE - 32.0:
			continue
		if Goblin.safe_zone.has_point(spot):
			continue
		var clear := true
		# kilka równoległych promieni - potwór ma szerokość
		for side: float in [-6.0, 0.0, 6.0]:
			var offset := (target - spot).normalized().orthogonal() * side
			var ray := PhysicsRayQueryParameters2D.create(spot + offset, target + offset + (spot - target).normalized() * 30.0, 1)
			if not space.intersect_ray(ray).is_empty():
				clear = false
				break
		if clear:
			return spot
	return fallback


func _far_spawn(min_player: float) -> Vector2:
	var spots := _spots(w.player.global_position, min_player, 100000.0)
	if spots.is_empty():
		spots = _spots(w.player.global_position, 0.0, 100000.0)
	return spots.pick_random() if not spots.is_empty() else w.player.global_position + Vector2(200, 0)


func _monster_name(goblin: Goblin) -> String:
	var info: Dictionary = Codex.MONSTERS.get(Codex.monster_id(goblin), {})
	return info.get("name", "Potwór")


func _scale_damage(goblin: Goblin, factor: float) -> void:
	for property in goblin.get_property_list():
		var key: String = property["name"]
		if key.ends_with("damage") and key != "traveler_damage" and key != "event_damage" and property["type"] == TYPE_INT \
				and goblin.get(key) > 0:
			goblin.set(key, maxi(1, roundi(goblin.get(key) * factor)))


func _label(goblin: Goblin, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140, 10)
	label.position = Vector2(-70, -48)
	label.z_index = 30
	# napis nie rośnie ze skalą potwora
	label.scale = Vector2.ONE / goblin.scale.x
	label.position /= goblin.scale.x
	goblin.add_child(label)


## Potwór wydarzenia: nie odradza się, jego zabicie liczy się graczowi (zadania, encyklopedia), wkład - w rankingu.
func _spawn_mob(kind: String, pos: Vector2, level: int, elite := false) -> Goblin:
	var goblin: Goblin = w.scene_for(kind).instantiate()
	goblin.level = level
	goblin.position = pos
	goblin.look_at_point = pos + Vector2(0, 10)
	if "lurk" in goblin:
		goblin.set("lurk", false)
	goblin.set_meta("event", true)
	if elite:
		goblin.set_meta("elite", true)
	goblin.leash_radius = 1200.0
	goblin.died.connect(_on_mob_died)
	w.entities.add_child(goblin)
	goblin.appear()
	mobs.append(goblin)
	return goblin


func _build_hunt() -> void:
	var type: String = event["boss"]
	for spawn: Dictionary in w._goblin_spawns:
		if spawn.get("type", "") != type:
			continue
		center = spawn["position"]
		boss = w._live_goblins.get(spawn["id"])
		if boss == null or boss.state == Goblin.State.DEAD:
			for i in range(w._respawn_queue.size() - 1, -1, -1):
				if w._respawn_queue[i]["spawn"]["id"] == spawn["id"]:
					w._respawn_queue.remove_at(i)
			boss = w._spawn_goblin(spawn)
			boss.appear()
		break
	if boss == null:
		center = _far_spawn(0.0)
		return
	_boss_base = {"max_health": boss.max_health, "scale": boss.scale, "modulate": boss.modulate}
	boss.max_health = roundi(boss.max_health * HUNT_HEALTH)
	boss.health = boss.max_health
	_scale_damage(boss, HUNT_DAMAGE)
	boss.scale *= 1.2
	boss.modulate = Color(1.35, 0.8, 0.8)
	boss.set_meta("event", true)
	boss.set_meta("elite", true)
	boss.died.connect(_on_mob_died)
	mobs.append(boss)


# ---------------------------------------------------------------- kapliczka (cel najazdu)
func is_alive() -> bool:
	return _type == "raid" and not done and health > 0.0


func take_hit(amount: float) -> void:
	if not is_alive():
		return
	health -= amount
	_flash = 0.15
	if health <= 0.0:
		health = 0.0
		Sfx.play_at("rock_break", center)
		_finish(false)


# ---------------------------------------------------------------- przebieg
func _process(delta: float) -> void:
	if done:
		return
	if not is_same(events.active, event):
		# wydarzenie zakończone gdzie indziej (np. tryb deweloperski)
		done = true
		_cleanup(false)
		return
	_flash = maxf(_flash - delta, 0.0)
	_process_travelers(delta)
	_sample -= delta
	if _sample <= 0.0:
		_sample = 0.25
		for mob in mobs.duplicate():
			if not is_instance_valid(mob):
				mobs.erase(mob)
			elif mob.state != Goblin.State.DEAD:
				_account(mob)
	match _type:
		"raid":
			_process_raid(delta)
		"champion":
			_process_champion(delta)
		"meteors":
			_process_meteors(delta)
	if _type == "hunt" and is_instance_valid(boss):
		center = boss.global_position
	for node: Traveler in get_tree().get_nodes_in_group("travelers"):
		if node.mode == "event":
			node.home = center
	queue_redraw()
	if not done and float(event["left"]) <= 0.0:
		_finish(_type == "raid" or _type == "meteors")


func _process_raid(delta: float) -> void:
	_wave_timer -= delta
	if _wave < RAID_WAVES and _wave_timer <= 0.0:
		_wave += 1
		_wave_timer = RAID_WAVE_GAP
		var from := _clear_spot(center, 240.0, 420.0)
		var kinds := _common_types()
		for i in 3 + _wave * 2:
			var mob := _spawn_mob(kinds.pick_random(), from + Vector2(randf_range(-40, 40), randf_range(-30, 30)), _level)
			mob.objective = self
			mob.state = Goblin.State.CHASE
		w.hud.show_banner("Fala %d/%d nadciąga na kapliczkę!" % [_wave, RAID_WAVES], WorldEvents.TYPES["raid"]["color"])
	elif _wave >= RAID_WAVES and _alive_mobs() == 0:
		_finish(true)


func _process_champion(delta: float) -> void:
	if not is_instance_valid(champion) or champion.state == Goblin.State.DEAD:
		return
	center = champion.global_position
	# wędrówka po krainie
	_roam -= delta
	if _roam <= 0.0 and champion.state == Goblin.State.IDLE:
		_roam = ROAM_EVERY
		var spots := _spots(champion.global_position, 120.0, 600.0)
		if not spots.is_empty():
			champion.home = spots.pick_random()
	var fighting := champion.state in [Goblin.State.CHASE, Goblin.State.ATTACK]
	match event["trait"]:
		"fiery":
			_aura -= delta
			if _aura <= 0.0 and champion.velocity.length() > 5.0:
				_aura = 0.9
				var patch := BurningPatch.new()
				patch.radius = 16.0
				patch.damage = maxi(1, roundi(Levels.damage(_level) * 0.4))
				patch.life = 3.5
				patch.position = champion.global_position
				w.entities.add_child(patch)
		"vampiric":
			if fighting:
				champion.health = mini(champion.max_health, champion.health + ceili(champion.max_health * 0.012 * delta))
		"summoner":
			_summon -= delta
			if fighting and _summon <= 0.0:
				_summon = 12.0
				SkillEffects.spark(w.entities, champion.global_position, Color(1.0, 0.6, 1.0), 16)
				for i in 2:
					var minion := _spawn_mob(_common_types().pick_random(), champion.global_position + Vector2.from_angle(randf() * TAU) * 30.0, _level)
					minion.aggro()


func _process_meteors(delta: float) -> void:
	_meteor_timer -= delta
	if _meteor_timer > 0.0 or float(event["left"]) < 4.0:
		return
	_meteor_timer = randf_range(METEOR_GAP.x, METEOR_GAP.y)
	var at := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * METEOR_RADIUS
	# co trzeci meteoryt celuje w gracza, jeśli jest blisko
	if randf() < 0.33 and w.player.global_position.distance_to(center) < METEOR_RADIUS * 1.3:
		at = w.player.global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	var meteor := Meteor.new()
	meteor.position = at
	meteor.site = self
	meteor.level = _level
	w.entities.add_child(meteor)


## Meteoryt uderzył: skała do rozbicia, czasem potwory z krateru.
func on_meteor_landed(at: Vector2) -> void:
	var rock := MeteorRock.create(at, _level)
	rock.site = self
	w.entities.add_child(rock)
	if randf() < 0.35:
		var kinds := _common_types()
		for i in randi_range(2, 3):
			var mob := _spawn_mob(kinds.pick_random(), at + Vector2.from_angle(randf() * TAU) * 20.0, _level)
			mob.aggro.call_deferred()


func _alive_mobs() -> int:
	var count := 0
	for mob in mobs:
		if is_instance_valid(mob) and mob.state != Goblin.State.DEAD:
			count += 1
	return count


## Wkład gracza: obrażenia potwora od ostatniego pomiaru minus część podróżników.
func _account(mob: Goblin) -> void:
	var taken := float(mob.max_health - maxi(mob.health, 0))
	var seen := float(mob.get_meta("seen", 0.0))
	var travel := float(mob.event_damage)
	var seen_travel := float(mob.get_meta("seen_travel", 0.0))
	if taken > seen:
		events.add_points(WorldEvents.PLAYER, maxf(0.0, (taken - seen) - (travel - seen_travel)))
	mob.set_meta("seen", taken)
	mob.set_meta("seen_travel", travel)


func _on_mob_died(mob: Goblin) -> void:
	if done:
		return
	_account(mob)
	if mob != boss:
		w.note_event_kill(mob)
	if mob == champion or mob == boss:
		_finish(true)


## Skała rozbita (MeteorRock) - punkty wkładu dla tego, kto ją rozbił.
func on_rock_mined(who: String) -> void:
	events.add_points(who, Levels.health(_level) * 0.6)


# ---------------------------------------------------------------- podróżnicy
func _process_travelers(delta: float) -> void:
	if _arrivals_left == 0 and _travelers_left > 0:
		_arrivals_left = _travelers_left * 2
	if _arrivals_left <= 0:
		return
	_traveler_timer -= delta
	if _traveler_timer > 0.0:
		return
	_traveler_timer = TRAVELER_GAP
	var present := get_tree().get_nodes_in_group("travelers").filter(func(t: Traveler) -> bool:
		return t.mode == "event" and t.is_alive()).size()
	if present >= _travelers_left:
		return
	var data := _pick_traveler()
	if data.is_empty():
		_arrivals_left = -1
		return
	_arrivals_left -= 1
	data["state"] = "hunt"
	data["zone"] = w.zone
	var at := center + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 150.0)
	var node: Traveler = w._spawn_traveler(data, "event", at)
	SkillEffects.spark(w.entities, at + Vector2(0, -12), Color(1.0, 0.6, 0.25), 14)
	if randf() < 0.5:
		node.say.call_deferred(["Słyszałem o %s!" % event["title"].to_lower(), "Jestem! Gdzie oni są?", "Za Ostoję!",
				"Ten łup będzie mój!", "Razem damy radę!"].pick_random())


## Aktywny podróżnik, którego jeszcze nie widać (najchętniej w poziomie wydarzenia).
func _pick_traveler() -> Dictionary:
	var shown := {}
	for node: Traveler in get_tree().get_nodes_in_group("travelers"):
		shown[node.data["name"]] = true
	var pool: Array = w.player.travelers.active().filter(func(t: Dictionary) -> bool:
		return not shown.has(t["name"]) and t["state"] != "party" and t["state"] != "dead")
	if pool.is_empty():
		return {}
	var strong: Array = pool.filter(func(t: Dictionary) -> bool: return int(t["level"]) >= _level - 10)
	return (strong if not strong.is_empty() else pool).pick_random()


# ---------------------------------------------------------------- koniec
func _finish(success: bool) -> void:
	if done:
		return
	for mob in mobs:
		if is_instance_valid(mob) and mob.state != Goblin.State.DEAD:
			_account(mob)
	done = true
	var result := events.finish(success)
	if success and int(result.get("place", 0)) > 0:
		_chest(int(result["place"]))
	_cleanup(success)


func _cleanup(success: bool) -> void:
	# czempion odchodzi, boss się uspokaja, podróżnicy wracają do Ostoi
	if not success and is_instance_valid(champion) and champion.state != Goblin.State.DEAD:
		var tween := champion.create_tween()
		tween.tween_property(champion, "modulate:a", 0.0, 1.0)
		tween.tween_callback(champion.queue_free)
	if is_instance_valid(boss) and boss.state != Goblin.State.DEAD and not _boss_base.is_empty():
		boss.max_health = _boss_base["max_health"]
		boss.health = mini(boss.health, boss.max_health)
		boss.scale = _boss_base["scale"]
		boss.modulate = _boss_base["modulate"]
		boss.remove_meta("event")
		boss.remove_meta("elite")
	for mob in mobs:
		if is_instance_valid(mob):
			mob.objective = null
	for node: Traveler in get_tree().get_nodes_in_group("travelers"):
		if node.mode == "event":
			node.say(["Dobra robota!", "Do następnego razu!", "Wracam do Ostoi."].pick_random() if success else
					["Nie tym razem...", "Uciekamy!", "Następnym razem się uda."].pick_random())
			var leave := node.create_tween()
			leave.tween_interval(randf_range(4.0, 9.0))
			leave.tween_callback(func() -> void:
				if is_instance_valid(node) and node.mode == "event":
					node.recall())
	queue_redraw()


## Skrzynia wydarzenia: łup wg miejsca gracza w rankingu.
func _chest(place: int) -> void:
	var chest := Sprite2D.new()
	chest.texture = CHEST
	chest.scale = Vector2(1.6, 1.6)
	chest.offset = Vector2(0, -CHEST.get_height() / 2.0)
	chest.position = center + Vector2(0, 24)
	w.entities.add_child(chest)
	SkillEffects.shockwave(w.entities, chest.position, 40.0, Color(1.0, 0.85, 0.4))
	var tween := chest.create_tween()
	tween.tween_interval(CHEST_LIFE)
	tween.tween_property(chest, "modulate:a", 0.0, 1.0)
	tween.tween_callback(chest.queue_free)
	for drop: Array in chest_loot(place, _level):
		var pickup: Pickup = load(Goblin.PICKUP_PATH).instantiate()
		pickup.item_id = drop[0]
		pickup.amount = drop[1]
		pickup.position = chest.position + Vector2(randf_range(-30, 30), randf_range(4, 22))
		w.entities.add_child(pickup)


## Zawartość skrzyni: [[id, ilość]...] - złoto, przedmioty, kamienie, czasem runa i Serce Kryształu.
static func chest_loot(place: int, level: int) -> Array:
	var first := place == 1
	var top := place <= 3
	var loot := [["gold", roundi(Levels.gold(level) * (30.0 if first else 20.0 if top else 12.0))]]
	for i in (3 if first else 2 if top else 1):
		loot.append([Loot.drop_at_level(level, 0.5, Loot.RARE if first else Loot.MAGIC), 1])
	if Gems.unlocked and randf() < (0.6 if first else 0.4 if top else 0.25):
		loot.append([Gems.roll("", Gems.cut_for_level(level)), 1])
	if randf() < (0.25 if first else 0.1 if top else 0.0):
		loot.append(["rune_chaos", 1])
	if first:
		var bag := Bags.roll_vault(level, 0.5)
		if bag != "":
			loot.append([bag, 1])
	if first and level >= 23 and randf() < 0.1:
		loot.append([Essences.HEART, 1])
	return loot


func objective_text() -> String:
	match _type:
		"raid":
			return "Kapliczka: %d%%  -  fala %d/%d" % [roundi(health / max_health * 100.0), _wave, RAID_WAVES]
		"champion":
			if is_instance_valid(champion):
				return "Czempion: %d%% zdrowia" % roundi(100.0 * champion.health / maxf(1.0, champion.max_health))
		"hunt":
			if is_instance_valid(boss):
				return "%s: %d%% zdrowia" % [WorldEvents.boss_title(event["boss"]), roundi(100.0 * boss.health / maxf(1.0, boss.max_health))]
		"meteors":
			return "Rozbijaj meteoryty i bij potwory z kraterów"
	return ""


func _draw() -> void:
	if _type != "raid" or done:
		return
	# pasek zdrowia kapliczki i krąg obrony
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)
	draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color(1.0, 0.5, 0.35, 0.25 + 0.25 * pulse), 2.0)
	var bar := Rect2(-20, -58, 40, 4)
	draw_rect(bar.grow(1), Color(0.1, 0.11, 0.17))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * health / max_health, bar.size.y)),
			Color(1, 1, 1) if _flash > 0.0 else Color(1.0, 0.7, 0.3))


func _exit_tree() -> void:
	# gracz opuścił krainę - wydarzenie toczy się dalej bez niego
	if not done and events != null and is_same(events.active, event):
		event["built"] = false
