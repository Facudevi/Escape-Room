extends Area2D
# Baldosa amarilla del paso 1: una elipse que late sobre el piso (se dibuja aplastada por la perspectiva).

const SOL := Color("FFD23F")
const TINTA := Color("1B2540")

var _tiempo: float = 0.0


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	var pulso: float = 1.0 + 0.08 * sin(_tiempo * 5.0)
	var radio := Vector2(62.0, 17.0) * pulso
	var puntos := PackedVector2Array()
	for i in range(41):
		var a: float = TAU * i / 40.0
		puntos.append(Vector2(cos(a) * radio.x, sin(a) * radio.y))
	draw_colored_polygon(puntos, Color(SOL.r, SOL.g, SOL.b, 0.3))
	draw_polyline(puntos, TINTA, 6.0)
	draw_polyline(puntos, SOL, 3.0)
