class_name Player
extends CharacterBody2D

# ---------- Movimiento ----------
@export var max_speed: float = 180.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var air_control: float = 0.7

# ---------- Salto y gravedad ----------
@export var jump_velocity: float = -380.0
@export var gravity: float = 1100.0
@export var fall_gravity_multiplier: float = 1.6
@export var jump_cut_multiplier: float = 0.45
@export var max_fall_speed: float = 600.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# ---------- Cajas ----------
@export var grab_speed_multiplier: float = 0.5
@export var push_speed: float = 70.0
@export var max_grab_distance: float = 40.0
@export var detector_reach: float = 14.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_dead: bool = false
var is_sliding: bool = false
var facing: int = 1
var spawn_position: Vector2
var grabbed_box: PushableBox = null
var interactable: Area2D = null

@onready var visuals: Node2D = $Visuals
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var box_detector: RayCast2D = $BoxDetector
@onready var interact_area: Area2D = $InteractArea
@onready var col_stand: CollisionShape2D = $CollisionShape2D
@onready var col_slide: CollisionShape2D = $CollisionSlide


func _ready() -> void:
	spawn_position = global_position
	if GameManager.has_checkpoint:
		global_position = GameManager.last_checkpoint_position
	box_detector.target_position = Vector2(detector_reach, 0.0)
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var input_dir := Input.get_axis("move_left", "move_right")

	_handle_grab()
	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_horizontal(input_dir, delta)
	_handle_interact()
	_move_and_push(delta)
	_update_facing(input_dir)
	_update_animation()


# ---------------- Gravedad ----------------
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		return
	coyote_timer -= delta
	var g := gravity
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier  # cae más rápido = se siente más firme
	velocity.y = min(velocity.y + g * delta, max_fall_speed)


# ---------------- Salto ----------------
func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if grabbed_box:
		return  # no se salta mientras se agarra una caja

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Salto variable: soltar el botón corta el impulso
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


# ---------------- Movimiento horizontal ----------------
func _handle_horizontal(input_dir: float, delta: float) -> void:
	var target_speed := max_speed
	if grabbed_box:
		target_speed *= grab_speed_multiplier

	var control := 1.0 if is_on_floor() else air_control

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * target_speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _update_facing(input_dir: float) -> void:
	# Con una caja agarrada no se voltea (así puede jalarla de espaldas)
	if grabbed_box or input_dir == 0.0:
		return
	facing = 1 if input_dir > 0.0 else -1
	box_detector.target_position.x = detector_reach * facing


# ---------------- Mover a Key y empujar/jalar cajas ----------------
func _move_and_push(delta: float) -> void:
	var start_x := global_position.x
	var pulling := false

	if grabbed_box and velocity.x != 0.0:
		var dir_to_box := signf(grabbed_box.global_position.x - global_position.x)
		if signf(velocity.x) == dir_to_box:
			# Empujando: la caja se mueve primero y Key avanza lo mismo
			var moved := grabbed_box.move_x(velocity.x * delta)
			velocity.x = moved / delta
		else:
			pulling = true  # Jalando: Key se mueve y la caja la sigue

	move_and_slide()

	if pulling:
		grabbed_box.move_x(global_position.x - start_x)
	elif not grabbed_box:
		# Empujar caminando contra la caja (sin agarrarla)
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var box := c.get_collider() as PushableBox
			if box and absf(c.get_normal().x) > 0.9:
				box.move_x(-c.get_normal().x * push_speed * delta)


# ---------------- Agarrar / soltar caja ----------------
func _handle_grab() -> void:
	if Input.is_action_just_pressed("grab") and is_on_floor() and not grabbed_box:
		if box_detector.is_colliding():
			var box := box_detector.get_collider() as PushableBox
			if box:
				grabbed_box = box
				grabbed_box.set_grabbed(true)

	if grabbed_box:
		var too_far := absf(grabbed_box.global_position.x - global_position.x) > max_grab_distance
		if Input.is_action_just_released("grab") or not is_on_floor() or too_far:
			_release_box()


func _release_box() -> void:
	if grabbed_box:
		grabbed_box.set_grabbed(false)
		grabbed_box = null


# ---------------- Interactuar (palancas) ----------------
func _handle_interact() -> void:
	if Input.is_action_just_pressed("interact") and is_instance_valid(interactable):
		interactable.interact(self)


func _on_interact_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		interactable = area


func _on_interact_area_exited(area: Area2D) -> void:
	if area == interactable:
		interactable = null


# ---------------- Deslizarse (listo, aún sin tecla asignada) ----------------
func set_sliding(value: bool) -> void:
	if is_sliding == value:
		return
	is_sliding = value
	col_stand.set_deferred("disabled", value)
	col_slide.set_deferred("disabled", not value)


# ---------------- Animaciones ----------------
func _update_animation() -> void:
	var anim := "idle" if facing == 1 else "idle_left"

	if not is_on_floor():
		if velocity.y < -120.0:
			anim = "jump"   # subiendo
		elif velocity.y < 120.0:
			anim = "peak"   # punto más alto
		else:
			anim = "fall"   # cayendo
	elif grabbed_box:
		anim = "push"       # agarrando una caja (empujar o jalar)
	elif is_sliding:
		anim = "slide"
	elif absf(velocity.x) > 10.0:
		anim = "walk"

	# Si falta alguna animación, usa idle para que no truene
	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle"

	if sprite.animation != anim:
		sprite.play(anim)

	# idle_left ya mira a la izquierda (no se voltea); las demás sí
	visuals.scale.x = 1 if anim == "idle_left" else facing

	# La caminata va más lenta cuando el movimiento es más lento
	if anim == "walk":
		sprite.speed_scale = clampf(absf(velocity.x) / max_speed, 0.4, 1.0)
	else:
		sprite.speed_scale = 1.0


# ---------------- Morir y reaparecer ----------------
func die() -> void:
	if is_dead:
		return
	is_dead = true
	_release_box()
	velocity = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 0.4)
	await tween.finished
	respawn()


func respawn() -> void:
	if GameManager.has_checkpoint:
		global_position = GameManager.last_checkpoint_position
	else:
		global_position = spawn_position
	velocity = Vector2.ZERO
	visuals.modulate.a = 1.0
	is_dead = false
	GameManager.player_respawned.emit()
