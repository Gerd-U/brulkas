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

# Para que solo se recoja una vez
var _recogida := false


func _ready() -> void:
	_actualizar()
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
		# Diferido: no se puede cambiar de escena dentro de una señal de física
		gm.call_deferred("nivel_completado")


func _draw() -> void:
	# Brillo: círculos cada vez más grandes y más transparentes
	draw_circle(Vector2.ZERO, radio * 2.5, Color(color, 0.08))
	draw_circle(Vector2.ZERO, radio * 1.8, Color(color, 0.15))
	draw_circle(Vector2.ZERO, radio * 1.3, Color(color, 0.3))
	# Centro de la luz
	draw_circle(Vector2.ZERO, radio, color)
