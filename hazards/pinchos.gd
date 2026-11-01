@tool
extends Area2D

## Cuántos pinchos seguidos hay
@export var cantidad: int = 2:
	set(valor):
		cantidad = max(1, valor)
		_actualizar()

## Ancho de cada pincho en píxeles
@export var ancho: float = 32.0:
	set(valor):
		ancho = max(4.0, valor)
		_actualizar()

## Altura de los pinchos en píxeles
@export var alto: float = 20.0:
	set(valor):
		alto = max(4.0, valor)
		_actualizar()

## Color de los pinchos (si no tienen imagen)
@export var color: Color = Color(0.75, 0.75, 0.8):
	set(valor):
		color = valor
		queue_redraw()

@export_group("Imagen")
## Imagen de UN pincho: se dibuja una copia por cada pincho,
## cada una en su espacio de ancho x alto. Si está vacía se dibujan triángulos.
@export var textura: Texture2D:
	set(valor):
		textura = valor
		_actualizar()

## Mueve los pinchos dibujados (en píxeles) por si quedan corridos
@export var ajuste_textura: Vector2 = Vector2.ZERO:
	set(valor):
		ajuste_textura = valor
		_actualizar()

## Agranda o achica cada pincho desde su base (1 = tamaño normal)
@export var escala_textura: float = 1.0:
	set(valor):
		escala_textura = valor
		_actualizar()

@export_group("Colisión")
## Baja el borde de arriba de la zona que mata (en píxeles)
@export var recorte_arriba: float = 0.0:
	set(valor):
		recorte_arriba = valor
		_actualizar()

## Achica la zona que mata de cada costado (en píxeles)
@export var recorte_lados: float = 0.0:
	set(valor):
		recorte_lados = valor
		_actualizar()

## La zona que mata toma la forma de cada pincho dibujado
## (no mata en el aire que hay entre las puntas)
@export var colision_por_forma: bool = false:
	set(valor):
		colision_por_forma = valor
		_actualizar()

var _formas: Array[CollisionPolygon2D] = []  # una por pincho, si se usa la forma


func _ready() -> void:
	_actualizar()
	# Solo en el juego (no en el editor) escuchamos cuando algo nos toca
	if not Engine.is_editor_hint():
		body_entered.connect(_al_tocar)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho * cantidad - recorte_lados * 2, alto - recorte_arriba)
	forma.shape = rect
	# La base queda en y = 0
	forma.position = Vector2(0, -rect.size.y / 2)

	# Una forma por pincho (en vez del rectángulo) si hay imagen
	for vieja in _formas:
		vieja.queue_free()
	_formas.clear()
	var usar_forma := colision_por_forma and textura != null and is_inside_tree()
	forma.disabled = usar_forma
	if usar_forma:
		for i in cantidad:
			var poligono := CollisionPolygon2D.new()
			poligono.polygon = TexturaUtil.envolvente(textura, _rect_pincho(i))
			add_child(poligono)
			_formas.append(poligono)
	queue_redraw()


# Dónde se dibuja el pincho número i
func _rect_pincho(i: int) -> Rect2:
	var x := -ancho * cantidad / 2.0 + i * ancho
	var tam := Vector2(ancho, alto) * escala_textura
	# La escala se aplica desde la base del pincho
	return Rect2(Vector2(x + ancho / 2 - tam.x / 2, -tam.y) + ajuste_textura, tam)


func _draw() -> void:
	if textura:
		var parte := TexturaUtil.parte_visible(textura)
		for i in cantidad:
			draw_texture_rect_region(textura, _rect_pincho(i), parte)
		return

	var inicio := -ancho * cantidad / 2.0
	for i in cantidad:
		var x := inicio + i * ancho
		var triangulo := PackedVector2Array([
			Vector2(x, 0),                  # esquina abajo-izquierda
			Vector2(x + ancho / 2, -alto),  # punta de arriba
			Vector2(x + ancho, 0),          # esquina abajo-derecha
		])
		draw_colored_polygon(triangulo, color)


func _al_tocar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("morir"):
		cuerpo.morir()
