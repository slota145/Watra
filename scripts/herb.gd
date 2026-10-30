class_name Herb
extends Harvestable
## Dzikie zioło (Herbs.KINDS) zrywane gołymi rękami klawiszem F - szybciej niż ścinanie drzewa. Daje ziele, z którego
## zielarka w Ostoi warzy mikstury wzmacniające; po zerwaniu znika i po kilku minutach odrasta (albo od razu po
## odpoczynku w karczmie). Nie blokuje przejścia. Budowane w kodzie (Herb.create), bez sceny.

const HARVEST_TIME := 0.8
## Na jaką wysokość (w pikselach świata) zmniejszać 64-pikselową grafikę rośliny.
const PLANT_HEIGHT := 26.0

var kind := ""
var _base_scale := Vector2.ONE
## Delikatne iskierki nad rośliną - żeby dało się ją wypatrzyć wśród trawy i kwiatów.
var _sparkles: CPUParticles2D


static func create(herb_kind: String, pos: Vector2) -> Herb:
	var herb := Herb.new()
	herb.kind = herb_kind
	herb.position = pos
	var data: Dictionary = Herbs.KINDS[herb_kind]
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var texture: Texture2D = data["plant"]
	sprite.texture = texture
	sprite.scale = Vector2.ONE * (PLANT_HEIGHT / texture.get_height())
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 6.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	herb.add_child(sprite)
	return herb


func _init() -> void:
	action_name = "Zerwij"
	harvest_time = HARVEST_TIME
	chip_color = Color(0.45, 0.8, 0.35)
	hit_sound = "step_grass"
	break_sound = "pickup"
	regrow_min = 300.0
	regrow_max = 420.0
	bar_height = 26.0
	bar_color = Color(0.5, 0.9, 0.4)
	# zioło nie zasłania drogi - bez kolizji z postaciami
	collision_layer = 0
	collision_mask = 0


func _ready() -> void:
	super()
	# rośliny lekko różnią się wielkością i kierunkiem
	sprite.flip_h = randf() < 0.5
	sprite.scale *= randf_range(0.9, 1.1)
	_base_scale = sprite.scale
	_sparkles = CPUParticles2D.new()
	_sparkles.position = Vector2(0, -12)
	_sparkles.amount = 4
	_sparkles.lifetime = 1.4
	_sparkles.preprocess = 1.4
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkles.emission_rect_extents = Vector2(8, 5)
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 20.0
	_sparkles.gravity = Vector2(0, -6)
	_sparkles.initial_velocity_min = 2.0
	_sparkles.initial_velocity_max = 6.0
	_sparkles.scale_amount_min = 1.5
	_sparkles.scale_amount_max = 2.5
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1.0, 1.0, 0.8, 0.0), Color(1.0, 1.0, 0.75, 0.95), Color(1.0, 1.0, 0.8, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	_sparkles.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sparkles.material = additive
	add_child(_sparkles)


func deplete(regrow_time: float) -> void:
	super(regrow_time)
	if _sparkles != null:
		_sparkles.emitting = false


## Odrasta jak inne zbierane obiekty, ale do własnej skali (grafika 64 px jest zmniejszona).
func regrow() -> void:
	if not is_depleted:
		return
	is_depleted = false
	set_process(false)
	sprite.texture = _full_texture
	sprite.offset = _full_offset
	sprite.scale = _base_scale * 0.3
	if _sparkles != null:
		_sparkles.emitting = true
	create_tween().tween_property(sprite, "scale", _base_scale, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func roll_loot() -> Array:
	var data: Dictionary = Herbs.KINDS[kind]
	return [[data["item"], randi_range(data["amount"][0], data["amount"][1])]]


func _play_harvest(_from: Vector2) -> void:
	var leaves := CPUParticles2D.new()
	leaves.position = Vector2(0, -6)
	leaves.one_shot = true
	leaves.explosiveness = 1.0
	leaves.amount = 10
	leaves.lifetime = 0.6
	leaves.spread = 180.0
	leaves.direction = Vector2.UP
	leaves.initial_velocity_min = 20.0
	leaves.initial_velocity_max = 50.0
	leaves.gravity = Vector2(0, 120)
	leaves.scale_amount_max = 2.0
	leaves.color = chip_color
	leaves.emitting = true
	add_child(leaves)
	leaves.finished.connect(leaves.queue_free)
