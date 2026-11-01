extends Node

# Cargamos la escena de pausa.
var escena_pausa = preload("res://ui/pausa.tscn")


# Detectamos cuando se presiona ESC.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:

		# Creamos la pantalla de pausa dentro del nivel actual.
		var pausa = escena_pausa.instantiate()
		get_tree().current_scene.add_child(pausa)

		# Pausamos el juego.
		get_tree().paused = true

		# Evitamos procesar nuevamente la tecla.
		get_viewport().set_input_as_handled()
