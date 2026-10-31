# core/game_manager.gd
extends Node

var ultimo_checkpoint: Vector2 = Vector2.ZERO

# Agreguen aquí los niveles conforme los vayan creando
var niveles: Array[String] = [
	"res://levels/nivel_01.tscn",
	# "res://levels/nivel_02.tscn",
]
var nivel_actual: int = 0


func guardar_checkpoint(posicion: Vector2) -> void:
	ultimo_checkpoint = posicion


func obtener_checkpoint() -> Vector2:
	return ultimo_checkpoint


func nivel_completado() -> void:
	nivel_actual += 1
	if nivel_actual < niveles.size():
		if ResourceLoader.exists(niveles[nivel_actual]):
			get_tree().change_scene_to_file(niveles[nivel_actual])
		else:
			push_warning("El nivel no existe: " + niveles[nivel_actual])
	else:
		pass  # ir a la pantalla final de Nazareth
