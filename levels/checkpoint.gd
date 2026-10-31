@tool
extends Area2D

## Alto de la zona invisible (en píxeles)
@export var alto: float = 300.0:
	set(valor):
		alto = max(10.0, valor)
		_actualizar()

## Ancho de la zona invisible (en píxeles)
@export var ancho: float = 40.0:
	set(valor):
		ancho = max(10.0, valor)
		_actualizar()

## Dónde reaparece el jugador, medido desde la base del checkpoint.
## Lo subimos un poco para que no aparezca enterrado en el suelo.
@export var punto_reaparicion: Vector2 = Vector2(0, -50):
	set(valor):
		punto_reaparicion = valor
		queue_redraw()

# Para que solo se active una vez
var _activado := false


func _ready() -> void:
	_actualizar()
	# Solo en el juego (no en el editor) escuchamos cuando algo entra
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, alto)
	forma.shape = rect
	# Subimos la forma para que la base quede en y = 0
	forma.position = Vector2(0, -alto / 2)
	queue_redraw()


func _al_entrar(cuerpo: Node2D) -> void:
	if _activado:
		return
	# Solo el jugador tiene die(), así sabemos que es él
	if not cuerpo.has_method("die"):
		return

	# Buscamos el GameManager de Key (si existe)
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return

	_activado = true
	gm.set_checkpoint(global_position + punto_reaparicion)


func _draw() -> void:
	# Solo se dibuja en el editor: en el juego es invisible
	if not Engine.is_editor_hint():
		return
	var zona := Rect2(-ancho / 2, -alto, ancho, alto)
	draw_rect(zona, Color(0.2, 1.0, 0.4, 0.15))          # relleno verde clarito
	draw_rect(zona, Color(0.2, 1.0, 0.4, 0.8), false, 2.0)  # borde verde
	draw_circle(punto_reaparicion, 6.0, Color(1, 1, 0.3))   # punto amarillo: donde reaparece
