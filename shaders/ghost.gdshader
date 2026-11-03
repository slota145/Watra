shader_type canvas_item;
// Upiór z Uroczyska (Uroczysko): potwór klimatu jako półprzezroczysta, sinozielona zjawa - barwa wg jasności
// oryginału, migotanie przezroczystości, jasny obrys i błysk przy trafieniu (jak flash.gdshader).

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 ghost : source_color = vec4(0.55, 1.0, 0.85, 1.0);
uniform float phase = 0.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float flick = 0.6 + 0.1 * sin(TIME * 5.0 + phase) + 0.06 * sin(TIME * 13.0 + phase * 1.7 + UV.y * 40.0);
	if (c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float near = max(max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
				max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		COLOR = near > 0.5 ? vec4(ghost.rgb * 1.3, 0.55 * flick * tint.a) : vec4(0.0);
	} else {
		float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
		vec3 g = ghost.rgb * (0.3 + lum * 1.2) * tint.rgb;
		COLOR = vec4(mix(g, flash_color.rgb, flash), flick * tint.a);
	}
}
