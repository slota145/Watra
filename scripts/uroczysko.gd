class_name Uroczysko
extends Harvestable
## Uroczysko w lochu (mechanika "uroczysko", stałe URO_* w Dungeons) - jak Breach w Path of Exile. Omszały menhir
## ze zgaszoną spiralą; dotknięty (klawisz F) rozpala się i otwiera krąg innego świata, z którego wychodzą upiory -
## potwory klimatu lochu jako sinozielone zjawy (shaders/ghost.gdshader). Upiory żyją tylko w kręgu (nie wychodzą
## poza brzeg, znikają razem z nim), zwykłe potwory lochu działają po staremu.
## Krąg ciągle się kurczy (coraz szybciej), a każdy zabity upiór go poszerza - kto szybko zabija, ten dłużej trzyma
## krąg i zbiera więcej run. Gdy krąg zmaleje do URO_END, gaśnie: upiory rozwiewają się, a menhir sypie runy
## (ItemCraft.RUNES) - tym więcej, im więcej upiorów padło. Co URO_LORD_EVERY zabitych z kręgu wychodzi Upiorny Pan
## (większy i mocniejszy, zawsze zostawia runę); zwykły upiór czasem upuszcza runę sam.
## Budowane w kodzie (Uroczysko.create), bez sceny.

const TEXTURE := preload("res://assets/ancient/menhir_1.png")
const TOUCH_TIME := 0.8
const SCALE := 1.4
const COLOR := Color(0.45, 1.0, 0.78)
const LORD_COLOR := Color(0.75, 0.6, 1.0)
const SHADER := preload("res://shaders/ghost.gdshader")
const RING_SHADER := preload("res://shaders/uroczysko.gdshader")
## Co tyle sekund upiory są przytrzymywane w kręgu (i liczone na nowo).
const KEEP_EVERY := 0.1

var dungeon: Node
## "idle" - czeka na dotknięcie, "open" - krąg otwarty, "closed" - po wszystkim.
var state := "idle"
var radius := 0.0
var best_radius := 0.0
var kills := 0
## Żywe upiory: [Goblin, id miejsca w świecie].
var ghosts: Array = []
## Poświata z lochu (Dungeon._glow) - gaśnie po zamknięciu kręgu.
var glow: Sprite2D
var _elapsed := 0.0
var _spawn_timer := 0.0
var _keep_timer := 0.0
var _lords_due := 0
var _ring: Sprite2D
var _ring_mat: ShaderMaterial
var _label: Label
var _rng := RandomNumberGenerator.new()


static func create(owner_dungeon: Node) -> Uroczysko:
	var stone := Uroczysko.new()
	stone.dungeon = owner_dungeon
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.hframes = 2
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 3.0)
	stone.add_child(sprite)
	return stone


func _init() -> void:
	action_name = Lang.t("Dotknij kamienia")
	harvest_time = TOUCH_TIME
	chip_color = COLOR
	hit_sound = ""
	break_sound = "magic"
	bar_height = 80.0
	bar_color = COLOR
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_rng.randomize()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", COLOR.lightened(0.4))
	_label.add_theme_color_override("font_outline_color", Color(0.03, 0.07, 0.06))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(160, 30)
	_label.position = Vector2(-80, -bar_height - 12.0 - _label.size.y)
	_label.z_index = 30
	if dungeon != null:
		_label.modulate = dungeon.label_boost()
	add_child(_label)
	_update_label()


func can_harvest() -> bool:
	return state == "idle"


## Dotknięcie kamienia: spirala się rozpala, krąg otwiera.
func harvest(_from: Vector2) -> void:
	if state != "idle":
		return
	set_progress(0.0)
	open()


func open() -> void:
	state = "open"
	radius = Dungeons.URO_START
	best_radius = radius
	sprite.frame = 1
	_ring = Sprite2D.new()
	var texture := GradientTexture2D.new()
	texture.width = 8
	texture.height = 8
	_ring.texture = texture
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = RING_SHADER
	_ring_mat.set_shader_parameter("color", COLOR)
	_ring.material = _ring_mat
	_floor_layer().add_child(_ring)
	_ring.global_position = global_position
	_resize_ring()
	MiscVfx.summon(get_parent(), global_position, 1.2)
	Sfx.play_at("summon", global_position)
	dungeon.w.hud.show_banner(Lang.t("Uroczysko otwarte!\nZabijaj upiory, żeby krąg nie zgasł"), COLOR)
	set_process(true)
	queue_redraw()


func _floor_layer() -> Node:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	return layer if layer != null else get_parent()


func _resize_ring() -> void:
	if _ring == null:
		return
	_ring.scale = Vector2.ONE * radius * 2.0 / 8.0
	_ring_mat.set_shader_parameter("radius", radius)


func _update_label() -> void:
	if _label == null:
		return
	match state:
		"idle":
			_label.text = Lang.t("Uroczysko")
		"open":
			_label.text = "%s\n%s" % [Lang.t("Uroczysko"), Lang.t("Upiory: %d") % kills]
		_:
			_label.visible = false


func _process(delta: float) -> void:
	if state != "open":
		return
	_elapsed += delta
	if _elapsed > Dungeons.URO_GRACE:
		radius -= Dungeons.URO_SHRINK * (1.0 + (_elapsed - Dungeons.URO_GRACE) / Dungeons.URO_SPEEDUP) * delta
	if radius <= Dungeons.URO_END:
		close()
		return
	_resize_ring()
	_keep_timer -= delta
	if _keep_timer <= 0.0:
		_keep_timer = KEEP_EVERY
		_keep_inside()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = Dungeons.URO_SPAWN_EVERY
		if _lords_due > 0:
			if _spawn_ghost(true) != null:
				_lords_due -= 1
		elif ghosts.size() < wanted_ghosts():
			_spawn_ghost(false)


## Ilu upiorów naraz chce krąg (więcej przy większym kręgu).
func wanted_ghosts() -> int:
	return Dungeons.URO_ALIVE + int(radius / Dungeons.URO_ALIVE_PER)


## Upiory nie wychodzą poza brzeg kręgu (także gdy krąg się kurczy).
func _keep_inside() -> void:
	var limit := maxf(radius - 6.0, 4.0)
	for entry: Array in ghosts:
		var ghost: Goblin = entry[0]
		if not is_instance_valid(ghost) or ghost.state == Goblin.State.DEAD:
			continue
		var offset := ghost.global_position - global_position
		if offset.length() > limit:
			ghost.global_position = global_position + offset.normalized() * limit
			ghost.velocity = Vector2.ZERO


## Nowy upiór w wolnym miejscu kręgu (podłoga lochu, nie w ścianie); null, gdy nie ma miejsca.
func _spawn_ghost(lord: bool) -> Goblin:
	var spot := Vector2.INF
	for attempt in 8:
		var at := global_position + Vector2.from_angle(_rng.randf() * TAU) * radius * sqrt(_rng.randf_range(0.12, 0.85))
		if dungeon._walkable(Vector2i((at / Dungeon.CELL).round())) and not dungeon._blocked(at, 8.0):
			spot = at
			break
	if spot == Vector2.INF:
		return null
	var kind: String = dungeon._pick(dungeon.climate["monsters"])
	var spawn: Dictionary = dungeon._spawn(kind, spot, global_position, dungeon.level)
	var ghost: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if ghost == null:
		return null
	if ghost.speed <= 0.0:
		# nieruchome potwory (kokony) nie nadają się na zjawy
		_vanish(ghost, spawn["id"])
		return null
	haunt(ghost, lord)
	ghosts.append([ghost, spawn["id"]])
	ghost.died.connect(_on_ghost_died.bind(lord))
	MiscVfx.puff(get_parent(), ghost.global_position + Vector2(0, -6), COLOR, 0.8)
	return ghost


## Zmienia potwora w upiora: wygląd zjawy, słabszy (Upiorny Pan - mocniejszy), mniej łupu.
func haunt(ghost: Goblin, lord := false) -> void:
	var health := Dungeons.URO_LORD_HEALTH if lord else Dungeons.URO_HEALTH
	var damage := Dungeons.URO_LORD_DAMAGE if lord else Dungeons.URO_DAMAGE
	ghost.max_health = maxi(1, roundi(ghost.max_health * health))
	ghost.health = ghost.max_health
	for property in ghost.get_property_list():
		var key: String = property["name"]
		if key.ends_with("damage") and property["type"] == TYPE_INT and ghost.get(key) > 0 \
				and key != "traveler_damage" and key != "event_damage":
			ghost.set(key, maxi(1, roundi(ghost.get(key) * damage)))
	ghost.xp_reward = roundi(ghost.xp_reward * (Dungeons.URO_XP * 4.0 if lord else Dungeons.URO_XP))
	ghost.equipment_drop_chance *= 1.0 if lord else 0.3
	ghost.heart_drop_chance = 0.0
	ghost.gold_max = ghost.gold_min
	ghost.home = global_position
	ghost.map_color = LORD_COLOR if lord else COLOR
	ghost.set_meta("ghost", true)
	if lord:
		ghost.scale = Vector2.ONE * 1.4
		ghost.hurt_radius *= 1.4
		ghost.hurt_height *= 1.4
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ghost", LORD_COLOR if lord else COLOR)
	mat.set_shader_parameter("phase", _rng.randf() * TAU)
	ghost.sprite.material = mat
	ghost.sitting = false
	ghost.appear()
	ghost.aggro()


func _on_ghost_died(ghost: Goblin, lord: bool) -> void:
	ghosts = ghosts.filter(func(entry: Array) -> bool: return entry[0] != ghost)
	if state != "open":
		return
	kills += 1
	radius = minf(Dungeons.URO_MAX, radius + Dungeons.URO_GROW * (1.0 - 0.6 * radius / Dungeons.URO_MAX))
	best_radius = maxf(best_radius, radius)
	if kills % Dungeons.URO_LORD_EVERY == 0:
		_lords_due += 1
	var tier := int(dungeon.config.get("tier", 1))
	if lord or _rng.randf() < Dungeons.URO_GHOST_RUNE:
		dungeon._drop(ghost.global_position, ItemCraft.roll_rune(tier, _rng), 1)
	_update_label()


## Krąg gaśnie: upiory się rozwiewają, menhir sypie runy.
func close() -> void:
	if state != "open":
		return
	state = "closed"
	set_process(false)
	for entry: Array in ghosts:
		if is_instance_valid(entry[0]):
			_vanish(entry[0], entry[1])
	ghosts.clear()
	if _ring != null:
		var ring := _ring
		_ring = null
		var tween := ring.create_tween()
		tween.tween_method(func(v: float) -> void: _ring_mat.set_shader_parameter("strength", v), 1.0, 0.0, 0.8)
		tween.tween_callback(ring.queue_free)
	sprite.frame = 0
	sprite.modulate = Color(0.7, 0.7, 0.75)
	if glow != null:
		glow.visible = false
	var runes := reward_runes(kills)
	var tier := int(dungeon.config.get("tier", 1))
	for i in runes:
		dungeon._drop(global_position + Vector2(0, 18), ItemCraft.roll_rune(tier, _rng), 1)
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -40), COLOR, 1.4)
	Sfx.play("quest_ready")
	_update_label()
	queue_redraw()
	dungeon.w.hud.show_banner(Lang.t("Uroczysko gaśnie\nUpiory: %d, runy: %d") % [kills, runes], COLOR)


## Ile run sypie kamień po zamknięciu kręgu (0 - nikt nie walczył).
static func reward_runes(kill_count: int) -> int:
	if kill_count <= 0:
		return 0
	@warning_ignore("integer_division")
	return mini(Dungeons.URO_RUNES_MAX, 1 + kill_count / Dungeons.URO_KILLS_PER_RUNE)


## Upiór znika bez łupu (zamknięcie kręgu).
func _vanish(ghost: Goblin, spawn_id: int) -> void:
	if ghost.state == Goblin.State.DEAD:
		return
	ghost.state = Goblin.State.DEAD
	ghost.remove_from_group("enemies")
	ghost.get_node("CollisionShape2D").set_deferred("disabled", true)
	dungeon.w._live_goblins.erase(spawn_id)
	MiscVfx.puff(ghost.get_parent(), ghost.global_position + Vector2(0, -6), COLOR, 0.7)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ghost.queue_free)


func _draw() -> void:
	super()
	if state != "idle":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 34.0, Color(COLOR, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
