extends Node
# Controla el zoom de la cámara del jugador:
# de cerca mientras juega, y se aleja si se queda quieto un rato.
# nivel.gd lo crea y le pasa la cámara y el jugador con configurar().

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
## Qué tan rápido sigue la cámara al jugador (suavizado)
@export var velocidad_seguimiento: float = 6.0

# Si el jugador se mueve más que esto en un cuadro, es que reapareció
const SALTO_REAPARECER := 200.0

var _camara: Camera2D
var _jugador  # el jugador (CharacterBody2D con is_dead)
var _quieto := 0.0       # segundos que lleva quieto
var _alejada := false    # true si la cámara está (o va) hacia el zoom lejano
var _tween: Tween
var _posicion_anterior := Vector2.ZERO


func configurar(camara: Camera2D, jugador: Node2D) -> void:
	_camara = camara
	_jugador = jugador
	_camara.position_smoothing_enabled = true
	_camara.position_smoothing_speed = velocidad_seguimiento
	_camara.zoom = Vector2(zoom_cerca, zoom_cerca)
	_camara.reset_smoothing()
	_posicion_anterior = jugador.global_position


# Como este nodo se pausa con el juego, mientras está en pausa
# no corre _process y el temporizador no avanza.
func _process(delta: float) -> void:
	if not is_instance_valid(_camara) or not is_instance_valid(_jugador):
		return

	# Si el jugador reapareció lejos, la cámara salta con él en vez de cruzar el nivel
	if _jugador.global_position.distance_to(_posicion_anterior) > SALTO_REAPARECER:
		_camara.reset_smoothing()
	_posicion_anterior = _jugador.global_position

	# Muerto o reapareciendo: nada de alejarse, y vuelve al zoom cercano
	if _jugador.get("is_dead"):
		_quieto = 0.0
		if _alejada:
			_ir_a_zoom(zoom_cerca, duracion_acercar)
			_alejada = false
		return

	if _esta_quieto():
		_quieto += delta
		if _quieto >= tiempo_quieto and not _alejada:
			_ir_a_zoom(zoom_lejos, duracion_alejar)
			_alejada = true
	else:
		_quieto = 0.0
		if _alejada:
			_ir_a_zoom(zoom_cerca, duracion_acercar)
			_alejada = false


# Quieto = en el suelo, casi sin velocidad y sin apretar moverse ni saltar
func _esta_quieto() -> bool:
	if not _jugador.is_on_floor():
		return false
	if _jugador.velocity.length() > 5.0:
		return false
	for accion in ["move_left", "move_right", "jump"]:
		if Input.is_action_pressed(accion):
			return false
	return true


func _ir_a_zoom(valor: float, duracion: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_camara, "zoom", Vector2(valor, valor), duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
