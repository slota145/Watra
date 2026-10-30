class_name LegendFx
## Pomocnicze węzły efektów legend Hydry i Gryfa (LegendaryEffects): fala półksiężyca, wieżyczka ognia,
## trąba powietrzna. Każdy rani wrogów wprost (take_damage) - obrażenia z efektów nie wywołują kolejnych efektów.


## Półksiężyc wiatru wystrzelony z cięcia miecza (Ostrze Gryfa): leci prosto i rani każdego wroga raz.
class WindCrescent extends Node2D:
	const SPEED := 260.0
	const RANGE := 230.0
	const RADIUS := 18.0
	var direction := Vector2.RIGHT
	var damage := 10
	var _travelled := 0.0
	var _hit := {}

	func _ready() -> void:
		rotation = direction.angle()
		z_index = 3

	func _process(delta: float) -> void:
		var step := direction * SPEED * delta
		global_position += step
		_travelled += step.length()
		for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
			if _hit.has(enemy):
				continue
			if enemy.hurt_center().distance_to(global_position + Vector2(0, -8)) <= RADIUS + enemy.hurt_radius:
				_hit[enemy] = true
				enemy.take_damage(damage, global_position - direction * 10.0, 90.0)
		modulate.a = 1.0 - _travelled / RANGE
		if _travelled >= RANGE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2(-6, -8), 16.0, -1.1, 1.1, 14, Color(0.85, 0.95, 1.0, 0.85), 3.0)
		draw_arc(Vector2(-9, -8), 13.0, -0.9, 0.9, 12, Color(0.6, 0.8, 1.0, 0.5), 2.0)


## Kula ognia, która nie wybucha od razu (Księga Gryfiego Płomienia): wisi w miejscu i strzela płomieniami
## w pobliskich wrogów, a na koniec wybucha.
class FireTurret extends Node2D:
	const LIFE := 3.0
	const SHOT := 0.35
	const RANGE := 150.0
	var shot_damage := 10
	var explosion: Projectile
	var _time := 0.0
	var _shot := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_time += delta
		_shot -= delta
		queue_redraw()
		if _shot <= 0.0:
			_shot = SHOT
			var target: Goblin = null
			var best := RANGE
			for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
				var d := enemy.global_position.distance_to(global_position)
				if d < best:
					best = d
					target = enemy
			if target != null:
				SkillEffects.bolt(get_parent(), global_position + Vector2(0, -10), target.hurt_center(), 0.18, 3.0)
				SkillEffects.spark(get_parent(), target.hurt_center(), Color(1.0, 0.6, 0.2), 5)
				target.take_damage(shot_damage, global_position, 30.0)
				Sfx.play_at("fireball_launch", global_position, -14.0)
		if _time >= LIFE:
			set_process(false)
			if is_instance_valid(explosion):
				explosion.global_position = global_position
				get_parent().add_child(explosion)
				explosion.set_physics_process(false)
				explosion._explode()
			queue_free()

	func _draw() -> void:
		var pulse := 1.0 + 0.15 * sin(_time * 14.0)
		draw_circle(Vector2(0, -10), 7.0 * pulse, Color(1.0, 0.45, 0.1, 0.5))
		draw_circle(Vector2(0, -10), 4.0 * pulse, Color(1.0, 0.85, 0.4))


## Trąba powietrzna spod stóp biegnącego gracza (Skrzydła Gryfa): sunie przed siebie, wciąga i rani wrogów.
class Tornado extends Node2D:
	const LIFE := 2.4
	const SPEED := 70.0
	const RADIUS := 26.0
	const TICK := 0.3
	var direction := Vector2.RIGHT
	var damage := 6
	var _time := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_time += delta
		_tick -= delta
		global_position += direction * SPEED * delta
		queue_redraw()
		if _tick <= 0.0:
			_tick = TICK
			for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
				var to_center := global_position - enemy.global_position
				if to_center.length() <= RADIUS + enemy.hurt_radius:
					enemy.take_damage(damage, global_position, 0.0)
					if not enemy is Boss and enemy.state != Goblin.State.DEAD:
						enemy._knockback = to_center.normalized() * 80.0
		if _time >= LIFE:
			queue_free()

	func _draw() -> void:
		var fade := clampf(minf(_time * 4.0, (LIFE - _time) * 3.0), 0.0, 1.0)
		for i in 5:
			var y := -4.0 - i * 6.0
			var wobble := sin(_time * 12.0 + i) * 3.0
			draw_arc(Vector2(wobble, y), 5.0 + i * 2.5, 0.0, TAU, 16, Color(0.85, 0.92, 1.0, 0.5 * fade), 1.5)
