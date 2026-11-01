# core/Game_Manager.gd
extends Node

var ultimo_checkpoint: Vector2 = Vector2.ZERO

# Agreguen aquí los niveles conforme los vayan creando
var niveles: Array[String] = [
	"res://levels/nivel_01.tscn",
	"res://levels/nivel_02.tscn",
	"res://levels/nivel_03.tscn",
]
var nivel_actual: int = 0


func guardar_checkpoint(posicion: Vector2) -> void:
	ultimo_checkpoint = posicion


func obtener_checkpoint() -> Vector2:
	return ultimo_checkpoint


func nivel_completado() -> void:
	nivel_actual += 1
	
	# Interceptamos cuando se termina el Nivel 1 para mostrar su cinemática (Escenas 4, 5 y 6)
	if nivel_actual == 1:
		get_tree().change_scene_to_file("res://ui/cinematic_level_1.tscn")
		return

	if nivel_actual < niveles.size():
		if ResourceLoader.exists(niveles[nivel_actual]):
			get_tree().change_scene_to_file(niveles[nivel_actual])
		else:
			push_warning("El nivel no existe: " + niveles[nivel_actual])
	else:
		# Al terminar el Nivel 3, cargamos la cinemática final (Escena 7) antes de los créditos
		get_tree().change_scene_to_file("res://ui/cinematic_final.tscn")


func finalizar_cinematica() -> void:
	# Carga automáticamente el nivel correspondiente (para la transición del Nivel 1 al 2)
	get_tree().change_scene_to_file(GameManager.niveles[GameManager.nivel_actual])
