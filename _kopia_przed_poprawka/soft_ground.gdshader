shader_type canvas_item;
// Miękkie przejście terenu: warstwa pełnych kafelków górnego terenu widoczna tylko tam, gdzie
// gładkie pole narożników (SoftGround) z dodanym szumem przekracza połowę. Brzeg dostaje obwódkę
// albo pikselowy dithering, więc zamiast schodków z kafelków Wang wychodzą organiczne kształty.

uniform sampler2D field : filter_linear, repeat_disable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
// liczba narożników mapy (rozmiar mapy + 1) - pole ma po jednym tekselu na narożnik
uniform vec2 corner_count = vec2(201.0, 151.0);
uniform float edge_noise = 0.5;
// obwódka po wewnętrznej stronie brzegu (kolor, krycie w alfie) i jej szerokość w jednostkach pola
uniform vec4 rim_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float rim_width = 0.0;
// pas szachownicy po zewnętrznej stronie brzegu (miękki brzeg trawy, mchu)
uniform float dither_width = 0.0;
// lekki cień rzucany na niższy teren tuż za brzegiem (kolor, krycie w alfie)
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float shadow_width = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float level(vec2 p) {
	float f = texture(field, (p / 16.0 + 0.5) / corner_count).r;
	float n = texture(noise_tex, p / 110.0).r - 0.5;
	n += (texture(noise_tex, p / 37.0 + vec2(0.37, 0.71)).r - 0.5) * 0.7;
	return f + n * edge_noise;
}

void fragment() {
	vec2 p = floor(world_pos) + 0.5;
	float v = level(p);
	vec4 c = texture(TEXTURE, UV);
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
