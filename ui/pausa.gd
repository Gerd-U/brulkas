extends CanvasLayer
# La raíz es un CanvasLayer para que el menú se dibuje siempre fijo en la
# pantalla (no en el mundo) y por encima de todo, incluido el fondo.


# Se ejecuta cuando aparece la pantalla de pausa.
func _ready() -> void:
	# Permitimos que la pantalla funcione aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configuramos el efecto de zoom para los botones.
	for boton in $Control/Panel.get_children():
		if boton is Button:
			boton.pivot_offset = boton.size / 2
			boton.mouse_entered.connect(_al_entrar.bind(boton))
			boton.mouse_exited.connect(_al_salir.bind(boton))

	# El botón Continuar arranca con el foco, para poder usar el teclado.
	$Control/Panel/Button.grab_focus.call_deferred()


# Aumenta el tamaño del botón cuando el ratón pasa sobre él.
func _al_entrar(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.05, 1.05), 0.15)


# Devuelve el botón a su tamaño normal.
func _al_salir(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.15)


# Reanuda el juego y cierra la pausa (lo usa el botón y también la tecla ESC).
func continuar() -> void:
	get_tree().paused = false
	queue_free()


# Reanuda el juego cuando se presiona CONTINUAR.
func _on_button_pressed() -> void:
	continuar()


# Regresa al menú principal cuando se presiona SALIR AL MENÚ.
func _on_button_2_pressed() -> void:
	# Primero se quita la pausa, después se cambia de escena
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://ui/menu_principal.tscn")
