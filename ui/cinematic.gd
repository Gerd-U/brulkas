extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var timer: Timer = $Timer # <-- Apunta directamente al Timer porque es hijo directo

# Lista completa de la cinemática
var cinematicas: Array[String] = [
	"res://assets/cinematicas/escena_1.png",
	"res://assets/cinematicas/escena_2.png",
	"res://assets/cinematicas/escena_2.1.png",
	"res://assets/cinematicas/escena_3.png"
]
var indice_actual: int = 0

# Variables para el mini loop de las alas
var en_loop_de_alas: bool = false
var contador_loop: int = 0
const REPETICIONES_ALAS: int = 3 # Cuántas veces parpadea/baja y sube las alas

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
	# Verificamos si estamos en la "escena_2.png" (índice 1) para iniciar el mini loop
	if indice_actual == 1 and not en_loop_de_alas:
		en_loop_de_alas = true
		contador_loop = 0
		ejecutar_loop_alas()
		return

	if en_loop_de_alas:
		contador_loop += 1
		if contador_loop < REPETICIONES_ALAS:
			ejecutar_loop_alas()
			return
		else:
			# Terminó el loop, salimos de él y pasamos a la siguiente normal (escena_3)
			en_loop_de_alas = false
			indice_actual = 3 # Saltamos directamente al índice de escena_3.png
	else:
		indice_actual += 1

	if indice_actual < cinematicas.size():
		texture_rect.texture = load(cinematicas[indice_actual])
		if timer:
			# Si caemos de nuevo en la escena_2, ajustamos el tiempo del timer para que sea un loop rápido (ej. 0.35 segundos)
			if indice_actual == 1 or indice_actual == 2:
				timer.wait_time = 0.35 
			else:
				timer.wait_time = 4.0 # Tiempo normal para las demás imágenes
			timer.start()
	else:
		# Fin de la cinemática, al nivel 1
		GameManager.nivel_actual = 0
		get_tree().change_scene_to_file("res://levels/nivel_01.tscn")

func ejecutar_loop_alas() -> void:
	# Alterna rápidamente entre escena_2 (índice 1) y escena_2.1 (índice 2)
	if texture_rect.texture and texture_rect.texture.resource_path == cinematicas[1]:
		indice_actual = 2
	else:
		indice_actual = 1
	
	texture_rect.texture = load(cinematicas[indice_actual])
	if timer:
		timer.wait_time = 0.35 # Velocidad rápida para el aleteo
		timer.start()
