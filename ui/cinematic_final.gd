extends "res://ui/cinematic.gd"
# Cinemática final después del Nivel 3.
# Muestra la Escena 7 y al terminar salta a la pantalla de créditos.

func _init() -> void:
	escenas = [
		{
			"imagenes": ["res://assets/cinematicas/escena_7.png"],
			"partes": [
				"Volvimos con el alma que nos arrebataron.",
				"Maleddries nos recibe entre sus raíces, como una madre que temió no vernos regresar.",
				"Hoy, los salvados fueron más que los perdidos.",
			],
		},
	]
	
	# Al terminar toda la secuencia, salta a la pantalla de créditos
	escena_destino = "res://ui/titulo_final.tscn"
