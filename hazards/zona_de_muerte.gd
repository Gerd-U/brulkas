@tool
extends Area2D

## Ancho de la zona (en píxeles)
@export var ancho: float = 4000.0:
	set(valor):
		ancho = max(10.0, valor)
		_actualizar()

## Alto de la zona (en píxeles)
@export var alto: float = 200.0:
	set(valor):
		alto = max(10.0, valor)
		_actualizar()


func _ready() -> void:
	_actualizar()
	# Solo en el juego (no en el editor) escuchamos cuando algo cae
	if not Engine.is_editor_hint():
		body_entered.connect(_al_caer)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, alto)
	forma.shape = rect
	queue_redraw()


func _al_caer(cuerpo: Node2D) -> void:
	if cuerpo.has_method("die"):
		cuerpo.die()


func _draw() -> void:
	# Solo se dibuja en el editor: en el juego es invisible
	if not Engine.is_editor_hint():
		return
	var zona := Rect2(-ancho / 2, -alto / 2, ancho, alto)
	draw_rect(zona, Color(1.0, 0.2, 0.2, 0.15))           # relleno rojo clarito
	draw_rect(zona, Color(1.0, 0.2, 0.2, 0.8), false, 2.0)  # borde rojo
