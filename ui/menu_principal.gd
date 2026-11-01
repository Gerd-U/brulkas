# Extiende de Control (mantén lo que ya tengas arriba)
extends Control

@onready var visuals: Node2D = get_node_or_null("Visuals") # O los nodos que tengas

func _ready() -> void:
	await get_tree().process_frame

	# Agregamos el efecto de zoom a todos los botones.
	for boton in $HBoxContainer.get_children():
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


# MODIFICADO: Ahora abre la cinemática en lugar de ir directo al nivel 1.
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/cinematic.tscn")
	

# Cierra el juego cuando se presiona SALIR.
func _on_button_3_pressed() -> void:
	get_tree().quit()


# Abre la pantalla de créditos.
func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/creditos.tscn")
