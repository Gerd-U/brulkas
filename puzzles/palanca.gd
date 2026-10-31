@tool
extends Area2D

## Las cosas que se activan con esta palanca.
## Cualquier nodo que tenga una función activar() sirve.
@export var objetivos: Array[Node] = []:
	set(valor):
		objetivos = valor
		queue_redraw()

## Tamaño de la zona donde el jugador puede usarla (ancho, alto)
@export var zona: Vector2 = Vector2(80, 80):
	set(valor):
		zona = valor
		_actualizar()

## Color de la palanca
@export var color: Color = Color(0.55, 0.45, 0.35):
	set(valor):
		color = valor
		queue_redraw()

## Dónde reaparece el jugador después de activarla (igual que un checkpoint)
@export var punto_reaparicion: Vector2 = Vector2(0, -50)

var _activada := false
# -1 = manija a la izquierda, 1 = a la derecha (se anima entre los dos)
var _inclinacion := -1.0:
	set(valor):
		_inclinacion = valor
		queue_redraw()


func _ready() -> void:
	_actualizar()


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = zona
	forma.shape = rect
	# Base en y = 0, igual que los otros objetos
	forma.position = Vector2(0, -zona.y / 2)
	queue_redraw()


## El jugador de Key llama esto cuando aprieta E cerca de la palanca
func interact(_jugador: Node) -> void:
	if _activada:
		return
	_activada = true
	# La manija gira hacia el otro lado
	var tween := create_tween()
	tween.tween_property(self, "_inclinacion", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for objetivo in objetivos:
		if objetivo and objetivo.has_method("activar"):
			objetivo.activar()

	# La palanca también funciona como checkpoint
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.guardar_checkpoint(global_position + punto_reaparicion)


func _draw() -> void:
	# Base
	draw_rect(Rect2(-14, -10, 28, 10), color.darkened(0.4))
	# Manija: inclinada a la izquierda si está apagada, a la derecha si se activó
	var angulo := 0.6 * _inclinacion
	var punta := Vector2(0, -8) + Vector2(sin(angulo), -cos(angulo)) * 32.0
	draw_line(Vector2(0, -8), punta, color, 5.0)
	draw_circle(punta, 6.0, color.lightened(0.2))

	# Solo en el editor: líneas hacia cada objetivo, para ver qué activa
	if Engine.is_editor_hint():
		for objetivo in objetivos:
			if objetivo is Node2D:
				var destino := to_local(objetivo.global_position)
				draw_dashed_line(Vector2(0, -20), destino, Color(1, 0.6, 0.2, 0.7), 2.0, 12.0)
