extends "res://ui/cinematic.gd"
# Cinemática final después del Nivel 3.
# Muestra la Escena 7 y al terminar salta a la pantalla de créditos.

func _init() -> void:
	escenas = [
		{
			"imagenes": ["res://assets/cinematicas/escena_7.png"],
			"partes": [
				"Escribe aquí el texto final que acompañará a la escena 7...",
			],
		},
	]
	
	# Al terminar toda la secuencia, salta a la pantalla de créditos
	escena_destino = "res://ui/creditos.tscn"
