extends StaticBody2D
## Ognisko: animowane płomienie i migoczący blask.

const FPS := 8.0

var _time := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	_time = randf() * 10.0


func _process(delta: float) -> void:
	_time += delta
	sprite.frame = int(_time * FPS) % sprite.hframes
	var flicker := 1.0 + sin(_time * 9.0) * 0.04 + sin(_time * 23.0) * 0.03
	glow.scale = Vector2.ONE * flicker
