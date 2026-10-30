class_name SkillTreeView
extends Control
## Sieć węzłów drzewka umiejętności broni (SkillTree) w oknie umiejętności. Węzły: umiejętności (ikona w kole),
## pasywne (małe koła), kluczowe (duże, złote) i start. Wybrane mają złotą obwódkę i złote połączenia, możliwe do
## wybrania teraz - pulsującą jasną, reszta jest przygaszona. Kliknięcie zaznacza węzeł (szczegóły i przyciski
## pokazuje okno umiejętności), dymek opisuje węzeł, a umiejętność z wybranego węzła (start - zwykły atak) przeciąga się
## na pasek.

signal selected(node_id: String)

## Ile pikseli interfejsu na jednostkę pozycji węzła i promienie węzłów wg rodzaju.
const UNIT := 21.0
const RADIUS := {"start": 9.0, "skill": 10.0, "passive": 6.5, "keystone": 12.0}
const GOLD := Color(1.0, 0.82, 0.35)
const LINK := Color(0.35, 0.36, 0.45)
const ICONS := {
	"physical_damage": preload("res://assets/skills/node_physical.png"), "attack_speed": preload("res://assets/skills/node_attack_speed.png"),
	"crit_chance": preload("res://assets/skills/node_crit.png"), "combo_window": preload("res://assets/skills/node_combo.png"),
	"spell_damage": preload("res://assets/skills/node_spell.png"), "cast_speed": preload("res://assets/skills/node_spell.png"),
	"whirl_radius": preload("res://assets/skills/whirlwind.png"), "flicker_mana": preload("res://assets/skills/flicker.png"),
	"smoke_charge": preload("res://assets/skills/smoke_burst.png"),
}
const KEYSTONE_ICONS := {"endless_whirl": preload("res://assets/skills/ks_endless_whirl.png")}

var weapon_type := "melee"
var selected_id := ""
var _player: Player
var _hover := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func setup(player: Player, weapon: String) -> void:
	_player = player
	weapon_type = weapon
	queue_redraw()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()  # pulsowanie węzłów możliwych do wybrania


func node_position(id: String) -> Vector2:
	return size / 2.0 + SkillTree.nodes(weapon_type)[id]["pos"] * UNIT


func node_at(point: Vector2) -> String:
	var tree := SkillTree.nodes(weapon_type)
	for id: String in tree:
		if node_position(id).distance_to(point) <= RADIUS[tree[id]["kind"]] + 2.0:
			return id
	return ""


func icon_of(id: String) -> Texture2D:
	var node: Dictionary = SkillTree.nodes(weapon_type)[id]
	match node["kind"]:
		"start":
			return Hotbar.ATTACK_ICON
		"skill":
			return Skills.get_data(node["skill"])["icon"]
		"keystone":
			return KEYSTONE_ICONS.get(id, Hotbar.ATTACK_ICON)
	var stats: Dictionary = node.get("stats", {})
	return ICONS.get(stats.keys()[0], ICONS["physical_damage"]) if not stats.is_empty() else ICONS["physical_damage"]


func _draw() -> void:
	if _player == null:
		return
	var tree := SkillTree.nodes(weapon_type)
	var book := _player.skills
	# połączenia
	for id: String in tree:
		for link: String in tree[id]["links"]:
			var both := book.has_node_id(weapon_type, id) and book.has_node_id(weapon_type, link)
			draw_line(node_position(id), node_position(link), GOLD if both else LINK, 2.0 if both else 1.5)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	for id: String in tree:
		var kind: String = tree[id]["kind"]
		var center := node_position(id)
		var radius: float = RADIUS[kind]
		var taken := book.has_node_id(weapon_type, id)
		var can := book.can_take(weapon_type, id)
		draw_circle(center, radius + 1.5, Color(0.06, 0.06, 0.1))
		var icon := icon_of(id)
		var box := Rect2(center - Vector2.ONE * (radius - 1.0), Vector2.ONE * (radius - 1.0) * 2.0)
		draw_texture_rect(icon, box, false, Color.WHITE if taken else Color(0.75, 0.75, 0.8) if can else Color(0.35, 0.35, 0.42))
		var ring := GOLD if taken else Color(0.85, 0.9, 1.0, 0.45 + 0.5 * pulse) if can else Color(0.3, 0.3, 0.38)
		if kind == "keystone":
			ring = Color(1.0, 0.6, 0.25) if taken else ring
		draw_arc(center, radius + 1.0, 0.0, TAU, 32, ring, 2.0 if taken or kind == "keystone" else 1.5)
		if id == selected_id:
			draw_arc(center, radius + 4.0, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 1.0)
		elif id == _hover:
			draw_arc(center, radius + 3.0, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 1.0)
		# poziom umiejętności pod węzłem
		if kind == "skill" and taken:
			var level := book.level_of(tree[id]["skill"])
			draw_string(get_theme_default_font(), center + Vector2(radius - 2.0, radius + 2.0), str(level),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 7, GOLD)


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var hover := node_at(motion.position)
		if hover != _hover:
			_hover = hover
			queue_redraw()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var id := node_at(click.position)
		if id != "":
			selected_id = id
			selected.emit(id)
			Sfx.play("ui_click")
			queue_redraw()
			accept_event()


func _get_tooltip(at_position: Vector2) -> String:
	var id := node_at(at_position)
	return describe(id) if id != "" else ""


## Opis węzła do dymku i panelu szczegółów.
func describe(id: String) -> String:
	var node: Dictionary = SkillTree.nodes(weapon_type)[id]
	var lines: Array[String] = [SkillTree.node_name(weapon_type, id)]
	match node["kind"]:
		"skill":
			var skill: String = node["skill"]
			var tags := Skills.tags_text(skill)
			lines[0] += ("  (%s  •  %s)" % [tags, Skills.mana_cost_text(skill)]) if tags != "" else "  (umiejętność pasywna)"
			lines.append(Skills.get_data(skill)["description"])
		"passive":
			lines.append(SkillTree.stats_text(node.get("stats", {})))
		"keystone":
			lines[0] += "  (węzeł kluczowy)"
			lines.append(node["description"])
		"start":
			lines.append(node["description"])
	if _player != null and not _player.skills.has_node_id(weapon_type, id):
		lines.append("Kliknij, a potem \"Wybierz\" (1 punkt)." if _player.skills.can_take(weapon_type, id)
				else "Wybierz najpierw sąsiedni węzeł." if _player.skills.points_left() > 0 else "Brak punktów umiejętności.")
	return "\n".join(lines)


## Umiejętność z wybranego węzła przeciąga się na pasek (dane jak z kart umiejętności: {"skill": id}).
func _get_drag_data(at_position: Vector2) -> Variant:
	var id := node_at(at_position)
	if id == "" or _player == null:
		return null
	var node: Dictionary = SkillTree.nodes(weapon_type)[id]
	if node["kind"] == "start":
		set_drag_preview(UiStyle.drag_preview(Hotbar.ATTACK_ICON))
		return {"skill": Hotbar.ATTACK}
	if node["kind"] != "skill" or not Hotbar.can_slot_skill(node["skill"]) or not _player.skills.has_node_id(weapon_type, id):
		return null
	set_drag_preview(UiStyle.drag_preview(Skills.get_data(node["skill"])["icon"]))
	Sfx.play("ui_click")
	return {"skill": node["skill"]}
