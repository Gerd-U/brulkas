extends CanvasLayer
# Autoload Transicion: fundido a negro entre escenas.
# Uso: Transicion.cambiar_escena("res://...") en lugar de change_scene_to_file,
# o Transicion.fundir_y(accion) para oscurecer antes de hacer otra cosa
# (por ejemplo avisarle al GameManager que terminó el nivel).
# Si alguna escena cambia sin pasar por acá, igual aparece con un fundido.

## Segundos que tarda en oscurecer y en volver a aclarar
@export var duracion: float = 0.6

var _cortina: ColorRect
var _tween: Tween
var _ocupado := false  # mientras dura el fundido no se aceptan clics ni teclas


func _ready() -> void:
	layer = 128
	# Tiene que funcionar aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

	_cortina = ColorRect.new()
	_cortina.color = Color.BLACK
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.modulate.a = 0.0
	add_child(_cortina)

	get_tree().scene_changed.connect(_al_cambiar_escena)


# Oscurece, cambia de escena y la nueva aparece aclarándose
func cambiar_escena(ruta: String) -> void:
	fundir_y(func(): get_tree().change_scene_to_file(ruta))


# Oscurece la pantalla y recién ahí ejecuta la acción
func fundir_y(accion: Callable) -> void:
	if _ocupado:
		return
	_ocupado = true
	_animar(1.0, func():
		accion.call()
		_por_si_no_cambia())


func _al_cambiar_escena() -> void:
	# Si la escena cambió sin oscurecer antes, arranca en negro igual
	_ocupado = true
	_cortina.modulate.a = 1.0
	_animar(0.0, func(): _ocupado = false)


# Si la acción no cambió de escena, no dejamos la pantalla en negro
func _por_si_no_cambia() -> void:
	var escena := get_tree().current_scene
	await get_tree().create_timer(1.0, true).timeout
	if get_tree().current_scene == escena and _cortina.modulate.a > 0.99:
		_animar(0.0, func(): _ocupado = false)


func _animar(alfa: float, al_terminar: Callable) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_cortina, "modulate:a", alfa, duracion) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(al_terminar)


func _input(event: InputEvent) -> void:
	# Un clic o una tecla durante el fundido no hace nada (ni saltea dos cosas)
	if _ocupado and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
