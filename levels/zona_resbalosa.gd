@tool
extends Area2D

## Largo de la zona: el mismo largo que la pendiente
@export var largo: float = 400.0:
	set(valor):
		largo = max(10.0, valor)
		_actualizar()

## Qué tan alta es la zona encima de la pendiente
@export var alto: float = 80.0:
	set(valor):
		alto = max(10.0, valor)
		_actualizar()

## Mitad del grosor de la pendiente (la pendiente mide 30, entonces 15).
## Sirve para que la zona empiece justo en la superficie, no en el centro.
@export var separacion: float = 15.0:
	set(valor):
		separacion = valor
		_actualizar()


func _ready() -> void:
	_actualizar()
	# Solo en el juego escuchamos cuando el jugador entra o sale
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)
		body_exited.connect(_al_salir)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(largo, alto)
	forma.shape = rect
	# La subimos para que quede encima de la superficie de la pendiente
	forma.position = Vector2(0, -separacion - alto / 2)
	queue_redraw()


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("set_sliding"):
		cuerpo.set_sliding(true)


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo.has_method("set_sliding"):
		cuerpo.set_sliding(false)


func _draw() -> void:
	# Solo se dibuja en el editor: en el juego es invisible
	if not Engine.is_editor_hint():
		return
	var zona := Rect2(-largo / 2, -separacion - alto, largo, alto)
	draw_rect(zona, Color(0.3, 0.6, 1.0, 0.15))           # relleno azul clarito
	draw_rect(zona, Color(0.3, 0.6, 1.0, 0.8), false, 2.0)  # borde azul
