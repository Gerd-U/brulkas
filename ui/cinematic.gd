extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var timer: Timer = $Timer

# Lista de imágenes de la cinemática en orden
var cinematicas: Array[String] = [
	"res://assets/cinematicas/escena_1.png",
	"res://assets/cinematicas/escena_2.png",
	"res://assets/cinematicas/escena_2.1.png",
	"res://assets/cinematicas/escena_3.png"
]
var indice_actual: int = 0

func _ready() -> void:
	# Nos aseguramos de mostrar la primera imagen al iniciar
	if cinematicas.size() > 0:
		texture_rect.texture = load(cinematicas[0])
	
	# Conectamos la señal del timer por código (o puedes usar el paso 2 del editor)
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

# Permite avanzar haciendo clic o presionando espacio si el jugador quiere saltar rápido
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		siguiente_escena()
		timer.start() # Reinicia el temporizador al hacer clic manual

# Se ejecuta automáticamente cada vez que el Timer llega a su tiempo límite
func _on_timer_timeout() -> void:
	siguiente_escena()

func siguiente_escena() -> void:
	indice_actual += 1
	if indice_actual < cinematicas.size():
		texture_rect.texture = load(cinematicas[indice_actual])
	else:
		# Cuando se acaban todas las imágenes, pasa al nivel 1
		GameManager.nivel_actual = 0
		get_tree().change_scene_to_file("res://levels/nivel_01.tscn")
