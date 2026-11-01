shader_type canvas_item;
// Migotanie płomieni nad napisem w menu (assets/menu/logo.png): powyżej linii płomieni piksele kołyszą się
// na boki i podskakują (o całe piksele grafiki, im wyżej, tym mocniej), płomienie jaśnieją i przygasają,
// a cały napis delikatnie pulsuje żarem. Litery pod linią płomieni stoją w miejscu.

// Linia płomieni (część wysokości od góry) - niżej zaczynają się litery.
uniform float flame_line = 0.36;
// Największe przesunięcie na czubkach płomieni (piksele grafiki).
uniform float sway = 1.6;
uniform float rise = 1.2;
uniform float speed = 1.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec2 cell = floor(UV / texel);
	float height = clamp((flame_line - UV.y) / flame_line, 0.0, 1.0);
	float t = TIME * speed;
	// kolumny płomieni kołyszą się niezależnie (fala zależna od kolumny i wiersza)
	float column = floor(cell.x / 6.0);
	float wave = sin(t * 5.0 + cell.y * 0.55 + hash(column) * 6.28) + 0.5 * sin(t * 8.3 + cell.y * 1.3);
	float dx = floor(wave * sway * height * height + 0.5);
	float jump = 0.5 + 0.5 * sin(t * 6.0 + hash(column + 7.0) * 6.28);
	float dy = floor(jump * rise * height + 0.5);
	vec4 color = texture(TEXTURE, (cell + vec2(dx, dy) + 0.5) * texel);
	// płomienie migoczą jasnością, napis pulsuje żarem
	float flicker = 1.0 + height * 0.18 * sin(t * 11.0 + hash(column + 3.0) * 6.28);
	float glow = 1.0 + 0.05 * sin(t * 2.2);
	color.rgb *= flicker * glow;
	COLOR = color * COLOR;
}
