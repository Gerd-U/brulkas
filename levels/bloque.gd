@tool
extends StaticBody2D

## Tamaño del bloque en píxeles (ancho, alto)
@export var tamano: Vector2 = Vector2(200, 40):
	set(valor):
		tamano = valor
		_actualizar()

## Color con el que se dibuja el bloque (si no tiene imagen)
@export var color: Color = Color(0.15, 0.15, 0.17):
	set(valor):
		color = valor
		queue_redraw()

## Si se desactiva, el jugador que se pare encima es empujado hacia un costado
@export var se_puede_pisar: bool = true

@export_group("Imagen")
## Imagen del bloque. Si está vacía se dibuja el rectángulo de color.
@export var textura: Texture2D:
	set(valor):
		textura = valor
		queue_redraw()

## Rellenar: la imagen se estira al tamaño del bloque (troncos, torres, árboles).
## Plataforma: la imagen toma el ancho del bloque sin aplastarse, y su borde
## de arriba queda donde camina el jugador; el resto cuelga hacia abajo.
## Repetir: la imagen toma el alto del bloque sin aplastarse y se repite
## a lo largo (para suelos largos).
@export_enum("Rellenar", "Plataforma", "Repetir") var modo_textura: int = 0:
	set(valor):
		modo_textura = valor
		queue_redraw()

## Mueve la imagen (en píxeles) por si queda corrida
@export var ajuste_textura: Vector2 = Vector2.ZERO:
	set(valor):
		ajuste_textura = valor
		queue_redraw()

## Agranda o achica la imagen (1 = tamaño normal)
@export var escala_textura: float = 1.0:
	set(valor):
		escala_textura = valor
		queue_redraw()

## Dibuja la imagen derecha aunque el bloque esté girado
## (para dibujos que ya vienen inclinados, como la pendiente)
@export var ignorar_rotacion: bool = false:
	set(valor):
		ignorar_rotacion = valor
		queue_redraw()

@export_group("Colisión")
## Baja el borde de arriba de la colisión (en píxeles), para que el jugador
## pise donde empieza el dibujo y no en el aire. El dibujo no cambia.
@export var recorte_arriba: float = 0.0:
	set(valor):
		recorte_arriba = valor
		_actualizar()

## Achica la colisión de cada costado (en píxeles). El dibujo no cambia.
@export var recorte_lados: float = 0.0:
	set(valor):
		recorte_lados = valor
		_actualizar()

const EMPUJE := 320.0  # velocidad con que tira al jugador si se sube encima

# Parte visible (sin bordes transparentes) de cada imagen, se calcula una sola vez
static var _partes_visibles := {}

var _techo: Area2D  # franja encima del bloque (solo si no se puede pisar)


func _ready() -> void:
	_actualizar()
	if not Engine.is_editor_hint() and not se_puede_pisar:
		_crear_techo()


func _crear_techo() -> void:
	# Franja delgadita justo encima del bloque que detecta al jugador
	_techo = Area2D.new()
	_techo.collision_layer = 0
	_techo.collision_mask = 2  # capa del jugador
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tamano.x - recorte_lados * 2, 10)
	forma.shape = rect
	# Se mete 2 px dentro del bloque para detectar bien los pies del jugador
	forma.position = Vector2(0, -tamano.y / 2 + recorte_arriba - 3)
	_techo.add_child(forma)
	add_child(_techo)


func _physics_process(delta: float) -> void:
	if _techo == null:
		return
	# Si el jugador está parado arriba, lo empujamos hacia el lado más cercano
	for cuerpo in _techo.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador"):
			var lado := signf(cuerpo.global_position.x - global_position.x)
			if lado == 0.0:
				lado = 1.0
			cuerpo.global_position.x += lado * EMPUJE * delta


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano - Vector2(recorte_lados * 2, recorte_arriba)
	forma.shape = rect
	# El borde de abajo queda donde estaba; solo baja el de arriba
	forma.position = Vector2(0, recorte_arriba / 2)
	queue_redraw()


func _parte_visible() -> Rect2:
	if not _partes_visibles.has(textura):
		var parte := Rect2(Vector2.ZERO, textura.get_size())
		var imagen := textura.get_image()
		if imagen:
			if imagen.is_compressed():
				imagen.decompress()
			var usada := imagen.get_used_rect()
			if usada.has_area():
				parte = Rect2(usada)
		_partes_visibles[textura] = parte
	return _partes_visibles[textura]


func _dibujar_textura() -> void:
	var parte := _parte_visible()
	var caja := Rect2(-tamano / 2, tamano)
	if ignorar_rotacion:
		# Deshacemos el giro del nodo y usamos la caja que ocupa el bloque girado
		draw_set_transform(Vector2.ZERO, -rotation)
		var giro := Transform2D(rotation, Vector2.ZERO)
		caja = Rect2(giro * caja.position, Vector2.ZERO)
		for esquina in [Vector2(tamano.x / 2, -tamano.y / 2), tamano / 2, Vector2(-tamano.x / 2, tamano.y / 2)]:
			caja = caja.expand(giro * esquina)

	if modo_textura == 2:
		_dibujar_repetida(parte, caja)
		draw_set_transform(Vector2.ZERO)
		return

	var destino := caja
	if modo_textura == 1:
		# Plataforma: mismo ancho, sin aplastar, colgando desde el borde de arriba
		destino.size.y = caja.size.x * parte.size.y / parte.size.x

	# La escala se aplica desde el centro (en Plataforma, desde el centro de arriba,
	# así el borde donde se camina no se mueve)
	var tam := destino.size * escala_textura
	var arriba := Vector2(destino.get_center().x, destino.position.y)
	if modo_textura == 0:
		arriba.y = destino.get_center().y - tam.y / 2
	destino = Rect2(arriba - Vector2(tam.x / 2, 0) + ajuste_textura, tam)

	draw_texture_rect_region(textura, destino, parte)
	draw_set_transform(Vector2.ZERO)


func _dibujar_repetida(parte: Rect2, caja: Rect2) -> void:
	# Cada copia mide lo mismo de alto que el bloque y mantiene su proporción
	var alto := caja.size.y * escala_textura
	var ancho := alto * parte.size.x / parte.size.y
	if ancho <= 0.0:
		return
	var x := caja.position.x
	var fin := caja.end.x
	while x < fin:
		# La última copia se corta para no pasarse del bloque
		var w := minf(ancho, fin - x)
		var region := Rect2(parte.position, Vector2(parte.size.x * w / ancho, parte.size.y))
		var destino := Rect2(Vector2(x, caja.position.y) + ajuste_textura, Vector2(w, alto))
		draw_texture_rect_region(textura, destino, region)
		x += w


func _draw() -> void:
	if textura:
		_dibujar_textura()
		return
	draw_rect(Rect2(-tamano / 2, tamano), color)
