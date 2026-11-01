extends Node
# Autoload Audio: música de fondo y sonidos que no pertenecen a un objeto del nivel
# (muerte del jugador y alma). Los archivos de audio no se modifican: solo se
# reproducen y se ajusta el volumen de reproducción.
#
# Para afinar los volúmenes, cambiá los números de abajo (en dB: 0 = volumen
# original del archivo, números negativos = más bajo, -6 dB ≈ la mitad).

const MUSICA := "res://audio/bgm/Brulkas 003.mp3"
const SONIDO_MUERTE := "res://audio/sfx/Brulkas 004 - Death.mp3"
const SONIDO_ALMA := "res://audio/sfx/Brulkas 004 - Soul Pick.mp3"

@export_group("Buses")
## Volumen general de todo el juego
@export var volumen_master: float = 0.0
## Volumen de todo lo que suena en el bus "Musica"
@export var volumen_bus_musica: float = 0.0
## Volumen de todos los efectos (aplastador, trampa, muerte, alma)
@export var volumen_bus_efectos: float = 0.0

@export_group("Música")
## Volumen de la música de fondo (Brulkas 003)
@export var volumen_musica: float = -2.0
## Segundos que tarda la música en entrar al arrancar el juego
@export var fade_in_musica: float = 1.5

@export_group("Muerte")
## Volumen del sonido de muerte (Death)
@export var volumen_muerte: float = -8.0

@export_group("Alma")
## Volumen del sonido al recoger el alma (Soul Pick)
@export var volumen_alma: float = -1.0
## Segundos que suena el alma antes de empezar a desvanecerse
@export var alma_antes_del_fade: float = 4.0
## Segundos que tarda el alma en desvanecerse
@export var alma_fade: float = 1.5
## Cuántos dB baja la música mientras suena el alma
@export var musica_baja_con_alma: float = 6.0
## Segundos que tarda la música en volver a su volumen después del alma
@export var musica_vuelve: float = 1.5

const SILENCIO := -60.0  # volumen al que se lleva un sonido para apagarlo

var _musica: AudioStreamPlayer
var _muerte: AudioStreamPlayer
var _alma: AudioStreamPlayer
var _tween_musica: Tween
var _tween_alma: Tween
var _sin_muerte_hasta := 0  # ms: hasta cuándo no suena la muerte (la tapa otro sonido)


func _ready() -> void:
	# La música sigue aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

	_poner_volumen_bus("Master", volumen_master)
	_poner_volumen_bus("Musica", volumen_bus_musica)
	_poner_volumen_bus("Efectos", volumen_bus_efectos)

	# Música: una sola reproducción para todo el juego, en bucle.
	# El loop se activa en una copia en memoria; el archivo no cambia.
	var stream := (load(MUSICA) as AudioStreamMP3).duplicate() as AudioStreamMP3
	stream.loop = true
	_musica = _crear_reproductor(stream, "Musica", SILENCIO)
	_musica.play()
	_mover_musica(volumen_musica, fade_in_musica)

	# Muerte y alma: se pausan con el juego, como los demás efectos
	_muerte = _crear_reproductor(load(SONIDO_MUERTE), "Efectos", volumen_muerte)
	_muerte.process_mode = Node.PROCESS_MODE_PAUSABLE
	_alma = _crear_reproductor(load(SONIDO_ALMA), "Efectos", volumen_alma)
	_alma.process_mode = Node.PROCESS_MODE_PAUSABLE


# Suena una vez cada vez que el jugador muere (lo llama player.gd)
func reproducir_muerte() -> void:
	if Time.get_ticks_msec() < _sin_muerte_hasta:
		return
	_muerte.volume_db = volumen_muerte
	_muerte.play()


# La trampa llama a esto antes de matar al jugador: su propio sonido ya es
# la muerte, así no se escuchan los dos encimados
func callar_muerte(segundos: float = 0.5) -> void:
	_sin_muerte_hasta = Time.get_ticks_msec() + int(segundos * 1000.0)


# Suena al recoger el alma. Suena desde acá para no cortarse al cambiar de escena.
func reproducir_alma() -> void:
	if _tween_alma:
		_tween_alma.kill()
	_alma.volume_db = volumen_alma
	_alma.play()

	# Después de un rato se desvanece solo (el archivo dura mucho más)
	_tween_alma = _alma.create_tween()
	_tween_alma.tween_interval(alma_antes_del_fade)
	_tween_alma.tween_property(_alma, "volume_db", SILENCIO, alma_fade)
	_tween_alma.tween_callback(_alma.stop)

	# Mientras suena, la música baja un poco y después vuelve suave
	_mover_musica(volumen_musica - musica_baja_con_alma, 0.3)
	_tween_musica.tween_interval(alma_antes_del_fade + alma_fade)
	_tween_musica.tween_property(_musica, "volume_db", volumen_musica, musica_vuelve)


func _mover_musica(destino: float, duracion: float) -> void:
	if _tween_musica:
		_tween_musica.kill()
	_tween_musica = _musica.create_tween()
	_tween_musica.tween_property(_musica, "volume_db", destino, duracion)


func _crear_reproductor(stream: AudioStream, bus: String, volumen: float) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.stream = stream
	reproductor.bus = bus
	reproductor.volume_db = volumen
	add_child(reproductor)
	return reproductor


func _poner_volumen_bus(nombre: String, volumen: float) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice >= 0:
		AudioServer.set_bus_volume_db(indice, volumen)
