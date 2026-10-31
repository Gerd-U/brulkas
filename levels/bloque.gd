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

## Si se desactiva, el jugador que se pare encima es empujado hacia un costado
@export var se_puede_pisar: bool = true

const EMPUJE := 320.0  # velocidad con que tira al jugador si se sube encima

var _techo: Area2D  # franja encima del bloque (solo si no se puede pisar)


func _ready() -> void:
	_actualizar()
	if not Engine.is_editor_hint() and not se_puede_pisar:
		_crear_techo()


func _crear_techo() -> void:
	# Franja delgadita justo encima del bloque que detecta al jugador
	_techo = Area2D.new()
	_techo.collision_layer = 0
	_techo.collision_mask = 2  # capa del jugador
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tamano.x, 10)
	forma.shape = rect
	# Se mete 2 px dentro del bloque para detectar bien los pies del jugador
	forma.position = Vector2(0, -tamano.y / 2 - 3)
	_techo.add_child(forma)
	add_child(_techo)


func _physics_process(delta: float) -> void:
	if _techo == null:
		return
	# Si el jugador está parado arriba, lo empujamos hacia el lado más cercano
	for cuerpo in _techo.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador"):
			var lado := signf(cuerpo.global_position.x - global_position.x)
			if lado == 0.0:
				lado = 1.0
			cuerpo.global_position.x += lado * EMPUJE * delta


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
