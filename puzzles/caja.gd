@tool
class_name PushableBox
extends CharacterBody2D

## Tamaño de la caja en píxeles (ancho, alto)
@export var tamano: Vector2 = Vector2(64, 64):
	set(valor):
		tamano = valor
		_actualizar()

## Color de la caja
@export var color: Color = Color(0.45, 0.33, 0.22):
	set(valor):
		color = valor
		queue_redraw()

## Qué tan rápido cae
@export var gravedad: float = 1100.0
@export var max_caida: float = 600.0

# Si el jugador la tiene agarrada o no
var is_grabbed: bool = false


func _ready() -> void:
	_actualizar()


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	# Subimos la forma media altura para que la base quede en y = 0
	forma.position = Vector2(0, -tamano.y / 2)
	queue_redraw()


func _physics_process(delta: float) -> void:
	# En el editor no queremos que la caja se caiga
	if Engine.is_editor_hint():
		return
	# La caja nunca se mueve de lado sola: solo cae
	velocity.x = 0.0
	velocity.y = min(velocity.y + gravedad * delta, max_caida)
	move_and_slide()


# ---------- Métodos que usa el jugador de Key ----------

## El jugador avisa si la agarró o la soltó
func set_grabbed(valor: bool) -> void:
	is_grabbed = valor


## El jugador la mueve dx píxeles de lado.
## Devuelve cuánto se movió de verdad (menos si chocó con algo).
func move_x(dx: float) -> float:
	var choque := move_and_collide(Vector2(dx, 0.0))
	if choque:
		return choque.get_travel().x
	return dx


# ---------- Dibujo (hasta que haya arte) ----------

func _draw() -> void:
	var r := Rect2(-tamano.x / 2, -tamano.y, tamano.x, tamano.y)
	var borde := color.darkened(0.4)
	draw_rect(r, color)
	draw_rect(r, borde, false, 3.0)
	draw_line(r.position, r.end, borde, 3.0)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), borde, 3.0)
