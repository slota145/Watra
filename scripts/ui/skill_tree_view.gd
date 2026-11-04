class_name SkillTreeView
extends Control
## Sieć węzłów wspólnego drzewka umiejętności (SkillTree) w oknie umiejętności. Przeciąganie myszą po pustym miejscu
## przesuwa drzewko, kółko myszy je przybliża i oddala. W tle kolorowe strony drzewka (siła, zręczność, inteligencja
## i strefy pośrednie), przy większym przybliżeniu podpisy skupisk. Węzły: umiejętności (ikona w kole, obwódka
## w kolorze broni), węzły znaczące (średnie koła z ikoną), drobne węzły ścieżek (kropki w kolorze strony), kluczowe
## (duże, złote), gniazda i start. Puste miejsca na później (SkillTree.is_soon) są przygaszone, z kreskowaną obwódką.
## Wybrane mają złotą obwódkę i złote połączenia, możliwe do wybrania teraz - pulsującą jasną, reszta jest przygaszona.
## Kliknięcie zaznacza węzeł (szczegóły i przyciski pokazuje okno umiejętności), dymek opisuje węzeł, a umiejętność
## z wybranego węzła (start - zwykły atak) przeciąga się na pasek. Gniazda pokazują osadzony kamień; kamień
## przeciągnięty z plecaka na wybrane gniazdo się w nim osadza, a kamień promienia rysuje swój zasięg.

signal selected(node_id: String)
## Prawy przycisk na węźle - prośba o cofnięcie go (okno sprawdza, czy się da).
signal refund_requested(node_id: String)
## Kamień z plecaka upuszczony na gniazdo (okno umiejętności pokazuje wynik).
signal gem_dropped(message: String)

## Ile pikseli interfejsu na jednostkę pozycji węzła, zakres przybliżenia i przybliżenie na start.
const UNIT := 15.0
const ZOOM_RANGE := Vector2(0.25, 1.6)
const START_ZOOM := 0.8
## Od jakiego przybliżenia widać podpisy skupisk.
const LABEL_ZOOM := 0.7
## Promienie węzłów wg rodzaju (węzły znaczące - "notable", drobne - "small").
const RADIUS := {"start": 9.0, "skill": 9.0, "notable": 6.5, "small": 3.0, "keystone": 10.0, "socket": 7.5}
## Promień tła stron drzewka (w jednostkach pozycji węzłów).
const REGION_REACH := 30.0
const SOCKET_LEGEND_ICON := preload("res://assets/ui/socket_legend.png")
const LEGEND_RING := Color(1.0, 0.55, 0.2)
const GOLD := Color(1.0, 0.82, 0.35)
const LINK := Color(0.35, 0.36, 0.45)
const ICONS := {
	"physical_damage": preload("res://assets/skills/node_physical.png"), "attack_speed": preload("res://assets/skills/node_attack_speed.png"),
	"crit_chance": preload("res://assets/skills/node_crit.png"), "combo_window": preload("res://assets/skills/node_combo.png"),
	"spell_damage": preload("res://assets/skills/node_spell_power.png"), "cast_speed": preload("res://assets/skills/node_cast_speed.png"),
	"whirl_radius": preload("res://assets/skills/whirlwind.png"), "flicker_mana": preload("res://assets/skills/flicker.png"),
	"smoke_charge": preload("res://assets/skills/smoke_burst.png"), "smoke_damage": preload("res://assets/skills/smoke_burst.png"),
	"whirl_damage": preload("res://assets/skills/whirlwind.png"), "flicker_damage": preload("res://assets/skills/flicker.png"),
	"combo_damage": preload("res://assets/skills/node_combo.png"), "bleed_damage": preload("res://assets/skills/rend.png"),
	"cry_power": preload("res://assets/skills/war_cry.png"), "slam_stun": preload("res://assets/skills/ground_slam.png"),
	"cry_radius": preload("res://assets/skills/war_cry.png"), "whirl_pull": preload("res://assets/skills/whirlwind.png"),
	"full_strength": preload("res://assets/skills/health_regen.png"), "wounded_wrath": preload("res://assets/skills/rend.png"),
	"tremor_stun": preload("res://assets/skills/ground_slam.png"),
	"lunge_cooldown": preload("res://assets/skills/lunge.png"), "riposte_damage": preload("res://assets/skills/riposte.png"),
	"blade_count": preload("res://assets/skills/spectral_blades.png"), "life_on_hit": preload("res://assets/skills/node_physical.png"),
	"move_speed": preload("res://assets/skills/node_attack_speed.png"), "crit_damage": preload("res://assets/skills/node_crit.png"),
	"health_percent": preload("res://assets/skills/health_regen.png"), "health": preload("res://assets/skills/health_regen.png"),
	"health_regen": preload("res://assets/skills/health_regen.png"), "mana": preload("res://assets/skills/mana_regen.png"),
	"mana_percent": preload("res://assets/skills/mana_regen.png"),
	"mana_regen": preload("res://assets/skills/mana_regen.png"), "cooldown_reduction": preload("res://assets/skills/node_combo.png"),
	"armor": preload("res://assets/items/chainmail.png"), "armor_percent": preload("res://assets/items/chainmail.png"),
	"dodge_chance": preload("res://assets/skills/flicker.png"),
	"multishot_arrows": preload("res://assets/skills/multishot.png"), "multishot_damage": preload("res://assets/skills/multishot.png"),
	"rain_damage": preload("res://assets/skills/arrow_rain.png"), "rain_area": preload("res://assets/skills/arrow_rain.png"),
	"seeker_hits": preload("res://assets/skills/seeker.png"), "falcon_damage": preload("res://assets/skills/falcon.png"),
	"wind_damage": preload("res://assets/skills/wind_arrow.png"), "power_charge": preload("res://assets/skills/power_shot.png"),
	"power_damage": preload("res://assets/skills/power_shot.png"), "arrow_pierce": preload("res://assets/skills/node_pierce.png"),
	"arrow_range": preload("res://assets/skills/node_range.png"), "ballista_damage": preload("res://assets/skills/ballista.png"),
	"ballista_time": preload("res://assets/skills/ballista.png"), "snare_time": preload("res://assets/skills/snare.png"),
	"venom_damage": preload("res://assets/skills/venom_arrows.png"), "vault_cooldown": preload("res://assets/skills/vault.png"),
	"fireball_charge": preload("res://assets/skills/fireball.png"), "fireball_damage": preload("res://assets/skills/fireball.png"),
	"burn_damage": preload("res://assets/skills/meteor.png"), "meteor_radius": preload("res://assets/skills/meteor.png"),
	"shield_share": preload("res://assets/skills/mana_shield.png"), "blink_cooldown": preload("res://assets/skills/blink.png"),
	"rune_bonus": preload("res://assets/skills/rune_stone.png"), "chain_targets": preload("res://assets/skills/chain_lightning.png"),
	"storm_time": preload("res://assets/skills/storm_call.png"), "orb_damage": preload("res://assets/skills/ball_lightning.png"),
	"lance_damage": preload("res://assets/skills/frost_lance.png"), "chill_time": preload("res://assets/skills/blizzard.png"),
	"lance_pierce": preload("res://assets/skills/frost_lance.png"), "blizzard_damage": preload("res://assets/skills/blizzard.png"),
	"blizzard_time": preload("res://assets/skills/blizzard.png"),
	"strength": preload("res://assets/ui/tags/str.png"), "dexterity": preload("res://assets/ui/tags/dex.png"),
	"intelligence": preload("res://assets/ui/tags/int.png"), "area_damage": preload("res://assets/ui/tags/area.png"),
	"hit_damage": preload("res://assets/ui/tags/hit.png"), "projectile_damage": preload("res://assets/ui/tags/projectile.png"),
	"fire_damage": preload("res://assets/ui/tags/fire.png"), "cold_damage": preload("res://assets/ui/tags/ice.png"),
	"lightning_damage": preload("res://assets/ui/tags/lightning.png"), "elemental_damage": preload("res://assets/ui/tags/arcane.png"),
	"fire_resistance": preload("res://assets/ui/tags/fire.png"), "cold_resistance": preload("res://assets/ui/tags/ice.png"),
	"lightning_resistance": preload("res://assets/ui/tags/lightning.png"), "nawia_resistance": preload("res://assets/ui/tags/arcane.png"),
	"all_resistances": preload("res://assets/ui/tags/arcane.png"), "shock_chance": preload("res://assets/ui/tags/lightning.png"),
	"resistance_penetration": preload("res://assets/skills/node_pierce.png"),
}
const KEYSTONE_ICONS := {"cyclone_eye": preload("res://assets/skills/ks_cyclone_eye.png"),
		"blade_dance": preload("res://assets/skills/ks_blade_dance.png"), "smoke_shadow": preload("res://assets/skills/ks_smoke_shadow.png"),
		"blood_frenzy": preload("res://assets/skills/ks_blood_frenzy.png"),
		"falcon_eye": preload("res://assets/skills/ks_falcon_eye.png"), "hail": preload("res://assets/skills/ks_hail.png"),
		"shadow_hunter": preload("res://assets/skills/ks_shadow_hunter.png"), "running_fire": preload("res://assets/skills/ks_running_fire.png"),
		"harmony": preload("res://assets/skills/ks_harmony.png"), "blood_sacrifice": preload("res://assets/skills/ks_blood_sacrifice.png"),
		"full_power": preload("res://assets/skills/ks_full_power.png"), "echo_runes": preload("res://assets/skills/ks_echo_runes.png"),
		"last_bastion": preload("res://assets/skills/ks_last_bastion.png")}
## Ikony pustych miejsc: aura i umiejętność wg tagów (tag "aura" albo forma), węzeł - wg rodzaju.
const SOON_ICONS := {"aura": preload("res://assets/ui/tags/aura.png"), "skill": preload("res://assets/ui/tags/attack.png"),
		"keystone": preload("res://assets/ui/tags/arcane.png"), "passive": preload("res://assets/ui/tags/arcane.png")}

var selected_id := ""
var _player: Player
var _hover := ""
## Przesunięcie i przybliżenie widoku (przeciąganie, kółko myszy) oraz czy właśnie przeciągamy.
var _offset := Vector2.ZERO
var _zoom := START_ZOOM
var _panning := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func setup(player: Player) -> void:
	_player = player
	queue_redraw()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()  # pulsowanie węzłów możliwych do wybrania


func node_position(id: String) -> Vector2:
	return _to_screen(SkillTree.node(id)["pos"])


func _to_screen(pos: Vector2) -> Vector2:
	return size / 2.0 + _offset + pos * UNIT * _zoom


## Rodzaj węzła do rysowania: start, skill, notable, small, keystone, socket.
func shape_of(id: String) -> String:
	var node := SkillTree.node(id)
	if node["kind"] == "passive":
		return "notable" if node.get("notable", false) else "small"
	return node["kind"]


func radius_of(id: String) -> float:
	return RADIUS[shape_of(id)] * clampf(_zoom / START_ZOOM, 0.45, 1.3)


func node_at(point: Vector2) -> String:
	var best := ""
	var best_distance := INF
	for id: String in SkillTree.nodes():
		var distance := node_position(id).distance_to(point)
		if distance <= maxf(radius_of(id), 4.0) + 2.0 and distance < best_distance:
			best = id
			best_distance = distance
	return best


func icon_of(id: String) -> Texture2D:
	var node := SkillTree.node(id)
	if node.get("soon", false):
		return SOON_ICONS["aura"] if node.get("aura", false) else SOON_ICONS.get(node["kind"], SOON_ICONS["passive"])
	match node["kind"]:
		"start":
			return Hotbar.ATTACK_ICON
		"skill":
			return Skills.get_data(node["skill"])["icon"]
		"keystone":
			return KEYSTONE_ICONS.get(id, Hotbar.ATTACK_ICON)
		"socket":
			var gem := _player.skills.gem_in(id) if _player != null else {}
			if gem.has("essence"):
				return Essences.ICONS.get(gem.get("group", ""), SOCKET_LEGEND_ICON)
			if not gem.is_empty():
				return Gems.icon_of(gem)
			return SOCKET_LEGEND_ICON if node.get("legendary", false) else Gems.SOCKET_ICON
	var stats: Dictionary = node.get("stats", {})
	return ICONS.get(stats.keys()[0], ICONS["physical_damage"]) if not stats.is_empty() else ICONS["physical_damage"]


func _region_color(id: String) -> Color:
	var region: String = SkillTree.node(id).get("region", "")
	return SkillTreeData.REGIONS[region]["color"] if SkillTreeData.REGIONS.has(region) else Color(0.6, 0.6, 0.65)


func _draw() -> void:
	if _player == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), UiStyle.SLOT_BG)
	_draw_regions()
	var tree := SkillTree.nodes()
	var book := _player.skills
	var reached := book.reachable()
	# połączenia
	for id: String in tree:
		for link: String in tree[id]["links"]:
			var both := book.has_node_id(id) and book.has_node_id(link)
			draw_line(node_position(id), node_position(link), GOLD if both else LINK, 2.0 if both else 1.0)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	# zasięg kamieni promienia (wzmocnione węzły pasywne - turkusowe kropki)
	for id: String in book.tree_gems:
		if book.gem_in(id).get("kind", "") == "radius" and book.has_node_id(id):
			var reach := SkillBook.RADIUS_RANGE * UNIT * _zoom
			draw_circle(node_position(id), reach, Color(0.37, 0.88, 0.82, 0.07))
			draw_arc(node_position(id), reach, 0.0, TAU, 64, Color(0.37, 0.88, 0.82, 0.55), 1.0)
	var points := book.points_left() > 0
	var font := get_theme_default_font()
	for id: String in tree:
		var node: Dictionary = tree[id]
		var center := node_position(id)
		var radius := radius_of(id)
		if not Rect2(Vector2.ZERO, size).grow(radius + 4.0).has_point(center):
			continue
		var shape := shape_of(id)
		var soon: bool = node.get("soon", false)
		var taken := book.has_node_id(id)
		var open := not taken and not soon and SkillTree.neighbors(id).any(func(other: String) -> bool: return reached.has(other))
		var can := open and points
		if shape == "small" and not soon:
			var dot := _region_color(id)
			draw_circle(center, radius + 1.0, Color(0.06, 0.06, 0.1))
			draw_circle(center, radius, dot if taken else dot.darkened(0.25) if can else dot.darkened(0.65))
			if taken:
				draw_arc(center, radius + 1.0, 0.0, TAU, 16, GOLD, 1.5)
			elif can:
				draw_arc(center, radius + 1.0, 0.0, TAU, 16, Color(0.85, 0.9, 1.0, 0.45 + 0.5 * pulse), 1.0)
		else:
			draw_circle(center, radius + 1.5, Color(0.06, 0.06, 0.1))
			var icon := icon_of(id)
			var box := Rect2(center - Vector2.ONE * (radius - 1.0), Vector2.ONE * (radius - 1.0) * 2.0)
			var tint := Color(0.3, 0.3, 0.36, 0.6) if soon else Color.WHITE if taken else Color(0.75, 0.75, 0.8) if can \
					else Color(0.4, 0.4, 0.48)
			draw_texture_rect(icon, box, false, tint)
			var ring := GOLD if taken else Color(0.85, 0.9, 1.0, 0.45 + 0.5 * pulse) if can else Color(0.3, 0.3, 0.38)
			if shape == "skill" and not taken and not can:
				var weapon := SkillTree.weapon_of(id)
				ring = (SkillTree.WEAPON_COLORS.get(weapon, ring) as Color).darkened(0.35)
			if shape == "keystone":
				ring = Color(1.0, 0.6, 0.25) if taken else ring
			elif shape == "socket" and node.get("legendary", false):
				ring = LEGEND_RING if taken else ring
			if soon:
				_draw_dashed_ring(center, radius + 1.0, Color(0.6, 0.6, 0.7, 0.6))
			else:
				draw_arc(center, radius + 1.0, 0.0, TAU, 32, ring, 2.0 if taken or shape == "keystone" else 1.5)
			if node.get("aura", false):
				draw_arc(center, radius + 3.0, 0.0, TAU, 32, Color(0.8, 0.8, 0.9, 0.35), 1.0)
		if id == selected_id:
			draw_arc(center, radius + 4.0, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 1.0)
		elif id == _hover:
			draw_arc(center, radius + 3.0, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 1.0)
		if node["kind"] == "passive" and taken and book.radius_factor(id) > 1.0:
			draw_circle(center + Vector2(radius - 1.0, -radius + 1.0), 2.0, Color(0.37, 0.88, 0.82))
		# poziom umiejętności pod węzłem
		if node.has("skill") and taken:
			var level := book.level_of(node["skill"])
			draw_string(font, center + Vector2(radius - 2.0, radius + 2.0), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, GOLD)
	_draw_cluster_labels(font)


## Tło stron drzewka: kliny w kolorach stron (siła, zręczność, inteligencja i strefy pośrednie) i ich nazwy.
func _draw_regions() -> void:
	var origin := _to_screen(Vector2.ZERO)
	var reach := REGION_REACH * UNIT * _zoom
	var font := get_theme_default_font()
	for region: String in SkillTreeData.REGIONS:
		var data: Dictionary = SkillTreeData.REGIONS[region]
		var angle := deg_to_rad(float(data["angle"]))
		var color: Color = data["color"]
		var points := PackedVector2Array([origin])
		for step in 13:
			points.append(origin + Vector2.from_angle(angle - PI / 6.0 + step * PI / 36.0) * reach)
		draw_colored_polygon(points, Color(color, 0.09))
		var at := origin + Vector2.from_angle(angle) * reach * 0.93
		var name := Lang.t(data["name"])
		var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_string_outline(font, at - Vector2(width / 2.0, -3.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UiStyle.OUTLINE)
		draw_string(font, at - Vector2(width / 2.0, -3.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color.lightened(0.2))


## Nazwy skupisk przy większym przybliżeniu.
func _draw_cluster_labels(font: Font) -> void:
	if _zoom < LABEL_ZOOM:
		return
	for cluster: String in SkillTreeData.CLUSTERS:
		var data: Dictionary = SkillTreeData.CLUSTERS[cluster]
		var at := _to_screen(data["center"])
		var name := Lang.t(data["name"])
		var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_string_outline(font, at - Vector2(width / 2.0, -2.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, UiStyle.OUTLINE)
		draw_string(font, at - Vector2(width / 2.0, -2.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.92, 0.86, 0.66, 0.85))


func _draw_dashed_ring(center: Vector2, radius: float, color: Color) -> void:
	for step in 8:
		var from := step * TAU / 8.0
		draw_arc(center, radius, from, from + TAU / 16.0, 4, color, 1.0)


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _panning:
			_offset += motion.relative
			_clamp_offset()
			accept_event()
			return
		var hover := node_at(motion.position)
		if hover != _hover:
			_hover = hover
			queue_redraw()
		return
	var click := event as InputEventMouseButton
	if click == null:
		return
	if click.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and click.pressed:
		var before := _zoom
		_zoom = clampf(_zoom * (1.1 if click.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1), ZOOM_RANGE.x, ZOOM_RANGE.y)
		# przybliżanie wokół kursora
		var anchor := click.position - size / 2.0
		_offset = anchor - (anchor - _offset) * (_zoom / before)
		_clamp_offset()
		accept_event()
		return
	if click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
		var refunded := node_at(click.position)
		if refunded != "":
			refund_requested.emit(refunded)
			accept_event()
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	if not click.pressed:
		_panning = false
		return
	var id := node_at(click.position)
	if id != "":
		selected_id = id
		selected.emit(id)
		Sfx.play("ui_click")
		queue_redraw()
	else:
		_panning = true
	accept_event()


## Drzewko nie ucieka całkiem poza widok.
func _clamp_offset() -> void:
	var limit := Vector2.ONE * REGION_REACH * UNIT * _zoom
	_offset = _offset.clamp(-limit, limit)
	queue_redraw()


## Ustawia widok na węźle (testy, zrzuty ekranu).
func focus(id: String, zoom := START_ZOOM) -> void:
	_zoom = clampf(zoom, ZOOM_RANGE.x, ZOOM_RANGE.y)
	_offset = -SkillTree.node(id)["pos"] * UNIT * _zoom
	_clamp_offset()


## Dymek rozumie BBCode - tagi umiejętności z ikonkami (Skills.tags_bbcode).
func _make_custom_tooltip(for_text: String) -> Object:
	return RichTooltip.build(self, for_text)


func _get_tooltip(at_position: Vector2) -> String:
	var id := node_at(at_position)
	return describe(id) if id != "" else ""


## Opis węzła do dymku i panelu szczegółów (BBCode - linia tagów z ikonkami).
func describe(id: String) -> String:
	var node := SkillTree.node(id)
	var lines: Array[String] = [SkillTree.node_name(id)]
	if node.get("soon", false):
		lines[0] += tr("  (wkrótce)")
		lines.append(SkillTree.node_description(id))
		lines.append(tr("Puste miejsce na nową umiejętność, aurę albo węzeł z kolejnych etapów rozwoju gry. Na razie nie da się go wybrać, ale drzewko przechodzi przez nie za darmo."))
		return "\n".join(lines)
	match node["kind"]:
		"skill":
			var skill: String = node["skill"]
			lines[0] += "  (%s)" % Skills.mana_cost_text(skill)
			lines.append(Skills.tags_bbcode(Skills.tags(skill)))
			lines.append(Skills.description_of(skill))
			var weapon: String = Skills.get_data(skill)["weapon"]
			if AuraData.is_aura(skill):
				lines.append(tr("Aura - działa z każdą bronią. Połóż ją na pasku i naciśnij klawisz, żeby włączyć albo wyłączyć."))
			elif _player != null and _player.stats.weapon_type() != weapon:
				lines.append("[color=#ff9a7a]%s[/color]" % (tr("Działa tylko z bronią: %s.") % Skills.weapon_name(weapon)))
		"passive":
			# węzeł znaczący z opisem (premia zmienia działanie, a nie liczbę) - opis zamiast listy premii
			if node.has("description"):
				lines.append(SkillTree.node_description(id))
			elif node.has("name"):
				lines.append(SkillTree.stats_text(node.get("stats", {})))
			else:
				lines.push_front(tr("Drobny węzeł"))
		"keystone":
			lines[0] += tr("  (węzeł kluczowy)")
			lines.append(SkillTree.node_description(id))
		"start":
			lines.append(SkillTree.node_description(id))
		"socket":
			if node.get("legendary", false):
				lines[0] += tr("  (gniazdo legendarne)")
			var gem := _player.skills.gem_in(id) if _player != null else {}
			if gem.has("essence"):
				lines.append(Essences.plain_text(gem))
			else:
				lines.append(Gems.plain_text(gem) if not gem.is_empty() else
						tr("Puste gniazdo na kamień szlachetny - jego premie są o połowę mocniejsze i działają z każdą bronią."))
			if node.get("legendary", false):
				lines.append(tr("Przyjmie też esencję legendy - jej efekt działa z każdą bronią."))
			if _player != null and _player.skills.has_node_id(id):
				lines.append(tr("Przeciągnij kamień z plecaka na gniazdo albo wybierz go obok."))
	if node["kind"] == "passive" and _player != null and _player.skills.radius_factor(id) > 1.0:
		lines.append(tr("Wzmocniony kamieniem promienia: +%d%%") % roundi((_player.skills.radius_factor(id) - 1.0) * 100.0))
	if _player != null and not _player.skills.has_node_id(id):
		lines.append(tr("Kliknij, a potem \"Wybierz\" (1 punkt).") if _player.skills.can_take(id)
				else tr("Wybierz najpierw sąsiedni węzeł.") if _player.skills.points_left() > 0 else tr("Brak punktów umiejętności."))
	elif _player != null and id != "start":
		lines.append(tr("Prawy przycisk myszy - cofnij węzeł (punkt wraca za %d zł).") % _player.skills.refund_gold())
	return "\n".join(lines)


## Umiejętność z wybranego węzła przeciąga się na pasek (dane jak z kart umiejętności: {"skill": id}).
func _get_drag_data(at_position: Vector2) -> Variant:
	var id := node_at(at_position)
	if id == "" or _player == null:
		return null
	var node := SkillTree.node(id)
	if node["kind"] == "start":
		set_drag_preview(UiStyle.drag_preview(Hotbar.ATTACK_ICON))
		return {"skill": Hotbar.ATTACK}
	if not node.has("skill") or not Hotbar.can_slot_skill(node["skill"]) or not _player.skills.has_node_id(id):
		return null
	set_drag_preview(UiStyle.drag_preview(Skills.get_data(node["skill"])["icon"]))
	Sfx.play("ui_click")
	return {"skill": node["skill"]}


func kind_of(id: String) -> String:
	return SkillTree.node(id).get("kind", "")


## Kamień z plecaka ({"inventory": Inventory, "index": i}) można upuścić na wybrane gniazdo.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if _player == null or not (data is Dictionary) or not data.has("inventory") or data["inventory"] != _player.inventory:
		return false
	var slot: Dictionary = _player.inventory.slots[data["index"]]
	var id := node_at(at_position)
	if slot.is_empty() or id == "":
		return false
	# kamień wsparcia na umiejętność z gniazdami (Supports)
	if Supports.is_support(slot["id"]):
		var node := SkillTree.node(id)
		return node.has("skill") and _player.skills.has_node_id(id) \
				and Supports.fits(Items.get_data(slot["id"])["support"]["kind"], node["skill"])
	if not _player.skills.can_socket(id):
		return false
	return Gems.is_gem(slot["id"]) or (Essences.is_essence(slot["id"]) and _player.skills.is_legendary_socket(id))


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var id := node_at(at_position)
	var message := ""
	if Supports.is_support(_player.inventory.slots[data["index"]].get("id", "")):
		message = _player.skills.support_socket_from(_player.inventory, SkillTree.node(id)["skill"], data["index"])
	else:
		message = _player.skills.socket_from(_player.inventory, id, data["index"])
	selected_id = id
	selected.emit(id)
	Sfx.play("ui_error" if message != "" else "pickup")
	gem_dropped.emit(message)
