shader_type canvas_item;
// Sylwetka postaci za zasłoną: jednolity kolor z przezroczystością, jasny obrys na krawędzi kształtu.

uniform vec4 fill : source_color = vec4(0.55, 0.8, 1.0, 0.12);
uniform vec4 outline : source_color = vec4(0.85, 0.95, 1.0, 0.9);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	vec2 px = TEXTURE_PIXEL_SIZE;
	float around = texture(TEXTURE, UV + vec2(px.x, 0.0)).a * texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			* texture(TEXTURE, UV + vec2(0.0, px.y)).a * texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	if (a < 0.5) {
		discard;
	}
	// piksel na brzegu kształtu (któryś sąsiad przezroczysty) - obrys, w środku - wypełnienie
	vec4 c = around < 0.5 ? outline : fill;
	COLOR = vec4(c.rgb, c.a * COLOR.a);
}
