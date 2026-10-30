shader_type canvas_item;
// Jesienne liście: zielone piksele (zieleń wyraźnie ponad czerwienią i błękitem) przyjmują barwę `tint`
// o jasności oryginału - pień, gałęzie i cienie zostają. Przezroczystość (zasłony, ścinanie) bez zmian.

uniform vec3 tint = vec3(1.0, 0.72, 0.28);

void fragment() {
	vec4 c = COLOR;  // w Godot 4 COLOR to już kolor tekstury razy modulate
	float leaf = clamp((c.g - max(c.r, c.b)) * 6.0, 0.0, 1.0);
	float light = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, min(tint * (light * 2.0 + 0.18), vec3(1.0)), leaf);
	COLOR = c;
}
