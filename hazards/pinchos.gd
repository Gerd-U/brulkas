@tool
extends Area2D

## Cuántos pinchos seguidos hay
@export var cantidad: int = 2:
	set(valor):
		cantidad = max(1, valor)
		_actualizar()

## Ancho de cada pincho en píxeles
@export var ancho: float = 32.0:
	set(valor):
		ancho = max(4.0, valor)
		_actualizar()

## Altura de los pinchos en píxeles
@export var alto: float = 20.0:
	set(valor):
		alto = max(4.0, valor)
		_actualizar()

## Color de los pinchos
@export var color: Color = Color(0.75, 0.75, 0.8):
	set(valor):
		color = valor
		queue_redraw()


func _ready() -> void:
	_actualizar()
	# Solo en el juego (no en el editor) escuchamos cuando algo nos toca
	if not Engine.is_editor_hint():
		body_entered.connect(_al_tocar)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho * cantidad, alto)
	forma.shape = rect
	# Subimos la forma media altura para que la base quede en y = 0
	forma.position = Vector2(0, -alto / 2)
	queue_redraw()


func _draw() -> void:
	var inicio := -ancho * cantidad / 2.0
	for i in cantidad:
		var x := inicio + i * ancho
		var triangulo := PackedVector2Array([
			Vector2(x, 0),                  # esquina abajo-izquierda
			Vector2(x + ancho / 2, -alto),  # punta de arriba
			Vector2(x + ancho, 0),          # esquina abajo-derecha
		])
		draw_colored_polygon(triangulo, color)


func _al_tocar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("morir"):
		cuerpo.morir()
