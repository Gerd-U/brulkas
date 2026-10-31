extends Node2D

# Límites de la cámara del jugador para este nivel
@export var limite_izquierdo: int = 0
@export var limite_derecho: int = 0
@export var limite_arriba: int = 0
@export var limite_abajo: int = 0


func _ready() -> void:
	# Buscamos al jugador por su grupo
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	# Al empezar el nivel, el punto de reaparición es donde arranca el jugador
	# (si no, quedaría guardado el último checkpoint del nivel anterior)
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.guardar_checkpoint(jugador.global_position)

	# La cámara es hija del jugador
	var camara := jugador.get_node_or_null("Camera2D") as Camera2D
	if camara == null:
		return

	camara.limit_left = limite_izquierdo
	camara.limit_right = limite_derecho
	camara.limit_top = limite_arriba
	camara.limit_bottom = limite_abajo
