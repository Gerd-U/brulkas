# Extiende de Control (mantén lo que ya tengas arriba)
extends Control

@onready var visuals: Node2D = get_node_or_null("Visuals") # O los nodos que tengas

# Colores del botón al pasar el mouse y al apretarlo
const COLOR_HOVER := Color(1.15, 1.15, 1.15)
const COLOR_APRETADO := Color(0.8, 0.8, 0.8)

func _ready() -> void:
	await get_tree().process_frame

	# Agregamos el efecto de zoom a todos los botones.
	for boton in $HBoxContainer.get_children():
		boton.pivot_offset = boton.size / 2
		boton.mouse_entered.connect(_al_entrar.bind(boton))
		boton.mouse_exited.connect(_al_salir.bind(boton))
		boton.button_down.connect(_al_apretar.bind(boton))
		boton.button_up.connect(_al_soltar.bind(boton))
		boton.button_down.connect(Audio.reproducir_boton)  # al apretar, no al soltar


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


# MODIFICADO: Ahora abre la cinemática en lugar de ir directo al nivel 1.
func _on_button_pressed() -> void:
	Transicion.cambiar_escena("res://ui/cinematic.tscn")
	

# Cierra el juego cuando se presiona SALIR.
func _on_button_3_pressed() -> void:
	get_tree().quit()


# Abre la pantalla de créditos.
func _on_button_2_pressed() -> void:
	Transicion.cambiar_escena("res://ui/creditos.tscn")
