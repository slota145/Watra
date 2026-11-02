class_name DungeonShrine
extends Harvestable
## Kapliczka w lochu (mechanika "shrine", Dungeons.SHRINES): omszały kamień z runą bóstwa. Krótka modlitwa
## (klawisz F) daje krótki, bardzo mocny dar (Boons, grupa "shrine", 60 s) - np. Moc Peruna (+50% obrażeń)
## albo Hojność Dadźboga (dwa razy więcej łupu). Każda kapliczka działa raz; dar z nowej zastępuje poprzedni.
## Budowana w kodzie (DungeonShrine.create), bez sceny.

const TEXTURE := preload("res://assets/ancient/v2_shrine.png")
const PRAY_TIME := 0.8
const SCALE := 1.5
## Kolor runy i poświaty wg daru.
const COLORS := {"shrine_might": Color(1.0, 0.45, 0.3), "shrine_ward": Color(0.45, 1.0, 0.5), "shrine_haste": Color(0.75, 1.0, 1.0),
		"shrine_fortune": Color(1.0, 0.85, 0.3), "shrine_wisdom": Color(0.8, 0.55, 1.0), "shrine_moon": Color(0.45, 0.65, 1.0)}

var dungeon: Node
var gift := "shrine_might"
var used := false
## Poświata z lochu (Dungeon._glow) - gaśnie po modlitwie.
var glow: Sprite2D
var _label: Label


static func create(owner_dungeon: Node, gift_id: String) -> DungeonShrine:
	var shrine := DungeonShrine.new()
	shrine.dungeon = owner_dungeon
	shrine.gift = gift_id
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TEXTURE
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 2.0)
	sprite.modulate = Color(1.0, 1.0, 1.0).lerp(COLORS[gift_id], 0.35)
	shrine.add_child(sprite)
	return shrine


func _init() -> void:
	action_name = Lang.t("Pomódl się")
	harvest_time = PRAY_TIME
	chip_color = Color(0.7, 0.9, 1.0)
	hit_sound = ""
	break_sound = "magic"
	bar_height = 54.0
	bar_color = Color(0.6, 0.85, 1.0)
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	_label = Label.new()
	_label.text = "%s\n%s" % [Lang.t("Kapliczka"), Lang.t(Boons.DEFS[gift]["name"])]
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", COLORS[gift].lightened(0.45))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(140, 30)
	_label.position = Vector2(-70, -bar_height - 14.0 - _label.size.y)
	_label.z_index = 30
	_label.modulate = dungeon.label_boost()
	add_child(_label)


func can_harvest() -> bool:
	return not used


## Modlitwa wysłuchana: dar na krótki czas, kapliczka gaśnie.
func harvest(_from: Vector2) -> void:
	if used:
		return
	used = true
	set_progress(0.0)
	var player: Player = dungeon.w.player
	player.boons.grant(gift)
	sprite.modulate = Color(0.55, 0.55, 0.6)
	_label.visible = false
	if glow != null:
		glow.visible = false
	queue_redraw()
	MiscVfx.spark(get_parent(), global_position + Vector2(0, -30), COLORS[gift], 1.0)
	var data: Dictionary = Boons.DEFS[gift]
	dungeon.w.hud.show_banner("%s\n%s" % [Lang.t(data["name"]), Lang.t(data["description"])], COLORS[gift])


func _draw() -> void:
	super()
	if used:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 28.0, Color(COLORS[gift], 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
