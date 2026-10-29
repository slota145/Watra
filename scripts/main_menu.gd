extends Control
## Menu startowe: kontynuacja (najnowszy zapis), nowa gra (z wyborem jednej z czterech postaci),
## wczytanie dowolnego zapisu z listy i wyjście.
## W tle rysuje leśną polanę z ogniskiem i goblinami.

const TILES := preload("res://assets/tiles.png")
const TREES: Array[Texture2D] = [
	preload("res://assets/tree_oak_0.png"),
	preload("res://assets/tree_oak_1.png"),
	preload("res://assets/tree_oak_2.png"),
	preload("res://assets/tree_pine.png"),
]
const CAMPFIRE := preload("res://assets/campfire.png")
const GOBLIN := preload("res://assets/goblin.png")
const TILE := 16
const BACKGROUND_SEED := 7

var _time := 0.0
var _menu: VBoxContainer
var _heroes: VBoxContainer
## Podglądy postaci w oknie wyboru (chodzą w miejscu) - [AtlasTexture, id postaci].
var _hero_previews: Array = []


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animacje menu idą w _process
	Sfx.stop_ambient()
	theme = UiStyle.make_menu_theme()

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.1, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)
	_menu = box
	_heroes = _make_hero_picker()
	_heroes.visible = false
	center.add_child(_heroes)

	var title := UiStyle.title("Gobliński Las")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_constant_override("outline_size", 8)
	box.add_child(title)
	var subtitle := UiStyle.label("Wytnij ich wszystkich", 10, UiStyle.DIM_COLOR)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(Control.new())  # odstęp

	# "Kontynuuj" wczytuje najnowszy zapis; pod nim jego nazwa i opis
	var saves := Game.list_saves()
	var continue_button := UiStyle.menu_button("Kontynuuj", Game.continue_game)
	continue_button.disabled = saves.is_empty()
	box.add_child(continue_button)
	var save_info := UiStyle.label("%s
%s" % [saves[0].get("name", ""), Game.describe_save(saves[0])] if not saves.is_empty() else "Brak zapisów", 8, UiStyle.DIM_COLOR)
	save_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(save_info)
	var new_game := UiStyle.menu_button("Nowa gra", _show_heroes)
	box.add_child(new_game)
	var load_game := UiStyle.menu_button("Wczytaj grę", _show_saves)
	load_game.disabled = saves.is_empty()
	box.add_child(load_game)
	box.add_child(UiStyle.menu_button("Wyjdź z gry", Game.quit_game))

	(continue_button if not continue_button.disabled else new_game).grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# podglądy postaci: chód w stronę widza
	for entry: Array in _hero_previews:
		var atlas: AtlasTexture = entry[0]
		var frame := HeroRig.frame_index("walk", 0, int(_time * 6.0) % HeroRig.FRAMES)
		atlas.region = Rect2((frame % HeroRig.FRAMES) * HeroRig.CELL, (frame / HeroRig.FRAMES) * HeroRig.CELL, HeroRig.CELL, HeroRig.CELL)
	queue_redraw()


## Okno wyboru postaci do nowej gry: cztery postacie z PixelLab, chodzące w miejscu.
func _make_hero_picker() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := UiStyle.title("Wybierz postać")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for id: String in HeroRig.HEROES:
		var card := Button.new()
		card.custom_minimum_size = Vector2(96, 124)
		card.pressed.connect(Game.new_game.bind(id))
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(inner)
		var atlas := AtlasTexture.new()
		atlas.atlas = HeroRig.sheet(id)
		atlas.region = Rect2(0, 0, HeroRig.CELL, HeroRig.CELL)
		_hero_previews.append([atlas, id])
		var picture := TextureRect.new()
		picture.texture = atlas
		picture.custom_minimum_size = Vector2(HeroRig.CELL, HeroRig.CELL) * 1.3
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(picture)
		var name_label := UiStyle.label(HeroRig.NAMES[id], 10)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(name_label)
		row.add_child(card)
	var back := UiStyle.menu_button("Wróć", _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	return box


func _show_heroes() -> void:
	_menu.visible = false
	_heroes.visible = true
	(_heroes.get_child(1).get_child(0) as Button).grab_focus()


func _show_saves() -> void:
	var browser := SaveBrowser.new()
	browser.mode = "load"
	browser.closed.connect(func() -> void: (_menu.get_child(_menu.get_child_count() - 2) as Button).grab_focus())
	add_child(browser)


func _show_menu() -> void:
	_heroes.visible = false
	_menu.visible = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = BACKGROUND_SEED
	var cols := ceili(size.x / TILE) + 1
	var rows := ceili(size.y / TILE) + 1

	# trawa
	for y in rows:
		for x in cols:
			var atlas := Vector2(rng.randi() % 4, rng.randi() % 2)
			draw_texture_rect_region(TILES, Rect2(x * TILE, y * TILE, TILE, TILE), Rect2(atlas * TILE, Vector2(TILE, TILE)))

	# ognisko z goblinami pod napisami
	var fire := Vector2(size.x / 2.0, size.y - 40)
	var sprites: Array[Dictionary] = []
	for i in 5:
		var a := PI * 0.15 + PI * 0.7 * i / 4.0 + PI
		var pos := fire + Vector2.from_angle(a) * Vector2(26, 14)
		sprites.append({"pos": pos, "goblin": true, "flip": pos.x > fire.x, "frame": 4 + (int(_time * 1.5 + i) % 2)})
	sprites.append({"pos": fire, "fire": true})

	# drzewa po bokach - środek zostaje wolny na menu
	for i in 70:
		var pos := Vector2(rng.randf() * size.x, rng.randf() * (size.y + 30))
		var from_center := absf(pos.x - size.x / 2.0)
		if from_center < size.x * 0.26 and pos.y < size.y - 70:
			continue
		if pos.distance_to(fire) < 60:
			continue
		sprites.append({"pos": pos, "tree": TREES[rng.randi() % TREES.size()]})

	sprites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["pos"].y < b["pos"].y)
	for s in sprites:
		var pos: Vector2 = s["pos"]
		if s.has("tree"):
			var tex: Texture2D = s["tree"]
			draw_texture(tex, (pos - Vector2(tex.get_width() / 2.0, tex.get_height() - 4)).floor())
		elif s.has("fire"):
			var glow := 22.0 + sin(_time * 8.0) * 1.5
			draw_circle(pos + Vector2(0, -4), glow, Color(1, 0.6, 0.2, 0.12))
			var frame := int(_time * 8.0) % 4
			draw_texture_rect_region(CAMPFIRE, Rect2(pos - Vector2(8, 14), Vector2(16, 16)), Rect2(frame * 16, 0, 16, 16))
		else:
			var frame: int = s["frame"]
			var src := Rect2((frame % 4) * 16, 16 if frame >= 4 else 0, 16, 16)
			# lustrzane odbicie goblinów po prawej stronie ogniska
			draw_set_transform(pos, 0.0, Vector2(-1, 1) if s["flip"] else Vector2.ONE)
			draw_texture_rect_region(GOBLIN, Rect2(-8, -15, 16, 16), src)
			draw_set_transform(Vector2.ZERO)
