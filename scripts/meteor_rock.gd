class_name MeteorRock
extends Harvestable
## Skała meteorytu po uderzeniu (deszcz meteorytów - EventSite): rozbija się kilofem jak głaz (F), daje rudę żelaza
## i kamień, czasem kamień szlachetny albo Serce Kryształu. Rozbita znika (nie odrasta), a rozbijający
## (gracz albo podróżnik) dostaje punkty wkładu w wydarzeniu.

const TEXTURES: Array[Texture2D] = [preload("res://assets/events/meteor_0.png"), preload("res://assets/events/meteor_1.png"),
		preload("res://assets/events/meteor_2.png")]
const LIFE := 300.0

var site: EventSite
var level := 1


static func create(at: Vector2, rock_level: int) -> MeteorRock:
	var rock := MeteorRock.new()
	rock.position = at
	rock.level = rock_level
	return rock


func _init() -> void:
	action_name = Lang.t("Rozbij meteoryt")
	tool_texture = preload("res://assets/weapons/pickaxe.png")
	chip_color = Color(0.95, 0.55, 0.25)
	hit_sound = "mine"
	break_sound = "rock_break"
	bar_height = 34.0
	var sprite_node := Sprite2D.new()
	sprite_node.name = "Sprite"
	sprite_node.scale = Vector2(0.5, 0.5)
	sprite_node.offset = Vector2(0, -24)
	add_child(sprite_node)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	textures.assign(TEXTURES)


func _ready() -> void:
	super()
	# żarzy się jeszcze po upadku
	var glow := create_tween().set_loops(4)
	glow.tween_property(sprite, "modulate", Color(1.6, 1.2, 1.0), 0.3)
	glow.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	var fade := create_tween()
	fade.tween_interval(LIFE)
	fade.tween_property(self, "modulate:a", 0.0, 1.0)
	fade.tween_callback(queue_free)


func roll_loot() -> Array:
	var loot := [["iron_ore", randi_range(3, 6)], ["stone", randi_range(2, 4)]]
	if Gems.unlocked and randf() < 0.2:
		loot.append([Gems.roll("", Gems.cut_for_level(level)), 1])
	if level >= 23 and randf() < 0.04:
		loot.append([Essences.HEART, 1])
	return loot


## Rozbita: odłamki, punkty wkładu dla rozbijającego (gracz albo najbliższy podróżnik) i znika.
func harvest(from: Vector2) -> void:
	_play_harvest(from)
	is_depleted = true
	if is_instance_valid(site):
		site.on_rock_mined(_miner(from))
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.6, 0.2), 0.2)
	tween.tween_callback(queue_free)


func _miner(from: Vector2) -> String:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player != null and player.global_position.distance_to(from) < 4.0:
		return WorldEvents.PLAYER
	var best := WorldEvents.PLAYER
	var best_d := 40.0
	for node: Traveler in get_tree().get_nodes_in_group("travelers"):
		var d := node.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = node.data.get("name", best)
	return best


func _play_harvest(_from: Vector2) -> void:
	# odłamki skały w jej kolorze i pył (efekty z kreatora efektów PixelLab - MiscVfx)
	MiscVfx.debris(get_parent(), global_position + Vector2(0, 4), chip_color, 0.9)
	MiscVfx.puff(get_parent(), global_position + Vector2(0, -6), chip_color.lerp(Color(0.8, 0.75, 0.7), 0.5), 0.6)
