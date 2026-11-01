class_name Boss
extends Goblin
## Wspólna logika bossów: czeka w swoim leżu, a gdy gracz podejdzie, walczy -
## goni go i co chwilę wykonuje atak specjalny. Każdy atak najpierw pokazuje
## czerwoną poświatę na ziemi (Telegraph) i animację zamachu, dopiero potem uderza.
## Bossa nie da się przerwać ani odepchnąć ciosem. Po ucieczce gracza wraca i się leczy.
## Podklasy wybierają atak (_choose_attack) i prowadzą go etapami (_update_attack).

@export var boss_name := ""
## Przerwa między atakami specjalnymi (s).
@export var attack_interval := 1.6
## Na ile monet rozsypuje się złoto (każda warta gold_min-gold_max).
@export var gold_coins := 8
## Unikalne, legendarne przedmioty bossa - każdy losowany osobno i naprawdę rzadko
## (w trybie deweloperskim wypadają zawsze, razem z całą resztą łupu).
@export var legendary_drops: PackedStringArray = []
@export_range(0.0, 1.0) var legendary_drop_chance := 0.02

## Bieżący atak specjalny ("" = brak) i jego etap: telegraph / act / recover.
var _attack := ""
var _attack_stage := ""
var _stage_timer := 0.0
var _special_cooldown := 1.2
var _telegraph: Telegraph
## Gracz obrywa tylko raz na jeden atak.
var _hit_player := false
## Jak długo boss wraca do leża - po RETURN_TIMEOUT s (np. zablokowany o drzewo) przenosi się do niego.
var _return_time := 0.0
## Rozwścieczony boss (np. polowanie na bossa w wydarzeniu) - stała aura wściekłości.
var enraged := false
## Zapętlona aura wściekłości (podklasa może podać własne klatki w aura_texture / aura_frames / aura_anchor).
var aura_texture: Texture2D = FX_ENRAGE
var aura_frames := 8
var aura_anchor := Vector2(31, 80)
var _aura: Sprite2D
var _aura_time := 0.0

## Wspólne efekty bossów z kreatora efektów PixelLab (tools/vfx_art.py): ryk z falą przy wejściu do walki, wybuch
## z duszami przy śmierci, wybuch mocy przy zmianie fazy i zapętlona aura wściekłości. Podklasy mogą podmienić każdy
## z nich (_fx_engage / _fx_death / _fx_phase / aura_texture), np. wynurzenie się z wody zamiast ryku.
const FX_ENGAGE := preload("res://assets/effects/boss_appear.png")
const FX_DEATH := preload("res://assets/effects/boss_death.png")
const FX_PHASE := preload("res://assets/effects/boss_phase.png")
const FX_ENRAGE := preload("res://assets/effects/boss_enrage.png")
## Poniżej tej części zdrowia (w walce) boss pokazuje aurę wściekłości (tylko wygląd).
const ENRAGE_HEALTH := 0.3

const RETURN_TIMEOUT := 6.0
## Ogłuszenie trwa u bossa tylko tyle (część pełnego czasu).
const STUN_RESISTANCE := 0.4


func _ready() -> void:
	super()
	add_to_group("bosses")
	hurt_radius = 13.0


func is_engaged() -> bool:
	return state == State.CHASE


## Wejście do walki: efekt pojawienia się (raz na każde podejście gracza).
func aggro() -> void:
	var was_idle := state == State.IDLE
	super()
	if was_idle and state == State.CHASE:
		_fx_engage()


## Skala wspólnych efektów - z wysokości klatki bossa (około 64 px = 1).
func fx_scale() -> float:
	if sprite == null or sprite.texture == null:
		return 1.0
	var height := sprite.texture.get_height() / float(maxi(sprite.vframes, 1)) * absf(sprite.scale.y)
	return clampf(height / 64.0, 0.8, 2.5)


## Ryk z falą i pyłem przy wejściu do walki (podklasy mogą podmienić).
func _fx_engage() -> void:
	SkillEffects.sheet_once(get_parent(), FX_ENGAGE, 11, 18.0, global_position, Vector2(72, 58), 0.0, 1.0, fx_scale())


## Wybuch, dym, odłamki i unoszące się dusze przy śmierci (podklasy mogą podmienić).
func _fx_death() -> void:
	SkillEffects.sheet_once(get_parent(), FX_DEATH, 15, 16.0, global_position, Vector2(63, 88), 0.0, 1.0, fx_scale())


## Wybuch mocy przy zmianie fazy walki (wołane przez bossów z fazami; podklasy mogą podmienić).
func _fx_phase() -> void:
	SkillEffects.sheet_once(get_parent(), FX_PHASE, 12, 16.0, global_position, Vector2(65, 76), 0.0, 1.0, fx_scale())


## Aura wściekłości za bossem: rozwścieczony albo w walce poniżej ENRAGE_HEALTH zdrowia.
func _update_aura(delta: float) -> void:
	var show := state != State.DEAD and (enraged or (is_engaged() and health < max_health * ENRAGE_HEALTH))
	if not show:
		if _aura != null:
			_aura.visible = false
		return
	if _aura == null:
		_aura = Sprite2D.new()
		_aura.texture = aura_texture
		_aura.hframes = aura_frames
		_aura.centered = false
		_aura.offset = -aura_anchor
		_aura.scale = Vector2.ONE * fx_scale()
		add_child(_aura)
		move_child(_aura, sprite.get_index())
	_aura.visible = true
	_aura_time += delta
	_aura.frame = int(_aura_time * 12.0) % aura_frames


func _die() -> void:
	_fx_death()
	if _aura != null:
		_aura.visible = false
	super()


## Bossa nie odpycha cios i nie przerywa jego ataku.
func take_damage(amount: int, _from_position: Vector2, _knockback := 0.0) -> void:
	if state == State.DEAD:
		return
	health -= amount
	DamageNumber.spawn(get_parent(), hurt_center(), amount)
	_flash()
	if health <= 0:
		_cancel_attack()
		_die()
		return
	aggro()


func _physics_process(delta: float) -> void:
	_update_aura(delta)
	if state == State.DEAD or _process_stun(delta):
		return
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if _player_alive() and not _player_is_safe() and global_position.distance_to(_player.global_position) < aggro_radius:
				aggro()
		State.RETURN:
			_cancel_attack()
			_return_time += delta
			if position.distance_to(home) < 4.0 or _return_time > RETURN_TIMEOUT:
				if position.distance_to(home) >= 4.0:
					position = home
					reset_physics_interpolation()
					appear()
				state = State.IDLE
				health = max_health
				velocity = Vector2.ZERO
				_return_time = 0.0
			else:
				velocity = position.direction_to(home) * speed
		_:
			_process_fight(delta)
	move_and_slide()
	_animate(delta)


func _process_fight(delta: float) -> void:
	if not _player_alive() or _player_is_safe() or position.distance_to(home) > leash_radius:
		_cancel_attack()
		state = State.RETURN
		return
	if _attack != "":
		_stage_timer -= delta
		_update_attack(delta)
		return
	_special_cooldown -= delta
	var to_player := _player.global_position - global_position
	if _special_cooldown <= 0.0 and _choose_attack(to_player):
		return
	velocity = _toward_player(to_player) * speed if to_player.length() > 28.0 else Vector2.ZERO


# ---------------------------------------------------------------- do nadpisania
## Wybiera i zaczyna atak specjalny; false, jeśli żaden nie pasuje do odległości.
func _choose_attack(_to_player: Vector2) -> bool:
	return false


func _update_attack(_delta: float) -> void:
	pass


# ---------------------------------------------------------------- pomocnicze dla ataków
func _start_attack(attack: String, telegraph_time: float) -> void:
	_attack = attack
	_hit_player = false
	velocity = Vector2.ZERO
	_set_stage("telegraph", telegraph_time)


func _set_stage(stage: String, time: float) -> void:
	_attack_stage = stage
	_stage_timer = time


func _end_attack() -> void:
	_attack = ""
	_attack_stage = ""
	_special_cooldown = attack_interval
	_remove_telegraph()


## Ogłuszenie przerywa atak specjalny (znika poświata ostrzegawcza).
func _on_stunned() -> void:
	_cancel_attack()
	_special_cooldown = maxf(_special_cooldown, 0.6)


func _cancel_attack() -> void:
	_attack = ""
	_attack_stage = ""
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE
	sprite.self_modulate = Color.WHITE
	_remove_telegraph()


## Czerwona poświata na ziemi (pod postaciami) w kształcie ataku.
func _show_telegraph(shape: Telegraph.Shape, pos: Vector2, angle: float, duration: float) -> Telegraph:
	Sfx.play_at("telegraph", pos)
	_remove_telegraph()
	var telegraph := Telegraph.new()
	telegraph.shape = shape
	telegraph.duration = duration
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = pos
	telegraph.rotation = angle
	_telegraph = telegraph
	return telegraph


func _remove_telegraph() -> void:
	if is_instance_valid(_telegraph):
		var fading := _telegraph
		fading.set_process(false)
		var tween := fading.create_tween()
		tween.tween_property(fading, "modulate:a", 0.0, 0.15)
		tween.tween_callback(fading.queue_free)
	_telegraph = null


## Czy gracz stoi w obszarze bieżącej poświaty.
func _player_in_telegraph() -> bool:
	return is_instance_valid(_telegraph) and _player_alive() and _telegraph.contains(_player.global_position)


func _hurt_player(amount: int, push := 0.0) -> void:
	if _hit_player or not _player_alive():
		return
	_hit_player = true
	_player.take_damage(amount, global_position)
	if push > 0.0:
		_player._knockback = (_player.global_position - global_position).normalized() * push


func _shake_camera(strength: float) -> void:
	if _player != null and _player.global_position.distance_to(global_position) < 320.0:
		_player._shake = maxf(_player._shake, strength)


## Kurz, dym albo iskry rozbryzgujące się po uderzeniu (efekty z kreatora efektów PixelLab - MiscVfx,
## barwione kolorem `color`): kłąb w rozmiarze z siły `power`, przy jasnym kolorze także iskry.
func _burst(pos: Vector2, color: Color, amount: int, power: float) -> void:
	var size := clampf(power / 110.0, 0.4, 1.6) * (0.8 if amount < 10 else 1.0)
	MiscVfx.puff(get_parent(), pos, color, size)
	if color.get_luminance() > 0.5:
		MiscVfx.spark(get_parent(), pos, color, size * 1.2)


# ---------------------------------------------------------------- efekty ataków
## Pęknięcia ziemi pod uderzeniem - zostają chwilę na podłożu (pod postaciami) i gasną.
func _ground_crack(pos: Vector2, radius: float, life := 3.0) -> void:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	SkillEffects.ground_crack(layer if layer != null else get_parent(), pos, radius, life)


## Odłamki ziemi i kamieni podrzucone uderzeniem z punktu na ziemi (MiscVfx.debris w kolorze `color`).
func _debris(pos: Vector2, amount: int, power: float, color := Color(0.42, 0.33, 0.24)) -> void:
	MiscVfx.debris(get_parent(), pos, color.lightened(0.15), clampf(power / 150.0, 0.6, 1.6) * (0.8 if amount < 6 else 1.0))


## Powidok sylwetki w ruchu (skok, szarża) - przezroczysta kopia bieżącej klatki gasnąca w miejscu.
func _afterimage(tint := Color(1.0, 0.4, 0.3, 0.55)) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.offset = sprite.offset
	ghost.global_position = sprite.global_position
	ghost.modulate = tint
	ghost.z_index = 1
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ghost.queue_free)


## Przyczajenie przed atakiem: sylwetka przysiada (spłaszcza się) i czerwienieje, potem wyrzut.
func _wind_up(time: float, squash := Vector2(1.12, 0.88)) -> void:
	var tween := sprite.create_tween().set_parallel()
	tween.tween_property(sprite, "scale", squash, time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "self_modulate", Color(1.0, 0.8, 0.76), time)


## Moment uderzenia: rozciągnięcie w górę i powrót do normy, kolor wraca.
func _snap(stretch := Vector2(0.86, 1.18)) -> void:
	sprite.self_modulate = Color.WHITE
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", stretch, 0.06)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _face(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x


# ---------------------------------------------------------------- łup
## Dużo więcej wszystkiego: złoto w wielu monetach, trofea, przedmioty i legendy (kamienie zaklinające
## wypadają tylko w lochach Watry).
func _drop_loot() -> void:
	for i in gold_coins:
		_spawn_pickup("gold", randi_range(gold_min, gold_max))
	_drop_trophies()
	# dwa przedmioty z poziomu bossa: pierwszy co najmniej magiczny, drugi z dużą szansą na rzadki
	# (w trybie deweloperskim oba rzadkie)
	_spawn_pickup(Loot.drop_at_level(level, 0.1, Loot.RARE if _dev_mode() else Loot.MAGIC, 2), 1)
	_spawn_pickup(Loot.drop_at_level(level, 0.2, Loot.RARE if _dev_mode() else "", 2), 1)
	if Gems.unlocked:
		_spawn_pickup(Gems.roll("", mini(Gems.cut_for_level(level) + 1, Gems.CUTS.size() - 1)), 1)
	for id in legendary_drops:
		if _dev_mode() or randf() < legendary_drop_chance:
			_spawn_pickup(Loot.legendary_at_level(id, level), 1)


## Tryb deweloperski gwarantuje cały możliwy łup bossa.
func _dev_mode() -> bool:
	var hud := get_tree().get_first_node_in_group("hud")
	return hud != null and hud.dev_mode


## Łup typowy dla gatunku bossa (serca, skóry...).
func _drop_trophies() -> void:
	pass
