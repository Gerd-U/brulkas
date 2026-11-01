extends Control


# Se ejecuta cuando aparece la pantalla de pausa.
func _ready() -> void:
	# Permitimos que la pantalla funcione aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configuramos el efecto de zoom para los botones.
	for boton in $Panel.get_children():
		if boton is Button:
			boton.pivot_offset = boton.size / 2
			boton.mouse_entered.connect(_al_entrar.bind(boton))
			boton.mouse_exited.connect(_al_salir.bind(boton))


# Aumenta el tamaño del botón cuando el ratón pasa sobre él.
func _al_entrar(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.05, 1.05), 0.15)


# Devuelve el botón a su tamaño normal.
func _al_salir(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.15)


# Reanuda el juego cuando se presiona CONTINUAR.
func _on_button_pressed() -> void:
	get_tree().paused = false
	queue_free()


# Regresa al menú principal cuando se presiona SALIR AL MENÚ.
func _on_button_2_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/menu_principal.tscn")
