class_name TexturaUtil
extends RefCounted
## Ayudas para dibujar imágenes usando solo su parte visible
## y para armar colisiones con la forma del dibujo.

# Se calculan una sola vez por imagen
static var _partes := {}
static var _envolventes := {}
static var _bases := {}


## Parte visible de la imagen: lo que se ve de verdad, sin los bordes
## transparentes ni el borde casi invisible del suavizado (si se contara,
## los objetos quedarían separados unos píxeles del suelo)
static func parte_visible(textura: Texture2D) -> Rect2:
	if not _partes.has(textura):
		var parte := Rect2(Vector2.ZERO, textura.get_size())
		var imagen := _imagen(textura)
		if imagen:
			# Desde cada borde avanzamos hasta encontrar un píxel bien visible
			var u := imagen.get_used_rect()
			var arriba := u.position.y
			while arriba < u.end.y and not _fila_visible(imagen, arriba, u):
				arriba += 1
			var abajo := u.end.y - 1
			while abajo > arriba and not _fila_visible(imagen, abajo, u):
				abajo -= 1
			var izquierda := u.position.x
			while izquierda < u.end.x and not _columna_visible(imagen, izquierda, arriba, abajo):
				izquierda += 1
			var derecha := u.end.x - 1
			while derecha > izquierda and not _columna_visible(imagen, derecha, arriba, abajo):
				derecha -= 1
			if arriba < u.end.y and izquierda < u.end.x:
				parte = Rect2(izquierda, arriba, derecha - izquierda + 1, abajo - arriba + 1)
		_partes[textura] = parte
	return _partes[textura]


## Punto de apoyo del dibujo: el centro de lo que se ve en la fila de más abajo
static func base_visible(textura: Texture2D) -> Vector2:
	if not _bases.has(textura):
		var parte := parte_visible(textura)
		var base := Vector2(parte.get_center().x, parte.end.y)
		var imagen := _imagen(textura)
		if imagen:
			# Promedio de los píxeles visibles en las últimas filas
			var suma := 0.0
			var cuenta := 0
			var desde := int(parte.end.y - maxf(2.0, parte.size.y * 0.04))
			for y in range(desde, int(parte.end.y)):
				for x in range(int(parte.position.x), int(parte.end.x)):
					if imagen.get_pixel(x, y).a > 0.5:
						suma += x
						cuenta += 1
			if cuenta > 0:
				base.x = suma / cuenta
		_bases[textura] = base
	return _bases[textura]


## Forma lisa del dibujo (une las puntas con líneas rectas, sin entradas),
## puesta dentro del rectángulo donde se dibuja la parte visible
static func envolvente(textura: Texture2D, destino: Rect2, detalle: float = 6.0) -> PackedVector2Array:
	var clave := [textura, detalle]
	if not _envolventes.has(clave):
		_envolventes[clave] = _envolvente_normalizada(textura, detalle)
	var resultado := PackedVector2Array()
	for punto in _envolventes[clave]:
		resultado.append(destino.position + punto * destino.size)
	return resultado


# La envolvente con medidas de 0 a 1 respecto de la parte visible
static func _envolvente_normalizada(textura: Texture2D, detalle: float) -> PackedVector2Array:
	var imagen := _imagen(textura)
	if imagen == null:
		return PackedVector2Array()
	var parte := parte_visible(textura)
	var recorte := imagen.get_region(Rect2i(parte))
	var mapa := BitMap.new()
	mapa.create_from_image_alpha(recorte, 0.5)
	var todos := PackedVector2Array()
	for contorno in mapa.opaque_to_polygons(Rect2i(Vector2i.ZERO, recorte.get_size()), detalle):
		for punto in contorno:
			todos.append(punto / parte.size)
	var lisa := Geometry2D.convex_hull(todos)
	if lisa.size() > 3:
		lisa.remove_at(lisa.size() - 1)  # el último punto repite el primero
		return lisa
	return PackedVector2Array()


static func _fila_visible(imagen: Image, y: int, u: Rect2i) -> bool:
	for x in range(u.position.x, u.end.x):
		if imagen.get_pixel(x, y).a >= 0.5:
			return true
	return false


static func _columna_visible(imagen: Image, x: int, arriba: int, abajo: int) -> bool:
	for y in range(arriba, abajo + 1):
		if imagen.get_pixel(x, y).a >= 0.5:
			return true
	return false


static func _imagen(textura: Texture2D) -> Image:
	var imagen := textura.get_image()
	if imagen and imagen.is_compressed():
		imagen.decompress()
	return imagen
