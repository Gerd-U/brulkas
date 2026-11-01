extends Node2D
# Sonido posicional que dura todo lo que haga falta (roca de cajas y ascensores).
# El archivo suena fuerte los primeros segundos y después se va apagando, así
# que en vez de dejarlo terminar se vuelve a empezar desde el principio cada
# `tramo` segundos, cruzando dos reproductores para que no se note el corte.
# El archivo no se modifica: solo se reproduce y se ajusta el volumen.

## Segundos que se usa de cada reproducción antes de empezar la siguiente
@export var tramo: float = 2.6
## Segundos del cruce entre una reproducción y la siguiente
@export var fundido: float = 0.4

const SILENCIO := -60.0

var volumen: float = 0.0
var _reproductores: Array[AudioStreamPlayer2D] = []
var _actual := 0
var _activo := false
var _tiempo := 0.0


func configurar(stream: AudioStream, bus: StringName, volumen_db: float,
		distancia: float, atenuacion: float) -> void:
	volumen = volumen_db
	for i in 2:
		var reproductor := AudioStreamPlayer2D.new()
		reproductor.stream = stream
		reproductor.bus = bus
		reproductor.volume_db = volumen
		reproductor.max_distance = distancia
		reproductor.attenuation = atenuacion
		add_child(reproductor)
		_reproductores.append(reproductor)


func empezar() -> void:
	if _activo:
		return
	_activo = true
	_tiempo = 0.0
	_arrancar(_actual)


# Se apaga suave en vez de cortarse
func parar(duracion: float = 0.3) -> void:
	if not _activo:
		return
	_activo = false
	for reproductor in _reproductores:
		if reproductor.playing:
			_apagar(reproductor, duracion)


func _process(delta: float) -> void:
	if not _activo:
		return
	_tiempo += delta
	if _tiempo >= tramo:
		_tiempo = 0.0
		var anterior := _reproductores[_actual]
		_actual = 1 - _actual
		_arrancar(_actual)
		_apagar(anterior, fundido)


func _arrancar(indice: int) -> void:
	var reproductor := _reproductores[indice]
	_matar_fundido(reproductor)
	reproductor.volume_db = volumen
	reproductor.play()


func _apagar(reproductor: AudioStreamPlayer2D, duracion: float) -> void:
	_matar_fundido(reproductor)
	var tween := reproductor.create_tween()
	tween.tween_property(reproductor, "volume_db", SILENCIO, duracion)
	tween.tween_callback(reproductor.stop)
	reproductor.set_meta("fundido", tween)


func _matar_fundido(reproductor: AudioStreamPlayer2D) -> void:
	if reproductor.has_meta("fundido"):
		var tween: Tween = reproductor.get_meta("fundido")
		if tween and tween.is_valid():
			tween.kill()
		reproductor.remove_meta("fundido")
