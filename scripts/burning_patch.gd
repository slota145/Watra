class_name BurningPatch
extends Node2D
## Płonąca plama po bombie zapalającej (albo trujący opar - style "poison"): co TICK rani gracza
## (albo wrogów - z legendy gracza), który w niej stoi, i po LIFE sekundach gaśnie.

const TICK := 0.5
const LIFE := 4.0

var radius := 24.0
var damage := 4
var life := LIFE
var style := "fire"
var hurts_enemies := false

var _time := 0.0
var _tick := 0.0
var _flames: AnimatedSprite2D


func _ready() -> void:
	# zapętlone płomienie (albo zielony opar) z kreatora efektów PixelLab
	_flames = WorldVfx.burning(style, radius)
	_flames.position.y = radius * 0.3  # płomienie wyrastają w górę - podstawa pierścienia niżej, w środku plamy
	_flames.z_index = 2
	add_child(_flames)


func _process(delta: float) -> void:
	_time += delta
	_tick -= delta
	queue_redraw()
	if _time >= life:
		set_process(false)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.6)
		tween.tween_callback(queue_free)
		return
	if _tick > 0.0:
		return
	_tick = TICK
	if hurts_enemies:
		for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) <= radius:
				enemy.take_damage(damage, global_position, 0.0)
		return
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null and not player.is_dead and player.global_position.distance_to(global_position) <= radius:
		player.take_damage(damage, global_position)


func _draw() -> void:
	var fade := clampf((life - _time) / 0.8, 0.0, 1.0)
	var color := Color(0.25, 0.08, 0.02, 0.45) if style == "fire" else Color(0.2, 0.45, 0.1, 0.35)
	draw_circle(Vector2.ZERO, radius, Color(color, color.a * fade))
