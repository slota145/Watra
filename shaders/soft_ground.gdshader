shader_type canvas_item;
// Miękkie przejście terenu: warstwa pełnych kafelków górnego terenu widoczna tylko tam, gdzie
// gładkie pole narożników (SoftGround) z dodanym szumem przekracza połowę. Brzeg dostaje obwódkę
// albo pikselowy dithering, więc zamiast schodków z kafelków Wang wychodzą organiczne kształty.

// pole narożników 0/1 bez wygładzenia - gładkie przejście daje interpolacja Catmulla-Roma w field_at()
uniform sampler2D field : filter_nearest, repeat_disable;
// góry: pole narożników od strony niższego terenu na granicach poziomów i wysokości komórek (R = poziom / 8);
// komórka, przy której leży wyższa, bierze to pole - teren płaskowyżu nie wylewa się obok jego krawędzi
uniform bool split_levels = false;
uniform sampler2D low_field : filter_nearest, repeat_disable;
uniform sampler2D levels : filter_nearest, repeat_disable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
// liczba narożników mapy (rozmiar mapy + 1) - pole ma po jednym tekselu na narożnik
uniform vec2 corner_count = vec2(201.0, 151.0);
uniform float edge_noise = 0.5;
// drobny, poszarpany szum brzegu (kępki trawy) - dodawany do gładkiego
uniform float fine_noise = 0.0;
// teren z bezszwową teksturą w przestrzeni świata zamiast kafelka z atlasu
uniform bool use_texture = false;
uniform sampler2D terrain_tex : filter_nearest, repeat_enable;
// warstwa bazowa terenu z teksturą - bez przycinania polem
uniform bool full = false;
// obwódka po wewnętrznej stronie brzegu (kolor, krycie w alfie) i jej szerokość w jednostkach pola
uniform vec4 rim_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float rim_width = 0.0;
// pas szachownicy po zewnętrznej stronie brzegu (miękki brzeg trawy, mchu)
uniform float dither_width = 0.0;
// lekki cień rzucany na niższy teren tuż za brzegiem (kolor, krycie w alfie)
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float shadow_width = 0.0;
// woda: tekstura faluje (przesunięcie o piksel-dwa w rytm fal) i przesuwają się po niej błyski
uniform bool animate = false;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// wagi Catmulla-Roma dla próbek w -1, 0, 1, 2 (ta sama krzywa co Image.INTERPOLATE_CUBIC)
vec4 catmull_rom(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	return vec4(-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0,
			-1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2);
}

float field_row(sampler2D tex, ivec2 base, int dy, ivec2 last, vec4 wx) {
	int y = clamp(base.y + dy, 0, last.y);
	return dot(vec4(
			texelFetch(tex, ivec2(clamp(base.x - 1, 0, last.x), y), 0).r,
			texelFetch(tex, ivec2(clamp(base.x, 0, last.x), y), 0).r,
			texelFetch(tex, ivec2(clamp(base.x + 1, 0, last.x), y), 0).r,
			texelFetch(tex, ivec2(clamp(base.x + 2, 0, last.x), y), 0).r), wx);
}

// czy komórka punktu ma obok (także po skosie) wyższą komórkę
bool below_higher(vec2 p) {
	ivec2 cell = ivec2(floor(p / 16.0));
	ivec2 last = textureSize(levels, 0) - 1;
	float own = texelFetch(levels, clamp(cell, ivec2(0), last), 0).r;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			if (texelFetch(levels, clamp(cell + ivec2(dx, dy), ivec2(0), last), 0).r > own + 0.01) {
				return true;
			}
		}
	}
	return false;
}

// gładkie pole w punkcie świata: narożnik i leży w p = 16 * i
float field_at(sampler2D tex, vec2 p) {
	vec2 c = p / 16.0;
	vec2 cell = floor(c);
	vec2 f = c - cell;
	ivec2 base = ivec2(cell);
	ivec2 last = ivec2(corner_count) - 1;
	vec4 wx = catmull_rom(f.x);
	vec4 wy = catmull_rom(f.y);
	float v = dot(vec4(field_row(tex, base, -1, last, wx), field_row(tex, base, 0, last, wx),
			field_row(tex, base, 1, last, wx), field_row(tex, base, 2, last, wx)), wy);
	return clamp(v, 0.0, 1.0);
}

float level(vec2 p) {
	float f = split_levels && below_higher(p) ? field_at(low_field, p) : field_at(field, p);
	float n = texture(noise_tex, p / 110.0).r - 0.5;
	n += (texture(noise_tex, p / 37.0 + vec2(0.37, 0.71)).r - 0.5) * 0.7;
	float fine = texture(noise_tex, p / 19.0 + vec2(0.13, 0.59)).r - 0.5;
	return f + n * edge_noise + fine * fine_noise;
}

void fragment() {
	vec2 p = floor(world_pos) + 0.5;
	vec4 c = use_texture ? texture(terrain_tex, p / vec2(textureSize(terrain_tex, 0))) : texture(TEXTURE, UV);
	if (animate && use_texture) {
		vec2 q = p + vec2(sin(TIME * 0.7 + p.y * 0.045) * 1.6, cos(TIME * 0.55 + p.x * 0.035) * 1.2);
		c = texture(terrain_tex, (floor(q) + 0.5) / vec2(textureSize(terrain_tex, 0)));
		float glint = texture(noise_tex, p / 90.0 + vec2(TIME * 0.015, TIME * 0.006)).r
				* texture(noise_tex, p / 47.0 - vec2(TIME * 0.012, 0.0)).r;
		if (glint > 0.5) {
			c.rgb = mix(c.rgb, vec3(0.85, 0.95, 1.0), 0.35);
		} else if (glint > 0.45) {
			c.rgb = mix(c.rgb, vec3(0.75, 0.88, 0.95), 0.12);
		}
	}
	float v = full ? 1.0 : level(p);
	if (v >= 0.5) {
		if (v < 0.5 + rim_width) {
			c.rgb = mix(c.rgb, rim_color.rgb, rim_color.a);
		}
		COLOR = c;
	} else if (v >= 0.5 - dither_width && mod(p.x + p.y - 1.0, 2.0) < 0.5) {
		COLOR = c;
	} else if (v >= 0.5 - shadow_width) {
		COLOR = vec4(shadow_color.rgb, shadow_color.a);
	} else {
		discard;
	}
}
