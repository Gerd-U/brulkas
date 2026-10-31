@tool
extends StaticBody2D

## Tamaño de la plataforma (ancho, alto)
@export var tamano: Vector2 = Vector2(200, 40):
	set(valor):
		tamano = valor
		_actualizar()

## Color de la plataforma
@export var color: Color = Color(0.3, 0.3, 0.33):
	set(valor):
		color = valor
		queue_redraw()

## Segundos que tarda en aparecer (de transparente a visible)
@export var duracion: float = 0.6

## Segundos que espera antes de empezar a aparecer.
## Sirve para que varias aparezcan una tras otra, como una escalera.
@export var retraso: float = 0.0

var _activa := false


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	# Al iniciar el juego: invisible y sin colisión
	modulate.a = 0.0
	$CollisionShape2D.set_deferred("disabled", true)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	queue_redraw()


## La palanca llama esto para que aparezca
func activar() -> void:
	if _activa:
		return
	_activa = true
	var tween := create_tween()
	tween.tween_interval(retraso)
	# Se vuelve sólida
	tween.tween_callback(func(): $CollisionShape2D.disabled = false)
	# Y aparece poco a poco
	tween.tween_property(self, "modulate:a", 1.0, duracion)


func _draw() -> void:
	var c := color
	# En el editor se ve medio transparente para saber que "aparece"
	if Engine.is_editor_hint():
		c.a = 0.4
	var r := Rect2(-tamano / 2, tamano)
	draw_rect(r, c)
	draw_rect(r, c.darkened(0.4), false, 2.0)
