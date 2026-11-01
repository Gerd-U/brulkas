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
## Repetir: la imagen toma el alto del bloque (por escala_textura) sin aplastarse
## y se repite a lo largo (para suelos y plataformas largas).
## Apilar: la imagen toma el ancho del bloque sin aplastarse y se repite
## hacia abajo, una copia encima de otra (para muros y escalones).
@export_enum("Rellenar", "Plataforma", "Repetir", "Apilar") var modo_textura: int = 0:
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

## Solo en modo Plataforma: hace el dibujo más delgado (menos de 1)
## o más grueso (más de 1) sin cambiar su ancho
@export var grosor_textura: float = 1.0:
	set(valor):
		grosor_textura = valor
		queue_redraw()
		if is_inside_tree():
			_crear_colision_por_forma()

## Solo en modo Repetir: cuánto se enciman las copias (0 = una al lado de la
## otra, 0.3 = se tapan un 30%). Sirve para que no queden huecos entre ellas.
@export var solape_copias: float = 0.0:
	set(valor):
		solape_copias = clampf(valor, 0.0, 0.9)
		queue_redraw()
		if is_inside_tree():
			_crear_colision_por_forma()

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

## La colisión toma la forma del dibujo (lo que no es transparente)
## en vez de ser un rectángulo. En modo Repetir solo funciona con forma lisa.
@export var colision_por_forma: bool = false:
	set(valor):
		colision_por_forma = valor
		if is_inside_tree():
			_crear_colision_por_forma()

## Cuánto se simplifica la forma: más alto = menos detalle y más suave
## para caminar; más bajo = sigue más los bordes del dibujo
@export var detalle_forma: float = 6.0:
	set(valor):
		detalle_forma = valor
		if is_inside_tree():
			_crear_colision_por_forma()

## Forma lisa: une las puntas del dibujo con líneas rectas, sin entradas
## ni picos, para que el jugador y las cajas no se traben al moverse
@export var forma_lisa: bool = false:
	set(valor):
		forma_lisa = valor
		if is_inside_tree():
			_crear_colision_por_forma()

const EMPUJE := 320.0  # velocidad con que tira al jugador si se sube encima

var _techo: Area2D  # franja encima del bloque (solo si no se puede pisar)
var _poligonos: Array[CollisionPolygon2D] = []  # colisión con la forma del dibujo


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
	if is_inside_tree():
		_crear_colision_por_forma()
	queue_redraw()


func _parte_visible() -> Rect2:
	return TexturaUtil.parte_visible(textura)


# Caja donde se dibuja la imagen (si se ignora el giro, la que ocupa el bloque girado)
func _caja_dibujo() -> Rect2:
	var caja := Rect2(-tamano / 2, tamano)
	if ignorar_rotacion:
		var giro := Transform2D(rotation, Vector2.ZERO)
		caja = Rect2(giro * caja.position, Vector2.ZERO)
		for esquina in [Vector2(tamano.x / 2, -tamano.y / 2), tamano / 2, Vector2(-tamano.x / 2, tamano.y / 2)]:
			caja = caja.expand(giro * esquina)
	return caja


# Rectángulo exacto donde queda la imagen (modos Rellenar y Plataforma)
func _rect_dibujo(parte: Rect2) -> Rect2:
	var caja := _caja_dibujo()
	var destino := caja
	if modo_textura == 1:
		# Plataforma: mismo ancho, sin aplastar, colgando desde el borde de arriba
		destino.size.y = caja.size.x * parte.size.y / parte.size.x * grosor_textura

	# La escala se aplica desde el centro (en Plataforma, desde el centro de arriba,
	# así el borde donde se camina no se mueve)
	var tam := destino.size * escala_textura
	var arriba := Vector2(destino.get_center().x, destino.position.y)
	if modo_textura == 0:
		arriba.y = destino.get_center().y - tam.y / 2
	return Rect2(arriba - Vector2(tam.x / 2, 0) + ajuste_textura, tam)


func _dibujar_textura() -> void:
	var parte := _parte_visible()
	if ignorar_rotacion:
		# Deshacemos el giro del nodo para dibujar la imagen derecha
		draw_set_transform(Vector2.ZERO, -rotation)

	if modo_textura == 2:
		for copia in _copias_repetidas(parte, _caja_dibujo()):
			draw_texture_rect_region(textura, copia, parte)
	elif modo_textura == 3:
		for copia in _copias_apiladas(parte, _caja_dibujo()):
			draw_texture_rect_region(textura, copia, parte)
	else:
		draw_texture_rect_region(textura, _rect_dibujo(parte), parte)
	draw_set_transform(Vector2.ZERO)


func _crear_colision_por_forma() -> void:
	for poligono in _poligonos:
		poligono.queue_free()
	_poligonos.clear()

	var rectangulo := get_node_or_null("CollisionShape2D") as CollisionShape2D
	# En modo Repetir y Apilar solo se puede usar la forma lisa
	var usar_forma := colision_por_forma and textura != null and (modo_textura < 2 or forma_lisa)
	if rectangulo:
		rectangulo.disabled = usar_forma
	if not usar_forma:
		return

	var imagen := textura.get_image()
	if imagen == null:
		if rectangulo:
			rectangulo.disabled = false
		return
	if imagen.is_compressed():
		imagen.decompress()

	# Contorno de la parte visible de la imagen (lo que no es transparente)
	var parte := _parte_visible()
	var recorte := imagen.get_region(Rect2i(parte))
	var mapa := BitMap.new()
	mapa.create_from_image_alpha(recorte, 0.5)
	var contornos := mapa.opaque_to_polygons(Rect2i(Vector2i.ZERO, recorte.get_size()), detalle_forma)

	# Pasamos el contorno al mismo tamaño y lugar en que se dibuja la imagen
	var destino := _rect_dibujo(parte)
	var escala := destino.size / parte.size
	if forma_lisa:
		# Juntamos todos los puntos (de todas las copias, si se repite)
		# y los envolvemos con una sola forma sin entradas
		var copias: Array[Rect2] = [destino]
		if modo_textura == 2:
			copias = _copias_repetidas(parte, _caja_dibujo())
		elif modo_textura == 3:
			copias = _copias_apiladas(parte, _caja_dibujo())
		var todos := PackedVector2Array()
		for copia in copias:
			var escala_copia := copia.size / parte.size
			for contorno in contornos:
				for punto in contorno:
					todos.append(copia.position + punto * escala_copia)
		var lisa := Geometry2D.convex_hull(todos)
		if lisa.size() > 3:
			lisa.remove_at(lisa.size() - 1)  # el último punto repite el primero
			var envolvente := CollisionPolygon2D.new()
			envolvente.polygon = lisa
			if ignorar_rotacion:
				envolvente.rotation = -rotation
			add_child(envolvente)
			_poligonos.append(envolvente)
		return

	for contorno in contornos:
		if contorno.size() < 3:
			continue
		var puntos := PackedVector2Array()
		for punto in contorno:
			puntos.append(destino.position + punto * escala)
		# Limpia el contorno por si se cruza sobre sí mismo (si no, Godot no lo acepta)
		for limpio in Geometry2D.offset_polygon(puntos, 0.0):
			if limpio.size() < 3:
				continue
			var poligono := CollisionPolygon2D.new()
			# Hecho de segmentos (el borde): acepta formas con entradas y picos
			poligono.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			poligono.polygon = limpio
			if ignorar_rotacion:
				poligono.rotation = -rotation
			add_child(poligono)
			_poligonos.append(poligono)


# Dónde va cada copia en modo Repetir. Cada copia mide de alto lo mismo que el
# bloque (por la escala) y mantiene su proporción; se usan copias enteras,
# apenas estiradas o achicadas, para que entren justas a lo largo del bloque
func _copias_repetidas(parte: Rect2, caja: Rect2) -> Array[Rect2]:
	var copias: Array[Rect2] = []
	var alto := caja.size.y * escala_textura
	var ancho := alto * parte.size.x / parte.size.y
	if ancho <= 0.0:
		return copias
	# Con solape, cada copia avanza solo una parte de su ancho
	var avance := 1.0 - solape_copias
	var cantidad := maxi(1, roundi((caja.size.x - ancho) / (ancho * avance)) + 1)
	var w := caja.size.x / (1.0 + (cantidad - 1) * avance)
	for i in cantidad:
		var x := caja.position.x + w * avance * i
		copias.append(Rect2(Vector2(x, caja.position.y) + ajuste_textura, Vector2(w, alto)))
	return copias


# Dónde va cada copia en modo Apilar. Cada copia mide de ancho lo mismo que el
# bloque (por la escala) y mantiene su proporción; se usan copias enteras,
# apenas estiradas o achicadas, para que entren justas a lo alto del bloque
func _copias_apiladas(parte: Rect2, caja: Rect2) -> Array[Rect2]:
	var copias: Array[Rect2] = []
	var ancho := caja.size.x * escala_textura
	var alto := ancho * parte.size.y / parte.size.x
	if alto <= 0.0:
		return copias
	var cantidad := maxi(1, roundi(caja.size.y / alto))
	var h := caja.size.y / cantidad
	for i in cantidad:
		var y := caja.position.y + h * i
		copias.append(Rect2(Vector2(caja.get_center().x - ancho / 2, y) + ajuste_textura, Vector2(ancho, h)))
	return copias


func _draw() -> void:
	if textura:
		_dibujar_textura()
		return
	draw_rect(Rect2(-tamano / 2, tamano), color)
