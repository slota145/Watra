shader_type canvas_item;
render_mode blend_add;
// Krąg Uroczyska (Uroczysko): kwadrat 2R x 2R, w środku sinozielona mgła innego świata (falujący szum),
// przy brzegu świetlisty pierścień z pulsującymi runami-iskrami. `radius` - promień w pikselach (grubość brzegu
// stała w pikselach), `strength` - jasność (gaśnie przy zamykaniu).

uniform vec4 color : source_color = vec4(0.35, 1.0, 0.75, 1.0);
uniform float radius = 100.0;
uniform float strength = 1.0;
// połowa boku tekstury duszka (Uroczysko.RING_TEXTURE / 2) - położenie liczone z wierzchołków, a nie z UV
uniform float half_size = 4.0;

varying vec2 local;

void vertex() {
	local = VERTEX / half_size;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = local;
	float d = length(p);
	if (d > 1.0) {
		discard;
	}
	vec2 world = p * radius;
	float t = TIME * 0.35;
	float mist = noise(world / 46.0 + vec2(t, -t * 0.6)) * 0.6 + noise(world / 19.0 - vec2(t * 1.3, t * 0.4)) * 0.4;
	// pierścień o stałej grubości w pikselach
	float edge_px = (1.0 - d) * radius;
	float ang = atan(p.y, p.x);
	float sparks = step(0.82, noise(vec2(ang * radius / 9.0, TIME * 1.6))) * exp(-edge_px / 8.0);
	// smugi mgły: tylko jaśniejsze płaty szumu, wyraźne na ciemnej podłodze
	float wisps = smoothstep(0.5, 0.85, mist);
	float inner = 0.025 + 0.16 * wisps;
	float ring_a = exp(-edge_px / 3.0) * 0.9 + exp(-edge_px / 18.0) * 0.25;
	float a = (inner + ring_a * (0.8 + 0.2 * sin(TIME * 3.0)) + sparks * 0.7) * strength;
	COLOR = vec4(color.rgb * a, 1.0);
}
