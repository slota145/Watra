class_name TownPortal
extends Node2D
## Portal do miasta (jak w Path of Exile): niebieski płomień Watry. W lochu stoi tam, gdzie gracz go otworzył
## (klawisz B) i prowadzi do Ostoi bez kończenia wyprawy; w Ostoi stoi obok Watry i prowadzi z powrotem do tego
## samego lochu (World.open_town_portal, World.return_through_portal). Wejście - po prostu wejdź w płomień.

const TEXTURE := preload("res://assets/village/watra.png")
const FRAMES := 6
const FPS := 7.0
const COLOR := Color(0.55, 0.75, 1.6)
## Mniejszy niż płomienie Watry, żeby nie mylił się z nimi.
const SCALE := 0.55
## Pole, w które trzeba wejść (względem stóp płomienia).
const RECT := Rect2(Vector2(-16, -12), Vector2(32, 20))

## Co robi wejście: "town" - z lochu do Ostoi, "dungeon" - z Ostoi do lochu.
var kind := "town"
## Otwierany portal (gracz trzyma B) nie działa i rośnie - 0..1.
var opening := 1.0
var _sprite: Sprite2D
var _glow: Sprite2D
var _label: Label
var _time := 0.0


func _ready() -> void:
	# poświata pod płomieniem (jak przy płomieniach wyjścia z lochu, ale niebieska)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.35, 0.55, 1.0, 0.6), Color(0.35, 0.55, 1.0, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 120
	texture.height = 84
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.position = Vector2(0, -10)
	_glow.show_behind_parent = true
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = FRAMES
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 10.0)
	_sprite.modulate = COLOR
	add_child(_sprite)
	_label = Label.new()
	_label.text = Lang.t("Portal do Ostoi") if kind == "town" else Lang.t("Portal do lochu")
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.15))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120, 10)
	_label.position = Vector2(-60, -TEXTURE.get_height() * SCALE - 6.0)
	_label.z_index = 30
	add_child(_label)
	_update_look()


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * FPS) % FRAMES
	_update_look()
	if opening < 1.0:
		return
	var world := get_tree().get_first_node_in_group("world")
	if world == null or world._traveling or world.player.is_dead:
		return
	if Rect2(global_position + RECT.position, RECT.size).has_point(world.player.global_position):
		Sfx.play("magic", 2.0, 1.2)
		if kind == "town":
			world.open_town_portal(global_position)
		else:
			world.return_through_portal()


func _update_look() -> void:
	var grow := lerpf(0.2, 1.0, clampf(opening, 0.0, 1.0)) * SCALE
	_sprite.scale = Vector2(grow, grow)
	_sprite.modulate.a = lerpf(0.4, 1.0, opening)
	if _glow != null:
		_glow.modulate.a = opening
	_label.visible = opening >= 1.0
