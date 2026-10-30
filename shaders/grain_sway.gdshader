shader_type canvas_item;
// Łan zboża na wietrze: kłosy u góry pasa przesuwają się w bok falą biegnącą przez pole (wg położenia
// w świecie), łodygi przy ziemi stoją. Przesunięcie w pełnych pikselach tekstury - bez rozmycia.

uniform float strength = 1.6;
uniform float speed = 1.7;
uniform float height = 30.0;

varying vec2 world;
varying float lift;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	lift = clamp(-VERTEX.y / height, 0.0, 1.0);
}

void fragment() {
	float wave = sin(TIME * speed - world.x * 0.045 + world.y * 0.02) + 0.35 * sin(TIME * speed * 2.3 + world.x * 0.13);
	float shift = floor(wave * strength * lift * lift + 0.5);
	COLOR = texture(TEXTURE, UV + vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0)) * COLOR;
}
