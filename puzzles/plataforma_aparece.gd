@tool
extends StaticBody2D

## Tamaño de la plataforma (ancho, alto)
@export var tamano: Vector2 = Vector2(200, 40):
	set(valor):
		tamano = valor
		_actualizar()

## Color de la plataforma (si no tiene imagen)
@export var color: Color = Color(0.3, 0.3, 0.33):
	set(valor):
		color = valor
		queue_redraw()

## Segundos que tarda en aparecer (de transparente a visible)
@export var duracion: float = 0.6

## Segundos que espera antes de empezar a aparecer.
## Sirve para que varias aparezcan una tras otra, como una escalera.
@export var retraso: float = 0.0

@export_group("Imagen")
## Imagen de la plataforma. Si está vacía se dibuja el rectángulo de color.
@export var textura: Texture2D:
	set(valor):
		textura = valor
		queue_redraw()

## Rellenar: la imagen se estira al tamaño de la plataforma.
## Plataforma: la imagen toma el ancho sin aplastarse, y su borde
## de arriba queda donde camina el jugador; el resto cuelga hacia abajo.
@export_enum("Rellenar", "Plataforma") var modo_textura: int = 0:
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
## o más grueso (más de 1) sin cambiar su ancho ni la colisión
@export var grosor_textura: float = 1.0:
	set(valor):
		grosor_textura = valor
		queue_redraw()

@export_group("Colisión")
## La colisión toma la forma del dibujo (lo que no es transparente)
## en vez de ser un rectángulo
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

var _activa := false
var _poligonos: Array[CollisionPolygon2D] = []  # colisión con la forma del dibujo


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	# Al iniciar el juego: invisible y sin colisión
	modulate.a = 0.0
	_activar_colision(false)


# Prende o apaga la colisión (el rectángulo, o la forma del dibujo si se usa)
func _activar_colision(prendida: bool) -> void:
	var usar_forma := not _poligonos.is_empty()
	$CollisionShape2D.set_deferred("disabled", usar_forma or not prendida)
	for poligono in _poligonos:
		poligono.set_deferred("disabled", not prendida)


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


## La palanca llama esto para que aparezca
func activar() -> void:
	if _activa:
		return
	_activa = true
	var tween := create_tween()
	tween.tween_interval(retraso)
	# Se vuelve sólida
	tween.tween_callback(_activar_colision.bind(true))
	# Y aparece poco a poco
	tween.tween_property(self, "modulate:a", 1.0, duracion)


func _parte_visible() -> Rect2:
	return TexturaUtil.parte_visible(textura)


func _dibujar_textura(transparencia: float) -> void:
	var parte := _parte_visible()
	# La transparencia del juego la pone modulate.a (el efecto de aparecer)
	draw_texture_rect_region(textura, _rect_dibujo(parte), parte, Color(1, 1, 1, transparencia))


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


func _draw() -> void:
	var c := color
	# En el editor se ve medio transparente para saber que "aparece"
	if Engine.is_editor_hint():
		c.a = 0.4
	if textura:
		_dibujar_textura(c.a)
		return
	var r := Rect2(-tamano / 2, tamano)
	draw_rect(r, c)
	draw_rect(r, c.darkened(0.4), false, 2.0)
