extends Control

func _ready() -> void:
	await get_tree().process_frame

	for boton in $HBoxContainer.get_children():
		boton.pivot_offset = boton.size / 2
		boton.mouse_entered.connect(_al_entrar.bind(boton))
		boton.mouse_exited.connect(_al_salir.bind(boton))


func _al_entrar(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.05, 1.05), 0.15)


func _al_salir(boton: Control) -> void:
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.15)
