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


var _jugador: Node2D = null  # el jugador mientras está dentro de la zona
var _lado := 0.0            # de qué lado del centro entró (-1 izquierda, 1 derecha)


func _ready() -> void:
	_actualizar()
	# Solo en el juego (no en el editor) escuchamos cuando algo entra
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)
		body_exited.connect(_al_salir)


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
	# Solo el jugador tiene die(), así sabemos que es él
	if not cuerpo.is_in_group("jugador"):
		return
	_jugador = cuerpo
	_lado = signf(cuerpo.global_position.x - global_position.x)


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo == _jugador:
		_jugador = null


func _physics_process(_delta: float) -> void:
	if _jugador == null:
		return
	# Solo cuenta cuando el centro del jugador cruza la línea del checkpoint,
	# no con rozar el borde de la zona
	var lado_actual := signf(_jugador.global_position.x - global_position.x)
	if lado_actual == _lado and lado_actual != 0.0:
		return
	_lado = lado_actual

	# Buscamos el GameManager de Key (si existe)
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return

	# Se guarda cada vez que el jugador pasa por aquí,
	# así también funciona cuando se devuelve
	gm.guardar_checkpoint(global_position + punto_reaparicion)


func _draw() -> void:
	# Solo se dibuja en el editor: en el juego es invisible
	if not Engine.is_editor_hint():
		return
	var zona := Rect2(-ancho / 2, -alto, ancho, alto)
	draw_rect(zona, Color(0.2, 1.0, 0.4, 0.15))             # relleno verde clarito
	draw_rect(zona, Color(0.2, 1.0, 0.4, 0.8), false, 2.0)  # borde verde
	draw_circle(punto_reaparicion, 6.0, Color(1, 1, 0.3))   # punto amarillo: donde reaparece
