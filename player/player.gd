class_name Player
extends CharacterBody2D

# ---------- Movimiento ----------
@export var max_speed: float = 720.0
@export var acceleration: float = 5600.0
@export var friction: float = 7200.0
@export var air_control: float = 0.7

# ---------- Salto y gravedad ----------
@export var jump_velocity: float = -1520.0
@export var gravity: float = 4400.0
@export var fall_gravity_multiplier: float = 1.6
@export var jump_cut_multiplier: float = 0.45
@export var max_fall_speed: float = 2400.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# ---------- Cajas ----------
@export var grab_speed_multiplier: float = 0.5
@export var detector_reach: float = 56.0

# ---------- Resbalar (zona resbalosa) ----------
@export var resbalar_aceleracion: float = 2400.0
@export var resbalar_velocidad_max: float = 1100.0
@export var resbalar_control: float = 400.0  # cuánto influyen A/D (poco)

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_dead: bool = false
var resbalando: bool = false
var facing: int = 1
var caja_agarrada = null  # sin tipo a propósito: la caja es de Gerald

@onready var visuals: Node2D = $Visuals
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var box_detector: RayCast2D = $BoxDetector
@onready var col_stand: CollisionShape2D = $CollisionShape2D
@onready var col_slide: CollisionShape2D = $CollisionSlide


func _ready() -> void:
	add_to_group("jugador")
	box_detector.target_position = Vector2(detector_reach, 0.0)
	# Posición inicial = primer checkpoint, por si muere antes de tocar uno
	GameManager.guardar_checkpoint(global_position)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var input_dir := Input.get_axis("move_left", "move_right")

	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_horizontal(input_dir, delta)

	# Se guarda ANTES de move_and_slide, porque al chocar con la caja
	# move_and_slide puede dejar velocity.x en 0 y la caja no se movería
	var velocidad_x_deseada := velocity.x

	move_and_slide()

	_handle_grab(velocidad_x_deseada, delta)
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

	if caja_agarrada != null:
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
	# Resbalando: baja solo hacia la derecha, cada vez más rápido
	if resbalando:
		velocity.x += resbalar_aceleracion * delta
		velocity.x += input_dir * resbalar_control * delta
		velocity.x = clampf(velocity.x, 0.0, resbalar_velocidad_max)
		return

	var target_speed := max_speed
	if caja_agarrada != null:
		target_speed *= grab_speed_multiplier  # con caja se siente pesada

	var control := 1.0 if is_on_floor() else air_control

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * target_speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _update_facing(input_dir: float) -> void:
	# Con caja agarrada o resbalando no se voltea
	if caja_agarrada != null or resbalando or input_dir == 0.0:
		return
	facing = 1 if input_dir > 0.0 else -1
	box_detector.target_position.x = detector_reach * facing


# ---------------- Cajas (de Gerald: grupo "cajas", mover() y soltar()) ----------------

func _handle_grab(velocidad_x: float, delta: float) -> void:
	# Si la caja desapareció del juego, se olvida
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

	# Mientras siga agarrada: caminar hacia la caja la empuja,
	# al otro lado la jala
	caja_agarrada.mover(velocidad_x * delta)



func _buscar_caja() -> Node:
	# 1) El rayo que mira al frente
	if box_detector.is_colliding():
		var c = box_detector.get_collider()
		if c is Node and c.is_in_group("cajas") and c.has_method("mover"):
			return c
	# 2) Lo que se tocó con move_and_slide
	for i in get_slide_collision_count():
		var otro = get_slide_collision(i).get_collider()
		if otro is Node and otro.is_in_group("cajas") and otro.has_method("mover"):
			return otro
	return null


func _soltar_caja() -> void:
	if caja_agarrada != null and is_instance_valid(caja_agarrada):
		caja_agarrada.soltar()
	caja_agarrada = null


# ---------------- Zona resbalosa (la llama la zona de Gerald) ----------------
func empezar_resbalar() -> void:
	if resbalando:
		return
	resbalando = true
	facing = 1
	box_detector.target_position.x = detector_reach
	_soltar_caja()
	# Al resbalar queda sentada: se usa la colisión baja y ancha
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

	if not is_on_floor():
		if velocity.y < -480.0:
			anim = "jump"   # subiendo
		elif velocity.y < 480.0:
			anim = "peak"   # punto más alto
		else:
			anim = "fall"   # cayendo
	elif resbalando:
		anim = "slide"      # sentada resbalando
	elif caja_agarrada != null:
		anim = "push"       # agarrando una caja (empujar o jalar)
	elif absf(velocity.x) > 40.0:
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


# ---------------- Morir y reaparecer (la llaman los pinchos y el hueco) ----------------
func morir() -> void:
	if is_dead:
		return
	is_dead = true
	_soltar_caja()
	dejar_resbalar()
	velocity = Vector2.ZERO

	# Desvanecer un momento (aquí se puede agregar sonido, pantalla negra, etc.)
	var tween := create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 0.4)
	await tween.finished

	global_position = GameManager.obtener_checkpoint()
	velocity = Vector2.ZERO
	visuals.modulate.a = 1.0
	is_dead = false
