class_name Pickup
extends Node2D
## Łup leżący na ziemi (złoto albo przedmiot). Wyskakuje z pokonanego wroga,
## a gdy gracz podejdzie blisko, przyciąga się do niego i zostaje zebrany.

const MAGNET_RADIUS := 36.0
const COLLECT_RADIUS := 6.0
const LIFETIME := 120.0
const GOLD_COLOR := Color(1.0, 0.85, 0.3)

var item_id := "gold"
var amount := 1

var _player: Player
var _speed := 0.0
var _age := 0.0
var _can_collect := false
## Gdy ekwipunek jest pełny, przedmiot czeka chwilę przed kolejną próbą.
var _retry_at := 0.0

@onready var sprite: Sprite2D = $Sprite



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	add_to_group("pickups")  # dymek łupu na ziemi (GroundTooltip)
	# opcja „łup niezidentyfikowany” - magiczne i rzadkie przedmioty zawinięte w płótno
	if item_id != "gold":
		item_id = Unidentified.convert(item_id)
	sprite.texture = Items.GOLD_ICON if item_id == "gold" else Items.get_data(item_id)["icon"]
	# ikony mają 64 px - na ziemi leżą w rozmiarze 16 px (moneta 10 px)
	sprite.scale = Vector2.ONE * (10.0 if item_id == "gold" else 16.0) / sprite.texture.get_width()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if item_id != "gold" and Items.is_legendary(item_id):
		_add_legendary_beam()
		Sfx.play_at("legendary_drop", global_position)
	elif item_id != "gold" and Items.rarity_of(item_id) in ["magic", "rare"]:
		_add_quality_glint(Items.rarity_of(item_id), Items.rarity_color(item_id))

	# wyskok z ciała wroga w losową stronę
	var target := position + Vector2(randf_range(-16, 16), randf_range(-8, 10))
	# tweeny w tempie fizyki - łup ma interpolację fizyki
	create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(self, "position", target, 0.4) 			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var hop := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	hop.tween_property(sprite, "position:y", -14.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	hop.tween_property(sprite, "position:y", -3.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	hop.tween_callback(func() -> void: _can_collect = true)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	if not _can_collect:
		return
	sprite.position.y = -3.0 + sin(_age * 4.0)
	# migotanie przed zniknięciem
	sprite.visible = _age < LIFETIME - 5.0 or fmod(_age, 0.3) < 0.2

	if _player == null or _player.is_dead or _age < _retry_at:
		return
	var to_player := _player.global_position + Vector2(0, -4) - global_position
	if to_player.length() < COLLECT_RADIUS:
		_collect()
	elif to_player.length() < MAGNET_RADIUS or _speed > 0.0:
		_speed = minf(_speed + 500.0 * delta, 240.0)
		global_position += to_player.normalized() * minf(_speed * delta, to_player.length())


## Migotanie w kolorze jakości wokół magicznego (niebieskie) albo rzadkiego (złote) łupu - zapętlony błysk
## z kreatora efektów PixelLab (WorldVfx.loot_glint; klatki wspólne dla wszystkich łupów, więc setki łupów mało kosztują).
func _add_quality_glint(rarity: String, color: Color) -> void:
	var glint := WorldVfx.loot_glint(rarity)
	glint.position = Vector2(0, -3)
	glint.frame = randi() % 16  # łupy obok siebie nie błyskają naraz
	add_child(glint)
	sprite.modulate = Color(1, 1, 1).lerp(color, 0.25) * 1.15


## Słup pomarańczowo-złotego światła i iskry nad legendarnym łupem (iskry z kreatora efektów PixelLab) - widać go z daleka.
func _add_legendary_beam() -> void:
	var beam := Sprite2D.new()
	var image := Image.create(13, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 13:
			var across := 1.0 - absf(x - 6.0) / 6.5
			var along := pow(float(y) / 63.0, 1.2)
			image.set_pixel(x, y, Color(1.0, 0.65 + 0.3 * across, 0.25 + 0.5 * across * across, minf(1.0, across * along * 1.3)))
	beam.texture = ImageTexture.create_from_image(image)
	beam.position = Vector2(0, -30)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beam.material = additive
	beam.show_behind_parent = true
	add_child(beam)
	var pulse := beam.create_tween().set_loops()
	pulse.tween_property(beam, "modulate:a", 0.55, 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(beam, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	var sparks := WorldVfx.loot_legendary()
	sparks.position = Vector2(0, -3)
	sparks.scale = Vector2.ONE * 1.25
	add_child(sparks)
	sprite.modulate = Color(1.3, 1.15, 0.9)


func _collect() -> void:
	var text_pos := _player.body_center() + Vector2(0, -8)
	if item_id == "gold":
		var gold := roundi(amount * _player.stats.gold_multiplier())  # premia "więcej złota" z przedmiotów
		_player.stats.add_gold(gold)
		Sfx.play("coins")
		DamageNumber.spawn_text(get_parent(), text_pos, Lang.t("+%d zł") % gold, GOLD_COLOR)
		queue_free()
		return

	var left := _player.inventory.add_item(item_id, amount)
	var taken := amount - left
	if taken > 0:
		_player.item_picked.emit(item_id, taken)
		if Items.is_legendary(item_id):
			Sfx.play("legendary_pickup")
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null:
				hud.show_banner(Lang.t("Przedmiot legendarny: %s!") % Items.display_name(item_id), Items.LEGENDARY_COLOR)
		# lepsze przedmioty dostają powiadomienie w rogu ekranu zamiast napisu nad głową
		if not LootFeed.is_notable(item_id):
			DamageNumber.spawn_text(get_parent(), text_pos, "+%d %s" % [taken, Items.display_name(item_id)], Color(0.95, 0.6, 0.65))
	if left == 0:
		queue_free()
		return
	amount = left
	_speed = 0.0
	_retry_at = _age + 2.0
	DamageNumber.spawn_text(get_parent(), text_pos, Lang.t("Ekwipunek pełny!"), Color(1, 0.4, 0.4))
