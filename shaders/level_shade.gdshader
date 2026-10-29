shader_type canvas_item;
// Cień u stóp płaskowyżów (MountainZone._build_level_shade): niższy teren przy wyższym ciemnieje
// łagodnie ku krawędzi, więc boki i tył płaskowyżu czytają się jak uskok, a nie jak pęknięcie w trawie.

// poziom komórki (R = poziom / 8), próbkowany dokładnie
uniform sampler2D levels : filter_nearest, repeat_disable;
// "zasięg" wyższego terenu (R = poziom / 8): poziom sąsiada pomniejszony z odległością, filtrowany liniowo
uniform sampler2D reach : filter_linear, repeat_disable;
uniform vec2 cells = vec2(200.0, 150.0);
uniform vec4 shade_color : source_color = vec4(0.05, 0.08, 0.02, 0.5);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(world_pos) + 0.5;
	vec2 uv = p / 16.0 / cells;
	float own = texture(levels, uv).r * 8.0;
	float near = texture(reach, uv).r * 8.0;
	float s = clamp(near - own, 0.0, 1.0);
	// schodkowy (pikselowy) spadek cienia zamiast gładkiego gradientu
	s = floor(s * 5.0) / 5.0;
	COLOR = vec4(shade_color.rgb, shade_color.a * s);
}
