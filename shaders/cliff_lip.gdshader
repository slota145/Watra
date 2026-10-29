shader_type canvas_item;
// Nawis krawędzi płaskowyżu (MountainZone._place_lips) z maski: białe piksele to podłoże, szare - obrys
// (podłoże przyciemnione do jasności maski), półprzezroczyste - cień na ścianie. Podłoże bierzemy z tej samej
// bezszwowej tekstury i w tych samych współrzędnych świata co SoftGround, więc nawis łączy się z płaskowyżem bez szwu.

uniform sampler2D terrain_tex : filter_nearest, repeat_enable;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	vec2 p = floor(world_pos) + 0.5;
	vec3 ground = texture(terrain_tex, p / vec2(textureSize(terrain_tex, 0))).rgb;
	COLOR = mask.a < 1.0 ? mask : vec4(ground * mask.r, 1.0);
}
