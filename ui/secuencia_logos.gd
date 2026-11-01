extends Control
# Muestra una lista de imágenes una tras otra, centradas en pantalla:
# aparece (fade in) → se queda un momento → desaparece (fade out).
# Al terminar va a la escena destino. Con clic, Espacio/Enter o ESC se salta todo.
# La usan intro.tscn (logos al abrir el juego) y titulo_final.tscn.

## Imágenes que se muestran, en orden
@export var imagenes: Array[Texture2D] = []
## Escena a la que va al terminar (o al saltar la secuencia)
@export_file("*.tscn") var escena_destino: String = "res://ui/menu_principal.tscn"
## Segundos que tarda cada imagen en aparecer o desaparecer
@export var duracion_fade: float = 0.8
## Segundos que cada imagen se queda quieta en pantalla
@export var tiempo_visible: float = 1.8
## Color del fondo (y del fundido al pasar a la escena destino)
@export var color_fondo: Color = Color.BLACK

@onready var fondo: ColorRect = $Fondo
@onready var imagen: TextureRect = $Imagen

var _tween: Tween
var _terminando := false


func _ready() -> void:
	fondo.color = color_fondo
	imagen.modulate.a = 0.0

	_tween = create_tween()
	for textura in imagenes:
		_tween.tween_callback(func(): imagen.texture = textura)
		_tween.tween_property(imagen, "modulate:a", 1.0, duracion_fade)
		_tween.tween_interval(tiempo_visible)
		_tween.tween_property(imagen, "modulate:a", 0.0, duracion_fade)
	_tween.tween_callback(_ir_al_destino)


func _unhandled_input(event: InputEvent) -> void:
	if _terminando or event.is_echo():
		return
	var clic: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if clic or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_ir_al_destino()


func _ir_al_destino() -> void:
	# Un solo cambio de escena aunque se toque varias veces
	if _terminando:
		return
	_terminando = true
	if _tween:
		_tween.kill()

	# Fundido a negro y la escena destino aparece suave, sin corte
	Transicion.cambiar_escena(escena_destino)
