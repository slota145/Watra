class_name Skeleton
extends Goblin
## Szkielet z Leśnego Cmentarza: ożywiony przez nekromantę wojownik z tarczą i wyszczerbionym mieczem.
## Nie zna strachu. Część szkieletów wypełza z grobów w trakcie walki (rise) - wtedy nie wraca do żadnego
## miejsca, tylko walczy, aż padnie.

const BONE_COLOR := Color(0.85, 0.82, 0.7)
const RISE_TIME := 0.7

## Wyszedł z grobu w trakcie walki (nie wraca na miejsce i nie odradza się).
var risen := false


func _ready() -> void:
	super()
	hurt_radius = 7.0
	heart_drop_chance = 0.0
	equipment_drop_chance = 0.05
	map_color = BONE_COLOR
	quest_kind = "skeleton"
	fearless = true


## Wypełza z ziemi: wyłania się od stóp w górę, rozsypując ziemię, i od razu rusza na gracza.
func rise() -> void:
	risen = true
	leash_radius = 100000.0
	sprite.scale = Vector2(1.2, 0.05)
	sprite.position.y = 6.0
	modulate = Color(0.6, 0.9, 0.6, 1.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2.ONE, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, RISE_TIME)
	tween.tween_property(self, "modulate", Color.WHITE, RISE_TIME)
	tween.chain().tween_callback(aggro)
	var dirt := CPUParticles2D.new()
	dirt.position = Vector2(0, -2)
	dirt.one_shot = true
	dirt.explosiveness = 0.6
	dirt.amount = 14
	dirt.lifetime = 0.7
	dirt.direction = Vector2.UP
	dirt.spread = 50.0
	dirt.initial_velocity_min = 25.0
	dirt.initial_velocity_max = 60.0
	dirt.gravity = Vector2(0, 160)
	dirt.scale_amount_max = 2.5
	dirt.color = Color(0.3, 0.24, 0.18)
	dirt.emitting = true
	add_child(dirt)
	Sfx.play_at("drowner_emerge", global_position, -6.0)


func _process_return() -> void:
	# szkielet z grobu nie ma dokąd wracać - rozpada się, gdy gracz ucieknie
	if risen:
		_die_quietly()
		return
	super()


func _die_quietly() -> void:
	state = State.DEAD
	remove_from_group("enemies")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _drop_loot() -> void:
	# szkielety z grobów dają tylko doświadczenie i drobne złoto - inaczej walka przy grobach byłaby farmą
	if risen:
		_spawn_pickup("gold", randi_range(gold_min, gold_max))
		return
	super()
	if randf() < 0.25:
		_spawn_pickup("bone_dust", 1)


func _spawn_poof() -> void:
	var bones := CPUParticles2D.new()
	bones.position = position + Vector2(0, -8)
	bones.one_shot = true
	bones.emitting = true
	bones.amount = 14
	bones.lifetime = 0.7
	bones.explosiveness = 1.0
	bones.direction = Vector2.UP
	bones.spread = 120.0
	bones.initial_velocity_min = 30.0
	bones.initial_velocity_max = 70.0
	bones.gravity = Vector2(0, 220)
	bones.scale_amount_min = 1.5
	bones.scale_amount_max = 2.5
	bones.color = BONE_COLOR
	get_parent().add_child(bones)
	bones.finished.connect(bones.queue_free)
	Sfx.play_at("rock_break", global_position, -14.0)
