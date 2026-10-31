@tool
extends AnimatableBody2D

## Tamaño del bloque con los pinchos incluidos (ancho, alto)
@export var tamano: Vector2 = Vector2(120, 80):
	set(valor):
		tamano = valor
		_actualizar()

## Cuántos píxeles cae (distancia entre arriba y abajo)
@export var caida: float = 300.0:
	set(valor):
		caida = max(10.0, valor)
		queue_redraw()

## Segundos que se queda arriba (el momento para pasar)
@export var tiempo_arriba: float = 1.2
## Segundos que tarda en caer (poco = rápido)
@export var tiempo_caida: float = 0.15
## Segundos que se queda abajo
@export var tiempo_abajo: float = 0.4
## Segundos que tarda en subir
@export var tiempo_subida: float = 1.0
## Segundos que espera antes de empezar. Sirve para hacer la "ola" con varios.
@export var desfase: float = 0.0

## Color del bloque
@export var color: Color = Color(0.3, 0.3, 0.33):
	set(valor):
		color = valor
		queue_redraw()

const PICOS := 16.0  # alto de los pinchos de abajo
const EMPUJE := 320.0  # velocidad con que tira al jugador si se sube encima

var _abajo: Vector2
var _arriba: Vector2
var _techo: Area2D  # franja encima del bloque para que nadie se pare arriba


func _ready() -> void:
	_actualizar()
	if Engine.is_editor_hint():
		return
	# La posición donde lo ponés es donde queda ABAJO (tocando el suelo).
	# Al empezar el juego lo subimos.
	_abajo = position
	_arriba = position - Vector2(0, caida)
	position = _arriba
	$ZonaPinchos.body_entered.connect(_al_tocar)
	_crear_techo()
	_empezar()


func _crear_techo() -> void:
	# Franja delgadita justo encima del bloque que detecta al jugador
	_techo = Area2D.new()
	_techo.collision_layer = 0
	_techo.collision_mask = 2  # capa del jugador
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tamano.x, 10)
	forma.shape = rect
	# Se mete 2 px dentro del bloque para detectar bien los pies del jugador
	forma.position = Vector2(0, -tamano.y - 3)
	_techo.add_child(forma)
	add_child(_techo)


func _physics_process(delta: float) -> void:
	if _techo == null:
		return
	# Si el jugador está parado arriba, lo empujamos hacia el lado más cercano
	for cuerpo in _techo.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador"):
			var lado := signf(cuerpo.global_position.x - global_position.x)
			if lado == 0.0:
				lado = 1.0
			cuerpo.global_position.x += lado * EMPUJE * delta


func _actualizar() -> void:
	# Bloque sólido (sin contar los pinchos)
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(tamano.x, tamano.y - PICOS)
		forma.shape = rect
		forma.position = Vector2(0, -PICOS - (tamano.y - PICOS) / 2)

	# Zona que mata: la franja de los pinchos
	var zona := get_node_or_null("ZonaPinchos/CollisionShape2D") as CollisionShape2D
	if zona:
		var rect2 := RectangleShape2D.new()
		rect2.size = Vector2(tamano.x - 8, PICOS + 6)
		zona.shape = rect2
		zona.position = Vector2(0, -PICOS / 2)

	queue_redraw()


func _empezar() -> void:
	if desfase > 0.0:
		await get_tree().create_timer(desfase).timeout

	var tween := create_tween()
	tween.set_loops()  # se repite para siempre
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_interval(tiempo_arriba)
	# Cae rápido (acelerando, como si pesara)
	tween.tween_property(self, "position", _abajo, tiempo_caida) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(tiempo_abajo)
	# Sube despacio
	tween.tween_property(self, "position", _arriba, tiempo_subida) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _al_tocar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("morir"):
		cuerpo.morir()


func _draw() -> void:
	# En el editor lo dibujamos ARRIBA (donde empieza),
	# y con una línea amarilla marcamos dónde cae.
	var desplazamiento := Vector2.ZERO
	if Engine.is_editor_hint():
		desplazamiento = Vector2(0, -caida)

	var w := tamano.x
	var h := tamano.y
	# Bloque
	var bloque := Rect2(Vector2(-w / 2, -h) + desplazamiento, Vector2(w, h - PICOS))
	draw_rect(bloque, color)
	draw_rect(bloque, color.darkened(0.4), false, 2.0)
	# Pinchos (triángulos hacia abajo)
	var cantidad := int(w / 20.0)
	var paso := w / cantidad
	for i in cantidad:
		var x := -w / 2 + i * paso
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, -PICOS) + desplazamiento,
			Vector2(x + paso / 2, 0) + desplazamiento,
			Vector2(x + paso, -PICOS) + desplazamiento,
		]), Color(0.75, 0.75, 0.8))

	# Solo en el editor: dónde queda cuando cae
	if Engine.is_editor_hint():
		var amarillo := Color(1, 1, 0.3, 0.8)
		draw_dashed_line(Vector2(0, -caida), Vector2(0, -h), amarillo, 2.0, 10.0)
		draw_rect(Rect2(-w / 2, -h, w, h), amarillo, false, 2.0)
