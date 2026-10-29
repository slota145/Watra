shader_type canvas_item;
// Skośny nawis w wcięciu schodka krawędzi płaskowyżu (MountainZone._place_fillets): pas nawisu ścięty pod 45°,
// a nad skosem podłoże płaskowyżu. Duszek ma 16 x 33 px; wiersz 0 to rząd, w którym zaczyna się zwykły nawis
// po lewej, a skos schodzi o 17 px na 16 kolumnach - do rzędu, w którym zaczyna się nawis po prawej.
// Odbicia duszka (flip_h / flip_v) obracają skos do pozostałych wcięć; pas próbkujemy wg x świata,
// więc pasuje do sąsiednich nawisów.

// pas nawisu (malowany pas trawy albo maska: białe - podłoże, szare - obrys, półprzezroczyste - cień)
uniform sampler2D lip_tex : filter_nearest, repeat_enable;
uniform bool is_mask = true;
uniform sampler2D terrain_tex : filter_nearest, repeat_enable;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 local = floor(UV * vec2(16.0, 33.0));
	float edge = floor((local.x + 0.5) * 17.0 / 16.0);
	vec2 p = floor(world_pos) + 0.5;
	vec3 ground = texture(terrain_tex, p / vec2(textureSize(terrain_tex, 0))).rgb;
	if (local.y < edge) {
		COLOR = vec4(ground, 1.0);
	} else {
		float s = local.y - edge;
		if (s >= 16.0) {
			discard;
		}
		vec2 size = vec2(textureSize(lip_tex, 0));
		vec4 lip = texture(lip_tex, vec2(mod(p.x, size.x), s + 0.5) / size);
		COLOR = !is_mask ? lip : lip.a < 1.0 ? lip : vec4(ground * lip.r, 1.0);
	}
}
