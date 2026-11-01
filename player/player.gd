class_name Player
extends CharacterBody2D

# ---------- Movimiento (Adaptado a escala 0.5 / ~128px) ----------
@export var max_speed: float = 280.0
@export var acceleration: float = 2178.0
@export var friction: float = 2800.0
@export var air_control: float = 0.7

# ---------- Salto y gravedad ----------
@export var jump_velocity: float = -385.90
@export var gravity: float = 620.51
@export var fall_gravity_multiplier: float = 1.6
@export var jump_cut_multiplier: float = 0.45
@export var max_fall_speed: float = 338.46
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# ---------- Cajas ----------
@export var grab_speed_multiplier: float = 0.5
@export var detector_reach: float = 9.03

# ---------- Resbalar (zona resbalosa) ----------
@export var resbalar_aceleracion: float = 169.23
@export var resbalar_velocidad_max: float = 312.82
@export var resbalar_control: float = 56.41

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_dead: bool = false
var resbalando: bool = false
var facing: int = 1
var caja_agarrada = null

@onready var visuals: Node2D = $Visuals
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var box_detector: RayCast2D = $BoxDetector
@onready var col_stand: CollisionShape2D = $CollisionShape2D
@onready var col_slide: CollisionShape2D = $CollisionSlide


func _ready() -> void:
	add_to_group("jugador")
	floor_snap_length = 6.77
	col_stand.disabled = false
	col_slide.disabled = true
	box_detector.target_position = Vector2(detector_reach, 0.0)
	
	if GameManager.obtener_checkpoint() == Vector2.ZERO:
		GameManager.guardar_checkpoint(global_position)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var input_dir := Input.get_axis("move_left", "move_right")

	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_horizontal(input_dir, delta)

	var velocidad_x_deseada := velocity.x
	move_and_slide()

	_handle_grab(velocidad_x_deseada, delta)
	_handle_interact()
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
		g *= fall_gravity_multiplier
	velocity.y = min(velocity.y + g * delta, max_fall_speed)


# ---------------- Salto ----------------
func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if caja_agarrada != null:
		return

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


# ---------------- Movimiento horizontal ----------------
func _handle_horizontal(input_dir: float, delta: float) -> void:
	if resbalando:
		velocity.x += resbalar_aceleracion * delta
		velocity.x += input_dir * resbalar_control * delta
		velocity.x = clampf(velocity.x, 0.0, resbalar_velocidad_max)
		return

	var target_speed := max_speed
	if caja_agarrada != null:
		target_speed *= grab_speed_multiplier

	var control := 1.0 if is_on_floor() else air_control

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * target_speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _update_facing(input_dir: float) -> void:
	if caja_agarrada != null or resbalando or input_dir == 0.0:
		return
	facing = 1 if input_dir > 0.0 else -1
	box_detector.target_position.x = detector_reach * facing


# ---------------- Cajas ----------------
func _handle_grab(velocidad_x: float, delta: float) -> void:
	if caja_agarrada != null and not is_instance_valid(caja_agarrada):
		caja_agarrada = null

	var quiere_agarrar := Input.is_action_pressed("grab") and is_on_floor() and not resbalando

	if caja_agarrada == null:
		if quiere_agarrar:
			caja_agarrada = _buscar_caja()
		if caja_agarrada == null:
			return

	if not quiere_agarrar:
		_soltar_caja()
		return

	caja_agarrada.mover(velocidad_x * delta)


func _buscar_caja() -> Node:
	if box_detector.is_colliding():
		var c = box_detector.get_collider()
		if c is Node and c.is_in_group("cajas") and c.has_method("mover"):
			return c
	for i in get_slide_collision_count():
		var otro = get_slide_collision(i).get_collider()
		if otro is Node and otro.is_in_group("cajas") and otro.has_method("mover"):
			return otro
	return null


func _soltar_caja() -> void:
	if caja_agarrada != null and is_instance_valid(caja_agarrada):
		caja_agarrada.soltar()
	caja_agarrada = null


# ---------------- Interactuar (palancas) ----------------
func _handle_interact() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	for area in $InteractArea.get_overlapping_areas():
		if area.has_method("interact"):
			area.interact(self)
			return


# ---------------- Zona resbalosa ----------------
func empezar_resbalar() -> void:
	if resbalando or is_dead:
		return
	resbalando = true
	facing = 1
	box_detector.target_position.x = detector_reach
	_soltar_caja()
	col_stand.set_deferred("disabled", true)
	col_slide.set_deferred("disabled", false)


func dejar_resbalar() -> void:
	if not resbalando:
		return
	resbalando = false
	col_stand.set_deferred("disabled", false)
	col_slide.set_deferred("disabled", true)


# ---------------- Animaciones ----------------
func _update_animation() -> void:
	var anim := "idle" if facing == 1 else "idle_left"

	if resbalando and coyote_timer > 0.0:
		anim = "slide"
	elif not is_on_floor():
		if velocity.y < -240.0:
			anim = "jump"
		elif velocity.y < 240.0:
			anim = "peak"
		else:
			anim = "fall"
	elif caja_agarrada != null:
		anim = "push"
	elif absf(velocity.x) > 20.0:
		anim = "walk"

	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle"

	if sprite.animation != anim:
		sprite.play(anim)

	visuals.scale.x = 1 if anim == "idle_left" else facing

	if anim == "walk":
		sprite.speed_scale = clampf(absf(velocity.x) / max_speed, 0.4, 1.0)
	else:
		sprite.speed_scale = 1.0

	# --- Ajuste dinámico para rampa y deslizamiento ---
	var angulo_objetivo := 0.0
	var offset_y_deslizamiento := 0.0
	
	if resbalando and is_on_floor():
		angulo_objetivo = get_floor_normal().angle() + PI / 2.0
		# Prueba cambiando este número a 22.0 o 24.0 para que baje un poco más
		offset_y_deslizamiento = 30.0 

	visuals.rotation = lerp_angle(visuals.rotation, angulo_objetivo, 0.25)
	
	var posicion_objetivo = Vector2(0.0, offset_y_deslizamiento)
	visuals.position = visuals.position.lerp(posicion_objetivo, 0.25)

# ---------------- Morir y reaparecer ----------------
func morir() -> void:
	if is_dead:
		return
	is_dead = true
	_soltar_caja()
	dejar_resbalar()
	velocity = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 0.4)
	await tween.finished

	var posicion_reaparicion = GameManager.obtener_checkpoint()
	if posicion_reaparicion == Vector2.ZERO:
		posicion_reaparicion = global_position 

	global_position = posicion_reaparicion
	velocity = Vector2.ZERO
	dejar_resbalar()
	
	var tween_aparecer := create_tween()
	tween_aparecer.tween_property(visuals, "modulate:a", 1.0, 0.3)
	await tween_aparecer.finished
	
	is_dead = false
