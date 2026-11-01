extends "res://ui/cinematic.gd"
# Cinemática de transición del Nivel 1 al Nivel 2.
# Usa el mismo sistema de texto que la cinemática del inicio (cinematic.gd).


func _init() -> void:
	# Imágenes de esta cinemática y sus partes de texto
	escenas = [
		{
			"imagenes": ["res://assets/cinematicas/escena_4.png"],
			"partes": [
				"Y no importa qué tan oscuro se ponga el bosque: los vamos a traer de vuelta.",
			],
		},
	]
	# Cuando termina, pasamos al Nivel 2
	escena_destino = "res://levels/nivel_02.tscn"
	nivel_destino = 1
