class_name DungeonElite
extends Node2D
## Elitarny potwór w lochu (mechanika "elites", Dungeons.ELITE_TRAITS) - jak magiczne i rzadkie potwory w PoE.
## Zwykły potwór lochu dostaje 1-3 cechy (każda z innej grupy), jest większy, świeci w kolorze pierwszej cechy
## i ma nad głową napis z cechami. Ma więcej zdrowia i obrażeń, daje więcej doświadczenia, złota i lepszy łup.
## Grupy cech:
## - aury (Dowódczy, Poganiający, Osłaniający) wzmacniają wrogów wokół (Goblin.empower),
## - obrona (Tarczowy - odnawiana tarcza, Uzdrawiający - leczy siebie i sąsiadów, Kolczasty - odbija obrażenia),
## - żywioły (Wybuchowy - wybuch po śmierci, Płonący - płonący ślad, Mroźny - spowalniające fale, Burzowy - pioruny),
## - przywołanie (Przywołujący - przyzywa pomocników, Rozszczepialny - po śmierci dzieli się na mniejsze).
## Drzewko Watry: `idol` - elita upuszcza bożka („Bożkowe Piętno”), Czempion (make_champion) - wszystkie grupy cech,
## CHAMPION_HEALTH razy więcej zdrowia i pewna legenda, "elite_loot" (Dungeon.tree_value) - dodatkowy łup z każdej elity.
## Węzeł jest dzieckiem potwora (Goblin.elite); budowany w kodzie (DungeonElite.promote), bez sceny.

const SCALE := 1.25
const CHAMPION_HEALTH := 2.0
const CHAMPION_SCALE := 1.15
## Żywioł cech elit i dodatkowa odporność elity na ten żywioł (Elements, etap 3).
const TRAIT_ELEMENTS := {"frost": Elements.COLD, "burning": Elements.FIRE, "volatile": Elements.FIRE, "storm": Elements.LIGHTNING}
const TRAIT_RESISTANCE := 0.5
const TICK := 0.25
const AURA_RADIUS := 120.0
## Aura trwa tyle po ostatnim odświeżeniu (elita odświeża ją co AURA_EVERY).
const AURA_TIME := 1200
const AURA_EVERY := 0.5
## Tarcza wraca po tylu milisekundach bez obrażeń.
const SHIELD_DELAY := 6000
## Kolczasty: odbicie najwyżej raz na tyle milisekund, najwyżej REFLECT_CAP x obrażenia elity.
const REFLECT_EVERY := 700
const REFLECT_CAP := 1.5
const REFLECT_RANGE := 160.0
## Uzdrawiający leczy sąsiadów mocniej niż siebie.
const HEAL_ALLIES := 1.4
## Mroźny: fala co FROST_EVERY s, gdy gracz jest bliżej niż FROST_RADIUS.
const FROST_EVERY := 4.0
const FROST_RADIUS := 80.0
## Burzowy: piorun w miejscu gracza co STORM_EVERY s (zapowiedź STORM_WARN s).
const STORM_EVERY := 3.5
const STORM_WARN := 0.9
const STORM_RADIUS := 30.0
const STORM_RANGE := 260.0
## Płonący: ślad co BURN_EVERY s w ruchu, plama trwa BURN_LIFE s.
const BURN_EVERY := 0.6
const BURN_LIFE := 4.0
const BURN_RADIUS := 18.0
## Wybuchowy: zapowiedź i promień wybuchu po śmierci.
const BLAST_WARN := 1.1
const BLAST_RADIUS := 60.0
## Przywołujący: co SUMMON_EVERY s po SUMMON_COUNT pomocników, najwyżej SUMMON_MAX żywych naraz.
const SUMMON_EVERY := 8.0
const SUMMON_COUNT := 2
const SUMMON_MAX := 6
## Rozszczepialny: odpryski mają tę część zdrowia elity i są mniejsze.
const SPLIT_HEALTH := 0.2
const SPLIT_SCALE := 0.8
const LABEL_COLOR := Color(1.0, 0.85, 0.45)
## Obrys elity w kolorze pierwszej cechy (z błyskiem trafienia jak flash.gdshader).
const SHADER := preload("res://shaders/elite.gdshader")

var goblin: Goblin
var dungeon: Node
var traits: Array[String] = []
## Rodzaj potwora (klucz z Dungeons.CLIMATES "monsters") - odpryski Rozszczepialnego są tego samego rodzaju.
var kind := ""
## Drzewko Watry: elita upuszcza bożka; Czempion - pewna legenda.
var idol := false
var champion := false
var shield := 0
var max_shield := 0
var _shield_back_at := 0
var _reflect_at := 0
var _tick := 0.0
var _timers := {}
var _summons: Array[Goblin] = []
var _glow: Sprite2D
var _label: Label
var _time := 0.0
var _outline: ShaderMaterial


## Zmienia potwora w elitę z cechami `trait_ids` (potwór musi już być w scenie - statystyki z poziomu są gotowe).
static func promote(target: Goblin, trait_ids: Array[String], owner_dungeon: Node, spawn_kind: String) -> DungeonElite:
	var elite := DungeonElite.new()
	elite.goblin = target
	elite.dungeon = owner_dungeon
	elite.traits = trait_ids
	elite.kind = spawn_kind
	elite.name = "Elite"
	target.elite = elite
	elite._apply_stats()
	target.add_child(elite)
	target.move_child(elite, 0)  # poświata pod obrazkiem potwora
	return elite


## Czempion (drzewko Watry): więcej zdrowia, większy, napis „Czempion”, pewna legenda po śmierci.
func make_champion() -> void:
	champion = true
	goblin.max_health = roundi(goblin.max_health * CHAMPION_HEALTH)
	goblin.health = goblin.max_health
	goblin.scale *= CHAMPION_SCALE
	goblin.hurt_radius *= CHAMPION_SCALE
	goblin.hurt_height *= CHAMPION_SCALE
	if _label != null:
		_label.text = label_text()


func _apply_stats() -> void:
	var n := traits.size()
	goblin.max_health = maxi(1, roundi(goblin.max_health * (Dungeons.ELITE_HEALTH + Dungeons.ELITE_HEALTH_PER_TRAIT * n)))
	goblin.health = goblin.max_health
	for property in goblin.get_property_list():
		var key: String = property["name"]
		if key.ends_with("damage") and property["type"] == TYPE_INT and goblin.get(key) > 0 \
				and key != "traveler_damage" and key != "event_damage":
			goblin.set(key, maxi(1, roundi(goblin.get(key) * Dungeons.ELITE_DAMAGE)))
	goblin.xp_reward = roundi(goblin.xp_reward * (Dungeons.ELITE_XP + n))
	goblin.gold_min = roundi(goblin.gold_min * Dungeons.ELITE_GOLD)
	goblin.gold_max = roundi(goblin.gold_max * Dungeons.ELITE_GOLD)
	goblin.scale = Vector2.ONE * SCALE
	goblin.hurt_radius *= SCALE
	goblin.hurt_height *= SCALE
	goblin.map_color = LABEL_COLOR
	goblin.add_to_group("elites")
	# elity żywiołów (Elements, etap 3): biją swoim żywiołem i są na niego odporne
	var resist: Dictionary = goblin.resistances.duplicate()
	for t: String in traits:
		if TRAIT_ELEMENTS.has(t):
			var element: String = TRAIT_ELEMENTS[t]
			goblin.element = element
			resist[element] = maxf(float(resist.get(element, 0.0)), 0.0) + TRAIT_RESISTANCE
	goblin.resistances = resist
	if traits.has("shielded"):
		max_shield = roundi(goblin.max_health * float(Dungeons.ELITE_TRAITS["shielded"]["power"]))
		shield = max_shield


func _ready() -> void:
	var color := main_color()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(color, 0.8), Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.scale = Vector2(1.1, 0.55)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)
	_label = Label.new()
	_label.text = label_text()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", color.lerp(LABEL_COLOR, 0.5).lightened(0.25))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(160, 24)
	_label.scale = Vector2.ONE / SCALE
	_label.position = Vector2(-80.0 / SCALE, _head_y() - 22.0 / SCALE)
	_label.z_index = 30
	if dungeon != null and dungeon.has_method("label_boost"):
		_label.modulate = dungeon.label_boost()
	add_child(_label)
	for id in traits:
		_timers[id] = randf_range(0.5, 2.0)
	# własny materiał (scena potwora dzieli swój ze wszystkimi potworami tego rodzaju)
	var sprite := goblin.sprite
	if sprite != null:
		_outline = ShaderMaterial.new()
		_outline.shader = SHADER
		_outline.set_shader_parameter("outline", color.lightened(0.2))
		sprite.material = _outline


## Kolor poświaty: pierwsza cecha.
func main_color() -> Color:
	return Dungeons.ELITE_TRAITS[traits[0]]["color"] if not traits.is_empty() else LABEL_COLOR


## Napis nad głową: cechy, np. „Dowódczy · Płonący”.
func label_text() -> String:
	var names: Array[String] = []
	for id in traits:
		names.append(Lang.t(Dungeons.ELITE_TRAITS[id]["name"]))
	return (Lang.t("Czempion") + "\n" if champion else "") + " · ".join(names)


## Górna krawędź obrazka potwora (w układzie potwora).
func _head_y() -> float:
	# prostokąt klatki ma zwykle pusty zapas nad głową - przycinamy go do nieprzezroczystych pikseli
	var sprite := goblin.sprite
	if sprite == null or sprite.texture == null:
		return -32.0
	var rect := sprite.get_rect()
	var top := rect.position.y
	var image := sprite.texture.get_image() if sprite.texture is CompressedTexture2D or sprite.texture is ImageTexture else null
	if image != null and not sprite.region_enabled:
		var frame_size := Vector2i(image.get_width() / sprite.hframes, image.get_height() / sprite.vframes)
		var used := image.get_region(Rect2i(Vector2i.ZERO, frame_size)).get_used_rect()
		if used.size.y > 0:
			top += used.position.y
	return sprite.position.y + top * sprite.scale.y - 2.0


func _process(delta: float) -> void:
	if goblin == null or goblin.state == Goblin.State.DEAD:
		return
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	_glow.modulate.a = 0.7 + 0.3 * pulse
	if _outline != null:
		_outline.set_shader_parameter("outline", main_color().lerp(Color.WHITE, 0.45 * pulse))
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	var now := Time.get_ticks_msec()
	if max_shield > 0 and shield < max_shield and now >= _shield_back_at:
		shield = max_shield
		MiscVfx.spark(goblin.get_parent(), goblin.hurt_center(), Color(0.5, 0.8, 1.0), 0.8)
		queue_redraw()
	for id in traits:
		_timers[id] = float(_timers[id]) - TICK
		if float(_timers[id]) > 0.0:
			continue
		_timers[id] = _trait_tick(id, now)


## Działanie cechy; zwraca czas do następnego razu.
func _trait_tick(id: String, now: int) -> float:
	var power: float = Dungeons.ELITE_TRAITS[id]["power"]
	var player := goblin._player
	var engaged := goblin.state == Goblin.State.CHASE or goblin.state == Goblin.State.ATTACK
	var to_player := INF
	if player != null and not player.is_dead:
		to_player = goblin.global_position.distance_to(player.global_position)
	match id:
		"commander", "hastening", "warding":
			for other in Goblin.near(get_tree(), goblin.global_position, AURA_RADIUS):
				if other.global_position.distance_to(goblin.global_position) <= AURA_RADIUS:
					other.empower(id, power, now + AURA_TIME)
			return AURA_EVERY
		"healer":
			_heal(goblin, power)
			for other in Goblin.near(get_tree(), goblin.global_position, AURA_RADIUS):
				if other != goblin and other.global_position.distance_to(goblin.global_position) <= AURA_RADIUS:
					_heal(other, power * HEAL_ALLIES)
			return 1.0
		"frost":
			if engaged and to_player < FROST_RADIUS:
				SkillEffects.shockwave(goblin.get_parent(), goblin.global_position, FROST_RADIUS, Color(0.6, 0.9, 1.0, 0.8))
				Sfx.play_at("hit_ice", goblin.global_position)
				player.apply_slow(0.55, 2.0)
				player.take_damage(maxi(1, roundi(goblin.damage * power)), goblin.global_position, Elements.COLD)
				return FROST_EVERY
			return TICK
		"storm":
			if engaged and to_player < STORM_RANGE:
				_storm_strike(player.global_position, maxi(1, roundi(goblin.damage * power)))
				return STORM_EVERY
			return TICK
		"burning":
			if engaged and goblin.velocity.length() > 5.0:
				_burn_patch(goblin.global_position, maxi(1, roundi(goblin.damage * power)))
			return BURN_EVERY
		"summoner":
			_summons = _summons.filter(func(g) -> bool: return is_instance_valid(g) and g.state != Goblin.State.DEAD)
			if engaged and _summons.size() < SUMMON_MAX:
				_summon(int(power))
				return SUMMON_EVERY
			return TICK
	return 9999.0  # cechy bez działania w czasie (Kolczasty, Tarczowy, Wybuchowy, Rozszczepialny)


func _heal(target: Goblin, fraction: float) -> void:
	if target.state == Goblin.State.DEAD or target.health >= target.max_health:
		return
	target.health = mini(target.max_health, target.health + maxi(1, roundi(target.max_health * fraction)))


## Obrażenia zadane elicie (Goblin.take_damage): najpierw tarcza, Kolczasty odbija część w gracza.
## Zwraca obrażenia, które dochodzą do zdrowia.
func absorb(amount: int, _from: Vector2) -> int:
	var now := Time.get_ticks_msec()
	if max_shield > 0:
		_shield_back_at = now + SHIELD_DELAY
		if shield > 0:
			var taken := mini(shield, amount)
			shield -= taken
			amount -= taken
			queue_redraw()
			if shield == 0:
				Sfx.play_at("hit_ice", goblin.global_position)
				MiscVfx.spark(goblin.get_parent(), goblin.hurt_center(), Color(0.5, 0.8, 1.0), 1.2)
	if traits.has("thorns") and now >= _reflect_at:
		var player := goblin._player
		if player != null and not player.is_dead and player.global_position.distance_to(goblin.global_position) < REFLECT_RANGE:
			_reflect_at = now + REFLECT_EVERY
			var back := mini(roundi(amount * float(Dungeons.ELITE_TRAITS["thorns"]["power"])), roundi(goblin.damage * REFLECT_CAP))
			if back > 0:
				player.take_damage(back, goblin.global_position)
				MiscVfx.spark(goblin.get_parent(), player.body_center(), Color(0.9, 0.9, 0.5), 0.7)
	return amount


func _draw() -> void:
	if shield <= 0:
		return
	var center := Vector2(0, -goblin.hurt_height / SCALE)
	var radius := goblin.hurt_radius / SCALE + 8.0
	var fill := 0.5 + 0.5 * float(shield) / max_shield
	draw_circle(center, radius, Color(0.45, 0.75, 1.0, 0.12 * fill))
	draw_arc(center, radius, 0.0, TAU, 28, Color(0.6, 0.85, 1.0, 0.65 * fill), 1.0)


## Elita padła: wybuch, odpryski i łup (`rewarded` - gracza, a nie podróżników, więc z łupem).
func on_died(rewarded: bool) -> void:
	shield = 0
	queue_redraw()
	var at := goblin.global_position
	if traits.has("volatile"):
		_blast(at, maxi(1, roundi(goblin.damage * float(Dungeons.ELITE_TRAITS["volatile"]["power"]))))
	if traits.has("splitting"):
		_split.call_deferred(at)
	if rewarded:
		var rolls: float = 1.0 + (dungeon.tree_value("elite_loot") if dungeon != null and dungeon.has_method("tree_value") else 0.0)
		while rolls > 0.0:
			if rolls >= 1.0 or randf() < rolls:
				for id in roll_loot(goblin.level, traits.size()):
					goblin._spawn_pickup(id, 1)
			rolls -= 1.0
		if champion:
			goblin._spawn_pickup(Loot.world_legend(goblin.level), 1)
		if idol:
			var tree: Dictionary = dungeon.config.get("tree", {}) if dungeon != null else {}
			goblin._spawn_pickup(Idols.roll(null, float(tree.get("idol_rarity", 0.0)), float(tree.get("idol_ancient", 0.0))), 1)


## Dodatkowy łup elity: 1 + liczba cech przedmiotów (pierwszy co najmniej magiczny), szansa na legendę.
static func roll_loot(level: int, trait_count: int) -> Array[String]:
	var result: Array[String] = []
	var bonus := Dungeons.ELITE_QUALITY_PER_TRAIT * trait_count
	for i in 1 + trait_count:
		result.append(Loot.drop_at_level(level, bonus, Loot.MAGIC if i == 0 else ""))
	if randf() < Dungeons.ELITE_LEGEND_CHANCE + Dungeons.ELITE_LEGEND_PER_TRAIT * trait_count:
		result.append(Loot.world_legend(level))
	return result


func _floor_layer() -> Node:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	return layer if layer != null else goblin.get_parent()


## Burzowy: zapowiedź w miejscu gracza, po chwili piorun - trafia, jeśli gracz nie uciekł z kręgu.
func _storm_strike(at: Vector2, amount: int) -> void:
	_strike(_floor_layer(), goblin.get_parent(), goblin._player, at, STORM_RADIUS + 4.0, STORM_WARN, amount, "storm")


## Wybuchowy: po śmierci krąg się wypełnia, potem wybuch.
func _blast(at: Vector2, amount: int) -> void:
	_strike(_floor_layer(), goblin.get_parent(), goblin._player, at, BLAST_RADIUS, BLAST_WARN, amount, "blast")


## Zapowiedziany cios w kręgu `radius` po `warn` s. Statyczny, bo wybuch następuje już po zniknięciu elity
## (funkcja zwykła wiązałaby odliczanie z węzłem elity i przepadałoby razem z nim).
static func _strike(layer: Node, parent: Node, player: Player, at: Vector2, radius: float, warn: float, amount: int, fx: String) -> void:
	var telegraph := Telegraph.new()
	telegraph.shape = Telegraph.Shape.CIRCLE
	telegraph.radius = radius
	telegraph.duration = warn
	layer.add_child(telegraph)
	telegraph.global_position = at
	# autoload Sfx nie jest widoczny w funkcji statycznej - przez drzewo sceny
	var sfx := layer.get_node("/root/Sfx")
	sfx.play_at("telegraph", at, -6.0)
	# słabe odwołania - węzły mogą zniknąć przed wybuchem (np. wyjście z lochu)
	var refs := [weakref(telegraph), weakref(parent), weakref(player), weakref(sfx)]
	layer.get_tree().create_timer(warn).timeout.connect(func() -> void:
		var mark: Node = refs[0].get_ref()
		var where: Node = refs[1].get_ref()
		var target: Player = refs[2].get_ref()
		var sound: Node = refs[3].get_ref()
		if mark != null:
			mark.queue_free()
		if where == null:
			return
		if fx == "storm":
			MonsterFx.sky_bolt(where, at)
			if sound != null:
				sound.play_at("thunder", at, -4.0)
		else:
			BossFx.bomb(where, at, radius)
			if sound != null:
				sound.play_at("explosion", at)
		if target != null and not target.is_dead and target.global_position.distance_to(at) <= radius:
			target.take_damage(amount, at, Elements.LIGHTNING if fx == "storm" else Elements.FIRE))


func _burn_patch(at: Vector2, amount: int) -> void:
	var patch := FirePatch.new()
	patch.amount = amount
	patch.player = goblin._player
	_floor_layer().add_child(patch)
	patch.global_position = at


## Przywołujący: pomocnicy z puli potworów klimatu wyskakują obok i od razu gonią gracza.
func _summon(count: int) -> void:
	if dungeon == null:
		return
	MiscVfx.summon(goblin.get_parent(), goblin.global_position, 0.6)
	Sfx.play_at("summon", goblin.global_position, -4.0)
	for i in count:
		var at := goblin.global_position + Vector2.from_angle(randf() * TAU) * randf_range(24.0, 40.0)
		var spawn: Dictionary = dungeon._spawn(dungeon._pick(dungeon.climate["monsters"]), at, goblin.global_position, goblin.level)
		var helper: Goblin = dungeon.w._live_goblins.get(spawn["id"])
		if helper == null:
			continue
		# przywołańcy dają mniej (inaczej elita byłaby studnią łupu)
		helper.xp_reward = roundi(helper.xp_reward * 0.5)
		helper.equipment_drop_chance *= 0.25
		helper.heart_drop_chance = 0.0
		helper.gold_max = helper.gold_min
		_rally(helper)
		_summons.append(helper)


## Rozszczepialny: kilka mniejszych potworów tego samego rodzaju w miejscu śmierci.
func _split(at: Vector2) -> void:
	if dungeon == null or not is_instance_valid(dungeon) or kind == "":
		return
	var parent: Node = dungeon.w.entities
	var pieces := int(Dungeons.ELITE_TRAITS["splitting"]["power"])
	MiscVfx.puff(parent, at + Vector2(0, -6), main_color(), 1.2)
	for i in pieces:
		var spot: Vector2 = at + Vector2.from_angle(TAU * i / pieces + randf_range(-0.4, 0.4)) * 18.0
		var spawn: Dictionary = dungeon._spawn(kind, spot, at, goblin.level)
		var piece: Goblin = dungeon.w._live_goblins.get(spawn["id"])
		if piece == null:
			continue
		piece.max_health = maxi(1, roundi(goblin.max_health * SPLIT_HEALTH))
		piece.health = piece.max_health
		piece.scale = Vector2.ONE * SPLIT_SCALE
		piece.equipment_drop_chance *= 0.5
		_rally(piece)


func _rally(helper: Goblin) -> void:
	helper.home = helper.position
	helper.sitting = false
	helper.appear()
	helper.aggro()


## Płonąca plama Płonącego: parzy gracza co pół sekundy, potem gaśnie.
class FirePatch extends Node2D:
	var amount := 1
	var player: Player
	var _life := BURN_LIFE
	var _burn := 0.0

	func _ready() -> void:
		add_child(WorldVfx.burning("fire", BURN_RADIUS))

	func _process(delta: float) -> void:
		_life -= delta
		if _life < 0.5:
			modulate.a = maxf(0.0, _life / 0.5)
		if _life <= 0.0:
			queue_free()
			return
		_burn -= delta
		if _burn <= 0.0 and is_instance_valid(player) and not player.is_dead \
				and player.global_position.distance_to(global_position) < BURN_RADIUS:
			_burn = 0.5
			player.take_damage(amount, global_position, Elements.FIRE)
