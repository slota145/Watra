class_name Meteor
extends Node2D
## Spadający meteoryt (deszcz meteorytów - EventSite): najpierw rośnie czerwony krąg ostrzegawczy na ziemi,
## potem z nieba spada płonąca skała. Uderzenie rani gracza w pobliżu, trzęsie ekranem i zostawia skałę
## do rozbicia (EventSite.on_meteor_landed - MeteorRock i czasem potwory z krateru).

const WARNING := 1.4
const FALL := 0.35
const RADIUS := 34.0
const FALL_TEXTURE := preload("res://assets/events/meteor_fall.png")

var site: EventSite
var level := 1
var _time := 0.0
var _rock: Sprite2D
var _landed := false


func _ready() -> void:
	z_index = 4
	_rock = Sprite2D.new()
	_rock.texture = FALL_TEXTURE
	_rock.scale = Vector2(0.55, 0.55)
	_rock.position = Vector2(-90, -260)
	_rock.visible = false
	_rock.z_index = 40
	add_child(_rock)
	var trail := CPUParticles2D.new()
	trail.amount = 30
	trail.lifetime = 0.35
	trail.gravity = Vector2.ZERO
	trail.direction = Vector2(-0.33, -1.0)
	trail.spread = 12.0
	trail.initial_velocity_min = 40.0
	trail.initial_velocity_max = 80.0
	trail.scale_amount_min = 3.0
	trail.scale_amount_max = 5.0
	trail.color = Color(1.0, 0.55, 0.2)
	_rock.add_child(trail)
	Sfx.play_at("telegraph", global_position)


func _process(delta: float) -> void:
	_time += delta
	if _time >= WARNING and not _landed:
		_rock.visible = true
		var t := clampf((_time - WARNING) / FALL, 0.0, 1.0)
		_rock.position = Vector2(-90, -260).lerp(Vector2(0, -8), t)
		if t >= 1.0:
			_land()
	queue_redraw()


func _land() -> void:
	_landed = true
	Sfx.play_at("explosion", global_position)
	SkillEffects.shockwave(get_parent(), global_position, RADIUS + 10.0, Color(1.0, 0.6, 0.3))
	SkillEffects.spark(get_parent(), global_position + Vector2(0, -6), Color(1.0, 0.7, 0.3), 18)
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null:
		var d := player.global_position.distance_to(global_position)
		if d < 260.0:
			player.add_shake(5.0 * (1.0 - d / 260.0) + 1.0)
		if d < RADIUS and not player.is_dead:
			player.take_damage(maxi(1, roundi(Levels.damage(level) * 3.0)), global_position)
	if is_instance_valid(site):
		site.on_meteor_landed(global_position)
	queue_free()


func _draw() -> void:
	if _landed:
		return
	var t := clampf(_time / WARNING, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * 18.0)
	draw_circle(Vector2.ZERO, RADIUS * t, Color(1.0, 0.25, 0.15, 0.12 + 0.1 * pulse))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1.0, 0.35, 0.2, 0.5 + 0.4 * pulse), 1.5)
