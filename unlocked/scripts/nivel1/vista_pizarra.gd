extends CanvasLayer


func _ready() -> void:
	# Ocultamos la vista ampliada al iniciar el nivel
	hide()

func abrir_pizarra() -> void:
	show()

func _on_boton_cerrar_pressed() -> void:
	hide()
