@tool
extends StaticBody2D

## Tamaño del bloque en píxeles (ancho, alto)
@export var tamano: Vector2 = Vector2(200, 40):
	set(valor):
		tamano = valor
		_actualizar()

## Color con el que se dibuja el bloque
@export var color: Color = Color(0.15, 0.15, 0.17):
	set(valor):
		color = valor
		queue_redraw()


func _ready() -> void:
	_actualizar()


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-tamano / 2, tamano), color)
