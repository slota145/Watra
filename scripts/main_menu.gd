extends Control
## Menu startowe: kontynuacja (najnowszy zapis), nowa gra (z wyborem jednej z czterech postaci),
## wczytanie dowolnego zapisu z listy i wyjście.
## W tle: świt nad Ostoją (grafika z PixelLab, tools/menu_art.py) ożywiona w grze - mgła płynie dolinami,
## z kominów idzie dym, watra w osadzie migocze i sypie iskrami, słońce pulsuje poświatą z promieniami,
## w świetle unoszą się drobinki, czasem przelatuje klucz ptaków, a całe tło lekko podąża za myszą.

const BACKGROUND := preload("res://assets/menu/background.png")
const LOGO := preload("res://assets/menu/logo.png")
const LOGO_SHADER := preload("res://shaders/logo_flames.gdshader")
const BG_SIZE := Vector2(640, 360)
## Punkty na grafice tła (piksele): słońce, watra i kominy osady.
const SUN := Vector2(300, 112)
const WATRA := Vector2(336, 246)
const CHIMNEYS: Array[Vector2] = [Vector2(278, 196), Vector2(374, 186), Vector2(392, 206)]
## Jak daleko tło przesuwa się za myszą (piksele grafiki).
const PARALLAX := 5.0
const PAN_SHADER := preload("res://shaders/menu_pan.gdshader")
const SUBTITLE := "Dopóki płonie ogień, Ostoja trwa"

var _time := 0.0
var _scene: Node2D
## Scena tła rysuje się do obrazu w rozmiarze grafiki, a na ekran trafia przez shader (płynne przesuwanie).
var _viewport: SubViewport
var _view: TextureRect
var _birds_layer: Node2D
var _pan := Vector2.ZERO
var _sun_glow: Sprite2D
var _rays: Array[Sprite2D] = []
var _fire_glow: Sprite2D
var _mists: Array[Sprite2D] = []
var _birds := []
var _bird_timer := 3.0
var _title: TextureRect
var _subtitle: Label
var _menu: VBoxContainer
var _heroes: VBoxContainer
## Podglądy postaci w oknie wyboru (chodzą w miejscu) - [AtlasTexture, id postaci].
var _hero_previews: Array = []


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # animacje menu idą w _process
	Sfx.stop_ambient()
	Sfx.play_music("menu")
	theme = UiStyle.make_menu_theme()

	_build_scene()

	# logo: płonący napis "WATRA" u góry, nad niebem (płomienie migoczą - shaders/logo_flames.gdshader)
	var logo := Control.new()
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	_title = TextureRect.new()
	_title.texture = LOGO
	_title.position = Vector2(-LOGO.get_width() / 2.0, 6)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flames := ShaderMaterial.new()
	flames.shader = LOGO_SHADER
	_title.material = flames
	logo.add_child(_title)
	var subtitle := UiStyle.label(Lang.t(SUBTITLE), 9, Color(1.0, 0.92, 0.78))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(-150, _title.position.y + LOGO.get_height() + 1)
	subtitle.size = Vector2(300, 14)
	logo.add_child(subtitle)
	_subtitle = subtitle

	# przyciski po lewej, na ciemnym lesie - osada w środku zostaje odsłonięta
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiStyle.panel(Color(0.06, 0.05, 0.08, 0.72), Color(0.42, 0.3, 0.16), 8))
	side.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	side.position = Vector2(22, -46)
	add_child(side)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	side.add_child(box)
	_menu = box

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_heroes = _make_hero_picker()
	_heroes.visible = false
	center.add_child(_heroes)

	# "Kontynuuj" wczytuje najnowszy zapis; pod nim jego nazwa i opis
	var saves := Game.list_saves()
	var continue_button := UiStyle.menu_button(Lang.t("Kontynuuj"), Game.continue_game)
	continue_button.disabled = saves.is_empty()
	box.add_child(continue_button)
	var save_info := UiStyle.label("%s
%s" % [saves[0].get("name", ""), Game.describe_save(saves[0])] if not saves.is_empty() else Lang.t("Brak zapisów"), 8, UiStyle.DIM_COLOR)
	save_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(save_info)
	var new_game := UiStyle.menu_button(Lang.t("Nowa gra"), _show_heroes)
	box.add_child(new_game)
	var load_game := UiStyle.menu_button(Lang.t("Wczytaj grę"), _show_saves)
	load_game.disabled = saves.is_empty()
	box.add_child(load_game)
	box.add_child(UiStyle.menu_button(Lang.t("Ustawienia"), _show_settings))
	box.add_child(UiStyle.menu_button(Lang.t("Wyjdź z gry"), Game.quit_game))

	(continue_button if not continue_button.disabled else new_game).grab_focus()


func _process(delta: float) -> void:
	_time += delta
	_animate_scene(delta)
	# podglądy postaci: chód w stronę widza
	for entry: Array in _hero_previews:
		var atlas: AtlasTexture = entry[0]
		var frame := HeroRig.frame_index("walk", 0, int(_time * 6.0) % HeroRig.frames(HeroRig.HEROES[0], "walk"))
		atlas.region = Rect2((frame % HeroRig.FRAMES) * HeroRig.CELL, (frame / HeroRig.FRAMES) * HeroRig.CELL, HeroRig.CELL, HeroRig.CELL)


## Okno wyboru postaci do nowej gry: cztery postacie z PixelLab, chodzące w miejscu.
func _make_hero_picker() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := UiStyle.title(Lang.t("Wybierz postać"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for id: String in HeroRig.HEROES:
		var card := Button.new()
		card.custom_minimum_size = Vector2(96, 124)
		card.pressed.connect(_show_modes.bind(id))
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
	var back := UiStyle.menu_button(Lang.t("Wróć"), _show_menu)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	return box


## Po wyborze bohatera: tryb świata (WorldModes) z wyjaśnieniem, potem nowa gra.
func _show_modes(hero_id: String) -> void:
	_heroes.visible = false
	var panel := PanelContainer.new()
	panel.theme = UiStyle.make_theme()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 0.92)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var picker := WorldModePicker.new()
	picker.current = Game.world_mode
	picker.chosen.connect(func(mode: String) -> void:
		Game.world_mode = mode
		Game.new_game(hero_id))
	box.add_child(picker)
	var back := UiStyle.menu_button(Lang.t("Wróć"), func() -> void:
		panel.queue_free()
		_show_heroes())
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
	_heroes.get_parent().add_child(panel)


func _show_heroes() -> void:
	_menu.get_parent().visible = false
	_subtitle.visible = false
	_heroes.visible = true
	(_heroes.get_child(1).get_child(0) as Button).grab_focus()


func _show_saves() -> void:
	var browser := SaveBrowser.new()
	browser.mode = "load"
	browser.closed.connect(func() -> void: (_menu.get_child(_menu.get_child_count() - 2) as Button).grab_focus())
	add_child(browser)


func _show_settings() -> void:
	var settings := SettingsWindow.new()
	var language := Game.language
	settings.closed.connect(func() -> void:
		# po zmianie języka menu buduje się od nowa, żeby napisy składane w kodzie też się zmieniły
		if Game.language != language:
			get_tree().reload_current_scene.call_deferred()
			return
		(_menu.get_child(_menu.get_child_count() - 2) as Button).grab_focus())
	add_child(settings)


func _show_menu() -> void:
	_heroes.visible = false
	_menu.get_parent().visible = true
	_subtitle.visible = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _view != null:
		_fit_scene()


# ---------------------------------------------------------------- tło
func _build_scene() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(BG_SIZE)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	_scene = Node2D.new()
	_viewport.add_child(_scene)
	_view = TextureRect.new()
	_view.texture = _viewport.get_texture()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_SCALE
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = PAN_SHADER
	_view.material = material
	add_child(_view)
	move_child(_view, 0)
	var bg := Sprite2D.new()
	bg.texture = BACKGROUND
	bg.centered = false
	_scene.add_child(bg)
	# promienie i poświata słońca (dodawane światło)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 5:
		var ray := Sprite2D.new()
		ray.texture = _beam_texture()
		ray.material = add
		ray.position = SUN
		ray.offset = Vector2(0, 90)
		ray.rotation = deg_to_rad(-55.0 + i * 27.0 + randf_range(-6, 6))
		ray.modulate = Color(1.0, 0.85, 0.6, 0.0)
		_scene.add_child(ray)
		_rays.append(ray)
	_sun_glow = _glow_sprite(Color(1.0, 0.82, 0.55, 0.55), 150, add)
	_sun_glow.position = SUN
	_scene.add_child(_sun_glow)
	# mgła płynąca dolinami (dwa pasma, różna prędkość)
	for band: Array in [[Vector2(0, 150), 70, 0.32], [Vector2(0, 268), 80, 0.26]]:
		var mist := Sprite2D.new()
		mist.texture = _mist_texture(band[1])
		mist.centered = false
		mist.region_enabled = true
		mist.region_rect = Rect2(0, 0, BG_SIZE.x, band[1])
		mist.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		mist.position = band[0]
		mist.modulate.a = band[2]
		_scene.add_child(mist)
		_mists.append(mist)
	# dym z kominów i z watry
	for chimney in CHIMNEYS:
		_scene.add_child(_smoke(chimney, 6, 0.35))
	_scene.add_child(_smoke(WATRA + Vector2(0, -6), 10, 0.25))
	# watra: migocząca poświata i iskry
	_fire_glow = _glow_sprite(Color(1.0, 0.55, 0.2, 0.7), 46, add)
	_fire_glow.position = WATRA + Vector2(0, -4)
	_scene.add_child(_fire_glow)
	_scene.add_child(_embers())
	_scene.add_child(_motes())
	_birds_layer = Node2D.new()
	_birds_layer.draw.connect(_draw_birds)
	_scene.add_child(_birds_layer)
	_fit_scene()


## Tło wypełnia ekran (zachowując proporcje, z zapasem na ruch za myszą): shader pokazuje wycinek obrazu.
func _fit_scene() -> void:
	var scale := maxf(size.x / BG_SIZE.x, size.y / BG_SIZE.y) * (1.0 + PARALLAX * 2.0 / BG_SIZE.x)
	(_view.material as ShaderMaterial).set_shader_parameter("visible", size / (BG_SIZE * scale))


func _animate_scene(delta: float) -> void:
	if _scene == null:
		return
	# lekki ruch za myszą (wycinek przesuwa się w stronę kursora - tło odpływa w przeciwną), płynnie
	var mouse := ((get_local_mouse_position() / size - Vector2(0.5, 0.5)) * 2.0).clamp(Vector2(-1, -1), Vector2.ONE)
	var visible: Vector2 = (_view.material as ShaderMaterial).get_shader_parameter("visible")
	var target := mouse * (Vector2.ONE - visible) / 2.0
	_pan = _pan.lerp(target, 1.0 - exp(-delta * 3.0))
	(_view.material as ShaderMaterial).set_shader_parameter("shift", _pan)
	_sun_glow.scale = Vector2.ONE * (1.0 + sin(_time * 0.6) * 0.05)
	for i in _rays.size():
		_rays[i].modulate.a = 0.07 + 0.06 * sin(_time * 0.35 + i * 1.7)
	_fire_glow.modulate.a = 0.75 + sin(_time * 9.0) * 0.08 + sin(_time * 23.0) * 0.05
	_fire_glow.scale = Vector2.ONE * (1.0 + sin(_time * 7.0) * 0.04)
	for i in _mists.size():
		_mists[i].region_rect.position.x = _time * (6.0 + i * 4.0)
	_update_birds(delta)
	_birds_layer.queue_redraw()


## Klucz ptaków przelatuje co jakiś czas po niebie (rysowany w _draw w przestrzeni tła).
func _update_birds(delta: float) -> void:
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = randf_range(9.0, 18.0)
		var y := randf_range(30, 90)
		var flock := []
		for k in randi_range(3, 6):
			flock.append(Vector2(-k * randf_range(9, 13), y + absf(k - 2) * 5.0 + randf_range(-2, 2)))
		_birds.append({"points": flock, "speed": randf_range(18, 26), "phase": randf() * TAU})
	for bird: Dictionary in _birds:
		var points: Array = bird["points"]
		for k in points.size():
			points[k] += Vector2(bird["speed"] * delta, -bird["speed"] * 0.12 * delta)
	_birds = _birds.filter(func(b: Dictionary) -> bool: return (b["points"][0] as Vector2).x < BG_SIZE.x + 80)


func _draw_birds() -> void:
	for bird: Dictionary in _birds:
		for k in bird["points"].size():
			var p: Vector2 = (bird["points"][k] as Vector2).floor()
			var up := sin(_time * 8.0 + bird["phase"] + k) > 0.0
			var c := Color(0.16, 0.12, 0.18, 0.85)
			_birds_layer.draw_rect(Rect2(p, Vector2.ONE), c)
			for side in [-1.0, 1.0]:
				_birds_layer.draw_rect(Rect2(p + Vector2(side, -1.0 if up else 0.0), Vector2.ONE), c)
				_birds_layer.draw_rect(Rect2(p + Vector2(side * 2.0, -2.0 if up else 1.0), Vector2.ONE), c)


func _glow_sprite(color: Color, radius: int, material: Material) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = radius * 2
	texture.height = radius * 2
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)  # promień do brzegu tekstury - bez widocznych krawędzi kwadratu
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.material = material
	return sprite


## Smuga światła: wąska u słońca, rozszerza się w dół, miękka z boków i wygaszona na końcu.
func _beam_texture() -> Texture2D:
	var image := Image.create(40, 180, false, Image.FORMAT_RGBA8)
	for y in 180:
		var t := y / 180.0
		var half := 3.0 + t * 17.0
		for x in 40:
			var d := absf(x - 19.5) / half
			if d < 1.0:
				var a := (1.0 - d * d) * sin(t * PI) * 0.9
				image.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(image)


## Bezszwowa mgła: miękki szum, przezroczysta u góry i dołu pasma.
func _mist_texture(height: int) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var image := noise.get_seamless_image(int(BG_SIZE.x), height)
	image.convert(Image.FORMAT_RGBA8)
	for y in height:
		var edge := sin(float(y) / height * PI)
		for x in int(BG_SIZE.x):
			var v := image.get_pixel(x, y).r
			image.set_pixel(x, y, Color(0.92, 0.9, 0.95, clampf((v - 0.35) * 2.2, 0.0, 1.0) * edge))
	return ImageTexture.create_from_image(image)


func _smoke(at: Vector2, amount: int, alpha: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = amount
	p.lifetime = 4.5
	p.direction = Vector2.UP
	p.spread = 12.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector2(2.5, -1.0)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.85, 0.82, 0.86, alpha), Color(0.8, 0.78, 0.85, 0.0)])
	p.color_ramp = ramp
	return p


func _embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = WATRA + Vector2(0, -4)
	p.amount = 14
	p.lifetime = 1.8
	p.direction = Vector2.UP
	p.spread = 25.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 18.0
	p.gravity = Vector2(1.5, -4.0)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 1.0), Color(1.0, 0.4, 0.1, 0.0)])
	p.color_ramp = ramp
	return p


## Drobinki kurzu i pyłku w porannym świetle - wolno dryfują po całym ekranie.
func _motes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = BG_SIZE / 2.0
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = BG_SIZE / 2.0
	p.direction = Vector2(1, -0.3)
	p.spread = 40.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector2.ZERO
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.9, 0.7, 0.0), Color(1, 0.92, 0.75, 0.55), Color(1, 0.9, 0.7, 0.0)])
	p.color_ramp = ramp
	return p
