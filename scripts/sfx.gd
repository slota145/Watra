extends Node
## Dźwięki gry (autoload "Sfx"): efekty z paczek CC0 od Kenney (assets/sfx), własne efekty
## z tools/sfx_synth.py (zaklinanie, kula ognia, kowadło, młotek, kukły, łuk), muzyka w tle
## z tools/music.py i tools/music_tracks.py (osobna do menu, osady, każdej krainy i walk z bossami - zmienia
## się płynnym przenikaniem, play_music) i odgłosy lasu z tools/ambient.py: co jakiś czas podmuch wiatru w koronach
## drzew i ptaki odzywające się losowo dookoła postaci (w budynkach ciszej).
## Sfx.play("hit") gra efekt bez położenia, Sfx.play_at("anvil", pozycja) - z położeniem
## (cichnie z odległością od kamery). Zdarzenie ma kilka wariantów i losową wysokość,
## żeby nie męczyło ucha, a zbyt częste powtórki (np. ciosy w tłum) są pomijane.
## Głośność muzyki, efektów i otoczenia zapisuje się w user://settings.cfg (osobno od zapisu gry).

const SFX_DIR := "res://assets/sfx/"
const MUSIC := {
	"menu": "res://assets/music/menu.ogg", "ostoja": "res://assets/music/ostoja_theme.ogg",
	"forest": "res://assets/music/forest.ogg", "swamp": "res://assets/music/swamp.ogg",
	"mountains": "res://assets/music/mountains.ogg", "ancient": "res://assets/music/ancient.ogg",
	"boss": "res://assets/music/boss.ogg",
}
const MUSIC_DB := -4.0
const MUSIC_FADE := 2.5
const SETTINGS_PATH := "user://settings.cfg"
const POOL_SIZE := 12
const POOL_2D_SIZE := 16
## Zasięg słyszenia dźwięków z położeniem (piksele świata).
const HEARING_DISTANCE := 420.0

## nazwa: [pliki, głośność (dB), rozrzut wysokości, minimalny odstęp między powtórkami (s)]
const SOUNDS := {
	# interfejs
	"ui_click": [["click_002"], -8.0, 0.05, 0.03],
	"ui_open": [["open_001"], -10.0, 0.03, 0.05],
	"ui_close": [["close_001"], -10.0, 0.03, 0.05],
	"ui_book": [["bookOpen", "bookFlip1"], -6.0, 0.05, 0.05],
	"ui_error": [["error_004"], -8.0, 0.0, 0.15],
	"ui_confirm": [["confirmation_002"], -8.0, 0.0, 0.05],
	"coins": [["handleCoins", "handleCoins2"], -6.0, 0.08, 0.06],
	"pickup": [["handleSmallLeather", "handleSmallLeather2"], -6.0, 0.1, 0.05],
	"pickup_rare": [["glass_002"], -6.0, 0.05, 0.1],
	"potion": [["glass_005"], -4.0, 0.05, 0.1],
	"deposit": [["dropLeather"], -4.0, 0.1, 0.05],
	# walka
	"swing": [["drawKnife1", "drawKnife2", "drawKnife3"], -10.0, 0.12, 0.05],
	"hit": [["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_002",
			"impactPunch_medium_003", "impactPunch_medium_004"], -8.0, 0.12, 0.04],
	"hit_heavy": [["impactPunch_heavy_000", "impactPunch_heavy_001", "impactPunch_heavy_002"], -5.0, 0.08, 0.08],
	"hurt": [["impactSoft_heavy_000", "impactSoft_heavy_001", "impactSoft_heavy_002"], -3.0, 0.08, 0.15],
	"enemy_die": [["impactSoft_medium_000", "impactSoft_medium_001", "impactSoft_medium_002"], -8.0, 0.15, 0.05],
	"bow": [["bow_shot_1", "bow_shot_2", "bow_shot_3"], -5.0, 0.06, 0.05],
	"magic": [["maximize_003"], -9.0, 0.1, 0.05],
	"explosion": [["explosion"], 0.0, 0.06, 0.08],
	"fireball_launch": [["fireball_launch"], -2.0, 0.0, 0.1],
	"fireball_full": [["fireball_full"], -2.0, 0.0, 0.3],
	"dash": [["cloth1", "cloth2", "cloth3", "cloth4"], -4.0, 0.1, 0.1],
	"whirl": [["drawKnife1", "drawKnife2", "drawKnife3"], -9.0, 0.1, 0.12],
	"big_slash": [["big_slash"], -3.0, 0.05, 0.1],
	"seeker": [["seeker_whistle"], -4.0, 0.04, 0.1],
	"zap": [["lightning_zap_1", "lightning_zap_2"], -7.0, 0.1, 0.04],
	"thunder": [["thunder"], -2.0, 0.04, 0.3],
	"legendary_drop": [["legendary_drop"], -2.0, 0.0, 1.0],
	"legendary_pickup": [["legendary_pickup"], -2.0, 0.0, 1.0],
	"shockwave": [["shockwave"], -3.0, 0.06, 0.12],
	"tide_wave": [["tide_wave"], -3.0, 0.06, 0.12],
	"stun": [["stun"], -10.0, 0.1, 0.15],
	"summon": [["summon"], -1.0, 0.0, 1.0],
	"craft": [["craft"], -4.0, 0.03, 0.2],
	"claw": [["claw"], -5.0, 0.1, 0.05],
	"eagle_cry": [["eagle_cry"], -6.0, 0.08, 1.5],
	"goat_bleat": [["goat_bleat"], -8.0, 0.1, 0.6],
	"birdman_screech": [["birdman_screech"], -5.0, 0.1, 0.4],
	"birdman_death": [["birdman_death"], -5.0, 0.1, 0.1],
	"storm_eagle_screech": [["storm_eagle_screech"], -1.0, 0.03, 1.0],
	"wing_gust": [["wing_gust"], -2.0, 0.05, 0.3],
	"drowner_emerge": [["drowner_emerge"], -4.0, 0.08, 0.15],
	"drowner_groan": [["drowner_groan"], -6.0, 0.1, 0.4],
	"wisp_charge": [["wisp_charge"], -6.0, 0.05, 0.2],
	"wisp_burst": [["wisp_burst"], -3.0, 0.08, 0.1],
	"rusalka_song": [["rusalka_song"], -8.0, 0.04, 2.0],
	"rusalka_death": [["rusalka_death"], -4.0, 0.05, 0.3],
	"wodnik_laugh": [["wodnik_laugh"], -1.0, 0.03, 1.0],
	"whirlpool": [["whirlpool"], -3.0, 0.05, 0.3],
	"treant_groan": [["treant_groan"], -5.0, 0.1, 0.6],
	"tree_rumble": [["tree_rumble"], -2.0, 0.05, 0.5],
	"roots_burst": [["roots_burst"], -3.0, 0.08, 0.1],
	"leshy_whisper": [["leshy_whisper"], -2.0, 0.04, 1.0],
	"spider_hiss": [["spider_hiss"], -8.0, 0.12, 0.4],
	"spider_death": [["spider_death"], -6.0, 0.12, 0.08],
	"queen_screech": [["queen_screech"], -3.0, 0.04, 1.0],
	"cocoon_burst": [["cocoon_burst"], -4.0, 0.1, 0.1],
	"bear_roar": [["bear_roar"], -3.0, 0.08, 1.0],
	"werewolf_howl": [["werewolf_howl"], -4.0, 0.06, 1.0],
	"bies_roar": [["bies_roar"], -1.0, 0.04, 1.0],
	"shroom_chime": [["shroom_chime"], -12.0, 0.1, 0.15],
	"telegraph": [["impactBell_heavy_000"], -10.0, 0.05, 0.3],
	"death": [["jingles_PIZZI01"], -6.0, 0.0, 1.0],
	# świat
	"step_grass": [["footstep_grass_000", "footstep_grass_001", "footstep_grass_002", "footstep_grass_003",
			"footstep_grass_004"], -18.0, 0.1, 0.1],
	"step_water": [["water_step_1", "water_step_2", "water_step_3"], -12.0, 0.1, 0.1],
	"step_wood": [["footstep_wood_000", "footstep_wood_001", "footstep_wood_002", "footstep_wood_003",
			"footstep_wood_004"], -16.0, 0.1, 0.1],
	"chop": [["impactWood_medium_000", "impactWood_medium_001", "impactWood_medium_002", "impactWood_medium_003",
			"impactWood_medium_004"], -5.0, 0.08, 0.1],
	"tree_fall": [["impactWood_heavy_000"], -2.0, 0.05, 0.2],
	"mine": [["impactMining_000", "impactMining_001", "impactMining_002", "impactMining_003",
			"impactMining_004"], -5.0, 0.08, 0.1],
	"rock_break": [["impactPlate_heavy_000"], -3.0, 0.05, 0.2],
	"anvil": [["anvil_1", "anvil_2", "anvil_3", "anvil_4"], -10.0, 0.04, 0.1],
	"hammer": [["wood_hammer_1", "wood_hammer_2", "wood_hammer_3", "wood_hammer_4"], -9.0, 0.08, 0.1],
	"dummy": [["dummy_hit_1", "dummy_hit_2", "dummy_hit_3", "dummy_hit_4"], -9.0, 0.08, 0.1],
	"door": [["doorOpen_1"], -12.0, 0.05, 0.3],
	# zwierzęta (słychać je tylko w pobliżu)
	"deer_grunt": [["deer_grunt"], -8.0, 0.08, 0.5],
	"roe_bark": [["roe_bark"], -6.0, 0.06, 0.8],
	"boar_grunt": [["boar_grunt_1", "boar_grunt_2"], -8.0, 0.1, 0.4],
	"boar_squeal": [["boar_squeal"], -6.0, 0.08, 0.6],
	"duck_quack": [["duck_quack_1", "duck_quack_2"], -8.0, 0.08, 0.3],
	"wing_flap": [["wing_flap"], -6.0, 0.1, 0.2],
	"crane_call": [["crane_call"], -4.0, 0.04, 2.0],
	"dragonfly": [["dragonfly"], -16.0, 0.15, 0.6],
	"frogman_croak": [["frogman_croak_1", "frogman_croak_2"], -6.0, 0.1, 0.4],
	"frog_attack": [["frog_attack"], -6.0, 0.1, 0.1],
	"frog_death": [["frog_death"], -5.0, 0.1, 0.1],
	"spit": [["spit"], -6.0, 0.1, 0.1],
	"spit_hit": [["spit_hit"], -6.0, 0.1, 0.1],
	"frog_boss_roar": [["frog_boss_roar"], -2.0, 0.03, 1.0],
	"tongue_lash": [["tongue_lash"], -3.0, 0.03, 0.3],
	"boss_splash": [["boss_splash"], -1.0, 0.03, 0.3],
	"fish_splash": [["water_step_1", "water_step_2", "water_step_3"], -10.0, 0.15, 0.3],
	"door_close": [["doorClose_1"], -14.0, 0.05, 0.3],
	"rest": [["creak1"], -4.0, 0.0, 0.5],
	# zaklinanie i nagrody
	"enchant_tick": [["tick_001"], -10.0, 0.0, 0.02],
	"enchant_success": [["enchant_strike"], -1.0, 0.03, 0.05],
	"enchant_fail": [["error_006"], -6.0, 0.0, 0.05],
	"enchant_fanfare": [["jingles_PIZZI15"], -4.0, 0.0, 0.3],
	"enchant_drop": [["jingles_PIZZI05"], -5.0, 0.0, 0.3],
	"level_up": [["jingles_PIZZI16"], -3.0, 0.0, 0.5],
	"quest_ready": [["jingles_PIZZI04"], -4.0, 0.0, 0.5],
	"quest_done": [["jingles_PIZZI10"], -3.0, 0.0, 0.5],
	"barracks": [["jingles_PIZZI02"], -2.0, 0.0, 1.0],
}

## Ptaki: plik i jak często się odzywa (waga losowania) - kukułka, dzięcioł i gołąb rzadziej.
const BIRDS := {"bird_sparrow": 3, "bird_finch": 3, "bird_blackbird": 3, "bird_tit": 3,
		"bird_cuckoo": 1, "bird_woodpecker": 1, "bird_dove": 1, "bird_loon": 1, "bird_loon_laugh": 1,
		"deer_roar_1": 1, "deer_roar_2": 1}
## Dodatkowe głosy w rozlewiskach: żaby rechoczą często, gawie odzywają się częściej niż w lesie.
const SWAMP_CALLS := {"frog_croak": 6, "frog_tree": 4, "bird_loon": 2, "bird_loon_laugh": 2}
## W górach mniej śpiewających ptaków, za to orły i kozy.
const MOUNTAIN_CALLS := {"bird_sparrow": 1, "bird_finch": 1, "bird_blackbird": 0, "bird_tit": 1, "bird_cuckoo": 1,
		"bird_woodpecker": 0, "bird_dove": 0, "bird_loon": 0, "bird_loon_laugh": 0, "deer_roar_1": 0, "deer_roar_2": 0,
		"eagle_cry": 3, "goat_bleat": 2}
## Podmuchy wiatru: ile wariantów i co ile sekund (losowo) przychodzi następny.
const GUSTS := 5
const GUST_INTERVAL := Vector2(10.0, 30.0)
## O ile ciszej jest las, gdy postać stoi w budynku.
const INDOORS_DB := -14.0
var _gust_scale := 1.0

var master_volume := 1.0
var music_volume := 0.6
var sfx_volume := 0.8
var ambient_volume := 0.7

var _streams := {}
var _last_played := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _next := 0
var _next_2d := 0
## Dwa odtwarzacze muzyki na zmianę - stary utwór gaśnie, nowy narasta.
var _music_players: Array[AudioStreamPlayer] = []
var _music_track := ""
var _music_streams := {}
var _wind: AudioStreamPlayer
var _gust_timer := 0.0
var _gust_db := -10.0
var _bird_players: Array[AudioStreamPlayer2D] = []
var _ambient_on := false
## Głosy otoczenia bieżącej krainy (plik -> waga losowania).
var _calls := BIRDS
var _bird_timer := 3.0
var _indoors_check := 0.0
var _indoors := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # dźwięki interfejsu także w pauzie
	_make_bus("Music")
	_make_bus("SFX")
	_make_bus("Ambient")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	for i in POOL_2D_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX"
		player.max_distance = HEARING_DISTANCE
		player.attenuation = 1.6
		add_child(player)
		_pool_2d.append(player)
	for i in 2:
		var music := AudioStreamPlayer.new()
		music.bus = "Music"
		add_child(music)
		_music_players.append(music)
	_wind = AudioStreamPlayer.new()
	_wind.bus = "Ambient"
	add_child(_wind)
	for i in 3:
		var bird := AudioStreamPlayer2D.new()
		bird.bus = "Ambient"
		bird.max_distance = 900.0
		bird.attenuation = 1.0
		add_child(bird)
		_bird_players.append(bird)
	_load_settings()
	# każdy przycisk w grze klika
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind("ui_click", 0.0, 1.0))


## Efekt bez położenia (interfejs, gracz). `volume` - dodatkowe dB.
func play(sound: String, volume := 0.0, pitch := 1.0) -> void:
	var stream := _pick(sound)
	if stream == null:
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	_setup(player, sound, stream, volume, pitch)
	player.play()


## Efekt w świecie (pozycja w pikselach) - słychać go tylko w pobliżu.
func play_at(sound: String, at: Vector2, volume := 0.0) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.get_screen_center_position().distance_to(at) > HEARING_DISTANCE:
		return
	var stream := _pick(sound)
	if stream == null:
		return
	var player := _pool_2d[_next_2d]
	_next_2d = (_next_2d + 1) % _pool_2d.size()
	_setup(player, sound, stream, volume, 1.0)
	player.global_position = at
	player.play()


## Las w tle - włączany w świecie gry, wyłączany w menu.
## Otoczenie zależy od krainy - w rozlewiskach dochodzą żaby.
func set_ambient_zone(zone: String) -> void:
	_calls = BIRDS.duplicate()
	if zone == "swamp":
		_calls.merge(SWAMP_CALLS, true)
	elif zone == "mountains":
		_calls.merge(MOUNTAIN_CALLS, true)
	# w górach wieje częściej
	_gust_scale = 0.5 if zone == "mountains" else 1.0


func start_ambient() -> void:
	_ambient_on = true
	_bird_timer = randf_range(1.0, 3.0)
	_gust_timer = randf_range(3.0, 8.0)


func stop_ambient() -> void:
	_ambient_on = false
	_wind.stop()
	for bird in _bird_players:
		bird.stop()


func _process(delta: float) -> void:
	if not _ambient_on:
		return
	# w budynku las cichnie
	_indoors_check -= delta
	if _indoors_check <= 0.0:
		_indoors_check = 0.4
		_indoors = false
		for building: Node in get_tree().get_nodes_in_group("buildings"):
			if building.is_player_inside():
				_indoors = true
				break
	var target_db := _gust_db + (INDOORS_DB if _indoors else 0.0)
	_wind.volume_db = move_toward(_wind.volume_db, target_db, 20.0 * delta)
	if get_tree().paused:
		return
	# co jakiś czas wiatr podrywa się w koronach drzew i po chwili cichnie
	_gust_timer -= delta
	if _gust_timer <= 0.0 and not _wind.playing:
		_gust_timer = randf_range(GUST_INTERVAL.x, GUST_INTERVAL.y) * _gust_scale
		var file := "gust_%d" % (randi() % GUSTS + 1)
		if not _streams.has(file):
			_streams[file] = load(SFX_DIR + file + ".ogg")
		_wind.stream = _streams[file]
		_gust_db = randf_range(-14.0, -7.0)
		_wind.volume_db = _gust_db + (INDOORS_DB if _indoors else 0.0)
		_wind.pitch_scale = randf_range(0.92, 1.06)
		_wind.play()
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = randf_range(2.5, 8.0)
		_play_bird()


## Losowy ptak gdzieś między drzewami wokół kamery.
func _play_bird() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var total := 0
	for weight: int in _calls.values():
		total += weight
	var roll := randi() % total
	var file := ""
	for name: String in _calls:
		roll -= _calls[name]
		if roll < 0:
			file = name
			break
	if not _streams.has(file):
		_streams[file] = load(SFX_DIR + file + ".ogg")
	var player: AudioStreamPlayer2D = null
	for bird in _bird_players:
		if not bird.playing:
			player = bird
			break
	if player == null:
		return
	player.stream = _streams[file]
	player.volume_db = randf_range(-14.0, -6.0) + (INDOORS_DB if _indoors else 0.0)
	player.pitch_scale = randf_range(0.95, 1.05)
	player.global_position = camera.get_screen_center_position() + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 380.0)
	player.play()


func set_ambient_volume(value: float) -> void:
	ambient_volume = clampf(value, 0.0, 1.0)
	_apply_volume("Ambient", ambient_volume)
	_save_settings()


## Przełącza muzykę na utwór `track` (klucz MUSIC) z przenikaniem; ten sam utwór gra dalej bez przerwy.
func play_music(track: String, fade := MUSIC_FADE) -> void:
	if track == _music_track or not MUSIC.has(track):
		return
	_music_track = track
	if not _music_streams.has(track):
		var stream: AudioStreamOggVorbis = load(MUSIC[track]).duplicate()
		stream.loop = true
		_music_streams[track] = stream
	var old := _music_players[0]
	var new := _music_players[1]
	_music_players.reverse()
	new.stream = _music_streams[track]
	new.volume_db = -40.0
	new.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(new, "volume_db", MUSIC_DB, fade).set_trans(Tween.TRANS_SINE)
	if old.playing:
		tween.tween_property(old, "volume_db", -40.0, fade).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(old.stop)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume("Master", master_volume)
	_save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volume("Music", music_volume)
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volume("SFX", sfx_volume)
	_save_settings()


## Losowy wariant dźwięku; null, jeśli ten sam efekt grał przed chwilą.
func _pick(sound: String) -> AudioStream:
	var data: Array = SOUNDS.get(sound, [])
	if data.is_empty():
		push_warning("Nieznany dźwięk: " + sound)
		return null
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -10.0)) < data[3]:
		return null
	_last_played[sound] = now
	var file: String = data[0].pick_random()
	if not _streams.has(file):
		_streams[file] = load(SFX_DIR + file + ".ogg")
	return _streams[file]


func _setup(player: Node, sound: String, stream: AudioStream, volume: float, pitch: float) -> void:
	var data: Array = SOUNDS[sound]
	player.stream = stream
	player.volume_db = data[1] + volume
	player.pitch_scale = pitch * (1.0 + randf_range(-data[2], data[2]))


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _apply_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
		ambient_volume = clampf(float(config.get_value("audio", "ambient", ambient_volume)), 0.0, 1.0)
		master_volume = clampf(float(config.get_value("audio", "master", master_volume)), 0.0, 1.0)
	_apply_volume("Master", master_volume)
	_apply_volume("Music", music_volume)
	_apply_volume("SFX", sfx_volume)
	_apply_volume("Ambient", ambient_volume)


func _save_settings() -> void:
	# ustawienia obrazu (Game) leżą w tym samym pliku - wczytujemy, żeby ich nie skasować
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "ambient", ambient_volume)
	config.save(SETTINGS_PATH)
