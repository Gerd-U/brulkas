@tool
extends Area2D

## Ancho de la trampa
@export var ancho: float = 70.0:
	set(valor):
		ancho = max(10.0, valor)
		_actualizar()

## Alto de la trampa (cuando está cerrada)
@export var alto: float = 30.0:
	set(valor):
		alto = max(5.0, valor)
		_actualizar()

## Segundos que tarda en volver a abrirse después de atrapar al jugador
@export var tiempo_reabrir: float = 1.5

## Color del metal (si no tiene imagen)
@export var color: Color = Color(0.55, 0.55, 0.6):
	set(valor):
		color = valor
		queue_redraw()

@export_group("Imagen")
## Las imágenes vienen del AnimatedSprite2D hijo: el cuadro 0 es el cepo abierto
## y el 1 el cerrado. El abierto se ajusta al ancho y alto de la trampa.
## Mueve el dibujo (en píxeles) por si queda corrido
@export var ajuste_textura: Vector2 = Vector2.ZERO:
	set(valor):
		ajuste_textura = valor
		_actualizar()

## Agranda o achica el dibujo desde la base (1 = tamaño normal)
@export var escala_textura: float = 1.0:
	set(valor):
		escala_textura = valor
		_actualizar()

@export_group("Colisión")
## Baja el borde de arriba de la zona que atrapa (en píxeles)
@export var recorte_arriba: float = 0.0:
	set(valor):
		recorte_arriba = valor
		_actualizar()

## Achica la zona que atrapa de cada costado (en píxeles)
@export var recorte_lados: float = 0.0:
	set(valor):
		recorte_lados = valor
		_actualizar()

## La zona que atrapa toma la forma del cepo abierto dibujado
@export var colision_por_forma: bool = false:
	set(valor):
		colision_por_forma = valor
		_actualizar()

@export_group("Sonido")
## Volumen al cerrarse (Brulkas 004 - Trampa)
@export var volumen_trampa: float = -1.5
## Distancia en píxeles a partir de la cual ya no se escucha
@export var distancia_sonido: float = 1200.0
## Segundo del archivo desde donde empieza a sonar (0 = desde el principio).
## El golpe fuerte del archivo está cerca de los 0.5 s.
@export var inicio_sonido: float = 0.0

const SONIDO_TRAMPA := "res://audio/sfx/Brulkas 004 - Trampa.mp3"

var _cerrado := false      # está cerrada ahora mismo
var _desarmado := false    # una caja la cerró: ya no hace daño nunca más
var _forma_dibujo: CollisionPolygon2D  # zona con la forma del dibujo, si se usa
var _sonido: AudioStreamPlayer2D  # suena al cerrarse


func _ready() -> void:
	_actualizar()
	# Solo en el juego escuchamos cuando algo la pisa
	if not Engine.is_editor_hint():
		body_entered.connect(_al_pisar)
		_sonido = AudioStreamPlayer2D.new()
		_sonido.stream = load(SONIDO_TRAMPA)
		_sonido.bus = &"Efectos"
		_sonido.volume_db = volumen_trampa
		_sonido.max_distance = distancia_sonido
		add_child(_sonido)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho - recorte_lados * 2, alto - recorte_arriba)
	forma.shape = rect
	# Base en y = 0, igual que los pinchos
	forma.position = Vector2(0, -rect.size.y / 2)

	_acomodar_dibujo()

	# Zona con la forma del cepo abierto (en vez del rectángulo)
	if _forma_dibujo:
		_forma_dibujo.queue_free()
		_forma_dibujo = null
	var abierto := _textura_abierto()
	var usar_forma := colision_por_forma and abierto != null and is_inside_tree()
	forma.disabled = usar_forma
	if usar_forma:
		_forma_dibujo = CollisionPolygon2D.new()
		_forma_dibujo.polygon = TexturaUtil.envolvente(abierto, _rect_dibujo())
		add_child(_forma_dibujo)
	_mostrar_estado()


# El AnimatedSprite2D hijo (si tiene cuadros)
func _sprite() -> AnimatedSprite2D:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
		return sprite
	return null


func _textura_abierto() -> Texture2D:
	var sprite := _sprite()
	if sprite == null:
		return null
	return sprite.sprite_frames.get_frame_texture(sprite.animation, 0)


# Dónde queda la parte visible del cepo abierto
func _rect_dibujo() -> Rect2:
	var tam := Vector2(ancho, alto) * escala_textura
	return Rect2(Vector2(-tam.x / 2, -tam.y) + ajuste_textura, tam)


# Escala y ubica el sprite para que el cepo abierto ocupe ancho x alto.
# El cerrado usa el mismo lienzo, así que queda alineado solo.
func _acomodar_dibujo() -> void:
	var abierto := _textura_abierto()
	if abierto == null:
		return
	var sprite := _sprite()
	var parte := TexturaUtil.parte_visible(abierto)
	var destino := _rect_dibujo()
	sprite.centered = false
	sprite.scale = destino.size / parte.size
	sprite.position = destino.position - parte.position * sprite.scale


# Muestra el cuadro que corresponde: abierto o cerrado
func _mostrar_estado() -> void:
	var sprite := _sprite()
	if sprite:
		sprite.stop()
		sprite.frame = 1 if _cerrado else 0
	queue_redraw()


func _al_pisar(cuerpo: Node2D) -> void:
	if _cerrado:
		return

	# ¿Es una caja? → se cierra y queda desarmada para siempre
	if cuerpo.is_in_group("cajas"):
		_cerrado = true
		_desarmado = true
		_mostrar_estado()
		_sonido.play(inicio_sonido)
		return

	# ¿Es el jugador? → se cierra y lo mata
	if cuerpo.has_method("morir"):
		_cerrado = true
		_mostrar_estado()
		_sonido.play(inicio_sonido)
		# El sonido de la trampa reemplaza al de muerte, para que no se encimen
		var audio := get_node_or_null("/root/Audio")
		if audio:
			audio.callar_muerte()
		cuerpo.morir()
		# Esperamos un rato y la volvemos a abrir
		await get_tree().create_timer(tiempo_reabrir).timeout
		if not _desarmado:
			_cerrado = false
			_mostrar_estado()


func _draw() -> void:
	# Con imágenes dibuja el AnimatedSprite2D
	if _sprite():
		return

	var w := ancho
	var oscuro := color.darkened(0.4)

	# Base (siempre se ve)
	draw_rect(Rect2(-w / 2, -6, w, 6), oscuro)

	if not _cerrado:
		# ABIERTA: fila de dientes apuntando hacia arriba
		var dientes := 6
		var paso := w / dientes
		for i in dientes:
			var x := -w / 2 + i * paso
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, -6),
				Vector2(x + paso / 2, -6 - alto * 0.5),
				Vector2(x + paso, -6),
			]), color)
	else:
		# CERRADA: las dos mandíbulas levantadas, juntas en el centro
		draw_colored_polygon(PackedVector2Array([
			Vector2(-w / 2, -6), Vector2(-4, -alto), Vector2(0, -6),
		]), color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -6), Vector2(4, -alto), Vector2(w / 2, -6),
		]), color.darkened(0.15))
