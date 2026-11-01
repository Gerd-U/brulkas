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

# Parte visible (sin bordes transparentes) de cada imagen, se calcula una sola vez
static var _partes_visibles := {}

var _activa := false


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	# Al iniciar el juego: invisible y sin colisión
	modulate.a = 0.0
	$CollisionShape2D.set_deferred("disabled", true)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	queue_redraw()


## La palanca llama esto para que aparezca
func activar() -> void:
	if _activa:
		return
	_activa = true
	var tween := create_tween()
	tween.tween_interval(retraso)
	# Se vuelve sólida
	tween.tween_callback(func(): $CollisionShape2D.disabled = false)
	# Y aparece poco a poco
	tween.tween_property(self, "modulate:a", 1.0, duracion)


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


func _dibujar_textura(transparencia: float) -> void:
	var parte := _parte_visible()
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
	destino = Rect2(arriba - Vector2(tam.x / 2, 0) + ajuste_textura, tam)

	# La transparencia del juego la pone modulate.a (el efecto de aparecer)
	draw_texture_rect_region(textura, destino, parte, Color(1, 1, 1, transparencia))


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
