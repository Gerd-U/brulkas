extends Node

signal player_respawned

var last_checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

# Agreguen aquí los niveles conforme los vayan creando
var levels: Array[String] = [
	"res://levels/test_level.tscn",
]
var current_level_index: int = 0


func set_checkpoint(pos: Vector2) -> void:
	last_checkpoint_position = pos
	has_checkpoint = true


func change_level(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("El nivel no existe: " + path)
		return
	has_checkpoint = false  # el checkpoint no pasa de nivel
	get_tree().change_scene_to_file(path)


func next_level() -> void:
	current_level_index += 1
	if current_level_index >= levels.size():
		current_level_index = 0
	change_level(levels[current_level_index])


func reload_level() -> void:
	has_checkpoint = false
	get_tree().reload_current_scene()
