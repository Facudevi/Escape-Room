extends Node2D
# Flecha amarilla que salta sobre el objeto del paso actual. Solo aparece en la práctica.

const SOL := Color("FFD23F")
const TINTA := Color("1B2540")

var _punta: Vector2 = Vector2.ZERO
var _tiempo: float = 0.0


func _ready() -> void:
	z_index = 50
	visible = false


func apuntar(punta: Vector2) -> void:
	_punta = punta
	visible = true


func ocultar() -> void:
	visible = false


func _process(delta: float) -> void:
	_tiempo += delta
	position = _punta + Vector2(0, -8.0 * absf(sin(_tiempo * 4.0)))
	queue_redraw()


# El origen del nodo es la punta de la flecha
func _draw() -> void:
	var tri := PackedVector2Array([Vector2(0, 0), Vector2(-16, -26), Vector2(16, -26)])
	draw_colored_polygon(tri, SOL)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), TINTA, 4.0)
