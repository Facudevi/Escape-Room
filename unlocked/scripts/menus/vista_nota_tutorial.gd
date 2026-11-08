extends CanvasLayer
# Nota del armario en "Cómo jugar": usa la misma hoja de cuaderno que las pistas.
# El inventario la abre con doble clic llamando a abrir_papel().

const TEXTO := "¡Bien! Las notas se leen con doble clic. Cuando termines, cerrá con la X."


func _ready() -> void:
	visible = false
	$Hoja/Encabezado/Fila/Titulo.text = "NOTA"
	$Hoja/Encabezado/Fila/Bombilla.visible = false


func abrir_papel() -> void:
	$Hoja/Pista.text = TEXTO
	visible = true


# Conectada desde la escena al botón X
func _on_boton_cerrar_pressed() -> void:
	visible = false
