extends CanvasLayer

# Panel de botones de la puerta de salida.
# Cada pulsación enciende un LED; recién con la cuarta se valida la secuencia,
# así no se puede adivinar de a un color por vez.
signal secuencia_correcta
signal secuencia_incorrecta

const ESCALA := 0.74
const SECUENCIA: Array[String] = ["azul", "amarillo", "rojo", "verde"]
# Posiciones sobre la imagen original del panel (640x760)
const BOTONES := {
	"rojo": Vector2(215, 335),
	"verde": Vector2(425, 335),
	"azul": Vector2(215, 525),
	"amarillo": Vector2(425, 525),
}
const POS_LEDS: Array[Vector2] = [Vector2(155, 150), Vector2(265, 150), Vector2(375, 150), Vector2(485, 150)]
const RADIO_BOTON := 84.0
const RADIO_LED := 28.0

const COLOR_PULSADO := Color(1.0, 0.85, 0.35)
const COLOR_ERROR := Color(0.9, 0.15, 0.1)
const COLOR_OK := Color(0.2, 0.9, 0.35)

@onready var imagen: TextureRect = $ImagenPanel
@onready var boton_cerrar: Button = $BotonCerrar

var leds: Array[Panel] = []
var ingresados: Array[String] = []
var bloqueado: bool = false
var resuelto: bool = false


func _ready() -> void:
	hide()
	boton_cerrar.pressed.connect(hide)
	imagen.size = Vector2(640, 760) * ESCALA
	imagen.position = (get_viewport().get_visible_rect().size - imagen.size) / 2.0
	for pos in POS_LEDS:
		leds.append(_crear_led(pos))
	for color in BOTONES:
		_crear_boton(color, BOTONES[color])


func abrir() -> void:
	show()


func _crear_led(pos: Vector2) -> Panel:
	var led := Panel.new()
	led.size = Vector2.ONE * RADIO_LED * 2.0 * ESCALA
	led.position = pos * ESCALA - led.size / 2.0
	led.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pintar(led, Color(0, 0, 0, 0))
	imagen.add_child(led)
	return led


func _crear_boton(color: String, pos: Vector2) -> void:
	var boton := Button.new()
	boton.flat = true
	boton.size = Vector2.ONE * RADIO_BOTON * 2.0 * ESCALA
	boton.position = pos * ESCALA - boton.size / 2.0
	boton.focus_mode = Control.FOCUS_NONE
	var vacio := StyleBoxEmpty.new()
	var resalte := StyleBoxFlat.new()
	resalte.bg_color = Color(1, 1, 1, 0.18)
	resalte.set_corner_radius_all(100)
	var presionado := StyleBoxFlat.new()
	presionado.bg_color = Color(1, 1, 1, 0.35)
	presionado.set_corner_radius_all(100)
	boton.add_theme_stylebox_override("normal", vacio)
	boton.add_theme_stylebox_override("hover", resalte)
	boton.add_theme_stylebox_override("pressed", presionado)
	boton.add_theme_stylebox_override("focus", vacio)
	boton.pressed.connect(_on_boton.bind(color))
	imagen.add_child(boton)


func _pintar(led: Panel, color: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(100)
	led.add_theme_stylebox_override("panel", estilo)


func _on_boton(color: String) -> void:
	if bloqueado or resuelto:
		return
	_pintar(leds[ingresados.size()], COLOR_PULSADO)
	ingresados.append(color)
	if ingresados.size() < SECUENCIA.size():
		return
	bloqueado = true
	if ingresados == SECUENCIA:
		resuelto = true
		for led in leds:
			_pintar(led, COLOR_OK)
		await get_tree().create_timer(1.0).timeout
		hide()
		secuencia_correcta.emit()
	else:
		for led in leds:
			_pintar(led, COLOR_ERROR)
		secuencia_incorrecta.emit()
		await get_tree().create_timer(0.9).timeout
		_reiniciar()


func _reiniciar() -> void:
	ingresados.clear()
	for led in leds:
		_pintar(led, Color(0, 0, 0, 0))
	bloqueado = false
