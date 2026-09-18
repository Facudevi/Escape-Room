extends CanvasLayer


func _ready() -> void:
	# Nos aseguramos de que empiece oculta
	hide()

func abrir_papel() -> void:
	show()

func _on_boton_cerrar_pressed() -> void:
	# Al tocar la cruz roja simplemente la ocultamos
	hide()
