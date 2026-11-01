extends CanvasLayer
# La raíz es un CanvasLayer para que el menú se dibuje siempre fijo en la
# pantalla (no en el mundo) y por encima de todo, incluido el fondo.


# Colores del botón al pasar el mouse y al apretarlo
const COLOR_HOVER := Color(1.15, 1.15, 1.15)
const COLOR_APRETADO := Color(0.8, 0.8, 0.8)


# Se ejecuta cuando aparece la pantalla de pausa.
func _ready() -> void:
	# Permitimos que la pantalla funcione aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configuramos el efecto de zoom para los botones.
	for boton in $Control/Panel.get_children():
		# BaseButton incluye los botones con imagen (TextureButton) y los de texto
		if boton is BaseButton:
			boton.pivot_offset = boton.size / 2
			boton.mouse_entered.connect(_al_entrar.bind(boton))
			boton.mouse_exited.connect(_al_salir.bind(boton))
			boton.button_down.connect(_al_apretar.bind(boton))
			boton.button_up.connect(_al_soltar.bind(boton))
			boton.button_down.connect(Audio.reproducir_boton)  # al apretar, no al soltar

	# El botón Continuar arranca con el foco, para poder usar el teclado.
	$Control/Panel/Button.grab_focus.call_deferred()


# Aumenta el tamaño del botón y lo aclara un poco cuando el ratón pasa sobre él.
func _al_entrar(boton: Control) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(boton, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(boton, "modulate", COLOR_HOVER, 0.15)


# Devuelve el botón a su tamaño y color normal.
func _al_salir(boton: Control) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(boton, "modulate", Color.WHITE, 0.15)


# Mientras se mantiene apretado, el botón se ve un poco más oscuro.
func _al_apretar(boton: Control) -> void:
	boton.modulate = COLOR_APRETADO


func _al_soltar(boton: Control) -> void:
	boton.modulate = COLOR_HOVER if boton.is_hovered() else Color.WHITE


# Reanuda el juego y cierra la pausa (lo usa el botón y también la tecla ESC).
func continuar() -> void:
	get_tree().paused = false
	queue_free()


# Reanuda el juego cuando se presiona CONTINUAR.
func _on_button_pressed() -> void:
	continuar()


# Regresa al menú principal cuando se presiona SALIR AL MENÚ.
func _on_button_2_pressed() -> void:
	# El juego sigue en pausa mientras se oscurece; al quedar en negro
	# se quita la pausa y se cambia de escena
	Transicion.fundir_y(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/menu_principal.tscn"))
