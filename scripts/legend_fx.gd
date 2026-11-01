class_name LegendFx
## Pomocnicze węzły efektów legend Hydry i Gryfa (LegendaryEffects): fala półksiężyca, wieżyczka ognia,
## trąba powietrzna. Każdy rani wrogów wprost (take_damage) - obrażenia z efektów nie wywołują kolejnych efektów.
## Wygląd - zapętlone efekty z kreatora efektów PixelLab (LegendVfx).


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
		var fx := LegendVfx.wind_crescent()
		fx.position = Vector2(0, -8).rotated(-rotation)
		add_child(fx)

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
		var fx := LegendVfx.fireball()
		fx.position = Vector2(0, -10)
		add_child(fx)

	func _process(delta: float) -> void:
		_time += delta
		_shot -= delta
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
				LegendVfx.fire_shot(get_parent(), global_position + Vector2(0, -10), target.hurt_center())
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

	var _fx: Node2D

	func _ready() -> void:
		z_index = 2
		_fx = LegendVfx.tornado()
		_fx.scale = Vector2.ONE * 0.75
		add_child(_fx)

	func _process(delta: float) -> void:
		_time += delta
		_tick -= delta
		global_position += direction * SPEED * delta
		_fx.modulate.a = clampf(minf(_time * 4.0, (LIFE - _time) * 3.0), 0.0, 1.0)
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
