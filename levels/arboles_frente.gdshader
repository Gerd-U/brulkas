shader_type canvas_item;

// Los troncos (la parte de arriba de la imagen) se ven transparentes para no
// tapar el juego; el pasto y las rocas de abajo quedan enteros.

// Cuánto se ven los troncos (0 = invisibles, 1 = enteros)
uniform float transparencia_troncos : hint_range(0.0, 1.0) = 0.3;
// Altura de la imagen donde empieza el pasto (0 = arriba, 1 = abajo)
uniform float inicio_pasto : hint_range(0.0, 1.0) = 0.92;
// Qué tan suave es el paso de transparente a entero
uniform float suavidad : hint_range(0.0, 0.5) = 0.06;

void fragment() {
	float entero = smoothstep(inicio_pasto - suavidad, inicio_pasto, UV.y);
	COLOR.a *= mix(transparencia_troncos, 1.0, entero);
}
