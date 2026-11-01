extends Control
# Cinemática del inicio: cada imagen tiene su texto narrado, que se escribe
# letra por letra. La imagen no cambia hasta que su texto terminó.

# Las imágenes y sus partes de texto, en orden.
# Si una escena tiene dos imágenes, se alternan (el aleteo de la escena 2).
# Otras cinemáticas extienden este script y cambian esto en _init().
var escenas := [
	{
		"imagenes": ["res://assets/cinematicas/escena_1.png"],
		"partes": [
			"En las profundidades del bosque Maleddries habitan criaturas de más de cuatro metros, con garras que te partirían en dos y dientes que romperían tus huesos.",
			"Nadie del pueblo que colinda entra y conserva la vida; quien cruza la barrera de raíces nunca regresa.",
		],
	},
	{
		"imagenes": ["res://assets/cinematicas/escena_2.png", "res://assets/cinematicas/escena_2.1.png"],
		"partes": [
			"No es ritual ni tradición. Hay padres que no desearon serlo y dejaron a sus hijos morir en el bosque.",
			"Maleddries tomó a cada bebé que dejaron en sus faldas, lo cuidó y le enseñó a sobrevivir.",
			"Pero no todos sobreviven. Los Viveriuz buscan las almas puras, no por hambre sino por poder: las capturan para abrigarse en la oscuridad.",
			"Y cuando un alma es robada, es nuestra obligación devolverla al lugar al que pertenece.",
		],
	},
	{
		"imagenes": ["res://assets/cinematicas/escena_3.png"],
		"partes": [
			"El escuadrón de niños se aventura más adentro, donde ni la madre bosque quiere que se pierdan sus hijos.",
			"El bosque sabe que no los puede proteger de todo, pero madre es, y velar por sus hijos es lo único que puede hacer.",
		],
	},
]
# A dónde va al terminar
var escena_destino := "res://levels/nivel_01.tscn"
var nivel_destino := 0

## Letras por segundo al escribir el texto
@export var velocidad_escritura: float = 38.0
## Segundos que espera con el texto completo antes de avanzar solo (0 = solo con tecla o clic)
@export var avance_automatico: float = 0.0
## Segundos entre cada cambio de imagen del aleteo
@export var velocidad_aleteo: float = 0.35

@onready var texture_rect: TextureRect = $TextureRect
@onready var texto: Label = $Narracion/Pantalla/Cuadro/Texto
@onready var indicador: Label = $Narracion/Pantalla/Cuadro/Indicador

var escena_actual := 0
var parte_actual := 0
var escribiendo := false
var letras := 0.0        # letras escritas hasta ahora (con decimales)
var espera := 0.0        # segundos con el texto completo, para el avance automático
var aleteo := 0.0        # segundos desde el último cambio de imagen del aleteo
var imagen_actual := 0   # cuál de las imágenes de la escena se ve
var terminando := false  # para no cambiar al nivel dos veces


func _ready() -> void:
	_mostrar_escena()


func _process(delta: float) -> void:
	if terminando:
		return

	# Aleteo: si la escena tiene varias imágenes, se alternan sin tocar el texto
	var imagenes: Array = escenas[escena_actual]["imagenes"]
	if imagenes.size() > 1:
		aleteo += delta
		if aleteo >= velocidad_aleteo:
			aleteo = 0.0
			imagen_actual = (imagen_actual + 1) % imagenes.size()
			texture_rect.texture = load(imagenes[imagen_actual])

	if escribiendo:
		letras += velocidad_escritura * delta
		texto.visible_characters = int(letras)
		if texto.visible_characters >= texto.get_total_character_count():
			_completar_parte()
	else:
		# El indicador parpadea mientras espera
		indicador.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
		if avance_automatico > 0.0:
			espera += delta
			if espera >= avance_automatico:
				_avanzar()


func _unhandled_input(event: InputEvent) -> void:
	if terminando or event.is_echo():
		return

	# ESC salta toda la cinemática
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ir_al_nivel()
		return

	var clic: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("ui_accept") or clic:
		# Se marca antes, porque al terminar la cinemática esta escena se va
		get_viewport().set_input_as_handled()
		# Un toque hace una sola cosa: completar el texto, o avanzar si ya estaba completo
		if escribiendo:
			_completar_parte()
		else:
			_avanzar()


func _mostrar_escena() -> void:
	imagen_actual = 0
	aleteo = 0.0
	texture_rect.texture = load(escenas[escena_actual]["imagenes"][0])
	parte_actual = 0
	_empezar_parte()


func _empezar_parte() -> void:
	texto.text = escenas[escena_actual]["partes"][parte_actual]
	texto.visible_characters = 0
	letras = 0.0
	espera = 0.0
	escribiendo = true
	indicador.visible = false


func _completar_parte() -> void:
	texto.visible_characters = -1
	escribiendo = false
	espera = 0.0
	indicador.visible = true


# Siguiente parte de la misma imagen, o la siguiente imagen si era la última
func _avanzar() -> void:
	if parte_actual + 1 < escenas[escena_actual]["partes"].size():
		parte_actual += 1
		_empezar_parte()
	elif escena_actual + 1 < escenas.size():
		escena_actual += 1
		_mostrar_escena()
	else:
		_ir_al_nivel()


func _ir_al_nivel() -> void:
	if terminando:
		return
	terminando = true
	GameManager.nivel_actual = nivel_destino
	get_tree().change_scene_to_file(escena_destino)
