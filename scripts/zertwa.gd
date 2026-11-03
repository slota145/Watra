class_name Zertwa
extends Harvestable
## Krąg Żertwy w lochu (mechanika "zertwa", stałe ZER_* w Dungeons) - jak Ritual w Path of Exile. Pień ofiarny
## z porożem i świecami; dotknięty (F) zapala krwawy krąg wokół siebie, a spoza kręgu nadciągają fale potworów
## klimatu lochu. Każdy wróg zabity w kręgu to danina (elity i Wybrańcy - więcej). Po zebraniu ZER_GOAL daniny pień
## czeka na odebranie nagrody: F otwiera wybór 1 z 3 talizmanów (Talismans.roll_offer, okno TalismanOffer). Kto
## zamiast odebrać walczy dalej (do ZER_GOAL * ZER_OVERFLOW daniny), dostaje lepszą ofertę (więcej rzadkich
## i wielkich talizmanów). Okno zamknięte bez wyboru otwiera się znów przy pniu.
## Budowane w kodzie (Zertwa.create), bez sceny.

const TEXTURE := preload("res://assets/ancient/altar_stump.png")
const TOUCH_TIME := 0.8
const SCALE := 1.25
const COLOR := Color(1.0, 0.32, 0.22)
const CHOSEN_COLOR := Color(1.0, 0.55, 0.2)
const RING_SHADER := preload("res://shaders/uroczysko.gdshader")

var dungeon: Node
## "idle" - czeka na dotknięcie, "open" - krąg zbiera daninę, "ready" - danina zebrana (można odebrać albo walczyć
## dalej), "reward" - oferta czeka na wybór, "closed" - po wszystkim.
var state := "idle"
var tribute := 0
var kills := 0
## Potwory fal: żywe [Goblin, id miejsca].
var wave: Array = []
## Wylosowana oferta talizmanów (po odebraniu nagrody).
var offer: Array[String] = []
## Poświata z lochu (Dungeon._glow) - gaśnie po wyborze nagrody.
var glow: Sprite2D
var _spawn_timer := 0.0
var _chosen_due := 0
var _ring: Sprite2D
var _ring_mat: ShaderMaterial
var _label: Label
var _rng := RandomNumberGenerator.new()


static func create(owner_dungeon: Node) -> Zertwa:
	var altar := Zertwa.new()
	altar.dungeon = owner_dungeon
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 8.0)
	altar.add_child(sprite)
	return altar


func _init() -> void:
	action_name = Lang.t("Złóż ofiarę")
	harvest_time = TOUCH_TIME
	chip_color = COLOR
	hit_sound = ""
	break_sound = "magic"
	bar_height = 64.0
	bar_color = COLOR
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_rng.randomize()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", COLOR.lightened(0.45))
	_label.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.03))
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


func can_harvest() -> bool:
	return state in ["idle", "ready", "reward"]


func harvest(_from: Vector2) -> void:
	set_progress(0.0)
	match state:
		"idle":
			open()
		"ready":
			claim()
		"reward":
			_show_offer()


## Dotknięcie pnia: zapala się krąg, ruszają fale.
func open() -> void:
	if state != "idle":
		return
	state = "open"
	_ring = Sprite2D.new()
	var texture := GradientTexture2D.new()
	texture.width = 8
	texture.height = 8
	_ring.texture = texture
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = RING_SHADER
	_ring_mat.set_shader_parameter("color", COLOR)
	_ring_mat.set_shader_parameter("radius", Dungeons.ZER_RADIUS)
	_ring.material = _ring_mat
	_floor_layer().add_child(_ring)
	_ring.global_position = global_position
	_ring.scale = Vector2.ONE * Dungeons.ZER_RADIUS * 2.0 / 8.0
	if dungeon != null and dungeon.w != null:
		dungeon.w.goblin_died.connect(_on_goblin_died)
		dungeon.w.hud.show_banner(Lang.t("Krąg Żertwy!\nZabijaj wrogów w kręgu, żeby złożyć daninę"), COLOR)
	MiscVfx.summon(get_parent(), global_position, 1.2)
	Sfx.play_at("summon", global_position)
	set_process(true)
	_update_label()
	queue_redraw()


func _floor_layer() -> Node:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	return layer if layer != null else get_parent()


## Ile daniny daje nadwyżka do lepszej oferty (danina po progu).
func max_tribute() -> int:
	return roundi(Dungeons.ZER_GOAL * Dungeons.ZER_OVERFLOW)


## Nadwyżka daniny 0..1 (0 - równo próg, 1 - pełna nadwyżka) - podnosi szanse w ofercie.
func overflow() -> float:
	return clampf(float(tribute - Dungeons.ZER_GOAL) / float(max_tribute() - Dungeons.ZER_GOAL), 0.0, 1.0)


func _process(delta: float) -> void:
	if state != "open" and state != "ready":
		return
	if tribute >= max_tribute():
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = Dungeons.ZER_SPAWN_EVERY
	wave = wave.filter(func(entry: Array) -> bool: return is_instance_valid(entry[0]) and entry[0].state != Goblin.State.DEAD)
	if _chosen_due > 0:
		if _spawn_attacker(true) != null:
			_chosen_due -= 1
	elif wave.size() < Dungeons.ZER_ALIVE:
		_spawn_attacker(false)


## Nowy potwór fali tuż za brzegiem kręgu (podłoga lochu) - od razu rusza na gracza; null, gdy nie ma miejsca.
func _spawn_attacker(chosen: bool) -> Goblin:
	var spot := Vector2.INF
	for attempt in 12:
		var gap := _rng.randf_range(Dungeons.ZER_SPAWN_GAP.x, Dungeons.ZER_SPAWN_GAP.y)
		# gdy za brzegiem jest ściana - skraj kręgu
		if attempt >= 8:
			gap = -_rng.randf_range(10.0, 50.0)
		var at := global_position + Vector2.from_angle(_rng.randf() * TAU) * (Dungeons.ZER_RADIUS + gap)
		if dungeon._walkable(Vector2i((at / Dungeon.CELL).round())) and not dungeon._blocked(at, 8.0):
			spot = at
			break
	if spot == Vector2.INF:
		return null
	var kind: String = dungeon._pick(dungeon.climate["monsters"])
	var spawn: Dictionary = dungeon._spawn(kind, spot, global_position, dungeon.level)
	var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if goblin == null:
		return null
	if goblin.speed <= 0.0:
		# nieruchome potwory (kokony) nie przyjdą do kręgu
		goblin.state = Goblin.State.DEAD
		goblin.remove_from_group("enemies")
		dungeon.w._live_goblins.erase(spawn["id"])
		goblin.queue_free()
		return null
	mark(goblin, chosen)
	wave.append([goblin, spawn["id"]])
	MiscVfx.puff(get_parent(), goblin.global_position + Vector2(0, -6), COLOR, 0.8)
	return goblin


## Potwór fali: mniej nagród (danina to nagroda), Wybraniec - większy i mocniejszy.
func mark(goblin: Goblin, chosen := false) -> void:
	goblin.xp_reward = roundi(goblin.xp_reward * (Dungeons.ZER_XP * 3.0 if chosen else Dungeons.ZER_XP))
	goblin.equipment_drop_chance *= 1.0 if chosen else Dungeons.ZER_ITEMS
	goblin.heart_drop_chance = 0.0
	goblin.home = global_position
	goblin.set_meta("zertwa", true)
	if chosen:
		goblin.set_meta("zertwa_chosen", true)
		goblin.max_health = maxi(1, roundi(goblin.max_health * Dungeons.ZER_CHOSEN_HEALTH))
		goblin.health = goblin.max_health
		for property in goblin.get_property_list():
			var key: String = property["name"]
			if key.ends_with("damage") and property["type"] == TYPE_INT and goblin.get(key) > 0 \
					and key != "traveler_damage" and key != "event_damage":
				goblin.set(key, maxi(1, roundi(goblin.get(key) * Dungeons.ZER_CHOSEN_DAMAGE)))
		goblin.scale = Vector2.ONE * 1.35
		goblin.hurt_radius *= 1.35
		goblin.hurt_height *= 1.35
		goblin.map_color = CHOSEN_COLOR
		goblin.sprite.modulate = Color(1.25, 0.8, 0.7)
	goblin.sitting = false
	goblin.appear()
	goblin.aggro()


## Ile daniny daje pokonany wróg (elity, Wybrańcy i bossowie - więcej).
static func tribute_of(goblin: Goblin) -> int:
	if goblin.elite != null or goblin is Boss or goblin.has_meta("zertwa_chosen"):
		return Dungeons.ZER_ELITE_TRIBUTE
	return Dungeons.ZER_TRIBUTE


## Wróg zginął gdziekolwiek w lochu - liczy się, jeśli padł w kręgu.
func _on_goblin_died(goblin: Goblin) -> void:
	if state != "open" and state != "ready":
		return
	if goblin.global_position.distance_to(global_position) > Dungeons.ZER_RADIUS + 6.0:
		return
	add_tribute(tribute_of(goblin), goblin.global_position)


func add_tribute(amount: int, at := Vector2.INF) -> void:
	var before := tribute
	tribute = mini(tribute + amount, max_tribute())
	kills += 1
	@warning_ignore("integer_division")
	_chosen_due += tribute / Dungeons.ZER_CHOSEN_EVERY - before / Dungeons.ZER_CHOSEN_EVERY
	if at != Vector2.INF and tribute > before:
		MiscVfx.spark(get_parent(), at + Vector2(0, -8), COLOR, 0.5)
	if state == "open" and tribute >= Dungeons.ZER_GOAL:
		state = "ready"
		Sfx.play("quest_ready")
		if dungeon != null and dungeon.w != null:
			dungeon.w.hud.show_banner(Lang.t("Danina złożona!\nF przy pniu - nagroda, walka dalej - lepsza nagroda"), COLOR)
	if tribute >= max_tribute() and before < max_tribute() and dungeon != null and dungeon.w != null:
		dungeon.w.hud.show_banner(Lang.t("Bogowie są syci\nOdbierz nagrodę przy pniu"), COLOR)
	_update_label()


## Odebranie nagrody: krąg gaśnie, fale ustają (żywi zostają jak zwykłe potwory), losuje się oferta talizmanów.
func claim() -> void:
	if state != "ready":
		return
	state = "reward"
	if dungeon != null and dungeon.w != null and dungeon.w.goblin_died.is_connected(_on_goblin_died):
		dungeon.w.goblin_died.disconnect(_on_goblin_died)
	_close_ring()
	var tier := Dungeons.config_tier(dungeon.config) if dungeon != null else 1
	var item_level: int = clampi((dungeon.level if dungeon != null else 1) + tier * Dungeons.ZER_LEVEL_PER_TIER, 1, Loot.MAX_ITEM_LEVEL)
	var choices := Dungeons.ZER_OFFER + (1 if dungeon != null and dungeon.mechanic_power("zertwa") > 1.0 else 0)
	offer = Talismans.roll_offer(item_level, overflow(), choices, _rng)
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -40), COLOR, 1.4)
	_update_label()
	_show_offer()


func _close_ring() -> void:
	if _ring == null:
		return
	var ring := _ring
	_ring = null
	var mat := _ring_mat
	var tween := ring.create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("strength", v), 1.0, 0.0, 0.8)
	tween.tween_callback(ring.queue_free)


func _show_offer() -> void:
	if dungeon == null or dungeon.w == null or dungeon.w.hud.get("talisman_offer") == null:
		return
	dungeon.w.hud.talisman_offer.open(offer, choose, overflow())


## Gracz wybrał talizman z oferty: trafia do plecaka (albo na ziemię), pień gaśnie.
func choose(id: String) -> void:
	if state != "reward" or not offer.has(id):
		return
	state = "closed"
	set_process(false)
	sprite.modulate = Color(0.65, 0.6, 0.6)
	if glow != null:
		glow.visible = false
	if dungeon != null and dungeon.w != null:
		dungeon.w.player._gain_item(id, 1)
	Sfx.play("pickup_rare")
	_update_label()
	queue_redraw()


func _update_label() -> void:
	if _label == null:
		return
	match state:
		"idle":
			_label.text = Lang.t("Krąg Żertwy")
		"open", "ready":
			_label.text = "%s\n%s" % [Lang.t("Krąg Żertwy"), Lang.t("Danina: %d/%d") % [tribute, Dungeons.ZER_GOAL]]
			if state == "ready":
				_label.text += " (+%d%%)" % roundi(overflow() * 100.0)
		"reward":
			_label.text = Lang.t("Wybierz nagrodę (F)")
		_:
			_label.visible = false


func _draw() -> void:
	super()
	if state == "closed":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 36.0, Color(COLOR, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
