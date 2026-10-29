class_name AncientTree
extends Goblin
## Prastare drzewo z twarzą w korze. Uśpione wygląda jak zwykły, wiekowy dąb - ale gdy
## ktoś je zaatakuje, otwiera świecące ślepia i wypuszcza z korzeni falę drzewców. Gdy cała
## fala padnie, a drzewo wciąż stoi, budzi kolejną - najwyżej `max_waves` razy, potem już
## tylko się broni. Rozbite zostawia poszarpany pień i dużo prastarej kory, a potem odrasta
## w tym samym miejscu jak zwykłe potwory.

@export var wave_min := 8
@export var wave_max := 11
@export var max_waves := 5
## Odstęp między kolejnymi drzewcami jednej fali (wyłażą z ziemi po kolei, nie naraz).
@export var spawn_stagger := 0.18

const TREANT := preload("res://scenes/treant.tscn")
const STUMP := preload("res://assets/ancient/ancient_stump.png")
const TREE_COLOR := Color(0.55, 0.85, 0.4)

var awake := false
var waves_done := 0
var _spawn_timer := 0.0
var _to_spawn := 0
var _treants: Array[Node] = []


func _ready() -> void:
	super()
	fearless = true
	hurt_radius = 22.0
	map_color = TREE_COLOR
	quest_kind = "ancient_tree"
	sprite.frame = 0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -40)


func aggro() -> void:
	if state == State.DEAD:
		return
	if not awake:
		awake = true
		sprite.frame = 1
		_spawn_timer = 1.0
		Sfx.play_at("tree_rumble", global_position)
		_shake()


func take_damage(amount: int, from_position: Vector2, _force := 0.0) -> void:
	super(amount, from_position, 0.0)
	_knockback = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	velocity = Vector2.ZERO
	_process_stun(delta)
	if not awake:
		return
	# drzewo zasypia, gdy gracz odejdzie daleko
	if not _player_alive() or global_position.distance_to(_player.global_position) > 420.0:
		awake = false
		sprite.frame = 0
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0 or is_stunned():
		return
	if _to_spawn > 0:
		_to_spawn -= 1
		_spawn_timer = spawn_stagger
		_spawn_treant(_to_spawn)
		return
	_treants.assign(_treants.filter(func(t) -> bool: return is_instance_valid(t) and t.state != State.DEAD))
	# cała fala pokonana - drzewo budzi następną (o ile jeszcze ma siły)
	if _treants.is_empty() and waves_done < max_waves:
		waves_done += 1
		_to_spawn = randi_range(wave_min, wave_max)
		_spawn_timer = 1.2 if waves_done > 1 else 0.0
		Sfx.play_at("tree_rumble", global_position)
		_shake()


func _spawn_treant(index: int) -> void:
	var treant: Node = TREANT.instantiate()
	# fala wyrasta wieńcem wokół drzewa
	var angle := TAU * index / float(wave_max) + randf_range(-0.2, 0.2)
	treant.position = global_position + Vector2.from_angle(angle) * Vector2(randf_range(48, 72), randf_range(30, 44))
	treant.xp_reward = 30
	treant.equipment_drop_chance = 0.0
	treant.bark_drop_chance = 0.25
	treant.leash_radius = 320.0
	get_parent().add_child(treant)
	treant.modulate.a = 0.0
	treant.create_tween().tween_property(treant, "modulate:a", 1.0, 0.5)
	treant.aggro()
	_treants.append(treant)
	SkillEffects.spark(get_parent(), treant.global_position, Color(0.5, 0.35, 0.2), 14)
	Sfx.play_at("roots_burst", treant.global_position)


func _shake() -> void:
	var tween := sprite.create_tween()
	for i in 4:
		tween.tween_property(sprite, "position:x", 2.0 * (1 if i % 2 else -1), 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.05)


func _animate(_delta: float) -> void:
	pass


## Rozbite drzewo: zostaje poszarpany pień (bez kolizji), drzewce wokół zostają.
func _die() -> void:
	var stump := Sprite2D.new()
	stump.texture = STUMP
	stump.offset = Vector2(0, -STUMP.get_height() / 2.0 + 2.0 + PropSinks.of(STUMP))
	stump.position = position
	get_parent().add_child(stump)
	get_tree().create_timer(60.0).timeout.connect(stump.queue_free)
	Sfx.play_at("tree_fall", global_position)
	super()


func _drop_loot() -> void:
	super()
	_spawn_pickup("ancient_bark", randi_range(3, 5))
