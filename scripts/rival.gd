class_name Rival
extends Goblin
## Podróżnik walczący z graczem (tryby świata - WorldModes): pojedynek ("duel") albo napad zbója ("pk"). To zwykły
## potwór (Goblin - działają na niego wszystkie umiejętności gracza) z wyglądem podróżnika (arkusz NPC), jego imieniem
## i poziomem. Pojedynek kończy się, gdy ktoś spadnie do 10% zdrowia (nikt nie ginie) - sygnał `finished`
## ("won" - wygrał gracz, "lost" - przegrał). Zbój walczy na śmierć: pokonany zostawia złoto, doświadczenie i czasem
## przedmiot (Goblin._drop_loot), a gdy pokona gracza - World zabiera graczowi część złota.

signal finished(result: String)

const SCENE := preload("res://scenes/goblin.tscn")
const YIELD_AT := 0.1
const REACH := {"melee": 20.0, "bow": 95.0, "spell": 85.0}

var traveler: Dictionary = {}
var kind := "duel"
var weapon := "melee"
var _ended := false
var _label: Label


static func create(data: Dictionary, fight: String) -> Rival:
	var foe := SCENE.instantiate()
	foe.set_script(load("res://scripts/rival.gd"))
	foe.traveler = data
	foe.kind = fight
	foe.weapon = data.get("weapon", "melee")
	return foe


func _ready() -> void:
	super()
	quest_kind = "rival"
	heart_drop_chance = 0.0
	sprite.texture = load("res://assets/npc/%s.png" % traveler.get("look", "adventurer_a"))
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.offset = Vector2(0, -19)
	map_color = WorldModes.TEMPERS["bandit" if kind == "pk" else "duelist"]["color"]
	_label = Label.new()
	_label.text = "%s  [%d]" % [traveler.get("name", "?"), level]
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", map_color)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120, 10)
	_label.position = Vector2(-60, -50)
	_label.z_index = 30
	add_child(_label)
	aggro()


## Statystyki z poziomu podróżnika: wytrzymały jak mały boss, bije jak potwór jego poziomu.
func _apply_level() -> void:
	level = int(traveler.get("level", 1))
	max_health = roundi(Levels.health(level) * 6.0)
	damage = roundi(Levels.damage(level) * 1.3)
	speed = 52.0
	attack_range = REACH.get(weapon, 20.0)
	attack_windup = 0.35
	attack_cooldown = 1.0
	aggro_radius = 400.0
	alert_radius = 0.0
	leash_radius = 100000.0
	hurt_height = 12.0
	if kind == "pk":
		xp_reward = roundi(Levels.xp(level) * 6.0)
		gold_min = roundi(Levels.gold(level) * 20.0)
		gold_max = roundi(Levels.gold(level) * 40.0)
		equipment_drop_chance = 0.4
	else:
		xp_reward = 0
		gold_min = 0
		gold_max = 0
		equipment_drop_chance = 0.0


## Pojedynek: zamiast spaść poniżej 10% zdrowia - poddaje się.
func take_damage(amount: int, from_position: Vector2, knockback := 120.0) -> void:
	if _ended:
		return
	if kind == "duel" and health - amount <= max_health * YIELD_AT:
		health = maxi(1, roundi(max_health * YIELD_AT))
		end("won")
		return
	super(amount, from_position, knockback)


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_timer -= delta
	if _attack_timer > 0.0 or _ended:
		return
	_strike_anim = 0.25
	_cooldown = attack_cooldown
	state = State.CHASE
	if not _player_alive() or global_position.distance_to(_player.global_position) > attack_range + 8.0:
		return
	match weapon:
		"bow":
			BowSkills.arrow_hit(get_parent(), _player.body_center(), (_player.body_center() - global_position).angle())
			Sfx.play_at("bow", global_position)
		"spell":
			SkillEffects.sheet_once(get_parent(), Traveler.SPELL_HIT_FX, 6, 18.0, _player.body_center(), Vector2(20, 20), 0.0, 1.0, 0.7)
			Sfx.play_at("magic", global_position)
		_:
			var aim := (_player.body_center() - global_position).normalized()
			SkillEffects.sheet_once(get_parent(), Traveler.SLASH_FX, 5, 24.0, global_position + Vector2(0, -9), Vector2(32, 32), aim.angle(), 1.0, 0.7)
			SkillEffects.sheet_once(get_parent(), Traveler.HIT_FX, 5, 16.0, _player.body_center(), Vector2(14, 14), randf() * TAU, 1.0, 0.8)
			Sfx.play_at("swing", global_position)
	# pojedynek: gracz nie ginie - przegrywa przy 10% zdrowia
	if kind == "duel" and _player.health - damage <= _player.stats.max_health() * YIELD_AT:
		end("lost")
		return
	_player.take_damage(damage, global_position)


## Koniec walki bez śmierci (pojedynek albo odejście zbója po wygranej): sygnał i zniknięcie.
func end(result: String) -> void:
	if _ended:
		return
	_ended = true
	state = State.DEAD
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	finished.emit(result)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


## Okrzyk nad głową; gotowe hasła (bez wstawionych danych) tłumaczy sam.
func say(text: String) -> void:
	DamageNumber.spawn_text(get_parent(), global_position + Vector2(0, -44), tr(text), map_color, 8)


func _animate(delta: float) -> void:
	var to := _player.global_position - global_position if _player != null else Vector2.DOWN
	if state == State.ATTACK or _strike_anim > 0.0:
		sprite.frame = 12 + (2 if _strike_anim > 0.0 else 0) + int(_anim_time) % 2
		sprite.flip_h = to.x < 0.0
		_anim_time += delta * 6.0
		return
	var dir := velocity if velocity.length() > 4.0 else to
	var row := 2 if absf(dir.x) >= absf(dir.y) else (0 if dir.y > 0.0 else 1)
	sprite.flip_h = row == 2 and dir.x < 0.0
	if velocity.length() > 8.0:
		_anim_time += delta * 8.0
		sprite.frame = row * 4 + int(_anim_time) % 4
	else:
		sprite.frame = row * 4
