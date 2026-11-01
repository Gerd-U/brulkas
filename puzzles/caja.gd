
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

## Gravedad
@export var gravedad: float = 1100.0
@export var max_caida: float = 600.0

var is_grabbed: bool = false


func _ready() -> void:
	_actualizar()

	# Todas las cajas se agregan automáticamente al grupo
	if not Engine.is_editor_hint():
		add_to_group("cajas")


# ---------- Actualizar tamaño y colisión ----------

func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if forma == null:
		return

	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect

	# La base de la caja queda en y = 0
	forma.position = Vector2(0, -tamano.y / 2)

	queue_redraw()


# ---------- Métodos utilizados por Player.gd ----------

# El jugador mueve la caja horizontalmente
func mover(dx: float) -> void:
	if Engine.is_editor_hint():
		return

	# Si el jugador está parado encima, no se puede empujar desde arriba
	if _jugador_encima():
		is_grabbed = false
		return

	is_grabbed = true
	move_and_collide(Vector2(dx, 0.0))


# true si el jugador está apoyado sobre la parte de arriba de esta caja
func _jugador_encima() -> bool:
	var jugador := get_tree().get_first_node_in_group("jugador") as CharacterBody2D

	if jugador == null:
		return false

	for i in jugador.get_slide_collision_count():
		var choque := jugador.get_slide_collision(i)
		# La normal apunta hacia arriba cuando el jugador pisa la caja
		if choque.get_collider() == self and choque.get_normal().y < -0.5:
			return true

	return false


# El jugador suelta la caja
func soltar() -> void:
	is_grabbed = false


# Compatibilidad con otros scripts que utilicen este método
func set_grabbed(valor: bool) -> void:
	is_grabbed = valor


# ---------- Gravedad ----------

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	velocity.x = 0.0
	velocity.y = min(velocity.y + gravedad * delta, max_caida)

	move_and_slide()


# ---------- Dibujo de la caja ----------

func _draw() -> void:
	var r := Rect2(-tamano.x / 2, -tamano.y, tamano.x, tamano.y)

	var borde := color.darkened(0.4)

	draw_rect(r, color)
	draw_rect(r, borde, false, 3.0)

	draw_line(r.position, r.end, borde, 3.0)

	draw_line(
		Vector2(r.position.x, r.end.y),
		Vector2(r.end.x, r.position.y),
		borde,
		3.0
	)
