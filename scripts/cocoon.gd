class_name Cocoon
extends Goblin
## Kokon w leżu pająków. Nie rusza się i nie atakuje, ale gdy go rozbijemy, wysypują się
## z niego małe pająki (pajęczaki), które od razu atakują. Zostaje rozerwana skorupa.
## Po pewnym czasie pająki snują nowy kokon w tym samym miejscu.

@export var spiderlings := 3

const SPIDERLING := preload("res://scenes/spiderling.tscn")
const COCOON_COLOR := Color(0.85, 0.85, 0.9)


func _ready() -> void:
	super()
	fearless = true
	hurt_radius = 7.0
	map_color = COCOON_COLOR
	quest_kind = "cocoon"
	sprite.frame = 0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -22)


## Kokon nikogo nie goni ani nie alarmuje - pęka dopiero od ciosów.
func aggro() -> void:
	pass


func take_damage(amount: int, from_position: Vector2, _force := 0.0) -> void:
	super(amount, from_position, 0.0)
	_knockback = Vector2.ZERO
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.15, 0.9), 0.06)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	velocity = Vector2.ZERO
	_process_stun(delta)


func _animate(_delta: float) -> void:
	pass


func _die() -> void:
	# rozerwana skorupa zostaje na ziemi, z kokonu wybiegają pajęczaki
	var shell := Sprite2D.new()
	shell.texture = sprite.texture
	shell.hframes = 2
	shell.frame = 1
	shell.offset = sprite.offset
	shell.position = position
	get_parent().add_child(shell)
	get_tree().create_timer(40.0).timeout.connect(shell.queue_free)
	Sfx.play_at("cocoon_burst", global_position)
	for i in spiderlings:
		var spiderling: Node = SPIDERLING.instantiate()
		spiderling.position = position + Vector2.from_angle(TAU * i / spiderlings + randf()) * 10.0
		spiderling.leash_radius = 260.0
		get_parent().add_child.call_deferred(spiderling)
		spiderling.ready.connect(spiderling.aggro)
	super()
