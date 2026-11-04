shader_type canvas_item;
// Mgła Nawii (NawiaMist) na ekranie: sine, powoli płynące kłęby mgły, gęstsze przy brzegach ekranu niż na środku.
// "density" 0..1 - im gęściej, tym mgła mocniej zasłania brzegi i sięga bliżej postaci.

uniform float density : hint_range(0.0, 1.0) = 0.0;
uniform vec4 mist : source_color = vec4(0.62, 0.62, 0.82, 1.0);
uniform float aspect = 1.78;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y) * 3.0;
	float t = TIME * 0.05;
	float cloud = fbm(p + vec2(t, t * 0.6)) * 0.6 + fbm(p * 1.7 - vec2(t * 1.3, -t * 0.4)) * 0.4;
	vec2 c = (UV - 0.5) * vec2(aspect, 1.0);
	// brzegi ekranu: pełna mgła, środek: tym czystszy, im rzadsza mgła
	float edge = smoothstep(0.25 - 0.2 * density, 1.0, length(c) * 1.1);
	float a = density * (0.18 + 0.62 * edge) * (0.45 + 0.75 * cloud);
	COLOR = vec4(mist.rgb * (0.85 + 0.3 * cloud), clamp(a, 0.0, 0.75));
}
