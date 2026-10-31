@tool
extends AnimatableBody2D

## Tamaño de la roca (ancho, alto)
@export var tamano: Vector2 = Vector2(160, 50):
	set(valor):
		tamano = valor
		_actualizar()

## Cuántos píxeles sube
@export var altura: float = 730.0:
	set(valor):
		altura = valor
		queue_redraw()

## Cuántos segundos tarda en subir
@export var duracion: float = 4.0

## Cuántos segundos espera antes de empezar a subir
@export var espera: float = 0.5

## Color de la roca
@export var color: Color = Color(0.35, 0.35, 0.38):
	set(valor):
		color = valor
		queue_redraw()

var _arriba := false    # true cuando está en la parte de arriba
var _moviendo := false  # para no empezar otro viaje a la mitad


func _ready() -> void:
	_actualizar()
	# Solo en el juego escuchamos cuando alguien se sube
	if not Engine.is_editor_hint():
		$Sensor.body_entered.connect(_al_subir)


func _actualizar() -> void:
	# Forma sólida de la roca (con la base en y = 0)
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma:
		var rect := RectangleShape2D.new()
		rect.size = tamano
		forma.shape = rect
		forma.position = Vector2(0, -tamano.y / 2)

	# Sensor: una franja delgadita justo encima de la roca
	var sensor := get_node_or_null("Sensor/CollisionShape2D") as CollisionShape2D
	if sensor:
		var rect2 := RectangleShape2D.new()
		rect2.size = Vector2(tamano.x - 10, 16)
		sensor.shape = rect2
		sensor.position = Vector2(0, -tamano.y - 8)

	queue_redraw()


func _al_subir(cuerpo: Node2D) -> void:
	if _moviendo:
		return
	# Solo el jugador tiene die(), así sabemos que es él
	if not cuerpo.is_in_group("jugador"):
		return
	_moviendo = true

	# Si está abajo sube, si está arriba baja
	var destino := position.y + altura if _arriba else position.y - altura
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_interval(espera)
	tween.tween_property(self, "position:y", destino, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_arriba = not _arriba
	_moviendo = false


func _draw() -> void:
	var w := tamano.x
	var h := tamano.y
	# Forma de piedra: un rectángulo con las esquinas de arriba cortadas
	var roca := PackedVector2Array([
		Vector2(-w * 0.5, 0),
		Vector2(-w * 0.5, -h * 0.6),
		Vector2(-w * 0.35, -h),
		Vector2(w * 0.35, -h),
		Vector2(w * 0.5, -h * 0.6),
		Vector2(w * 0.5, 0),
	])
	draw_colored_polygon(roca, color)

	# Solo en el editor: línea que muestra hasta dónde va a subir
	if Engine.is_editor_hint():
		var arriba := Vector2(0, -h - altura)
		draw_dashed_line(Vector2(0, -h), arriba, Color(1, 1, 0.3, 0.8), 2.0, 10.0)
		draw_line(arriba + Vector2(-w * 0.5, 0), arriba + Vector2(w * 0.5, 0), Color(1, 1, 0.3), 3.0)
