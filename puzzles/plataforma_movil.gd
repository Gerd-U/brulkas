@tool
extends AnimatableBody2D

## Tamaño de la plataforma (ancho, alto)
@export var tamano: Vector2 = Vector2(160, 30):
	set(valor):
		tamano = valor
		_actualizar()

## Hacia dónde y cuánto se mueve desde donde está.
## (300, 0) = 300 px a la derecha.  (0, -200) = 200 px hacia arriba.
@export var recorrido: Vector2 = Vector2(300, 0):
	set(valor):
		recorrido = valor
		queue_redraw()

## Segundos que tarda en ir de una punta a la otra
@export var duracion: float = 2.5

## Segundos que se queda quieta en cada punta
@export var espera: float = 0.5

## Si está marcada, se mueve desde el inicio.
## Si no, espera a que una palanca le llame activar().
@export var empieza_activa: bool = true

## Color de la plataforma
@export var color: Color = Color(0.3, 0.3, 0.33):
	set(valor):
		color = valor
		queue_redraw()

var _inicio: Vector2
var _activa := false


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	_inicio = position
	if empieza_activa:
		_empezar()


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	queue_redraw()


## La palanca llama esto para encenderla
func activar() -> void:
	if not _activa:
		_empezar()


func _empezar() -> void:
	_activa = true
	var tween := create_tween()
	tween.set_loops()  # se repite para siempre
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Ida
	tween.tween_property(self, "position", _inicio + recorrido, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(espera)
	# Vuelta
	tween.tween_property(self, "position", _inicio, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(espera)


func _draw() -> void:
	var r := Rect2(-tamano / 2, tamano)
	draw_rect(r, color)
	draw_rect(r, color.darkened(0.4), false, 2.0)

	# Solo en el editor: línea del recorrido y un "fantasma" de dónde llega
	if Engine.is_editor_hint():
		var amarillo := Color(1, 1, 0.3, 0.8)
		draw_dashed_line(Vector2.ZERO, recorrido, amarillo, 2.0, 10.0)
		draw_rect(Rect2(recorrido - tamano / 2, tamano), amarillo, false, 2.0)
