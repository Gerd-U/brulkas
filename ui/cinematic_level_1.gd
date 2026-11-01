extends "res://ui/cinematic.gd"
# Cinemática de transición del Nivel 1 al Nivel 2.
# Usa el mismo sistema de texto que la cinemática del inicio (cinematic.gd).


func _init() -> void:
	# Secuencia completa de imágenes y textos para esta transición
	escenas = [
		{
			"imagenes": ["res://assets/cinematicas/escena_4.png"],
			"partes": [
				"Y no importa qué tan oscuro se ponga el bosque: los vamos a traer de vuelta.",
			],
		},
		{
			"imagenes": ["res://assets/cinematicas/escena_5.png"],
			"partes": [
				"Escribe aquí el texto que aparecerá con la escena 5...",
			],
		},
		{
			"imagenes": ["res://assets/cinematicas/escena_6.png"],
			"partes": [
				"Escribe aquí el texto que aparecerá con la escena 6...",
			],
		},
	]
	
	# Cuando termina toda la secuencia, pasamos al Nivel 2
	escena_destino = "res://levels/nivel_02.tscn"
	nivel_destino = 1
