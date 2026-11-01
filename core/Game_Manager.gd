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
	
	# Interceptamos cuando se termina el Nivel 1 para mostrar la cinemática
	if nivel_actual == 1:
		get_tree().change_scene_to_file("res://ui/cinematic_level_1.tscn")
		return

	if nivel_actual < niveles.size():
		if ResourceLoader.exists(niveles[nivel_actual]):
			get_tree().change_scene_to_file(niveles[nivel_actual])
		else:
			push_warning("El nivel no existe: " + niveles[nivel_actual])
	else:
		# Al terminar el último nivel (Nivel 3), mandamos al jugador a los créditos
		get_tree().change_scene_to_file("res://ui/creditos.tscn")


func finalizar_cinematica() -> void:
	# Carga automáticamente el nivel correspondiente (en este caso el Nivel 2)
	get_tree().change_scene_to_file(GameManager.niveles[GameManager.nivel_actual])
