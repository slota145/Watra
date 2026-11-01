class_name WorldVfx
## Efekty świata i interfejsu z kreatora efektów PixelLab (tools/vfx_art.py, wpisy w pixellab_src/vfx/ids.json):
## płonąca ziemia i trujący opar, rozbity głaz, fajerwerki na Święcie, błyski łupu na ziemi i w powiadomieniach,
## zaklinanie u kowala. Odtwarzają je SkillEffects.sheet_once (jednorazowe) i SkillEffects.looping (zapętlone).

const BURNING_FIRE := preload("res://assets/effects/burning_fire.png")
const BURNING_POISON := preload("res://assets/effects/burning_poison.png")
## Pierścień płomieni ma w rysunku promień około 33 px - skala dopasowuje go do promienia plamy.
const BURNING_RADIUS := 33.0
const BOULDER_BREAK := preload("res://assets/effects/boulder_break.png")
const FIREWORKS := [
	[preload("res://assets/effects/firework_peony.png"), 16, 14.0, Vector2(41, 29)],
	[preload("res://assets/effects/firework_rocket.png"), 16, 12.0, Vector2(35, 42)],
]
const LOOT_GLINT_MAGIC := preload("res://assets/effects/loot_glint_magic.png")
const LOOT_GLINT_RARE := preload("res://assets/effects/loot_glint_rare.png")
const LOOT_LEGENDARY := preload("res://assets/effects/loot_legendary.png")
const ENCHANT_SUCCESS := preload("res://assets/effects/enchant_success.png")
const ENCHANT_FAIL := preload("res://assets/effects/enchant_fail.png")
const ENCHANT_CHARGE := preload("res://assets/effects/enchant_charge.png")


## Zapętlone płomienie płonącej plamy (style "fire") albo zielony opar (style "poison") o promieniu `radius`.
static func burning(style: String, radius: float) -> AnimatedSprite2D:
	var fx := SkillEffects.looping(BURNING_POISON if style == "poison" else BURNING_FIRE, 8, 12.0, Vector2(35, 28))
	fx.scale = Vector2.ONE * radius / BURNING_RADIUS
	fx.frame = randi() % 8  # sąsiednie plamy nie migoczą równo
	return fx


## Odłamki i pył rozbitego głazu (`at` - środek głazu).
static func boulder_break(parent: Node, at: Vector2) -> void:
	SkillEffects.sheet_once(parent, BOULDER_BREAK, 12, 12.0, at, Vector2(58, 23), 0.0, 1.0, 0.8)


## Fajerwerk w losowym kolorze: rozkwitający kwiat iskier albo rakieta z deszczem iskier (`at` - miejsce wybuchu).
## Rysunki są białe, więc kolor nadaje węzeł-uchwyt (modulate), a mieszanie addytywne rozjaśnia je nocą.
static func firework(parent: Node, at: Vector2) -> void:
	var kind: Array = FIREWORKS.pick_random()
	var holder := Node2D.new()
	holder.modulate = Color.from_hsv(randf(), 0.55, 1.0)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	holder.material = additive
	parent.add_child(holder)
	SkillEffects.sheet_once(holder, kind[0], kind[1], kind[2], at, kind[3], 0.0, 1.0, randf_range(0.8, 1.15))
	holder.get_child(0).use_parent_material = true
	holder.get_tree().create_timer(kind[1] / kind[2] + 0.2).timeout.connect(holder.queue_free)


## Zapętlony błysk nad łupem: niebieski dla magicznego, złoty dla rzadkiego przedmiotu.
static func loot_glint(rarity: String) -> AnimatedSprite2D:
	if rarity == "magic":
		return SkillEffects.looping(LOOT_GLINT_MAGIC, 16, 12.0, Vector2(12, 20))
	return SkillEffects.looping(LOOT_GLINT_RARE, 16, 12.0, Vector2(13, 22))


## Złoto-pomarańczowe iskry unoszące się nad legendarnym łupem (w słupie światła).
static func loot_legendary() -> AnimatedSprite2D:
	return SkillEffects.looping(LOOT_LEGENDARY, 16, 12.0, Vector2(21, 52))


## Złote runy krążące wokół zaklinanego przedmiotu (w trakcie zaklinania).
static func enchant_charge() -> AnimatedSprite2D:
	return SkillEffects.looping(ENCHANT_CHARGE, 24, 12.0, Vector2(30, 22))


## Złoty rozbłysk z gwiazdkami po udanym zaklęciu albo czerwone pęknięcie z iskrami i dymem po porażce.
static func enchant_result(parent: Node, at: Vector2, success: bool) -> void:
	if success:
		SkillEffects.sheet_once(parent, ENCHANT_SUCCESS, 12, 16.0, at, Vector2(35, 30))
	else:
		SkillEffects.sheet_once(parent, ENCHANT_FAIL, 12, 16.0, at, Vector2(42, 26))
