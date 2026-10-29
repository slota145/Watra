class_name Harvestable
extends StaticBody2D
## Coś, co gracz zbiera klawiszem E: drzewo (siekiera, drewno) albo głaz (kilof, kamień).
## Zebrane zostawia ślad (pieniek, gruz), z którego po kilku minutach odrasta -
## albo od razu po odpoczynku w karczmie. Podklasy ustawiają nazwę czynności,
## narzędzie i łup oraz animację zbierania.

@export var textures: Array[Texture2D] = []
## Wygląd po zebraniu (pieniek, gruz).
@export var depleted_texture: Texture2D
@export var depleted_offset := Vector2.ZERO
@export var regrow_min := 120.0
@export var regrow_max := 180.0
## Jak wysoko nad podstawą rysować pasek postępu.
@export var bar_height := 48.0
@export var bar_color := Color(0.85, 0.65, 0.35)

## Napis nad obiektem ("[E] ...") i narzędzie, którym gracz pracuje.
var action_name := ""
var tool_texture: Texture2D
## Kolor drzazg / odłamków przy uderzeniu.
var chip_color := Color.WHITE
## Dźwięki uderzenia narzędziem i zebrania (nazwy z Sfx.SOUNDS).
var hit_sound := ""
var break_sound := ""

var is_depleted := false
## Ile sekund zostało do odrośnięcia.
var regrow_left := 0.0
## Postęp zbierania 0..1 (pasek nad obiektem).
var progress := 0.0

var _full_texture: Texture2D
var _full_offset := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("harvestables")
	if not textures.is_empty():
		sprite.texture = textures.pick_random()
	_full_texture = sprite.texture
	_full_offset = sprite.offset
	set_process(false)


func can_harvest() -> bool:
	return not is_depleted


func set_progress(value: float) -> void:
	progress = value
	queue_redraw()


## Drgnięcie po uderzeniu narzędziem.
func shake() -> void:
	var tween := create_tween()
	for x in [2.0, -2.0, 1.0, 0.0]:
		tween.tween_property(sprite, "position:x", x, 0.04)


## Zebrane: animacja (podklasa) i ślad, który kiedyś odrośnie.
func harvest(from: Vector2) -> void:
	_play_harvest(from)
	deplete(randf_range(regrow_min, regrow_max))


## Co dostaje gracz: lista par [id przedmiotu, ilość].
func roll_loot() -> Array:
	return []


## Zamienia obiekt w ślad po zebraniu (także przy wczytywaniu gry, bez animacji).
func deplete(regrow_time: float) -> void:
	is_depleted = true
	regrow_left = regrow_time
	set_progress(0.0)
	sprite.texture = depleted_texture
	sprite.offset = depleted_offset
	set_process(true)


## Odrasta (wołane też przez odpoczynek w karczmie).
func regrow() -> void:
	if not is_depleted:
		return
	is_depleted = false
	set_process(false)
	sprite.texture = _full_texture
	sprite.offset = _full_offset
	sprite.scale = Vector2.ONE * 0.3
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _play_harvest(_from: Vector2) -> void:
	pass


func _process(delta: float) -> void:
	regrow_left -= delta
	if regrow_left <= 0.0:
		regrow()


func _draw() -> void:
	if progress <= 0.0:
		return
	var bar := Rect2(-12, -bar_height, 24, 3)
	draw_rect(bar.grow(1), Color(0.1, 0.11, 0.17))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), bar_color)
