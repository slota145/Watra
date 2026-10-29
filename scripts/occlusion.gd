class_name Occlusion
extends Node
## Znikające zasłony: wysokie rekwizyty świata (drzewa, skały, namioty, wieże, budowle z zewnątrz) robią się
## półprzezroczyste, gdy gracz wejdzie za nie (stoi wyżej niż ich podstawa i w obrysie grafiki), a przez
## zasłonę prześwituje jego sylwetka (Player.set_occluded). Rekwizyty zbiera z węzła postaci świata do siatki
## kubełków i co REFRESH_TIME odświeża (nowe budowle, ścięte drzewa); co klatkę sprawdza tylko kubełki
## wokół gracza.

## Rekwizyt jest zasłoną, gdy jego grafika jest wyższa niż postać.
const MIN_HEIGHT := 40.0
const BUCKET := 128.0
const FADED_ALPHA := 0.4
const FADE_SPEED := 4.0
const REFRESH_TIME := 3.0
## Brzegi grafiki (zwykle przezroczyste) nie zasłaniają - obrys zwężony o ten ułamek z boków.
const SIDE_MARGIN := 0.18

var _entities: Node
var _player: Player
## Vector2i kubełka -> [Sprite2D]
var _buckets := {}
var _fading: Array[Sprite2D] = []
var _refresh := 0.0


func setup(entities: Node, player: Player) -> void:
	_entities = entities
	_player = player
	_rebuild()


func _process(delta: float) -> void:
	if _player == null:
		return
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = REFRESH_TIME
		_rebuild()
	var feet := _player.global_position
	var body := feet + Vector2(0, -14)
	var occluded := false
	var hiding: Array[Sprite2D] = []
	var home := Vector2i((feet / BUCKET).floor())
	# podstawy zasłon leżą niżej niż gracz (do 3 kubełków - olbrzymie drzewa Prastarego Lasu)
	for dy in range(-1, 4):
		for dx in range(-1, 2):
			for item in _buckets.get(home + Vector2i(dx, dy), []):
				# ścięte drzewo / zburzony rekwizyt znika przed odświeżeniem siatki
				if not is_instance_valid(item):
					continue
				var sprite := item as Sprite2D
				if not sprite.is_visible_in_tree():
					continue
				# za rekwizytem: wyżej niż jego podstawa i w obrysie (zwężonym z boków) jego grafiki
				if feet.y >= sprite.global_position.y - 1.0:
					continue
				var rect := _rect_of(sprite)
				if rect.has_point(body) or rect.has_point(feet + Vector2(0, -4)):
					hiding.append(sprite)
					occluded = true
	for sprite in hiding:
		if not sprite in _fading:
			_fading.append(sprite)
	for i in range(_fading.size() - 1, -1, -1):
		var sprite := _fading[i]
		if not is_instance_valid(sprite):
			_fading.remove_at(i)
			continue
		var target := FADED_ALPHA if sprite in hiding else 1.0
		sprite.modulate.a = move_toward(sprite.modulate.a, target, delta * FADE_SPEED)
		if target == 1.0 and sprite.modulate.a >= 1.0:
			_fading.remove_at(i)
	_player.set_occluded(occluded)


## Obrys grafiki w świecie (z klatką arkusza i przesunięciem), zwężony z boków.
func _rect_of(sprite: Sprite2D) -> Rect2:
	var rect := sprite.get_rect()
	rect.position += sprite.global_position
	var margin := rect.size.x * SIDE_MARGIN
	return Rect2(rect.position.x + margin, rect.position.y, rect.size.x - margin * 2.0, rect.size.y)


func _rebuild() -> void:
	_buckets.clear()
	if _entities == null:
		return
	for node in _entities.get_children():
		var sprite := _prop_sprite(node)
		if sprite == null or sprite.get_rect().size.y < MIN_HEIGHT or sprite.has_meta("no_occlusion"):
			continue
		var key := Vector2i((sprite.global_position / BUCKET).floor())
		if not _buckets.has(key):
			_buckets[key] = []
		_buckets[key].append(sprite)


## Grafika nieruchomego rekwizytu: sam Sprite2D bez skryptu albo StaticBody2D z dzieckiem Sprite2D.
## Postaci, zwierzęta i wszystko, co się rusza, pomijamy.
func _prop_sprite(node: Node) -> Sprite2D:
	if node is Sprite2D:
		return node if node.get_script() == null else null
	if node is StaticBody2D:
		for child in node.get_children():
			if child is Sprite2D:
				return child
	return null
