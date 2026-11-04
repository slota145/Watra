class_name DungeonChest
extends Harvestable
## Skrzynia w lochu (mechanika "chests", Dungeons.CHEST_KINDS) - jak strongbox w Path of Exile. Rodzaj mówi, co jest
## w środku: zwykła (kilka przedmiotów i złoto), kowala (broń i zbroje, kamienie błogosławione), szkatuła jubilera
## (kamienie szlachetne i biżuteria), skarbnica (dużo złota, czasem rzadki przedmiot albo legenda). Cechy
## (Dungeons.CHEST_TRAITS): strzeżona - po otwarciu wyskakują strażnicy, a skrzynia otwiera się dopiero po ich
## pokonaniu; obfita - więcej łupu; cenna - lepsze rzadkości. Otwiera się klawiszem F (chwila majstrowania przy zamku).
## Drzewko Watry: nowe rodzaje skrzyń („Skrzynie Bogów” - bożki, runy, talizmany; "special" w CHEST_KINDS) i mimik -
## skrzynia ożywa jako elitarny potwór (MIMIC_*), a po jego pokonaniu sypie potrójny łup.
## Budowana w kodzie (DungeonChest.create), bez sceny.

const TEXTURE := preload("res://assets/village/chest.png")
const OPEN_TIME := 1.0
const SCALE := 1.6
## Linie przedmiotów (ItemBases.LINES) wg rodzaju łupu.
const WEAPON_LINES: Array[String] = ["sword", "axe", "mace", "dagger", "bow", "book", "staff"]
const ARMOR_LINES: Array[String] = ["hood", "helm", "robe", "jerkin", "plate", "gloves", "gauntlets", "boots", "greaves", "belt", "girdle"]
const JEWELRY_LINES: Array[String] = ["band", "signet", "stud", "fang", "amulet", "talisman"]
## Strażnicy strzeżonej skrzyni: ilu (plus po jednym na dwa stopnie lochu) i o ile wyższy poziom.
const GUARDS := 5
const GUARD_LEVEL := 1
## Skarbnica: ile razy złoto z jednego potwora i szanse na rzadki przedmiot i legendę.
const GOLD_PILE := Vector2i(25, 40)
const GOLD_RARE_CHANCE := 0.25
const GOLD_LEGEND_CHANCE := 0.03
## Mimik: o ile wyższy poziom, ile cech elity, ile razy więcej zdrowia.
const MIMIC_LEVEL := 2
const MIMIC_TRAITS := 2
const MIMIC_HEALTH := 2.0

var dungeon: Node
var kind := "common"
var traits: Array[String] = []
## closed (czeka na gracza), guarded (strażnicy walczą), open
var state := "closed"
var _guards: Array = []
var _label: Label


static func create(owner_dungeon: Node, chest_kind: String, chest_traits: Array[String]) -> DungeonChest:
	var chest := DungeonChest.new()
	chest.dungeon = owner_dungeon
	chest.kind = chest_kind
	chest.traits = chest_traits
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 2.0)
	sprite.modulate = Dungeons.CHEST_KINDS[chest_kind]["tint"]
	chest.add_child(sprite)
	return chest


func _init() -> void:
	action_name = Lang.t("Otwórz")
	harvest_time = OPEN_TIME
	chip_color = Color(0.8, 0.65, 0.4)
	hit_sound = "door"
	break_sound = "door"
	bar_height = 40.0
	bar_color = Color(1.0, 0.85, 0.4)
	# skrzynia nie zasłania drogi - bez kolizji z postaciami
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_label = Label.new()
	_label.text = title()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(Dungeons.CHEST_KINDS[kind]["glow"], 1.0).lightened(0.45))
	_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# tuż nad napisem "[F] Otwórz" (Player._harvest_prompt), rośnie w górę
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(140, 30)
	_label.position = Vector2(-70, -bar_height - 14.0 - _label.size.y)
	_label.z_index = 30
	_label.modulate = dungeon.label_boost()
	add_child(_label)


## Nazwa z cechami, np. "Skrzynia kowala\nStrzeżona, Obfita".
func title() -> String:
	var text := Lang.t(Dungeons.CHEST_KINDS[kind]["name"])
	if not traits.is_empty():
		text += "\n" + ", ".join(traits.map(func(id: String) -> String: return Lang.t(Dungeons.CHEST_TRAITS[id]["name"])))
	return text


func can_harvest() -> bool:
	return state == "closed"


## Gracz otworzył zamek: strzeżona wypuszcza strażników, pozostałe od razu wysypują łup.
func harvest(_from: Vector2) -> void:
	if state != "closed":
		return
	set_progress(0.0)
	if traits.has("mimic"):
		_wake_mimic()
	elif traits.has("guarded"):
		_release_guards()
	else:
		open()


## Mimik: skrzynia ożywa jako elitarny potwór; otworzy się po jego pokonaniu (razem ze strażnikami strzeżonej).
func _wake_mimic() -> void:
	state = "guarded"
	var spawn: Dictionary = dungeon._spawn(dungeon._pick(dungeon.climate["monsters"]), global_position + Vector2(0, 14),
			global_position, dungeon.level + MIMIC_LEVEL)
	var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if goblin != null:
		var elite := DungeonElite.promote(goblin, Dungeons.roll_elite_traits(RandomNumberGenerator.new(), MIMIC_TRAITS), dungeon, spawn["type"])
		dungeon.elites.append(elite)
		goblin.max_health = roundi(goblin.max_health * MIMIC_HEALTH)
		goblin.health = goblin.max_health
		goblin.state = Goblin.State.CHASE
		goblin.sitting = false
		_guards.append(goblin)
	if traits.has("guarded"):
		_release_guards()
	sprite.visible = false
	_label.text = Lang.t("Mimik! Pokonaj go, a skrzynia się otworzy")
	MiscVfx.puff(get_parent(), global_position + Vector2(0, -10), Color(0.9, 0.6, 0.3), 1.0)
	Sfx.play("telegraph", -2.0)
	dungeon.w.hud.show_banner(Lang.t("To mimik! Pokonaj go, żeby zdobyć skarb"), Color(1.0, 0.55, 0.35))
	set_process(true)
	if _guards.is_empty():
		open()


func _release_guards() -> void:
	state = "guarded"
	var tier := Dungeons.config_tier(dungeon.config)
	var count := roundi((GUARDS + floori(tier / 2.0)) * Dungeons.mult(dungeon.config, "count"))
	for i in count:
		var angle := TAU * i / count + randf_range(-0.3, 0.3)
		var at := global_position + Vector2.from_angle(angle) * Vector2(90, 64)
		var spawn: Dictionary = dungeon._spawn(dungeon._pick(dungeon.climate["monsters"]), at, global_position, dungeon.level + GUARD_LEVEL)
		var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
		if goblin == null:
			continue
		goblin.home = goblin.position
		goblin.state = Goblin.State.CHASE
		goblin.sitting = false
		_guards.append(goblin)
	_label.text = Lang.t("Pokonaj strażników skrzyni!")
	Sfx.play("telegraph", -2.0)
	dungeon.w.hud.show_banner(Lang.t("Strażnicy skrzyni! Pokonaj ich, a skrzynia się otworzy"), Color(1.0, 0.7, 0.4))
	set_process(true)
	if _guards.is_empty():
		open()


func _process(_delta: float) -> void:
	if state != "guarded":
		set_process(false)
		return
	_guards = _guards.filter(func(g) -> bool: return is_instance_valid(g) and g.state != Goblin.State.DEAD)
	if _guards.is_empty():
		open()


## Otwarta: łup na ziemi, skrzynia gaśnie.
func open() -> void:
	if state == "open":
		return
	state = "open"
	sprite.visible = true
	sprite.modulate = Dungeons.CHEST_KINDS[kind]["tint"].darkened(0.45)
	_label.visible = false
	Sfx.play("pickup_rare" if kind != "common" else "coins")
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -16), Dungeons.CHEST_KINDS[kind]["glow"], 0.8)
	for entry: Array in roll_contents(kind, traits, dungeon.level, Dungeons.config_tier(dungeon.config)):
		dungeon._drop(global_position + Vector2(0, 20), entry[0], entry[1])


## Zawartość skrzyni: lista [id, ilość]. `level` - poziom potworów lochu, `tier` - stopień (runy).
static func roll_contents(chest_kind: String, chest_traits: Array, level: int, tier := 1) -> Array:
	var amount := 1.0
	for id: String in chest_traits:
		amount *= float(Dungeons.CHEST_TRAITS[id]["loot"])
	var precious := chest_traits.has("rare")
	var result := []
	match chest_kind:
		"common":
			for i in roundi(randi_range(3, 5) * amount):
				result.append([_item(ItemBases.LINES.keys(), level, precious), 1])
			result.append(["gold", roundi(Levels.gold(level) * randi_range(4, 8) * amount)])
		"smith":
			for i in roundi(randi_range(2, 4) * amount):
				result.append([_item(WEAPON_LINES if randf() < 0.5 else ARMOR_LINES, level, precious), 1])
			if randf() < 0.5:
				result.append(["blessed_stone", roundi(randi_range(1, 2) * amount)])
		"jeweler":
			for i in roundi(randi_range(1, 3) * amount):
				result.append([_item(JEWELRY_LINES, level, precious), 1])
			for i in roundi(randi_range(1, 2) * amount):
				if Gems.unlocked:
					result.append([Gems.roll("", Gems.cut_for_level(level), true), 1])
				else:
					result.append([_item(JEWELRY_LINES, level, precious), 1])
		"gold":
			result.append(["gold", roundi(Levels.gold(level) * randi_range(GOLD_PILE.x, GOLD_PILE.y) * amount)])
			if randf() < GOLD_RARE_CHANCE * (2.0 if precious else 1.0) * amount:
				result.append([Loot.drop_at_level(level, 0.0, Loot.RARE), 1])
			if randf() < GOLD_LEGEND_CHANCE * (2.0 if precious else 1.0) * amount:
				result.append([Loot.legendary_at_level(Dungeons.VAULT_LEGENDS.pick_random(), level), 1])
		"idols":
			for i in roundi(randi_range(2, 3) * amount):
				result.append([Idols.roll(null, 0.3 if precious else 0.0), 1])
		"runes":
			for i in roundi(randi_range(3, 6) * amount):
				result.append([ItemCraft.roll_rune(tier), 1])
		"talismans":
			for i in roundi(randi_range(1, 2) * amount):
				result.append([Talismans.roll(Levels.item_level(level), "rare" if precious or randf() < 0.3 else "magic"), 1])
	return result


## Przedmiot z jednej z linii na poziomie lochu; `precious` - co najmniej magiczny i częściej rzadki.
static func _item(lines: Array, level: int, precious: bool) -> String:
	var quality := Loot.roll_quality(0.12 if precious else 0.0)
	if precious and quality == Loot.COMMON:
		quality = Loot.MAGIC
	var item_level := Levels.item_level(level)
	return Loot.generate(Loot.base_for(lines.pick_random(), item_level), quality, item_level)


func _draw() -> void:
	super()
	if state == "open":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 26.0, Color(Dungeons.CHEST_KINDS[kind]["glow"], 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
