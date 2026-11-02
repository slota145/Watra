shader_type canvas_item;
// Elita lochu (DungeonElite): błysk przy trafieniu (jak flash.gdshader) i obrys w kolorze cechy wokół kształtu.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform vec4 outline : source_color = vec4(1.0, 0.8, 0.3, 1.0);

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		// przezroczysty piksel tuż obok kształtu - obrys
		vec2 px = TEXTURE_PIXEL_SIZE;
		float near = max(max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
				max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		COLOR = near > 0.5 ? vec4(outline.rgb, outline.a * tint.a) : vec4(0.0);
	} else {
		COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash);
	}
}
