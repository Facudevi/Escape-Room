extends Control

# Escena a la que lleva SALIR (por defecto, la selección de niveles)
@export_file("*.tscn") var escena_salida: String = "res://escenas/menus/niveles.tscn"

@onready var oscuro: Control = $Panel
@onready var marco: Control = $Marco

var _marco_y: float = 0.0
var _tween: Tween


func _ready() -> void:
	_marco_y = marco.position.y
	visibility_changed.connect(_al_cambiar_visibilidad)


# La pizarra cae con un pequeño rebote y el fondo se oscurece (corre aunque el juego esté en pausa)
func _al_cambiar_visibilidad() -> void:
	if not visible:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	oscuro.modulate.a = 0.0
	marco.position.y = _marco_y - 560.0
	_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(oscuro, "modulate:a", 1.0, 0.25)
	_tween.tween_property(marco, "position:y", _marco_y, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_reanudar_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_salir_pressed() -> void:
	get_tree().paused = false
	# Reiniciamos el inventario y datos globales antes de cambiar de escena
	Global.reiniciar_datos()
	FX.cambiar_escena(escena_salida)
