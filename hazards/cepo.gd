@tool
extends Area2D

## Ancho de la trampa
@export var ancho: float = 70.0:
	set(valor):
		ancho = max(10.0, valor)
		_actualizar()

## Alto de la trampa (cuando está cerrada)
@export var alto: float = 30.0:
	set(valor):
		alto = max(5.0, valor)
		_actualizar()

## Segundos que tarda en volver a abrirse después de atrapar al jugador
@export var tiempo_reabrir: float = 1.5

## Color del metal
@export var color: Color = Color(0.55, 0.55, 0.6):
	set(valor):
		color = valor
		queue_redraw()

var _cerrado := false      # está cerrada ahora mismo
var _desarmado := false    # una caja la cerró: ya no hace daño nunca más


func _ready() -> void:
	_actualizar()
	# Solo en el juego escuchamos cuando algo la pisa
	if not Engine.is_editor_hint():
		body_entered.connect(_al_pisar)


func _actualizar() -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, alto)
	forma.shape = rect
	# Base en y = 0, igual que los pinchos
	forma.position = Vector2(0, -alto / 2)
	queue_redraw()


func _al_pisar(cuerpo: Node2D) -> void:
	if _cerrado:
		return

	# ¿Es una caja? → se cierra y queda desarmada para siempre
	if cuerpo.is_in_group("cajas"):
		_cerrado = true
		_desarmado = true
		queue_redraw()
		return

	# ¿Es el jugador? → se cierra y lo mata
	if cuerpo.has_method("die"):
		_cerrado = true
		queue_redraw()
		cuerpo.die()
		# Esperamos un rato y la volvemos a abrir
		await get_tree().create_timer(tiempo_reabrir).timeout
		if not _desarmado:
			_cerrado = false
			queue_redraw()


func _draw() -> void:
	var w := ancho
	var oscuro := color.darkened(0.4)

	# Base (siempre se ve)
	draw_rect(Rect2(-w / 2, -6, w, 6), oscuro)

	if not _cerrado:
		# ABIERTA: fila de dientes apuntando hacia arriba
		var dientes := 6
		var paso := w / dientes
		for i in dientes:
			var x := -w / 2 + i * paso
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, -6),
				Vector2(x + paso / 2, -6 - alto * 0.5),
				Vector2(x + paso, -6),
			]), color)
	else:
		# CERRADA: las dos mandíbulas levantadas, juntas en el centro
		draw_colored_polygon(PackedVector2Array([
			Vector2(-w / 2, -6), Vector2(-4, -alto), Vector2(0, -6),
		]), color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -6), Vector2(4, -alto), Vector2(w / 2, -6),
		]), color.darkened(0.15))
