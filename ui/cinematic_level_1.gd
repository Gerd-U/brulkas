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
				"Las pequeñas victorias no siempre duran, mucho menos teniendo a las criaturas en tu contra. Salvar un alma no te excede de que se lleven otra.",
			],
		},
		{
			"imagenes": ["res://assets/cinematicas/escena_6.png"],
			"partes": [
				"Y regresar a las profundidades del bosque es nuestro único camino. Esperando que al regreso sean más los salvados que los perdidos.",
			],
		},
	]
	
	# Cuando termina toda la secuencia, pasamos al Nivel 2
	escena_destino = "res://levels/nivel_02.tscn"
	nivel_destino = 1
