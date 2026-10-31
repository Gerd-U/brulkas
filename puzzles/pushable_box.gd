class_name PushableBox
extends CharacterBody2D

@export var gravity: float = 1100.0
@export var max_fall_speed: float = 600.0

var is_grabbed: bool = false


func set_grabbed(value: bool) -> void:
	is_grabbed = value


# Lo usa el Player para mover la caja. Devuelve cuánto se movió realmente.
func move_x(dx: float) -> float:
	var collision := move_and_collide(Vector2(dx, 0.0))
	if collision:
		return collision.get_travel().x
	return dx


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	move_and_slide()
