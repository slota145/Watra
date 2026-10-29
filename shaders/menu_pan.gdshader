shader_type canvas_item;
// Tło menu: obraz sceny (SubViewport w rozmiarze grafiki) przycięty tak, żeby wypełniał ekran, i przesuwany
// za myszą o ułamki piksela - w shaderze, bo przesuwanie węzła przyciąga go do pełnych pikseli gry
// (snap_2d_transforms_to_pixel) i ruch szedł skokami co 4 piksele ekranu.

uniform vec2 visible = vec2(1.0, 1.0);  // jaka część obrazu mieści się na ekranie (UV)
uniform vec2 shift = vec2(0.0, 0.0);    // przesunięcie widocznego wycinka (UV)

void fragment() {
	vec2 uv = vec2(0.5) + (UV - vec2(0.5)) * visible + shift;
	COLOR = texture(TEXTURE, uv);
}
