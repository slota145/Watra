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
	# grudy ziemi i pył spod stóp, dopóki szkielet się wygrzebuje
	var dirt := MonsterFx.dust()
	dirt.position = Vector2(0, 2)
	add_child(dirt)
	get_tree().create_timer(RISE_TIME).timeout.connect(dirt.queue_free)
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
	MonsterFx.bones(get_parent(), global_position + Vector2(0, -4))
	Sfx.play_at("rock_break", global_position, -14.0)
