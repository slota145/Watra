class_name SwordSkills
extends Node
## Umiejętności drzewka miecza (SkillTree "melee") z własną obsługą - dziecko gracza, jak LegendaryEffects:
## - Mgnienie: dopóki trzymasz klawisz, postać przeskakuje na wylot przez najbliższego widocznego wroga (za każdym razem
##   innego, jeśli jest wybór) i tnie wszystkich na drodze (mana za każdy skok); jednego wroga przebija tam i z powrotem.
##   Combo z Młynkiem: Mgnienie w trakcie Młynka to wirujące Mgnienie - seria szybkich skoków od wroga do wroga
##   z odnowieniem; Amulet Wiecznego Wiru znosi odnowienie (skoki trwają, dopóki trzymasz klawisz).
## - Dymne Wybuchy: przytrzymanie ładuje (1-3 rzędy po 3 wybuchy dymu w stożku przed postacią), puszczenie odpala.
##   Combo: zaraz po innej umiejętności wszystkie 9 wybuchów od razu, bez ładowania. Atak i czar jednocześnie.
## - Rozpłatanie: szerokie cięcie z krwawieniem (po Mgnieniu podwójnym).
## - Rozłupanie Ziemi: fala pęknięć przed postacią, rani i ogłusza (po Półksiężycu - pierścień dookoła).
## - Riposta: krótka zasłona; cios w tym czasie nie rani, a postać kontratakuje wszystkich wokół (potem darmowa Szarża).
## - Zew Peruna: okrzyk - premia do obrażeń, strach wrogów wokół i 3 kolejne ciosy krytyczne.
## - Widmowe Ostrza (czar): krążące miecze raniące wrogów (po Młynku od razu wylatują we wrogów).
## - Wilczy Kieł: seria pchnięć w jednego wroga (najbliższego kursora), ostatnie mocniejsze i ogłusza.
## - Ryk Tura: okrzyk - wrogowie wokół rzucają się na postać, premia do pancerza.
## - Skok Niedźwiedzia: skok pod kursor ponad przeszkodami (Player.start_leap), lądowanie rani i odrzuca.
## Węzły Pełnia Sił i Gniew rannego oraz kluczowy Ostatni Bastion zmieniają obrażenia wg zdrowia
## (health_damage_factor, bastion_taken), Wstrząs ogłusza trafionych umiejętnościami obszarowymi miecza (tremor).
## Węzły kluczowe: Oko Cyklonu (Młynek wciąga i rozkręca się - `Player.whirl_spin_up`), Taniec Ostrzy
## (combo przyspiesza ataki), Dym i Cień (chmura po Dymnych Wybuchach: unik i darmowe Mgnienie), Krwawy Szał
## (krwawienie leczy). Chwilowe premie trafiają do CharacterStats.temp_bonus i na listę efektów (statuses).

var _smoke_tags: Array = Skills.tags("smoke_burst")
const SMOKE_COLOR := Color(0.78, 0.78, 0.82)
## Odstęp między rzędami wybuchów (s) i promień cięcia po skoku Mgnienia.
const SMOKE_RING_DELAY := 0.12
const FLICKER_HIT_RADIUS := 30.0
## Mgnienie na wylot: jak daleko za celem ląduje postać i jak szeroki jest pas cięcia wzdłuż drogi skoku.
const FLICKER_OVERSHOOT := 18.0
const FLICKER_PATH_WIDTH := 12.0
## Efekty Mgnienia z kreatora efektów PixelLab (tools/vfx_art.py): smuga za postacią (błysk w miejscu startu,
## rysowana w prawo, cienki ogon pogrubia się w stronę postaci i gaśnie od ogona; długość w klatce - FLICKER_TRAIL_LENGTH) i proste cięcie z błyskiem na trafionym celu.
const FLICKER_TRAIL := preload("res://assets/effects/flicker_trail.png")
const FLICKER_TRAIL_ANCHOR := Vector2(8, 10)
const FLICKER_TRAIL_LENGTH := 64.0
const FLICKER_SLASH := preload("res://assets/effects/flicker_hit.png")
const FLICKER_SLASH_ANCHOR := Vector2(43, 16)
## Cięcie na celu ukośnie do drogi skoku (losowo w jedną lub drugą stronę), żeby nie zlewało się ze smugą.
const FLICKER_SLASH_TILT := 0.6
## Wirujące Mgnienie: mocniejsza smuga (spirala ostrza, więcej linii pędu) i szybszy wir Młynka przez chwilę po skoku.
const FLICKER_SPIN_TRAIL := preload("res://assets/effects/flicker_spin_trail.png")
const FLICKER_SPIN_TRAIL_ANCHOR := Vector2(15, 13)
const FLICKER_SPIN_TRAIL_LENGTH := 70.0
const SPIN_FX_TIME := 0.35
## Dymny Wybuch z kreatora efektów PixelLab: klin dymu i smug buchający z punktu do przodu (rysowany w prawo).
## Podstawa klina (punkt zaczepienia) stoi z tyłu kręgu obrażeń; klin ma w klatce około 1,3 x SMOKE_FX_RADIUS długości,
## żeby kolejne rzędy (co około 38 px) nie zlewały się w jeden strumień.
const SMOKE_FX := preload("res://assets/effects/smoke_burst.png")
const SMOKE_FX_ANCHOR := Vector2(14, 26)
const SMOKE_FX_RADIUS := 32.0
## Kierunek wybuchu: kolejne rzędy na przemian odchylone o SMOKE_FX_ZIGZAG (rad) w lewo i w prawo, do tego mały losowy
## rozrzut - wybuchy kolejnych rzędów nie układają się w jedną linię.
const SMOKE_FX_ZIGZAG := 0.4
const SMOKE_FX_JITTER := 0.12
## Klin jest narysowany lekko pod górę (około 14 stopni) - obrót o tyle w drugą stronę kieruje go wzdłuż lotu.
const SMOKE_FX_LEAN := 0.25
## Rozpłatanie z kreatora efektów PixelLab: szeroki łuk stali z krwawym śladem i kroplami krwi (rysowany w prawo,
## punkt zaczepienia w środku tułowia - poza klatką, promień łuku REND_FX_RADIUS) i rozprysk krwi na zranionym wrogu.
const REND_FX := preload("res://assets/effects/rend.png")
const REND_FX_ANCHOR := Vector2(-7, 38)
const REND_FX_RADIUS := 36.0
const REND_WOUND_FX := preload("res://assets/effects/rend_wound.png")
const REND_WOUND_ANCHOR := Vector2(9, 12)
## Rozłupanie Ziemi z kreatora efektów PixelLab: erupcja kamiennych kolców, odłamków i pyłu (nieobracana, punkt
## zaczepienia na ziemi) w każdym kroku fali pęknięć - coraz większa; w combo erupcje w dwóch kręgach wokół postaci.
const SLAM_FX := preload("res://assets/effects/ground_slam.png")
const SLAM_FX_ANCHOR := Vector2(26, 35)
## Riposta z kreatora efektów PixelLab: zapętlona złota zasłona wokół tułowia (dwa krążące łuki ostrzy, błyski)
## i kontra - błysk zderzenia stali, pełne cięcie dookoła i fala (promień cięcia w klatce RIPOSTE_FX_RADIUS).
const RIPOSTE_GUARD_FX := preload("res://assets/effects/riposte_guard.png")
const RIPOSTE_COUNTER_FX := preload("res://assets/effects/riposte_counter.png")
const RIPOSTE_COUNTER_ANCHOR := Vector2(65, 47)
const RIPOSTE_FX_RADIUS := 56.0
## Zew Peruna z kreatora efektów PixelLab: złoty piorun uderza z nieba w postać, a po ziemi rozchodzi się fala
## z wyładowaniami (promień fali w klatce PERUN_FX_RADIUS, punkt zaczepienia pod stopami); w czasie premii wokół
## postaci trzaskają złote wyładowania (zapętlone klatki).
const PERUN_FX := preload("res://assets/effects/war_cry.png")
const PERUN_FX_ANCHOR := Vector2(115, 156)
const PERUN_FX_RADIUS := 110.0
const PERUN_BUFF_FX := preload("res://assets/effects/war_cry_buff.png")
const PERUN_BUFF_FRAMES := 12
const PERUN_BUFF_FPS := 12.0
const SPECTRAL_COLOR := Color(0.65, 0.85, 1.0)
## Taniec Ostrzy: premia za combo, ile razy się kumuluje i jak długo trwa; Dym i Cień: chmura; Krwawy Szał: leczenie.
const DANCE_STEP := 0.05
const DANCE_STACKS := 5
const DANCE_TIME := 4.0
const CLOUD_TIME := 5.0
const CLOUD_RADIUS := 70.0
## Wirujący krąg dymu u stóp w czasie ładowania Dymnych Wybuchów (skala efektu MiscVfx).
const SWIRL_SIZE := 0.4
const CLOUD_DODGE := 0.3
const FRENZY_LEECH := 0.3
## Ostatni Bastion: poniżej tej części zdrowia premia do obrażeń i mniej otrzymanych obrażeń.
const BASTION_HEALTH := 0.3
const BASTION_DAMAGE := 0.5
const BASTION_TAKEN := 0.5
## Efekty z kreatora efektów PixelLab (tools/vfx_art.py): pchnięcie Wilczego Kła (stalowa smuga rysowana w prawo
## z iskrą na końcu, długość w klatce FANG_FX_LENGTH), fala Ryku Tura (pomarańczowy pierścień z pyłem, promień
## w klatce ROAR_FX_RADIUS) i lądowanie Skoku Niedźwiedzia (pęknięcia, pył i odłamki, promień LEAP_FX_RADIUS).
const FANG_FX := preload("res://assets/effects/wolf_fang.png")
const FANG_FX_ANCHOR := Vector2(6, 12)
const FANG_FX_LENGTH := 56.0
const ROAR_FX := preload("res://assets/effects/bull_roar.png")
const ROAR_FX_ANCHOR := Vector2(85, 40)
const ROAR_FX_RADIUS := 81.0
const ROAR_FX_ALPHA := 0.7
const LEAP_FX := preload("res://assets/effects/bear_leap.png")
const LEAP_FX_ANCHOR := Vector2(49, 30)
const LEAP_FX_RADIUS := 46.0
const ROAR_COLOR := Color(0.95, 0.55, 0.3)
const ICONS := {
	"war_cry": preload("res://assets/skills/war_cry.png"), "blade_dance": preload("res://assets/skills/ks_blade_dance.png"),
	"smoke_shadow": preload("res://assets/skills/ks_smoke_shadow.png"), "riposte": preload("res://assets/skills/riposte.png"),
	"bull_roar": preload("res://assets/skills/bull_roar.png"), "last_bastion": preload("res://assets/skills/ks_last_bastion.png"),
}

var _player: Player
var _flicker_timer := 0.0
var _whirl_cooldown := 0.0
var _whirl_cooldown_total := 0.0
var _whirl_jumps_left := 0
## Ile jeszcze pokazywać szybki wir Młynka po skoku wirującego Mgnienia (s).
var _spin_fx_time := 0.0
var _whirl_jump_timer := 0.0
var _last_target: Goblin
## Ładowanie Dymnych Wybuchów: sekundy ładowania (-1 - nie ładujemy) i ostatni osiągnięty rząd (do błysku).
var _smoke_charge := -1.0
var _smoke_stage := 0
var _smoke_swirl: FxLoop
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
var _parry_time := 0.0
var _parry_ring: Node2D
var _cry_time := 0.0
## Pełny czas obecnego Zewu Peruna (dłuższy z Donośnym Głosem).
var _cry_total := Skills.CRY_TIME
## Trzaskające wyładowania wokół postaci w czasie premii Zewu Peruna.
var _cry_fx: Sprite2D
var _forced_crits := 0
var _dance_stacks := 0
var _dance_time := 0.0
## Chmura Dymu i Cienia: środek i ile jeszcze trwa.
var _cloud_at := Vector2.ZERO
var _cloud_time := 0.0
var _cloud_node: FxLoop
var _blades: SpectralBlades
## Ostatnio trafieni przez Mgnienie wrogowie (Riposta po Mgnieniu - kontra wybucha na nich).
var _flicker_marks: Array = []
## Kolce z pęknięć ostatniego Rozłupania Ziemi i ile jeszcze czekają (Szarża po Rozłupaniu - wybuchają).
var _spikes: Array[Vector2] = []
var _spikes_time := 0.0
## Ryk Tura: ile jeszcze trwa premia do pancerza.
var _roar_time := 0.0
## Wstrząs: wróg -> czas (ms), od którego może być znów ogłuszony.
var _tremor_ready := {}


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (trzymanie sprawdza Player.is_skill_held).
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return
	match id:
		"flicker":
			_press_flicker()
		"smoke_burst":
			_press_smoke()
		"crescent":
			if _cooldowns.get(id, [0.0])[0] <= 0.0 and _player.use_followup(id):
				_start_cooldown(id, Skills.CRESCENT_COOLDOWN)
		_:
			if _cooldowns.get(id, [0.0])[0] > 0.0:
				return
			var cost := _player.skill_mana(id)
			if not _player.spend_mana(cost):
				_player._hint(Lang.t("Za mało many"))
				return
			match id:
				"rend":
					_rend()
				"ground_slam":
					_ground_slam()
				"riposte":
					_riposte()
				"war_cry":
					_war_cry()
				"spectral_blades":
					_spectral_blades()
				"wolf_fang":
					_wolf_fang()
				"bull_roar":
					_bull_roar()
				"bear_leap":
					_bear_leap()


## Czy Młynek ma teraz pokazywać szybszy wir (seria skoków wirującego Mgnienia trwa).
func is_spin_flickering() -> bool:
	return _spin_fx_time > 0.0 or _whirl_jumps_left > 0


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_whirl_jumps_left = 0
	_spin_fx_time = 0.0
	_stop_smoke_charge()
	_parry_time = 0.0


func cooldown_of(id: String) -> Vector2:
	if id == "flicker":
		# odnowienie ma tylko wirujące Mgnienie - poza Młynkiem zwykłe Mgnienie jest gotowe (sama mana)
		if not _player.is_whirling():
			return Vector2.ZERO
		return Vector2(_whirl_cooldown, maxf(_whirl_cooldown_total, _whirl_cooldown))
	var entry: Array = _cooldowns.get(id, [0.0, 0.0])
	return Vector2(entry[0], maxf(entry[1], entry[0]))


func _start_cooldown(id: String, base: float) -> void:
	var time: float = _player._cooldown(base, Skills.tags(id))
	_cooldowns[id] = [time, time]


func _physics_process(delta: float) -> void:
	_whirl_cooldown = maxf(_whirl_cooldown - delta, 0.0)
	_spin_fx_time = maxf(_spin_fx_time - delta, 0.0)
	for id: String in _cooldowns:
		_cooldowns[id][0] = maxf(_cooldowns[id][0] - delta, 0.0)
	_process_timed(delta)
	if _player.is_dead:
		cancel()
		return
	_process_flicker(delta)
	_process_smoke(delta)


# ---------------------------------------------------------------- Mgnienie
func _press_flicker() -> void:
	if _player.is_whirling():
		if _endless_whirl():
			return
		if _whirl_cooldown > 0.0:
			_player._hint(Lang.t("Wirujące Mgnienie się odnawia"))
			return
		_whirl_jumps_left = Skills.whirl_flicker_jumps(_player.skills.level_of("flicker"))
		_whirl_jump_timer = 0.0
		_whirl_cooldown = Skills.WHIRL_FLICKER_COOLDOWN * _player.stats.cooldown_multiplier()
		_whirl_cooldown_total = _whirl_cooldown
		Sfx.play("whirl", 2.0, 1.3)
		return
	_flicker_timer = 0.0


func _endless_whirl() -> bool:
	return _player.equipment.effect_power("endless_whirl") > 0.0


func _process_flicker(delta: float) -> void:
	_flicker_timer -= delta
	_whirl_jump_timer -= delta
	var whirling := _player.is_whirling()
	var level := _player.skills.level_of("flicker")
	if level <= 0 or _player.stats.weapon_type() != "melee":
		_whirl_jumps_left = 0
		return
	# wirujące Mgnienie: seria skoków w trakcie Młynka (z Amuletem Wiecznego Wiru - dopóki trzymasz klawisz)
	var endless := whirling and _endless_whirl() and _player.is_skill_held("flicker")
	if whirling and (_whirl_jumps_left > 0 or endless):
		if _whirl_jump_timer <= 0.0:
			_whirl_jump_timer = maxf(Skills.WHIRL_FLICKER_INTERVAL / _player._skill_speed(Skills.tags("flicker")), Skills.WHIRL_FLICKER_MIN_INTERVAL)
			if _jump(Skills.FLICKER_RANGE * 1.2, level, true):
				_whirl_jumps_left -= 1
				_player.note_skill("flicker")
				_player.combo_used()
			else:
				_whirl_jumps_left = 0
		return
	_whirl_jumps_left = 0
	if whirling or not _player.is_skill_held("flicker") or _flicker_timer > 0.0:
		return
	if _player.is_dashing() or _player.is_charging_fireball() or _player.is_chopping():
		return
	var cost := _player.skill_mana("flicker", Skills.FLICKER_MANA * (1.0 + _player.skills.tree_bonus("flicker_mana")))
	if _in_cloud():
		cost = 0.0
	if _player.mana < cost:
		_player._hint(Lang.t("Za mało many"))
		_flicker_timer = 0.3
		return
	if not _jump(Skills.FLICKER_RANGE, level, false):
		_player._hint(Lang.t("Brak wrogów w zasięgu"))
		_flicker_timer = 0.3
		return
	_player.spend_mana(cost)
	_player.note_skill("flicker")
	_flicker_timer = maxf(Skills.FLICKER_INTERVAL / _player._skill_speed(Skills.tags("flicker")), Skills.FLICKER_MIN_INTERVAL)


## Skok na wylot przez najbliższego widocznego wroga (innego niż poprzedni, jeśli jest wybór): postać ląduje za nim
## i rani wszystkich na swojej drodze i wokół celu - przy jednym wrogu przebija go tam i z powrotem.
func _jump(reach: float, level: int, spinning: bool) -> bool:
	var origin := _player.body_center()
	var space := _player.get_world_2d().direct_space_state
	# kandydaci od najbliższego; promień (czy nie zasłania ściana) tylko do pierwszego widocznego -
	# w gęstej gromadzie w zasięgu bywa ponad sto wrogów, a skoki w Młynku lecą kilka razy na sekundę
	var candidates: Array = []
	for enemy: Goblin in Goblin.near(_player.get_tree(), _player.global_position, reach):
		var d := enemy.global_position.distance_to(_player.global_position)
		if d > reach:
			continue
		if enemy == _last_target and is_instance_valid(_last_target):
			d += reach  # poprzedni cel tylko wtedy, gdy nie ma innego
		candidates.append([d, enemy])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var best: Goblin = null
	for candidate: Array in candidates:
		# Mgnienie przeskakuje przeszkody - wroga zasłania tylko granica mapy i ściana podziemi
		var ray := PhysicsRayQueryParameters2D.create(origin, candidate[1].hurt_center(), Player.JUMP_MASK)
		if space.intersect_ray(ray).is_empty():
			best = candidate[1]
			break
	if best == null:
		return false
	var spot := _landing_spot(best)
	if not spot.is_finite():
		return false
	var from := _player.global_position
	_player._spawn_ghost()
	_player.global_position = spot
	_player.reset_physics_interpolation()
	_player._invulnerable_timer = maxf(_player._invulnerable_timer, 0.15)
	_last_target = best
	_flicker_marks.erase(best)
	_flicker_marks.append(best)
	if _flicker_marks.size() > Skills.FLICKER_MARKS:
		_flicker_marks.pop_front()
	var travel := spot - from
	_player._face_direction(travel)
	if not spinning:
		_player.play_thrust(travel)  # ostrze do przodu, w stronę skoku
	var trail_from := from + Player.BODY_OFFSET
	var trail := _player.body_center() - trail_from
	# efekty przyspieszają z szybkością ataku (najwyżej 2x), żeby przy szybkich skokach nie nakładały się w bałagan
	var fps := 16.0 * clampf(_player._skill_speed(Skills.tags("flicker")), 1.0, 2.0)
	if spinning:
		_spin_fx_time = SPIN_FX_TIME
		SkillEffects.sheet_once(_player.get_parent(), FLICKER_SPIN_TRAIL, 7, fps, trail_from, FLICKER_SPIN_TRAIL_ANCHOR,
				trail.angle(), maxf(0.5, (trail.length() - 8.0) / FLICKER_SPIN_TRAIL_LENGTH))
	else:
		SkillEffects.sheet_once(_player.get_parent(), FLICKER_TRAIL, 7, fps, trail_from, FLICKER_TRAIL_ANCHOR,
				trail.angle(), maxf(0.5, (trail.length() - 8.0) / FLICKER_TRAIL_LENGTH))
	SkillEffects.sheet_once(_player.get_parent(), FLICKER_SLASH, 8, fps, best.hurt_center(), FLICKER_SLASH_ANCHOR,
			travel.angle() + FLICKER_SLASH_TILT * (1.0 if randf() < 0.5 else -1.0))
	Sfx.play("dash" if spinning else "swing", 0.0, 1.2)
	var multiplier := Skills.flicker_damage(level) * (1.0 + _player.skills.tree_bonus("flicker_damage")
			+ _player.equipment.effect_power("endless_whirl"))
	# cięcie wokół celu i wzdłuż drogi skoku (odrzut od postaci, która już stoi za celem)
	var path_from := from + Player.BODY_OFFSET
	var path_to := _player.body_center()
	var reach_hit := (path_to - path_from).length() / 2.0 + maxf(FLICKER_PATH_WIDTH, FLICKER_HIT_RADIUS) + 40.0
	for enemy: Goblin in Goblin.near(_player.get_tree(), (path_from + path_to) / 2.0, reach_hit):
		var center := enemy.hurt_center()
		var on_path := Geometry2D.get_closest_point_to_segment(center, path_from, path_to).distance_to(center) <= FLICKER_PATH_WIDTH + enemy.hurt_radius
		if on_path or center.distance_to(best.hurt_center()) <= FLICKER_HIT_RADIUS + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier, Skills.tags("flicker")), _player.global_position, 90.0, "", Skills.tags("flicker"))
	return true


## Wolne miejsce za celem (na wylot): najpierw dokładnie na przedłużeniu skoku, potem coraz bardziej z boku,
## a na końcu - gdy za celem ściana - od strony, z której przychodzimy. Nie w przeszkodzie ani w głębokiej wodzie,
## ale za płotem czy klifem już tak (przegradza tylko granica mapy i ściana podziemi).
func _landing_spot(target: Goblin) -> Vector2:
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = Player.SOLID_MASK | Player.JUMP_MASK
	var space := _player.get_world_2d().direct_space_state
	var through := (target.global_position - _player.global_position).normalized()
	if through == Vector2.ZERO:
		through = _player.facing_dir
	var distance := target.hurt_radius + FLICKER_OVERSHOOT
	for turn in [0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, PI]:
		var spot: Vector2 = target.global_position + through.rotated(turn) * distance
		query.transform = Transform2D(0.0, spot)
		if space.intersect_shape(query, 1).is_empty():
			var ray := PhysicsRayQueryParameters2D.create(target.global_position, spot, Player.JUMP_MASK)
			if space.intersect_ray(ray).is_empty():
				return spot
	return Vector2.INF


# ---------------------------------------------------------------- Dymne Wybuchy
func _press_smoke() -> void:
	if _smoke_charge >= 0.0:
		return
	if not _player.spend_mana(_player.skill_mana("smoke_burst", Skills.SMOKE_MANA)):
		_player._hint(Lang.t("Za mało many"))
		return
	if _player.combo_with("smoke_burst"):
		_player.combo_used()
		_fire_smoke(3, true)
		return
	_smoke_charge = 0.0
	_smoke_stage = 0
	# wirujący krąg dymu u stóp w czasie ładowania (MiscVfx), rośnie z każdym rzędem
	_smoke_swirl = MiscVfx.looping("smoke_ring")
	_smoke_swirl.scale = Vector2.ONE * SWIRL_SIZE
	_player.add_child(_smoke_swirl)
	Sfx.play("magic", -4.0, 0.7)


## Czas ładowania jednego rzędu: szybszy z szybkością ataku i rzucania oraz z węzłem drzewka.
func _smoke_row_time() -> float:
	return Skills.SMOKE_CHARGE_TIME / (_player.stats.skill_speed(_smoke_tags) * (1.0 + _player.skills.tree_bonus("smoke_charge")))


func _process_smoke(delta: float) -> void:
	if _smoke_charge < 0.0:
		return
	if _player.is_dashing() or _player.stats.weapon_type() != "melee":
		_stop_smoke_charge()
		return
	var aim := _player._aim_direction()
	_player._ranged_pose(aim)
	if _player.is_skill_held("smoke_burst"):
		_smoke_charge += delta
		var stage := mini(int(_smoke_charge / _smoke_row_time()), 2)
		if stage > _smoke_stage:
			_smoke_stage = stage
			Sfx.play("magic", -2.0, 0.8 + 0.2 * stage)
			MiscVfx.puff(_player.get_parent(), _player.body_center(), SMOKE_COLOR, 0.4 + 0.15 * stage)
			if _smoke_swirl != null:
				_smoke_swirl.scale = Vector2.ONE * SWIRL_SIZE * (1.0 + 0.25 * stage)
		return
	var rows := 1 + _smoke_stage
	_stop_smoke_charge()
	_fire_smoke(rows, false)


func _stop_smoke_charge() -> void:
	_smoke_charge = -1.0
	_smoke_stage = 0
	if _smoke_swirl != null:
		_smoke_swirl.queue_free()
		_smoke_swirl = null


## Odpala `rows` rzędów po 3 wybuchy w stożku przed postacią (kolejne rzędy dalej, większe i mocniejsze).
func _fire_smoke(rows: int, combo: bool) -> void:
	var aim := _player._aim_direction()
	var origin := _player.global_position
	var level := _player.skills.level_of("smoke_burst")
	_player._ranged_pose(aim)
	_player.note_skill("smoke_burst")
	if _player.skills.has_keystone("smoke_shadow"):
		_start_cloud(origin + aim * Skills.SMOKE_DISTANCE[rows - 1] * 0.6)
	if combo:
		MiscVfx.spark(_player.get_parent(), _player.body_center(), Color(1.0, 0.9, 0.6), 1.4)
	_player.support_echo("smoke_burst", _fire_smoke.bind(rows, combo))
	for ring in rows:
		var spread := deg_to_rad(Skills.SMOKE_SPREAD_DEGREES[ring])
		for k in 3:
			var at := origin + aim.rotated((k - 1) * spread) * Skills.SMOKE_DISTANCE[ring]
			var timer := _player.get_tree().create_timer(ring * SMOKE_RING_DELAY + k * 0.02, false)
			var bonus := (1.0 + _player.skills.tree_bonus("smoke_damage")) * (_player.combo_damage() if combo else 1.0)
			timer.timeout.connect(_burst.bind(at, aim.rotated((k - 1) * spread + SMOKE_FX_ZIGZAG * (1.0 if ring % 2 == 0 else -1.0)), Skills.SMOKE_RADIUS[ring] * _player.stats.area_multiplier(_smoke_tags),
					Skills.smoke_damage(level, ring) * bonus))


## Jeden Dymny Wybuch: klin dymu buchający w kierunku `dir` i obrażenia w kręgu o promieniu `radius`.
func _burst(at: Vector2, dir: Vector2, radius: float, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	var parent := _player.get_parent()
	var size := radius / SMOKE_FX_RADIUS
	var fx_dir := dir.rotated(randf_range(-SMOKE_FX_JITTER, SMOKE_FX_JITTER))
	SkillEffects.sheet_once(parent, SMOKE_FX, 10, 16.0, at - fx_dir * radius * 0.6, SMOKE_FX_ANCHOR, fx_dir.angle(), 1.0, size,
			SMOKE_FX_LEAN)
	Sfx.play_at("explosion", at, -12.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at + Vector2(0, -6)) <= radius + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier, _smoke_tags), at, 110.0, "fire", _smoke_tags)


# ---------------------------------------------------------------- Rozpłatanie i krwawienie
func _rend() -> void:
	var level := _player.skills.level_of("rend")
	var aim := _player._aim_direction()
	var combo := _player.combo_with("rend")
	if combo:
		_player.combo_used()
	_player._ranged_pose(aim)
	_player.play_skill_anim("sweep")
	_player.note_skill("rend")
	var origin := _player.body_center()
	var half := deg_to_rad(Skills.REND_ARC_DEGREES) / 2.0
	var tags := Skills.tags("rend")
	var reach := Skills.REND_REACH * _player.stats.area_multiplier(tags)
	SkillEffects.sheet_once(_player.get_parent(), REND_FX, 7, 18.0, origin, REND_FX_ANCHOR, aim.angle(), 1.0,
			reach / REND_FX_RADIUS)
	Sfx.play("big_slash", 0.0, 1.1)
	var bleed := Skills.rend_bleed(level) * (2.0 if combo else 1.0) * (_player.combo_damage() if combo else 1.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > reach + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(aim.angle(), to_enemy.angle())) > half:
			continue
		_player.hit_enemy(enemy, _player._skill_damage(Skills.rend_damage(level), tags), _player.global_position, 80.0, "", tags)
		bleed_enemy(enemy, bleed)


## Krwawienie: `multiplier` obrażeń broni rozłożone na BLEED_TICKS ran co pół sekundy (więcej z węzłów drzewka).
## Z Krwawym Szałem rany leczą gracza.
func bleed_enemy(enemy: Goblin, multiplier: float) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var total := _player._skill_damage(multiplier * (1.0 + _player.skills.tree_bonus("bleed_damage")), Skills.tags("rend"))
	var per_tick := maxi(1, roundi(float(total) / Skills.BLEED_TICKS))
	var frenzy := _player.skills.has_keystone("blood_frenzy")
	SkillEffects.sheet_once(_player.get_parent(), REND_WOUND_FX, 9, 15.0, enemy.hurt_center(), REND_WOUND_ANCHOR)
	for i in Skills.BLEED_TICKS:
		_player.get_tree().create_timer(0.5 * (i + 1), false).timeout.connect(func() -> void:
			if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
				enemy.take_damage(per_tick, enemy.global_position, 0.0)
				SkillEffects.sheet_once(enemy.get_parent(), REND_WOUND_FX, 9, 15.0, enemy.hurt_center(), REND_WOUND_ANCHOR, 0.0, 1.0, 0.45)
				if frenzy and is_instance_valid(_player) and not _player.is_dead:
					_player.legendary.leech_heal(per_tick * FRENZY_LEECH))


# ---------------------------------------------------------------- Rozłupanie Ziemi
func _ground_slam() -> void:
	var level := _player.skills.level_of("ground_slam")
	_start_cooldown("ground_slam", Skills.SLAM_COOLDOWN)
	var aim := _player._aim_direction()
	var combo := _player.combo_with("ground_slam")
	if combo:
		_player.combo_used()
	_spikes.clear()
	_spikes_time = Skills.SPIKE_TIME
	_player._ranged_pose(aim)
	_player.play_skill_anim("chop")
	_player.note_skill("ground_slam")
	_player.add_shake(4.0)
	Sfx.play("explosion", -4.0, 0.7)
	var origin := _player.global_position
	var area := _player.stats.area_multiplier(Skills.tags("ground_slam"))
	var damage := Skills.slam_damage(level) * (_player.combo_damage() if combo else 1.0)
	var stun := Skills.slam_stun(level) * (1.0 + _player.skills.tree_bonus("slam_stun"))
	var layer := _player.get_tree().get_first_node_in_group("floor_layer")
	var parent: Node = layer if layer != null else _player.get_parent()
	var hit := {}
	if combo:
		MiscVfx.ring(_player.get_parent(), origin, Skills.SLAM_RING * area, Color(0.75, 0.6, 0.4))
		SkillEffects.ground_crack(parent, origin, Skills.SLAM_RING * area * 0.7, 2.0)
		# [promień jako część kręgu, liczba erupcji, opóźnienie, przesunięcie kąta w ułamku odstępu]
		for ring in [[0.5, 9, 0.0, 0.0], [0.85, 14, 0.08, 0.5]]:
			for k: int in ring[1]:
				var spot: Vector2 = origin + Vector2.from_angle(TAU * (k + ring[3]) / ring[1]) * Skills.SLAM_RING * area * ring[0]
				_spikes.append(spot)
				_player.get_tree().create_timer(ring[2] + randf() * 0.04, false).timeout.connect(func() -> void:
					if is_instance_valid(_player):
						SkillEffects.sheet_once(_player.get_parent(), SLAM_FX, 10, 15.0, spot, SLAM_FX_ANCHOR, 0.0, 1.0, 1.0))
		for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(origin) <= Skills.SLAM_RING * area + enemy.hurt_radius:
				_slam_hit(enemy, damage, stun, origin)
		return
	# fala pęknięć biegnie przed postacią
	var steps := 6
	for i in steps:
		var at := origin + aim * (20.0 + (Skills.SLAM_LENGTH * area - 20.0) * i / (steps - 1))
		_spikes.append(at)
		_player.get_tree().create_timer(i * 0.05, false).timeout.connect(func() -> void:
			if not is_instance_valid(_player):
				return
			SkillEffects.ground_crack(parent, at, Skills.SLAM_WIDTH * area, 1.6)
			SkillEffects.sheet_once(_player.get_parent(), SLAM_FX, 10, 15.0, at, SLAM_FX_ANCHOR, 0.0, 1.0,
					lerpf(0.75, 1.2, float(i) / (steps - 1)))
			for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
				if not hit.has(enemy) and enemy.global_position.distance_to(at) <= Skills.SLAM_WIDTH * area + enemy.hurt_radius:
					hit[enemy] = true
					_slam_hit(enemy, damage, stun, origin))


## Szarża zaraz po Rozłupaniu Ziemi (combo): kolce z pęknięć wybuchają jeden po drugim; każdy wróg dostaje raz.
func explode_spikes() -> void:
	if _spikes_time <= 0.0 or _spikes.is_empty():
		return
	var tags := Skills.tags("ground_slam")
	var area := _player.stats.area_multiplier(tags)
	var radius := Skills.SPIKE_BLAST_RADIUS * area
	var damage := Skills.slam_damage(_player.skills.level_of("ground_slam")) * Skills.SPIKE_BLAST_DAMAGE * _player.combo_damage()
	var hit := {}
	var spots := _spikes.duplicate()
	_spikes.clear()
	_spikes_time = 0.0
	_player.add_shake(5.0)
	for i in spots.size():
		var at: Vector2 = spots[i]
		_player.get_tree().create_timer(0.03 * i, false).timeout.connect(func() -> void:
			if not is_instance_valid(_player):
				return
			MiscVfx.ring(_player.get_parent(), at, radius, Color(1.0, 0.6, 0.3))
			SkillEffects.sheet_once(_player.get_parent(), SLAM_FX, 10, 20.0, at, SLAM_FX_ANCHOR, 0.0, 1.0, 1.3)
			if i % 3 == 0:
				Sfx.play_at("explosion", at, -8.0)
			for enemy: Goblin in Goblin.near(_player.get_tree(), at, radius + 40.0):
				if not hit.has(enemy) and enemy.global_position.distance_to(at) <= radius + enemy.hurt_radius:
					hit[enemy] = true
					_player.hit_enemy(enemy, _player._skill_damage(damage, tags), at, 90.0, "", tags))


func _slam_hit(enemy: Goblin, damage: float, stun: float, from: Vector2) -> void:
	var tags := Skills.tags("ground_slam")
	_player.hit_enemy(enemy, _player._skill_damage(damage, tags), from, 60.0, "", tags)
	if enemy.state != Goblin.State.DEAD:
		enemy.stun(stun)


# ---------------------------------------------------------------- Riposta
func _riposte() -> void:
	_start_cooldown("riposte", Skills.RIPOSTE_COOLDOWN)
	# zaraz po Mgnieniu: kontra wybucha na ostatnio trafionych przez Mgnienie wrogach
	if _player.combo_after("riposte") == "flicker":
		_player.combo_used()
		_marked_ripostes()
	_parry_time = Skills.RIPOSTE_TIME
	_player._ranged_pose(_player._aim_direction())
	Sfx.play("swing", 0.0, 0.8)
	if _parry_ring == null:
		_parry_ring = _ParryRing.new(RIPOSTE_GUARD_FX)
		_player.add_child(_parry_ring)
		_player.move_child(_parry_ring, _player.sprite.get_index())
		_parry_ring.position = Player.BODY_OFFSET
	_parry_ring.visible = true
	_parry_ring.time = 0.0


## Riposta po Mgnieniu (combo): na każdym z ostatnio trafionych przez Mgnienie wrogów (Skills.FLICKER_MARKS) wybucha
## kontra Riposty, raniąc i ogłuszając wszystkich wokół niego.
func _marked_ripostes() -> void:
	var marks := _flicker_marks.filter(func(e) -> bool: return is_instance_valid(e) and (e as Goblin).state != Goblin.State.DEAD)
	_flicker_marks.clear()
	var tags := Skills.tags("riposte")
	var radius := Skills.RIPOSTE_RADIUS * _player.stats.area_multiplier(tags)
	var damage := Skills.riposte_damage(_player.skills.level_of("riposte")) * (1.0 + _player.skills.tree_bonus("riposte_damage")) \
			* _player.combo_damage()
	for i in marks.size():
		# słaba referencja - wróg może zginąć, zanim kontra wybuchnie
		var mark: WeakRef = weakref(marks[i])
		_player.get_tree().create_timer(0.08 * i, false).timeout.connect(func() -> void:
			var target: Goblin = mark.get_ref()
			if not is_instance_valid(_player) or target == null:
				return
			var at := target.hurt_center()
			SkillEffects.sheet_once(_player.get_parent(), RIPOSTE_COUNTER_FX, 6, 18.0, at, RIPOSTE_COUNTER_ANCHOR, 0.0, 1.0,
					radius / RIPOSTE_FX_RADIUS)
			Sfx.play_at("hit_heavy", at, 0.0)
			for enemy: Goblin in Goblin.near(_player.get_tree(), at, radius + 40.0):
				if enemy.hurt_center().distance_to(at) <= radius + enemy.hurt_radius:
					_player.hit_enemy(enemy, _player._skill_damage(damage, tags), at, 120.0, "", tags)
					if enemy.state != Goblin.State.DEAD:
						enemy.stun(0.5))


## Wołane przez gracza przy otrzymaniu ciosu: w czasie zasłony cios nie rani, a postać kontratakuje.
func try_parry(from: Vector2) -> bool:
	if _parry_time <= 0.0:
		return false
	_parry_time = 0.0
	if _parry_ring != null:
		_parry_ring.visible = false
	var level := _player.skills.level_of("riposte")
	var damage := Skills.riposte_damage(level) * (1.0 + _player.skills.tree_bonus("riposte_damage"))
	var origin := _player.body_center()
	_player._invulnerable_timer = maxf(_player._invulnerable_timer, 0.4)
	_player._face_direction(from - _player.global_position)
	var tags := Skills.tags("riposte")
	var radius := Skills.RIPOSTE_RADIUS * _player.stats.area_multiplier(tags)
	SkillEffects.sheet_once(_player.get_parent(), RIPOSTE_COUNTER_FX, 6, 18.0, origin, RIPOSTE_COUNTER_ANCHOR, 0.0, 1.0,
			radius / RIPOSTE_FX_RADIUS)
	DamageNumber.spawn_text(_player.get_parent(), origin + Vector2(0, -14), Lang.t("Riposta!"), Color(1.0, 0.9, 0.5), 9)
	Sfx.play("hit_heavy", 2.0, 1.2)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(origin) <= radius + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(damage, tags), _player.global_position, 160.0, "", tags)
			if enemy.state != Goblin.State.DEAD:
				enemy.stun(0.5)
	# po udanej Ripoście Szarża jest darmowa (Skills.COMBOS)
	_player.note_skill("riposte")
	return true


# ---------------------------------------------------------------- Zew Peruna
func _war_cry() -> void:
	var level := _player.skills.level_of("war_cry")
	_start_cooldown("war_cry", Skills.CRY_COOLDOWN * cry_cooldown_factor())
	# Donośny Głos (kamień wsparcia): dłuższy zew i większy obszar strachu; węzeł Donośny głos - zasięg okrzyków
	var tags := Skills.tags("war_cry")
	var radius := Skills.CRY_RADIUS * _player.stats.area_multiplier(tags) * cry_radius_factor()
	_cry_total = Skills.CRY_TIME * (1.0 + _player.support("war_cry", "duration"))
	_cry_time = _cry_total
	_forced_crits = Skills.CRY_CRITS
	_player.note_skill("war_cry")
	var origin := _player.global_position
	SkillEffects.sheet_once(_player.get_parent(), PERUN_FX, 10, 20.0, origin, PERUN_FX_ANCHOR, 0.0, 1.0,
			radius / PERUN_FX_RADIUS)
	if _cry_fx == null:
		_cry_fx = Sprite2D.new()
		_cry_fx.texture = PERUN_BUFF_FX
		_cry_fx.hframes = PERUN_BUFF_FRAMES
		_cry_fx.position = Player.BODY_OFFSET
		_cry_fx.z_index = 1
		_player.add_child(_cry_fx)
	_cry_fx.visible = true
	Sfx.play("thunder", -2.0)
	_player.add_shake(3.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(origin) <= radius:
			enemy.fear(Skills.CRY_FEAR * (1.0 + _player.support("war_cry", "duration")), origin)
	_update_temp_bonus()


## Wołane przy trafieniu: po Zewie Peruna kolejne ciosy są krytyczne.
func take_forced_crit() -> bool:
	if _forced_crits <= 0:
		return false
	_forced_crits -= 1
	return true


## Węzeł Donośny głos: zasięg i odnowienie okrzyków (Zew Peruna, Ryk Tura).
func cry_radius_factor() -> float:
	return 1.0 + _player.skills.tree_bonus("cry_radius")


func cry_cooldown_factor() -> float:
	return maxf(1.0 + _player.skills.tree_bonus("cry_cooldown"), 0.2)


# ---------------------------------------------------------------- Wilczy Kieł
## Wróg najbliższy kursora w zasięgu pchnięć (od tułowia; preferowany ten na linii celowania).
func _fang_target(aim: Vector2) -> Goblin:
	var origin := _player.body_center()
	var best: Goblin = null
	var best_score := INF
	for enemy: Goblin in Goblin.near(_player.get_tree(), origin, Skills.FANG_REACH + 40.0):
		if enemy.state == Goblin.State.DEAD:
			continue
		var to_enemy := enemy.hurt_center() - origin
		var dist := to_enemy.length()
		if dist > Skills.FANG_REACH + enemy.hurt_radius:
			continue
		var score := dist + absf(angle_difference(aim.angle(), to_enemy.angle())) * 40.0
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _wolf_fang() -> void:
	var level := _player.skills.level_of("wolf_fang")
	var tags := Skills.tags("wolf_fang")
	_start_cooldown("wolf_fang", Skills.FANG_COOLDOWN)
	var aim := _player._aim_direction()
	var target := _fang_target(aim)
	if target != null:
		aim = (target.hurt_center() - _player.body_center()).normalized()
	_player._ranged_pose(aim)
	_player.note_skill("wolf_fang")
	var interval := Skills.FANG_INTERVAL / _player._skill_speed(tags)
	var target_ref: WeakRef = weakref(target) if target != null else null
	for i in Skills.FANG_THRUSTS:
		var last := i == Skills.FANG_THRUSTS - 1
		_player.get_tree().create_timer(interval * i, false).timeout.connect(func() -> void:
			if not is_instance_valid(_player) or _player.is_dead:
				return
			var enemy: Goblin = target_ref.get_ref() if target_ref != null else null
			var dir := aim
			if enemy != null and enemy.state != Goblin.State.DEAD:
				dir = (enemy.hurt_center() - _player.body_center()).normalized()
			_player.play_thrust(dir)
			Sfx.play("swing", -2.0, 1.3 + 0.1 * i)
			# smuga pchnięcia od tułowia do celu (lekko rozrzucona w pionie, ostatnia dłuższa)
			var start := _player.body_center() + dir.orthogonal() * randf_range(-3.0, 3.0)
			var reach := Skills.FANG_REACH
			if enemy != null and enemy.state != Goblin.State.DEAD:
				reach = start.distance_to(enemy.hurt_center()) + 6.0
			SkillEffects.sheet_once(_player.get_parent(), FANG_FX, 7, 30.0, start, FANG_FX_ANCHOR, dir.angle(),
					reach * (1.25 if last else 1.0) / FANG_FX_LENGTH, 1.3 if last else 1.0)
			if enemy == null or enemy.state == Goblin.State.DEAD:
				return
			var at := enemy.hurt_center()
			var multiplier := Skills.fang_damage(level) * (Skills.FANG_FINAL if last else 1.0)
			_player.hit_enemy(enemy, _player._skill_damage(multiplier, tags), _player.global_position, 140.0 if last else 20.0, "", tags)
			if last:
				_player.add_shake(3.0)
				Sfx.play_at("hit_heavy", at, 0.0)
				SkillEffects.sheet_once(_player.get_parent(), REND_WOUND_FX, 9, 15.0, at, REND_WOUND_ANCHOR, 0.0, 1.0, 1.2)
				if enemy.state != Goblin.State.DEAD:
					enemy.stun(Skills.FANG_FINAL_STUN))


# ---------------------------------------------------------------- Ryk Tura
func _bull_roar() -> void:
	var level := _player.skills.level_of("bull_roar")
	var tags := Skills.tags("bull_roar")
	_start_cooldown("bull_roar", Skills.ROAR_COOLDOWN * cry_cooldown_factor())
	var radius := Skills.ROAR_RADIUS * _player.stats.area_multiplier(tags) * cry_radius_factor()
	_roar_time = Skills.ROAR_TIME * (1.0 + _player.support("bull_roar", "duration"))
	_player.note_skill("bull_roar")
	_player.play_skill_anim("chop", 0.4)
	var origin := _player.global_position
	# fala jest duża (cały zasięg okrzyku) - półprzezroczysta, żeby nie zasłaniała walki
	SkillEffects.sheet_once(_player.get_parent(), ROAR_FX, 10, 16.0, origin, ROAR_FX_ANCHOR, 0.0, 1.0,
			radius / ROAR_FX_RADIUS).modulate.a = ROAR_FX_ALPHA
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -14), Lang.t("Ryk Tura!"), ROAR_COLOR, 9)
	Sfx.play("explosion", -6.0, 0.55)
	_player.add_shake(4.0)
	# wrogowie wokół rzucają się na postać: koniec strachu, budzą się i gonią
	for enemy: Goblin in Goblin.near(_player.get_tree(), origin, radius + 40.0):
		if enemy.state == Goblin.State.DEAD or enemy.global_position.distance_to(origin) > radius:
			continue
		enemy._fear_time = 0.0
		enemy.aggro()
	_update_temp_bonus()


# ---------------------------------------------------------------- Skok Niedźwiedzia
func _bear_leap() -> void:
	_start_cooldown("bear_leap", Skills.LEAP_COOLDOWN)
	var from := _player.global_position
	# cel jak u czarów (SpellSkills._cursor): kursor albo tułów + aim_override (testy, celowanie padem)
	var aim := _player.get_global_mouse_position() if _player.aim_override == Vector2.ZERO else _player.body_center() + _player.aim_override
	var target := from + (aim - from).limit_length(Skills.LEAP_RANGE)
	# skok przenosi nad przeszkodami - zatrzymuje go tylko granica mapy i ściany podziemi (jak Krok przez Mgłę)
	var ray := PhysicsRayQueryParameters2D.create(from, target, Player.JUMP_MASK)
	var hit := _player.get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		target = hit["position"] - (target - from).normalized() * 10.0
	_player._face_direction(target - from)
	_player.note_skill("bear_leap")
	_player.play_skill_anim("dash", Skills.LEAP_TIME)
	Sfx.play("dash", 0.0, 0.8)
	SkillEffects.ground_crack(_dust_parent(), from, 14.0, 0.8)
	_player.start_leap(target, Skills.LEAP_TIME, _leap_landed)


func _dust_parent() -> Node:
	var layer := _player.get_tree().get_first_node_in_group("floor_layer")
	return layer if layer != null else _player.get_parent()


## Lądowanie Skoku Niedźwiedzia: rani i odrzuca wszystkich wokół.
func _leap_landed() -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	var level := maxi(_player.skills.level_of("bear_leap"), 1)
	var tags := Skills.tags("bear_leap")
	var radius := Skills.LEAP_RADIUS * _player.stats.area_multiplier(tags)
	var origin := _player.global_position
	_player.play_skill_anim("chop", 0.3, 4)
	_player.add_shake(6.0)
	Sfx.play("explosion", -3.0, 0.6)
	SkillEffects.ground_crack(_dust_parent(), origin, radius * 0.8, 1.6)
	SkillEffects.sheet_once(_player.get_parent(), LEAP_FX, 12, 16.0, origin, LEAP_FX_ANCHOR, 0.0, 1.0, radius / LEAP_FX_RADIUS)
	for enemy: Goblin in Goblin.near(_player.get_tree(), origin, radius + 40.0):
		if enemy.global_position.distance_to(origin) <= radius + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(Skills.leap_damage(level), tags), origin, Skills.LEAP_KNOCKBACK, "", tags)


# ---------------------------------------------------------------- zdrowie a obrażenia (Pełnia Sił, Gniew rannego, Ostatni Bastion)
func _health_share() -> float:
	return clampf(float(_player.health) / maxf(float(_player.stats.max_health()), 1.0), 0.0, 1.0)


func bastion_active() -> bool:
	return _player.skills.has_keystone("last_bastion") and not _player.is_dead and _health_share() < BASTION_HEALTH


## Mnożnik zadawanych obrażeń wg zdrowia: Pełnia Sił (+1% za każde 5% ponad połowę), Gniew rannego (+1% za każde
## 5% brakującego zdrowia) i Ostatni Bastion (poniżej 30% zdrowia).
func health_damage_factor() -> float:
	var share := _health_share()
	var bonus := 0.0
	var full := _player.skills.tree_bonus("full_strength")
	if full > 0.0:
		bonus += minf(floorf(maxf(share - 0.5, 0.0) / 0.05) * 0.01, full)
	var wrath := _player.skills.tree_bonus("wounded_wrath")
	if wrath > 0.0:
		bonus += minf(floorf((1.0 - share) / 0.05 + 0.001) * 0.01, wrath)
	if bastion_active():
		bonus += BASTION_DAMAGE
	return 1.0 + bonus


## Jaka część ciosu dociera do postaci (Ostatni Bastion: poniżej 30% zdrowia połowa).
func bastion_taken() -> float:
	return BASTION_TAKEN if bastion_active() else 1.0


## Wstrząs (węzeł): trafienie umiejętnością obszarową miecza ogłusza na chwilę (każdego wroga najwyżej raz na
## Skills.TREMOR_INTERVAL s, żeby Młynek nie trzymał wrogów w ogłuszeniu bez końca).
func tremor(enemy: Goblin, tags: Array) -> void:
	if not "area" in tags or enemy.state == Goblin.State.DEAD:
		return
	var skill := Skills.skill_of(tags)
	if skill == "" or Skills.get_data(skill).get("weapon", "") != "melee":
		return
	var stun := _player.skills.tree_bonus("tremor_stun")
	if stun <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if int(_tremor_ready.get(enemy, 0)) > now:
		return
	if _tremor_ready.size() > 200:
		_tremor_ready.clear()
	_tremor_ready[enemy] = now + roundi(Skills.TREMOR_INTERVAL * 1000.0)
	enemy.stun(stun)


# ---------------------------------------------------------------- Widmowe Ostrza
func _spectral_blades() -> void:
	var level := _player.skills.level_of("spectral_blades")
	_start_cooldown("spectral_blades", Skills.BLADES_COOLDOWN)
	# zaraz po Młynku ostrza od razu wylatują; zaraz po Rozpłataniu wylatują i rozpłatują swoje cele
	var after := _player.combo_after("spectral_blades")
	var combo := after != ""
	if combo:
		_player.combo_used()
	_player.note_skill("spectral_blades")
	if is_instance_valid(_blades):
		_blades.queue_free()
	_blades = SpectralBlades.new()
	_blades.player = _player
	_blades.count = Skills.BLADES_COUNT + roundi(_player.skills.tree_bonus("blade_count"))
	_blades.damage = Skills.blades_damage(level) * (_player.combo_damage() if combo else 1.0)
	_blades.time_left = Skills.BLADES_TIME
	_blades.orbit = Skills.BLADES_ORBIT * _player.stats.area_multiplier(Skills.tags("spectral_blades"))
	if after == "rend":
		_blades.on_hit = _blade_rend
	_player.get_parent().add_child(_blades)
	Sfx.play("magic", 0.0, 1.3)
	if combo:
		_blades.launch()


## Widmowe ostrze po Rozpłataniu (combo) dotarło do celu: Rozpłatanie wokół niego - cios i krwawienie.
func _blade_rend(target: Goblin) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(target):
		return
	var level := maxi(_player.skills.level_of("rend"), 1)
	var tags := Skills.tags("rend")
	var at := target.hurt_center()
	var reach := Skills.REND_REACH * 0.6 * _player.stats.area_multiplier(tags)
	SkillEffects.sheet_once(_player.get_parent(), REND_FX, 7, 18.0, at, REND_FX_ANCHOR, randf() * TAU, 1.0, reach / REND_FX_RADIUS)
	for enemy: Goblin in Goblin.near(_player.get_tree(), at, reach + 40.0):
		if enemy.hurt_center().distance_to(at) <= reach + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(Skills.rend_damage(level) * _player.combo_damage(), tags), at, 60.0, "", tags)
			bleed_enemy(enemy, Skills.rend_bleed(level) * _player.combo_damage())


## Młynek zaraz po Widmowych Ostrzach (combo): na chwilę wokół postaci krąży burza widmowych ostrzy - więcej
## ostrzy, szybciej i szerzej niż zwykłe Widmowe Ostrza (zastępuje je).
func blade_storm() -> void:
	var level := _player.skills.level_of("spectral_blades")
	if is_instance_valid(_blades):
		_blades.queue_free()
	_blades = SpectralBlades.new()
	_blades.player = _player
	_blades.count = (Skills.BLADES_COUNT + roundi(_player.skills.tree_bonus("blade_count"))) * Skills.BLADE_STORM_COUNT
	_blades.damage = Skills.blades_damage(level) * _player.combo_damage()
	_blades.time_left = Skills.BLADE_STORM_TIME
	_blades.orbit = Skills.BLADES_ORBIT * Skills.BLADE_STORM_ORBIT * _player.stats.area_multiplier(Skills.tags("spectral_blades"))
	_blades.spin_speed = SpectralBlades.SPIN_SPEED * Skills.BLADE_STORM_SPIN
	_blades.hit_interval = SpectralBlades.HIT_INTERVAL * 0.6
	_player.get_parent().add_child(_blades)
	Sfx.play("magic", 2.0, 1.5)


# ---------------------------------------------------------------- premie czasowe i węzły kluczowe
## Wykonane combo: Taniec Ostrzy dokłada ładunek szybkości ataku.
func on_combo() -> void:
	if not _player.skills.has_keystone("blade_dance"):
		return
	_dance_stacks = mini(_dance_stacks + 1, DANCE_STACKS)
	_dance_time = DANCE_TIME
	_update_temp_bonus()


func _start_cloud(at: Vector2) -> void:
	_cloud_at = at
	_cloud_time = CLOUD_TIME
	if is_instance_valid(_cloud_node):
		_cloud_node.queue_free()
	# chmura dymu: wirujący krąg dymu na cały promień chmury (MiscVfx)
	_cloud_node = MiscVfx.looping("smoke_ring")
	_cloud_node.position = at
	_cloud_node.scale = Vector2.ONE * CLOUD_RADIUS / MiscVfx.SMOKE_RING_RADIUS
	_cloud_node.modulate = SMOKE_COLOR
	_player.get_parent().add_child(_cloud_node)
	_update_temp_bonus()


func _in_cloud() -> bool:
	return _cloud_time > 0.0 and _player.global_position.distance_to(_cloud_at) <= CLOUD_RADIUS


func _process_timed(delta: float) -> void:
	var before := [_cry_time > 0.0, _dance_stacks, _in_cloud(), _roar_time > 0.0]
	if _parry_time > 0.0:
		_parry_time -= delta
		if _parry_time <= 0.0 and _parry_ring != null:
			_parry_ring.visible = false
	_cry_time = maxf(_cry_time - delta, 0.0)
	if _cry_fx != null:
		_cry_fx.visible = _cry_time > 0.0
		_cry_fx.frame = int((_cry_total - _cry_time) * PERUN_BUFF_FPS) % PERUN_BUFF_FRAMES
	_spikes_time = maxf(_spikes_time - delta, 0.0)
	_dance_time = maxf(_dance_time - delta, 0.0)
	if _dance_time <= 0.0:
		_dance_stacks = 0
	if _cloud_time > 0.0:
		_cloud_time -= delta
		if _cloud_time <= 0.0 and is_instance_valid(_cloud_node):
			var fade := _cloud_node.create_tween()
			fade.tween_property(_cloud_node, "modulate:a", 0.0, 0.8)
			fade.tween_callback(_cloud_node.queue_free)
	_roar_time = maxf(_roar_time - delta, 0.0)
	if before != [_cry_time > 0.0, _dance_stacks, _in_cloud(), _roar_time > 0.0]:
		_update_temp_bonus()


## Chwilowe premie do statystyk postaci: Zew Peruna (obrażenia), Taniec Ostrzy (szybkość ataku), chmura (unik).
func _update_temp_bonus() -> void:
	var bonus := {}
	if _cry_time > 0.0:
		bonus["damage_percent"] = Skills.cry_bonus(_player.skills.level_of("war_cry")) + _player.skills.tree_bonus("cry_power")
	if _dance_stacks > 0:
		bonus["attack_speed"] = DANCE_STEP * _dance_stacks
	if _in_cloud():
		bonus["dodge_chance"] = CLOUD_DODGE
	if _roar_time > 0.0:
		bonus["armor_percent"] = Skills.roar_armor(_player.skills.level_of("bull_roar"))
	_player.stats.set_temp("sword", bonus)


## Efekty do rzędu ikon pod paskami zdrowia i many (jak LegendaryEffects.statuses).
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _cry_time > 0.0:
		result.append({"name": Lang.t("Zew Peruna"), "kind": "good", "left": _cry_time, "total": _cry_total, "icon": ICONS["war_cry"],
				"stacks": _forced_crits, "description": Lang.t("+%d%% zadawanych obrażeń; ciosy krytyczne w zapasie: %d") % [
					roundi(_player.stats.temp_bonus.get("damage_percent", 0.0) * 100.0), _forced_crits]})
	if _dance_stacks > 0:
		result.append({"name": Lang.t("Taniec Ostrzy"), "kind": "good", "left": _dance_time, "total": DANCE_TIME, "icon": ICONS["blade_dance"],
				"stacks": _dance_stacks, "description": Lang.t("+%d%% szybkości ataku (każde combo dokłada)") % roundi(DANCE_STEP * _dance_stacks * 100.0)})
	if _in_cloud():
		result.append({"name": Lang.t("Dym i Cień"), "kind": "good", "left": _cloud_time, "total": CLOUD_TIME, "icon": ICONS["smoke_shadow"],
				"description": Lang.t("+%d%% szansy na unik, Mgnienie nie zużywa many") % roundi(CLOUD_DODGE * 100.0)})
	if _roar_time > 0.0:
		result.append({"name": Lang.t("Ryk Tura"), "kind": "good", "left": _roar_time, "total": Skills.ROAR_TIME, "icon": ICONS["bull_roar"],
				"description": Lang.t("+%d%% pancerza") % roundi(Skills.roar_armor(_player.skills.level_of("bull_roar")) * 100.0)})
	if bastion_active():
		result.append({"name": Lang.t("Ostatni Bastion"), "kind": "good", "left": -1.0, "icon": ICONS["last_bastion"],
				"description": Lang.t("+%d%% zadawanych obrażeń, o %d%% mniej otrzymanych") % [roundi(BASTION_DAMAGE * 100.0),
					roundi((1.0 - BASTION_TAKEN) * 100.0)]})
	if _parry_time > 0.0:
		result.append({"name": Lang.t("Riposta"), "kind": "good", "left": _parry_time, "total": Skills.RIPOSTE_TIME, "icon": ICONS["riposte"],
				"description": Lang.t("Zasłona: następny cios nie zrani, a ty kontratakujesz")})
	return result


## Złota zasłona Riposty wokół postaci: zapętlone klatki (8 w rzędzie), górna połowa za postacią (węzeł stoi
## w drzewie przed jej grafiką), dolna przed nią.
class _ParryRing:
	extends Node2D

	const FRAMES := 8
	const FPS := 12.0
	var time := 0.0
	var _halves: Array[Sprite2D] = []

	func _init(texture: Texture2D) -> void:
		var size := Vector2(texture.get_width() / float(FRAMES), texture.get_height())
		var half := floorf(size.y / 2.0)
		for front in [false, true]:
			var fx := Sprite2D.new()
			fx.texture = texture
			fx.centered = false
			fx.region_enabled = true
			fx.region_rect = Rect2(0, half if front else 0.0, texture.get_width(), size.y - half if front else half)
			fx.hframes = FRAMES
			fx.position = Vector2(-size.x / 2.0, 0.0 if front else -half)
			if front:
				fx.z_index = 1
			add_child(fx)
			_halves.append(fx)

	func _process(delta: float) -> void:
		if not visible:
			return
		time += delta
		for fx in _halves:
			fx.frame = int(time * FPS) % FRAMES
