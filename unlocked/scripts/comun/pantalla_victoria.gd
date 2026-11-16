extends CanvasLayer

# Pantalla ganadora que cada nivel muestra al completarse.
# Ofrece volver al menú de niveles o continuar directo al siguiente nivel.

const ESCENA_NIVELES := "res://escenas/menus/niveles.tscn"
# Escenas jugables por número de nivel (el nivel 4 todavía no existe)
const ESCENAS_NIVEL: Dictionary = {
	1: "res://escenas/niveles/nivel1/nivel1.tscn",
	2: "res://escenas/niveles/nivel2/nivel2.tscn",
	3: "res://escenas/niveles/nivel3/nivel3.tscn",
}

@onready var oscuro: Control = $Panel
@onready var marco: Control = $Marco
@onready var titulo: Label = $Marco/Pizarra/VBoxContainer/Titulo
@onready var boton_continuar: Button = $Marco/Pizarra/VBoxContainer/Continuar
@onready var boton_niveles: Button = $Marco/Pizarra/VBoxContainer/MenuNiveles

var _nivel: int = 1
var _marco_y: float = 0.0
var _tween: Tween


func _ready() -> void:
	_marco_y = marco.position.y


# Lo llama el nivel al completarse: pausa el juego y muestra la pantalla
func mostrar(nivel: int) -> void:
	_nivel = nivel
	titulo.text = "¡NIVEL %d COMPLETADO!" % nivel
	# Si no hay un nivel siguiente jugable todavía, el botón CONTINUAR no se muestra
	boton_continuar.visible = ESCENAS_NIVEL.has(nivel + 1)

	# Se pausa el mundo para que no se pueda interactuar con el escenario de atrás
	get_tree().paused = true
	visible = true

	# La pizarra cae con un pequeño rebote y el fondo se oscurece (corre aunque el juego esté en pausa)
	oscuro.modulate.a = 0.0
	marco.position.y = _marco_y - 560.0
	_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(oscuro, "modulate:a", 1.0, 0.25)
	_tween.tween_property(marco, "position:y", _marco_y, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_continuar_pressed() -> void:
	_ir_a(ESCENAS_NIVEL.get(_nivel + 1, ESCENA_NIVELES))


func _on_menu_niveles_pressed() -> void:
	_ir_a(ESCENA_NIVELES)


func _ir_a(ruta: String) -> void:
	# Un solo clic: evita que un doble clic dispare dos transiciones
	boton_continuar.disabled = true
	boton_niveles.disabled = true
	get_tree().paused = false
	# Se limpian inventario y datos del nivel; el progreso de niveles se conserva
	Global.reiniciar_datos()
	FX.cambiar_escena(ruta)
