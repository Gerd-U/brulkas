@tool
extends Area2D

## Tamaño del alma (radio en píxeles)
@export var radio: float = 16.0:
	set(valor):
		radio = max(4.0, valor)
		_actualizar()

## Color de la luz
@export var color: Color = Color(0.85, 0.95, 1.0):
	set(valor):
		color = valor
		queue_redraw()

@export_group("Imagen")
## La animación viene del AnimatedSprite2D hijo (en bucle).
## Tamaño del dibujo (1 = cada cuadro a su tamaño original)
@export var escala_dibujo: float = 0.3:
	set(valor):
		escala_dibujo = valor
		_acomodar_dibujo()

## Cuadros por segundo de la animación
@export var fps: float = 11.0:
	set(valor):
		fps = max(0.1, valor)
		_acomodar_dibujo()

## Mueve el dibujo (en píxeles) por si queda corrido
@export var ajuste_textura: Vector2 = Vector2.ZERO:
	set(valor):
		ajuste_textura = valor
		_acomodar_dibujo()

## Dibuja un brillo suave detrás del alma
@export var brillo: bool = true:
	set(valor):
		brillo = valor
		queue_redraw()

# Para que solo se recoja una vez
var _recogida := false


func _ready() -> void:
	_actualizar()
	_acomodar_dibujo()
	var sprite := _sprite()
	if sprite:
		sprite.play()
	# Solo en el juego (no en el editor) escuchamos cuando algo la toca
	if not Engine.is_editor_hint():
		body_entered.connect(_al_tocar)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	forma.shape = circulo
	queue_redraw()


# El AnimatedSprite2D hijo (si tiene cuadros)
func _sprite() -> AnimatedSprite2D:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
		return sprite
	return null


func _acomodar_dibujo() -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	sprite.centered = true
	sprite.position = ajuste_textura
	sprite.scale = Vector2(escala_dibujo, escala_dibujo)
	# La velocidad base está en el SpriteFrames; la ajustamos a los fps pedidos
	var base := sprite.sprite_frames.get_animation_speed(sprite.animation)
	sprite.speed_scale = fps / base if base > 0.0 else 1.0
	queue_redraw()


func _al_tocar(cuerpo: Node2D) -> void:
	if _recogida:
		return
	# Solo el jugador tiene die(), así sabemos que es él
	if not cuerpo.is_in_group("jugador"):
		return

	_recogida = true
	hide()  # el alma desaparece

	# Le avisamos al GameManager de Key que el nivel terminó
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		# Primero se oscurece la pantalla y recién ahí se cambia de nivel
		var transicion := get_node_or_null("/root/Transicion")
		if transicion:
			transicion.fundir_y(gm.nivel_completado)
		else:
			# Diferido: no se puede cambiar de escena dentro de una señal de física
			gm.call_deferred("nivel_completado")


func _draw() -> void:
	if _sprite():
		# Con animación: solo un brillo suave detrás del dibujo
		if brillo:
			draw_circle(ajuste_textura, radio * 2.5, Color(color, 0.06))
			draw_circle(ajuste_textura, radio * 1.7, Color(color, 0.1))
		return

	# Brillo: círculos cada vez más grandes y más transparentes
	draw_circle(Vector2.ZERO, radio * 2.5, Color(color, 0.08))
	draw_circle(Vector2.ZERO, radio * 1.8, Color(color, 0.15))
	draw_circle(Vector2.ZERO, radio * 1.3, Color(color, 0.3))
	# Centro de la luz
	draw_circle(Vector2.ZERO, radio, color)
