extends Label
# Cartel de aviso: se ajusta al texto, entra con un rebote y sube un poco al desvanecerse.
# Solo mira el texto y la transparencia que ya maneja cada nivel; no cambia esa lógica.

const MARGEN_LATERAL: float = 60.0
const ANCHO_MIN: float = 220.0
const ANCHO_MAX: float = 920.0
const SALIDA_Y: float = 24.0

var _base_y: float = 0.0
var _extra_y: float = 0.0
var _texto_previo: String = ""
var _alfa_previo: float = 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crear_chinche()
	await get_tree().process_frame
	_base_y = position.y


func _process(_delta: float) -> void:
	var alfa: float = modulate.a
	var aparece: bool = alfa > 0.9 and _alfa_previo < 0.5
	var cambia: bool = text != _texto_previo and alfa > 0.01
	if aparece or cambia:
		_ajustar_ancho()
		_entrar()
	_texto_previo = text
	_alfa_previo = alfa
	if alfa > 0.0:
		position.y = _base_y + _extra_y - (1.0 - alfa) * SALIDA_Y


func _entrar() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_extra_y = -90.0
	_tween = create_tween()
	_tween.tween_property(self, "_extra_y", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ajustar_ancho() -> void:
	var fuente: Font = get_theme_font("font")
	var tamano: int = get_theme_font_size("font_size")
	var ancho_texto: float = fuente.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	var ancho: float = clampf(ancho_texto + MARGEN_LATERAL, ANCHO_MIN, ANCHO_MAX)
	offset_left = -ancho / 2.0
	offset_right = ancho / 2.0


# Chinche roja arriba del cartel, solo decorativa
func _crear_chinche() -> void:
	var chinche := Panel.new()
	chinche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chinche.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chinche.offset_left = -10.0
	chinche.offset_right = 10.0
	chinche.offset_top = -12.0
	chinche.offset_bottom = 8.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("C43A2C")
	estilo.border_color = Color("1B2540")
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	chinche.add_theme_stylebox_override("panel", estilo)
	add_child(chinche)
