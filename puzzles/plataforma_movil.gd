@tool
extends AnimatableBody2D

## Tamaño de la plataforma (ancho, alto)
@export var tamano: Vector2 = Vector2(160, 30):
	set(valor):
		tamano = valor
		_actualizar()

## Hacia dónde y cuánto se mueve desde donde está.
## (300, 0) = 300 px a la derecha.  (0, -200) = 200 px hacia arriba.
@export var recorrido: Vector2 = Vector2(300, 0):
	set(valor):
		recorrido = valor
		queue_redraw()

## Segundos que tarda en ir de una punta a la otra
@export var duracion: float = 2.5

## Segundos que se queda quieta en cada punta
@export var espera: float = 0.5

## Si está marcada, se mueve desde el inicio.
## Si no, espera a que una palanca le llame activar().
@export var empieza_activa: bool = true

## Color de la plataforma (si no tiene imagen)
@export var color: Color = Color(0.3, 0.3, 0.33):
	set(valor):
		color = valor
		queue_redraw()

@export_group("Imagen")
## Imagen de la plataforma. Si está vacía se dibuja el rectángulo de color.
@export var textura: Texture2D:
	set(valor):
		textura = valor
		_actualizar()

## Rellenar: la imagen se estira al tamaño de la plataforma.
## Plataforma: la imagen toma el ancho sin aplastarse, y su borde
## de arriba queda donde camina el jugador; el resto cuelga hacia abajo.
@export_enum("Rellenar", "Plataforma") var modo_textura: int = 0:
	set(valor):
		modo_textura = valor
		_actualizar()

## Mueve la imagen (en píxeles) por si queda corrida
@export var ajuste_textura: Vector2 = Vector2.ZERO:
	set(valor):
		ajuste_textura = valor
		_actualizar()

## Agranda o achica la imagen (1 = tamaño normal)
@export var escala_textura: float = 1.0:
	set(valor):
		escala_textura = valor
		_actualizar()

## Solo en modo Plataforma: hace el dibujo más delgado (menos de 1)
## o más grueso (más de 1) sin cambiar su ancho
@export var grosor_textura: float = 1.0:
	set(valor):
		grosor_textura = valor
		_actualizar()

@export_group("Colisión")
## La colisión toma la forma del dibujo (lo que no es transparente)
## en vez de ser un rectángulo
@export var colision_por_forma: bool = false:
	set(valor):
		colision_por_forma = valor
		_actualizar()

## Cuánto se simplifica la forma: más alto = menos detalle y más suave
## para caminar; más bajo = sigue más los bordes del dibujo
@export var detalle_forma: float = 6.0:
	set(valor):
		detalle_forma = valor
		_actualizar()

## Forma lisa: une las puntas del dibujo con líneas rectas, sin entradas
## ni picos, para que el jugador y las cajas no se traben al moverse
@export var forma_lisa: bool = false:
	set(valor):
		forma_lisa = valor
		_actualizar()

# Parte visible (sin bordes transparentes) de cada imagen, se calcula una sola vez
static var _partes_visibles := {}

var _inicio: Vector2
var _activa := false
var _poligonos: Array[CollisionPolygon2D] = []  # colisión con la forma del dibujo


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	_inicio = position
	if empieza_activa:
		_empezar()


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	if is_inside_tree():
		_crear_colision_por_forma()
	queue_redraw()


## La palanca llama esto para encenderla
func activar() -> void:
	if not _activa:
		_empezar()


func _empezar() -> void:
	_activa = true
	var tween := create_tween()
	tween.set_loops()  # se repite para siempre
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Ida
	tween.tween_property(self, "position", _inicio + recorrido, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(espera)
	# Vuelta
	tween.tween_property(self, "position", _inicio, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(espera)


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


# Rectángulo exacto donde queda la imagen
func _rect_dibujo(parte: Rect2) -> Rect2:
	var destino := Rect2(-tamano / 2, tamano)
	if modo_textura == 1:
		# Plataforma: mismo ancho, sin aplastar, colgando desde el borde de arriba
		destino.size.y = tamano.x * parte.size.y / parte.size.x * grosor_textura

	# La escala se aplica desde el centro (en Plataforma, desde el centro de arriba,
	# así el borde donde se camina no se mueve)
	var tam := destino.size * escala_textura
	var arriba := Vector2(destino.get_center().x, destino.position.y)
	if modo_textura == 0:
		arriba.y = destino.get_center().y - tam.y / 2
	return Rect2(arriba - Vector2(tam.x / 2, 0) + ajuste_textura, tam)


func _crear_colision_por_forma() -> void:
	for poligono in _poligonos:
		poligono.queue_free()
	_poligonos.clear()

	var rectangulo := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var usar_forma := colision_por_forma and textura != null
	var imagen: Image = textura.get_image() if usar_forma else null
	if rectangulo:
		rectangulo.disabled = imagen != null
	if imagen == null:
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
		# Juntamos todos los puntos y los envolvemos con una sola forma sin entradas
		var todos := PackedVector2Array()
		for contorno in contornos:
			for punto in contorno:
				todos.append(destino.position + punto * escala)
		var lisa := Geometry2D.convex_hull(todos)
		if lisa.size() > 3:
			lisa.remove_at(lisa.size() - 1)  # el último punto repite el primero
			var envolvente := CollisionPolygon2D.new()
			envolvente.polygon = lisa
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
			add_child(poligono)
			_poligonos.append(poligono)


func _draw() -> void:
	if textura:
		draw_texture_rect_region(textura, _rect_dibujo(_parte_visible()), _parte_visible())
	else:
		var r := Rect2(-tamano / 2, tamano)
		draw_rect(r, color)
		draw_rect(r, color.darkened(0.4), false, 2.0)

	# Solo en el editor: línea del recorrido y un "fantasma" de dónde llega
	if Engine.is_editor_hint():
		var amarillo := Color(1, 1, 0.3, 0.8)
		draw_dashed_line(Vector2.ZERO, recorrido, amarillo, 2.0, 10.0)
		draw_rect(Rect2(recorrido - tamano / 2, tamano), amarillo, false, 2.0)
