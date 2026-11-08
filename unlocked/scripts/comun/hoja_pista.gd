extends Panel
# Hoja de cuaderno del cartel de pistas: dibuja renglones, margen y agujeros, alinea el texto
# con los renglones y entra con un pequeño giro y rebote. Solo presentación.

const RENGLON: float = 36.0
const PRIMER_RENGLON: float = 144.0
const TINTA := Color("1B2540")

@onready var pista: Label = $Pista

var _tween: Tween
var _base_y: float = 0.0
var _rotacion: float = 0.0


func _ready() -> void:
	_rotacion = rotation
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	_alinear_texto()
	get_parent().visibility_changed.connect(_al_cambiar_visibilidad)


# El texto cae justo sobre los renglones, sea cual sea la fuente
func _alinear_texto() -> void:
	var fuente: Font = pista.get_theme_font("font")
	var tamano: int = pista.get_theme_font_size("font_size")
	pista.add_theme_constant_override("line_spacing", int(RENGLON - fuente.get_height(tamano)))
	var alto: float = pista.offset_bottom - pista.offset_top
	pista.offset_top = PRIMER_RENGLON - 6.0 - fuente.get_ascent(tamano)
	pista.offset_bottom = pista.offset_top + alto


func _draw() -> void:
	var y: float = PRIMER_RENGLON
	while y < size.y - 14.0:
		draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color(0.275, 0.51, 0.82, 0.38), 1.5)
		y += RENGLON
	draw_line(Vector2(78, 4), Vector2(78, size.y - 4), Color(0.769, 0.227, 0.173, 0.6), 3.0)
	for hy in [82.0, 178.0, 274.0]:
		draw_circle(Vector2(36, hy), 13.0, Color("5F6B85"))
		draw_arc(Vector2(36, hy), 13.0, 0.0, TAU, 24, TINTA, 3.0)


func _al_cambiar_visibilidad() -> void:
	var capa: CanvasLayer = get_parent()
	var oscuro: Control = capa.get_node_or_null("Oscuro")
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_restaurar(oscuro)
	if not capa.visible:
		return
	_base_y = position.y
	pivot_offset = size / 2.0
	modulate.a = 0.0
	position.y = _base_y + 90.0
	scale = Vector2(0.82, 0.82)
	rotation = _rotacion - deg_to_rad(7.0)
	if oscuro != null:
		oscuro.modulate.a = 0.0
	_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.tween_property(self, "position:y", _base_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", _rotacion, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if oscuro != null:
		_tween.tween_property(oscuro, "modulate:a", 1.0, 0.25)


func _restaurar(oscuro: Control) -> void:
	modulate.a = 1.0
	position.y = _base_y
	scale = Vector2.ONE
	rotation = _rotacion
	if oscuro != null:
		oscuro.modulate.a = 1.0
