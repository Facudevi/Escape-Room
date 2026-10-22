extends Node

# Escala el personaje según su posición Y (efecto de perspectiva).
# Opcional: con `activo = false` el personaje vuelve a su escala y velocidad originales.

@export var objetivo: CharacterBody2D
@export var activo: bool = true:
	set(valor):
		activo = valor
		if is_node_ready():
			aplicar()

# Dos puntos de referencia (Y -> escala); fuera de ese rango se mantiene el límite
var y_lejos: float = 470.0
var escala_lejos: float = 0.6
var y_cerca: float = 640.0
var escala_cerca: float = 1.1
# Fracción de la velocidad base cuando está lo más lejos
var velocidad_lejos: float = 0.75

var _escala_base: Vector2
var _velocidad_base: float


func _ready() -> void:
	_escala_base = objetivo.scale
	_velocidad_base = objetivo.speed
	aplicar()


func configurar(y_l: float, esc_l: float, y_c: float, esc_c: float, vel_l: float = 0.75) -> void:
	y_lejos = y_l
	escala_lejos = esc_l
	y_cerca = y_c
	escala_cerca = esc_c
	velocidad_lejos = vel_l
	aplicar()


func _process(_delta: float) -> void:
	if activo:
		aplicar()


func aplicar() -> void:
	if objetivo == null:
		return
	if not activo:
		objetivo.scale = _escala_base
		objetivo.speed = _velocidad_base
		return
	var t: float = clampf((objetivo.global_position.y - y_lejos) / (y_cerca - y_lejos), 0.0, 1.0)
	objetivo.scale = _escala_base * lerpf(escala_lejos, escala_cerca, t)
	objetivo.speed = _velocidad_base * lerpf(velocidad_lejos, 1.0, t)
