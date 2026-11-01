extends Node
# Autoload ControlPausa: abre y cierra el menú de pausa con ESC (acción "pause").

# Cargamos la escena de pausa.
var escena_pausa = preload("res://ui/pausa.tscn")

# Solo se puede pausar en las escenas que usan este script (los niveles).
const SCRIPT_NIVEL := "res://levels/nivel.gd"

# La pausa abierta ahora mismo (null si no hay ninguna).
var _pausa: Node = null


func _ready() -> void:
	# Tiene que seguir escuchando ESC aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS


# Detectamos cuando se presiona ESC.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return

	if is_instance_valid(_pausa):
		# Ya está en pausa: ESC hace lo mismo que el botón Continuar.
		_pausa.continuar()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused and _estamos_en_un_nivel():
		_abrir_pausa()
		get_viewport().set_input_as_handled()


# true si la escena actual es un nivel (y no el menú, los créditos o una cinemática)
func _estamos_en_un_nivel() -> bool:
	var escena := get_tree().current_scene
	if escena == null:
		return false
	var script: Script = escena.get_script()
	return script != null and script.resource_path == SCRIPT_NIVEL


func _abrir_pausa() -> void:
	# Creamos la pantalla de pausa dentro del nivel actual
	# (si el nivel se cambia o se reinicia, se va junto con él).
	_pausa = escena_pausa.instantiate()
	# Cuando la pausa se cierra (Continuar, ESC o Salir), limpiamos la referencia.
	_pausa.tree_exited.connect(_al_cerrar_pausa)
	get_tree().current_scene.add_child(_pausa)

	# Pausamos el juego.
	get_tree().paused = true


func _al_cerrar_pausa() -> void:
	_pausa = null
