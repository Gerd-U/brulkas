extends Node2D

# Límites de la cámara del jugador para este nivel
@export var limite_izquierdo: int = 0
@export var limite_derecho: int = 0
@export var limite_arriba: int = 0
@export var limite_abajo: int = 0

@export_group("Zoom de la cámara")
## Zoom mientras se juega (más alto = más cerca)
@export var zoom_cerca: float = 1.5
## Zoom cuando el jugador se queda quieto
@export var zoom_lejos: float = 1.0
## Segundos quieto antes de que la cámara se aleje
@export var tiempo_quieto: float = 2.5
## Segundos que tarda en alejarse
@export var duracion_alejar: float = 1.5
## Segundos que tarda en volver a acercarse
@export var duracion_acercar: float = 0.5

const CamaraZoom := preload("res://levels/camara_zoom.gd")


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

	# Los sonidos posicionales (aplastador, cepo) se oyen desde el jugador,
	# no desde el centro de la cámara, que con el zoom puede quedar lejos de él
	var oido := AudioListener2D.new()
	oido.name = "Oido"
	jugador.add_child(oido)
	oido.make_current()

	# La cámara es hija del jugador
	var camara := jugador.get_node_or_null("Camera2D") as Camera2D
	if camara == null:
		return

	camara.limit_left = limite_izquierdo
	camara.limit_right = limite_derecho
	camara.limit_top = limite_arriba
	camara.limit_bottom = limite_abajo

	# El zoom (cerca al jugar, lejos al quedarse quieto) lo maneja otro nodo
	var zoom := CamaraZoom.new()
	zoom.name = "CamaraZoom"
	zoom.zoom_cerca = zoom_cerca
	zoom.zoom_lejos = zoom_lejos
	zoom.tiempo_quieto = tiempo_quieto
	zoom.duracion_alejar = duracion_alejar
	zoom.duracion_acercar = duracion_acercar
	add_child(zoom)
	zoom.configurar(camara, jugador)
