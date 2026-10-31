class_name Player
extends CharacterBody2D
## Postać gracza: ruch w 8 kierunkach z przyspieszeniem i hamowaniem,
## zryw (dash), atak założoną bronią w stronę kursora (cięcie po półksiężycu,
## strzała z łuku albo magiczny pocisk z księgi), zdrowie i mana zależne
## od statystyk i ekwipunku, umiejętności z paska szybkiego wyboru (Hotbar: LPM, PPM, Q, E, R, Z, X - zwykły atak,
## młynek / salwa / kula ognia, uderzenia; przedmioty pod 1-0), pasywne regeneracje, ścinanie drzew (F przy drzewie)
## oraz odradzanie się po śmierci.

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal died
signal respawned
## Gracz zagadał do kupca - interfejs otwiera okno handlu.
signal shop_requested(merchant: Npc)
## Podniesiono przedmiot z ziemi (bez złota) - dla powiadomień o łupie.
signal item_picked(id: String, amount: int)
## Gracz zagadał do NPC, który ma dla niego zadanie - interfejs otwiera rozmowę.
signal dialog_requested(npc: Npc)

@export var max_speed := 95.0
@export var acceleration := 1000.0
@export var friction := 1200.0

@export_group("Dash")
@export var dash_speed := 280.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.5

@export_group("Atak")
## Zasięg i szerokość cięcia gołymi pięściami (bronie mają własne wartości).
@export var attack_reach := 20.0
@export var attack_arc_degrees := 120.0
## Bazowy czas zamachu i przerwy między cięciami (skracane przez zręczność).
@export var attack_duration := 0.18
@export var attack_cooldown := 0.3
@export var attack_knockback := 150.0
## Spowolnienie ruchu podczas machania mieczem.
@export var attack_move_factor := 0.55

@export_group("Zdrowie i mana")
## Bazowa regeneracja many (0 - manę odnawiają tylko umiejętności i mikstury).
@export var mana_regen := 0.0
@export var invulnerability_time := 0.5
@export var respawn_delay := 2.0
@export var respawn_invulnerability := 1.5

const WALK_FPS := 9.0
const GHOST_INTERVAL := 0.03
const HURT_COLOR := Color(1.0, 0.25, 0.25)
const DODGE_COLOR := Color(0.75, 0.9, 1.0)
const LEVEL_UP_COLOR := Color(1.0, 0.85, 0.3)
const PROJECTILE := preload("res://scenes/projectile.tscn")
## Jak długo widać broń dystansową w ręku po strzale.
const RANGED_POSE_TIME := 0.2
const FIREBALL_TEXTURE := preload("res://assets/projectiles/fireball.png")
## Prędkość obrotu w młynku (rad/s) i spowolnienie ruchu podczas niego.
const WHIRL_SPIN_SPEED := 16.0
const WHIRL_MOVE_FACTOR := 0.7
## Zbieranie (drzewa, głazy): zasięg (od stóp do podstawy), czas i odstęp między uderzeniami.
const HARVEST_RANGE := 26.0
const HARVEST_TIME := 2.0
const HARVEST_HIT_INTERVAL := 0.5

## Postać z PixelLab (HeroRig): 5 kierunków w arkuszu - pozostałe 3 to ich odbicia.
## Oktanty kąta patrzenia (0 = wschód, zgodnie z ruchem wskazówek) -> [kierunek w arkuszu, odbicie].
const OCTANT_DIRS := [[2, false], [1, false], [0, false], [1, true], [2, true], [3, true], [4, false], [3, false]]
## Środek tułowia względem stóp - stąd lecą pociski i liczy się zasięg ciosów.
const BODY_OFFSET := Vector2(0, -13)
## Skala grafik broni w dłoni (bronie mają swój pierwotny rozmiar).
const WEAPON_SCALE := {"melee": 1.0, "bow": 1.0, "spell": 1.0}
const ATTACK_ANIMS := {"melee": "slash", "bow": "shoot", "spell": "cast"}
## O ile przesunąć grafikę broni w dłoni względem pozycji przy ataku (rękojeść w pięści).
const HELD_GRIP_SHIFT := {"melee": 4.0, "bow": 7.0, "spell": 8.0}

## Efekty legendarnych pierścieni przy trafieniu.
var legendary: LegendaryEffects
## Co ile sprawdzać warunki zadań głównych (QuestLog.update_main).
var _main_quest_check := 0.0
## Kierunek patrzenia (jeden z 8, wektor jednostkowy) i który wybrana postać z PixelLab.
var facing_dir := Vector2.DOWN
var hero := "wojciech"
var _dir_row := 0
var health := 0
var mana := 0.0
var is_dead := false
## Miejsce, w którym gracz odradza się po śmierci.
var spawn_point := Vector2.ZERO

var _anim_time := 0.0
var _dash_timer := 0.0
## Spowolnienie (np. śpiew topielicy): mnożnik prędkości i ile jeszcze trwa.
var _slow_factor := 1.0
var _slow_time := 0.0
var _heal_buffer := 0.0
## Trucizna (ukąszenia pająków): obrażenia na sekundę, ile jeszcze trwa i co ile tyka.
var _poison_dps := 0.0
var _poison_time := 0.0
var _poison_tick := 0.0
const POISON_COLOR := Color(0.55, 1.0, 0.35)
## Skąd zaczął się unik (ślad piorunów Lotki Burzy).
var _dash_from := Vector2.ZERO
var _dash_cooldown_timer := 0.0
var _dash_dir := Vector2.ZERO
var _ghost_timer := 0.0

## Przycisk ataku wciśnięty poza oknami interfejsu.
var _attack_held := false
var _attack_timer := 0.0
var _attack_length := 0.0
var _attack_cooldown_timer := 0.0
var _attack_angle := 0.0
var _swing_sign := 1.0
## Mnożnik obrażeń bieżącego cięcia (półksiężyc tnie mocniej niż zwykły atak).
var _attack_multiplier := 1.0
## Uderzenia (slot z uderzeniem) i dodatkowe ciosy (atak zaraz po uderzeniu).
var _strike_request := false
var _combo_request := false
var _strike_cooldown := 0.0
var _strike_cooldown_total := 0.0
var _combo_window := 0.0
## Szarża: ile jeszcze trwa, kierunek, prędkość, mnożnik obrażeń i kogo już trafiła.
var _lunge_time := 0.0
var _lunge_dir := Vector2.RIGHT
var _lunge_speed := 0.0
var _lunge_damage := 1.0
var _lunge_hit := {}
## Łańcuch błyskawic: zasięg pierwszego celu od postaci i przeskoku między wrogami.
const CHAIN_FIRST_RANGE := 220.0
const CHAIN_JUMP_RANGE := 130.0
## Rodzaj bieżącego ataku: melee / bow / spell.
var _attack_kind := "melee"
var _attack_reach := 30.0
var _attack_arc := PI
## Wrogowie trafieni w bieżącym cięciu - każdy obrywa tylko raz na zamach.
var _hit_this_swing: Dictionary[Node, bool] = {}

## Prawy przycisk (umiejętność) wciśnięty poza oknami interfejsu.
var _skill_held := false
var _skill_cooldown_timer := 0.0
var _skill_cooldown_total := 0.0
## Wciśnięte sloty pasków (wspólna numeracja jak Hotbar.SLOT_ACTIONS) i trzymane umiejętności drzewka (id -> true).
var _held_slots: Array[bool] = []
var _held_ids := {}
## Ostatnio użyta umiejętność i ile jeszcze trwa okno combo po niej (Skills.COMBOS).
var _chain_skill := ""
var _chain_time := 0.0
## Umiejętności drzewek: miecza (Mgnienie, Dymne Wybuchy...), łuku (Grot Swaroga, Balista...) i księgi (Zamieć...).
var sword_skills: SwordSkills
var bow_skills: BowSkills
var spell_skills: SpellSkills
## Ofiara Krwi: ułamek zdrowia do zapłacenia za umiejętności (koszty są ułamkowe, zdrowie - całkowite).
var _blood_cost := 0.0
var _whirling := false
## Ładowanie kuli ognia: postęp 0..1 (-1 = nie ładujemy), kula w dłoniach i jej dźwięki.
var _fireball_charge := -1.0
var _fireball_full := false
var _fireball_pop := 1.0
var _fireball_time := 0.0
var _fireball_orb: Sprite2D
var _fireball_embers: CPUParticles2D
var _charge_sound: AudioStreamPlayer
var _hold_sound: AudioStreamPlayer
var _whirl_tick := 0.0
var _health_regen_progress := 0.0
## Żeby podpowiedź "za mało many" nie wyskakiwała co klatkę.
var _hint_cooldown := 0.0

## Odliczanie do kolejnego kroku (dźwięk kroków).
var _step_timer := 0.0
## Czy postać brodzi w płytkiej wodzie (wolniej i z pluskiem) - sprawdzane co chwilę.
var _in_water := false
var _water_check := 0.0
const WATER_SLOWDOWN := 0.7

## Zbierany obiekt (null = nie zbieramy), najbliższy w zasięgu i podpowiedź nad nim.
var _harvest_target: Harvestable
var _harvest_time := 0.0
var _harvest_hit := 0.0
var _nearest_harvestable: Harvestable
var _harvest_scan := 0.0
var _harvest_prompt: Label

var _invulnerable_timer := 0.0
## Oszołomienie (fletnia Króla Satyrów): sterowanie odwrócone, dopóki trwa.
var _confused_time := 0.0
## Prędkość wynikająca ze sterowania (bez odrzutu).
var _move_velocity := Vector2.ZERO
var _knockback := Vector2.ZERO
var _shake := 0.0
var _last_max_health := 0
var _last_max_mana := 0

@onready var stats: CharacterStats = $Stats
@onready var inventory: Inventory = $Inventory
@onready var equipment: Equipment = $Equipment
@onready var skills: SkillBook = $SkillBook
@onready var quests: QuestLog = $QuestLog
@onready var storage: Inventory = $Storage
## Premie z osady (posiłki, błogosławieństwa, łaźnia, bestiariusz).
var boons := Boons.new()
## Paski szybkiego wyboru: przedmioty pod 1-0 i umiejętności (osobny układ dla każdej broni).
var hotbar := Hotbar.new()
## Encyklopedia: odkryte przedmioty i pokonane potwory.
var codex := Codex.new()
## Inni podróżnicy (spis i ich życie) i rynek w gildii - zapisywane z postacią.
var travelers := Travelers.new()
var market := Market.new()
## Losowe wydarzenia w świecie (najazdy, czempioni, meteoryty, polowania) - zapisywane z postacią.
var events := WorldEvents.new()
## Darmowe gniazda u jubilera (pierwsze - nagroda za zadanie "Pierwszy klejnot").
var free_sockets := 0

## Plecak bez toreb i miejsca na torby (sakwy, plecaki) pod ekwipunkiem.
const BASE_INVENTORY := 20
const BAG_SLOTS := 5
signal bags_changed
var bags: Array[String] = ["", "", "", "", ""]
@onready var sprite: Sprite2D = $Sprite
@onready var camera: Camera2D = $Camera2D
@onready var pivot: Node2D = $Pivot
@onready var sword: Sprite2D = $Pivot/Sword
@onready var slash: Sprite2D = $Pivot/Slash



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	add_to_group("player")
	_held_slots.resize(Hotbar.slot_count())
	_held_slots.fill(false)
	Items.worn = equipment
	legendary = LegendaryEffects.new(self)
	add_child(legendary)
	sword_skills = SwordSkills.new(self)
	sword_skills.name = "SwordSkills"
	add_child(sword_skills)
	bow_skills = BowSkills.new(self)
	bow_skills.name = "BowSkills"
	add_child(bow_skills)
	spell_skills = SpellSkills.new(self)
	spell_skills.name = "SpellSkills"
	add_child(spell_skills)
	stats.skill_book = skills
	equipment.skill_book = skills
	skills.character_level = stats.level
	boons.name = "Boons"
	add_child(boons)
	codex.name = "Codex"
	add_child(codex)
	travelers.name = "Travelers"
	add_child(travelers)
	market.name = "Market"
	market.setup(self)
	add_child(market)
	travelers.market = market
	events.name = "WorldEvents"
	events.setup(self)
	add_child(events)
	Gems.unlocked = false
	quests.quest_done.connect(_on_quest_done)
	quests.quest_ready.connect(_on_quest_ready)
	stats.boons = boons
	spawn_point = position
	set_hero(Game.hero)
	stats.equipment = equipment
	equipment.changed.connect(_update_weapon_sprite)
	_update_weapon_sprite()
	health = stats.max_health()
	mana = stats.max_mana()
	_last_max_health = stats.max_health()
	_last_max_mana = stats.max_mana()
	stats.changed.connect(_on_stats_changed)
	stats.leveled_up.connect(_on_leveled_up)
	sword.visible = false
	slash.visible = false
	_harvest_prompt = _make_harvest_prompt()
	add_child(_harvest_prompt)
	_make_fireball_orb()
	item_picked.connect(_on_item_picked)
	inventory.changed.connect(_update_gather_quests)
	for source: Signal in [inventory.changed, storage.changed, equipment.changed]:
		source.connect(func() -> void: codex.note_owned(self))
	storage.changed.connect(_update_gather_quests)
	quests.changed.connect(_update_gather_quests)
	_emit_resources.call_deferred()


## Kliknięcie w okno ekwipunku / postaci jest przechwytywane przez interfejs
## i tutaj nie dociera, więc nie powoduje ataku.
func _unhandled_input(event: InputEvent) -> void:
	for i in Hotbar.SLOT_ACTIONS.size():
		if event.is_action_pressed(Hotbar.SLOT_ACTIONS[i]):
			_press_slot(i)
			return
	if is_dead:
		return
	if event.is_action_pressed("interact"):
		_interact()
		return


func _input(event: InputEvent) -> void:
	for i in Hotbar.SLOT_ACTIONS.size():
		if event.is_action_released(Hotbar.SLOT_ACTIONS[i]):
			_held_slots[i] = false
			_update_held_slots()


## Wciśnięty slot paska (wspólna numeracja): przedmiot (np. mikstura), atak (albo dodatkowy cios zaraz po uderzeniu),
## umiejętność aktywna (trzymana - młynek, ładowanie kuli ognia) albo uderzenie (jedno na wciśnięcie).
## Umiejętność innej broni (z paska 1-0) czeka, aż ją założysz.
func _press_slot(index: int) -> void:
	_held_slots[index] = true
	var id := hotbar.entry(stats.weapon_type(), index)
	if Hotbar.is_item(id):
		if not is_dead:
			use_item(id)
		return
	if id != "" and id != Hotbar.ATTACK and Skills.get_data(id)["weapon"] != stats.weapon_type():
		_hint("%s działa z bronią: %s" % [Skills.get_data(id)["name"], Skills.WEAPON_NAMES[Skills.get_data(id)["weapon"]].to_lower()])
		return
	if id == Hotbar.ATTACK:
		if combo_ready():
			_combo_request = true
		else:
			_attack_held = true
	elif id != "":
		match Skills.get_data(id)["type"]:
			"active":
				_skill_held = true
			"strike":
				_strike_request = true
			"skill":
				_held_ids[id] = true
				match Skills.get_data(id)["weapon"]:
					"bow":
						bow_skills.press(id)
					"spell":
						spell_skills.press(id)
					_:
						sword_skills.press(id)


## Atak i umiejętność aktywna trwają, dopóki trzymany jest któryś slot z nimi.
func _update_held_slots() -> void:
	var weapon_type := stats.weapon_type()
	_attack_held = false
	_skill_held = false
	_held_ids.clear()
	for i in _held_slots.size():
		var id := hotbar.entry(weapon_type, i)
		if not _held_slots[i] or id == "" or Hotbar.is_item(id):
			continue
		if id == Hotbar.ATTACK:
			_attack_held = true
		elif Skills.get_data(id)["weapon"] != weapon_type:
			continue
		elif Skills.get_data(id)["type"] == "active":
			_skill_held = true
		elif Skills.get_data(id)["type"] == "skill":
			_held_ids[id] = true


## Przedmiot ze slotu 1-0 (np. mikstura); umiejętność z tego slotu - jak wciśnięcie klawisza.
func use_hotbar_item(index: int) -> bool:
	var id := hotbar.items[index]
	return use_item(id) if Hotbar.is_item(id) else false


## Ile zostało do końca odnowienia umiejętności i ile trwa całe (Vector2(pozostało, całość); zero - gotowa).
func cooldown_of(id: String) -> Vector2:
	match Skills.get_data(id).get("type", ""):
		"active":
			return Vector2(_skill_cooldown_timer, maxf(_skill_cooldown_total, _skill_cooldown_timer))
		"strike":
			return Vector2(_strike_cooldown, maxf(_strike_cooldown_total, _strike_cooldown))
		"skill":
			match Skills.get_data(id)["weapon"]:
				"bow":
					return bow_skills.cooldown_of(id)
				"spell":
					return spell_skills.cooldown_of(id)
			return sword_skills.cooldown_of(id)
	return Vector2.ZERO


## Czy umiejętność drzewka jest trzymana (jej slot wciśnięty).
func is_skill_held(id: String) -> bool:
	return _held_ids.has(id)


# ---------------------------------------------------------------- combo
## Okno combo (s): bazowe i dłuższe z węzłów drzewka.
func combo_window() -> float:
	return Skills.COMBO_WINDOW + skills.tree_bonus(stats.weapon_type(), "combo_window")


## Zapamiętuje użytą umiejętność - przez okno combo kolejne mogą zadziałać inaczej (Skills.COMBOS).
func note_skill(id: String) -> void:
	_chain_skill = id
	_chain_time = combo_window()
	spell_skills.on_cast(id)


## Czy umiejętność użyta teraz zadziała jako combo (po pasującej umiejętności w oknie combo).
func combo_with(id: String) -> bool:
	if _chain_time <= 0.0 or _chain_skill == "" or not Skills.COMBOS.has(id):
		return false
	var after: Array = Skills.COMBOS[id]
	return (_chain_skill != id and "any" in after) or _chain_skill in after


## Mnożnik obrażeń ciosów combo (węzły drzewka).
func combo_damage() -> float:
	return 1.0 + skills.tree_bonus(stats.weapon_type(), "combo_damage")


## Wykonane combo (np. Półksiężyc po Szarży) - Taniec Ostrzy dokłada wtedy szybkości ataku.
func combo_used() -> void:
	sword_skills.on_combo()


## Ile okna combo jeszcze zostało (0..1) - do kurczącego się pierścienia na pasku.
func combo_fraction() -> float:
	return clampf(_chain_time / combo_window(), 0.0, 1.0)


## Zasięg Młynka (poziom umiejętności i premia z drzewka) i mnożnik zużycia many (węzeł kluczowy Nieustający Wir).
func whirl_radius() -> float:
	return Skills.whirlwind_radius(skills.level_of("whirlwind")) * (1.0 + skills.tree_bonus("melee", "whirl_radius")) * stats.area_multiplier()


func whirl_mana_factor() -> float:
	return 2.0 if skills.has_keystone("melee", "endless_whirl") else 1.0


## Rzeczy na start nowej postaci (mikstury leżą od razu na pasku pod 1 i 2).
## Identyfikacja przedmiotów niezidentyfikowanych (Unidentified) ze stosu w plecaku: jeden albo cały stos - tyle,
## ile zmieści się w plecaku (każdy przedmiot zajmuje kratkę; ostatnia sztuka stosu zwalnia swoją). Zwraca liczbę.
func identify(index: int, whole := false) -> int:
	var slot: Dictionary = inventory.slots[index]
	if slot.is_empty() or not Unidentified.is_unidentified(slot["id"]):
		return 0
	var id: String = slot["id"]
	var wanted: int = slot["count"] if whole else 1
	var done := 0
	for i in wanted:
		var current: Dictionary = inventory.slots[index]
		if current.is_empty() or current["id"] != id:
			break
		if current["count"] > 1 and not inventory.slots.any(func(s: Dictionary) -> bool: return s.is_empty()):
			DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -10), "Plecak pełny", Color(1, 0.5, 0.5), 8)
			break
		inventory.take_one(index)
		var item := Unidentified.identify(id)
		inventory.add_item(item, 1)
		item_picked.emit(item, 1)
		done += 1
	if done > 0:
		Sfx.play("pickup_rare")
	return done


## Wszystkie niezidentyfikowane stosy w plecaku.
func identify_all() -> int:
	var total := 0
	for i in inventory.slots.size():
		if not inventory.slots[i].is_empty() and Unidentified.is_unidentified(inventory.slots[i]["id"]):
			total += identify(i, true)
	return total


func give_starting_items() -> void:
	for id in Hotbar.DEFAULT_ITEMS:
		inventory.add_item(id, Hotbar.STARTING_POTIONS)


func _physics_process(delta: float) -> void:
	_main_quest_check -= delta
	if _main_quest_check <= 0.0:
		_main_quest_check = 0.5
		quests.update_main(self)
	_update_shake(delta)
	_update_poison(delta)
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_factor = 1.0
			sprite.self_modulate = Color.WHITE
	if is_dead:
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# fletnia Króla Satyrów: oszołomiony gracz biegnie w przeciwną stronę
	if _confused_time > 0.0:
		_confused_time -= delta
		input = -input
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_attack_cooldown_timer = maxf(_attack_cooldown_timer - delta, 0.0)
	_skill_cooldown_timer = maxf(_skill_cooldown_timer - delta, 0.0)
	_strike_cooldown = maxf(_strike_cooldown - delta, 0.0)
	_combo_window = maxf(_combo_window - delta, 0.0)
	_chain_time = maxf(_chain_time - delta, 0.0)
	_hint_cooldown = maxf(_hint_cooldown - delta, 0.0)
	_update_invulnerability(delta)
	_regenerate_mana(delta)
	_regenerate_health(delta)

	if Input.is_action_just_pressed("dash") and can_dash():
		_start_dash(input)
	_process_strikes()
	if _attack_held and can_attack():
		_start_attack()
	_process_skill(delta)

	if _lunge_time > 0.0:
		_update_lunge(delta)
	elif is_dashing():
		_dash_timer -= delta
		_move_velocity = _dash_dir * dash_speed
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_spawn_ghost()
			_ghost_timer = GHOST_INTERVAL
		if _dash_timer <= 0.0:
			_move_velocity = _dash_dir * max_speed
			legendary.on_dash(_dash_from, global_position)
	else:
		var slowdown := WHIRL_MOVE_FACTOR if _whirling or is_charging_fireball() \
				else attack_move_factor if is_attacking() and not bow_skills.running_fire() else 1.0
		var target_speed := max_speed * stats.move_speed() * slowdown * (WATER_SLOWDOWN if _in_water else 1.0) * _slow_factor
		if input != Vector2.ZERO:
			_move_velocity = _move_velocity.move_toward(input * target_speed, acceleration * delta)
		else:
			_move_velocity = _move_velocity.move_toward(Vector2.ZERO, friction * delta)

	# odrzut dokładamy osobno, żeby nie kumulował się w prędkości ruchu
	velocity = _move_velocity + _knockback
	move_and_slide()
	_move_velocity = velocity - _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)

	_update_footsteps(delta, input)
	_update_harvest(delta, input)
	_scan_harvestables(delta)
	if _whirling:
		_update_whirl(delta)
	elif _harvest_target != null or is_charging_fireball() or _lunge_time > 0.0:
		pass
	elif is_attacking():
		_update_attack(delta)
	elif not is_dashing():
		_update_facing(input)
	_update_animation(delta)


func is_dashing() -> bool:
	return _dash_timer > 0.0


func can_dash() -> bool:
	return not is_dashing() and _dash_cooldown_timer == 0.0


func is_attacking() -> bool:
	return _attack_timer > 0.0


func can_attack() -> bool:
	return not is_attacking() and not is_dashing() and not _whirling and _harvest_target == null and not is_charging_fireball() and _lunge_time <= 0.0 and _attack_cooldown_timer == 0.0


func is_whirling() -> bool:
	return _whirling


## Czy umiejętność pod PPM jest gotowa (bez czasu odnowienia).
func skill_ready() -> bool:
	return _skill_cooldown_timer == 0.0


## Pełnia Mocy podraża umiejętności, a z Ofiarą Krwi płaci się zdrowiem (nigdy do zera).
func spend_mana(amount: float) -> bool:
	amount *= spell_skills.mana_cost_factor()
	if spell_skills.blood_magic():
		if health - (_blood_cost + amount) < 1.0:
			return false
		_blood_cost += amount
		var whole := floori(_blood_cost)
		if whole > 0:
			_blood_cost -= whole
			health -= whole
			health_changed.emit(health, stats.max_health())
		return true
	if mana < amount:
		return false
	mana -= amount
	mana_changed.emit(int(mana), stats.max_mana())
	return true


## Środek "ciała" postaci (tułów, nie stopy) - stąd liczymy zasięg ciosów.
func body_center() -> Vector2:
	return global_position + BODY_OFFSET


## Ustawia granice kamery (w pikselach świata).
func set_camera_limits(rect: Rect2i) -> void:
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y
	camera.reset_smoothing()


func take_damage(amount: int, from_position: Vector2) -> void:
	# podczas zrywu i tuż po trafieniu gracz jest nietykalny
	if is_dead or is_dashing() or _lunge_time > 0.0 or _invulnerable_timer > 0.0:
		return
	# unik z przedmiotów: cios chybia, a chwilowa nietykalność jak po trafieniu chroni przed resztą zamachu
	if randf() < stats.dodge_chance():
		DamageNumber.spawn_text(get_parent(), body_center(), "Unik", DODGE_COLOR, 9)
		_invulnerable_timer = invulnerability_time
		return
	# Riposta: zasłona przyjmuje cios i odpowiada kontrą
	if sword_skills.try_parry(from_position):
		return
	amount = stats.reduce_damage(amount)
	# Tarcza Many: część ciosu (albo cały) zabiera mana
	amount = spell_skills.absorb(amount)
	if amount <= 0:
		DamageNumber.spawn_text(get_parent(), body_center(), "Tarcza", Color(0.6, 0.8, 1.0), 9)
		_invulnerable_timer = invulnerability_time
		return
	# Pancerz z Łusek Czerwia może pochłonąć cios zakopaniem się w ziemi
	if legendary.on_hurt(amount):
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, stats.max_health())
	DamageNumber.spawn(get_parent(), body_center(), amount, HURT_COLOR)
	_knockback = (global_position - from_position).normalized() * 120.0
	_invulnerable_timer = invulnerability_time
	_shake = 3.0
	_flash(HURT_COLOR)
	Sfx.play("hurt")
	if health == 0:
		_die()


# ---------------------------------------------------------------- przedmioty i interakcja
## Używa przedmiotu z ekwipunku (np. mikstury). Zwraca true, jeśli został zużyty.
func use_item(id: String) -> bool:
	var effect: Dictionary = Items.get_data(id).get("use", {})
	if effect.is_empty() or is_dead:
		return false
	var text_pos := body_center() + Vector2(0, -10)
	if inventory.count_of(id) == 0:
		DamageNumber.spawn_text(get_parent(), text_pos, "Brak: %s" % Items.get_data(id)["name"], Color(1, 0.5, 0.5), 8)
		return false
	if effect.has("health") and health >= stats.max_health():
		DamageNumber.spawn_text(get_parent(), text_pos, "Pełne zdrowie", Color(0.8, 0.8, 0.85), 8)
		return false
	if effect.has("mana") and mana >= stats.max_mana():
		DamageNumber.spawn_text(get_parent(), text_pos, "Pełna mana", Color(0.8, 0.8, 0.85), 8)
		return false

	if effect.has("summon"):
		var world := get_tree().get_first_node_in_group("world")
		var refusal: String = world.summon_boss(effect["summon"]) if world != null else "Tu nie da się nikogo przyzwać"
		if refusal != "":
			Sfx.play("ui_error")
			DamageNumber.spawn_text(get_parent(), text_pos, refusal, Color(1, 0.5, 0.5), 8)
			return false
		inventory.remove_item(id, 1)
		return true

	if effect.has("guards"):
		_summon_guards(int(effect["guards"]))
		inventory.remove_item(id, 1)
		return true

	# mikstura zielarki: czasowa premia (zastępuje poprzednią miksturę)
	if effect.has("boon"):
		inventory.remove_item(id, 1)
		boons.grant(effect["boon"])
		Sfx.play("potion")
		DamageNumber.spawn_text(get_parent(), text_pos, Boons.DEFS[effect["boon"]]["name"], Color(0.55, 0.95, 0.5), 8)
		_flash(Color(0.5, 1.0, 0.5))
		return true

	# Pas Mokoszy: mikstura może nie ubyć; Pas Bogatyra: gniew po wypiciu
	var saved := legendary.on_potion() if (effect.has("health") or effect.has("mana")) else false
	if not saved:
		inventory.remove_item(id, 1)
	else:
		DamageNumber.spawn_text(get_parent(), text_pos + Vector2(0, -10), "Mikstura ocalała", Color(0.6, 1.0, 0.6), 8)
	Sfx.play("potion")
	# mikstury leczą stałą wartość i procent maksimum - nie słabną z poziomem postaci; pasy wzmacniają (siła mikstur)
	var potion := stats.potion_multiplier()
	if effect.has("health"):
		var amount := roundi((int(effect["health"]) + float(effect.get("health_percent", 0.0)) * stats.max_health()) * potion)
		var healed := mini(amount, stats.max_health() - health)
		health += healed
		DamageNumber.spawn_text(get_parent(), text_pos, "+%d HP" % healed, Color(0.5, 1, 0.5))
		_flash(Color(0.4, 1, 0.4))
	if effect.has("mana"):
		var amount := (float(effect["mana"]) + float(effect.get("mana_percent", 0.0)) * stats.max_mana()) * potion
		var restored := minf(amount, stats.max_mana() - mana)
		mana += restored
		DamageNumber.spawn_text(get_parent(), text_pos, "+%d many" % roundi(restored), Color(0.5, 0.7, 1))
		_flash(Color(0.4, 0.6, 1))
	_emit_resources()
	return true


## Zakłada przedmiot z danego slotu ekwipunku; poprzedni wraca do plecaka.
## `slot` - konkretne miejsce na postaci (przeciąganie); puste = pierwsze wolne pasujące.
func equip_from_inventory(index: int, slot := "") -> void:
	var data: Dictionary = inventory.slots[index]
	if data.is_empty() or not Items.is_equippable(data["id"]) or (slot != "" and not equipment.fits(slot, data["id"])):
		return
	_cancel_attack()
	var taken := inventory.take_one(index)
	var previous := equipment.equip_to(slot, taken["id"], taken["enchant"]) if slot != "" 			else equipment.equip(taken["id"], taken["enchant"])
	if not previous.is_empty():
		# zdjęty przedmiot wraca na zwolnione miejsce w plecaku
		if not inventory.put(index, previous["id"], previous["enchant"]):
			inventory.add_item(previous["id"], 1, previous["enchant"])


## Zakłada sakwę / plecak z ekwipunku w pierwsze wolne miejsce na torby.
func equip_bag(index: int) -> void:
	var id: String = inventory.slots[index].get("id", "")
	if not Items.is_bag(id):
		return
	var free := bags.find("")
	if free < 0:
		DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -10), "Wszystkie miejsca na torby zajęte!", Color(1, 0.4, 0.4), 8)
		return
	inventory.take_one(index)
	bags[free] = id
	inventory.resize(inventory_capacity())
	Sfx.play("pickup")
	bags_changed.emit()


## Zdejmuje torbę - tylko jeśli miejsca, które zniknął, są puste i torba zmieści się w plecaku.
func unequip_bag(bag_index: int) -> void:
	var id := bags[bag_index]
	if id == "":
		return
	var new_size: int = inventory_capacity() - int(Items.get_data(id)["bag"])
	var has_room := false
	for i in new_size:
		if inventory.slots[i].is_empty():
			has_room = true
			break
	if not inventory.is_empty_from(new_size) or not has_room:
		DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -10), "Najpierw zrób miejsce w plecaku!", Color(1, 0.4, 0.4), 8)
		Sfx.play("ui_error")
		return
	bags[bag_index] = ""
	inventory.resize(new_size)
	inventory.add_item(id, 1)
	bags_changed.emit()


func inventory_capacity() -> int:
	var total := BASE_INVENTORY
	for id in bags:
		if id != "":
			total += int(Items.get_data(id).get("bag", 0))
	return total


## Zdejmuje przedmiot z postaci do plecaka.
## `index` - kratka plecaka, do której trafi zdjęty przedmiot (przeciąganie); zajęta albo -1 = pierwsza wolna.
func unequip(slot: String, index := -1) -> void:
	var id := equipment.get_item(slot)
	if id == "":
		return
	var free := index >= 0 and index < inventory.slots.size() and inventory.slots[index].is_empty()
	if not free and not inventory.can_add(id, 1):
		DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -10), "Ekwipunek pełny!", Color(1, 0.4, 0.4), 8)
		return
	_cancel_attack()
	var removed := equipment.unequip(slot)
	if not (free and inventory.put(index, removed["id"], removed["enchant"])):
		inventory.add_item(removed["id"], 1, removed["enchant"])


## Przerywa zamach (np. przy zmianie broni).
func _cancel_attack() -> void:
	_attack_timer = 0.0
	sword.visible = false
	slash.visible = false


## Rozmowa / handel z najbliższą postacią w zasięgu.
func _interact() -> void:
	var nearest: Npc = null
	var best := Npc.INTERACT_DISTANCE
	for npc: Npc in get_tree().get_nodes_in_group("interactables"):
		var d := npc.global_position.distance_to(global_position)
		if d < best:
			best = d
			nearest = npc
	if nearest != null:
		nearest.interact(self)
	elif _harvest_target == null:
		# świeże wyszukanie - gracz mógł podejść przed kolejnym skanem
		_harvest_scan = 0.0
		_scan_harvestables(0.0)
		if _nearest_harvestable != null:
			_start_harvest(_nearest_harvestable)


## Ile sztuk przedmiotu gracz ma łącznie w plecaku i w magazynie.
func count_owned(id: String) -> int:
	return inventory.count_of(id) + storage.count_of(id)


## Zabiera przedmioty - najpierw z plecaka, resztę z magazynu (np. surowce oddane sołtysowi).
func take_owned(id: String, amount: int) -> void:
	var from_bag := mini(amount, inventory.count_of(id))
	if from_bag > 0:
		inventory.remove_item(id, from_bag)
	if amount > from_bag:
		storage.remove_item(id, amount - from_bag)


func _update_gather_quests() -> void:
	quests.update_gathered(count_owned)


## Odpoczynek w karczmie: pełne zdrowie i mana.
func rest() -> void:
	if is_dead:
		return
	health = stats.max_health()
	mana = stats.max_mana()
	_emit_resources()


# ---------------------------------------------------------------- zbieranie (drzewa, głazy)
func is_chopping() -> bool:
	return _harvest_target != null


func _start_harvest(target: Harvestable) -> void:
	_cancel_attack()
	_harvest_target = target
	_harvest_time = 0.0
	_harvest_hit = 0.0
	_face_direction(target.global_position - global_position)
	# niezależnie od broni pracujemy narzędziem (siekiera / kilof)
	sword.texture = target.tool_texture
	sword.offset = Vector2(12, 0)
	sword.flip_v = false


func _update_harvest(delta: float, input: Vector2) -> void:
	if _harvest_target == null:
		return
	if input != Vector2.ZERO or is_dashing() or not _harvest_target.can_harvest():
		_stop_harvest()
		return
	_harvest_time += delta
	var duration := _harvest_target.harvest_time if _harvest_target.harvest_time > 0.0 else HARVEST_TIME
	_harvest_target.set_progress(_harvest_time / duration)
	_harvest_hit -= delta
	if _harvest_hit <= 0.0:
		_harvest_hit = HARVEST_HIT_INTERVAL
		_swing_tool()
	if _harvest_time >= duration:
		var target := _harvest_target
		_stop_harvest()
		target.harvest(global_position)
		Sfx.play(target.break_sound)
		for entry: Array in target.roll_loot():
			_gain_item(entry[0], entry[1])


func _stop_harvest() -> void:
	if is_instance_valid(_harvest_target):
		_harvest_target.set_progress(0.0)
	_harvest_target = null
	sword.visible = false
	_update_weapon_sprite()


## Zamach narzędziem w stronę celu, drgnięcie i drzazgi / odłamki.
func _swing_tool() -> void:
	var to_target := _harvest_target.global_position + Vector2(0, -6) - body_center()
	pivot.rotation = to_target.angle()
	sword.visible = true
	sword.rotation = -1.1
	var tween := create_tween()
	tween.tween_property(sword, "rotation", 0.5, 0.14).set_ease(Tween.EASE_IN)
	tween.tween_callback(_harvest_target.shake)
	Sfx.play(_harvest_target.hit_sound)
	var chips := CPUParticles2D.new()
	chips.position = _harvest_target.global_position + Vector2(0, -8)
	chips.one_shot = true
	chips.explosiveness = 1.0
	chips.amount = 6
	chips.lifetime = 0.4
	chips.spread = 120.0
	chips.direction = Vector2.UP
	chips.initial_velocity_min = 30.0
	chips.initial_velocity_max = 60.0
	chips.gravity = Vector2(0, 200)
	chips.scale_amount_max = 2.0
	chips.color = _harvest_target.chip_color
	chips.emitting = true
	get_parent().add_child(chips)
	chips.finished.connect(chips.queue_free)


## Zebrany przedmiot trafia do plecaka, a nadmiar zostaje na ziemi.
func _gain_item(id: String, amount: int) -> void:
	var left := inventory.add_item(id, amount)
	if amount - left > 0:
		item_picked.emit(id, amount - left)
	if left > 0:
		var pickup: Pickup = load("res://scenes/pickup.tscn").instantiate()
		pickup.item_id = id
		pickup.amount = left
		pickup.position = position
		get_parent().add_child(pickup)


## Dźwięk podniesionego przedmiotu: rzadkie dzwonią, zwykłe szeleszczą.
func _on_item_picked(id: String, _amount: int) -> void:
	var item := Items.get_data(id)
	if item.has("stone") or item.has("enchant_aid"):
		Sfx.play("pickup_rare")
	else:
		Sfx.play("pickup")


## Kroki: po trawie na zewnątrz, po deskach w budynkach.
func _update_footsteps(delta: float, input: Vector2) -> void:
	_water_check -= delta
	if _water_check <= 0.0:
		_water_check = 0.1
		# płycizna według danych krainy (kafelki wody mają przejścia Wang, więc nie sprawdzamy atlasu)
		var world := get_tree().current_scene
		_in_water = world != null and world.has_method("water_at") and world.water_at(global_position) == "shallow"
	if input == Vector2.ZERO or is_dashing() or _move_velocity.length() < 20.0:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = 0.32
	var indoors := false
	for building: Building in get_tree().get_nodes_in_group("buildings"):
		if building.is_player_inside():
			indoors = true
			break
	Sfx.play("step_wood" if indoors else "step_water" if _in_water else "step_grass")


## Co chwilę szuka najbliższego drzewa / głazu w zasięgu i pokazuje nad nim podpowiedź.
func _scan_harvestables(delta: float) -> void:
	_harvest_scan -= delta
	if _harvest_scan <= 0.0:
		_harvest_scan = 0.15
		_nearest_harvestable = null
		var best := HARVEST_RANGE
		for target: Harvestable in get_tree().get_nodes_in_group("harvestables"):
			var d := target.global_position.distance_to(global_position)
			if d < best and target.can_harvest():
				best = d
				_nearest_harvestable = target
	var npc_near := false
	for npc: Node2D in get_tree().get_nodes_in_group("interactables"):
		if npc.global_position.distance_to(global_position) < Npc.INTERACT_DISTANCE:
			npc_near = true
			break
	_harvest_prompt.visible = _nearest_harvestable != null and _harvest_target == null and not npc_near
	if _harvest_prompt.visible:
		_harvest_prompt.text = "[F] " + _nearest_harvestable.action_name
		_harvest_prompt.global_position = _nearest_harvestable.global_position + Vector2(-30, -_nearest_harvestable.bar_height - 10.0)


func _make_harvest_prompt() -> Label:
	var label := Label.new()
	label.top_level = true
	label.z_index = 40
	label.size = Vector2(60, 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	return label


# ---------------------------------------------------------------- zapis
func get_save_data() -> Dictionary:
	# martwy gracz zapisuje się tak, jakby już się odrodził
	var pos := spawn_point if is_dead else global_position
	return {
		"position": [pos.x, pos.y],
		"health": stats.max_health() if is_dead else health,
		"mana": mana,
		"stats": stats.get_save_data(),
		"inventory": inventory.get_save_data(),
		"equipment": equipment.get_save_data(),
		"skills": skills.get_save_data(),
		"quests": quests.get_save_data(),
		"storage": storage.get_save_data(),
		"bags": bags.duplicate(),
		"boons": boons.get_save_data(),
		"hotbar": hotbar.get_save_data(),
		"codex": codex.get_save_data(),
		"travelers": travelers.get_save_data(),
		"market": market.get_save_data(),
		"events": events.get_save_data(),
		"free_sockets": free_sockets,
		"generated_items": Loot.export_used(_owned_ids()),
		"hero": hero,
	}


## Wszystkie przedmioty gracza (plecak, postać, magazyn) - do zapisu wylosowanych przedmiotów.
func _owned_ids() -> Array:
	var ids := []
	for slot: Dictionary in inventory.slots + storage.slots:
		if not slot.is_empty():
			ids.append(slot["id"])
	for slot in Equipment.SLOTS:
		ids.append(equipment.get_item(slot))
	return ids


## Zadanie jubilera wykonane: kamienie szlachetne i gniazda zaczynają wypadać, pierwsze gniazdo za darmo
## i pierwszy kamień na próbę.
## Prośba drużyny o pomoc wykonana: nagroda wypłaca się sama, a zleceniodawca dziękuje.
func _on_quest_ready(id: String) -> void:
	if Quests.get_data(id).get("help", false):
		_finish_help.call_deferred(id)


func _finish_help(id: String) -> void:
	var quest := Quests.get_data(id).duplicate()
	if not quests.finish_bounty(id, self):
		return
	Sfx.play("quest_done")
	DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -14), "+%d zł  +%d exp" % [quest["gold"], quest["xp"]],
			Color(1.0, 0.85, 0.3), 10)
	for node in get_tree().get_nodes_in_group("travelers"):
		if node.data.get("name", "") == quest.get("poster", ""):
			node.say(["Dzięki, bez ciebie byśmy nie dali rady!", "Dobra robota! Należy ci się nagroda.",
					"Świetnie się z tobą walczy. Dziękujemy!"].pick_random())


func _on_quest_done(id: String) -> void:
	# zadania główne: przedmioty i punkty umiejętności
	if MainQuests.is_main(id):
		var quest := Quests.get_data(id)
		var items: Dictionary = quest.get("reward_items", {})
		for item: String in items:
			_gain_item(item, int(items[item]))
		if int(quest.get("skill_points", 0)) > 0:
			skills.bonus_points += int(quest["skill_points"])
			skills.changed.emit()
	if id != Gems.QUEST:
		return
	Gems.unlocked = true
	free_sockets += 1
	_gain_item(Gems.roll("", 0), 1)


func load_save_data(data: Dictionary) -> void:
	set_hero(str(data.get("hero", hero)))
	# wylosowane przedmioty muszą istnieć, zanim wczytamy plecak, postać i magazyn
	Loot.import(data.get("generated_items", {}))
	# torby najpierw - od nich zależy, ile miejsc ma plecak
	for i in BAG_SLOTS:
		var saved: Array = data.get("bags", [])
		var id := str(saved[i]) if i < saved.size() else ""
		bags[i] = id if Items.is_bag(id) else ""
	inventory.resize(inventory_capacity())
	bags_changed.emit()
	# starsze zapisy nie mają ekwipunku - zostaje startowa broń
	if data.has("equipment"):
		equipment.load_save_data(data["equipment"])
	if data.has("skills"):
		skills.load_save_data(data["skills"])
	if data.has("quests"):
		quests.load_save_data(data["quests"])
	Gems.unlocked = quests.state_of(Gems.QUEST) == Quests.STATE_DONE
	free_sockets = int(data.get("free_sockets", 0))
	if data.has("storage"):
		storage.load_save_data(data["storage"])
	boons.load_save_data(data.get("boons", {}))
	# starsze zapisy bez paska - zostaje domyślny (mikstury pod 1 i 2, umiejętności pod LPM, PPM i Q)
	if data.has("hotbar"):
		hotbar.load_save_data(data["hotbar"])
	stats.load_save_data(data.get("stats", {}))
	skills.character_level = stats.level
	skills.changed.emit()
	inventory.load_save_data(data.get("inventory", []))
	# starsze zapisy bez encyklopedii odkrywają przynajmniej to, co gracz ma
	codex.load_save_data(data.get("codex", {}))
	travelers.load_save_data(data.get("travelers", {}))
	market.load_save_data(data.get("market", {}))
	events.load_save_data(data.get("events", {}))
	codex.note_owned(self)
	var pos: Array = data.get("position", [spawn_point.x, spawn_point.y])
	global_position = Vector2(pos[0], pos[1])
	reset_physics_interpolation()  # skok, nie ruch - bez smugi przez ekran
	_last_max_health = stats.max_health()
	_last_max_mana = stats.max_mana()
	health = clampi(int(data.get("health", _last_max_health)), 1, _last_max_health)
	mana = clampf(float(data.get("mana", _last_max_mana)), 0.0, _last_max_mana)
	camera.reset_smoothing()
	_emit_resources()


# ---------------------------------------------------------------- statystyki
func _on_stats_changed() -> void:
	# zwiększenie maksimum dodaje też tyle samo do bieżącej wartości
	var max_hp := stats.max_health()
	var max_mp := stats.max_mana()
	if not is_dead:
		health = clampi(health + max_hp - _last_max_health, 0, max_hp)
	mana = clampf(mana + max_mp - _last_max_mana, 0.0, max_mp)
	_last_max_health = max_hp
	_last_max_mana = max_mp
	_emit_resources()


func _on_leveled_up(new_level: int) -> void:
	skills.character_level = new_level
	skills.changed.emit()
	if not is_dead:
		health = stats.max_health()
		mana = stats.max_mana()
		_emit_resources()
	DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -14), "Poziom %d!" % new_level, LEVEL_UP_COLOR, 12)
	Sfx.play("level_up")
	_flash(LEVEL_UP_COLOR)


func _regenerate_mana(delta: float) -> void:
	var max_mp := stats.max_mana()
	if mana >= max_mp:
		return
	var before := int(mana)
	var rate := mana_regen + skills.regen("mana_regen", stats.weapon_type(), max_mp) + stats.mana_regen() \
			+ max_mp * _village_regen()
	mana = minf(mana + rate * delta, max_mp)
	if int(mana) != before:
		mana_changed.emit(int(mana), max_mp)


## Regeneracja zdrowia z umiejętności pasywnych założonej broni i z przedmiotów.
func _regenerate_health(delta: float) -> void:
	var rate := skills.regen("health_regen", stats.weapon_type(), stats.max_health()) + stats.health_regen() \
			+ stats.max_health() * _village_regen()
	if rate <= 0.0 or health >= stats.max_health():
		_health_regen_progress = 0.0
		return
	_health_regen_progress += rate * delta
	if _health_regen_progress >= 1.0:
		var gained := int(_health_regen_progress)
		_health_regen_progress -= gained
		health = mini(health + gained, stats.max_health())
		health_changed.emit(health, stats.max_health())


## Róg straży: żołnierze Ostoi pojawiają się po obu stronach postaci i walczą przez chwilę.
func _summon_guards(count: int) -> void:
	Sfx.play("barracks")
	for i in count:
		var ally := SoldierAlly.new()
		ally.player = self
		ally.sheet = load("res://assets/npc/%s.png" % ["soldier_a", "soldier_b", "soldier_c"][i % 3])
		ally.position = global_position + Vector2(-26.0 if i % 2 == 0 else 26.0, 4.0 + 6.0 * (i / 2))
		ally.set("_side", -1.0 if i % 2 == 0 else 1.0)
		get_parent().add_child(ally)


## Sylwetka postaci prześwitująca przez zasłony (drzewa, namioty - Occlusion): kopia bieżącej klatki
## rysowana nad wszystkim jednolitym, półprzezroczystym kolorem. Pojawia się i gaśnie płynnie.
const SILHOUETTE_SHADER := preload("res://shaders/silhouette.gdshader")
var _silhouette: Sprite2D
var _occluded := false


func set_occluded(occluded: bool) -> void:
	_occluded = occluded


func _update_silhouette(delta: float) -> void:
	if _silhouette == null:
		_silhouette = Sprite2D.new()
		var material := ShaderMaterial.new()
		material.shader = SILHOUETTE_SHADER
		_silhouette.material = material
		_silhouette.z_index = 60
		_silhouette.modulate.a = 0.0
		add_child(_silhouette)
	var target := 1.0 if _occluded and not is_dead else 0.0
	_silhouette.modulate.a = move_toward(_silhouette.modulate.a, target, delta * 5.0)
	_silhouette.visible = _silhouette.modulate.a > 0.0
	if not _silhouette.visible:
		return
	_silhouette.texture = sprite.texture
	_silhouette.hframes = sprite.hframes
	_silhouette.vframes = sprite.vframes
	_silhouette.frame = sprite.frame
	_silhouette.flip_h = sprite.flip_h
	_silhouette.offset = sprite.offset
	_silhouette.position = sprite.position
	_silhouette.scale = sprite.scale


## Lecznica w osadzie: za palisadą zdrowie i mana wracają szybciej (ułamek maksimum na sekundę).
func _village_regen() -> float:
	var settlement := get_tree().get_first_node_in_group("settlement") as Settlement
	return settlement.regen_bonus(global_position) if settlement != null else 0.0


func _emit_resources() -> void:
	health_changed.emit(health, stats.max_health())
	mana_changed.emit(int(mana), stats.max_mana())


# ---------------------------------------------------------------- atak
func _start_attack() -> void:
	var weapon := equipment.weapon()
	var aim := get_global_mouse_position() - body_center()
	if aim == Vector2.ZERO:
		aim = _facing_vector()
	_attack_angle = aim.angle()
	_attack_kind = weapon.get("type", "melee")
	_attack_multiplier = 1.0
	var speed: float = stats.attack_speed() * weapon.get("speed", 1.0)
	_hit_this_swing.clear()

	pivot.rotation = _attack_angle
	sword.visible = sword.texture != null
	_face_direction(aim)

	if _attack_kind == "melee":
		_attack_length = attack_duration / speed
		_attack_cooldown_timer = (attack_duration + attack_cooldown) / speed
		_attack_reach = weapon.get("reach", attack_reach)
		_attack_arc = deg_to_rad(weapon.get("arc", attack_arc_degrees))
		_swing_sign = -_swing_sign  # kolejne cięcia na przemian z góry i z dołu
		sword.flip_v = false
		slash.flip_v = _swing_sign < 0.0
		slash.scale = Vector2.ONE * (_attack_reach / 30.0)
		slash.frame = 0
		slash.visible = true
		Sfx.play("swing")
		legendary.on_melee_swing(aim.normalized())
	else:
		_attack_cooldown_timer = weapon["cooldown"] / speed
		_attack_length = minf(RANGED_POSE_TIME, _attack_cooldown_timer)
		# księga i łuk zawsze "do góry", także przy celowaniu w lewo
		sword.rotation = 0.0
		sword.flip_v = absf(_attack_angle) > PI / 2.0
		_shoot(weapon, aim.normalized())
	_attack_timer = _attack_length
	_update_attack(0.0)


func _update_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_kind == "melee":
		var progress := clampf(1.0 - _attack_timer / _attack_length, 0.0, 1.0)
		var half_arc := _attack_arc / 2.0
		sword.rotation = lerpf(-half_arc, half_arc, ease(progress, 0.5)) * _swing_sign
		slash.frame = mini(int(progress * slash.hframes), slash.hframes - 1)
		_hit_enemies_in_arc(half_arc)

	if _attack_timer <= 0.0:
		sword.visible = false
		slash.visible = false


## Wystrzeliwuje strzałę albo magiczny pocisk w kierunku `dir`.
func _shoot(weapon: Dictionary, dir: Vector2) -> void:
	get_parent().add_child(_make_projectile(weapon, dir))
	Sfx.play("bow" if weapon["type"] == "bow" else "magic")


## Pocisk broni gotowy do wystrzelenia (jeszcze nie dodany do świata).
func _make_projectile(weapon: Dictionary, dir: Vector2) -> Projectile:
	var config: Dictionary = weapon["projectile"]
	var projectile: Projectile = PROJECTILE.instantiate()
	projectile.position = position + dir * 6.0
	projectile.direction = dir
	projectile.speed = config["speed"]
	projectile.max_range = config["range"]
	projectile.pierce = config["pierce"]
	projectile.magic = config["magic"]
	projectile.texture = config["texture"]
	if weapon["type"] == "bow":
		projectile.pierce += roundi(skills.tree_bonus("bow", "arrow_pierce"))
		projectile.max_range *= 1.0 + skills.tree_bonus("bow", "arrow_range")
	var kind := stats.kind_multiplier(basic_tags())
	projectile.damage_min = maxi(1, roundi(stats.damage_min() * kind))
	projectile.damage_max = maxi(1, roundi(stats.damage_max() * kind))
	return projectile


# ---------------------------------------------------------------- umiejętności (PPM)
func _process_skill(delta: float) -> void:
	var id := skills.active_for(stats.weapon_type())
	if is_charging_fireball():
		_update_fireball_charge(delta, id)
		return
	if _whirling:
		if not _skill_held or id != "whirlwind" or not spend_mana(Skills.WHIRLWIND_MANA_PER_SECOND * delta * whirl_mana_factor()):
			_stop_whirl()
		return
	if not _skill_held or is_dashing() or _harvest_target != null or _lunge_time > 0.0:
		return
	if id == "":
		_hint("Odblokuj umiejętność tej broni (K)")
		return
	match id:
		"whirlwind":
			if mana >= Skills.WHIRLWIND_MANA_PER_SECOND * 0.3:
				_start_whirl()
			else:
				_hint("Za mało many")
		"multishot":
			if not skill_ready() or is_attacking():
				return
			# Salwa zaraz po Odskoku: darmowa i z większą liczbą strzał
			var combo := combo_with("multishot")
			if combo or spend_mana(Skills.MULTISHOT_MANA):
				if combo:
					combo_used()
				_cast(id, 0.0, combo)
			else:
				_hint("Za mało many")
		"fireball":
			if not skill_ready() or is_attacking():
				return
			if spend_mana(Skills.FIREBALL_MANA):
				# Kula ognia zaraz po Kroku przez Mgłę: od razu w pełni naładowana
				if combo_with("fireball"):
					combo_used()
					_cast("fireball", 1.0)
				else:
					_start_fireball_charge()
			else:
				_hint("Za mało many")


func is_charging_fireball() -> bool:
	return _fireball_charge >= 0.0


func _start_fireball_charge() -> void:
	_cancel_attack()
	_fireball_charge = 0.0
	_fireball_full = false
	_fireball_pop = 1.0
	_fireball_orb.visible = true
	_fireball_orb.modulate = Color.WHITE
	_fireball_embers.emitting = true
	_charge_sound.play()


## Kula rośnie w dłoniach i zjada manę aż do pełnej mocy; puszczenie PPM ją rzuca.
func _update_fireball_charge(delta: float, id: String) -> void:
	if id != "fireball" or is_dashing():
		_stop_fireball_charge()
		return
	var aim := get_global_mouse_position() - body_center()
	var dir := aim.normalized() if aim != Vector2.ZERO else _facing_vector()
	_ranged_pose(dir)
	if not _skill_held:
		var charge := _fireball_charge
		_stop_fireball_charge()
		_cast("fireball", charge)
		return
	_fireball_time += delta
	if not _fireball_full:
		var step := delta * _skill_speed(["spell"]) * (1.0 + skills.tree_bonus("spell", "fireball_charge")) / Skills.FIREBALL_CHARGE_TIME
		if spend_mana(Skills.FIREBALL_CHARGE_MANA * step):
			_fireball_charge = minf(_fireball_charge + step, 1.0)
			_charge_sound.stream_paused = false
			if _fireball_charge >= 1.0:
				_on_fireball_full()
		else:
			# bez many kula przestaje rosnąć, ale wciąż można ją rzucić
			_charge_sound.stream_paused = true
			_hint("Za mało many")
	# kula w dłoniach: rośnie, pulsuje, a po pełnym naładowaniu nagle się powiększa
	var pulse := 1.0 + (0.1 if _fireball_full else 0.05) * sin(_fireball_time * (22.0 if _fireball_full else 14.0))
	var grow := lerpf(0.35, 1.0, _fireball_charge) * (1.45 if _fireball_full else 1.0)
	_fireball_orb.scale = Vector2.ONE * grow * pulse * _fireball_pop
	_fireball_orb.position = to_local(body_center() + dir * 11.0)
	_fireball_orb.rotation += delta * 6.0
	_fireball_embers.position = _fireball_orb.position
	_fireball_embers.emission_sphere_radius = 8.0 + 8.0 * _fireball_charge


func _on_fireball_full() -> void:
	_fireball_full = true
	_fireball_pop = 1.6
	create_tween().tween_property(self, "_fireball_pop", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_fireball_orb.modulate = Color(1.6, 1.3, 1.0)
	_fireball_embers.amount = 24
	_charge_sound.stop()
	_hold_sound.play()
	Sfx.play("fireball_full")
	add_shake(1.5)
	var flare := CPUParticles2D.new()
	flare.position = _fireball_orb.position
	flare.one_shot = true
	flare.explosiveness = 1.0
	flare.amount = 20
	flare.lifetime = 0.4
	flare.direction = Vector2.RIGHT
	flare.spread = 180.0
	flare.gravity = Vector2.ZERO
	flare.initial_velocity_min = 40.0
	flare.initial_velocity_max = 90.0
	flare.damping_min = 100.0
	flare.damping_max = 160.0
	flare.scale_amount_max = 2.5
	flare.color_ramp = _fire_ramp()
	flare.emitting = true
	add_child(flare)
	flare.finished.connect(flare.queue_free)


func _stop_fireball_charge() -> void:
	_fireball_charge = -1.0
	_fireball_full = false
	_fireball_orb.visible = false
	_fireball_embers.emitting = false
	_charge_sound.stop()
	_hold_sound.stop()
	sword.visible = false
	_update_weapon_sprite()


## Kula ognia w dłoniach (ukryta, dopóki nie ładujemy) i jej dźwięki.
func _make_fireball_orb() -> void:
	_fireball_orb = Sprite2D.new()
	_fireball_orb.texture = FIREBALL_TEXTURE
	_fireball_orb.visible = false
	_fireball_orb.z_index = 1
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fireball_orb.material = glow
	add_child(_fireball_orb)
	# żar wciągany do kuli
	_fireball_embers = CPUParticles2D.new()
	_fireball_embers.emitting = false
	_fireball_embers.amount = 14
	_fireball_embers.lifetime = 0.45
	_fireball_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_fireball_embers.emission_sphere_radius = 10.0
	_fireball_embers.gravity = Vector2(0, -20)
	_fireball_embers.radial_accel_min = -90.0
	_fireball_embers.radial_accel_max = -60.0
	_fireball_embers.scale_amount_max = 2.0
	_fireball_embers.color_ramp = _fire_ramp()
	add_child(_fireball_embers)
	_charge_sound = _sound_player("res://assets/sfx/fireball_charge.ogg", false)
	_hold_sound = _sound_player("res://assets/sfx/fireball_hold.ogg", true)


func _sound_player(path: String, loop: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load(path).duplicate()
	stream.loop = loop
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = -4.0
	add_child(player)
	return player


func _fire_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 0.95, 0.6), Color(1, 0.5, 0.1, 0.9), Color(0.6, 0.15, 0.05, 0.0)])
	return ramp


## Poza z bronią dystansową (księga) wycelowaną w `dir`.
func _ranged_pose(dir: Vector2) -> void:
	_attack_angle = dir.angle()
	pivot.rotation = _attack_angle
	sword.rotation = 0.0
	sword.flip_v = absf(_attack_angle) > PI / 2.0
	sword.visible = sword.texture != null
	_face_direction(dir)


## Wstrząs kamery (np. bliski wybuch).
func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Salwa trzech strzał albo kula ognia (`charge` 0..1 - naładowanie) w stronę kursora.
## Salwa: więcej strzał z węzłów drzewka i Gradu, a w combo po Odskoku - Skills.VAULT_VOLLEY_ARROWS.
func _cast(id: String, charge := 0.0, combo := false) -> void:
	var weapon := equipment.weapon()
	var aim := get_global_mouse_position() - body_center()
	if aim == Vector2.ZERO:
		aim = _facing_vector()
	var dir := aim.normalized()
	var level := skills.level_of(id)
	note_skill(id)

	# poza z bronią w ręku, jak przy zwykłym strzale
	_attack_kind = weapon["type"]
	_attack_angle = dir.angle()
	pivot.rotation = _attack_angle
	sword.rotation = 0.0
	sword.flip_v = absf(_attack_angle) > PI / 2.0
	sword.visible = sword.texture != null
	_face_direction(dir)
	_attack_length = RANGED_POSE_TIME
	_attack_timer = _attack_length
	_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.25)

	if id == "multishot":
		_skill_cooldown_timer = _cooldown(Skills.MULTISHOT_COOLDOWN)
		_skill_cooldown_total = _skill_cooldown_timer
		var hail := bow_skills.has_keystone("hail")
		var count := (Skills.VAULT_VOLLEY_ARROWS if combo else Skills.MULTISHOT_ARROWS) \
				+ roundi(skills.tree_bonus("bow", "multishot_arrows")) + (BowSkills.HAIL_ARROWS if hail else 0)
		var spread := deg_to_rad(Skills.MULTISHOT_SPREAD_DEGREES) * sqrt(count / float(Skills.MULTISHOT_ARROWS))
		var multiplier := Skills.multishot_damage(level) * (1.0 + skills.tree_bonus("bow", "multishot_damage")) \
				* (BowSkills.HAIL_DAMAGE if hail else 1.0) * (combo_damage() if combo else 1.0)
		for i in count:
			var angle := lerpf(-spread / 2.0, spread / 2.0, float(i) / (count - 1))
			var arrow := _make_projectile(weapon, dir.rotated(angle))
			arrow.damage_min = roundi(arrow.damage_min * multiplier)
			arrow.damage_max = roundi(arrow.damage_max * multiplier)
			get_parent().add_child(arrow)
		Sfx.play("bow", 2.0, 0.9)
	else:
		_skill_cooldown_timer = _cooldown(Skills.FIREBALL_COOLDOWN, ["spell"])
		_skill_cooldown_total = _skill_cooldown_timer
		var fireball := _make_projectile(weapon, dir)
		var multiplier := Skills.fireball_damage(level) * Skills.fireball_charge_damage(charge) * (1.0 + skills.tree_bonus("spell", "fireball_damage"))
		fireball.texture = FIREBALL_TEXTURE
		fireball.magic = false
		fireball.fire = true
		fireball.pierce = 0
		fireball.speed = 210.0
		fireball.explosion_radius = Skills.fireball_radius(level) * Skills.fireball_charge_radius(charge) * stats.area_multiplier()
		fireball.size = lerpf(0.8, 1.7, charge)
		multiplier *= stats.kind_multiplier(["spell"])
		fireball.explosion_min = roundi(stats.damage_min() * multiplier)
		fireball.explosion_max = roundi(stats.damage_max() * multiplier)
		fireball.turret_damage = legendary.fire_turret_damage(multiplier)
		get_parent().add_child(fireball)
		Sfx.play("fireball_launch", lerpf(-4.0, 2.0, charge), lerpf(1.15, 0.85, charge))


func _start_whirl() -> void:
	_cancel_attack()
	_whirling = true
	_whirl_tick = 0.0
	note_skill("whirlwind")
	var radius := whirl_radius()
	sword.visible = sword.texture != null
	sword.rotation = 0.0
	sword.flip_v = false
	slash.visible = true
	slash.frame = 1
	slash.flip_v = false
	slash.scale = Vector2.ONE * (radius / 30.0)


## Postać kręci się z bronią, a co chwilę rani wszystkich w promieniu.
func _update_whirl(delta: float) -> void:
	pivot.rotation += WHIRL_SPIN_SPEED * delta
	_face_direction(Vector2.from_angle(pivot.rotation))
	_whirl_tick -= delta
	if _whirl_tick > 0.0:
		return
	_whirl_tick = Skills.WHIRLWIND_TICK / _skill_speed()
	Sfx.play("whirl")
	var level := skills.level_of("whirlwind")
	var radius := whirl_radius()
	var multiplier := Skills.whirlwind_damage(level) * (1.0 + skills.tree_bonus("melee", "whirl_damage"))
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(body_center()) <= radius + enemy.hurt_radius:
			hit_enemy(enemy, _skill_damage(multiplier), global_position, 70.0)


func _stop_whirl() -> void:
	_whirling = false
	sword.visible = false
	slash.visible = false
	slash.scale = Vector2.ONE


func _hint(text: String) -> void:
	if _hint_cooldown > 0.0:
		return
	_hint_cooldown = 1.5
	DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -12), text, Color(0.7, 0.8, 1.0), 8)


## Tekstura broni w ręku zależy od założonej broni (bez broni - pięści).
func _update_weapon_sprite() -> void:
	var weapon := equipment.weapon()
	sword.texture = weapon.get("held")
	sword.offset = _held_offset(weapon, false)


## Przesunięcie grafiki broni względem punktu obrotu: chwyt (weapon.grip, w pikselach grafiki) leży
## w punkcie obrotu - dłoni albo barku przy zamachu. Odbicie w pionie przenosi chwyt na drugą stronę.
## Grafiki bez chwytu (dawne) przesuwa held_offset.
func _held_offset(weapon: Dictionary, flipped: bool) -> Vector2:
	var held: Texture2D = weapon.get("held")
	if held == null or not weapon.has("grip"):
		return weapon.get("held_offset", Vector2(13, 0))
	var offset: Vector2 = held.get_size() / 2.0 - weapon["grip"]
	return Vector2(offset.x, -offset.y) if flipped else offset


## Sposób trzymania broni: blade (wzdłuż ręki), bow albo book (zawsze grzbietem w górę).
func _hold_of(weapon: Dictionary) -> String:
	return weapon.get("hold", "book" if weapon.get("type", "") == "spell" else "blade")


## Zadaje obrażenia każdemu wrogowi, którego dotyka łuk cięcia.
func _hit_enemies_in_arc(half_arc: float) -> void:
	var origin := body_center()
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if _hit_this_swing.has(enemy):
			continue
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > _attack_reach + enemy.hurt_radius:
			continue
		# wróg bardzo blisko obrywa zawsze, dalej musi być w obrębie łuku
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(_attack_angle, to_enemy.angle())) > half_arc:
			continue
		_hit_this_swing[enemy] = true
		var dmg := _skill_damage(_attack_multiplier)
		hit_enemy(enemy, dmg, global_position, attack_knockback * (1.6 if _attack_multiplier > 1.0 else 1.0))


# ---------------------------------------------------------------- uderzenia i dodatkowe ciosy
func strike_ready() -> bool:
	return _strike_cooldown <= 0.0


## Czy trwa okno na dodatkowy cios (atak zaraz po uderzeniu).
func combo_ready() -> bool:
	return _combo_window > 0.0 and skills.combo_for(stats.weapon_type()) != ""


func _process_strikes() -> void:
	if _strike_request:
		_strike_request = false
		_use_strike()
	if _combo_request:
		_combo_request = false
		_use_combo()


func _strike_blocked() -> bool:
	return is_dashing() or _lunge_time > 0.0 or _whirling or is_charging_fireball() or _harvest_target != null


func _use_strike() -> void:
	var id := skills.strike_for(stats.weapon_type())
	if id == "":
		_hint("Odblokuj uderzenie tej broni (K)")
		return
	if _strike_blocked() or not strike_ready():
		return
	var cost: float = {"lunge": Skills.LUNGE_MANA, "seeker": Skills.SEEKER_MANA, "chain_lightning": Skills.CHAIN_MANA}[id]
	# Szarża zaraz po udanej Ripoście: za darmo i bez odnowienia
	var free := combo_with(id)
	if free:
		cost = 0.0
		combo_used()
	if not spend_mana(cost):
		_hint("Za mało many")
		return
	var level := skills.level_of(id)
	match id:
		"lunge":
			_strike_cooldown = 0.0 if free else _cooldown(Skills.LUNGE_COOLDOWN) * (1.0 + skills.tree_bonus("melee", "lunge_cooldown"))
			_strike_cooldown_total = _strike_cooldown
			_start_lunge(level)
		"seeker":
			_strike_cooldown = _cooldown(Skills.SEEKER_COOLDOWN)
			_strike_cooldown_total = _strike_cooldown
			_cast_seeker(level)
			_combo_window = combo_window()
			note_skill(id)
		"chain_lightning":
			_strike_cooldown = _cooldown(Skills.CHAIN_COOLDOWN, ["spell"])
			_strike_cooldown_total = _strike_cooldown
			_cast_chain(level)
			_combo_window = combo_window()
			note_skill(id)


func _use_combo() -> void:
	var id := skills.combo_for(stats.weapon_type())
	if id == "" or _combo_window <= 0.0 or _strike_blocked():
		return
	var cost: float = {"crescent": Skills.CRESCENT_MANA, "rapid_volley": Skills.VOLLEY_MANA, "thunder_wave": Skills.WAVE_MANA}[id]
	if not spend_mana(cost):
		_hint("Za mało many")
		return
	_combo_window = 0.0
	var level := skills.level_of(id)
	note_skill(id)
	combo_used()
	match id:
		"crescent":
			_start_crescent(level)
		"rapid_volley":
			_cast_volley(level)
		"thunder_wave":
			_cast_wave(level)


## Kierunek celowania dla testera-bota (tests/playtest_bot.gd) zamiast myszy; zero - mysz.
var aim_override := Vector2.ZERO


func _aim_direction() -> Vector2:
	if aim_override != Vector2.ZERO:
		return aim_override.normalized()
	var aim := get_global_mouse_position() - body_center()
	return aim.normalized() if aim != Vector2.ZERO else _facing_vector()


## Prędkość ataku przyspiesza też umiejętności: krótsze odnowienie, szybsze ładowanie kuli
## ognia, szybsza salwa, łańcuch błyskawic, wir i półksiężyc.
## Spowolnienie na chwilę (odświeżane, dopóki działa źródło) - postać lekko sinieje.
## Oszołomienie: przez `seconds` sterowanie ruchem jest odwrócone (nad głową krążą nuty).
func confuse(seconds: float) -> void:
	if is_dead:
		return
	_confused_time = maxf(_confused_time, seconds)
	DamageNumber.spawn_text(get_parent(), body_center() + Vector2(0, -16), "Oszołomienie!", Color(1.0, 0.8, 0.35), 9)


func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor) if _slow_time > 0.0 else factor
	_slow_time = maxf(_slow_time, duration)
	sprite.self_modulate = Color(0.75, 0.9, 1.0)


## Zatrucie: co pół sekundy traci zdrowie (z pominięciem pancerza i nietykalności), zielenieje.
## Nowe zatrucie odświeża czas i bierze mocniejszą truciznę.
func apply_poison(dps: float, duration: float) -> void:
	if is_dead:
		return
	_poison_dps = maxf(_poison_dps if _poison_time > 0.0 else 0.0, dps)
	_poison_time = maxf(_poison_time, duration)


func is_poisoned() -> bool:
	return _poison_time > 0.0


func _update_poison(delta: float) -> void:
	if _poison_time <= 0.0:
		return
	_poison_time -= delta
	_poison_tick -= delta
	sprite.modulate = Color(0.75, 1.0, 0.65)
	if _poison_tick <= 0.0 and not is_dead:
		_poison_tick = 0.5
		var amount := maxi(1, roundi(_poison_dps * 0.5))
		health = maxi(health - amount, 0)
		health_changed.emit(health, stats.max_health())
		DamageNumber.spawn(get_parent(), body_center() + Vector2(randf_range(-6, 6), 0), amount, POISON_COLOR)
		if health == 0:
			_poison_time = 0.0
			_die()
	if _poison_time <= 0.0:
		sprite.modulate = Color.WHITE


## Leczenie (np. Perła Wodnika) - bez przekraczania maksimum.
func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	_heal_buffer += amount
	if _heal_buffer >= 1.0:
		var whole := floori(_heal_buffer)
		_heal_buffer -= whole
		health = mini(health + whole, stats.max_health())
		health_changed.emit(health, stats.max_health())


## Szybkość umiejętności: ataki przyspiesza szybkość ataku, czary - szybkość rzucania (Skills.tags).
func _skill_speed(tags: Array = ["attack"]) -> float:
	return stats.skill_speed(tags)


## Czas odnowienia umiejętności: krótszy z szybkością ataku / rzucania i ze skróceniem odnowienia z przedmiotów.
func _cooldown(base: float, tags: Array = ["attack"]) -> float:
	return base / _skill_speed(tags) * stats.cooldown_multiplier()


## Obrażenia broni razy mnożnik umiejętności i premia do rodzaju (fizyczne dla ataków, magiczne dla czarów).
func _skill_damage(multiplier: float, tags: Array = ["attack"]) -> int:
	return maxi(1, roundi(randi_range(stats.damage_min(), stats.damage_max()) * multiplier * stats.kind_multiplier(tags)))


## Losowe obrażenia broni razy mnożnik (dla efektów legendarnych przedmiotów - bez premii do rodzaju).
func roll_damage(multiplier: float) -> int:
	return roundi(_skill_damage(multiplier, []) * legendary.damage_multiplier() * stats.damage_multiplier())


## Rodzaj zwykłego ataku bronią: magiczny pocisk księgi to czar, reszta - atak.
func basic_tags() -> Array:
	return ["spell"] if stats.weapon_type() == "spell" else ["attack"]


## Każde trafienie wroga przez gracza (broń, umiejętności, pociski) przechodzi tędy,
## żeby legendarne pierścienie mogły odpalić swoje efekty. Tu działają też premie z przedmiotów:
## zwiększone obrażenia, cios krytyczny i zdrowie za trafienie.
func hit_enemy(enemy: Goblin, amount: int, from_position: Vector2, knockback: float) -> void:
	if enemy.state == Goblin.State.DEAD:
		return
	amount = roundi(amount * legendary.damage_multiplier() * stats.damage_multiplier() * boons.damage_multiplier(enemy))
	amount += legendary.execute_bonus(enemy)
	var bow := stats.weapon_type() == "bow"
	if bow:
		amount = roundi(amount * bow_skills.damage_factor(enemy))
	var critical := randf() < stats.crit_chance() or sword_skills.take_forced_crit() or (bow and bow_skills.forced_crit(enemy))
	if critical:
		amount = roundi(amount * stats.crit_multiplier())
	DamageNumber.critical = critical
	enemy.take_damage(amount, from_position, knockback)
	DamageNumber.critical = false
	if bow:
		bow_skills.on_hit(enemy, amount)
	if not is_dead:
		if enemy.state == Goblin.State.DEAD:
			legendary.on_kill(enemy)
		legendary.on_hit(enemy)
		legendary.count_hit(enemy)
		legendary.leech(amount)
		heal(stats.life_on_hit())


## Szarża: błyskawiczne pchnięcie w stronę kursora - postać pędzi z mieczem przed sobą
## i rani wszystkich na drodze (każdego raz). W trakcie jest nietykalna.
func _start_lunge(level: int) -> void:
	_cancel_attack()
	_lunge_dir = _aim_direction()
	_lunge_speed = Skills.lunge_speed(level)
	_lunge_damage = Skills.lunge_damage(level)
	_lunge_time = Skills.LUNGE_DISTANCE / _lunge_speed
	_lunge_hit.clear()
	_face_direction(_lunge_dir)
	pivot.rotation = _lunge_dir.angle()
	sword.visible = sword.texture != null
	sword.rotation = 0.0
	sword.flip_v = false
	Sfx.play("dash")
	Sfx.play("swing", 2.0, 0.8)


func _update_lunge(delta: float) -> void:
	_lunge_time -= delta
	_move_velocity = _lunge_dir * _lunge_speed
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_spawn_ghost()
		_ghost_timer = GHOST_INTERVAL * 0.6
	var tip := body_center() + _lunge_dir * 14.0
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if _lunge_hit.has(enemy):
			continue
		if enemy.hurt_center().distance_to(tip) <= enemy.hurt_radius + 14.0:
			_lunge_hit[enemy] = true
			hit_enemy(enemy, _skill_damage(_lunge_damage), global_position, 180.0)
	var blocked := get_slide_collision_count() > 0 and _lunge_time < Skills.LUNGE_DISTANCE / _lunge_speed - 0.05
	if _lunge_time <= 0.0 or blocked:
		_lunge_time = 0.0
		_move_velocity = _lunge_dir * max_speed * 0.4
		sword.visible = false
		_update_weapon_sprite()
		_combo_window = combo_window()
		note_skill("lunge")


## Półksiężyc: potężne, bardzo szerokie cięcie zaraz po szarży.
func _start_crescent(level: int) -> void:
	var aim := _aim_direction()
	_attack_angle = aim.angle()
	_attack_kind = "melee"
	_hit_this_swing.clear()
	_attack_length = 0.32 / _skill_speed()
	_attack_cooldown_timer = 0.45 / _skill_speed()
	_attack_reach = Skills.crescent_radius(level) * stats.area_multiplier()
	_attack_arc = deg_to_rad(Skills.CRESCENT_ARC_DEGREES)
	_attack_multiplier = Skills.CRESCENT_DAMAGE * combo_damage()
	_swing_sign = -_swing_sign
	pivot.rotation = _attack_angle
	sword.visible = sword.texture != null
	sword.flip_v = false
	slash.flip_v = _swing_sign < 0.0
	slash.scale = Vector2.ONE * (_attack_reach / 30.0)
	slash.frame = 0
	slash.visible = true
	_face_direction(aim)
	_attack_timer = _attack_length
	SkillEffects.crescent(get_parent(), body_center(), _attack_angle, _attack_arc / 2.0, _attack_reach)
	note_skill("crescent")
	Sfx.play("big_slash")
	_shake = maxf(_shake, 2.0)
	_update_attack(0.0)


## Strzała tropiąca w stronę kursora.
func _cast_seeker(level: int) -> void:
	var weapon := equipment.weapon()
	var dir := _aim_direction()
	_ranged_pose(dir)
	_attack_kind = weapon["type"]
	_attack_length = RANGED_POSE_TIME
	_attack_timer = _attack_length
	var arrow := SeekerArrow.new()
	arrow.position = position + dir * 6.0
	arrow.velocity = dir * SeekerArrow.SPEED
	arrow.hits_left = Skills.seeker_hits(level) + roundi(skills.tree_bonus("bow", "seeker_hits"))
	arrow.split = roundi(equipment.effect_power("seeker_split"))
	var kind := stats.kind_multiplier(["attack"])
	arrow.damage_min = maxi(1, roundi(stats.damage_min() * Skills.SEEKER_DAMAGE * kind))
	arrow.damage_max = maxi(1, roundi(stats.damage_max() * Skills.SEEKER_DAMAGE * kind))
	get_parent().add_child(arrow)
	Sfx.play("seeker")
	# Łuk Hydry: dodatkowe strzały tropiące rozchodzą się wachlarzem
	var extra := legendary.extra_seekers()
	for i in extra:
		var side := (i / 2 + 1) * (1 if i % 2 == 0 else -1)
		var more := SeekerArrow.new()
		more.position = arrow.position
		more.velocity = dir.rotated(side * 0.35) * SeekerArrow.SPEED
		more.hits_left = arrow.hits_left
		more.damage_min = arrow.damage_min
		more.damage_max = arrow.damage_max
		get_parent().add_child(more)


## Szybka salwa: seria strzał w stronę kursora, jedna po drugiej.
func _cast_volley(level: int) -> void:
	var count := Skills.volley_arrows(level)
	var tween := create_tween()
	for i in count:
		tween.tween_callback(_volley_arrow)
		tween.tween_interval(0.07 / _skill_speed())


func _volley_arrow() -> void:
	if is_dead or stats.weapon_type() != "bow":
		return
	var weapon := equipment.weapon()
	var dir := _aim_direction().rotated(randf_range(-0.06, 0.06))
	_ranged_pose(dir)
	_attack_kind = weapon["type"]
	_attack_length = RANGED_POSE_TIME
	_attack_timer = _attack_length
	var arrow := _make_projectile(weapon, dir)
	arrow.damage_min = maxi(1, roundi(arrow.damage_min * Skills.VOLLEY_DAMAGE))
	arrow.damage_max = maxi(1, roundi(arrow.damage_max * Skills.VOLLEY_DAMAGE))
	arrow.speed *= 1.25
	get_parent().add_child(arrow)
	Sfx.play("bow", -2.0, randf_range(1.0, 1.15))


## Łańcuch błyskawic: pierwszy cel najbliżej kursora, potem przeskok do najbliższego
## jeszcze nietrafionego wroga - błyskawicznie, jeden po drugim.
func _cast_chain(level: int) -> void:
	var dir := _aim_direction()
	_ranged_pose(dir)
	_attack_kind = "spell"
	_attack_length = RANGED_POSE_TIME
	_attack_timer = _attack_length
	var aim_point := get_global_mouse_position()
	var origin := body_center()
	var targets: Array[Goblin] = []
	var first: Goblin = null
	var best := INF
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(origin) > CHAIN_FIRST_RANGE:
			continue
		var d := enemy.hurt_center().distance_to(aim_point)
		if d < best:
			best = d
			first = enemy
	if first == null:
		# nikogo w zasięgu - błyskawica strzela w powietrze
		SkillEffects.bolt(get_parent(), origin, origin + dir * 90.0)
		Sfx.play("zap")
		return
	targets.append(first)
	while targets.size() < Skills.chain_targets(level) + roundi(skills.tree_bonus("spell", "chain_targets")):
		var last := targets[-1]
		var next: Goblin = null
		var nearest := CHAIN_JUMP_RANGE
		for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
			if enemy in targets:
				continue
			var d := enemy.hurt_center().distance_to(last.hurt_center())
			if d < nearest:
				nearest = d
				next = enemy
		if next == null:
			break
		targets.append(next)
	var tween := create_tween()
	var from := origin
	var multiplier := Skills.CHAIN_DAMAGE
	for target in targets:
		tween.tween_callback(_zap.bind(from, target, multiplier))
		tween.tween_interval(0.06 / _skill_speed(["spell"]))
		from = target.hurt_center()
		multiplier *= Skills.CHAIN_FALLOFF


func _zap(from: Vector2, target: Goblin, multiplier: float) -> void:
	if not is_instance_valid(target) or target.state == Goblin.State.DEAD:
		return
	var to := target.hurt_center()
	SkillEffects.bolt(get_parent(), from, to)
	Sfx.play("zap")
	hit_enemy(target, _skill_damage(multiplier, ["spell"]), from, 40.0)


## Fala piorunów: szeroki stożek błyskawic przed postacią.
func _cast_wave(level: int) -> void:
	var dir := _aim_direction()
	_ranged_pose(dir)
	_attack_kind = "spell"
	_attack_length = RANGED_POSE_TIME
	_attack_timer = _attack_length
	var origin := body_center()
	var half := deg_to_rad(Skills.wave_half_angle(level))
	var radius := Skills.wave_radius(level) * stats.area_multiplier()
	SkillEffects.cone(get_parent(), origin, dir.angle(), half, radius)
	for i in 7:  # pioruny rozchodzące się po stożku
		var angle := dir.angle() + lerpf(-half, half, (i + randf_range(-0.3, 0.3)) / 6.0)
		SkillEffects.bolt(get_parent(), origin, origin + Vector2.from_angle(angle) * radius * randf_range(0.7, 1.0), 0.35, 9.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > radius + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(dir.angle(), to_enemy.angle())) > half:
			continue
		SkillEffects.bolt(get_parent(), origin, enemy.hurt_center(), 0.3, 7.0)
		hit_enemy(enemy, _skill_damage(Skills.WAVE_DAMAGE, ["spell"]), global_position, 140.0)
	Sfx.play("thunder")
	_shake = maxf(_shake, 4.0)


# ---------------------------------------------------------------- śmierć i respawn
func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	_move_velocity = Vector2.ZERO
	_attack_timer = 0.0
	_attack_held = false
	_skill_held = false
	_held_slots.fill(false)
	_held_ids.clear()
	if sword_skills != null:
		sword_skills.cancel()
		bow_skills.cancel()
		spell_skills.cancel()
	_lunge_time = 0.0
	_combo_window = 0.0
	_stop_whirl()
	if is_charging_fireball():
		_stop_fireball_charge()
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", PI / 2.0, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 1.0).set_delay(0.5)
	Sfx.play("death")
	died.emit()
	# timer zatrzymuje się podczas pauzy
	await get_tree().create_timer(respawn_delay, false).timeout
	_respawn()


func _respawn() -> void:
	global_position = spawn_point
	reset_physics_interpolation()
	health = stats.max_health()
	mana = stats.max_mana()
	is_dead = false
	_knockback = Vector2.ZERO
	_dash_timer = 0.0
	_face_direction(Vector2.DOWN)
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	_poison_time = 0.0
	_slow_time = 0.0
	_slow_factor = 1.0
	_invulnerable_timer = respawn_invulnerability
	camera.reset_smoothing()
	_emit_resources()
	respawned.emit()


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_timer <= 0.0:
		return
	_invulnerable_timer -= delta
	# miganie podczas nietykalności
	sprite.visible = _invulnerable_timer <= 0.0 or fmod(_invulnerable_timer, 0.12) > 0.05


func _flash(color: Color) -> void:
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash", 0.8)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 0.8, 0.0, 0.25)


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, 20.0 * delta)
	var strength := _shake * Game.screen_shake
	camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))


# ---------------------------------------------------------------- ruch i animacja
## Skok w kierunku `dir` trwający `time` s (Odskok łuku) - jak zryw, ale bez zużycia jego odnowienia.
func leap(dir: Vector2, time: float) -> void:
	_cancel_attack()
	_dash_dir = dir.normalized() if dir != Vector2.ZERO else -_facing_vector()
	_dash_timer = time
	_dash_from = global_position
	_ghost_timer = 0.0
	_invulnerable_timer = maxf(_invulnerable_timer, time)
	Sfx.play("dash")


func _start_dash(input: Vector2) -> void:
	_dash_dir = (input if input != Vector2.ZERO else _facing_vector()).normalized()
	_dash_timer = dash_duration
	_dash_from = global_position
	_dash_cooldown_timer = dash_cooldown
	_ghost_timer = 0.0
	Sfx.play("dash")


func _facing_vector() -> Vector2:
	return facing_dir


func _update_facing(input: Vector2) -> void:
	if input != Vector2.ZERO:
		_face_direction(input)


## Patrzenie w jednym z 8 kierunków (kąt zaokrąglony do 45 stopni).
func _face_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var octant := posmod(roundi(dir.angle() / (PI / 4.0)), 8)
	facing_dir = Vector2.from_angle(octant * PI / 4.0)
	_dir_row = OCTANT_DIRS[octant][0]
	sprite.flip_h = OCTANT_DIRS[octant][1]


## Wybór postaci (z menu nowej gry albo z zapisu).
func set_hero(id: String) -> void:
	hero = id if id in HeroRig.HEROES else HeroRig.HEROES[0]
	sprite.texture = HeroRig.sheet(hero)
	sprite.hframes = HeroRig.FRAMES
	sprite.vframes = HeroRig.ANIMS.size() * HeroRig.DIRS
	sprite.offset = Vector2(0, HeroRig.CELL / 2.0 - HeroRig.FEET_Y)


## Klatka animacji: spoczynek, chód, zamach (broń biała, narzędzia, młynek, szarża),
## czar (księga, kula ognia) albo strzał z łuku - a broń w dłoni podąża za ręką.
func _update_animation(delta: float) -> void:
	var anim := "idle"
	var frame := 0
	if _whirling:
		anim = "slash"
		frame = int(Time.get_ticks_msec() / 70) % HeroRig.FRAMES
	elif _lunge_time > 0.0:
		anim = "slash"
		frame = HeroRig.FRAMES - 1
	elif is_charging_fireball():
		anim = "cast"
		frame = 1
	elif _harvest_target != null:
		anim = "slash"
		frame = clampi(int((1.0 - _harvest_hit / HARVEST_HIT_INTERVAL) * HeroRig.FRAMES), 0, HeroRig.FRAMES - 1)
	elif is_attacking():
		anim = ATTACK_ANIMS.get(_attack_kind, "slash")
		var progress := 1.0 - _attack_timer / maxf(_attack_length, 0.001)
		frame = clampi(int(progress * HeroRig.FRAMES), 0, HeroRig.FRAMES - 1)
	elif velocity.length() > 10.0:
		anim = "walk"
		_anim_time += delta * WALK_FPS * clampf(velocity.length() / max_speed, 0.5, 1.5)
		frame = int(_anim_time) % HeroRig.FRAMES
	else:
		_anim_time = 0.0
	sprite.frame = HeroRig.frame_index(anim, _dir_row, frame)
	_update_held_weapon(anim, frame)
	_update_silhouette(delta)


## Broń w dłoni poza atakiem: chwyt i kąt z danych postaci (HeroRig), odbite dla kierunków
## zachodnich. W trakcie ataku broń kręci się wokół barku jak dotąd (pivot/sword).
func _update_held_weapon(anim: String, frame: int) -> void:
	var swinging := _whirling or _lunge_time > 0.0 or is_charging_fireball() or _harvest_target != null or is_attacking()
	var weapon := equipment.weapon()
	# broń z PixelLab ma gęstszy piksel niż świat (held_scale 0,5); narzędzie do zbierania - zwykłą skalę
	var held_scale: float = weapon.get("held_scale", WEAPON_SCALE.get(weapon.get("type", "melee"), 1.0))
	sword.scale = Vector2.ONE * (1.0 if _harvest_target != null else held_scale)
	if swinging:
		pivot.position = BODY_OFFSET + facing_dir * 3.0
		pivot.z_index = 1
		_weapon_behind(false)
		if _harvest_target == null:
			sword.offset = _held_offset(weapon, sword.flip_v)
		return
	var held: Texture2D = weapon.get("held")
	var grip := HeroRig.grip(hero, anim, _dir_row, frame)
	if grip.is_empty():
		grip = HeroRig.grip(hero, "idle", _dir_row, 0)
	if held == null or grip.is_empty() or is_dead:
		sword.visible = false
		return
	var flip := sprite.flip_h
	var angle: float = grip[2]
	pivot.position = Vector2(-grip[0] if flip else grip[0], grip[1])
	pivot.rotation = (PI - angle) if flip else angle
	# księga zawsze grzbietem w górę, łuk, kostur i broń biała wzdłuż ręki
	var hold := _hold_of(weapon)
	if hold == "book":
		pivot.rotation = 0.0
	sword.rotation = 0.0
	sword.flip_v = flip and hold != "book"
	sword.texture = held
	# rękojeść (łęczysko, grzbiet księgi) w dłoni zamiast przy barku
	sword.offset = _held_offset(weapon, sword.flip_v)
	if not weapon.has("grip"):
		sword.offset -= Vector2(HELD_GRIP_SHIFT.get(weapon.get("type", ""), 4.0), 0)
	sword.visible = true
	# idąc "od kamery" (północ) postać zasłania broń
	pivot.z_index = 0
	_weapon_behind(facing_dir.y < -0.1)


## Broń za postacią (rysowana przed sprite'em) albo przed nią - kolejnością węzłów,
## bo ujemny z_index schowałby ją także pod ziemią.
func _weapon_behind(behind: bool) -> void:
	# przesunięcie na miejsce sprite'a wstawia broń przed nim albo (gdy była przed) tuż za nim
	if behind != (pivot.get_index() < sprite.get_index()):
		move_child(pivot, sprite.get_index())


## Półprzezroczysta kopia sprite'a zostawiana za graczem podczas zrywu.
func _spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.offset = sprite.offset
	ghost.position = position
	ghost.modulate = Color(0.6, 0.85, 1.0, 0.6)
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)
