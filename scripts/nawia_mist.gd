class_name NawiaMist
extends Harvestable
## Mglisty Słup w lochu (mechanika "mist", stałe MIST_* w Dungeons) - jak Delirium w Path of Exile. Siny obelisk
## owiany mgłą; dotknięcie (F) jest dobrowolne i wypuszcza Mgłę Nawii na cały loch. Co Dungeons.MIST_STEP sekund
## gęstość rośnie o 1 (do MIST_MAX): potwory w całym lochu są coraz silniejsze (Dungeons.mist_power - zdrowie i obrażenia),
## wokół gracza wychodzi coraz więcej zjaw (potwory klimatu jako sine upiory, shaders/ghost.gdshader), a co
## MIST_TRAIT_EVERY stopni Mgła zyskuje cechę elit (Dungeons.ELITE_TRAITS) - przewodnicy gromad zjaw stają się elitami.
## Ekran zasnuwa się mgłą (shaders/nawia_mist.gdshader), a pasek u góry pokazuje gęstość i pulę nagród.
## Każdy wróg zabity w Mgle dokłada do puli (przedmioty, złoto, kamienie wsparcia - Supports, Krzesiwa Nawii,
## od gęstości MIST_GREAT_FROM Wielkie Krzesiwa). Mgła kończy się przy Słupie (F), portalem do miasta (B,
## World.open_town_portal -> Dungeon.end_mists) albo śmiercią gracza (przepada połowa puli) - Słup wysypuje
## wtedy Skrzynię Mgły. Węzły Mgły w drzewku Watry zmieniają tempo, sufit gęstości, stratę po śmierci i kamienie
## (Dungeons.mist_rules, zmienna `rules`). Budowany w kodzie (NawiaMist.create), bez sceny.

const TEXTURE := preload("res://assets/cemetery/obelisk.png")
const CHEST_TEXTURE := preload("res://assets/village/chest.png")
const SHADER := preload("res://shaders/ghost.gdshader")
const FOG_SHADER := preload("res://shaders/nawia_mist.gdshader")
const TOUCH_TIME := 0.8
const END_TIME := 1.2
const SCALE := 1.7
const COLOR := Color(0.68, 0.7, 1.0)
const TINT := Color(0.72, 0.74, 1.0)
## Co tyle sekund Mgła sprawdza wszystkie potwory lochu (siła z gęstości, zjawy zostawione w tyle).
const SWEEP_EVERY := 1.0
## Mgła na ekranie przy pełnej gęstości (0..1 w shaderze).
const FOG_MAX := 0.85

var dungeon: Node
## "idle" - czeka na dotknięcie, "open" - Mgła trwa, "closed" - po wszystkim.
var state := "idle"
## Gęstość Mgły: 0 przed dotknięciem, potem 1..MIST_MAX.
var density := 0
## Cechy elit, które Mgła już zyskała (co MIST_TRAIT_EVERY stopni).
var traits: Array[String] = []
var kills := 0
## Zasady Mgły z premiami drzewka Watry (Dungeons.mist_rules) - ustawiane przy dotknięciu Słupa.
var rules := Dungeons.mist_rules({})
## Pula nagród (ułamki - Skrzynia Mgły zaokrągla losowo): items, gold, supports, flints, great.
var pool := {"items": 0.0, "gold": 0.0, "supports": 0.0, "flints": 0.0, "great": 0.0}
## Żywe zjawy: [Goblin, id miejsca w świecie].
var wraiths: Array = []
## Poświata z lochu (Dungeon._glow) - gaśnie po wszystkim.
var glow: Sprite2D
var _elapsed := 0.0
var _spawn_timer := 0.0
var _sweep_timer := 0.0
var _puff_timer := 0.0
var _label: Label
var _fog: ColorRect
var _fog_mat: ShaderMaterial
var _bar: VBoxContainer
var _bar_title: Label
var _bar_step: ProgressBar
var _bar_pool: Label
var _rng := RandomNumberGenerator.new()
## Nazwy właściwości obrażeń w skryptach potworów (skrypt -> [nazwy]) - get_property_list jest drogie.
static var _damage_keys := {}


static func create(owner_dungeon: Node) -> NawiaMist:
	var pillar := NawiaMist.new()
	pillar.dungeon = owner_dungeon
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 2.0)
	sprite.modulate = TINT
	pillar.add_child(sprite)
	return pillar


func _init() -> void:
	action_name = Lang.t("Dotknij Słupa")
	harvest_time = TOUCH_TIME
	chip_color = COLOR
	hit_sound = ""
	break_sound = "magic"
	bar_height = 84.0
	bar_color = COLOR
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_rng.randomize()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", COLOR.lightened(0.4))
	_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.09))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(170, 30)
	_label.position = Vector2(-85, -bar_height - 12.0 - _label.size.y)
	_label.z_index = 30
	if dungeon != null:
		_label.modulate = dungeon.label_boost()
	add_child(_label)
	_update_label()
	# kłęby mgły wokół Słupa także przed dotknięciem
	set_process(true)


func can_harvest() -> bool:
	return state != "closed"


## Dotknięcie Słupa: przed Mgłą - wypuszcza ją, w trakcie - rozwiewa i wysypuje Skrzynię Mgły.
func harvest(_from: Vector2) -> void:
	set_progress(0.0)
	if state == "idle":
		open()
	elif state == "open":
		close("pillar")


func open() -> void:
	state = "open"
	density = 1
	rules = Dungeons.mist_rules(dungeon.config.get("tree", {}))
	_elapsed = 0.0
	action_name = Lang.t("Rozwiej Mgłę")
	harvest_time = END_TIME
	sprite.modulate = TINT.lightened(0.25)
	dungeon.w.goblin_died.connect(_on_enemy_died)
	dungeon.w.player.died.connect(_on_player_died)
	_build_overlay()
	_sweep()
	MiscVfx.summon(get_parent(), global_position, 1.3)
	Sfx.play_at("summon", global_position)
	dungeon.w.hud.show_banner(Lang.t("Mgła Nawii wylewa się na loch!\nGęstnieje co minutę - wróć do Słupa albo otwórz portal (B), żeby zabrać łup"), COLOR)
	_update_label()


## Mgła na ekranie i pasek gęstości (pod HUD-em, za jego oknami).
func _build_overlay() -> void:
	var hud: Node = dungeon.w.hud
	_fog = ColorRect.new()
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = FOG_SHADER
	_fog.material = _fog_mat
	hud.add_child(_fog)
	hud.move_child(_fog, 0)
	_bar = VBoxContainer.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_bar.offset_left = -150.0
	_bar.offset_right = 150.0
	_bar.offset_top = 52.0
	_bar.add_theme_constant_override("separation", 1)
	_bar_title = _bar_label(10)
	_bar.add_child(_bar_title)
	_bar_step = ProgressBar.new()
	_bar_step.show_percentage = false
	_bar_step.custom_minimum_size = Vector2(300, 5)
	_bar_step.max_value = 1.0
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.06, 0.06, 0.12, 0.85)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR
	_bar_step.add_theme_stylebox_override("background", back)
	_bar_step.add_theme_stylebox_override("fill", fill)
	_bar.add_child(_bar_step)
	_bar_pool = _bar_label(8)
	_bar.add_child(_bar_pool)
	hud.add_child(_bar)
	_update_overlay()


func _bar_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR.lightened(0.35))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_overlay() -> void:
	if _bar == null:
		return
	var size := get_viewport().get_visible_rect().size
	_fog_mat.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	_fog_mat.set_shader_parameter("density", FOG_MAX * minf(density / float(Dungeons.MIST_MAX), 1.0))
	_bar_title.text = Lang.t("Mgła Nawii: gęstość %d/%d  (potwory +%d%%)") % [density, int(rules["max"]),
			roundi(Dungeons.MIST_POWER * density * 100.0)]
	_bar_step.value = 1.0 if density >= int(rules["max"]) else fposmod(_elapsed, float(rules["step"])) / float(rules["step"])
	_bar_pool.text = Lang.t("Pula: %d przedm., %d zł, kamienie wsparcia %d, krzesiwa %d, wielkie %d  (łup +%d%%)") % [
			int(pool["items"]), int(pool["gold"]), int(pool["supports"]), int(pool["flints"]), int(pool["great"]),
			roundi(Dungeons.MIST_LOOT * density * 100.0)]


func _update_label() -> void:
	if _label == null:
		return
	match state:
		"idle":
			_label.text = Lang.t("Mglisty Słup")
		"open":
			_label.text = "%s\n%s" % [Lang.t("Mglisty Słup"), Lang.t("F - rozwiej Mgłę i zabierz łup")]
		_:
			_label.visible = false


func _process(delta: float) -> void:
	_puff_timer -= delta
	if _puff_timer <= 0.0 and state != "closed":
		_puff_timer = 0.35 if state == "open" else 0.9
		var at := global_position + Vector2(_rng.randf_range(-26, 26), _rng.randf_range(-70, 4))
		MiscVfx.puff(get_parent(), at, COLOR, 0.9)
	if state != "open":
		return
	_elapsed += delta
	var wanted := mini(int(rules["max"]), 1 + int(_elapsed / float(rules["step"])))
	while density < wanted:
		_thicken()
	_sweep_timer -= delta
	if _sweep_timer <= 0.0:
		_sweep_timer = SWEEP_EVERY
		_sweep()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = Dungeons.MIST_SPAWN_EVERY
		var missing := Dungeons.mist_wraiths(density, int(dungeon.config.get("tier", 1))) - wraiths.size()
		if missing > 0:
			_spawn_pack(mini(missing, _rng.randi_range(Dungeons.MIST_PACK.x, Dungeons.MIST_PACK.y)))
	_update_overlay()


## Kolejny stopień gęstości (co trzeci - nowa cecha elit).
func _thicken() -> void:
	density += 1
	var text := Lang.t("Mgła gęstnieje: %d/%d") % [density, int(rules["max"])]
	if density % Dungeons.MIST_TRAIT_EVERY == 0:
		var options: Array = Dungeons.ELITE_TRAITS.keys().filter(func(t: String) -> bool: return not traits.has(t))
		if not options.is_empty():
			var picked: String = options[_rng.randi_range(0, options.size() - 1)]
			traits.append(picked)
			text += "\n" + Lang.t("Zjawy zyskują cechę: %s") % Lang.t(Dungeons.ELITE_TRAITS[picked]["name"])
	dungeon.w.hud.show_banner(text, COLOR)
	Sfx.play("summon")
	_sweep()


## Wszystkie potwory lochu dostają siłę z gęstości (target - mnożnik; 1 - zdjęcie Mgły); zjawy zostawione
## daleko w tyle znikają.
func _sweep(target := -1.0) -> void:
	var power := Dungeons.mist_power(density) if target < 0.0 else target
	for value in dungeon.w._live_goblins.values():
		if is_instance_valid(value) and value is Goblin and value.state != Goblin.State.DEAD:
			empower(value, power)
	if target >= 0.0:
		return
	var player_at: Vector2 = dungeon.w.player.global_position
	for entry: Array in wraiths.duplicate():
		var wraith: Goblin = entry[0]
		if is_instance_valid(wraith) and wraith.global_position.distance_to(player_at) > Dungeons.MIST_DESPAWN:
			wraiths.erase(entry)
			_vanish(wraith, entry[1])


## Ustawia mnożnik zdrowia i obrażeń potwora z Mgły. Statystyki sprzed Mgły pamięta meta "mist_base", więc mnożnik
## można zmieniać bez narastania błędów zaokrągleń; 1 - zdjęcie Mgły. Zdrowie zostaje w tej samej części.
static func empower(goblin: Goblin, power: float) -> void:
	if is_equal_approx(float(goblin.get_meta("mist", 1.0)), power):
		return
	if not goblin.has_meta("mist_base"):
		var stats := {"max_health": goblin.max_health}
		for key: String in _damage_props(goblin):
			stats[key] = goblin.get(key)
		goblin.set_meta("mist_base", stats)
	var base: Dictionary = goblin.get_meta("mist_base")
	var fraction := float(goblin.health) / maxf(goblin.max_health, 1.0)
	goblin.max_health = maxi(1, roundi(base["max_health"] * power))
	goblin.health = clampi(roundi(goblin.max_health * fraction), 1, goblin.max_health)
	for key: String in _damage_props(goblin):
		if int(base[key]) > 0:
			goblin.set(key, maxi(1, roundi(base[key] * power)))
	if is_equal_approx(power, 1.0):
		goblin.remove_meta("mist")
		goblin.remove_meta("mist_base")
	else:
		goblin.set_meta("mist", power)


static func _damage_props(goblin: Goblin) -> Array:
	var script: Script = goblin.get_script()
	if not _damage_keys.has(script):
		var keys := []
		for property in goblin.get_property_list():
			var key: String = property["name"]
			if key.ends_with("damage") and property["type"] == TYPE_INT and key != "traveler_damage" and key != "event_damage":
				keys.append(key)
		_damage_keys[script] = keys
	return _damage_keys[script]


## Gromada zjaw w wolnym miejscu lochu w pewnej odległości od gracza.
func _spawn_pack(count: int) -> void:
	var player_at: Vector2 = dungeon.w.player.global_position
	var spot := Vector2.INF
	for attempt in 10:
		var at := player_at + Vector2.from_angle(_rng.randf() * TAU) \
				* _rng.randf_range(Dungeons.MIST_SPAWN_RANGE.x, Dungeons.MIST_SPAWN_RANGE.y)
		if _free(at):
			spot = at
			break
	if spot == Vector2.INF:
		return
	for i in count:
		var at := spot if i == 0 else spot + Vector2(_rng.randf_range(-28, 28), _rng.randf_range(-22, 22))
		if i == 0 or _free(at):
			_spawn_wraith(at, i == 0)


func _free(at: Vector2) -> bool:
	return dungeon._walkable(Vector2i((at / Dungeon.CELL).round())) and not dungeon._blocked(at, 8.0)


## Nowa zjawa (potwór klimatu lochu); przewodnik gromady może zostać elitą z cechami Mgły.
func _spawn_wraith(at: Vector2, leader: bool) -> Goblin:
	var kind: String = dungeon._pick(dungeon.climate["monsters"])
	var spawn: Dictionary = dungeon._spawn(kind, at, dungeon.w.player.global_position, dungeon.level)
	var wraith: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if wraith == null:
		return null
	if wraith.speed <= 0.0:
		# nieruchome potwory (kokony) nie nadają się na zjawy
		_vanish(wraith, spawn["id"])
		return null
	haunt(wraith)
	if leader and not traits.is_empty() and _rng.randf() < Dungeons.MIST_ELITE_CHANCE:
		var elite_traits: Array[String] = traits.duplicate()
		DungeonElite.promote(wraith, elite_traits, dungeon, kind)
	empower(wraith, Dungeons.mist_power(density))
	wraiths.append([wraith, spawn["id"]])
	wraith.died.connect(_on_wraith_died)
	MiscVfx.puff(get_parent(), wraith.global_position + Vector2(0, -6), COLOR, 0.8)
	return wraith


## Zmienia potwora w zjawę Mgły: wygląd upiora, słabszy, mniej łupu (łup daje pula Mgły).
func haunt(wraith: Goblin) -> void:
	wraith.max_health = maxi(1, roundi(wraith.max_health * Dungeons.MIST_WRAITH_HEALTH))
	wraith.health = wraith.max_health
	for key: String in _damage_props(wraith):
		var value: int = wraith.get(key)
		if value > 0:
			wraith.set(key, maxi(1, roundi(value * Dungeons.MIST_WRAITH_DAMAGE)))
	wraith.xp_reward = roundi(wraith.xp_reward * Dungeons.MIST_WRAITH_XP)
	wraith.equipment_drop_chance *= 0.3
	wraith.heart_drop_chance = 0.0
	wraith.gold_max = wraith.gold_min
	wraith.map_color = COLOR
	wraith.set_meta("ghost", true)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ghost", COLOR)
	mat.set_shader_parameter("phase", _rng.randf() * TAU)
	wraith.sprite.material = mat
	wraith.sitting = false
	wraith.appear()
	wraith.aggro()


func _on_wraith_died(wraith: Goblin) -> void:
	wraiths = wraiths.filter(func(entry: Array) -> bool: return entry[0] != wraith)


## Każdy wróg zabity w Mgle (zjawa albo zwykły potwór lochu) dokłada do puli.
func _on_enemy_died(_enemy: Goblin) -> void:
	if state != "open":
		return
	kills += 1
	add_kill(pool, density, dungeon.level, rules)


## Pula za jednego zabitego przy gęstości `density` (poziom lochu - złoto, `with_rules` - Dungeons.mist_rules).
static func add_kill(target: Dictionary, at_density: int, level: int, with_rules := {}) -> void:
	if with_rules.is_empty():
		with_rules = Dungeons.mist_rules({})
	var loot := Dungeons.mist_loot(at_density)
	var rate := Dungeons.mist_rate(at_density) * float(with_rules["rate"])
	target["items"] += Dungeons.MIST_ITEMS_PER_KILL * loot
	target["gold"] += Dungeons.MIST_GOLD_PER_KILL * Levels.gold(level) * loot
	target["supports"] += Dungeons.MIST_SUPPORT_RATE * rate
	target["flints"] += Dungeons.MIST_FLINT_RATE * rate
	if at_density >= int(with_rules["great_from"]):
		target["great"] += Dungeons.MIST_GREAT_RATE * float(with_rules["rate"])


func _on_player_died() -> void:
	close("death")


## Koniec Mgły: "pillar" - przy Słupie, "portal" - portal do miasta, "death" - śmierć (przepada część puli).
## Słup wysypuje Skrzynię Mgły.
func close(reason: String) -> void:
	if state != "open":
		return
	state = "closed"
	set_process(false)
	set_progress(0.0)
	if dungeon.w.goblin_died.is_connected(_on_enemy_died):
		dungeon.w.goblin_died.disconnect(_on_enemy_died)
	if dungeon.w.player.died.is_connected(_on_player_died):
		dungeon.w.player.died.disconnect(_on_player_died)
	for entry: Array in wraiths:
		if is_instance_valid(entry[0]):
			_vanish(entry[0], entry[1])
	wraiths.clear()
	_sweep(1.0)
	_remove_overlay()
	sprite.modulate = TINT.darkened(0.3)
	if glow != null:
		glow.visible = false
	var keep := float(rules["keep"]) if reason == "death" else 1.0
	var counts := spill(keep * dungeon.mechanic_power("mist"))
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -40), COLOR, 1.4)
	Sfx.play("quest_ready")
	_update_label()
	var text := Lang.t("Mgła się rozwiewa - Skrzynia Mgły przy Słupie\nGęstość %d, pokonani: %d, przedmioty: %d, kamienie wsparcia: %d, krzesiwa: %d") \
			% [density, kills, counts["items"], counts["supports"], counts["flints"] + counts["great"]]
	if reason == "death":
		text = Lang.t("Śmierć w Mgle - przepada %d%% puli") % roundi((1.0 - keep) * 100.0) + "\n" + text
	dungeon.w.hud.show_banner(text, COLOR)


## Skrzynia Mgły: łup z puli (razy `scale`) wysypany przy Słupie. Zwraca liczby wysypanych rzeczy.
func spill(scale: float) -> Dictionary:
	var chest := Sprite2D.new()
	chest.texture = CHEST_TEXTURE
	chest.scale = Vector2.ONE * 1.6
	chest.modulate = TINT
	chest.position = Vector2(30, 14)
	chest.offset = Vector2(0, -CHEST_TEXTURE.get_height() / 2.0 + 2.0)
	add_child(chest)
	var at := global_position + Vector2(0, 30)
	var counts := {}
	for key: String in ["items", "supports", "flints", "great"]:
		counts[key] = _round(float(pool[key]) * scale)
	var tier := int(dungeon.config.get("tier", 1))
	for i in counts["items"]:
		dungeon._drop(at, Loot.drop_at_level(dungeon.level, 0.15 + 0.03 * density, Loot.MAGIC), 1)
	for i in counts["supports"]:
		dungeon._drop(at, Supports.roll("", Dungeons.mist_support_level(tier, density, _rng, int(rules["level"]))), 1)
	dungeon._drop(at, Supports.FLINT, counts["flints"])
	dungeon._drop(at, Supports.GREAT_FLINT, counts["great"])
	dungeon._drop(at, "gold", roundi(float(pool["gold"]) * scale))
	return counts


## Losowe zaokrąglenie (2,3 -> 2 albo 3 z szansą 30%).
func _round(value: float) -> int:
	var whole := int(floor(value))
	return whole + (1 if _rng.randf() < value - whole else 0)


func _remove_overlay() -> void:
	for node: Control in [_fog, _bar]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_fog = null
	_bar = null


func _exit_tree() -> void:
	_remove_overlay()


## Zjawa znika bez łupu (koniec Mgły albo zostawiona w tyle).
func _vanish(wraith: Goblin, spawn_id: int) -> void:
	if wraith.state == Goblin.State.DEAD:
		return
	wraith.state = Goblin.State.DEAD
	wraith.remove_from_group("enemies")
	wraith.remove_from_group("elites")
	wraith.get_node("CollisionShape2D").set_deferred("disabled", true)
	dungeon.w._live_goblins.erase(spawn_id)
	MiscVfx.puff(wraith.get_parent(), wraith.global_position + Vector2(0, -6), COLOR, 0.7)
	var tween := wraith.create_tween()
	tween.tween_property(wraith, "modulate:a", 0.0, 0.4)
	tween.tween_callback(wraith.queue_free)


func _draw() -> void:
	super()
	if state == "closed":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 40.0, Color(COLOR, 0.16 if state == "idle" else 0.3))
	draw_circle(Vector2.ZERO, 26.0, Color(COLOR, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
