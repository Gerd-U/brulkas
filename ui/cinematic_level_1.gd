extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var timer: Timer = $Timer

# Lista de imágenes de la cinemática de transición del Nivel 1
var cinematicas: Array[String] = [
	"res://assets/cinematicas/escena_4.png",
	# Agrega aquí las demás imágenes de esta cinemática si tienes más
]
var indice_actual: int = 0

func _ready() -> void:
	if cinematicas.size() > 0:
		texture_rect.texture = load(cinematicas[0])	
	
	if timer and not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

# Permite avanzar manualmente haciendo clic o presionando espacio
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		siguiente_escena()
		if timer:
			timer.start()

func _on_timer_timeout() -> void:
	siguiente_escena()

func siguiente_escena() -> void:
	indice_actual += 1
	if indice_actual < cinematicas.size():
		texture_rect.texture = load(cinematicas[indice_actual])
		if timer:
			timer.start()
	else:
		# Cuando se acaban las imágenes de esta cinemática, pasamos al Nivel 2
		GameManager.nivel_actual = 1  # Configuramos el índice del GameManager en 1 (Nivel 2)
		get_tree().change_scene_to_file("res://levels/nivel_02.tscn")
